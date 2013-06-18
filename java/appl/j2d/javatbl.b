XLOAD:		con 16r1 << 0;
XSTORE:		con 16r1 << 1;

javatbl := array [MAXJAVA] of {
	byte 0,		# Jnop
	byte XLOAD,	# Jaconst_null
	byte XLOAD,	# Jiconst_m1
	byte XLOAD,	# Jiconst_0
	byte XLOAD,	# Jiconst_1
	byte XLOAD,	# Jiconst_2
	byte XLOAD,	# Jiconst_3
	byte XLOAD,	# Jiconst_4
	byte XLOAD,	# Jiconst_5
	byte XLOAD,	# Jlconst_0
	byte XLOAD,	# Jlconst_1
	byte XLOAD,	# Jfconst_0
	byte XLOAD,	# Jfconst_1
	byte XLOAD,	# Jfconst_2
	byte XLOAD,	# Jdconst_0
	byte XLOAD,	# Jdconst_1
	byte XLOAD,	# Jbipush
	byte XLOAD,	# Jsipush
	byte XLOAD,	# Jldc
	byte XLOAD,	# Jldc_w
	byte XLOAD,	# Jldc2_w
	byte XLOAD,	# Jiload
	byte XLOAD,	# Jlload
	byte XLOAD,	# Jfload
	byte XLOAD,	# Jdload
	byte XLOAD,	# Jaload
	byte XLOAD,	# Jiload_0
	byte XLOAD,	# Jiload_1
	byte XLOAD,	# Jiload_2
	byte XLOAD,	# Jiload_3
	byte XLOAD,	# Jlload_0
	byte XLOAD,	# Jlload_1
	byte XLOAD,	# Jlload_2
	byte XLOAD,	# Jlload_3
	byte XLOAD,	# Jfload_0
	byte XLOAD,	# Jfload_1
	byte XLOAD,	# Jfload_2
	byte XLOAD,	# Jfload_3
	byte XLOAD,	# Jdload_0
	byte XLOAD,	# Jdload_1
	byte XLOAD,	# Jdload_2
	byte XLOAD,	# Jdload_3
	byte XLOAD,	# Jaload_0
	byte XLOAD,	# Jaload_1
	byte XLOAD,	# Jaload_2
	byte XLOAD,	# Jaload_3
	byte 0,		# Jiaload
	byte 0,		# Jlaload
	byte 0,		# Jfaload
	byte 0,		# Jdaload
	byte 0,		# Jaaload
	byte 0,		# Jbaload
	byte 0,		# Jcaload
	byte 0,		# Jsaload
	byte XSTORE,	# Jistore
	byte XSTORE,	# Jlstore
	byte XSTORE,	# Jfstore
	byte XSTORE,	# Jdstore
	byte XSTORE,	# Jastore
	byte XSTORE,	# Jistore_0
	byte XSTORE,	# Jistore_1
	byte XSTORE,	# Jistore_2
	byte XSTORE,	# Jistore_3
	byte XSTORE,	# Jlstore_0
	byte XSTORE,	# Jlstore_1
	byte XSTORE,	# Jlstore_2
	byte XSTORE,	# Jlstore_3
	byte XSTORE,	# Jfstore_0
	byte XSTORE,	# Jfstore_1
	byte XSTORE,	# Jfstore_2
	byte XSTORE,	# Jfstore_3
	byte XSTORE,	# Jdstore_0
	byte XSTORE,	# Jdstore_1
	byte XSTORE,	# Jdstore_2
	byte XSTORE,	# Jdstore_3
	byte XSTORE,	# Jastore_0
	byte XSTORE,	# Jastore_1
	byte XSTORE,	# Jastore_2
	byte XSTORE,	# Jastore_3
	byte 0,		# Jiastore
	byte 0,		# Jlastore
	byte 0,		# Jfastore
	byte 0,		# Jdastore
	byte 0,		# Jaastore
	byte 0,		# Jbastore
	byte 0,		# Jcastore
	byte 0,		# Jsastore
	byte 0,		# Jpop
	byte 0,		# Jpop2
	byte 0,		# Jdup
	byte 0,		# Jdup_x1
	byte 0,		# Jdup_x2
	byte 0,		# Jdup2
	byte 0,		# Jdup2_x1
	byte 0,		# Jdup2_x2
	byte 0,		# Jswap
	byte 0,		# Jiadd
	byte 0,		# Jladd
	byte 0,		# Jfadd
	byte 0,		# Jdadd
	byte 0,		# Jisub
	byte 0,		# Jlsub
	byte 0,		# Jfsub
	byte 0,		# Jdsub
	byte 0,		# Jimul
	byte 0,		# Jlmul
	byte 0,		# Jfmul
	byte 0,		# Jdmul
	byte 0,		# Jidiv
	byte 0,		# Jldiv
	byte 0,		# Jfdiv
	byte 0,		# Jddiv
	byte 0,		# Jirem
	byte 0,		# Jlrem
	byte 0,		# Jfrem
	byte 0,		# Jdrem
	byte 0,		# Jineg
	byte 0,		# Jlneg
	byte 0,		# Jfneg
	byte 0,		# Jdneg
	byte 0,		# Jishl
	byte 0,		# Jlshl
	byte 0,		# Jishr
	byte 0,		# Jlshr
	byte 0,		# Jiushr
	byte 0,		# Jlushr
	byte 0,		# Jiand
	byte 0,		# Jland
	byte 0,		# Jior
	byte 0,		# Jlor
	byte 0,		# Jixor
	byte 0,		# Jlxor
	byte 0,		# Jiinc
	byte 0,		# Ji2l
	byte 0,		# Ji2f
	byte 0,		# Ji2d
	byte 0,		# Jl2i
	byte 0,		# Jl2f
	byte 0,		# Jl2d
	byte 0,		# Jf2i
	byte 0,		# Jf2l
	byte 0,		# Jf2d
	byte 0,		# Jd2i
	byte 0,		# Jd2l
	byte 0,		# Jd2f
	byte 0,		# Ji2b
	byte 0,		# Ji2c
	byte 0,		# Ji2s
	byte 0,		# Jlcmp
	byte 0,		# Jfcmpl
	byte 0,		# Jfcmpg
	byte 0,		# Jdcmpl
	byte 0,		# Jdcmpg
	byte 0,		# Jifeq
	byte 0,		# Jifne
	byte 0,		# Jiflt
	byte 0,		# Jifge
	byte 0,		# Jifgt
	byte 0,		# Jifle
	byte 0,		# Jif_icmpeq
	byte 0,		# Jif_icmpne
	byte 0,		# Jif_icmplt
	byte 0,		# Jif_icmpge
	byte 0,		# Jif_icmpgt
	byte 0,		# Jif_icmple
	byte 0,		# Jif_acmpeq
	byte 0,		# Jif_acmpne
	byte 0,		# Jgoto
	byte 0,		# Jjsr
	byte 0,		# Jret
	byte 0,		# Jtableswitch
	byte 0,		# Jlookupswitch
	byte 0,		# Jireturn
	byte 0,		# Jlreturn
	byte 0,		# Jfreturn
	byte 0,		# Jdreturn
	byte 0,		# Jareturn
	byte 0,		# Jreturn
	byte 0,		# Jgetstatic
	byte 0,		# Jputstatic
	byte 0,		# Jgetfield
	byte 0,		# Jputfield
	byte 0,		# Jinvokevirtual
	byte 0,		# Jinvokespecial
	byte 0,		# Jinvokestatic
	byte 0,		# Jinvokeinterface
	byte 0,		# Jxxxunusedxxx
	byte 0,		# Jnew
	byte 0,		# Jnewarray
	byte 0,		# Janewarray
	byte 0,		# Jarraylength
	byte 0,		# Jathrow
	byte 0,		# Jcheckcast
	byte 0,		# Jinstanceof
	byte 0,		# Jmonitorenter
	byte 0,		# Jmonitorexit
	byte 0,		# Jwide
	byte 0,		# Jmultianewarray
	byte 0,		# Jifnull
	byte 0,		# Jifnonnull
	byte 0,		# Jgoto_w
	byte 0,		# Jjsr_w
};

opcode(j: ref Jinst): int
{
	ret: byte;

	if(j.op == byte Jwide) {
		pick jp := j {
		Pw =>
			ret = jp.w.op;
		* =>
			badpick("opcode");
		}
	} else
		ret = j.op;
	return int ret;
}

isload(j: ref Jinst): int
{
	return int javatbl[opcode(j)] & XLOAD;
}

isstore(j: ref Jinst): int
{
	return int javatbl[opcode(j)] & XSTORE;
}
