# Saltmire Trail

**One-call 2D motion trails / afterimages for Godot 4.**
Attach fading ghost copies to any sprite — instant dash, speed and juice.
One self-contained autoload, zero dependencies, MIT.

> Part of the Saltmire game-feel family (Juice · Transitions · FX · Trail).
> The paid **Impact** layer wires the whole family together so a full hit reads
> as one line — https://saltmire.itch.io/saltmire-impact

## Why

Motion trails sell speed and weight — dashes, dodges, projectiles, fast enemies.
Rolling your own means spawning ghost sprites, copying frames/flip/scale, and
fading them by hand every time. Trail does it in one call.

```gdscript
# continuous trail while the sprite moves
Trail.attach(player)

# a quick burst behind a dash / dodge
Trail.dash(player, 8)

# stop trailing — existing ghosts fade out naturally
Trail.detach(player)

# kill every live ghost right now
Trail.clear()
```

Works with `Sprite2D`, `AnimatedSprite2D` and `TextureRect` — it copies the
current frame, flip, rotation and scale automatically.

## Install

1. Copy `addons/saltmire_trail/` into your project's `addons/` folder.
2. **Project → Project Settings → Plugins → enable "Saltmire Trail".**
3. That registers the `Trail` autoload. Done.

## Tuning

Change the defaults once, globally, via `Trail.cfg` — or pass an overrides
dict per call:

```gdscript
Trail.attach(player, {
    "color": Color(0.4, 0.85, 1.0, 0.6),  # tint + start opacity
    "interval": 0.025,                    # seconds between ghosts
    "lifetime": 0.35,                     # fade-out duration
    "min_distance": 6.0,                  # px moved before a new ghost
    "scale_end": 0.4,                     # ghosts shrink as they fade
})
```

| Option            | Default              | What it does                          |
|-------------------|----------------------|---------------------------------------|
| `color`           | `Color(1,1,1,0.55)`  | ghost tint; alpha = start opacity     |
| `interval`        | `0.035`              | seconds between spawned ghosts        |
| `lifetime`        | `0.35`               | seconds each ghost takes to fade      |
| `min_distance`    | `5.0`                | min px moved before a ghost spawns    |
| `scale_end`       | `1.0`                | ghost scale multiplier at end of life |
| `modulate_source` | `true`               | tint by the source's own modulate     |
| `z_relative`      | `-1`                 | ghost z-index relative to source      |

## Demo

Open the project and run `demo/demo.tscn` — it cycles continuous trails, a
cyan speed trail, dash bursts and shrinking ghosts. Click or press **Space**
to skip ahead.

## License

MIT — free for any use, commercial or not. See `LICENSE.txt`.

https://saltmire.itch.io
