/*
 * Copyright (c) 1994, 2011, Oracle and/or its affiliates. All rights reserved.
 * DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS FILE HEADER.
 *
 * This code is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License version 2 only, as
 * published by the Free Software Foundation.  Oracle designates this
 * particular file as subject to the "Classpath" exception as provided
 * by Oracle in the LICENSE file that accompanied this code.
 *
 * This code is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
 * version 2 for more details (a copy is included in the LICENSE file that
 * accompanied this code).
 *
 * You should have received a copy of the GNU General Public License version
 * 2 along with this work; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA.
 *
 * Please contact Oracle, 500 Oracle Parkway, Redwood Shores, CA 94065 USA
 * or visit www.oracle.com if you need additional information or have any
 * questions.
 */
package java.io;

//import java.io.*;
//import java.util.Properties;
//import java.util.PropertyPermission;
//import java.util.StringTokenizer;
//import java.security.AccessController;
//import java.security.PrivilegedAction;
//import java.security.AllPermission;
//import java.nio.channels.Channel;
//import java.nio.channels.spi.SelectorProvider;
//import sun.nio.ch.Interruptible;
//import sun.reflect.Reflection;
//import sun.security.util.SecurityConstants;
//import sun.reflect.annotation.AnnotationType;

/**
 * The <code>FileDescriptor</code> class is the internal to Inferno's jvm
 * class representing internal file descriptor.
 *
 * Mainly provides in, out and err file descriptors.
 *
 * @author  kabbi
 */
public final class FileDescriptor {

    public static FileDescriptor in = new FileDescriptor();

    public static FileDescriptor out = new FileDescriptor();

    public static FileDescriptor err = new FileDescriptor();

    static {
        in = initSystemFD(in, 0);
        out = initSystemFD(out, 1);
        err = initSystemFD(err, 2);
    }

    /** Don't let anyone instantiate this class */
    private FileDescriptor() {
    }

    /**
     * Init some FileDescriptor object with system numeric fd number
     *
     * @param fd FileDescriptor object
     * @param number system fd index
     */
    public final static native FileDescriptor initSystemFD(FileDescriptor fd, int number);

    /**
     * Check if this file descriptor is valid.
     */
    public final native boolean valid();

    /*
     * Flush all the buffers and wait till every operation is completed.
     * Means nothing in Inferno, as all the operations are synchronous.
     */
    public final native void sync();

}
