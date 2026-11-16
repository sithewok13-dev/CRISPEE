---
name: review-build
description: Review the latest CRISPEE build against docs/STYLE.md with a fresh-eyes reviewer agent and rewrite docs/PUNCHLIST.md. Use when the user says "review the build", "review the latest build", or asks what makes the build feel generic.
---

Follow `docs/REVIEW.md` exactly. In short:

1. Get the newest `screenshots` artifact from the Build workflow (PNGs plus `playthrough.mp4`), or run
   `godot --path game --rendering-driver opengl3 --resolution 1280x720 -- --shots=DIR --record`
   under xvfb and then `game/tools/make_clip.sh DIR`.
2. Make a motion sheet from the clip (`ffmpeg -i playthrough.mp4 -vf "fps=1.5,scale=426:240,tile=6x4" sheet_%d.jpg`).
3. Start a separate general-purpose agent. Give it ONLY the reviewer's brief from `docs/REVIEW.md`, the path to
   `docs/STYLE.md`, the screenshot paths, the motion sheets and `docs/PUNCHLIST.md`. Never your own view of the build.
4. Write its punch list to `docs/PUNCHLIST.md`, commit, and tell the user the top three items.
