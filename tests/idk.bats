load helpers

# the public API per shell-hag:

# TODO: abstract out all of this socat cruft

@test "can track commands" {
  require <({
    status 0
    line 1 begins "captured call to"
  })
} <<CASES
socat stdio exec:."/shellswain_track.bash cp --help",pty,setsid,echo=0,crlf
socat stdio exec:"./shellswain_track.bash shopt -p expand_aliases",pty,setsid,echo=0,crlf
socat stdio exec:"./shellswain_track.bash fern",pty,setsid,echo=0,crlf
CASES

# TODO: maybe worth figuring out a way to implement this. Mainly just a problem of figuring out how to "rename" the existing alias without losing any part of it. Worth searching for ~renaming a bash alias before inventing something
@test "can't track aliases" {
  require <({
    status 1
    line 1 equals "shellswain doesn't currently track aliases (alfred)"
    line 2 equals "hehe"
  })
} <<CASES
socat stdio exec:"./shellswain_track.bash alfred",pty,setsid,echo=0,crlf
CASES

@test "runs deferred one-time init hook" {
  require <({
    status 0
    line 1 begins "on_init"
  })
} <<CASES
socat stdio exec:."/shellswain_command_init_hook.bash cp --help",pty,setsid,echo=0,crlf
socat stdio exec:"./shellswain_command_init_hook.bash shopt -p expand_aliases",pty,setsid,echo=0,crlf
socat stdio exec:"./shellswain_command_init_hook.bash fern",pty,setsid,echo=0,crlf
CASES

@test "runs before/run/after hooks" {
  require <({
    status 0
    line 1 begins "before args"
    line 2 begins "run args"
    line 3 begins "after args"
  })
} <<CASES
socat stdio exec:."/swain_phase_listen.bash cp --help",pty,setsid,echo=0,crlf
socat stdio exec:"./swain_phase_listen.bash shopt -p expand_aliases",pty,setsid,echo=0,crlf
socat stdio exec:"./swain_phase_listen.bash fern",pty,setsid,echo=0,crlf
CASES


@test "track + init + before/after with args" {
  require <({
    status 0
    line 1 equals "PROMPT>"
    line 2 equals 'on_init'
    line 3 equals "before args --help"
    line -3 equals "after args weirdargbro --help"
    line -2 equals "PROMPT>"
    # this kinda tests history--but note that we do have to
    # synthesize the history addition with `history -s`--it
    # isn't a good/pure test of the shell's true behavior.
    line -1 equals "executed:cp --help"
  })
} <<CASES
socat stdio exec:."/shellswain_with_args.bash cp --help",pty,setsid,echo=0,crlf
CASES


