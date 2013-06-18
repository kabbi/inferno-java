implement File_L;

# javal v1.3 generated file: edit with care

include "jni.m";
    jni : JNI;
        ClassModule,
        JString,
        JArray,
        JArrayI,
        JArrayC,
        JArrayB,
        JArrayS,
        JArrayJ,
        JArrayF,
        JArrayD,
        JArrayZ,
        JArrayJObject,
        JArrayJClass,
        JArrayJString,
        JClass,
        JThread,
        JObject : import jni;

#>> extra pre includes here
    sys : import jni;
    str : import jni;
    FALSE : import jni;
    TRUE : import jni;
#<<

include "File_L.m";

#>> extra post includes here
include "workdir.m";
include "regex.m";
str_mod : String;
#<<

init( jni_p : JNI )
{
    # save java native inteface mod instance
    jni = jni_p;
    #>>extra initialization here
    sys = jni->sys;
    str_mod = jni->str;
    #<<
}

exists0_Z( this : ref File_obj) : int
{#>>
        (ok, nil) := sys->stat(this.path.str);
        if (ok == -1)
                return (FALSE);
        return (TRUE);
}#<<

canWrite0_Z( this : ref File_obj) : int
{#>>
        # this routine is real cludgy...try to open the file for writing
        # to see if you have WRITE access rights or not.

        local_fd := sys->open(this.path.str, sys->OWRITE);
        if (local_fd == nil)
                return (FALSE);
        return (TRUE);
}#<<

canRead0_Z( this : ref File_obj) : int
{#>>
        # this routine is real cludgy...try to open the file for reading
        # to see if you have READ access rights or not.

        local_fd := sys->open(this.path.str, sys->OREAD);
        if (local_fd == nil)
                return (FALSE);
        return (TRUE);
}#<<

isFile0_Z( this : ref File_obj) : int
{#>>
        (ok, dir) := sys->stat(this.path.str);
        if(ok >= 0 && !(dir.mode & Sys->CHDIR))
                return (TRUE);
        return (FALSE);
}#<<

isDirectory0_Z( this : ref File_obj) : int
{#>>
        (ok, dir) := sys->stat(this.path.str);
        if(ok >= 0 && (dir.mode & Sys->CHDIR))
                return (TRUE);
        return (FALSE);
}#<<

lastModified0_J( this : ref File_obj) : big
{#>>
        (ok, dir) := sys->stat(this.path.str);
        if(ok >= 0)
                return (big dir.mtime);
        return (big 0);
}#<<

length0_J( this : ref File_obj) : big
{#>>
        (ok, dir) := sys->stat(this.path.str);
        if(ok >= 0)
                return (big dir.length);
        return (big 0);
}#<<

mkdir0_Z( this : ref File_obj) : int
{#>>
        (ok, nil) := sys->stat(this.path.str);
        if(ok >= 0)
                return (FALSE);
        fd := sys->create(this.path.str, sys->OREAD, sys->CHDIR + 8r777);
        if(fd == nil)
                return (FALSE);
        fd = nil;
        return (TRUE);
}#<<

renameTo0_rFile_Z( this : ref File_obj, p0 : ref File_obj) : int
{#>>
	# this routine is based on the appl/cmd/mv command in inferno....

	#put from and to file names into complete path names
	frompath := pathname(this.path.str);
	topath := pathname(p0.path.str);

	#seperate the name of the file from the directory the files reside in
	(fromdir, fromname) := split(frompath);
	(todir, toname) := split(topath);

	(i, dirf) := sys->stat(this.path.str);
	if ( i == -1 )
		return FALSE;

	# are the files in the same directory????
	if ( samefile(fromdir, todir) ) {
		if ( toname == fromname )
			return TRUE;
		(j, dirt) := sys->stat(p0.path.str);
		if ( j == 0 ) {
			if ( (dirf.mode | dirt.mode) & Sys->CHDIR )
				return FALSE;
			hardremove(topath);
		}
		dirf.name = toname;
		if ( sys->wstat(this.path.str, dirf) >= 0 )
			return TRUE;
	}
	#open the from file....
	if ( (fdf := sys->open(this.path.str, Sys->OREAD)) == nil )
		return FALSE;

	#open the to file....
	if ( (fdt := sys->create(p0.path.str, Sys->OWRITE, dirf.mode)) == nil )
		return FALSE;;

	#copy data from from file to to file....
	if ( (stat := copy1(fdf, fdt)) == TRUE ) {
		fdf = nil;
		if ( sys->remove(this.path.str) < 0 )
			return FALSE;
	}
	else {
		fdt = nil;
		sys->remove(p0.path.str);
	}
	return stat;
}#<<

delete0_Z( this : ref File_obj) : int
{#>>
        if (isFile0_Z(this) == TRUE)
                return (remove0_b(this));
        return (FALSE);
}#<<

rmdir0_Z( this : ref File_obj) : int
{#>>
        if (isDirectory0_Z(this) == TRUE)
                return (remove0_b(this));
        return (FALSE);
}#<<

list0_aString( this : ref File_obj) : JArrayJString
{#>>
        fd := sys->open(this.path.str, sys->OREAD);
        if(fd == nil) {
                return nil;
        }
	
	dir_array := array[200] of Sys->Dir;
	n := 0;
	for(;;){
		if(len dir_array - n == 0){
			# expand dir_array
			nd := array[2 * len dir_array] of Sys->Dir;
			nd[0:] = dir_array;
			dir_array = nd;
		}
		nr := sys->dirread(fd, dir_array[n:]);
		if(nr < 0)
			return nil;
		if(nr == 0)
			break;
		n += nr;
	}
        file_name := array[n] of string;

        for(i := 0; i < n; i++)
                file_name[i] = dir_array[i].name;

	return (jni->MkAString(file_name));
}#<<

canonPath_rString_rString( this : ref File_obj, p0 : JString) : JString
{#>>
	TRACE_1 := this;  # to remove warning msg at compile time;

	path := pathname(p0.str) + "/";

	regex := load Regex Regex->PATH;
	if ( regex == nil )
		jni->InitError( sys->sprint( "java.io.File: could not load %s: %r", Regex->PATH ) );

	path = squeeze_out(regex, regex->compile("//", 0), "/", path);
	path = squeeze_out(regex, regex->compile("/\\./", 0), "/", path);
	path = squeeze_out(regex, regex->compile("/[^/]+/\\.\\./", 0), "/", path);

	if ( len path > 1 && path[len path - 1] == '/' )
		path = path[0:len path - 1];

	return (jni->NewString( path));
}#<<

isAbsolute_Z( this : ref File_obj) : int
{#>>
        if (str_mod->prefix("/", this.path.str))
                return (TRUE);
        return (FALSE);
}#<<





remove0_b( this : ref File_obj) : int
{
        if (sys->remove(this.path.str) < 0)
                return (FALSE);
        return (TRUE);
}

copy1(fdf, fdt : ref Sys->FD): int
{
	n : int;
	buf := array[8192] of byte;

	for ( ; ; ) {
		n = sys->read(fdf, buf, len buf);
		if (n<=0)
			break;
		n1 := sys->write(fdt, buf, n);
		if ( n1 != n )
			return FALSE;
	}
	if ( n < 0 )
		return FALSE;
	return TRUE;
}

#convert a file name into complete path name
pathname(p : string) : string
{
	if ( p == nil || p[0] == '/' )
		return p;
	gwd := load Workdir Workdir->PATH;
	if ( gwd == nil )
		jni->InitError( sys->sprint( "java.io.File: could not load %s: %r", Workdir->PATH ) );

	wd := gwd->init();
	if ( len wd == 0 )
		return p;
	return wd + "/" + p;
}

#pull out the name of the file only
split(name : string): (string,string)
{
	(d,t) := str_mod->splitr(name, "/");
	if ( d != nil )
		return(d,t);
	else if ( name == ".." )
		return("../",".");
	else
		return("./",name);
}

# return TRUE if file a is same as file b
samefile(a,b : string): int
{
	if ( a == b ) 
		return 1;
	(i, file_a) := sys->stat(a);
	(j, file_b) := sys->stat(b);
	if ( i < 0 || j < 0 )
		return 0;
	i = ((file_a.qid.path == file_b.qid.path) && (file_a.qid.vers == file_b.qid.vers) &&
		(file_a.dev == file_b.dev) && (file_a.dtype == file_b.dtype));
	return i;
}

hardremove(a: string)
{
	do; while ( sys->remove(a) != -1 );
}

squeeze_out(r : Regex, pat : Regex->Re, repl, str :string) : string
{
	while ( str_mod->prefix("/../", str) )
		str = str[3:];
	a := r->execute(pat, str);
	if (a == nil)
		return str;
	(beg, end) := a[0];
	str = str[0:beg] + repl + str[end:];
	return squeeze_out(r, pat, repl, str);
}
