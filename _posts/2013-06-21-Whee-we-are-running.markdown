---
layout: post
title:  "Wheee, we are running!"
date: 2013.07.21 22:07:10
categories: gsoc
---

The issue of the day: System.initializeSystemClass().  
&nbsp;  
Yahooo, we are up and running! I've successfully started simple app! The last log lines:

    rtload end
    clinit done
    loader() exit
    rtload end
    clinit done
    loader() exit
    Debug print integer: 42
    count = 0 + 0
    ; 

Then I've tried to use System.out and found out, that it is initialized in System.initializeSystemClass(), but it is never actually called. I've called it in my jvm, and then the whole bunch of problems arized.

There is the source:

    private static void initializeSystemClass() {

        // VM might invoke JNU_NewStringPlatform() to set those encoding
        // sensitive properties (user.home, user.name, boot.class.path, etc.)
        // during "props" initialization, in which it may need access, via
        // System.getProperty(), to the related system encoding property that
        // have been initialized (put into "props") at early stage of the
        // initialization. So make sure the "props" is available at the
        // very beginning of the initialization and all system properties to
        // be put into it directly.
        props = new Properties();
        initProperties(props);  // initialized by the VM

        // There are certain system configurations that may be controlled by
        // VM options such as the maximum amount of direct memory and
        // Integer cache size used to support the object identity semantics
        // of autoboxing.  Typically, the library will obtain these values
        // from the properties set by the VM.  If the properties are for
        // internal implementation use only, these properties should be
        // removed from the system properties.
        //
        // See java.lang.Integer.IntegerCache and the
        // sun.misc.VM.saveAndRemoveProperties method for example.
        //
        // Save a private copy of the system properties object that
        // can only be accessed by the internal implementation.  Remove
        // certain system properties that are not intended for public access.
        sun.misc.VM.saveAndRemoveProperties(props);


        lineSeparator = props.getProperty("line.separator");
        sun.misc.Version.init();

        FileInputStream fdIn = new FileInputStream(FileDescriptor.in);
        FileOutputStream fdOut = new FileOutputStream(FileDescriptor.out);
        FileOutputStream fdErr = new FileOutputStream(FileDescriptor.err);
        setIn0(new BufferedInputStream(fdIn));
        setOut0(new PrintStream(new BufferedOutputStream(fdOut, 128), true));
        setErr0(new PrintStream(new BufferedOutputStream(fdErr, 128), true));
        // Load the zip library now in order to keep java.util.zip.ZipFile
        // from trying to use itself to load this library later.
        loadLibrary("zip");

        // Setup Java signal handlers for HUP, TERM, and INT (where available).
        Terminator.setup();

        // Initialize any miscellenous operating system settings that need to be
        // set for the class libraries. Currently this is no-op everywhere except
        // for Windows where the process-wide error mode is set before the java.io
        // classes are used.
        sun.misc.VM.initializeOSEnvironment();

        // Subsystems that are invoked during initialization can invoke
        // sun.misc.VM.isBooted() in order to avoid doing things that should
        // wait until the application class loader has been set up.
        sun.misc.VM.booted();

        // The main thread is not added to its thread group in the same
        // way as other threads; we must do it ourselves here.
        Thread current = Thread.currentThread();
        current.getThreadGroup().add(current);

        // register shared secrets
        setJavaLangAccess();
    }

Lots of classes were missing, some of them where not implemented and some of them lacked native parts. So, I've implemented initProperties(), created FileDescriptor class and internal VM.initializeOSEnvironment, VMVersion and some others. Everything went ok, until it ran Thread.currentThread(). It depends on AtomicInteger, which depends on sun.misc.Unsafe. And **that** is an awful module! It contains all the low-level stuff of JVM, and I currently have almost no idea, how to implement most of them. And there is a lot of functions there!

And also to mention the Reflection stuff, never use it in your own apps! All the things are also to be implemented by me.

Worked on files:
- `java/appl/java/classloader.b`: Classloader runtime code
- `java/pkg/sun/misc/Unsafe.java`
