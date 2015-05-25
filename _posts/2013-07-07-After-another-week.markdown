---
layout: post
title:  "After another week"
date: 2013.07.07 23:13:10
categories: gsoc
---

The issue of the day: Class loading is still very difficult to implement.  
&nbsp;  
Last week I spent trying to implement ldc instruction for Class loading. I was reading lots of the code and trying to understand how it works. I found several ways to do that: run static method Class.forName (implement it as translate-time code), and provide a string of class to load. But that needs some runtime modifications of class constants table, relocation tables and some other things which is not really trivial. Another way is to pass that task to the runtime code, so that translator will call classloader's 'getclassclass' function at runtime to get the Class object. This approach is also much simpler to debug, as we can just change runtime part and not re-translate class code. So, I've chosen the second variant. I made some research at how translator makes relocations and calls loader functions, and as a result I have this ldc handler:

    xgetclass(a: ref Addr, class: int)
    {
      imframe, iindw, i: ref Inst;
      n, rtflag: int;
      rtc: ref RTClass;
      cr: ref Creloc;
      frm, frf: ref Freloc;
      ai: ref ArrayInfo;

      # Ensure that Class is loaded
      rtc = getRTClass(RCLASSCLASS);
      callrtload(rtc, RCLASSCLASS);

      cr = getCreloc(RLOADER);
      frm = getFreloc(cr, RMP, nil, 0);
      frf = getFreloc(cr, "getclassclass", nil, 0);

      imframe = loadermframe(frm, frf);

      # 1st arg: our name

      i = newi(IMOVP);
      addrsind(i.s, Amp, mpstring(THISCLASS));
      addrdind(i.d, Afpind, imframe.d.offset, REGSIZE);
      datareloc(i);

      # 2nd arg: the name of Class to load

      i = newi(IMOVP);
      addrsind(i.s, Amp, mpstring(CLASSNAME(class)));
      addrdind(i.d, Afpind, imframe.d.offset, REGSIZE+IBY2WD);
      datareloc(i);

      # Result: Class object pointer

      i = newi(ILEA);
      dstreg(J.dst, DIS_P);
      *i.s = *J.dst;
      addrdind(i.d, Afpind, imframe.d.offset, REGRET*IBY2WD);

      loadermcall(imframe, frf, frm);
      relreg(imframe.d);
    }

But that also have some problems. We need to load the java/lang/Class instance, provide it with some data, prepare all the necessary relocations for the caller class and then pass the ref to the object back. Here is the runtime part to do some of this work:

    #
    # Get Class object for the class
    #
    getclassclass(caller: string, class: string): ref ClassObject
    {
      c := getclass(caller);
      if (c == nil)
        sthrow("NullPointerException");

      trace(JDEBUG, sys->sprint("Getclassclass called, %s asked for class %s",
        c.name, class));

      # TODO: put those strings in header
      # Prepare necessary classes
      if (stringclass == nil)
        loadstringclass();
      cc := getclass("java/lang/Class");
      if (cc == nil)
        sthrow("NullPointerException");
      f := cc.findsmethod("forName", "(Ljava/lang/String;)Ljava/lang/Class;");
      if (f == nil)
        error(sys->sprint("%s: %s: missing forName0 in Class",
          nosuchmethod, cc.name));

      # Call Class.forName method
      return cc.call(f.value, JStoObject(ref JavaString(stringclass.moddata,
        class)));
    }

While doing so, I've copied and fixed some missed native modules, fixed my small bug in translator (I copy-pasted ldc code also for the ldc2, which is not correct), compiled and translated lots of other jcl classes. It was actually a great shock for me to see that even simple empty java class depends on sun.security.cert.Certificate and lots of lots of others.

Actually I think that this is the biggest problem of my project right now. I can't isolate my changes, make them more independent and easy to test. That's because of anyhing in java I may want to run will depend on every (!) class in the whole java class hierarchy. So, currently my development strategy is quite weak, but I cannot find alternatives. I just have some empty java class with only `static main` function, and I continously try to run it. Every time jvm in inferno generates some exception, I debug it and then fix the thing that is causing it. Then I'm repeating that process untill everything is ok. Right now I have no successfull startup's, so I could only provide current jvm debug log (see [this]({{site.baseurl}}/logs/08072013.txt), or [this one]({{site.baseurl}}/logs/08072013-classes.txt) for more human-readable class loading log) from which you can see how far it is going, and my code fixes (see my repository [here](http://code.google.com/p/inferno-java/)).

Worked on files:
- `java/appl/java/classloader.b`: Classloader runtime code
- `java/appl/j2d/xlate.b`: Translator code and ldc handling
- `java/pkg/java/lang/Class_L.b`: Class class native module