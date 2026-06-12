#!/bin/bash

[[ -e ${1:?"input file missing"} ]] || { echo "$1: no such file or directory" >&2; exit 1; }
[[ -r $1 ]] || { echo "$1: cannot open file: permission denied" >&2; exit 1; }

inst=$(grep -oe "[+-.,<>[]" -e "]" $1 | tr -d "\n")
declare -a stack
ind=0

check_brakets ()
{
    local b=0
    local br=$(echo $inst | grep -oe "\[" -e "\]")

    for c in $br; do
        [[ "$c" = '[' ]] && b=$((b+1)) || b=$((b-1))
        [[ $b -eq -1 ]] && return 1
    done 
    return $b
}

find_braket ()
{
    local pos=0
    op=${1:$pos:1}
    local b=0
    until [[ "$op" = ']' ]] && [[ $b -eq 1 ]]; do
        [[ "$op" = '[' ]] && b=$((b+1)) || { [[ "$op" = ']' ]] && b=$((b-1)); }
        pos=$((pos+1))
        op=${1:$pos:1}
    done
    echo "$pos"
}

check_brakets || { echo "error: mismatch bracket" >&2; exit 1; }

loop ()
{
    local pos=0
    local bpos=$pos
    while [[ ${#1} -gt 0 ]] do
        op=${1:$pos:1}
        case $op in
            ('+') stack[$ind]=$(((${stack[$ind]-0}+1)%256));;
            ('-') stack[$ind]=$(((${stack[$ind]-0}+255)%256));;
            ('<') [[ $ind -gt 0 ]] || { echo "error: index cannot be lower than 0" >&2; exit 1; } && ind=$((ind-1));;
            ('>') [[ $ind -lt 30000 ]] || { echo "error: index must be lower than 30000" >&2; exit 1; } && ind=$((ind+1));;
            ('.') printf "\x$(printf %x ${stack[$ind]=0})";;
            (',') stack[$ind]=$(read -N 1 c; printf "%d" "'$c");;
            ('[') [[ ${stack[$ind]=0} -ne 0 ]] && { loop "${1:$((pos+1))}"; };
                local off=$(find_braket "${1:pos}")
                pos=$((pos+$off));;
            (']') [[ ${stack[$ind]=0} -ne 0 ]] && { pos=$bpos; continue; } || { return 0; };;
            (*);;
        esac
        pos=$((pos+1))
    done
}

while [[ ${#inst} -gt 0 ]] do
    op=${inst:0:1}
    case "$op" in
        ('+') stack[$ind]=$(((${stack[$ind]-0}+1)%256));;
        ('-') stack[$ind]=$(((${stack[$ind]-0}+255)%256));;
        ('<') [[ $ind -gt 0 ]] || { echo "error: index cannot be lower than 0" >&2; exit 1; } && ind=$((ind-1));;
        ('>') [[ $ind -lt 30000 ]] || { echo "error: index must be lower than 30000" >&2; exit 1; } && ind=$((ind+1));;
        ('.') printf "\x$(printf %x ${stack[$ind]=0})";;
        (',') stack[$ind]=$(read -n 1 c; printf "%d" "'$c");;
        ('[') [[ ${stack[$ind]=0} -ne 0 ]] && { loop "${inst:1}"; }; inst=${inst:$(find_braket "$inst")};;
        ('*');;
    esac
    inst=${inst#?}
done
