set -e
limbo -I../../module -GS $1.b
sed -n '/^	link/s;.*,\(0x[^,]*\),"\(.*\)"$;/^	link.*"\2"$/s/0x[^,]*/\1/;p' $1.s > sign.sed
sed -f sign.sed $2.base | tr -d '\15' > $2.s
asm $2.s
rm $1.s
