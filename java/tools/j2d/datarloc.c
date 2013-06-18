#include "java.h"
#include "reloc.h"

/*
 * Manage module data relocation and instruction patch information.
 */

static	Ipatch	*dreloc;
static	int	Ipatchtid;

void
setIpatchtid(void)
{
	Ipatchtid = descid(1, 0, (uchar*)"");
}

/*
 * Add an instruction patch directive to ip.
 * (flag == SAVEINST) <=> runtime relocation: Inst* needed later
 * (flag == !SAVEINST) <=> other: pinfo expected in sequential order
 */

void
addIpatch(Ipatch *ip, Inst *i, int operand, int patchkind, int flag)
{

	if(ip->n >= ip->max) {
		ip->max += ALLOCINCR;
		ip->pinfo = Realloc(ip->pinfo, ip->max * sizeof(int));
		if(flag == SAVEINST)
			ip->i = Realloc(ip->i, ip->max * sizeof(Inst*));
	}
	ip->pinfo[ip->n] = (i->pc << 8) | operand | patchkind;
	if(flag == SAVEINST)
		ip->i[ip->n] = i;
	ip->n += 1;
}

static char *operand[] = {
	"?",
	"src",		/* PSRC >> 2 */
	"dst",		/* PDST >> 2 */
	"mid"		/* PMID >> 2 */
};

static char *mode[] = {
	"$x",		/* PIMM */
	"x(reg)",	/* PSIND */
	"n(x(reg))",	/* PDIND1 */
	"x(n(reg))"	/* PDIND2 */
};

static	schar	*ba;
static	int	nba;
static	int	szba;

static void
sizeba(int sz)
{
	if(sz > szba) {
		szba = sz;
		ba = Realloc(ba, szba * sizeof(schar));
	}
}

static void
fillba(Ipatch *ip)
{
	int i;
	int pclast, pcnext, delta, skip;

	sizeba(2*ip->n);
	pclast = 0;
	for(i = 0; i < ip->n; i++) {
		pcnext = ip->pinfo[i] >> 8;
		delta = pcnext-pclast;
		sizeba(nba + delta/1024 + 2);
		while(delta > 7) {
			skip = (delta > 1024) ? 1024 : delta & 0xfffffff8;
			ba[nba++] = -(skip >> 3);
			delta -= skip;
		}
		ba[nba++] = (delta << 4) | (ip->pinfo[i] & 0xf);
		pclast = pcnext;
	}
}

/*
 * Write Ipatch information to .s file.
 */

void
asmIpatch(int off, Ipatch *ip)
{
	int i;
	int reloff;		/* relative offset for array elements */
	int pc;

	if(ip == nil || ip->n == 0)
		return;

	fillba(ip);

	reloff = 0;
	asmarray(off, Ipatchtid, nba, reloff);
	pc = 0;
	for(i = 0; i < nba; i++) {
		Bprint(bout, "\tbyte\t@mp+%d,%d", reloff, (uchar)ba[i]);
		if(ba[i] < 0)
			pc += -ba[i] << 3;
		else
			pc += ba[i] >> 4;
		Bprint(bout, "\t# %d", pc);
		if(ba[i] > 0) {
			Bprint(bout, ", %s, %s", operand[(ba[i] >> 2) & 0x3],
				mode[ba[i] & 0x3]);
		}
		Bputc(bout, '\n');
		reloff += 1;
	}
	Bprint(bout, "\tapop\n");

	free(ba);
	ba = nil;
	nba = 0;
	szba = 0;
}

/*
 * Write Ipatch information to .dis file.
 */

void
disIpatch(int off, Ipatch *ip)
{
	int i;
	int reloff;		/* relative offset for array elements */

	if(ip == nil || ip->n == 0)
		return;

	fillba(ip);

	disarray(off, Ipatchtid, nba);
	reloff = 0;
	for(i = 0; i < nba; i++) {
		disbyte(reloff, (uchar)ba[i]);
		reloff += 1;
	}
	disapop();

	free(ba);
	ba = nil;
	nba = 0;
	szba = 0;
}

/*
 * Add instruction patch information to dreloc.
 */

void
addDreloc(Inst *i, int operand, int patchkind)
{
	if(dreloc == nil)
		dreloc = Mallocz(sizeof(Ipatch));
	addIpatch(dreloc, i, operand, patchkind, !SAVEINST);
}

/*
 * Write Dreloc information to .s file.
 */

void
asmDreloc(int off)
{
	asmIpatch(off, dreloc);
}

/*
 * Write Dreloc information to .dis file.
 */

void
disDreloc(int off)
{
	disIpatch(off, dreloc);
}
