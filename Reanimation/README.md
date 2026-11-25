# Reanimation

This folder holds the four reanimations the hub can run, the code that lets the hub switch between them, and the small patches that were applied to the third-party files. Everything here loads on demand: nothing in this folder is needed for the hub to start.

## Read this first: a remote code channel in Uhhhhhh, switched off

The file you gave as `betabetafork.txt` (the Uhhhhhh fork) contains a block, near its end, that connects to a Pusher WebSocket (`wss://ws-us2.pusher.com`), subscribes to the channels `uhhhhhh-secrets` and `uhhhhhh-secrets-<your user id>`, and runs whatever text arrives with the event name `jumpscare` through `loadstring(data.content)()`. Whoever controls that channel can run any Lua they like inside your executor, on every user of the original script. The event `stevesays` only shows a notification.

In `Reanimation/Limb/Uhhhhhh.lua` that block is switched off by one change: `if WebSocket and WebSocket.connect then` became `if false and WebSocket and WebSocket.connect then`. The rest of the block is left as it was so the patch stays a one-line change you can read. It is the last hunk of `Reanimation/patches/Uhhhhhh.patch` and is labelled "security" in `Testing/patch_blocks.json`.

If you ever replace `Uhhhhhh.lua` with a newer upstream copy, check for that block again before you run it.

## The four reanimations

The hub knows exactly these four. The ids are the ones used in settings, in code and in `Scripts/manifest.json`.

| id | name | kind | made by | what it is |
|---|---|---|---|---|
| `atsuko` | Script Reanimate | hat | Atsuko (the style follows Uhhhhhh by STEVETHEREALONE) | your own reanimate, `Hub/Reanimate.lua`, with fly, speed and emotes |
| `fdless` | FDless | hat | MyWorld, continued by rqz (Patchma Hub Discord: https://discord.com/invite/QMy5f6DrbH) | the classic hat reanimate with fling, a modes system and the hub's emotes |
| `gelatek` | Gelatek | limb | Gelatek, poncho | limb reanimate, it can fling and bullet; stopping it respawns you |
| `uhhhhhh` | Uhhhhhh | limb | STEVETHEREALONE, BoredGal, Awes955 | limb reanimate with its own dances |

A hat reanimation moves your accessories to follow a puppet; a limb reanimation moves your real limbs. A hat script (everything in `Scripts/Hat/`) runs on a hat reanimation. A limb script would run on a limb one. No hat script brings its own reanimation: each one, the Main Scripts included, runs on Script Reanimate or FDless, whichever you picked.

## Choosing and setting them

Open Main Scripts. The Hat tab starts with the cards for the hat reanimations (Main Scripts > Setup has a button for it). The Limb tab is switched off for now, so the limb cards don't show. Tap a card to select it. The options for the selected reanimation appear under the cards. Everything is saved in `AtsukoHub/settings.json` as `hatReanim`, `reanimLimb` and `reanimOpts`.

- The hat reanimation has no default. Until you tap a card, starting a hat script (or the Reanimate button on its own) opens a small "Pick a reanimation" window with both cards, and the script starts as soon as you tap one. The older `reanimHat` setting is not read anymore, so after this update everyone picks once. The limb reanimation still starts on Gelatek.

- A script that is already running keeps the reanimation it started with. The new choice is used the next time you reanimate.
- A change made to an option while the reanimation is running says "applies the next time you reanimate". The hub never reloads a reanimation while it runs.
- Invalid values are repaired when the settings load: unknown ids go back to the default (nothing picked, for the hat one), numbers are clamped, and nothing but booleans, numbers and short text is kept.
- The Reanimate button with no script selected starts the selected hat reanimation on its own.
- The button under each card starts the selected reanimation of that kind on its own, without a script.
- A reanimation that cannot run on your executor is shown with the reason ("Needs sethiddenproperty" and so on). It is never hidden.

### Emotes on FDless

The dances on the Emotes page (from Uhhhhhh) play on FDless too. While FDless runs, `providers/fdless.lua` hands the emotes library (`Hub/Emotes.lua`) a host of its own through `Provider.driver(lib)`: the dance's root follows FDless's root, a dance that moves you moves FDless with `setCfr` (only over ground), and while a dance plays FDless is taken over with `forceMode`, so its idle, walk, jump and fall all show the dance and hand back with `releaseMode` when it stops. The running script's own frame still runs first every frame and the dance goes on top of it, so only your body dances: what the script moves on its own (InternalWar's Titan, the guns of Master Chief) keeps going, and a script that watches its frame to see if FDless is still there doesn't stop. The dance figure is kept out of FDless's ground check. A script that brings dances of its own (Studio Dummy V4) keeps them: the driver only steps in while nobody else is dancing, and picks the dances back up a second after the script lets go. `Provider.undrive(lib)` lets go, and stopping FDless does it by itself. Script Reanimate does not need a driver, its emotes run through `setPose` like before.

Both reanimations also keep your feet on the ground while you dance: the emotes library measures the lowest foot of every frame and pulls the body down when both feet float above the floor (it never pushes a crouch up). Each host tells it the hip height (FDless follows `setHipHeight`, Script Reanimate its own), so a script that lifted you still dances on the floor. A move that turns you over (a flip) or leaves the floor by more than twelve studs is left alone and the pull fades out instead of snapping. Emotes > Setup > Keep feet on the ground turns it off.

### FDless options

All fifteen options of FDless are in the hub. The defaults are FDless's own.

| group | option | choices | default |
|---|---|---|---|
| Fling | Fling | on / off | on |
| Fling | Click to fling (Ctrl + click teleports) | on / off | off |
| Fling | Fling direction | Down, Up, Side | Down |
| Fling | Fling targeting | Basic, Joints, Script, Best | Best |
| Fling | Highlight targets | on / off | on |
| Fling | Body while flinging | Light, Ragdoll, Standard | Standard |
| Controls | Ctrl + click teleport | on / off | on |
| Controls | Shift lock | on / off | on |
| Body | Hat placeholders | on / off | on |
| Body | Real body goes | Same spot, Nearby, Beside, Hidden | Hidden |
| Body | Break joints | 1, 2, 3, 4 (4 needs `replicatesignal`) | 1 |
| Body | Simulation radius | on / off | on |
| Body | Hide health bar | on / off | on |
| Body | Disable character scripts | on / off | on |
| Body | Disable GUI scripts | on / off | on |

FDless reads its settings once, when its file loads. The hub sets them just before it loads the shared copy and puts back whatever was there before, so they do not leak into other scripts. If your executor lacks `sethiddenproperty`, `setscriptable` or `replicatesignal`, FDless lowers the matching option by itself and the hub shows a note under the option.

## How it fits together

| file | job |
|---|---|
| `Reanimation/providers/registry.lua` | the one state machine (`idle`, `starting`, `running`, `stopping`), the list of providers, selection, saved options |
| `Reanimation/providers/atsuko.lua` | wraps `Hub/Reanimate.lua` (Lumen, version 9: a gun goes on the wrist and a sword on the back while you dance, and switching scripts holds the body and hands it to the next script; the rig also has setCamOverride, setCamZoom, getCamZoom and getAntivoid, and the camera is kept on the rig and pointing the same way every frame, so a respawn under the map never shows) |
| `Reanimation/providers/fdless.lua` | loads the shared FDless copy, applies the options, wraps the object it leaves in `_G.GenesisFDless` |
| `Reanimation/providers/gelatek.lua` | starts and stops Gelatek, with the stop warning |
| `Reanimation/providers/uhhhhhh.lua` | starts and stops Uhhhhhh in its headless mode |
| `Reanimation/Hat/FDless.lua` | the shared FDless copy, with the patches listed below |
| `Reanimation/Limb/Gelatek.lua`, `Reanimation/Limb/Uhhhhhh.lua` | the limb reanimations, with the patches listed below |
| `Hub/modules/reanim.lua` | the controller behind the Reanimate button |
| `Hub/modules/reanim_host.lua` | connects the controller and the registry to the running hub |
| `Hub/modules/reanim_ui.lua` | the Settings block |
| `Alignment/alignment.lua` | hats and alignment, see `Alignment/README.md` |

If the new reanimation code fails to load (a download fails, for example), the Reanimate button keeps working with the older built-in code, and the Settings block says what went wrong and offers "Try again".

### Where the hub looks for FDless and Uhhhhhh

FDless leaves its object in `_G.GenesisFDless` and Uhhhhhh leaves its API in `_G.UhhhhhhAPI`. On most executors `_G` and `getgenv()` are two different tables, and the hub used to look only in `getgenv()`. It never found FDless, waited 40 seconds and then stopped the script (Uhhhhhh was the same, with 90 seconds). The providers now look in both tables and keep them in step.

- Before a hat script starts, the provider you picked puts its object in `GenesisFDless` on both tables: FDless puts the shared copy there, Script Reanimate puts a rig that has the same functions. The Main Scripts check that field first, so the FDless copy inside their file never runs from the hub. The trap the hub used to set for scripts with their own FDless is gone.
- FDless also puts itself in `getgenv().AtsukoHatFd` for the hub's own scripts, and they hand it their hat list in `getgenv().AtsukoScriptAligns`. Both are cleared when the reanimation stops.
- If another FDless is already running when you start a script, the hub stops it first. If it won't stop, the hub says so and does not start.
- `Testing/tests/fdless_flow.lua` runs the whole chain (controller, registry, the four providers) with the two tables apart, and it fails against the old provider files.

## Hats and alignment

Any UGC hat can be added to any hat reanimation from Main Scripts, Setup, Hats & alignment. The hub merges your hats with the list that ships in `Alignment/alignment.lua`:

- Script Reanimate (and Studio Dummy, Snake Banisher and Dubstep Gun (Hub) when they run on it) reads the merged list from `AtsukoAligns`.
- The shared FDless copy puts your hats in front of its own table, then the running script's own list from `AtsukoScriptAligns`, and switches off the entries they replace.
- A hat with a job in one script (a sword, a gun, a bullet) is only for that script. `Scripts/README.md` lists the jobs.
- Gelatek and Uhhhhhh move limbs, not hats, so they do not use the list.

The changes apply the next time you reanimate. `Alignment/README.md` has the file formats and the limits.

## The patches

Each third-party file is the file you gave plus a recorded patch. `Reanimation/patches/*.patch` is a unified diff from your original to the shipped file, and `Testing/verify_patches.py` reverses every patch and must get your original back byte for byte. `Testing/patch_blocks.json` lists every hunk with the reason; a hunk that is not on that list fails the check.

### FDless (16 hunks)

| lines in your file | change |
|---|---|
| 4 | the guard notice call is removed, the `return` stays |
| 360 | `hubNotify` helper, and the `FDLESS SERVERBREAKJOINTS` notice goes through the hub |
| 417 | the `antivoid` flag of the newer FDless the Main Scripts carry |
| 512 | the camera override holder of the newer FDless |
| 693 | the hub's alignment list, then the running script's own list, go in front of the hat table and entries they cover are switched off |
| 1223 | `releaseMode`, `forceMode` and `isForced` are added after `addmode` (for emotes) |
| 1267 | the key switch of modes does nothing while a mode is forced |
| 1323 to 1340 | the input blocker and the gameProcessed flag on touches, from the newer FDless |
| 1432 | a blocked input does not move the camera, from the newer FDless |
| 1599 | with antivoid off the body falls, from the newer FDless |
| 1864 | the camera override runs after the camera moves, from the newer FDless |
| 2094 | `setShiftlock` and `getShiftlock`, from the newer FDless |
| 2107, 2122, 2134 | `forceMode`, `releaseMode`, `isForced`, `setShiftlock`, `getShiftlock`, `setInputBlocker`, `setAntivoid`, `getAntivoid`, `setCamZoom`, `getCamZoom` and `setCamOverride` are added to the returned table |

The functions from the newer FDless are copied from the copy inside the Main Scripts (Addict, Commander V2 and the others), so a Main Script that calls them works on the shared copy too. Nothing changes when nobody calls the new functions. The header ("FDless Reanimate by MyWorld continued by rqz") is as it was.

### Gelatek (52 hunks)

| hunks | change |
|---|---|
| 30 | connections are registered so stop can disconnect them |
| 6 | the animator stand-in is registered for stop |
| 4 | the bullet movers are registered for stop |
| 3 each | the R6 clone and the R15 rig are registered for stop |
| 2 | the bullet outline is registered for stop |
| 1 | the align objects are registered for stop |
| 1 | hub notice for the guard, plus the cleanup registry and the `Conn` and `Track` helpers |
| 1 | the "Pal Hair" notice goes through the hub |
| 1 | the advert notice is removed |

### Uhhhhhh (7 hunks)

| lines in your file | change |
|---|---|
| 63 | `Util.Notify` goes through the hub |
| 342, 706, 750 | headless mode: no window, no music, no intro |
| 7258 | a small API (`_G.UhhhhhhAPI`) next to the Reanimate button handler |
| 7769 | dance launcher functions for the Emotes page |
| 9932 | the remote code channel is switched off (see the top of this file) |

## What is not proven

Nothing in this folder has been run inside Roblox. What was checked offline: the patches reverse to your originals, every Lua file parses, the registry, controller, host, settings block and the alignment merge pass their tests, and the options and the merge were also tried against deliberately broken copies to see that the tests notice. `Testing/TESTING.md` lists what a person with Roblox still has to try, with a result cell for each of the four reanimations.

Known gaps:

- Gelatek and Uhhhhhh have no hat slots, so hats added by the user do not apply to them (Gelatek's "Pal Hair" bullet hat is not covered).
- A hat given only as a catalog id depends on `game:GetObjects` working on your executor.
- Switching reanimation while a script runs is blocked on purpose; stop the script first.
