---
layout: post
title:  "Day 4"
date: 2013.06.20 23:29:10
categories: gsoc
---

The issue of the day: Inferno panic.  
&nbsp;  
Seems that I'm having some progress... I've got lots of gdb skills today, and much better understanding of Inferno internals. For example, now I know that `R` struct holds all the information about the currently running dis program, and simple constructions like `print R.PC - R.M->m.prog` could tell you the current instruction. So, I've found out that somehow my `Class-><cliinit>;` calls ended up in some strange classloader's function like `compatclass`. Which was not really intended to happen. The caller provided not the expected agruments, and Inferno failed.

The part of Class.s clinit code:

    #J8 anewarray 279
    #4610
        bnew    1040(mp),0(mp),$4614
        mframe  0(mp),$0,32(fp)
        lea 1040(mp),32(32(fp))
        mcall   32(fp),$0,0(mp)
        mnewz   0(mp),$0,36(fp)
        movp    0(0(mp)),0(36(fp))
        newa    $0,$6,4(36(fp))
        movw    $1,8(36(fp))
        movp    1048(mp),12(36(fp))

As of the relocation mechanism of classloader, later the code fixes zeros in that code with appropriate runtime addresses and constants. So, the `mcall 32(fp),$0,0(mp)` should be turned to something like `mcall 32(fp),$10,98(mp)`, where $10 - the index of needed function in the linkage table. In this case, the function should be 'classloader.rtload'. And it really has the 10th index, but not from the start of the links array.

**It appeared, that Loader gives us all the links in the reverse order!** I don't know why, seems that some ordering has changed in Inferno since then. So, I've just fixed some lines in the loader.c, from

    ll = (Loader_Link*)ar->data + nlink;
    for(p = m->ext; p->name; p++) {
        ll--;
        ll->name = c2string(p->name, strlen(p->name));
        ll->sig = p->sig;
        ...
    }

to

    ll = (Loader_Link*)ar->data;
    for(p = m->ext; p->name; p++) {
        ll->name = c2string(p->name, strlen(p->name));
        ll->sig = p->sig;
        ...
        ll++;
    }

And all the Inferno crashes are gone! I'm really happy and now I can continue fixing some more serious bugs and finally (maybe) write some new code...

Worked on files:
- `libinterp/loader.c`: Loader module source code
- `java/appl/java/classloader.b`: jvm Classloader source
- `dis/java/classloader.dis`: Inferno's wm/rt tool is really helpful in debugging strange linkage errors and the things like that