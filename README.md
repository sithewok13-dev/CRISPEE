# CRISPEE

A small entitled terrier believes everything he pees on belongs to him, and the
world increasingly agrees. Close third-person exploration from dog height.

**Status: first playable, greybox.** All art and sound are placeholders. The
dog is built from primitives in code until the real Crispee model exists. He
never wears a diaper.

## The slice: "The Delivery"

Crispee wakes on the couch. Something smells good beyond the front door.

- Walk down the pet stairs (the couch is too high to hop back up without them).
- Claim the unclaimed delivery box. The human, resigned, labels it and moves it
  beside the bookshelf, and the claim becomes a step.
- Hop onto the box, then onto the shelf, grab the leash, and give it to the
  human. The human reads "walk" and opens the door.
- Optional: mark the furniture, bark at the door, claim the slippers, bring the
  human a sock or the squeaky toy, and sniff for hints.

## Controls

| | Touch (landscape) | Controller | Keyboard |
|---|---|---|---|
| Move | left thumb, floating stick | left stick | WASD |
| Look | drag on the right side | right stick | arrows / right-mouse drag |
| Hop / Grab / Give / Drop (contextual) | big button | A | Space |
| Mark | Mark (glows gold near something special) | B | E |
| Sniff (hint) | Sniff | X | R |
| Bark | Bark | Y | F |
| Pause | II | Start | Esc |

## Getting it on an iPhone (sideloading)

Every push runs `.github/workflows/ios.yml`:

1. **Linux:** imports the project, runs the headless playthrough test, and
   generates the Xcode project with Godot.
2. **macOS:** compiles it with **no code signing** and packages
   `Crispee-unsigned.ipa`.
3. Publishes the `.ipa` as a **GitHub pre-release** (`build-N`) and as a workflow
   artifact.

**Fallback: Codemagic.** If GitHub Actions can't run for the account,
`codemagic.yaml` does the same build on Codemagic's Macs. Sign in at
codemagic.io with GitHub, add this repository, and start the `ios-unsigned`
workflow. The `.ipa` appears under the build's artifacts.

An unsigned `.ipa` won't install as is. A sideloading tool re-signs it with
*your* Apple ID:

- **Sideloadly** (Windows/macOS) or **AltStore / SideStore**. Load
  `Crispee-unsigned.ipa`, then sign in with your Apple ID.
- On the iPhone: **Settings → Privacy & Security → Developer Mode → On**
  (requires a restart), then trust your Apple ID under **Settings → General →
  VPN & Device Management**.
- With a free Apple ID, the app expires after **7 days** and must be
  re-sideloaded. A paid Apple Developer account extends this to a year and
  enables TestFlight later.

Requires an iPhone with an A12 chip or newer (Godot's Metal renderer).

## Development

Godot **4.7.2-stable** is pinned (`project.godot`). Upgrade deliberately.

```sh
godot --headless --path . --import
godot --headless --path . --fixed-fps 60 res://tests/playthrough_test.tscn   # solves the slice end to end
```

### Layout

| Path | Responsibility |
|---|---|
| `scripts/input/input_router.gd` | Devices → intents. Gameplay never reads devices directly. |
| `scripts/ui/touch_controls.gd` | Multi-touch stick, buttons, camera drag; safe-area aware. |
| `scripts/player/crispee.gd` | Movement, step-up, contextual hop detection, mark/bark/sniff/grab/give. |
| `scripts/player/crispee_body.gd` | **Placeholder** body and procedural animation (gait, tail, ear springs, head look). |
| `scripts/camera/` | Close follow camera, recentering, collision, `CameraZone` overrides for tight spaces. |
| `scripts/interaction/interactable.gd` | What can be marked/grabbed, and reach scoring. |
| `scripts/npc/human.gd` | Human driven by a queue of small steps (walk, say, wait, face, sit, call). |
| `scripts/puzzles/delivery_puzzle.gd` | This slice's reactions, sniff hints, save restore and ending. |
| `scripts/core/` | `GameEvents` signal bus, `WorldState` flags/claims/save, synthesized placeholder `Sfx`. |
| `scripts/level/` | Greybox room and geometry helpers (real rooms will be authored scenes). |
