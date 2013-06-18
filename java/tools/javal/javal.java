package javal;
// Copyright (c) Lucent Technologies 1997
// Revisions copyright (c) Vita Nuova Holdings Limited 2004

import java.lang.reflect.*;
import java.io.FileInputStream;
import java.io.File;
import java.io.IOException;


public
class javal
{

	private static java.io.PrintStream out = System.out;

	private static boolean opt_verbose   = false;
	private static boolean opt_classinfo = false;   //dump class info
	private static boolean opt_module    = false;   //create Limbo mod (.m)
	private static boolean opt_impl      = false;   //create Limbo impl skeleton (.b)


	public static void main( String[] args )
	{
		int args_len = args.length;

		if ( (args_len < 1) || (args_len > 2) )
			error( "wrong args", true );

		if ( args_len == 2 )
			SetArgs( args[0] );

		// class to create limbo module for
		String targ_name  = args[args_len-1];
		Class  targ_class = null;

		try
		{
			TargetLoader tl = new TargetLoader( opt_verbose );
			targ_class = tl.loadClass( targ_name, false );
		}
		catch ( NoClassDefFoundError ee )
		{
			ee.printStackTrace();
			error( "ERROR: Class "+ targ_name +" not found.", false );
		}
		catch ( ClassNotFoundException ee )
		{
			error( "Error: Class "+ targ_name +" not found: "+ ee.getMessage(), false );
		}
		catch ( Exception ee )
		{
			error( "Error: Could not load class "+ targ_name +".", false );
		}

		out.println( "Class Name: "+ targ_class );

		Field[]   fields  = GetFields( targ_class );
		Method[]  methods = GetMethods( targ_class);

		if ( opt_classinfo )
		{
			Dump( "Fields", fields );
			Dump( "Methods", methods );
		}

		if ( opt_module || opt_impl )
		{
			try
			{
				LimboGen limbogen = new LimboGen( targ_class, fields, methods, opt_verbose );

				if ( opt_module )
					limbogen.DotM();

				if ( opt_impl )
					limbogen.DotB();
			}
			catch ( RuntimeException ee )
			{
				System.err.println( "Error: internal error: "+ ee );
				ee.printStackTrace();
				error( "...too bad.", false );
			}
			catch ( Exception ee )
			{
				error( "Error: could not generate limbo file: "+ ee, false );
			}
			
		}

	}


	/**
	 * Get all data fields for the class and
	 * all of his ancestors.
	 */
	private static Field[] GetFields( Class c )
	{
		if ( c == null ) return( new Field[0] );

		Class sup = c.getSuperclass();
		Field[] sup_f = GetFields( sup );
				
		Field[] f = c.getDeclaredFields();

		return( (Field[])ConcatArray( sup_f, f ) );
	}


	/**
	 * Get methods for the specified class 
	 * only (i.e. don't care about ancestor's)
	 */
	private static Method[] GetMethods( Class c )
	{
		return( c.getDeclaredMethods() );
	}


	private static Object ConcatArray( Object[] a1, Object[] a2 )
	{
		if ( (a2 == null) || (a2.length==0) ) return( a1 );
		if ( (a1 == null) || (a1.length==0) ) return( a2 );
		
		int[] dim = {a1.length+a2.length};
		Object a = Array.newInstance( a1[0].getClass(), dim );
 
 		System.arraycopy( a1, 0, a, 0, a1.length );
		System.arraycopy( a2, 0, a, a1.length, a2.length );

		return( a );
	}


	private static void Dump( String title, Object[] ary )
	{
		System.out.println( title );
		for(int x=0; x<ary.length; x++ )
		{
			System.out.println( "\t"+ ary[x] );
		}
	}

	private static void SetArgs( String opts )
	{
		
		if ( (opts.length() > 5) || 
		     (opts.length() < 2) ||
			 (! opts.startsWith("-")) )
			 error( "Error: bad options", true );

		opt_verbose   = opts.indexOf( "v" ) != -1;
		opt_classinfo = opts.indexOf( "c" ) != -1;
		opt_module    = opts.indexOf( "m" ) != -1;
		opt_impl      = opts.indexOf( "b" ) != -1;

		if ( opt_verbose )
			Runtime.getRuntime().traceMethodCalls(true);
	}


	private static void error( String msg, boolean usage )
	{
		out.println( msg );
		if ( usage )
		{
			out.println( "  javal [-vcmb] <class name>" );
		}
		System.exit(1);
	}
}
			
/**
 * This loader simply reads from a disk based
 * .class file in the "current" directory. It
 * only accepts the base name of the class,
 * appends ".class" and reads the file. The
 * purpose is to allow classes like "String.java"
 * to be read and queried, where the class
 * is different then the one used by this
 * program.  This tool is used to develop a
 * new java class library and this class loader
 * avoids the conflics of using a java based
 * tool to develop java classes, etc.
 */
class TargetLoader extends ClassLoader
{
	private boolean verbose;  
	private String  class_name = null;

	TargetLoader( boolean verbose )
	{
		this.verbose = verbose;
	}

	public Class loadClass( String name, boolean resolve ) throws ClassNotFoundException
	{

		// if we have already been here once
		// then load all other classes from the system
		if ( class_name != null )
		{
			return( findSystemClass( name ) );
		}

		// otherwise do our one time load from a disk file

		// read from the current directory the file "name".java
		class_name = name +".class";

		try
		{
			FileInputStream fin = new FileInputStream( class_name );
			
			int len = fin.available();  // how big is the file

			if ( len == 0 )
				throw new ClassNotFoundException( class_name );

			byte[] buf = new byte[len];
			
			fin.read( buf );  //read the .class file

			if ( verbose )
			{
				System.out.println( "loading class ["+ class_name +"]("+ len +")" );
			}

			// create class object and return it
			return( defineClass( buf, 0, buf.length ) );
		}
		catch ( IOException ee )
		{
			File f = new File( class_name );
			throw new ClassNotFoundException( "(path:"+f.getAbsolutePath() +")" );
		}
		catch ( Exception ee )
		{
			throw new ClassNotFoundException( ee.getMessage() );
		}
	}
}
