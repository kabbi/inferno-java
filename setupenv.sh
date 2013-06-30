export INFERNO_ROOT=$(pwd)
export EMU="-r$INFERNO_ROOT -g1024x600"
export PATH=$INFERNO_ROOT/MacOSX/386/bin:$PATH
alias emug="rlwrap -a blabla emu-g"
alias mkemu="mk install"
alias mkemug="mk install CONF=emu-g"
alias mkjava="cd java; mk install; cd .."

function ifind {
    find $1 | xargs grep -I $2
}
