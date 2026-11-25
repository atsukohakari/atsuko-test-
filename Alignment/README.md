# Alignment

`alignment.lua` is the list of hats and how each one is lined up. It has two parts:

- `rig`: hats that become a body part (Head, Torso, Left Arm, Right Arm, Left Leg, Right Leg) when you reanimate with FDless or Script Reanimate.
- `shared`: guns, swords, bullets and auras every script can use, the ported ones too. They count like a weapon you added for every script yourself. `bullet` and `aura` are only for this file: they can't be added for every script from the hub.
- `scripts`: the hats each script uses (swords, guns, bullets, auras) and where they sit.

Every hat from Uhhhhhh's hat map is in here too (rows with the note "from Uhhhhhh's hat map"): its body part hats in `rig` (the ones FDless didn't know already, so the hats FDless knows sit where they always did; a new arm or leg hat can be any arm or leg, like in Uhhhhhh), its guns, swords, bullets and auras in `shared`, so every script with a gun, a sword, a bullet or an aura takes them.

Your own file (`AtsukoHub/alignment_user.lua`) can also have `shared = { gun = { ... }, sword = { ... }, shotgun = { ... }, rifle = { ... } }`: one gun hat for every script with a gun, one sword hat for every script with a sword, and the same for a shotgun and a rifle.

You do not have to edit the file to use a new hat. There are three ways to add one, from easiest to most permanent.

## 1. In the hub (stays on your device)

Main Scripts > Setup > Hats & alignment.

1. Put on the hat in the game. Tap "Read the hats I'm wearing" and tap the hat. Its mesh id, texture id and name fill in by themselves. Or type a hat id (the number at the end of its catalog link, or paste the link) or a mesh id.
2. On the "Used for" row pick Rig and the body part it should become. Pick Weapon instead and a second row asks which one: Gun, Sword, Shotgun or Rifle. Every script with that weapon uses it, no body part needed. One script gives it a job in a single script.
3. Optional: type the alignment as `x y z rx ry rz` (studs, then degrees). Leave it empty to keep the reanimation's own default.
4. Optional: "How many of this hat" puts several copies of it on that part (1 to 8).
5. Tap Add hat.

It is used the next time you start a reanimation. Your hats are saved in `AtsukoHub/alignment_user.lua`, go before the shipped ones, and never leave your device. "Copy rows" and "Copy file" put them on your clipboard so you can paste them into the shared file (way 2) and keep them for everyone.

## 2. In the shared file (GitHub, or your own folder when testing)

Open `Alignment/alignment.lua` and add a line inside `rig = { ... }`:

```
{part = "Left Arm", mesh = "13831073174", align = {0.017, 0, -0.23, -85, -9, 126}, note = "patchma gear arms"},
{part = "Torso", hat = "4506945409"},
{part = "Right Leg", acc = "Accessory (autorig_RightLeg)"},
```

Upload the file. The hub reads it when it starts, and again when you tap Reload in the Hats screen. When you run the hub from your own folder (local test mode) it reads the file from that folder instead, so nothing has to be uploaded to test a change.

If GitHub can't be reached, the hub uses the copy it saved last time (`AtsukoHub/cache/alignment.lua`). If there is no copy either, only your own hats are used, and the screen says "file not found".

## 3. In your own file

`AtsukoHub/alignment_user.lua` has the same shape as the shared file. It is read as plain data and nothing in it is ever run. It also keeps `spots`: the spot you gave each hat in the Alignment window, one line per script, tab and hat (`spots = { ["The Hotline"] = { ["Gun"] = { ["97638566524944"] = {0, 0.5, 0, 0, 0, 0} } } }`), so a hat's spot never moves another hat. Up to 400 are kept. If it can't be read, the hub keeps working with the shipped rows and saves the broken file next to it as `alignment_user_broken.lua` the first time you add something.

## What a row can say

| Field | Meaning |
| --- | --- |
| `part` | rig rows: Head, Torso, Left Arm, Right Arm, Left Leg or Right Leg |
| `slot` | script rows: the job the hat does in that script (the `slots` list at the top of the file explains each one) |
| `hat` | the catalog id. The hub asks Roblox which mesh and texture it has and uses those |
| `mesh`, `tex` | the ids on the hat's handle. A row matches a hat when its ids are found in the handle's ids |
| `acc` | the exact name of the accessory on your character |
| `name`, `words`, `key` | extra ways script rows find a hat (the name, words in the name, a key the script looks for) |
| `count` | how many copies of the hat, 2 to 8 |
| `align` | `{x, y, z, rx, ry, rz}`: studs, then degrees. Missing numbers count as 0. Kept within 500 studs and 1440 degrees |
| `note` | anything you want to remember about the row |

A row needs at least one of `hat`, `mesh`, `tex` or `acc` so there is something to find.

## Which row wins

- Your own rows are tried first, then the shipped ones. The first row that matches a hat is the one used.
- If one of your rows names the same part, mesh, texture and accessory as a shipped row, yours replaces it.
- A row fits one hat. To use the same row for several copies of a hat, give it a `count`.

## Who reads the list

| Reanimation | Reads the rig rows |
| --- | --- |
| FDless (Hat) | Yes. The patched copy in `Reanimation/Hat/FDless.lua` puts your rows in front of its own table, then the list of the hub script that is starting (`AtsukoScriptAligns`). |
| Script Reanimate (Reanimate version 8) | Yes. It reads the list itself every time it starts, in front of the script's own list. |
| Gelatek and Uhhhhhh (Limb) | No. Their bodies are not made of hats, so there is no body part to put a hat on. |
| Every hat script | Yes, through the reanimation you picked. The hub hands each script the picked reanimation before it starts, so the FDless copy inside a Main Script is never the one that runs from the hub. |

The `scripts` rows are published for the scripts to read through `getgenv().AtsukoAlignment`:

| function | what it gives |
| --- | --- |
| `rows(script, slot)` | every row for that script and job, yours first, with the mesh and texture filled in when a catalog id was looked up |
| `match(script, slot, {mesh, tex, name})` | the first row that matches that hat, by mesh and texture, accessory name, words or name |
| `mine(script, slot)` | only the rows you added |
| `offset(row)` | the row's `align` as a CFrame |

The scripts only act on the rows you added (Main Scripts > Setup > Hats & alignment: Weapon or One script on the "Used for" row). A Gun hat answers for the `gun` job of every script (and `gun1` of Snake Banisher V3), a Sword hat for every `sword` job, a Shotgun hat for every `shotgun` job and a Rifle hat for every `rifle` job (Master Chief has both), after that script's own hats for the same job. The shipped rows stay a record of each script's own hats and alignments. `Scripts/README.md` lists which jobs each script reads and what a hat does there.

## Things that can go wrong

- A catalog id can only be turned into a mesh and a texture if the executor can load assets (`game:GetObjects`). If it can't, the screen says so and you type the mesh id instead.
- A hat id that Roblox can't find is not added. A row that waits on a lookup is shown as "waiting for a lookup" and is not used until it is found.
- Changes apply when a reanimation starts, not to one that is already running.
- The shared file may hold 600 rig rows, 40 scripts and 300 rows per script. You may add 300 rows of your own. At most 700 hats are handed to a reanimation.
