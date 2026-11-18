# Kael Prologue — Node Architecture

The cinematic is assembled in `scenes/ui/opening_cinematic.tscn`. The root `OpeningCinematic` script is a composition root only; behavior is divided among authored child nodes.

## Scene tree

- `OpeningCinematic` — composition root; connects component signals and owns the final scene-completion signal.
  - `Artwork` — authored TextureRect for the current still image.
  - `Shade` — authored atmosphere overlay.
  - `Caption` — editable narration label.
  - `AutoPlayButton` — authored playback toggle.
  - `SkipButton` — authored skip control.
  - `TimelineTrack/TimelineProgress` — authored progress display.
  - `CinematicFade` — authored end transition overlay.
  - `Sequence` — `KaelCinematicSequenceComponent`; loads the editable JSON shot list.
  - `Presentation` — `KaelCinematicPresentationComponent`; displays static images, narration and restrained fades.
  - `Playback` — `KaelCinematicPlaybackComponent`; owns current shot, manual advancement requests and optional timed autoplay.
  - `Input` — `KaelCinematicInputComponent`; owns touch/mouse taps and playback button signals.
  - `Audio` — `KaelCinematicAudioComponent`; starts and stops Kael's dedicated soundtrack.

## Ownership boundaries

- Shot order, image paths, captions, and durations remain in `kael_prologue_sequence.json`.
- Still artwork is never zoomed, panned, or animated by the presentation component.
- Manual touch/mouse input requests the next shot. Timed advancement occurs only when Auto Play is enabled.
- The title screen soundtrack remains The Frozen Kingdom and is started by the existing title startup flow.
- Fading Into the Void is requested only by the Kael cinematic audio component.

## Extension rule

Add new cinematic behavior as a dedicated scene node/component with one clear responsibility. Keep the root script limited to wiring signals and lifecycle. Do not add generic code-generated artwork or procedural visual elements.
