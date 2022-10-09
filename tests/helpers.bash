# setup_file(){
#   echo "test,shellswain?,comity?,duration" >> "$out/timings"
#   export TEST_TMP="$(mktemp -d)"
#   cp tests/*.{bats,bash} "$TEST_TMP"/ > /dev/null
#   pushd "$TEST_TMP"
#   PATH="$TEST_TMP:$PATH"
# } &> /dev/null

# teardown_file(){
#   popd
#   # separator
#   echo "" >> "$out/timings"
# }

setup() {
    {
        TEST_TMP="$(mktemp -d)"
        cp tests/*.{bats,bash} "$TEST_TMP"/ > /dev/null
        pushd "$TEST_TMP"
    } > /dev/null
}
teardown() {
    {
        popd > /dev/null
    } > /dev/null
}

# status <num>
_expect_status() {
    if [[ $status != "$1" ]]; then
        return 1
    fi
}

# line (-)<num> equals|contains|begins|ends|!equals|!contains|!begins|!ends "value"
# CAUTION: one gotcha; blank lines not included; you have to
# adjust down for each one
_expect_line() {
    if [[ $1 -lt 0 ]]; then
        let lineno=$1
    else
        # adjust to 0-index
        let lineno=$1-1 || true # 1-0 causes let to return 1
    fi

    local line=${lines[$lineno]} kind=$2
    case $kind in
        equals)
            if [[ $line == "$3" ]]; then
                return 0
            else
                echo "  expected line $1:"
                echo "     '$3'"
                echo "  actual:"
                echo "     '$line'"
                return 1
            fi
            ;;
        contains)
            if [[ $line == *"$3"* ]]; then
                return 0
            else
                echo "  expected line $1:"
                echo "     '$3'"
                echo "  actual:"
                echo "     '$line'"
                return 1
            fi
            ;;
        begins)
            if [[ $line == "$3"* ]]; then
                return 0
            else
                echo "  expected line $1 to begin with:"
                echo "     '$3'"
                echo "  actual line:"
                echo "     '$line'"
                return 1
            fi
            ;;
        ends)
            if [[ $line == *"$3" ]]; then
                return 0
            else
                echo "  expected line $1 to end with:"
                echo "     '$3'"
                echo "  actual line:"
                echo "     '$line'"
                return 1
            fi
            ;;
        !equals)
            if [[ $line != "$3" ]]; then
                return 0
            else
                echo "  expected line $1:"
                echo "     '$3'"
                echo "  actual:"
                echo "     '$line'"
                return 1
            fi
            ;;
        !contains)
            if [[ $line != *"$3"* ]]; then
                return 0
            else
                echo "  expected line $1:"
                echo "     '$3'"
                echo "  actual:"
                echo "     '$line'"
                return 1
            fi
            ;;
        !begins)
            if [[ $line != "$3"* ]]; then
                return 0
            else
                echo "  expected line $1 to begin with:"
                echo "     '$3'"
                echo "  actual line:"
                echo "     '$line'"
                return 1
            fi
            ;;
        !ends)
            if [[ $line != *"$3" ]]; then
                return 0
            else
                echo "  expected line $1 to end with:"
                echo "     '$3'"
                echo "  actual line:"
                echo "     '$line'"
                return 1
            fi
            ;;
    esac
    # shouldn't get here
    echo "unexpected input: $@"
    return 2
}

function __describe_duration()
{
  local d="$1"
  # new version, save time, direct math:
  if   ((d >  3600000000)); then                 # >1   hour
    local m=$(((((d/1000) / 1000) / 60) % 60))
    local h=$((((d/1000) / 1000) / 3600))
    printf "%dh%dm" $h $m
  elif ((d >  60000000)); then                   # >1   minute
    local s=$((((d/1000) / 1000) % 60))
    local m=$(((((d/1000) / 1000) / 60) % 60))
    printf "%dm%ds" $m $s
  elif ((d >= 10000000)); then                   # >=10 seconds
    local ms=$(((d/1000) % 1000))
    local s=$((((d/1000) / 1000) % 60))
    printf "%d.%ds" $s $((ms / 100))
  elif ((d >=  1000000)); then                    # > 1  second
    local ms=$(((d/1000) % 1000))
    local s=$((((d/1000) / 1000) % 60))
    printf "%d.%ds" $s $((ms / 10))
  elif ((d >=  100000)); then                    # > 100  ms
    local ms=$(((d/1000) % 1000))
    printf "%dms" $ms
  elif ((d >=  20000)); then                    # > 20  ms
    local ms=$(((d/1000)))
    # printf "%dms" $ms
    printf "%d.%dms" $ms $((d % 10))
  elif ((d >=  10000)); then                    # > 10  ms
    local ms=$(((d/1000)))
    # printf "%dms" $ms
    printf "%d.%dms" $ms $((d % 100))
  elif ((d >=  1000)); then                    # > 1  ms
    local ms=$(((d/1000)))
    # printf "%dms" $ms
    printf "%d.%dms" $ms $((d % 1000))
  else                                              # < 1  ms (1000 µs)
    printf "%dµs" "$d"
  fi
}

status() {
    echo "_expect_status ${@@Q}"
}

line() {
    echo "_expect_line ${@@Q}"
}

# cases are on STDIN
# expectations in fd passed as arg 1
require() {
    mapfile _cases
    mapfile _expectations < "$1"

    # TODO: I'd like to print numbers by these in the TAP output, but contrary to the docs they're leaking into the pretty-print output. Worth trying after the next bats version bump.
    # casenum=0
    for case in "${_cases[@]}"; do
        # ((casenum = casenum + 1))#
        run eval "${case@E}"
        # echo "#  ${BATS_TEST_NUMBER}-${casenum}: ${case%$'\n'}" >&3
        printf "status: %s\n" $status
        printf "output:\n%s" "$output"

        echo ""
        echo "expectations:"
        echo "${_expectations[@]}"
        for expected in "${_expectations[@]}"; do
            echo "expected=${expected%$'\n'}"
            eval "$expected"
        done

        # TODO: this is probably a little faster
        # but it was only respecting the last line
        # and my efforts to shim in errexit weren't
        # working for some reason and it's hard to debug down under bats.
        # if ! source "$1"; then

        #     # eval "$case"
        #     false
        # fi

    done
}

timeit(){
    local result duration end start="${EPOCHREALTIME/.}"
    # bash --norc --noprofile -i "$TEST_TMP/$1"
    # TODO: move the timing into the scripts to avoid measuring
    # the time to run footprint/tail/awk?
    bash --norc --noprofile -i "$TEST_TMP/$1" &> $out/trace${HAVE_SHELLSWAIN/1/_shellswain}${HAVE_COMITY/1/_comity}
    end="${EPOCHREALTIME/.}"
    duration=$((end - start))
    echo "'$BATS_TEST_DESCRIPTION',${HAVE_SHELLSWAIN/1/y},${HAVE_COMITY/1/y},$(__describe_duration $duration)" >> "$out/timings"
} # 2>/dev/null # obviously, disable to debug...

timings(){
    # echo "----,----,----,----" >> "$out/timings"
    timeit "bare.bash"
    HAVE_SHELLSWAIN=1 timeit "bare.bash"
    HAVE_COMITY=1 HAVE_SHELLSWAIN=1 timeit "bare.bash"
    timeit "shellswain.bash"
    HAVE_SHELLSWAIN=1 timeit "shellswain.bash"
    HAVE_COMITY=1 HAVE_SHELLSWAIN=1 timeit "shellswain.bash"
}

__tracktrack="${EPOCHREALTIME/.}"
_timeit(){
    set +x
    local _trucktruck="${EPOCHREALTIME/.}"
    # bash --norc --noprofile -i "$TEST_TMP/$1"
    # TODO: move the timing into the scripts to avoid measuring
    # the time to run footprint/tail/awk?
    echo "$(__describe_duration $((_trucktruck - __tracktrack)))"
    declare -g __tracktrack="${EPOCHREALTIME/.}"
    set -x
}
__goober(){
    echo buncha goobs
}
__hmm(){
    : first
    :
    :
    __goober
    true
    false
    : last
}
microfine(){
    PS4='+ ${EPOCHREALTIME/.} '
    set -x
    : start timer
    "$@"
    : end timer
    : clear
    set +x
    unset PS4
} {BASH_XTRACEFD}> >(__hum)
__hum(){
    local prev_depth prev_time prev_rest
    while read -r _depth _time _rest; do
        if [[ $prev_time > 0 ]]; then
            echo "$prev_depth $(__describe_duration $((_time - prev_time))) $prev_rest"
        fi
        prev_time=$_time prev_rest=$_rest prev_depth=$_depth
    done
}
