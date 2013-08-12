implement Reflection_L;

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
        JObject,
        Value : import jni;

#>> extra pre includes here

#<<

include "Reflection_L.m";

#>> extra post includes here

#<<

init( jni_p : JNI )
{
    # save java native inteface mod instance
    jni = jni_p;
    #>>extra initialization here
    #<<
}

getClassAccessFlags_rClass_I( p0 : JClass) : int
{#>>
    return 0;
}#<<

shouldskip(class: string): int
{
    skipclasses := array [] of {
        "classloader.dis",
        "javaassist.dis",
        "jvm.dis",
        "low.dis",
        "jni.dis",
        "sh.dis"
    };
    for (i := 0; i < len skipclasses; i++) {
        l := len skipclasses[i];
        # Check the string suffix equality
        if (len class >= l && class[len class - l :] == skipclasses[i])
            return 1;
    }
    return 0;
}
getstack(pid: int, ch: chan of list of string)
{
    stoppid(pid);

    # Read stacktrace
    stackfd := jni->sys->open("/prog/" + string pid + "/stack", jni->sys->OREAD);
    buf := array [4096] of byte;
    jni->sys->read(stackfd, buf, len buf);
    stack := string buf;
    # And then parse the data line by line 
    (nil, lines) := jni->sys->tokenize(stack, "\n");
    stacklines: list of string;
    for (it := lines; it != nil; it = tl it) {
        (nitems, items) := jni->sys->tokenize(hd it, " ");
        # Six's column is module name
        if (nitems != 6)
            continue;
        stackclass := hd tl tl tl tl tl items;
        # Skip jvm modules
        if (!shouldskip(stackclass))
            stacklines = stackclass :: stacklines;
    }

    # Reverse the list
    result: list of string;
    for (it = stacklines; it != nil; it = tl it)
        result = hd it :: result;

    resumepid(pid);

    ch <-= result;
}

progcmd(pid: int, cmd: string)
{
    dbgfd := jni->sys->open("/prog/" + string pid + "/dbgctl", jni->sys->ORDWR);
    jni->sys->fprint(dbgfd, "%s", cmd);
}
stoppid(pid: int)
{
    progcmd(pid, "stop");
}
resumepid(pid: int)
{
    progcmd(pid, "unstop");
}

classname(stackitem: string): string
{
    if (len stackitem > 2 && stackitem[:2] == "N-")
        return stackitem[2:];
    return stackitem;
}
forname(class: string): JClass
{
    {
        if (class != nil && class[0] == '[')
            return jni->LookupArrayClass(class);
        else
            return jni->GetClassObject(jni->InternalFindClass(class));
    }
    exception e {
        "JLD:e0*" =>
            jni->ThrowException( "java.lang.ClassNotFoundException", class);
    }
    
    return nil;
}
 
getCallerClass_I_rClass( p0 : int) : JClass
{#>>
    # Some really dumb implementation
    # TODO: think of better way to do this
    pid := jni->sys->pctl(0, nil);
    return nil;

    stackch := chan of list of string;
    spawn getstack(pid, stackch);
    trace := <-stackch;

    idx := 0;
    for (it := trace; it != nil; it = tl it) {
        if (idx++ == p0) {
            class := classname(hd it);
            jni->sys->fprint(jni->sys->fildes(2), "Returning '%s'\n", class);
            return forname(class);
        }
    }
    
    return nil;
}#<<

