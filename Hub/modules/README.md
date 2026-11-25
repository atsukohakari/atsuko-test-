# hub modules

`Hub/AtsukoHub.lua` is the hub. everything new lives in its own file in this folder and is loaded by name the first time it is needed (`Core.loadModule("name")`), so a broken module shows an error on its own page instead of stopping the hub.

a module is a file that returns a table. if the table has `init(ctx)` it is called once with the shared context (the hub's own tools: `UI`, `T` for the theme, `S` for the settings, `Bus`, `Log`, `notify`, `copyText`, `saveSettings`, `Cmd`, `Players`, `LP` and more), and `destroy()` is called when the hub closes. a module takes everything it needs from `ctx`, it never reaches for `game` services the hub already wraps.

when you run the hub from a folder (`getgenv().AtsukoLocalRoot`) the modules are read from that folder. on github they are fetched from `Hub/modules/` and a copy is kept for offline use. push this whole folder, `cmds/` included.

| module | what it does |
|---|---|
| `alignment`, `alignment_ui` | the hat list (`Alignment/alignment.lua`), the per-script hat matcher in `getgenv().AtsukoAlignment`, the add command's words and its gun or sword guess, each hat's own alignment spot (`tracker`, driven by the hub while a script runs) and the Hats & alignment screen (body parts and jobs in one script) |
| `chathook` | the opt-in chat hook (off by default) |
| `commands_page` | the Commands tab |
| `credits_ui` | the Credits button on About and the credits window it opens (`Hub/credits.json`, pictures in `Hub/credits/`) |
| `diagnostics` | the text behind Settings > About > Copy diagnostics |
| `dispatch`, `prefix` | the one command dispatcher and the one prefix |
| `edge`, `inputmode` | the touch arrow and the touch or desktop decision |
| `home_page` | the Home tab |
| `imagebrowser`, `imagepicker`, `imgsniff`, `scriptart` | the logo and banner of each script |
| `island`, `island_state` | the dynamic island |
| `manifest` | `Scripts/manifest.json` |
| `notify_router` | turns other scripts' pop-ups into hub toasts (opt-in hook), and gives the ones it leaves alone the hub's notification time |
| `reanim`, `reanim_host`, `reanim_ui` | the four reanimations: registry, controller (the hat pick, asked for before the first hat script, switching one hat script for another without deanimating and on the fake body, and putting the camera, mouse and gravity back on deanimate) and the reanimation cards |
| `relay` | live view: sends your fake body, your scripts' parts and sounds to the other hub users in your server through the relay in `Relay/`, and draws theirs smoothly on your screen |
| `emoteweapons` | where a gun (right wrist) and a sword (back) go while you dance, and which of your hats is which |
| `resizer` | resizing the editor window |
| `settings_colors` | Settings > Themes > My colors and the rainbow background |
| `verified` | the verified badge: how it is drawn and the chat window callback that makes room for it after a name |
| `nametag` | the badge above someone's head, in Roblox's own font: hides Roblox's own name for that player on your screen and draws it again with the badge, and puts it back when the badge goes |
| `badgeview` | draws the badge into Roblox's own chat window, the leaderboard, the Roblox menu's people list and a game's own name tags above heads (after the name, never the @username), finding each player's row, card or body |
| `servertime` | the server clock behind `serverinfo` and Home's uptime: the game's own start time when it keeps one, otherwise counted from the first time you were in that server (`AtsukoHub/servers.json`) |
| `sounds` | the hub's own sounds (`Hub/sounds/`): the login voice that plays once the hub has finished loading (every file in `Hub/sounds/login/` counts, named from its file name), and the click and notification sounds |

## cmds/

the command packs. nothing here runs until the hub has been up for about two seconds.

| file | what it is |
|---|---|
| `_meta.lua` | the name, usage and description of every planned command (generated from the catalogue, 286 rows) |
| `_kit.lua` | the helpers every pack uses: reading numbers, the calculator, the chat rate limit and `Kit.build(ctx)`, which makes the `kit` a pack gets |
| `_targets.lua` | the player words (`me`, `all`, `others`, `random`, `nearest`, `friends`, `team:name`, `@userid`, `-name`) with no Roblox in it |
| `info`, `world`, `camera`, `character`, `tools`, `targeting`, `extras`, `automation` | the packs |

a pack returns a table with `init(ctx)`. inside it:

```lua
kit.define("bounce", {
	start = function(arg)
		kit.on("bounce", game:GetService("RunService").Heartbeat, function() end)
		return true
	end,
	stop = function() end,
})
```

- `kit.define(id, behaviour)` takes the name, usage, short names and description from `_meta.lua`, so a pack only writes what the command does. an id that is not in `_meta.lua` is refused
- a toggle has `start` and `stop`; `stop` must put back everything `start` changed. `kit.on`, `kit.every` and `kit.bind` are cleaned up for you when the command goes off
- an action has `run` and returns `true` (optionally with a message) or `false, "why"`
- `kit.pick`, `kit.one` and `kit.targets` turn what the player typed into players
- two commands can't share a name: the hub keeps the first one and logs a warning
- a pack that throws is reported on the Console and the other packs still load. a pack that was loading when the game closed is switched off on the next start (`S.skipPacks`) until the hub is updated
- nothing in a pack may hook the engine (`hookmetamethod`, `hookfunction`, `getrawmetatable` and the like) or loop forever. `Testing/static_checks.py` fails if one does

`Testing/catalogue_ids.txt` is the full list of 288 planned commands and `Testing/catalogue_pending.txt` lists the ones that are not built, each with a reason (`hook`, `ownership` or `later`). `Testing/tests/cmd_packs.lua` checks that every id is either built, pending or one the hub already had.
