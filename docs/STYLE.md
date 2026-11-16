# CRISPEE style guide: the quality bar

Every session reads this before touching the game. Every build is reviewed against it
(see `docs/REVIEW.md`). "Generic" means a build that would pass for any game. Nothing
below is optional polish; it is what makes the build CRISPEE's.

## 1. Crispee moves like a dog

- **Trot, not slide.** Legs cycle, the body bobs, the head bounces a beat behind the body.
  Speed up and the bob gets bigger. Stop and he overshoots half a step, then settles.
- **Turns skid.** A sharp turn tilts the body into it and the back legs slip a little.
- **Jump has anticipation.** A crouch before, stretched in the air, a squash on landing, ears
  and cape a beat late.
- **Idle is busy.** Leave him alone two seconds and he sniffs the floor. Five seconds and he
  sits. Ten and he scratches, then lies down. Any input snaps him up instantly.
- **Pee is a performance.** Walk-up, sniff the spot, leg lift, the puddle grows, a small
  full-body shake after, then he walks off like nothing happened.
- **Ears and cape are physics.** They react to every landing, turn and stop. Horns stay rigid.
- **Tail says mood.** Wags when moving toward something, up when he has just claimed, flat
  when the bladder is empty.

## 2. The world reacts, visibly

- Every claim produces something the player can **watch**, not only read. Dad walks over,
  picks the slipper up, looks at it, puts it down, puts his other foot in the remaining one.
- The toast is a caption for the scene, not a substitute. Three lines maximum, gone in four
  seconds.
- A world change should be noticeable from across the room: the box is somewhere else,
  the door is open, the lights are off.

## 3. The writing has a voice

- The HUD is Crispee's to-do list. Spot names carry attitude: "Dad's left slipper. He'll
  understand." Not "Dad's slipper."
- Toasts read like deadpan news headlines about a small dog. No exclamation marks. No
  emoji. Nobody explains the joke.
- Humans mumble. Their bubbles are short and resigned: "Fine. FINE." "Why is it so cold."
- Every level opens with a title card and a flyover of the spots, like a heist briefing.

## 4. Sound

- Claws on the floor, a different sound on the couch and on the box. Panting when he runs.
  A sniff. One bark. The stream, and the shake after it.
- A claim lands with a short stinger. Pee Vision has its drone, a swell in and a reverse out.
- Music: one sly theme, played sparse. Extra's version of it is lower and slower.
- Silence is a bug. If an action has no sound, it is not done.

## 5. Camera

- Dog height is the point. Default distance 2.3 m, height 1.15 m, looking slightly down.
  Furniture should loom.
- The camera never shows the inside of a wall. When pushed, it rises and looks down rather
  than clipping.
- No manual camera. It follows the heading, with a swipe nudge.

## 6. Look

- The room is the owner's actual living room: orange walls, black leather couch, the air
  conditioner box with its print, a crooked lamp, a photo of Crispee on the wall. Evening
  light, low and warm, long shadows.
- Crispee stays blocky on purpose, but deliberate: beard wedge, tuft, cloudy eyes, hanging
  cape ties, skinny legs, the worried expression.
- Palette: coat `#E9D7B4`, coat shadow `#CDB07A`, nose and eyes `#26211E`, costume red
  `#E8402A`, walls `#D9622B`. Yellow for anything pee-related: `#F6D34A`.
- UI font: one rounded, slightly hand-made face. Never the engine default.

## 7. Phone

- Buttons under the thumbs, 88 px, never over the action. Stick zone is the whole left half.
- Everything readable at arm's length. Nothing smaller than 14 px on the 1280x720 canvas.
- Landscape only. No status bar.

## 8. Done means

A feature is done when it has motion, sound, a visible consequence and a line of copy in
the voice above, and the reviewer could not call it generic.
