implement JavaNative;

include	"jni.m";

#
#	This is to isolate jni from the classloader.
#

init(sys: Sys, ld: Loader, jldr: JavaClassLoader, jass: JavaAssist): string
{
	j := load JNI JNI->PATH;
	if (j == nil)
		return sys->sprint("could not load %s: %r", JNI->PATH);
	(m, s) := j->Self(sys, j);
	if (s != nil)
		return s;
	l := ld->link(m);
	if (l == nil)
		return sys->sprint("link failed: %r");
	n := len l;
	t := -1;
	for (i := 0; i < n; i++) {
		if (l[i].name == "init")
			t = i;
	}
	if (t == -1)
		return sys->sprint("%s: not signed", JNI->PATH);
	jldr->jninil = m;
	jldr->jnisig = l[t].sig;
	j->jinit(jldr, jass);
	return nil;
}
