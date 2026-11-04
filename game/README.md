# CRISPEE, the game

Godot 4.7.2 project. Territory 1, the living room, as a grey-box first playable.

## Controls

| | Phone | Keyboard | Controller |
|---|---|---|---|
| Move | left-half stick | WASD / arrows | left stick |
| Jump | JUMP | Space | A |
| Pee | PEE | E | B |
| Act (drink, bark) | ACT | F | X |
| Power (Pee Vision) | POWER | Q | Y |
| Camera nudge | swipe right half | | |

## Run it on Linux with screenshots

```
godot --path game --rendering-driver opengl3 --resolution 1280x720 -- --shots=/tmp/shots
```

Plays the level by script and saves one PNG per step. CI does this on every push and attaches the pictures to the run.

## The iPhone build

The `Build` workflow exports an Xcode project on a Mac runner, builds it without signing, and attaches `CRISPEE-iOS-unsigned.ipa`. Run it by hand with a release tag to publish the IPA to a release.

## Layout

- `scripts/game.gd`: claims, bladder, timer, best times (autoload `Game`)
- `scripts/crispee.gd`: the dog, movement, jump, pee, act
- `scripts/camera_rig.gd`: semi-automatic third-person camera
- `scripts/level_living_room.gd`: the room, Dad, the claims and what each one changes
- `scripts/human.gd`: a household human that walks, carries, and answers barks
- `scripts/pee_vision.gd` + `shaders/pee_vision.gdshader`: the yellow power and its drone
- `scripts/hud.gd`, `scripts/touch_controls.gd`: on-screen UI and phone controls
- `scripts/autotest.gd`: the scripted run used for screenshots
