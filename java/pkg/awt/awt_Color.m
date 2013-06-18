#
#  %W% - %E%
#

AwtColor : module
{
	PATH : con "/dis/java/inferno/awt/awt_Color.dis";

	getColor :	fn(jni: JNI, c: JObject) : ref Image;
	getColorIndex :	fn(jni: JNI, c: JObject) : int;
	makeColorModel :	fn(jni: JNI, bits: int) : JObject;
	loadSystemColors :	fn(jni: JNI, systemColors: JArrayI);
};
