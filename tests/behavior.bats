bats_load_library bats-require
load helpers

# TODO: abstract out all of this unbuffer cruft?

@test "can track commands" {
  require <({
    status 0
    line 1 begins "captured call to"
  })
} <<CASES
unbuffer ./shellswain_track.bash cp --help
unbuffer ./shellswain_track.bash shopt -p expand_aliases
unbuffer ./shellswain_track.bash fern
CASES

# TODO: maybe worth figuring out a way to implement this. Mainly just a problem of figuring out how to "rename" the existing alias without losing any part of it. Worth searching for ~renaming a bash alias before inventing something
@test "can't track aliases" {
  require <({
    status 1
    line 1 equals "shellswain doesn't currently track aliases (alfred)"
    line 2 equals "hehe"
  })
} <<CASES
unbuffer ./shellswain_track.bash alfred
CASES

@test "runs deferred one-time init hook" {
  require <({
    status 0
    line 1 begins "on_init"
  })
} <<CASES
unbuffer ./shellswain_command_init_hook.bash cp --help
unbuffer ./shellswain_command_init_hook.bash shopt -p expand_aliases
unbuffer ./shellswain_command_init_hook.bash fern
CASES

@test "runs before/run/after hooks" {
  require <({
    status 0
    line 1 begins "before args"
    line 2 begins "run args"
    line 3 begins "after args"
  })
} <<CASES
unbuffer ./swain_phase_listen.bash cp --help
unbuffer ./swain_phase_listen.bash shopt -p expand_aliases
unbuffer ./swain_phase_listen.bash fern
CASES


@test "track + init + before/after with args" {
  require <({
    status 0
    line 1 equals "PROMPT>"
    line 2 equals 'on_init'
    line 3 equals "before args --help"
    line 4 begins "Usage: cp" # make sure it ran!
    line -3 equals "after args weirdargbro --help"
    line -2 equals "PROMPT>"
    # this kinda tests history--but note that we do have to
    # synthesize the history addition with `history -s`--it
    # isn't a good/pure test of the shell's true behavior.
    line -1 equals "executed:cp --help"
  })
} <<CASES
unbuffer ./shellswain_with_args.bash cp --help
CASES


