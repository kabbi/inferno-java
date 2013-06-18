#include "java.h"
#include "javaisa.h"

enum {
	XLOAD	= 0x1 << 0,
	XSTORE	= 0x1 << 1
};

static uchar javatbl[MAXJAVA];

static int
opcode(Jinst *j)
{
	return (j->op == Jwide) ? j->u.w.op : j->op;
}

int
isload(Jinst *j)
{
	return javatbl[opcode(j)] & XLOAD;
}

int
isstore(Jinst *j)
{
	return javatbl[opcode(j)] & XSTORE;
}

static uchar javatbl[MAXJAVA] = {
	0,		/* Jnop */
	XLOAD,		/* Jaconst_null */
	XLOAD,		/* Jiconst_m1 */
	XLOAD,		/* Jiconst_0 */
	XLOAD,		/* Jiconst_1 */
	XLOAD,		/* Jiconst_2 */
	XLOAD,		/* Jiconst_3 */
	XLOAD,		/* Jiconst_4 */
	XLOAD,		/* Jiconst_5 */
	XLOAD,		/* Jlconst_0 */
	XLOAD,		/* Jlconst_1 */
	XLOAD,		/* Jfconst_0 */
	XLOAD,		/* Jfconst_1 */
	XLOAD,		/* Jfconst_2 */
	XLOAD,		/* Jdconst_0 */
	XLOAD,		/* Jdconst_1 */
	XLOAD,		/* Jbipush */
	XLOAD,		/* Jsipush */
	XLOAD,		/* Jldc */
	XLOAD,		/* Jldc_w */
	XLOAD,		/* Jldc2_w */
	XLOAD,		/* Jiload */
	XLOAD,		/* Jlload */
	XLOAD,		/* Jfload */
	XLOAD,		/* Jdload */
	XLOAD,		/* Jaload */
	XLOAD,		/* Jiload_0 */
	XLOAD,		/* Jiload_1 */
	XLOAD,		/* Jiload_2 */
	XLOAD,		/* Jiload_3 */
	XLOAD,		/* Jlload_0 */
	XLOAD,		/* Jlload_1 */
	XLOAD,		/* Jlload_2 */
	XLOAD,		/* Jlload_3 */
	XLOAD,		/* Jfload_0 */
	XLOAD,		/* Jfload_1 */
	XLOAD,		/* Jfload_2 */
	XLOAD,		/* Jfload_3 */
	XLOAD,		/* Jdload_0 */
	XLOAD,		/* Jdload_1 */
	XLOAD,		/* Jdload_2 */
	XLOAD,		/* Jdload_3 */
	XLOAD,		/* Jaload_0 */
	XLOAD,		/* Jaload_1 */
	XLOAD,		/* Jaload_2 */
	XLOAD,		/* Jaload_3 */
	0,		/* Jiaload */
	0,		/* Jlaload */
	0,		/* Jfaload */
	0,		/* Jdaload */
	0,		/* Jaaload */
	0,		/* Jbaload */
	0,		/* Jcaload */
	0,		/* Jsaload */
	XSTORE,		/* Jistore */
	XSTORE,		/* Jlstore */
	XSTORE,		/* Jfstore */
	XSTORE,		/* Jdstore */
	XSTORE,		/* Jastore */
	XSTORE,		/* Jistore_0 */
	XSTORE,		/* Jistore_1 */
	XSTORE,		/* Jistore_2 */
	XSTORE,		/* Jistore_3 */
	XSTORE,		/* Jlstore_0 */
	XSTORE,		/* Jlstore_1 */
	XSTORE,		/* Jlstore_2 */
	XSTORE,		/* Jlstore_3 */
	XSTORE,		/* Jfstore_0 */
	XSTORE,		/* Jfstore_1 */
	XSTORE,		/* Jfstore_2 */
	XSTORE,		/* Jfstore_3 */
	XSTORE,		/* Jdstore_0 */
	XSTORE,		/* Jdstore_1 */
	XSTORE,		/* Jdstore_2 */
	XSTORE,		/* Jdstore_3 */
	XSTORE,		/* Jastore_0 */
	XSTORE,		/* Jastore_1 */
	XSTORE,		/* Jastore_2 */
	XSTORE,		/* Jastore_3 */
	0,		/* Jiastore */
	0,		/* Jlastore */
	0,		/* Jfastore */
	0,		/* Jdastore */
	0,		/* Jaastore */
	0,		/* Jbastore */
	0,		/* Jcastore */
	0,		/* Jsastore */
	0,		/* Jpop */
	0,		/* Jpop2 */
	0,		/* Jdup */
	0,		/* Jdup_x1 */
	0,		/* Jdup_x2 */
	0,		/* Jdup2 */
	0,		/* Jdup2_x1 */
	0,		/* Jdup2_x2 */
	0,		/* Jswap */
	0,		/* Jiadd */
	0,		/* Jladd */
	0,		/* Jfadd */
	0,		/* Jdadd */
	0,		/* Jisub */
	0,		/* Jlsub */
	0,		/* Jfsub */
	0,		/* Jdsub */
	0,		/* Jimul */
	0,		/* Jlmul */
	0,		/* Jfmul */
	0,		/* Jdmul */
	0,		/* Jidiv */
	0,		/* Jldiv */
	0,		/* Jfdiv */
	0,		/* Jddiv */
	0,		/* Jirem */
	0,		/* Jlrem */
	0,		/* Jfrem */
	0,		/* Jdrem */
	0,		/* Jineg */
	0,		/* Jlneg */
	0,		/* Jfneg */
	0,		/* Jdneg */
	0,		/* Jishl */
	0,		/* Jlshl */
	0,		/* Jishr */
	0,		/* Jlshr */
	0,		/* Jiushr */
	0,		/* Jlushr */
	0,		/* Jiand */
	0,		/* Jland */
	0,		/* Jior */
	0,		/* Jlor */
	0,		/* Jixor */
	0,		/* Jlxor */
	0,		/* Jiinc */
	0,		/* Ji2l */
	0,		/* Ji2f */
	0,		/* Ji2d */
	0,		/* Jl2i */
	0,		/* Jl2f */
	0,		/* Jl2d */
	0,		/* Jf2i */
	0,		/* Jf2l */
	0,		/* Jf2d */
	0,		/* Jd2i */
	0,		/* Jd2l */
	0,		/* Jd2f */
	0,		/* Ji2b */
	0,		/* Ji2c */
	0,		/* Ji2s */
	0,		/* Jlcmp */
	0,		/* Jfcmpl */
	0,		/* Jfcmpg */
	0,		/* Jdcmpl */
	0,		/* Jdcmpg */
	0,		/* Jifeq */
	0,		/* Jifne */
	0,		/* Jiflt */
	0,		/* Jifge */
	0,		/* Jifgt */
	0,		/* Jifle */
	0,		/* Jif_icmpeq */
	0,		/* Jif_icmpne */
	0,		/* Jif_icmplt */
	0,		/* Jif_icmpge */
	0,		/* Jif_icmpgt */
	0,		/* Jif_icmple */
	0,		/* Jif_acmpeq */
	0,		/* Jif_acmpne */
	0,		/* Jgoto */
	0,		/* Jjsr */
	0,		/* Jret */
	0,		/* Jtableswitch */
	0,		/* Jlookupswitch */
	0,		/* Jireturn */
	0,		/* Jlreturn */
	0,		/* Jfreturn */
	0,		/* Jdreturn */
	0,		/* Jareturn */
	0,		/* Jreturn */
	0,		/* Jgetstatic */
	0,		/* Jputstatic */
	0,		/* Jgetfield */
	0,		/* Jputfield */
	0,		/* Jinvokevirtual */
	0,		/* Jinvokespecial */
	0,		/* Jinvokestatic */
	0,		/* Jinvokeinterface*/
	0,		/* Jxxxunusedxxx */
	0,		/* Jnew */
	0,		/* Jnewarray */
	0,		/* Janewarray */
	0,		/* Jarraylength */
	0,		/* Jathrow */
	0,		/* Jcheckcast */
	0,		/* Jinstanceof */
	0,		/* Jmonitorenter */
	0,		/* Jmonitorexit */
	0,		/* Jwide */
	0,		/* Jmultianewarray */
	0,		/* Jifnull */
	0,		/* Jifnonnull */
	0,		/* Jgoto_w */
	0,		/* Jjsr_w */
};
