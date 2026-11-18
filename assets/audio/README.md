# Reverie soundtrack integration

The authored AudioDirector is a persistent autoload with one looping music player and smooth fade transitions.

## Track assignments
- Crown of Ash and Rose: title screen / main menu.
- The Frozen Kingdom: active world exploration.
- Fading into the Void: reserved for Ravienne and Cassie's dedicated story scenes.

The existing opening cinematic is specifically Gerald and Lilith's prologue, so it intentionally does NOT use Fading into the Void. Call `AudioDirector.play_ravienne_cassie_story()` from the correct Ravienne/Cassie story scene when that content is connected.

Audio files are expected at:
- `assets/audio/music/crown_of_ash_and_rose.mp3`
- `assets/audio/music/the_frozen_kingdom.mp3`
- `assets/audio/music/fading_into_the_void.mp3`

The soundtrack asset ZIP contains those files in the correct project-relative folder structure.
