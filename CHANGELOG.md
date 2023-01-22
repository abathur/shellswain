# Changelog

## v0.3.0 (Jan 21 2023)
- add and document some basic usage examples
- nix:
  - update comity
  - add devShell for trying out shellswain interactively

## v0.2.0 (Jan 17 2023)
- stop exporting PROMPT_COMMAND
  
  Not 100% certain on this change, but I see a prompt plugin maintainer with clear conviction that exporting it is wrong.

## v0.1.0 (Jan 15 2023)
- refactor to clearly define public/private API and regularize naming
- draft initial documentation for those APIs
- adapt to bash 5.1 (replace workarounds for 5.0 bugs)
- add tests

---

## Prerelease
In 2018, the code that would eventually become shellswain started off as part of a larger shell history module project (eventually named [shell-hag](https://github.com/abathur/shell-hag)) in my shell profile. 

In 2019 I realized that shell-hag's logistic layer might make a good foundation for other projects, so I teased it out and created shellswain.

Since they weren't _designed_ as separate projects, this process left some messy cross-cutting naming patterns and responsibility boundaries where the projects bled together. 

I didn't want to cut a release without fixing this, but figuring out how to better integrate Bash/Shell projects with Nix was higher up my priority list. That yak-shave, which led to https://github.com/abathur/resholve, has kept me from getting back to this for a while.

This is all to say that shellswain is newly released in 2023, but I've been using it daily via my Bash profile for about 4 years already.
