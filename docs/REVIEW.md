# Reviewing a build

A build is reviewed by a fresh session or sub-agent that has NOT built it, against
`docs/STYLE.md`. The reviewer gets the latest CI artifacts: the screenshot sheet and the
clip of the scripted playthrough. It never gets the builder's own opinion of the build.

## How to run it (any Claude session on this repo)

Say: "review the latest build". The session then:

1. Downloads the newest `screenshots` artifact from the Build workflow (the PNGs and
   `playthrough.mp4`), or runs the playthrough locally with `--shots` and `--record`.
2. Starts a separate reviewer agent with only: `docs/STYLE.md`, the screenshots, the clip,
   and `docs/PUNCHLIST.md` as it stands. Its brief is the one below.
3. Replaces `docs/PUNCHLIST.md` with the reviewer's list, commits it.

## The reviewer's brief

You are reviewing a build of CRISPEE, a comedy platformer about a small dog who claims
things by peeing on them. Read `docs/STYLE.md`. Look at every screenshot and the clip.
For each section of the style guide, say what the build does and does not do. Then write
a punch list: the ten things that most make this build feel generic, most damaging first,
each as one line a developer can act on, with the style-guide section it violates. Be
specific ("Crispee slides; no leg motion, no bob" not "animation needs work"). Do not
praise. Do not suggest features outside the style guide. End with one sentence: would a
stranger know this was CRISPEE and not any game.

## Punch list rules

- Top of the list is the next thing built. Nothing lower is touched first.
- An item leaves the list only when a later review no longer finds it.
- Items are numbered by damage, not by effort.
