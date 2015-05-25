---
layout: post
title:  "Field inheritance problems"
date: 2013.07.09 22:07:10
categories: gsoc
---

The issue of the day: inheritance.  
&nbsp;  
Ok, after I've implemented Class loading, my jvm runs lasted much longer. And the new problem was:
`[java/lang/String] Broken: "dereference of nil"`. And looking at stacktrace we could see the error in StringBuilder, in function toString:
  
    public String toString() {
        // Create a copy, don't share the array
        return new String(value, 0, count);
    }

Somehow the `value` array here was null, though in the superclass's functions it was absolutely valid. Seems to be the problem with some relocation magic inside jvm, I'm working on fixing this.

Worked on files:
- `java/appl/java/classloader.b`: Classloader runtime code
- `java/pkg/java/lang/StringBuilder.java`
- `java/pkg/java/lang/AbstractStringBuilder.java`
