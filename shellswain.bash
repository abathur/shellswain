# shellcheck shell=bash

# Naming patterns:
# - shellswain-specific functions and events start with "swain"
# - namespace separators: '.' for functions and ':' for events
# - use function _names for likely-internal behavior

# shellcheck disable=SC2154
if [[ -n "$SHELLSWAIN_ABOARD" ]]; then
	return
fi

shopt -s expand_aliases

# set an array-safe prompt command
export PROMPT_COMMAND=${PROMPT_COMMAND-}

# double-dip:
# - shellswain is loaded
# - record the index of shellswain's prompt command
SHELLSWAIN_ABOARD=${#PROMPT_COMMAND[@]}

# associative array, global, export
declare -Ax swain

# START POTENTIAL PLUGIN: PART A
function swain._record_start()
{
	# builtin printf much faster than external date
	# shellcheck disable=SC2102,SC2183
	printf -v swain[start_time] '%(%a %b %d %Y %T)T'

	swain[command_number]=$1
	swain[command]="${*:2}" # un-expanded

	# record timestamp, which we use to calculate duration, last
	swain[start_timestamp]="${EPOCHREALTIME/.}"
}

# immediately record start time; if we do a good job of optimizing
# where this falls in the overall load it can report rough startup time
swain._record_start 0 "#shellswain init"

function swain._record_end()
{
	# record timestamp, which we use to calculate duration, first
	swain[end_timestamp]="${EPOCHREALTIME/.}"
	swain[pipestatus]=$*
	swain[duration]=$((swain[end_timestamp] - swain[start_timestamp]))

	# shellcheck disable=SC2102,SC2183
	printf -v swain[end_time] '%(%a %b %d %Y %T)T'
}
# PAUSE POTENTIAL PLUGIN: part a

# save time if it's already loaded
[[ -v __comity_signal_map ]] || source comity.bash

# RESUME POTENTIAL PLUGIN: part b
event on swain:before_first_prompt @_ swain._record_end
event on swain:before_command @_ swain._record_start
event on swain:after_command @_ swain._record_end
# END POTENTIAL PLUGIN: part b


# SHELLSWAIN CORE:
function swain._after_command() {
	event emit "swain:after_command" "${PIPESTATUS[@]}"
	trap "swain._expand_PS0" SIGCHLD
}

function swain._before_first_prompt() {
	event emit "swain:before_first_prompt"
	PROMPT_COMMAND[$SHELLSWAIN_ABOARD]="swain._after_command"

	# The *INTENT* is that this only runs when no history could be loaded
	# However, up through at least bash 5.0, something like
	# echo $HISTCMD $(echo $HISTCMD $(set -H; echo $HISTCMD))
	# 254 1 1
	# demonstrates that history won't just "work" in the subshell, so
	# set -o history # we turned history on
	# AFAIK bash 5.1 has fixed this, so we'll disable the workaround.
	# Remove after 2023.

	# Just trying to trick bash into launching *exactly one* subshell
	# when it expands PS0 so we can trap the subshell exit. This enables
	# us to run code:
	#
	# - outside of the subshell context (to modify persistent variables)
	# - at the time bash expands PS0 (to track command start time)
	#
	# PS0 enables us to run arbitrary code before command time,
	# but it's all in a subshell (requiring files or hacks to send data
	# back to parent shell). SIGCHLD trap is the approach used by the
	# existing bash-preexec hook (which does give it at least one big
	# advantage: BASH_COMMAND is updated by the time debug trap runs,
	# but NOT by the time we trap this subshell exit; we can't use
	# BASH_COMMAND here and use fc instead.)
	#
	# values that didn't work here in bash 5.0 were:
	#   '', '$()', '$(:)', '$(true)'
	# the value that did was:
	#   '``'
	# This stopped working in bash 5.1, so I guess I was relying on bug
	# behavior. I've had to update this to '`:`' (which now works and
	# seems to be faster than '$(:)'). Note that this behavior change
	# may indicate that the previous emission of what seemed like one
	# sigchld for the subshell and one for anything run inside of it may
	# have itself been a bug (but keep an eye out for this shifting in
	# bash 5.2 again?)
	# shellcheck disable=SC2016,SC2034
	PS0='`:`'
	trap "swain._expand_PS0" SIGCHLD
}

# PROMPT_COMMAND usually runs after some other command,
# but it also gets run to show the initial prompt.
# Let's run a special routine the first time...
PROMPT_COMMAND+=("swain._before_first_prompt")

# The below may have been obsoleted. I've tried running w/o
# it and haven't seen any problems. Dump after 2023
# -H is history expansion (which is turned off by default in scripts)
# this enables fc to work from the script
# set -H


function swain._expand_PS0(){
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
	set -- $(fc -lr -0)
	# preferred $() syntax for above had a bug circa bash 5.0
	# that can mangle user commands if they have more than one
	# command substitution in them; IIRC bash fixed it, but go
	# ahead and retain this knowledge through 2023 in case it
	# bites you.
	set +o noglob

	event emit "swain:before_command" "$@"
}

trap "event emit 'swain:before_exit'" HUP EXIT

# shellswain has a slightly circuitous init model designed to defer
# work until it's necessary:
# - YOU tell swain WHAT to wrap, and give it a setup callback
# - only if/when the user ever actually invokes the wrapped command, swain will run your callback to fully scaffold any hooks you wanted to apply to the command
# <command> <init callback>
function swain.track(){
	# shellcheck disable=SC2139
	if [[ $(type -ft "$1") == "alias" ]]; then
		echo "shellswain doesn't currently track aliases ($1)"
		return 1
	else
		alias "$1=swain._init_command $1 $2"
		# TODO: There's still a lingering design issue/flaw here; if multiple modules consuming swain try to wrap the same command, there'll be a race condition on who gets to set up. I'm going to put off making a call here because the alias-blocking mechanism should (coincidentally) give the race-loser a clear error. We can cross this bridge if anyone actually wants it. Possibilities:
		# 1. append multiple functions to the same alias if it already exists
		# 2. turn this into an event (I'm trying to avoid the setup costs of this I assume); might be possible to flatten init_command somewhat in this case?
	fi
}

# <command> <init callback>
function swain._init_command(){
	# wire up the normal orchestrator
	# (I don't think swain needs to wire up its *own* before/after callbacks)
	event on "swain:command:$1:run" @_ "swain._run" "$1"

	# re-alias for subsequent runs
	# shellcheck disable=SC2139
	alias "$1=event emit swain:command:$1:run"

	# run <consumer init callback> <command>
	"$2" "$1"

	# give interested parties a chance to init
	# Note: "fire" even runs events added by callbacks
	event fire "swain:command:$1:init"

	# if no hook added a runner, set a default
	if ! event has "swain:phase:run:$1"; then
		# Note: if default runner ever needs to do anything more than just run this, make it a function
		event on "swain:phase:run:$1" @_ command "$1"

	fi

	# kick-off a one-time run of the whole command event cycle
	# (subsequent runs handled by alias)
	event emit "swain:command:$1:run" "${@:3}"
}

# register a callback (and args) for deferred one-time setup
# <command> <callback> <all other args>
function swain.hook.init_command(){
	event once "swain:command:$1:init" @_ "$2" "$1" "${@:3}"
}

# <phase> <command> <callback> [<other args>...]"
function swain.phase.listen(){
	event on "swain:phase:$1:$2" @_ "$3" "${@:4}"
}

function swain.phase._run(){ # <phase> <command> [<other args>...]
	event emit "swain:phase:${1}:${2}" "${@:3}"
}


function swain._run(){
# <phase> <command> [<other args>...]
	swain.phase._run "before" "$@"
	swain.phase._run "run" "$@"
	local ret=$?
	# historical note: at one point this also pulled the record_end again.
	# I think it was a mistake, or perhaps it was working around a bug that I
	# have since fixed? Feel free to delete this after 2023.
	# swain._record_end "${PIPESTATUS[@]}"
	# TODO: I won't do it presumptively, but note that I've thought about
	#       extracting the command-timing bits into a plugin; this staying
	#       dead is a precondition for that. Consider this after June 2023.
	swain.phase._run "after" "$@"
	return $ret
}

# curry some args for a specific phase+command pair
function swain.phase.curry_args(){ # "phase" "command" "other args..."
	event curry "swain:phase:$1:$2" "${@:3}"
}
