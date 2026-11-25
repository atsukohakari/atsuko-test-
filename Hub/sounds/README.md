# sounds

the hub's own sounds. `Hub/modules/sounds.lua` plays them.

| file | what it is |
|---|---|
| `login/*.mp3`, `login/*.ogg` | the login voice: once the hub has finished loading, the one you picked plays, or a random one (never the same one twice in a row) |
| `click.mp3` | the click when you tap a button |
| `notify.mp3` | the notification sound |

the login voice waits until the hub is fully loaded and the game isn't lagging, never plays over a voice that is still talking (also when you `-reload`), and waits a few seconds between voices. Settings > General > Sounds > Login voice lists the lines by character name: tap one to keep it, or Random. the three sounds are always on, the volume slider sets how loud, and no notification sound plays over the voice. safe mode leaves the voice out.

## adding a login line

drop the file in `login/` and that's it. the hub reads the folder (from github, or from your folder when you run it locally) and lists every mp3 or ogg in it, no need to touch `sounds.json`.

it names the line from the file name, the same way Blue Archive's own files are named:

| file | shows up as |
|---|---|
| `Shiroko_LogIn_1.ogg.mp3` | Shiroko |
| `Mika_Swimsuit_LogIn_1.ogg.mp3` | Mika (Swimsuit) |
| `Hoshino_Swimsuit_EventLogin_2.ogg.mp3` | Hoshino (Swimsuit) |
| `haruka_dress.mp3` | Haruka (Dress) |

two lines with the same name get a number (`Haruka (Dress) 2`). letters, numbers, spaces, `_`, `-`, `.` and `( )` work in the name. it plays for as long as the file is.

`sounds.json` is only for picking a name yourself or saying how long a line is:

```json
{ "file": "login/your_line.mp3", "name": "Who says it", "seconds": 2.5 }
```

a line in `sounds.json` whose file isn't in the folder anymore is left out. new files show up the next time the hub loads its script list (when it starts, or every few minutes with auto refresh on). at most 60 lines.

the hub saves its copy of each sound in `AtsukoHub/sounds/` and plays it through `getcustomasset`, so the executor needs file functions for these sounds. without them the hub stays quiet: it never falls back to Roblox's own click or ping.

## where they come from

the voice lines and the click and notification sounds are from Blue Archive (Nexon Games and Yostar) and belong to them. `click.mp3` and `notify.mp3` were trimmed so they start at once and made louder, the voice lines are as they were.
