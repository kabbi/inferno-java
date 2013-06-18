#
#  %W% - %E%
#

implement AwtColor;

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
	Value,
	sys,
	FALSE,
        JObject : import jni;
 
    draw: Draw;
        Context, Display, Image: import draw;

include "java/lang/ClassLoader_L.m";
include "awt_Color.m";

ctxt : ref Context;
systemcolors_file := "/java/lib/systemcolor.properties";
 
rgbvmap := array[3*256] of {
	byte 255,byte 255,byte 255,   byte 255,byte 255,byte 170,
	byte 255,byte 255,byte  85,   byte 255,byte 255,byte   0,
	byte 255,byte 170,byte 255,   byte 255,byte 170,byte 170,
	byte 255,byte 170,byte  85,   byte 255,byte 170,byte   0,
	byte 255,byte  85,byte 255,   byte 255,byte  85,byte 170,
	byte 255,byte  85,byte  85,   byte 255,byte  85,byte   0,
	byte 255,byte   0,byte 255,   byte 255,byte   0,byte 170,
	byte 255,byte   0,byte  85,   byte 255,byte   0,byte   0,
	byte 238,byte   0,byte   0,   byte 238,byte 238,byte 238,
	byte 238,byte 238,byte 158,   byte 238,byte 238,byte  79,
	byte 238,byte 238,byte   0,   byte 238,byte 158,byte 238,
	byte 238,byte 158,byte 158,   byte 238,byte 158,byte  79,
	byte 238,byte 158,byte   0,   byte 238,byte  79,byte 238,
	byte 238,byte  79,byte 158,   byte 238,byte  79,byte  79,
	byte 238,byte  79,byte   0,   byte 238,byte   0,byte 238,
	byte 238,byte   0,byte 158,   byte 238,byte   0,byte  79,
	byte 221,byte   0,byte  73,   byte 221,byte   0,byte   0,
	byte 221,byte 221,byte 221,   byte 221,byte 221,byte 147,
	byte 221,byte 221,byte  73,   byte 221,byte 221,byte   0,
	byte 221,byte 147,byte 221,   byte 221,byte 147,byte 147,
	byte 221,byte 147,byte  73,   byte 221,byte 147,byte   0,
	byte 221,byte  73,byte 221,   byte 221,byte  73,byte 147,
	byte 221,byte  73,byte  73,   byte 221,byte  73,byte   0,
	byte 221,byte   0,byte 221,   byte 221,byte   0,byte 147,
	byte 204,byte   0,byte 136,   byte 204,byte   0,byte  68,
	byte 204,byte   0,byte   0,   byte 204,byte 204,byte 204,
	byte 204,byte 204,byte 136,   byte 204,byte 204,byte  68,
	byte 204,byte 204,byte   0,   byte 204,byte 136,byte 204,
	byte 204,byte 136,byte 136,   byte 204,byte 136,byte  68,
	byte 204,byte 136,byte   0,   byte 204,byte  68,byte 204,
	byte 204,byte  68,byte 136,   byte 204,byte  68,byte  68,
	byte 204,byte  68,byte   0,   byte 204,byte   0,byte 204,
	byte 170,byte 255,byte 170,   byte 170,byte 255,byte  85,
	byte 170,byte 255,byte   0,   byte 170,byte 170,byte 255,
	byte 187,byte 187,byte 187,   byte 187,byte 187,byte  93,
	byte 187,byte 187,byte   0,   byte 170,byte  85,byte 255,
	byte 187,byte  93,byte 187,   byte 187,byte  93,byte  93,
	byte 187,byte  93,byte   0,   byte 170,byte   0,byte 255,
	byte 187,byte   0,byte 187,   byte 187,byte   0,byte  93,
	byte 187,byte   0,byte   0,   byte 170,byte 255,byte 255,
	byte 158,byte 238,byte 238,   byte 158,byte 238,byte 158,
	byte 158,byte 238,byte  79,   byte 158,byte 238,byte   0,
	byte 158,byte 158,byte 238,   byte 170,byte 170,byte 170,
	byte 170,byte 170,byte  85,   byte 170,byte 170,byte   0,
	byte 158,byte  79,byte 238,   byte 170,byte  85,byte 170,
	byte 170,byte  85,byte  85,   byte 170,byte  85,byte   0,
	byte 158,byte   0,byte 238,   byte 170,byte   0,byte 170,
	byte 170,byte   0,byte  85,   byte 170,byte   0,byte   0,
	byte 153,byte   0,byte   0,   byte 147,byte 221,byte 221,
	byte 147,byte 221,byte 147,   byte 147,byte 221,byte  73,
	byte 147,byte 221,byte   0,   byte 147,byte 147,byte 221,
	byte 153,byte 153,byte 153,   byte 153,byte 153,byte  76,
	byte 153,byte 153,byte   0,   byte 147,byte  73,byte 221,
	byte 153,byte  76,byte 153,   byte 153,byte  76,byte  76,
	byte 153,byte  76,byte   0,   byte 147,byte   0,byte 221,
	byte 153,byte   0,byte 153,   byte 153,byte   0,byte  76,
	byte 136,byte   0,byte  68,   byte 136,byte   0,byte   0,
	byte 136,byte 204,byte 204,   byte 136,byte 204,byte 136,
	byte 136,byte 204,byte  68,   byte 136,byte 204,byte   0,
	byte 136,byte 136,byte 204,   byte 136,byte 136,byte 136,
	byte 136,byte 136,byte  68,   byte 136,byte 136,byte   0,
	byte 136,byte  68,byte 204,   byte 136,byte  68,byte 136,
	byte 136,byte  68,byte  68,   byte 136,byte  68,byte   0,
	byte 136,byte   0,byte 204,   byte 136,byte   0,byte 136,
	byte  85,byte 255,byte  85,   byte  85,byte 255,byte   0,
	byte  85,byte 170,byte 255,   byte  93,byte 187,byte 187,
	byte  93,byte 187,byte  93,   byte  93,byte 187,byte   0,
	byte  85,byte  85,byte 255,   byte  93,byte  93,byte 187,
	byte 119,byte 119,byte 119,   byte 119,byte 119,byte   0,
	byte  85,byte   0,byte 255,   byte  93,byte   0,byte 187,
	byte 119,byte   0,byte 119,   byte 119,byte   0,byte   0,
	byte  85,byte 255,byte 255,   byte  85,byte 255,byte 170,
	byte  79,byte 238,byte 158,   byte  79,byte 238,byte  79,
	byte  79,byte 238,byte   0,   byte  79,byte 158,byte 238,
	byte  85,byte 170,byte 170,   byte  85,byte 170,byte  85,
	byte  85,byte 170,byte   0,   byte  79,byte  79,byte 238,
	byte  85,byte  85,byte 170,   byte 102,byte 102,byte 102,
	byte 102,byte 102,byte   0,   byte  79,byte   0,byte 238,
	byte  85,byte   0,byte 170,   byte 102,byte   0,byte 102,
	byte 102,byte   0,byte   0,   byte  79,byte 238,byte 238,
	byte  73,byte 221,byte 221,   byte  73,byte 221,byte 147,
	byte  73,byte 221,byte  73,   byte  73,byte 221,byte   0,
	byte  73,byte 147,byte 221,   byte  76,byte 153,byte 153,
	byte  76,byte 153,byte  76,   byte  76,byte 153,byte   0,
	byte  73,byte  73,byte 221,   byte  76,byte  76,byte 153,
	byte  85,byte  85,byte  85,   byte  85,byte  85,byte   0,
	byte  73,byte   0,byte 221,   byte  76,byte   0,byte 153,
	byte  85,byte   0,byte  85,   byte  85,byte   0,byte   0,
	byte  68,byte   0,byte   0,   byte  68,byte 204,byte 204,
	byte  68,byte 204,byte 136,   byte  68,byte 204,byte  68,
	byte  68,byte 204,byte   0,   byte  68,byte 136,byte 204,
	byte  68,byte 136,byte 136,   byte  68,byte 136,byte  68,
	byte  68,byte 136,byte   0,   byte  68,byte  68,byte 204,
	byte  68,byte  68,byte 136,   byte  68,byte  68,byte  68,
	byte  68,byte  68,byte   0,   byte  68,byte   0,byte 204,
	byte  68,byte   0,byte 136,   byte  68,byte   0,byte  68,
	byte   0,byte 255,byte   0,   byte   0,byte 170,byte 255,
	byte   0,byte 187,byte 187,   byte   0,byte 187,byte  93,
	byte   0,byte 187,byte   0,   byte   0,byte  85,byte 255,
	byte   0,byte  93,byte 187,   byte   0,byte 119,byte 119,
	byte   0,byte 119,byte   0,   byte   0,byte   0,byte 255,
	byte   0,byte   0,byte 187,   byte   0,byte   0,byte 119,
	byte  51,byte  51,byte  51,   byte   0,byte 255,byte 255,
	byte   0,byte 255,byte 170,   byte   0,byte 255,byte  85,
	byte   0,byte 238,byte  79,   byte   0,byte 238,byte   0,
	byte   0,byte 158,byte 238,   byte   0,byte 170,byte 170,
	byte   0,byte 170,byte  85,   byte   0,byte 170,byte   0,
	byte   0,byte  79,byte 238,   byte   0,byte  85,byte 170,
	byte   0,byte 102,byte 102,   byte   0,byte 102,byte   0,
	byte   0,byte   0,byte 238,   byte   0,byte   0,byte 170,
	byte   0,byte   0,byte 102,   byte  34,byte  34,byte  34,
	byte   0,byte 238,byte 238,   byte   0,byte 238,byte 158,
	byte   0,byte 221,byte 147,   byte   0,byte 221,byte  73,
	byte   0,byte 221,byte   0,   byte   0,byte 147,byte 221,
	byte   0,byte 153,byte 153,   byte   0,byte 153,byte  76,
	byte   0,byte 153,byte   0,   byte   0,byte  73,byte 221,
	byte   0,byte  76,byte 153,   byte   0,byte  85,byte  85,
	byte   0,byte  85,byte   0,   byte   0,byte   0,byte 221,
	byte   0,byte   0,byte 153,   byte   0,byte   0,byte  85,
	byte  17,byte  17,byte  17,   byte   0,byte 221,byte 221,
	byte   0,byte 204,byte 204,   byte   0,byte 204,byte 136,
	byte   0,byte 204,byte  68,   byte   0,byte 204,byte   0,
	byte   0,byte 136,byte 204,   byte   0,byte 136,byte 136,
	byte   0,byte 136,byte  68,   byte   0,byte 136,byte   0,
	byte   0,byte  68,byte 204,   byte   0,byte  68,byte 136,
	byte   0,byte  68,byte  68,   byte   0,byte  68,byte   0,
	byte   0,byte   0,byte 204,   byte   0,byte   0,byte 136,
	byte   0,byte   0,byte  68,   byte   0,byte   0,byte   0,
};

modinit(jni_p : JNI)
{
        if (ctxt != nil)
                return;
 
	jni = jni_p;
	sys = jni->sys;
        ctxt = jni->getContext();
	if (ctxt == nil)
                jni->ThrowException("java.awt.AWTError", "can't get Draw Context");
	draw = load Draw Draw->PATH;

}

getColor(jni_p: JNI, c: JObject) : ref Image
{
	modinit(jni_p);

	cm_index := getColorIndex(jni_p, c);
	# (red, green, blue) := ctxt.display.cmap2rgb(cm_index);
        # sys->print("Inferno color: red=%d, green=%d, blue=%d\n", red, green, blue);
	col := ctxt.display.color(cm_index);
	return col;
}

getColorIndex(jni_p: JNI, c: JObject) : int
{
	modinit(jni_p);

	if (c == nil) {
        	sys->print("getColorIndex: null Color object\n");
		return 0;
	} 

	val := jni->GetObjField( c, "pData", "I" );
	if ( val == nil )
		sys->print( "getColorIndex: Couldn't get pData field from color object.\n" );
	else {
		pdata := val.Int();
        	if (pdata != 0) {
			# sys->print("Using pData.  pData = %d\n", pdata);
            		return pdata - 1;
		}
	}

        (ret, err) := jni->CallMethod(c, "getRGB", "()I", nil);
        if (err != jni->OK)
               jni->FatalError("awt_Color couldn't get RGB values of color");
 
	rgb := ret.Int();
	r := (rgb >> 16) & 255;
	g := (rgb >> 8) & 255;
	b := (rgb >> 0) & 255;
	cm_index := ctxt.display.rgb2cmap(r,g,b);
	# sys->print( "rgb: %d\n", rgb);
	# sys->print( "red: %d; green: %d; blue %d\n", r, g, b);
        # sys->print("Color map index is %d.\n", cm_index);

        # sys->print("Setting pData to %d\n", cm_index+1);
        val = ref Value.TInt(cm_index+1);
        err = jni->SetObjField( c, "pData", val );
        if (err != jni->OK)
               sys->print("getColorIndex: Couldn't set Color pData field\n");

	return cm_index;
}

makeColorModel(jni_p: JNI, bits: int) : JObject
{
	modinit(jni_p);

        cast := jni->CastMod();
        jbary := jni->MkAByte(rgbvmap);
        arraylen := len jbary.ary;
        # sys->print("makeColorModel:  Array length is %d.\n", arraylen);

        args := array[5] of ref Value;
        args[0] = ref Value.TInt(bits);
        args[1] = ref Value.TInt(256);
        args[2] = ref Value.TObject(cast->FromJArray(cast->ByteToJArray(jbary)));
        args[3] = ref Value.TInt(0);
        args[4] = ref Value.TBoolean(jni->FALSE);

        cl_data := jni->FindClass("java/awt/image/IndexColorModel");
        if (cl_data == nil)
                jni->FatalError("awt_Color couldn't load java/awt/image/IndexColorModel");
        jobj := jni->AllocObject(cl_data);
        (ret, err) := jni->CallMethod(jobj, "<init>", "(II[BIZ)V", args);

        if (err != jni->OK)
               jni->FatalError("awt_Color couldn't create IndexColorModel");
 
        system_flag := ref Value.TInt(1);
        err = jni->SetObjField( jobj, "pData", system_flag );
        if (err != jni->OK)
               sys->print("makeColorModel: Couldn't set ColorModel pData field to 1\n");

        return jobj;
}
 

loadSystemColors(jni_p: JNI, systemColors: JArrayI)
{
        val : ref Value;

        modinit(jni_p);
 
        cl := jni->GetClassObject(jni->FindClass("java/awt/SystemColor"));
        if (cl == nil)
                jni->FatalError("iToolkit_L couldn't load java/awt/SystemColor");
        val = jni->GetStaticField( cl.class, "NUM_COLORS", "I" );
        if ( val == nil ) {
                sys->print( "loadSystemColors: Couldn't get NUM_COLORS field from SystemColor class.\n" );
                return;
        }
 
        num_colors := val.Int();
        # sys->print("Using GetStaticField: NUM_COLORS = %d\n", num_colors);
 
        lines := readfile(systemcolors_file);
	if (lines == nil) {
                sys->print( "loadSystemColors: Couldn't read %s\n", systemcolors_file);
		return;
	}
        for(; lines != nil; lines = tl lines) {
                line := hd lines;
                (n, l) := sys->tokenize(line, " \t=");
                if (n < 2 || line[0] == '#')
                        continue;
                key := hd l;
                line = hd tl l;
                (n, l) = sys->tokenize(line, ";");
                if (n != 3)
                        continue;
                r := int hd l;
                g := int hd tl l;
                b := int hd tl tl l;
                # sys->print("  key = %s:  r = %d; g = %d; b = %d\n", key, r, g, b);
                val = jni->GetStaticField( cl.class, key, "I" );
                if ( val == nil )
                        continue;
                index := val.Int();
                color := (255 << 24) | ((r & 255) << 16) | ((g & 255) << 8) | ((b & 255) << 0);
                systemColors.ary[index] = color;
        }

        return;
}


# read a file and return its lines as a list of strings
readfile(filename: string) : list of string
{
  fd := sys->open(filename, sys->OREAD);
  if(fd != nil) {
    (n, dir) := sys->fstat(fd);
    if(n < 0)
      return nil; # shouldn't happen
    buf := array[dir.length] of byte;
    n = sys->read(fd, buf, dir.length);
    if(n == dir.length) {
      (nil, linelist) := sys->tokenize(string buf[0:n], "\r\n");
      return linelist;
    }
  }  
  return nil;
}


