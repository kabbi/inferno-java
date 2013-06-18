implement iImage_L;

# javal v1.5 generated file: edit with care

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

#
#  %W% - %E%
#

#<<

include "iImage_L.m";

#>> extra post includes here

draw : Draw;

#include "image2enc.m";
#    image2enc : Image2enc;

include "imagefile.m";
    readimg : RImagefile;
    imageremap : Imageremap;

include "bufio.m";
    B :Bufio;

#<<

init( jni_p : JNI )
{
    # save java native inteface mod instance
    jni = jni_p;
    #>>extra initialization here
    #<<
}

getImage_V( this : ref iImage_obj)
{#>>
    #	Open a file descriptor from which we can read a picture.
    #
    file : string;
    fd : ref Sys->FD;
    if ( this.file != nil ) {
	file = this.file.str;
	fd = jni->sys->open(file, Sys->OREAD);
	if ( fd == nil )
	     jni->ThrowException("java/io/IOException", jni->sys->sprint("%r"));
    }
    else if ( this.url != nil ) {	#  Try to open a network connection
	# file = some component of the URL
	return;			#  later.
    }
    else
	return;

    B = load Bufio Bufio->PATH;
    if ( B == nil )
	return;

    iobuf := B->fopen(fd, Bufio->OREAD);
    if ( (imagetype := guesstype(file)) == nil )
	return;

    imgarr : array of byte;
    (this.width, this.height, imgarr) = convert_img(iobuf, imagetype);
    this.imgbytes = jni->MkAByte(imgarr);
}#<<

#
#	Guess the file type from the suffix
#
guesstype(name : string) : string
{
    imagetype : string;
    (nil, suffix) := jni->str->splitr(name, ".");
    case suffix {
      "gif" =>			imagetype = "IMAGE/GIF";
      "pic" =>			imagetype = "IMAGE/PICT";
      "jpg" or "jpeg" =>	imagetype = "IMAGE/JPEG";
      "bit" or "mask" =>	imagetype = "IMAGE/X-INFERNO-BIT";
      "xbm" or "xbmp" =>	imagetype = "IMAGE/X-XBITMAP";
    }
    return imagetype;
}

#
# Convert the image into the Inferno bit format
# Return image height, width and the image(array of bytes)
# Uses readgif.b/readjpg.b/readxbitmap.b/readpic.b and image2enc.b 
#
convert_img(fd : ref Bufio->Iobuf, imagetype: string): (int, int, array of byte)
{
    # Initialization

    case imagetype {
      "IMAGE/GIF" =>	   readimg = load RImagefile RImagefile->READGIFPATH;
      "IMAGE/JPEG" =>	   readimg = load RImagefile RImagefile->READJPGPATH;
      "IMAGE/X-XBITMAP" => readimg = load RImagefile RImagefile->READXBMPATH;
      "IMAGE/X-PICT" =>    readimg = load RImagefile RImagefile->READPICPATH;
      "IMAGE/X-INFERNO-BIT" =>	# What to do here?
      * =>		   return(-1,-1,nil);			
    }

    if ( readimg == nil )
	return(-1,-1,nil);

    readimg->init(B);
    rawimg : ref RImagefile->Rawimage;

    # Read image [gif/jpg/xbm/pic]
    err_readimg: string;
    (rawimg, err_readimg) = readimg->read(fd);
    readimg = nil;		# memory control 

    # Error check
    if (err_readimg != "" ) {
	return(-1,-1,nil);
    }

    # Image2enc
#   image2enc = load Image2enc Image2enc->PATH;
#   if ( image2enc == nil )
#	return (-1, -1, nil);
#   (data, mask, err_enc) := image2enc->image2enc(rawimg, 1);
	
    # Error check
#   if (err_enc != "" ) {
#	return(-1,-1,nil);
#   }

    # Masking 
#   if (mask != nil) {
#	newdata := array[len data + len mask] of byte;
#	newdata[0:] = data[0:];
#	newdata[len data:] = mask[0:];
#	data = newdata;
#   }

    # Make Inferno image
    imageremap = load Imageremap Imageremap->PATH;
    draw = load Draw Draw->PATH;
    Image, Context : import draw;
    if ( imageremap == nil || draw == nil )
	return (-1, -1, nil);
    (img, err_remap) := imageremap->remap(rawimg, jni->getContext().display, 0);
    if ( img == nil )
	return (-1, -1, nil);
	
    # Determine image size
    wd := (rawimg.r.max.x - rawimg.r.min.x);
    ht := (rawimg.r.max.y - rawimg.r.min.y);

    data := array[wd*ht] of byte;	# what if depth != 3 ?
    img.readpixels(img.r, data);

    # Return width, height and image
    return(wd, ht, data);
}
