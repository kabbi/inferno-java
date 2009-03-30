implement Cipher;

include "sys.m";

include "keyring.m";
	kr: Keyring;
	RC4state: import kr;

include "sshio.m";

Cipherstate: adt
{
	enc: ref RC4state;
	dec: ref RC4state;
};

cs: ref Cipherstate;

id(): int
{
	return SSH_CIPHER_RC4;
}

init(key: array of byte, isserver: int)
{
	kr = load Keyring Keyring->PATH;
	if(isserver)
		cs = ref Cipherstate(kr->rc4setup(key[0:16]), kr->rc4setup(key[16:32]));
	else
		cs = ref Cipherstate(kr->rc4setup(key[16:32]), kr->rc4setup(key[0:16]));
}

encrypt(buf: array of byte, nbuf: int)
{
	kr->rc4(cs.enc, buf, nbuf);
}

decrypt(buf: array of byte, nbuf: int)
{
	kr->rc4(cs.dec, buf, nbuf);
}