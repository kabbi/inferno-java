#
#	Java Class Loader dis assist.
#

#0
# getint:
	addw	0(32(fp)),36(fp),40(fp)
	movw	0(40(fp)),0(16(fp))
	ret
#3
# getbytearray:
# getintarray:
# getreloc:
# getstrarray:
# getstring:
	addw	0(32(fp)),36(fp),40(fp)
	movp	0(40(fp)),0(16(fp))
	ret
#6
# putint:
	addw	32(fp),36(fp),44(fp)
	movw	40(fp),0(44(fp))
	ret
#9
# putclass:
# putmod:
# putobj:
# putptr:
# putstring:
	addw	32(fp),36(fp),44(fp)
	movp	40(fp),0(44(fp))
	ret
#12
# little_endian:
#
	movw	$0,0(16(fp))
	movb	0(mp),0(16(fp))
	ret
#15
# jclnilmod:
# sysnilmod:
# arrayof:
# bytearraytoJS:
# intarraytoJS:
# bigarraytoJS:
# realarraytoJS:
# ArraytoJS:
# JStoObject:
# ObjecttoJT:
	movp	32(fp),0(16(fp))
	ret
#17
# new:
	mnewz	32(fp),36(fp),0(16(fp))
	ret
#19
# getobjclass:
	movp	0(32(fp)),36(fp)
	movp	4(36(fp)),0(16(fp))
	ret
#22
# modhash:
# objhash:
	andw	32(fp),4(mp),0(16(fp))
	ret
#24
# getrtreloc:
# getclassadt:
# getadtstring:
	addw	32(fp),36(fp),40(fp)
	movp	0(40(fp)),0(16(fp))
	ret
#27
# getabsint
	movw	0(32(fp)),0(16(fp))
	ret
#29
# mcall0:
	mframe	32(fp),36(fp),40(fp)
	lea	0(16(fp)),16(40(fp))
	mcall	40(fp),36(fp),32(fp)
	ret
#33
# mcall1:
# mcalla:
# mcallm:
	mframe	32(fp),36(fp),44(fp)
	movp	40(fp),32(44(fp))
	lea	0(16(fp)),16(44(fp))
	mcall	44(fp),36(fp),32(fp)
	ret
#38
# getmd:
	movp	0(32(fp)),0(16(fp))
	ret
#40
# makeadt:
	movp	32(fp),0(16(fp))
	ret
	desc	$0,8,""
	desc	$1,48,"0080"
	desc	$2,48,"00a0"
	desc	$3,32,""
	desc	$4,40,"0080"
	desc	$5,40,"00c0"
	desc	$6,40,""
	var	@mp,8
	word	@mp+0,1
	word	@mp+4,2147483647
	module	JavaAssist
	link	1,0,0x9af56bb1,"getint"
	link	1,3,0x480b7ac3,"getbytearray"
	link	1,3,0x55e7e9b3,"getintarray"
	link	1,3,0xd7e85087,"getptr"
	link	1,3,0xbb4256c7,"getreloc"
	link	1,3,0x67808576,"getstrarray"
	link	1,3,0xe6647e4a,"getstring"
	link	1,6,0x2de68727,"putint"
	link	2,9,0x8f05c931,"putclass"
	link	2,9,0x66b5c780,"putmod"
	link	2,9,0x4f9a2948,"putobj"
	link	2,9,0x43ec4524,"putptr"
	link	2,9,0x46bbe09a,"putstring"
	link	3,12,0x616977e8,"little_endian"
	link	4,15,0x18138a11,"jclnilmod"
	link	4,15,0x8cdb1059,"sysnilmod"
	link	4,15,0x6d675ef6,"arrayof"
	link	4,15,0x79238ebb,"bytearraytoJS"
	link	4,15,0x9dfa2ee1,"intarraytoJS"
	link	4,15,0x1ebcdfdd,"bigarraytoJS"
	link	4,15,0xc8107991,"realarraytoJS"
	link	4,15,0xfb08d2ba,"ArraytoJS"
	link	4,15,0x76cd0754,"JStoObject"
	link	4,15,0xae823704,"ObjecttoJT"
	link	1,17,0xbb2da06c,"new"
	link	5,19,0x7e47f344,"getobjclass"
	link	4,22,0x4e5d43e7,"modhash"
	link	4,22,0x646cd7d0,"objhash"
	link	1,24,0xa1fa7e52,"getrtreloc"
	link	1,24,0x45af8037,"getclassadt"
	link	1,24,0x3911b054,"getadtstring"
	link	6,27,0xe67bf126,"getabsint"
	link	1,29,0x9af56bb1,"mcall0"
	link	2,33,0xcbd2cc54,"mcall1"
	link	2,33,0x2c8f47,"mcalla"
	link	2,33,0x1fe62f91,"mcallm"
	link	4,38,0x21126c42,"getmd"
	link	6,40,0x2d805d,"makeadt"
