#include "java.h"

/*
 * Class loader.
 */

Class	*class;		/* class under translation */
PCode	*pcode;		/* pointers to byte code of defined methods */
char	*THISCLASS;
char	*SUPERCLASS;

char*
CLASSNAME(int i)
{
	return class->cps[class->cps[i].ci.name_index].utf8.utf8;
}

char*
STRING(int i)
{
	return class->cps[i].utf8.utf8;
}

typedef	union Fc	Fc;

union Fc
{
	float	f;
	uint	ival;
};

static double
canontod(uint v[])
{
	union { double d; uint ui[2]; } a;

	a.d = 1.;
	if(a.ui[0]) {
		a.ui[0] = v[0];
		a.ui[1] = v[1];
	} else {
		a.ui[0] = v[1];
		a.ui[1] = v[0];
	}
	return a.d;
}

/*
 * Bytecode verification.
 */

static void
verifyutf8index(int index)
{
	verifycpindex(nil, index, 1 << CON_Utf8);
	if(STRING(index) == nil)
		verifyerrormess("nil name or descriptor");
}

static void
verifyclassindex(int index)
{
	verifycpindex(nil, index, 1 << CON_Class);
	verifyutf8index(class->cps[index].ci.name_index);
}

static void
verifyfielddesc(int name_index, int sig_index)
{
	char *sig;
	char ftype;

	verifyutf8index(name_index);
	verifyutf8index(sig_index);
	sig = STRING(sig_index);
	ftype = sig[0];
	sig = nextjavatype(sig);
	if(ftype == 'V' || sig[0] != '\0')
		verifyerrormess("field descriptor");
}

static void
verifymethoddesc(int name_index, int sig_index)
{
	char *name, *sig;
	char rtype;
	int wargs;

	verifyutf8index(name_index);
	name = STRING(name_index);
	verifyutf8index(sig_index);
	sig = STRING(sig_index);

	/* check special <method> names */
	if(name[0] == '<') {
		if(strcmp(name, "<init>") == 0)
			;
		else if(strcmp(name, "<clinit>") == 0) {
			if(strcmp(sig, "()V") != 0)
				verifyerrormess("<clinit> signature");
			return;
		} else
			verifyerrormess("<method> name");
	}

	/* check signature */
	if(sig[0] != '(')
		goto bad;
	sig++;
	wargs = 0;
	while(sig[0] != ')') {
		wargs++;
		if(sig[0] == 'J' || sig[0] == 'D')
			wargs++;
		sig = nextjavatype(sig);
	}
	sig++;
	rtype = sig[0];
	sig = nextjavatype(sig);
	if(wargs > 255 || sig[0] != '\0' || (name[0] == '<' && rtype != 'V'))
bad:		verifyerrormess("method descriptor");
}

static void
verifycpindexes(void)
{
	int i;
	Const *cp;
	int nameindex, sigindex, natindex;

	for(i = 1; i < class->cp_count; i++) {
		cp = &class->cps[i];
		switch(class->cts[i]) {
		case CON_Class:
			verifyutf8index(cp->ci.name_index);
			break;
		case CON_Fieldref:
		case CON_Methodref:
		case CON_InterfaceMref:
			verifyclassindex(cp->fmiref.class_index);
			natindex = cp->fmiref.name_type_index;
			verifycpindex(nil, natindex, 1 << CON_NameAndType);
			nameindex = class->cps[natindex].nat.name_index;
			sigindex = class->cps[natindex].nat.sig_index;
			if(class->cts[i] == CON_Fieldref)
				verifyfielddesc(nameindex, sigindex);
			else
				verifymethoddesc(nameindex, sigindex);
			break;
		case CON_String:
			verifycpindex(nil, cp->string_index, 1 << CON_Utf8);
			break;
		case CON_Integer:
		case CON_Float:
		case CON_NameAndType:
			/*
			 * CON_NameAndType is verified through
			 * CON_Fieldref, CON_Methodref, CON_InterfaceMref
			 */
		case CON_Utf8:
			break;
		case CON_Long:
		case CON_Double:
			i++;
			break;
		}
	}
}

#define CLASSMUTEX	(ACC_FINAL|ACC_ABSTRACT)

static void
verifyclassflags(void)
{
	int bad;

	if(class->access_flags & ACC_INTERFACE) {
		if(strcmp(SUPERCLASS, "java/lang/Object") != 0)
			verifyerrormess("superclass");
		/* java bug: ACC_ABSTRACT should be set ???
		bad = (class->access_flags & ACC_ABSTRACT) != ACC_ABSTRACT;
		*/
		bad = 0;
		bad += (class->access_flags & ACC_FINAL) != 0;
	} else {
		bad = (class->access_flags & CLASSMUTEX) == CLASSMUTEX;
	}
	if(bad)
		verifyerrormess("access_flags");
}

static int
multippp(int flag)
{
	int ret;

	switch(flag & (ACC_PUBLIC|ACC_PRIVATE|ACC_PROTECTED)) {
	case 0:
	case ACC_PUBLIC:
	case ACC_PRIVATE:
	case ACC_PROTECTED:
		ret = 0;
		break;
	default:
		ret = 1;
		break;
	}
	return ret;
}

#define IFACEFIELD	(ACC_PUBLIC|ACC_STATIC|ACC_FINAL)
#define _IFACEFIELD	(ACC_PRIVATE|ACC_PROTECTED|ACC_VOLATILE|ACC_TRANSIENT)
#define FIELDMUTEX	(ACC_FINAL|ACC_VOLATILE)
#define CVATTRTAGS	((1<<CON_Integer)|(1<<CON_Long)|(1<<CON_Float)|(1<<CON_Double)|(1<<CON_String))

static void
verifyfield(Field *fp)
{
	int bad, n;
	char c;

	verifyfielddesc(fp->name_index, fp->sig_index);
	if(class->access_flags & ACC_INTERFACE) {
		bad = (fp->access_flags & _IFACEFIELD) != 0;
		bad += (fp->access_flags & IFACEFIELD) != IFACEFIELD;
	} else {
		bad = multippp(fp->access_flags);
		bad += (fp->access_flags & FIELDMUTEX) == FIELDMUTEX;
	}
	if(bad)
		verifyerrormess("access_flags");

	/* verify ConstantValue attribute */
	n = CVattrindex(fp);
	if(n == 0)
		return;
	verifycpindex(nil, n, CVATTRTAGS);
	c = STRING(fp->sig_index)[0];
	switch(class->cts[n]) {
	case CON_Integer:
		switch(c) {
		case 'Z':
		case 'B':
		case 'C':
		case 'S':
		case 'I':
			bad = 0;
			break;
		default:
			bad = 1;
			break;
		}
		break;
	case CON_Long:
		bad = (c != 'J');
		break;
	case CON_Float:
		bad = (c != 'F');
		break;
	case CON_Double:
		bad = (c != 'D');
		break;
	case CON_String:
		bad = (c != 'L');
		break;
	}
	if(bad)
		verifyerrormess("ConstantValue attribute");
}

#define IFACEMETHOD	(ACC_PUBLIC|ACC_ABSTRACT)
#define _IFACEMETHOD	(ACC_PRIVATE|ACC_PROTECTED|ACC_STATIC|ACC_FINAL|ACC_SYNCHRONIZED|ACC_NATIVE)
#define _INITFLAGS	(ACC_STATIC|ACC_FINAL|ACC_SYNCHRONIZED|ACC_NATIVE|ACC_ABSTRACT)
/* java bug: ACC_SYNCHRONIZED wrongly allowed with ACC_ABSTRACT ???
#define METHODMUTEX	(ACC_PRIVATE|ACC_STATIC|ACC_FINAL|ACC_SYNCHRONIZED|ACC_NATIVE)
*/
#define METHODMUTEX	(ACC_PRIVATE|ACC_STATIC|ACC_FINAL|ACC_NATIVE)

static void
verifymethod(Method *mp)
{
	int bad;
	char *name;

	verifymethoddesc(mp->name_index, mp->sig_index);
	name = STRING(mp->name_index);
	if(strcmp(name, "<clinit>") == 0)
		return;
	if(class->access_flags & ACC_INTERFACE) {
		bad = (mp->access_flags & _IFACEMETHOD) != 0;
		bad += (mp->access_flags & IFACEMETHOD) != IFACEMETHOD;
	} else {
		bad = multippp(mp->access_flags);
		if(strcmp(name, "<init>") == 0)
			bad += (mp->access_flags & _INITFLAGS) != 0;
		if(mp->access_flags & ACC_ABSTRACT)
			bad += (mp->access_flags & METHODMUTEX) != 0;
	}
	if(bad)
		verifyerrormess("access_flags");
	/*
	 * Code attribute verified during disassembly
	 * ignore Exceptions attribute for now
	 */
}

/*
 * Parse a byte stream into a Class stucture.
 */

static void
byte2Class(uchar *text)
{
	Fc fc;
	uint v[2];
	int i, j;
	Field *fp;
	Method *mp;
	Const *cp;
	Attr a;

	uSet(text);
	class = Malloc(sizeof(Class));

	if(u4() != 0xCAFEBABE)
		verifyerrormess("magic");

	class->min = u2();
	class->maj = u2();

	class->cp_count = u2();
	class->cps = Mallocz(class->cp_count*sizeof(Const));
	class->cts = Mallocz(class->cp_count);

	for(i = 1; i < class->cp_count; i++) {
		cp = &class->cps[i];
		class->cts[i] = u1();
		switch(class->cts[i]) {
		case CON_Class:
			cp->ci.name_index = u2();
			break;
		case CON_Fieldref:
		case CON_Methodref:
		case CON_InterfaceMref:
			cp->fmiref.class_index = u2();
			cp->fmiref.name_type_index = u2();
			break;
		case CON_String:
			cp->string_index = u2();
			break;
		case CON_Integer:
			cp->tint = u4();
			break;
		case CON_Float:
			fc.ival = (uint)u4();
			cp->tdouble = fc.f;
			break;
		case CON_Long:
			cp->tvlong = ((vlong)u4()<<32) | (vlong)u4();
			i++;
			break;
		case CON_Double:
			v[0] = (uint)u4();
			v[1] = (uint)u4();
			cp->tdouble = canontod(v);
			i++;
			break;
		case CON_NameAndType:
			cp->nat.name_index = u2();
			cp->nat.sig_index = u2();
			break;
		case CON_Utf8:
			cp->utf8.ln = u2();
			cp->utf8.utf8 = Malloc(cp->utf8.ln+1);
			memmove(cp->utf8.utf8, uPtr(), cp->utf8.ln);
			cp->utf8.utf8[cp->utf8.ln] = '\0';
			uN(cp->utf8.ln);
			break;
		default:
			verifyerrormess("constant pool tag");
		}
	}

	verifycpindexes();		/* verify after all are established */

	class->access_flags = u2();	/* verify after [THIS|SUPER]CLASS set */

	class->this_class = u2();
	verifyclassindex(class->this_class);
	THISCLASS = CLASSNAME(class->this_class);

	class->super_class = u2();
	if(class->super_class != 0) {
		verifyclassindex(class->super_class);
		SUPERCLASS = CLASSNAME(class->super_class);
	} else if(strcmp(THISCLASS, "java/lang/Object") != 0)
		verifyerrormess("superclass");

	verifyclassflags();

	/* for compatibility with JavaSoft VM */
	if(strncmp(THISCLASS, "inferno/vm/", sizeof("inferno/vm/")-1) == 0) {
		/*
		 * ACC_ABSTRACT & ACC_FINAL are both set in JVM,
		 * but a class can't be declared that way
		 */
		class->access_flags |= ACC_ABSTRACT;
		/*
		 * ACC_SUPER not set in JVM, but javac sets it
		 * for inferno/vm/Array
		 */
		class->access_flags &= ~ACC_SUPER;
	} else if(class->access_flags & ACC_INTERFACE) {
		/* interfaces are implicitly abstract */
		class->access_flags |= ACC_ABSTRACT;
	}

	class->interfaces_count = u2();
	if(class->interfaces_count > 0)
		class->interfaces = Malloc(class->interfaces_count*sizeof(ushort));
	for(i = 0; i < class->interfaces_count; i++) {
		class->interfaces[i] = u2();
		verifyclassindex(class->interfaces[i]);
	}

	class->fields_count = u2();
	if(class->fields_count > 0)
		class->fields = Malloc(class->fields_count*sizeof(Field));
	for(i = 0, fp = class->fields; i < class->fields_count; i++, fp++) {
		fp->access_flags = u2();
		fp->name_index = u2();
		fp->sig_index = u2();
		fp->attr_count = u2();
		if(fp->attr_count > 0)
			fp->attr_info = Malloc(fp->attr_count*sizeof(Attr));
		for(j = 0; j < fp->attr_count; j++)
			getattr(&fp->attr_info[j]);
		verifyfield(fp);
	}

	class->methods_count = u2();
	if(class->methods_count > 0) {
		class->methods = Malloc(class->methods_count*sizeof(Method));
		pcode = Mallocz(class->methods_count*sizeof(PCode));
	}
	for(i = 0, mp = class->methods; i < class->methods_count; i++, mp++) {
		mp->access_flags = u2();
		mp->name_index = u2();
		mp->sig_index = u2();
		mp->attr_count = u2();
		if(mp->attr_count > 0)
			mp->attr_info = Malloc(mp->attr_count*sizeof(Attr));
		for(j = 0; j < mp->attr_count; j++)
			getattr(&mp->attr_info[j]);
		verifymethod(mp);
	}

	/* get SourceFile attribute */
	class->source_file = 0;
	i = u2();
	for(j = 0; j < i; j++) {
		getattr(&a);
		if(strcmp(STRING(a.name), "SourceFile") == 0) {
			class->source_file = (a.info[0] << 8) | a.info[1];
			verifyutf8index(class->source_file);
			free(a.info);
			break;
		}
		free(a.info);
	}
}

/*
 * Return Class structure for named class.
 */

void
ClassLoader(char *name)
{
	int fd;
	Dir dir;
	uchar *bytecode;

	fd = open(name, OREAD);
	if(fd < 0)
		fatal("ClassLoader: can't open %s: %r\n", name);

	if(dirfstat(fd, &dir) < 0)
		fatal("ClassLoader: can't stat %s: %r\n", name);

	bytecode = Malloc(dir.length);
	if(read(fd, bytecode, dir.length) != dir.length)
		fatal("ClassLoader: read %s: %r\n", name);

	byte2Class(bytecode);

	close(fd);
	free(bytecode);
}

/*
 * Print access flag mnemonics.
 */

static void
accessflags(int flags, int isclass)
{
	if(flags == 0)
		return;
	Bputc(bout, '\t');
	if(flags & ACC_PUBLIC)
		Bprint(bout, "|public");
	if(flags & ACC_PRIVATE)
		Bprint(bout, "|private");
	if(flags & ACC_PROTECTED)
		Bprint(bout, "|protected");
	if(flags & ACC_STATIC)
		Bprint(bout, "|static");
	if(flags & ACC_FINAL)
		Bprint(bout, "|final");
	if(flags & ACC_SUPER) {	/* ACC_SYNCHRONIZED == ACC_SUPER */
		if(isclass)
			Bprint(bout, "|super");
		else
			Bprint(bout, "|synchronized");
	}
	if(flags & ACC_VOLATILE)
		Bprint(bout, "|volatile");
	if(flags & ACC_TRANSIENT)
		Bprint(bout, "|transient");
	if(flags & ACC_NATIVE)
		Bprint(bout, "|native");
	if(flags & ACC_INTERFACE)
		Bprint(bout, "|interface");
	if(flags & ACC_ABSTRACT)
		Bprint(bout, "|abstract");
	Bputc(bout, '|');
}

/*
 * Print out the constant pool (-c option).
 */

void
dumpcpool(void)
{
	int i, n;
	Field *fp;
	Method *mp;
	Const *cp;

	Bprint(bout, "# -- Constant Pool Start --\n");
	Bprint(bout, "# minor: %d\n", class->min);
	Bprint(bout, "# major: %d\n", class->maj);

	Bprint(bout, "# constant pool count: %d\n", class->cp_count);

	for(i = 1; i < class->cp_count; i++) {
		Bprint(bout, "# %d ", i);
		cp = &class->cps[i];
		switch(class->cts[i]) {
		case CON_Class:
			Bprint(bout, "Class %d", cp->ci.name_index);
			Bprint(bout, "\t\"%s\"\n",
				STRING(cp->ci.name_index));
			break;
		case CON_Fieldref:
			Bprint(bout, "Field Ref %d %d\n",
				cp->fmiref.class_index, cp->fmiref.name_type_index);
			break;
		case CON_Methodref:
			Bprint(bout, "Method Ref %d %d\n",
				cp->fmiref.class_index, cp->fmiref.name_type_index);
			break;
		case CON_InterfaceMref:
			Bprint(bout, "InterfaceMethod Ref %d %d\n",
				cp->fmiref.class_index, cp->fmiref.name_type_index);
			break;
		case CON_String:
			Bprint(bout, "String %d", cp->string_index);
			Bprint(bout, "\t\"");
			pstring(STRING(cp->string_index));
			Bprint(bout, "\"\n");
			break;
		case CON_Integer:
			Bprint(bout, "Int %d\n", cp->tint);
			break;
		case CON_Float:
			Bprint(bout, "Float %g\n", cp->tdouble);
			break;
		case CON_Long:
			Bprint(bout, "Long %lld\n", cp->tvlong);
			i++;
			break;
		case CON_Double:
			Bprint(bout, "Double %g\n", cp->tdouble);
			i++;
			break;
		case CON_NameAndType:
			Bprint(bout, "N&T %d %d",
				cp->nat.name_index, cp->nat.sig_index);
			Bprint(bout, "\t\"%s\", \"%s\"\n",
				STRING(cp->nat.name_index),
				STRING(cp->nat.sig_index));
			break;
		case CON_Utf8:
			Bprint(bout, "utf8 \"");
			pstring(cp->utf8.utf8);
			Bprint(bout, "\"\n");
			break;
		}
	}

	Bprint(bout, "# access flags: %d", class->access_flags);
	accessflags(class->access_flags, 1);
	Bputc(bout, '\n');

	Bprint(bout, "# this_class: %d\t\"%s\"\n",
		class->this_class, THISCLASS);
	Bprint(bout, "# super_class: %d", class->super_class);
	if(SUPERCLASS)
		Bprint(bout, "\t\"%s\"", SUPERCLASS);
	Bputc(bout, '\n');

	Bprint(bout, "# interfaces: %d\n", class->interfaces_count);
	for(i = 0; i < class->interfaces_count; i++) {
		Bprint(bout, "#\t%s\n", CLASSNAME(class->interfaces[i]));
	}

	Bprint(bout, "# fields: %d\n", class->fields_count);
	for(i = 0, fp = class->fields; i < class->fields_count; i++, fp++) {
		Bprint(bout, "#\t%s: %s", STRING(fp->name_index),
			STRING(fp->sig_index));
		accessflags(fp->access_flags, 0);
		Bputc(bout, '\n');
		n = CVattrindex(fp);
		if(n == 0)
			continue;
		Bprint(bout, "#\t\tConstantValue: ");
		cp = &class->cps[n];
		switch(class->cts[n]) {
		case CON_Integer:
			Bprint(bout, "Int %d\n", cp->tint);
			break;
		case CON_Long:
			Bprint(bout, "Long %lld\n", cp->tvlong);
			break;
		case CON_Float:
			Bprint(bout, "Float %g\n", cp->tdouble);
			break;
		case CON_Double:
			Bprint(bout, "Double %g\n", cp->tdouble);
			break;
		case CON_String:
			Bprint(bout, "String \"%s\"\n",
				STRING(cp->ci.name_index));
			break;
		}
	}

	Bprint(bout, "# methods: %d\n", class->methods_count);
	for(i = 0, mp = class->methods; i < class->methods_count; i++, mp++) {
		Bprint(bout, "# %d Method %d sig %d",
			i, mp->name_index, mp->sig_index);
		Bprint(bout, "\t%s%s", STRING(mp->name_index),
			STRING(mp->sig_index));
		accessflags(mp->access_flags, 0);
		Bputc(bout, '\n');
	}

	Bprint(bout, "# class attribute ignored\n");
	Bprint(bout, "# -- Constant Pool End --\n");
}
