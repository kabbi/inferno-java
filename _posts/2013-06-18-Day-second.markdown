---
layout: post
title:  "Day 2"
date: 2013.06.18 22:29:10
categories: gsoc
---

The issue of the day: still failing `String_L.dis`.  
&nbsp;  
Not the best day ever. Most of the time I tried to create c code to pass `array of array of Import` to the limbo code, but that was not a trivial task. Either I screwed up some memory allocation code, or I've done wrong some other things, but eventually my code is not working, throwing `Null pointer` exception in limbo.

Anyway, I've setted up this wonderful and simple blog, using **Jekyll** and **Git**. It's really easy to write posts or any content, then just `git commit` - and all this appears online in few seconds. There is git post-update hook that executes jekyll build, and then Apache delivers static content over the Internet. Simple and usefull.

I've also setted up hg repository on google-code, to allow others see and test my changes. Its [here](http://code.google.com/p/inferno-java/). But currently no luck uploading my 400Mb of code there. Even though I've filtered debug and unneccessary data. Seems that java classes are too large. I'll try more.

**UPD 2013.06.31:**
I did it! For the future problems: `--debug` flag is really helpful.

Worked on files:
- `libinterp/loader.c`: Loader module source code
- `modules/Loader.m`: module definition file
- `java/pkg/java/lang/String_L.[bm]`: String_L native class