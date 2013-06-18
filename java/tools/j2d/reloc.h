enum {
	Rgetputfield		= 0x1 << 16,
	Rgetputstatic		= 0x2 << 16,
	Rinvokeinterface	= 0x3 << 16,
	Rinvokespecial		= 0x4 << 16,
	Rinvokestatic		= 0x5 << 16,
	Rinvokevirtual		= 0x6 << 16,

	Rstaticmp		= 0x8 << 16,
	Rspecialmp		= 0x10 << 16,

	PSRC			= 0x1 << 2,	/* patch source operand */
	PDST			= 0x2 << 2,	/* destination */
	PMID			= 0x3 << 2,	/* middle */

	PIMM			= 0x0,		/* patch immediate operand */
	PSIND			= 0x1,		/* single indirect offset */
	PDIND1			= 0x2,		/* 1st offset of double indirect */
	PDIND2			= 0x3,		/* 2nd offset */

	SAVEINST		= 1,		/* save Inst* for patching */

	LTCODE			= 0x1,		/* load-time resolution code */
	RTCODE			= 0x2,		/* run-time resolution code */
	RTCALL			= 0x4		/* call rtload() */
};

/* special fields */
#define	RCLASS	"@Class"
#define	RADT	"@adt"
#define	RJEX	"@jex"
#define	RMP	"@mp"
#define	RNP	"@np"
#define	ROBJ	"@obj"
#define	RSYS	"@sys"

/* special class name */
#define	RLOADER	"@Loader"

typedef	struct Ipatch	Ipatch;
typedef	struct Freloc	Freloc;
typedef	struct Creloc	Creloc;
typedef	struct RTReloc	RTReloc;
typedef	struct RTClass	RTClass;

struct Ipatch {
	int	n;		/* no. of significant elts. in pinfo & i */
	int	max;		/* number of elements pinfo & i can hold */
	int	*pinfo;		/* operand patch directives */
	Inst	**i;		/* instructions to patch (runtime relocation) */
};

/*
 * Load-time relocation.
 */

struct Freloc {
	char	*field;		/* field name */
	char	*sig;		/* Java type signature */
	uint	flags;		/* access flags */
	Ipatch	*ipatch;	/* instruction patch information */
	Freloc	*next;
};

struct Creloc {
	char	*classname;
	Freloc	*fr;
	Freloc	*tail;
	int	n;		/* number of elements in 'fr' */
};

/*
 * Run-time relocation.
 */

struct RTReloc {
	char	*field;		/* field name */
	char	*sig;		/* Java type signature */
	uint	flags;		/* access flags */
	Ipatch	*ipatch;	/* instruction patch information */
	RTReloc	*next;
};

struct RTClass {
	char	*classname;
	RTReloc	*rtr;
	RTReloc	*tail;
	int	n;		/* number of elements in 'rtr' */
	int	off;		/* Module Data offset */
};

/* datarloc.c */
extern	void	addDreloc(Inst*, int, int);
extern	void	asmDreloc(int);
extern	void	disDreloc(int);
extern	void	addIpatch(Ipatch*, Inst*, int, int, int);
extern	void	setIpatchtid(void);
extern	void	asmIpatch(int, Ipatch*);
extern	void	disIpatch(int, Ipatch*);

/* ltreloc.c */
extern	void	thisCreloc(void);
extern	Creloc	*getCreloc(char*);
extern	Freloc	*getFreloc(Creloc*, char*, char*, uint);
extern	void	LTIpatch(Freloc*, Inst*, int, int);
extern	int	LTrelocsize(void);
extern	void	LTrelocdesc(uchar*);
extern	int	asmCreloc(int);
extern	int	disCreloc(int);
extern	int	asmthisCreloc(int);
extern	int	disthisCreloc(int);
extern	int	doclinitinits;

/* rtreloc.c */
extern	RTClass	*getRTClass(char*);
extern	RTReloc	*getRTReloc(RTClass*, char*, char*, uint);
extern	void	RTIpatch(RTReloc*, Inst*, int, int);
extern	void	RTfixoff(int);
extern	void	doRTpatch(void);
extern	int	RTrelocsize(void);
extern	void	RTrelocdesc(uchar*, int);
extern	int	asmRTClass(int);
extern	int	disRTClass(int);
