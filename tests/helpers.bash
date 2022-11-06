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
