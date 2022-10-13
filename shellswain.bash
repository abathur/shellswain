# shellcheck shell=bash
# shellcheck disable=SC2154
if [[ -n "$SHELLSWAIN_ABOARD" ]]; then
	return
fi

SHELLSWAIN_ABOARD=1

# associative array, global, export
declare -Ax shellswain

# local reference for shorter use
declare -n cox=shellswain

# START POTENTIAL PLUGIN: PART A
function __record_start()
{
	cox[command_number]=$1
	cox[command]="${*:2}" # un-expanded
	cox[start_timestamp]="${EPOCHREALTIME/.}"

	# builtin printf much faster than external date
	# shellcheck disable=SC2102,SC2183
	printf -v cox[start_time] '%(%a %b %d %Y %T)T'
}

# immediately record start time; if we do a good job of optimizing
# where this falls in the overall load it can report rough startup time
__record_start 0 "#shellswain init"


function __record_end()
{
	cox[pipestatus]=$*
	cox[end_timestamp]="${EPOCHREALTIME/.}"

	# shellcheck disable=SC2102,SC2183
	printf -v cox[end_time] '%(%a %b %d %Y %T)T'
	cox[duration]=$((cox[end_timestamp] - cox[start_timestamp]))
}
# PAUSE POTENTIAL PLUGIN: part a

# if bashup_ev doesn't exist, source comity.bash
# (which also pulls in bashup.events)
[[ -v "bashup_ev[@]" ]] || source comity.bash

# RESUME POTENTIAL PLUGIN: part b
event on before_first_prompt @_ __record_end
event on before_command @_ __record_start
event on after_command @_ __record_end
# END POTENTIAL PLUGIN: part b


# SHELLSWAIN CORE:
function __after_command() {
	event emit after_command "${PIPESTATUS[@]}"
	trap __expand_PS0 SIGCHLD
}

function __before_first_prompt() {
	event emit "before_first_prompt"
	export PROMPT_COMMAND="__after_command"

	# The *INTENT* is that this only runs when no history could be loaded
	# However:
	# echo $HISTCMD $(echo $HISTCMD $(set -H; echo $HISTCMD))
	# 254 1 1
	# demonstrates that history won't just "work" in the subshell, so
	set -o history # we turn history on

	# Just trying to trick bash into launching *exactly one* subshell
	# when it expands PS0 so we can trap the subshell exit. This enables
	# us to run code:
	#
	# - outside of the subshell context (to modify persistent variables)
	# - at the time bash expands PS0 (to track command start time)
	#
	# PS0 enables us to run arbitrary code before command time,
	# but it's all in a subshell (requiring files or hacks to send data
	# back to parent shell). DEBUG trap is the approach used by the
	# existing bash-preexec hook (which does give it at least one big
	# advantage: BASH_COMMAND is updated by the time debug trap runs,
	# but NOT by the time we trap this subshell exit; we can't use
	# BASH_COMMAND here and use fc instead.)
	#
	# values that didn't work here: "", "$()", "$(:)", "$(true)"
	# shellcheck disable=SC2016,SC2034
	PS0='``'
	trap __expand_PS0 SIGCHLD
}

# PROMPT_COMMAND usually runs after some other command,
# but it also gets run to show the initial prompt.
# Let's run a special routine the first time...
export PROMPT_COMMAND="__before_first_prompt"

# -H is history expansion (which is turned off by default in scripts)
# this enables fc to work from the script
set -H

function __expand_PS0(){
	# We only want the first SIGCHLD
	# remove the trap so it only fires once
	trap - SIGCHLD

	# noglob enables us to abuse how "$@" works
	# to get each arg quoted to avoid expansion
	# and give the handling hook the choice
	# of whether to force expansion or not
	set -o noglob

	# $1 will be the command number, the command is the rest
	# shellcheck disable=SC2006,SC2046
	# -l lists, -r reverses, -0 is the "newest" item (rest just discards error)
	set -- `fc -lr -0 2>/dev/null` # swallow "history specification out of range"
	# preferred syntax for above has a bug that can break some user commands
	# if they have more than one command substitution in them; revert if the bug is fixed
	# set -- $(fc -lr -0 2> /dev/null)
	# TODO: try swapping this back when all else is stable
	set +o noglob

	event emit before_command "$@"
}

trap "event emit 'before_exit'" HUP EXIT

# TODO: document fully, but the idea behind the whole model here is designed around deferring work until it's necessary.
# - YOU tell swain WHAT to wrap, and give it a setup callback
# - only if/when the user ever actually invokes the wrapped command, swain will run your callback to fully scaffold any hooks you wanted to apply to the command
# TODO: There's still a lingering design issue/flaw here; if multiple modules consuming swain try to wrap the same command, there'll be a race condition on who gets to set up. I guess maybe we could append multiple functions to the same alias if it already exists or something.
# <command> <init callback>
function __shellswain_track(){
	# shellcheck disable=SC2139
	if [[ $(type -ft "$1") == "alias" ]]; then
		echo "shellswain doesn't currently track aliases ($1)"
		return 1
	else
		alias "$1=__shellswain_init_command $1 $2"
	fi
}

# <command> <init callback>
function __shellswain_init_command(){
	# wire up the normal orchestrator
	# (I don't think swain needs to wire up its *own* before/after callbacks)
	event on "__shellswain_command_$1" @_ "__swain_run" "$1"

	# re-alias for subsequent runs
	# shellcheck disable=SC2139
	alias "$1=event emit __shellswain_command_$1"

	# run <consumer init callback> <command>
	"$2" "$1"

	# give interested parties a chance to init
	# Note: "fire" even runs events added by callbacks
	# TODO: This was accidentally currying arguments from the first run into all runs (but fix may also break things); clear this if a decent test suite doesn't suss out issues. It was: event fire __shellswain_init_command_$1 "${@:3}" The fix is probably not passing these args...
	event fire "__shellswain_init_command_$1"

	# if no hook added a runner, set a default
	if ! event has "run_$1"; then
		# Note: if default runner ever needs to do anything more than just run this, make it a function
		event on "run_$1" @_ command "$1"

	fi

	# kick-off a one-time run of the whole command event cycle
	# (subsequent runs handled by alias)
	event emit "__shellswain_command_$1" "${@:3}"
}

# <command> <callback> <all other args>
function __shellswain_command_init_hook(){
	event once "__shellswain_init_command_$1" @_ "$2" "$1" "${@:3}"
}

# <phase> <command> <callback> [<other args>...]"
function __swain_phase_listen(){
	event on "$1_$2" @_ "$3" "${@:4}"
}

function __swain_phase_run(){ # "phase" "command" "other args..."
	local phase=$1 target=$2
	shift 2

	event emit "${phase}_${target}" "${@}"
}

function __swain_run(){
	__swain_phase_run "before" "$@"
	__swain_phase_run "run" "${@}"
	local ret=$?
	__record_end "${PIPESTATUS[@]}"
	__swain_phase_run "after" "$@"
	return $ret
}

# hack curry functionality atop bashup.events
# TODO: if you make a modular build process to separate the core/plugin parts, consider also extracting this bit?
declare -gA _ev_curried
__swain_event_curry() {
	if ! [[ -v "_ev_curried[$1]" ]] ; then # no key == first time setup
		# inject our var; clear it (unset is slower); original string
		bashup_ev[$1]="set -- \"$1\" \${_ev_curried[$1]} \"\${@:2}\"; _ev_curried[$1]=''; ${bashup_ev[$1]}"
	fi

	# add args to our var
	# shellcheck disable=SC2124
	_ev_curried[$1]+="${@:2} "
}

function __swain_curry(){ # "phase" "command" "other args..."
	# NOTE: quoted arrays per shellcheck, in case they bug out
	local -a to_curry
	for i in "${@:3}"; do
		to_curry+=("$i=${!i}")
	done
	__swain_event_curry "$1_$2" "${to_curry[@]}"
}
