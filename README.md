# shellswain

shellswain is a neighborly bash library you can use to build simpler event-driven bash profile/bashrc scripts and modules.

## Incorporating shellswain

I package shellswain and its dependencies with Nix and resholve for my own use, so that's the easiest/recommended way to incorporate it into a project.

> **Note:** Aside from bash 5.1, shellswain's dependencies are pure bash. It doesn't _require_ Nix and should be easy enough to package/vendor/inline outside of the Nix ecosystem. You'll also need:
> - signal/trap namespacing provided by https://github.com/abathur/comity
> - the event API provided by https://github.com/bashup/events (this is pulled in via comity, since comity also uses it)

You can find a real-world example of how I do this in https://github.com/abathur/shell-hag. That project is a little complex, so I'll break down the basic steps:

1. Include it in your Bash source. I use a guard to avoid wasting time sourcing it again it in case more than one module uses shellswain:

    ```bash
    if [[ -z "$SHELLSWAIN_ABOARD" ]]; then
        # shellcheck disable=SC1090
        source shellswain.bash
    fi
    ```

    For reference, here's [the equivalent statement in shell-hag](https://github.com/abathur/shell-hag/blob/c282e2b7581e57d5df2be261ffc505af0c92a091/hag.bash#L8-L12).

2. Package your script/module with Nix + [resholve](https://github.com/abathur/resholve) and supply shellswain as a dependency. Here's a basic skeleton:

    ```
    { lib
    , resholve
    , shellswain
    }:

    resholve.mkDerivation rec {
      pname = "your_project";
      version = "unreleased";

      src = lib.cleanSource ./.;
      # src = fetchFromGitHub {
      #   owner = "you";
      #   repo = "${pname}";
      #   rev = "v${version}";
      #   sha256 = "...";
      # };

      solutions = {
        profile = {
          scripts = [ "bin/your_module.bash" ];
          interpreter = "none";
          inputs = [ shellswain ];
        };
      };

      # ...
    }

    ```

    If it isn't clear how to turn this into a working Nix expression, I recommend referring to:
    - shellswain's own [shellswain.nix](shellswain.nix) is a simple, complete example of how to use resholve with Nix
    - resholve's Nix API is documented in the [nixpkgs README for resholve](https://github.com/NixOS/nixpkgs/blob/master/pkgs/development/misc/resholve/README.md)

## Using shellswain

There are four main ~areas of shellswain's public API:

1. shellswain publishes events related to shell init/teardown:
    - `swain:before_first_prompt` (emitted the first time bash evaluates `PROMPT_COMMAND`)

      > **Note:** In early versions of shellswain this assumed ownership of `PROMPT_COMMAND`, though shellswain should now also be compatible with the new array-based `PROMPT_COMMAND`.

    - `swain:before_exit` (emitted on HUP and EXIT)

    Your code can subscribe to these events using the bashup.events API (see https://github.com/bashup/events for more). For example:

    ```bash
    event on swain:before_exit _your_teardown_function
    ```

2. shellswain publishes events before and after _every_ command invocation:
    - `swain:before_command` (emitted right after bash evaluates PS0)

      > **Note:** This does assume shellswain owns PS0. Your code can print whatever it would like as the before-command prompt by attaching a handler to the swain:before_command event.

    - `swain:after_command` (emitted each time bash evaluates `PROMPT_COMMAND` except the first; see `swain:before_first_prompt`)

3. if you instruct shellswain to "track" _specific_ commands, it will emit command-specific events before/run/after events.

    Command-specific tracking is designed to encourage a lazy-initialization pattern. The goal is to avoid doing setup work for commands until the user actually invokes them. This may feel like a lot of conceptual overhead if you only want to track a single command--but the goal is making sure shell startup time is snappy even if users/modules are tracking scores of commands.

    - You call `swain.track <command> <your_init_callback>` to bootstrap deferred tracking for a command. shellswain will run `your_init_callback <command>` the first time the user invokes the tracked command.

        > **Note:** `swain.track` can only register one init callback, but other modules (or user code, if you're building a layer over shellswain) can use `swain.hook.init_command <command> <callback> <all other args>` to subscribe to a one-time event that shellswain will emit immediately after running the init callback.
        >
        > These callbacks are invoked as `callback <command> [<other args>...]`.

    - You can then use either kind of init callback to set up command-specific event listeners (and perform any other init you need).

        When users run a tracked command, shellswain emits three command-specific "phase" events: `before`, `run`, and `after`.

        You can set up a listener by calling:
        `swain.phase.listen <phase> <command> <callback> [<other args>...]`

        shellswain will invoke your callback as:
        `callback <command> [<other args from swain.phase.listen>...] [<args the user invoked command with>...]`

        > **Note:** shellswain also has a mechanism for currying additional arguments to a phase. You can call `swain.phase.curry_args <phase> <command> [<other args>...]` to inject args before those from the user's invocation.
        >
        > Instead of spending a second on a long computation in both the before and after phases, this enables you to compute it once in the before phase and curry the result to the after phase.

        The `run` phase is ~special--it's responsible for actually running the command. If none of your init callbacks register a run phase listener, shellswain will register a default runner (that just runs the command).

        If you register a run phase listener, make sure it runs the command!

4. shellswain maintains a global `swain` variable with information about command run so that each plugin/module doesn't have to compute them independently. In the order they are recorded:

    Before the command runs:
    - `start_time`

       This is a human-readable datetime as reported by `printf '%(%a %b %d %Y %T)T'` (ex: "Sun Jan 15 2023 12:34:45").

    - `command_number`

       The command number as reported by `fc -lr -0`.

    - `command`

       The most-recently run command (unexpanded) as reported by `fc -lr -0`.

    - `start_timestamp`

       A microsecond-precision timestamp created by removing the `.` from `$EPOCHREALTIME` (ex: "1673807685512462").

       > Caution: This value will be slightly different during the `swain:before_command` and afterwards. It is recorded once before running any `swain:before_command` listeners, and updated after.
       >
       > shellswain does this so that it can both give _some_  timestamp to plugins that need one before the command runs and exclude the time `swain:before_command` listeners take to run from the `duration` it computes after the command runs.

    After the command runs (immediately before `swain:after_command` is emitted):
    - `end_timestamp`

       A microsecond-precision timestamp created by removing the `.` from `$EPOCHREALTIME` (ex: "1673800973404806").
    - `pipestatus`

       Command exit statuses as reported by `${PIPESTATUS[@]}` (ex: "0", "0 1 0").

    - `duration`

       How long the command took to run in microseconds as reported by `$((swain[end_timestamp] - swain[start_timestamp]))` (ex: "6687376").

       > Note: While the time taken to run `swain:before_command` and `swain:after_command` listeners are excluded from the calculated duration, it will still include whatever time it takes to run any phase listeners registered with `swain.phase.listen`.

    - `end_time`

       This is a human-readable datetime as reported by `printf '%(%a %b %d %Y %T)T'` (ex: "Sun Jan 15 2023 12:34:45").

    > **Caution:** shellswain updates the `swain` variable in place. If you use any after-command value during the `swain:before_command` event or any listener registered with swain.phase.listen, the values will still refer to the _previous_ command run.
    >
    > (This may sound like a footgun, but in some cases it is exactly the behavior you want. A session-oriented shell history plugin, for example, might need the previous command's end time to create a new history file when you go more than an hour without running a command.)

