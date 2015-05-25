---
layout: post
title:  "After a short brake"
date: 2013.06.30 23:13:10
categories: gsoc
---

The issue of the day: template classes, Class loading is still impossible to implement.  
&nbsp;  
So, in my previous post I've listed some problems. One of them is Class class getter, which currently prevents lots of the java classes to work. The actual problem is in 'ldc' instructions. It's purpose is to push some constant to stack, but when the type of constant is 'class ref (class name)', then jvm should push a ref to the Class object, bounded to the given class. But since java 1.5, java Classes are bound to the objects using Generics, and it is not currently supported at all. It needs to be implemented to allow the whole jvm to work.

So, I decided to temporary throw away all the java classes and dependencies, to test the basic things.
I've made Object class to not depend on anything else, and wrote some test code in it. Here is my test class:

    package java.lang;

    public class Object {

         private native void someNativeFunction();
         private native int someAdder(int a, int b);
         static private native void logInteger(int a);

         Object() {

         }

         static int function() {
              return 42;
         }

         void sayHello() {
              function();
         }

         public static void main() {
              Object obj = new Object();
              obj.someNativeFunction();
              int result = obj.someAdder(function(), 13);
              logInteger(result);
         }
    }

It is using native functions to do the debug output, as we can't use those of java. And the output is:

    ; java/jvm -d java/lang/Object
    loadlinkgs size 80
    count = 1 + 0
    load class java/lang/Object
    Switching class java/lang/Object state to NEW
    [java/lang/Object]
    "/dis/java/java/java/lang/Object.dis"
    Switching class java/lang/Object state to RESOLVE
    someNativeFunction: static method
    Getmethod of java/lang/Object: someNativeFunction, ()V, 262402
    "/dis/java/java/java/lang/Object_L.dis"
    Mangled native name: someNativeFunction_V
    someNativeFunction: private method
    someAdder: static method
    Getmethod of java/lang/Object: someAdder, (II)I, 262402
    Mangled native name: someAdder_I_I_I
    someAdder: private method
    logInteger: static method
    Getmethod of java/lang/Object: logInteger, (I)V, 327946
    Mangled native name: logInteger_I_V
    logInteger: static method
    Getmethod of java/lang/Object: <init>, ()V, 1310720
    function: static method
    Getmethod of java/lang/Object: function, ()I, 8
    function: static method
    sayHello: new method
    main: static method
    Getmethod of java/lang/Object: main, ()V, 9
    main: static method
    Getmethod of java/lang/Object: <clone>, ()V, 8
    Getmethod of java/lang/Object: <init>, ()V, 262144
    Makevmtable for java/lang/Object, 1
    Getmethod of java/lang/Object: sayHello, ()V, 0
    reloc java/lang/Object
    relocate(java/lang/Object) enter
    java/lang/Object data 32 reloc 32
        0 bytes at 64
        33 instrs
    link 0 pc 0 tdesc 1 name <init>()V
    link 1 pc 1 tdesc 2 name function()I
    link 2 pc 3 tdesc 3 name sayHello()V
    link 3 pc 7 tdesc 4 name main()V
    link 4 pc 29 tdesc 5 name <clone>()V
    relocate(java/lang/Object) exit
    modpatch java/lang/Object
    compile java/lang/Object
    compile native java/lang/Object
    Switching class java/lang/Object state to INITED
    java/lang/Object->init()
    done
    loader() exit
    Some native function called
    Adder is doing it's work! 42 13
    Log integer: 55
    count = 0 + 0
    ;

I have also extended this test case to check all the things I can for now, like static/private/public fields and functions, inner classes, object creation, basic arithmetic and pointers. Everything works.

The next step will be to try and load Class class. We only need to throw out all the dependencies for better debugging.


Worked on files:
- `java/pkg/java/lang/Object.java`: Object class source
- `java/pkd/java/lang/Object_L.b`: Object class native module
- `java/appl/java/classloader.b`: Classloader module