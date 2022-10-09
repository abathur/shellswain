if [[ -n "$HAVE_SHELLSWAIN" ]]; then
	source "$SHELLSWAIN"
fi
set -x
for i in {1..100}; do
	ls
done
