
if [[ $# == 1 ]]; then
    sleep $1
fi


xmodmap -e 'remove mod4 = Super_R'
xmodmap -e 'keycode 134 = ISO_Level3_Shift NoSymbol ISO_Level3_Shift'
