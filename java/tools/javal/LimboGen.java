package javal;

import java.io.File;
import java.io.DataOutputStream;
import java.io.FileOutputStream;
import java.io.IOException;

import java.lang.reflect.*;


public
class LimboGen
{
	public LimboGen( Class cl, Field[] fields, Method[] methods, boolean verbose )
	{
		theClass     = cl;
		this.fields  = fields;
		this.methods = methods;
		opt_verbose  = verbose;

		// create names
		String full_name = cl.getName();
		base_name  = ClassBaseName( full_name );
		mod_name   = base_name +"_L";
		limbo_dotm = mod_name +".m";
		limbo_dotb = mod_name +".b";

		// some class are "special" to javal
		// if it is a special class we don't
		// want to generate adt's for it and
		// will use a special ADT name
		special = true;  //assume special
		obj_adt = SpecialClass( full_name );

		if ( obj_adt == null )
		{
			special = false;
			obj_adt = base_name +"_obj";
		}

		// will only generate skeleton for native methods
		natives     = GetNatives( methods );
		has_natives = natives.length > 0;

		// need to distinguish between instance and static fields
		iFields     = GetInstanceFields( fields );
		sFields     = GetStaticFields( fields );
	}

	
	/**
	 * Generate a Limbo Module Declaration
	 * file (.m) for a java class containing
	 * native methods.
	 */
	public void DotM() throws IOException
	{
		// open a file 
		out = MkFile( limbo_dotm );

		// emit the Limbo Module File

		Emit( "# generated file edit with care\n\n" );
		Emit( mod_name +" : module\n" );
		Emit( "{\n" );

		GenADT();

		Emit( "\n" );

		GenFct(false);

		Emit( "\n};\n" );

		out.close();

		if ( merge )
		{
			// save off existing .m and rename
			// tmp to .m
			File f = new File( limbo_dotm );
			File o = new File("old_"+limbo_dotm);
			File t = new File( tmpname );

			if ( o.exists() ) o.delete();
			f.renameTo( o );
			t.renameTo( f );

		}

	}


	/**
	 * Generate a Limbo Module Implementation
	 * Skeleton containing native methods for
	 * a java class.
	 */
	public void DotB() throws IOException
	{
		// don't generate a .b if no natives
		if ( ! has_natives ) return; 

		// open a file 
		out = MkFile( limbo_dotb );

		// generate file prolog
		Emit("implement "+ mod_name +";\n\n" );
		Emit("include \"jni.m\";\n" );
		Emit(T1+"jni : JNI;\n" );
		Emit(T2+"ClassModule,\n");
		Emit(T2+ T_JString +",\n");
		Emit(T2+ T_JArray  +",\n");
		Emit(T2+ T_JArrayI  +",\n");
		Emit(T2+ T_JArrayC  +",\n");
		Emit(T2+ T_JArrayB  +",\n");
		Emit(T2+ T_JArrayS  +",\n");
		Emit(T2+ T_JArrayJ  +",\n");
		Emit(T2+ T_JArrayF  +",\n");
		Emit(T2+ T_JArrayD  +",\n");
		Emit(T2+ T_JArrayZ  +",\n");
		Emit(T2+ T_JArrayJObject +",\n");
		Emit(T2+ T_JArrayJClass +",\n");
		Emit(T2+ T_JArrayJString +",\n");
		Emit(T2+ T_JClass  +",\n");
		Emit(T2+T_JObject +" : import jni;\n\n");

		Emit("#>> extra pre includes here\n\n#<<\n\n");

		Emit("include \""+ limbo_dotm +"\";\n\n" );

		Emit("#>> extra post includes here\n\n#<<\n\n");

		// generate a skeleton for init() and each native method
		GenFct( true );

		out.close();

		if ( merge )
			FileMerge.Merge( limbo_dotb, tmpname );
	}


	/**
	 * Generate an ADT declaration for the class
	 * instance fields.
	 */
	private void GenADT() throws IOException
	{
		// don't generate an ADT decl for "special" clases
		if ( special ) return;

		Emit( T1+ obj_adt +" : adt\n"+ T1+ "{\n" );

		// emit the std object header
		Emit( T2+ "cl_mod : ClassModule;\n" );

		// walk through instance data emitting Limbo decl
		for( int x=0; x<iFields.length; x++ )
		{
			Emit( T2+ GenFieldDecl( iFields[x] ) +";\n" );
		}

		Emit( T1+ "};\n" );
	}

	private void GenFct( boolean skel ) throws IOException
	{
		// generate init fct
		GenInit( skel );

		// walk native methods and generate
		// a limbo fct
		for( int x=0; x<natives.length; x++ )
		{
			String fct_name = MkFctName( natives[x] );
			String this_param = "";

			// if fct is virtual generate implicit this param
			if ( ! Modifier.isStatic( natives[x].getModifiers() ) )
			{
				// if this is a special class then don't use ref
				// because the generated special name is already a ref
				this_param  = ( special ? "this : " : "this : ref " );
				this_param += obj_adt;
			}

			// determine fct parameters
			String params = GenFctParams( natives[x].getParameterTypes() );

			StringBuffer fct_params = new StringBuffer(80);
			if ( this_param != "" )
			{
				fct_params.append( this_param );
				if ( params != "" )
					fct_params.append( ", " );
			}

			fct_params.append( params );

			// determine fct return type...if any
			String fct_t    = LimboType( natives[x].getReturnType() );
			if ( ! fct_t.equals("") )
				fct_t = " : "+ fct_t;

			if ( skel )
			{
				Emit( fct_name +"( "+ 
					  fct_params.toString() +")"+
					  fct_t +"\n{#>>\n}#<<\n\n" );

			}
			else
			{
				Emit( T1+ fct_name +" : fn( "+ 
			          fct_params.toString() +")"+ 
					  fct_t +";\n" );
			}
		}
	}


	/**
	 * every Limbo Native module has a init()
	 * function which the loader will call
	 * when the native mod is loaded. This
	 * method generates that fct.
	 *
	 * @param skel If true gen a fct skel; else fct decl
	 *
	 */
	private void GenInit( boolean skel ) throws IOException
	{
		if ( skel )
		{
			Emit( "init( jni_p : JNI )\n{\n" );
			Emit( T1+"# save java native inteface mod instance\n" );
			Emit( T1+"jni = jni_p;\n" );
			Emit( T1+"#>>extra initialization here\n"+T1+"#<<\n" );
			Emit( "}\n\n" );
		}
		else
		{
			Emit( T1+"init : fn( jni_p : JNI );\n" );
		}
	}
	
	/**
	 * Given an array of types return a string with
	 * a comma seperated sequence of java method
	 * parameter declarations
	 *
	 * @param ptypes An array of types
	 *
	 * @return A string representing method param decls
	 */		
	private String GenFctParams( Class[] ptypes )
	{
		String fct_params = "";
		for( int x=0; x<ptypes.length; x++ )
		{
			fct_params = fct_params +"p"+ x +" : "+ LimboType( ptypes[x] );
			if ( x <ptypes.length-1 )
				fct_params = fct_params +",";
		}

		return( fct_params );
	}

	
	/**
	 * Take a Java class data-field and
	 * return a string with a coresponding
	 * Limbo adt field declaration.
	 *
	 * @param fi The Java field descriptor
	 *
	 * @return Limbo Declaration
	 */
	private String GenFieldDecl( Field fi )
	{
		String fi_name   = fi.getName();
		Class  java_type = fi.getType();

		String limbo_type = LimboType( java_type );

		return( fi_name +" : "+ limbo_type );
	}


	/**
	 * Accept a java Type descriptor and
	 * return a corresponding limbo type
	 * as a string. Return a empty string
	 * if the type is void or an unknown.
	 *
	 * @param java_t Java type
	 * 
	 * @return Limbo type
	 */
	private String LimboType( Class java_t )
	{
		String limbo_t;

		if ( java_t.isPrimitive() )
		{
			// a java primitive type convert to appropriate limbo type
			String t_name = java_t.getName();
			if ( t_name.equals( "short"   ) ||
				 t_name.equals( "char"    ) ||
				 t_name.equals( "int"     )    )
				limbo_t = "int";
			else if ( t_name.equals( "long" ) )
				limbo_t = "big";
			else if ( t_name.equals( "float" ) ||
					  t_name.equals( "double" )   )
				limbo_t = "real";
			else if ( t_name.equals( "byte"    ) ||
					  t_name.equals( "boolean" ) )
				limbo_t = "byte";
			else 
				limbo_t = ""; // void

		}
		else
		{
			// a java reference (i.e. object or array) 
			String t_name = java_t.getName();

			if ( t_name.startsWith( "[" ) )
				limbo_t = ArrayType( t_name );
			else 
				limbo_t = ClassName( t_name );
		}

		return( limbo_t );
	}
		
	private String ArrayType( String name )
	{
		StringBuffer aryname = new StringBuffer(20);
		aryname.append( T_JArray );

		char let = name.charAt(1);

		if ( let == 'L' )
		{
			// array of some class, determine Limo name
			aryname.append( ClassName( name.substring(2, name.length()-1) ) );
		}
		else if ( let == '[' )
		{
			// array of array...
			// we only care about first level
			;
		}
		else
			aryname.append( name.substring(1) ); //append type
			
		return( aryname.toString() );
	}


	private String ClassName( String clname )
	{
		// we treat some classes special and 
		// use specific Limbo adt's otherwise
		// use the generic JObject
		String sp_class = SpecialClass( clname );
		if ( sp_class != null )
			return( sp_class );
		else if ( "java.io.FileDescriptor".equals(clname) )
			return( T_JFd );
		else if ( "inferno.vm.FD".equals(clname) )
			return( T_JInfernoFD );
		else if ( clname.endsWith( base_name ) )
			return( "ref "+ obj_adt );
		return( T_JObject );
	}


	private String SpecialClass( String clname )
	{
		if ( "java.lang.String".equals(clname) )
			return( T_JString );
		else if ( "java.lang.Class".equals(clname) )
			return( T_JClass );
		else if ( "java.lang.Object".equals(clname) )
			return( T_JObject );
		else 
			return( null );
	}

	/** 
	 * Scan methods list and return list of
	 * native methods.
	 *
	 * @return Array of native methods, else array of length 0.
	 */
	private Method[] GetNatives( Method[] methods )
	{
		// walk the methods array and count natives
		int native_count = 0;
		for( int x=0; x<methods.length; x++ )
			if ( Modifier.isNative( methods[x].getModifiers() ) )
				native_count++;
		
		if ( native_count == 0 ) return( new Method[0] );

		if ( opt_verbose )
			System.out.println( "Native Methods:" );

		// now create an array to hold natives and fill it
		Method[] natives = new Method[native_count];
		native_count = 0;
		for( int x=0; x<methods.length; x++ )
			if ( Modifier.isNative( methods[x].getModifiers() ) )
			{
				natives[native_count++] = methods[x];
				if ( opt_verbose )
					System.out.println( "\t"+ methods[x] );
			}

		return( natives );
	}


	/**
	 * Scan fields list and return list of
	 * instance fields.
	 *
	 * @return Array of instnace fields, else array oflen 0
	 */
	private Field[] GetInstanceFields( Field[] fields )
	{
		// walk the fields array and count non-statics
		int count = 0;
		for( int x=0; x<fields.length; x++ )
			if ( ! Modifier.isStatic( fields[x].getModifiers() ) )
				count++;
		
		if ( count == 0 ) return( new Field[0] );

		if ( opt_verbose )
			System.out.println( "Instance Fields:" );

		// now create an array to hold instance-fields and fill it
		Field[] iFields = new Field[count];
		count = 0;
		for( int x=0; x<fields.length; x++ )
			if ( ! Modifier.isStatic( fields[x].getModifiers() ) )
			{
				iFields[count++] = fields[x];
				if ( opt_verbose )
					System.out.println( "\t"+ fields[x] );
			}

		return( iFields );
	}


	/**
	 * Scan fields list and return list of
	 * static fields.
	 *
	 * @return Array of static fields, else array oflen 0
	 */
	private Field[] GetStaticFields( Field[] fields )
	{
		// walk the fields array and count non-statics
		int count = 0;
		for( int x=0; x<fields.length; x++ )
			if ( Modifier.isStatic( fields[x].getModifiers() ) )
				count++;
		
		if ( count == 0 ) return( new Field[0] );

		if ( opt_verbose )
			System.out.println( "Instance Fields:" );

		// now create an array to hold instance-fields and fill it
		Field[] sFields = new Field[count];
		count = 0;
		for( int x=0; x<fields.length; x++ )
			if ( Modifier.isStatic( fields[x].getModifiers() ) )
			{
				sFields[count++] = fields[x];
				if ( opt_verbose )
					System.out.println( "\t"+ fields[x] );
			}

		return( sFields );
	}


	private String ClassBaseName( String name )
	{
		// for java.lang.Object return Object
		// if last char is ';' strip it off (arrays)

		int start = name.lastIndexOf( '.' );
		int end   = name.lastIndexOf( ';' );

		// if neither found return name
		if ( (start == -1) && (end==-1) ) return( name );

		// adjust if ';' not found
		end = ( (end==-1)? name.length() : end );

		return( name.substring( start+1, end ) );
	}


	private String MkFctName( Method meth )
	{
		// build name from java method name
		// java method param types, and the
		// java method return type

		StringBuffer encode = new StringBuffer(50);  
		encode.append(meth.getName());

		// append parmeter encoding
		Class[] jparam = meth.getParameterTypes();
		for( int x=0; x<jparam.length; x++ )
		{
			encode.append( "_" );
			encode.append( JTypeEncode( jparam[x] ) );
		}

		// append the method return type encoding
		encode.append("_");
		encode.append( JTypeEncode( meth.getReturnType() ) );

		if ( opt_verbose )
			System.out.println( "--mangled fct name:"+ encode );

		return( encode.toString() );
	}


	private String JTypeEncode( Class jtype )
	{
		String t_name;   //types name
		String encode = "";   //limbo encoding

		if ( jtype.isPrimitive() )
		{
			// a java primitive type convert to appropriate limbo type
			t_name = jtype.getName();
		
			// determine 
			if ( t_name.equals( "int" ) )
				encode = "I";
			else if ( t_name.equals( "char" ) )
				encode = "C";
			else if ( t_name.equals( "short" ) )
				encode = "S";
			else if ( t_name.equals( "long" ) )
				encode = "J";
			else if ( t_name.equals( "boolean" ) )
				encode = "Z";
			else if ( t_name.equals( "byte" ) )
				encode = "B";
			else if ( t_name.equals( "float" ) )
				encode = "F";
			else if ( t_name.equals( "double" ) )
				encode = "D";
			else
				encode = "V";
		}
		else
		{
			// a java reference (i.e. object or array) 
			t_name = jtype.getName();

			if ( t_name.indexOf( '[' ) == -1 )
			{
				// just an object reference
				encode = "r"+ ClassBaseName( t_name );
			}
			else
			{
				// array
				int x=0;
				StringBuffer buf = new StringBuffer(40);
				while( t_name.charAt(x)== '[' )
				{
					buf.append('a');
					x++;
				}
				if ( t_name.charAt(x) == 'L' )
					buf.append( ClassBaseName(t_name.substring(x+1)) );
				else
					buf.append( t_name.substring(x) );
				encode = buf.toString();
			}
		}

		return( encode );
	}


	private DataOutputStream MkFile( String name ) throws IOException
	{
		File             f     = new File( name );
		FileOutputStream fout;

		tmpname = "tmp_"+ name; 

		if ( f.exists() )
		{
			fout  = new FileOutputStream( tmpname );
			merge = true;
		}
		else
			fout = new FileOutputStream( name );

		return( new DataOutputStream( fout ) );
	}

	private void Emit( String info ) throws IOException
	{
		out.writeBytes( info );
	}


	// data fields
	private String base_name;     // name of class
	private String mod_name;      // module name of native "peer" module
	private String limbo_dotm;    // name of limbo module decl .m file
	private String limbo_dotb;    // name of limbo module impl .b file
	private String obj_adt;       // adt describing objects instance fields
	private boolean special;      // set true if a special class; a special
	                              // class is one known to this tool.

	Class    theClass; // class descriptor object

	DataOutputStream out;           // current gen output file
	boolean          merge = false; // merge old and new gen'ed files
	String           tmpname;

	Method[] methods;               // all methods
	Method[] natives;               // native methods

	Field[]  fields;   // all fields
	Field[]  iFields;  // instance fields
	Field[]  sFields;  // static fields

	boolean  opt_verbose;         // print stuff if true
	boolean  has_natives;         // set true if class has native methods

	// consts
	private static final String T1 = "    ";
	private static final String T2 = "        ";
	private static final String T3 = "            ";

	// generated Limbo/Java type names
	private static final String T_JObject         = "JObject";
	private static final String T_JString         = "JString";
	private static final String T_JClass          = "JClass";
	private static final String T_JArrayI        = "JArrayI";
	private static final String T_JArrayC        = "JArrayC";
	private static final String T_JArrayS        = "JArrayS";
	private static final String T_JArrayB        = "JArrayB";
	private static final String T_JArrayJ        = "JArrayJ";
	private static final String T_JArrayF        = "JArrayF";
	private static final String T_JArrayD        = "JArrayD";
	private static final String T_JArrayZ        = "JArrayZ";
	private static final String T_JArrayJObject  = "JArrayJObject";
	private static final String T_JArrayJClass   = "JArrayJClass";
	private static final String T_JArrayJString  = "JArrayJString";
	private static final String T_JArray          = "JArray";
	private static final String T_JFd             = "ref FileDescriptor_obj";
	private static final String T_JInfernoFD      = "ref Sys->FD";

}
