AwtImage : module
{
	PATH : con "/dis/java/inferno/awt/awt_Image.dis";

	#
	# Inferno rep of manifest constants defined in
	# java.awt.image.ImageObserver (hope they don't change
	# in javaland).
	ImO_WIDTH: 	con 1;
	ImO_HEIGHT: 	con 2;
	ImO_PROPERTIES: con 4;
	ImO_SOMEBITS: 	con 8;
	ImO_FRAMEBITS: 	con 16;
	ImO_ALLBITS: 	con 32;
	ImO_ERROR: 	con 64;
	ImO_ABORT: 	con 128;

	#
	# Inferno rep of pixel delivery hints from 
	# java.awt.image.ImageConsumer.
        # 
	ImC_RANDOMPIXELORDER: 	con 1;
	ImC_TOPDOWNLEFTRIGHT:	con 2;
	ImC_COMPLETESCANLINES:	con 4;
	ImC_SINGLEPASS:		con 8;
	ImC_SINGLEFRAME:		con 16;

	#
	# Inferno rep of imageComplete status bits
	# java.awt.image.ImageConsumer.
        # 
	ImC_IMAGEERROR:	con 1;
	ImC_SINGLFRAMEDONE:	con 2;
	ImC_STATICIMAGEDONE: con 3;
	ImC_IMAGEABORTED: 	con 4;
};
