# Scripts

Every script the hub can run lives here. The first folder says what kind of script it is (`Hat` or `Limb`). Folders below it only keep the files tidy: the Hat and Limb tabs are one list each, with no headings. A file or folder whose name starts with `_` is hidden from the list, and so is `Testing/`. Names, credits, the kind and the reanimation each script needs come from `manifest.json`, so a script file does not need a header for them. A header line inside the script (`@name`, `@author`, `@desc` and the others in the table further down) still wins when there is one.

## What is here

| file | shows as | made by |
|---|---|---|
| `Hat/FDless/Addict.lua` | Addict | Booga, MelonScripter, Auxnos, Emper, MyWorld & rqz, STEVETHEREALONE |
| `Hat/FDless/CommanderV2.lua` | Commander V2 | Shackluster, Melon, MyWorld & rqz |
| `Hat/FDless/InternalWar.lua` | InternalWar | BeezelduD, MelonScripter, Emper, MyWorld & rqz |
| `Hat/FDless/NeptunianV.lua` | Neptunian V | Tory, NoobyGames12, MyWorld & rqz |
| `Hat/FDless/NeptunianVGun.lua` | Neptunian V Gun | NoobyGames12, gObl00x (random_hacke6), MyWorld & rqz |
| `Hat/FDless/DubstepGun.lua` | Dubstep Gun (Original) | Supr14, MyWorld & rqz, BloxinStud10 |
| `Hat/FDless/LastStar.lua` | Last Star | Asarii_IV, StratopshericAero, GunsForGunsKidd, DangerRedile, MyWorld & rqz |
| `Hat/FDless/MasterChief.lua` | Master Chief | Helkern, MelonScripter, Emper, MyWorld & rqz |
| `Hat/FDless/TheHotline.lua` | The Hotline | Gelatek Hub, MyWorld & rqz |
| `Hat/FDless/RealityOrbGlitcher.lua` | Reality Orb Glitcher | BloxinStud10 (RbxUtility), MyWorld & rqz; the original maker isn't named in the file |
| `_unlisted/TheSniper.lua` | not in the list | Gelatek Hub, MyWorld & rqz |
| `Hat/DubstepGun.lua` | Dubstep Gun (Hub) | Supr14 |
| `Hat/SnakeBanisherV3.lua` | Snake Banisher V3 | MLG Super Killer, Epic |
| `Hat/StudioDummyV4-Test.lua` | Studio Dummy V4 | Vulnerali / padero, andrfix |
| `Hat/FakeVR.lua` | FakeVR | 0866 & Abacaxl (CLOVR), im_patrick (FakeVR), saucekid (RERilla), Atsuko Hub |
| `Hat/BookReader.lua` | Book Reader | Dark Eccentric (showcase, [youtube.com/@DarkEccentric](https://www.youtube.com/@DarkEccentric)), Atsuko Hub |
| `Hat/AK47.lua` | AK-47 | STEVETHEREALONE (Uhhhhhh, MIT) |
| `Hat/Banisher.lua` | Banisher | STEVETHEREALONE (Uhhhhhh, MIT) |
| `Hat/LinkedSword.lua` | Linked Sword | STEVETHEREALONE (Uhhhhhh, MIT) |
| `Hat/R6.lua` | R6 | STEVETHEREALONE (Uhhhhhh, MIT) |

The first eleven are the Main Scripts: each is the file it came as plus one recorded patch. The Sniper is hidden on purpose: the file came named "Don't use this". To try it, run it from your own folder (`loadstring(readfile("Atsuko Hub/Scripts/_unlisted/TheSniper.lua"))()`) or paste it in the editor. The last nine were written for the hub. AK-47, Banisher, Linked Sword and R6 are movesets from Uhhhhhh (MIT), rebuilt on the hub's reanimation with new animations (see below). The two Dubstep Guns are both Supr14's: "Original" is the FDless conversion with a recorded patch, "Hub" is the hub's own rebuild.

## Every hat script runs on the reanimation you pick

No hat script brings its own reanimation. Every one of them, Main Script or not, runs on Script Reanimate or on FDless, whichever card you picked at the top of the Hat tab, and `manifest.json` lists `"reanim": ["atsuko", "fdless"]` for all of them.

- Nothing is picked until you pick it. Starting a hat script (or tapping Reanimate) with no pick opens a small window with the two cards, and the script starts right after you tap one. The pick is saved as `hatReanim` in `AtsukoHub/settings.json`, so it is asked once. The old `reanimHat` setting is not read anymore, which is why everyone picks once after this update.
- The Main Scripts still carry the FDless copy their file came with, but they only use it when nothing else is there. The hub always puts the reanimation you picked in `_G.GenesisFDless` before the script starts (the shared `Reanimation/Hat/FDless.lua` for FDless, an Script Reanimate rig with the same functions for Atsuko), so the copy inside the file never runs from the hub.
- The hub's own scripts (Dubstep Gun (Hub), Snake Banisher V3, Studio Dummy V4) look for `getgenv().AtsukoHatFd` first. FDless puts itself there, together with the script's own hat list in `getgenv().AtsukoScriptAligns`, which FDless puts in front of its own list. On Script Reanimate the field is empty and they use Script Reanimate like before.
- The newer scripts call a few FDless functions the old shared copy did not have (`setCamOverride`, `setCamZoom`, `getCamZoom`, `setInputBlocker`, `setShiftlock`, `getShiftlock`, `setAntivoid`, `getAntivoid`). The shared copy got them from the newer FDless inside the Main Scripts (recorded in `Reanimation/patches/FDless.patch`), and Script Reanimate's rig has them too.

## FakeVR

`Hat/FakeVR.lua` is full-body VR in the style of **CLOVR by 0866 and Abacaxl** (who thank unverified in their script), with arms built like **RERilla** by saucekid and hands and throwing that build on FakeVR by im_patrick. Like the other hub scripts it runs on whichever reanimation you picked (Script Reanimate or FDless) and never brings its own.

- **Arms.** By default your arms are RERilla style two-rig arms: each leg hat becomes an upper arm hanging from the shoulder and the arm hat is the forearm, bending at the elbow. If a side has no leg hat, that arm is a single arm. The arms never play walking or other animations; they rest in front of you like holding VR controllers and move smoothly when you use them. They always stay attached and never stretch past their own length.
- **Legs.** Switch the leg hats to Legs (L or the menu) and your feet plant on the floor like in CLOVR: look a little to the side and only your head turns, look further and the body turns and the feet step after it. Walking and sprinting swing the legs, and the legs never go through the floor. Hide tucks the leg hats away.
- **Hands.** On a computer, hold the left mouse button for the left arm and the right button for the right arm: that arm points where you aim. On a phone, two circles sit in the middle of the screen, one on the left for the left arm and one on the right for the right arm. Put a finger in a circle to lift that arm: at the top it points up, in the middle straight ahead, at the bottom down, and sliding left or right swings it to that side (half as far across your body). A dot shows where your finger is, and moving your arm never moves the camera. A finger keeps the arm it started with until you lift it, even if it leaves the circle. A lowered arm hangs straight down at your side, the two-rig arms too. Touching anywhere outside the circles turns the camera like always, and the joystick under the left circle and the jump button keep working. With a VR headset the head and both hands follow the headset and controllers.
- **Throwing.** Grab an accessory near your hand, or point at one further away to pull it into your hand. On a computer let go mid swing to throw it the way your hand was moving. On a phone just lift your finger: it flies the way the arm points, and a quick flick throws it harder. A quick tap on an accessory anywhere outside the circles pulls it into the hand on that side. Only accessories can be thrown: hair never, rig hats never, and hats on your head only when Head hats is on. 1 to 9 puts one in your right hand (Shift for the left) and R brings everything back.
- **Moving.** Shift sprints, C or Ctrl crouches (the reanimation really gets lower), F flies smoothly where you look (Space or E up, Ctrl or Q down, Shift faster). On a phone, flying goes where you look and holding jump goes up; fly, crouch and sprint are switches in the menu.
- **Menu.** FakeVR has no screen of its own. Its menu is a hub window: the menu button at the top of Main Scripts (it shows while FakeVR runs), T, or `vrhats` opens it. Throw lists your accessories with L and R buttons, a bring back button and the head hats switch. Body has the leg hats, view, fly, crouch, sprint, and sliders for up/down distance and sideways distance (how far the circles move the arm, in degrees), circle size, arm reach (how far the two-rig arms stretch out when they point), throw power, smoothness and speeds, plus the arm circles switch. The two circles are drawn by the hub too, on a layer under the hub, and step aside while the hub or the menu is open. The credits are on the hub's credits page. Settings are saved in `FakeVR_Settings.json` in your workspace folder.

Other scripts can read `getgenv().AtsukoFakeVR` while it runs (`cfg`, `items`, `hands`, `feet`, `body`, `throwables()`, `summon(item, side)`, `recall()`, `setFly(on)`, `setCrouch(on)`, `setSprint(on)`, `openMenu(open)`, `menu()`, `stop()`).

## Uhhhhhh movesets: AK-47, Banisher, Linked Sword and R6

These four are the movesets from [Uhhhhhh](https://github.com/STEVE-916-create/Uhhhhhh) by STEVETHEREALONE (MIT), with Uhhhhhh's own code in them: the same animations, the lines they say, the sounds, the effects, the settings and Banisher's theme. R6 is Uhhhhhh's "2015 Roblox" and plays the real 2015 Roblox animations. Each file is the moveset as it is in Uhhhhhh's `content/v_moveset1.lua` or `content/v_moveset2.lua`, without its comments and type notes. The one line changed in AK-47, Banisher and Linked Sword is the raycast filter, which leaves out the stand-in body below.

They run on Script Reanimate or FDless like every hat script, through `Hub/UhhMoveset.lua`. It gives the moveset the things Uhhhhhh gives it: an invisible R6 stand-in body (the `figure`) whose joints the moveset moves and which your body copies every frame, `HatReanimator` with Uhhhhhh's whole list of known accessories, `ContextActions` for the keys, the config switches and sliders, the music, `ReanimateFling` and the chat lines. Speed and jump power the moveset sets go to the reanimation, and so do the turns and pushes it gives the body (AK-47 turning to where you shoot, Banisher's rocket boots).

- **AK-47.** "what comes before 47?" "AK." M1 - Shoot. Settings: Sounds, Gun = Sword, Bullets Per Second.
- **Banisher.** hes a very tuff CLANKER. M1 - Primary Attack, R - Secondary Attack, F - Holster/Unholster Gun, Left Ctrl - Run. Hold jump in the air to fly. His theme (DM DOKURO, Guardian of the Former Seas) is downloaded into your `UhhhhhhReanim` folder like the dances. Settings: Tuff, Sounds, No Cooldown, Ignore Dancing, Hitbox Visual, Fall Parkour Anim, Camera Fly, Use Sword instead of Gun.
- **Linked Sword.** He has been fighting since 2006! M1 - Linked Sword, Z - Superball, X - Rocket Launcher, C - Timebomb. Settings: Dialog, Sounds, No Cooldown, Ignore Dancing, Hitbox Visual.
- **R6.** Uhhhhhh's 2015 Roblox: the 2015 idle, walk, jump and fall animations with the old character sounds.

Every setting and every key is a hub command with Uhhhhhh's name for it (`sounds`, `camerafly`, `superball`, `secondaryattack` and so on), and `music` turns the theme on or off. A tap on a phone is M1. Uhhhhhh's own buttons next to the jump button are not shown, like every other script's pad. Settings are saved in `AtsukoHub/movesets/<name>.json`, the way Uhhhhhh saves them.

Their hats are picked like Uhhhhhh picks them: a hat you added for that script (`add gun <id>`, `add sword <id>` or `add bullet <id>` while it runs) comes first, then Uhhhhhh's known accessories (they sit exactly where Uhhhhhh puts them, the two halves of a gun together), then the guns, swords and bullets in `Alignment/alignment.lua` and the hat's name. A hat that is a body part is never taken. While one of these runs, a hat Uhhhhhh knows that the moveset isn't using sits where Uhhhhhh rests it (a sword or gun on your back, wings on your back, the golden bullet on your left shoulder). AK-47's Aiming tab moves the rifle only while you shoot, and Linked Sword's Bazooka tab moves the rocket launcher. While you dance the weapon goes back so the dance can put it on your wrist or back.

## Book Reader

`Hat/BookReader.lua` is the **Fe Book Reader** from [Dark Eccentric's Roblox Fe Script Showcase Episode 131](https://www.youtube.com/watch?v=221xjv9UYdo) (his channel: [youtube.com/@DarkEccentric](https://www.youtube.com/@DarkEccentric)). The original file is lost, so it was rebuilt from that video on the hub's own reanimation: it runs on Script Reanimate or FDless, like every hat script. Dark Eccentric showed the script, he didn't write it; who did is not known.

- **The pose from the video.** Standing, you hold the book open in front of your face like you're reading it: the book arm holds it up, the other arm is forward at your chest, and your head tips down a little to read.
- **Walking.** Like in the video, the book arm goes up beside your head with the book resting on that hand, tipped back, and the other arm is held forward across you. The legs swing with your speed, the body bobs, sways and turns a little with each step, the head stays steady, the book bounces with your steps and the free arm swings. When you stop, the book comes back down in front of your face.
- **Jumping.** Going up, the leg in front lifts, the body leans back a little, the book goes up and the free arm swings out; falling, the legs reach for the floor and the free arm stays out for balance; landing, the body dips and springs back. Everything blends, nothing snaps.
- **Book hand.** The Alignment window has a Book hand choice: Right or Left. The other arm does the free arm's part, and the choice is saved.
- **The book.** Wear the [How To Read Book](https://www.roblox.com/catalog/18701259915) (the script looks its mesh up by itself), any hat with "book" in its name, or say `add book <hat id>` (a hat you add this way comes first). A book shaped hat is stood up and turned to face you whatever way it was made.
- **Alignment.** Book moves the book, Book arm and Other arm turn the arms while you read. The Book tab's spot is saved for that book only, and "Flip the book" turns it around if you see the inside of the cover. Saved in `BookReaderAlign.json` with the book hand.

Other scripts can read `getgenv().AtsukoBookReader` while it runs (`book`, `pose`, `hand`, `state`, `stop()`).

## The Main Scripts tab

The page has five tabs.

| tab | what it lists |
|---|---|
| Hat | scripts that wear hats, in one list sorted by name. On top of it sit two cards, Script Reanimate and FDless. Every hat script runs on the one you tap; its options open under the cards. Until you tap one, starting a hat script asks you to pick |
| Limb | switched off for now while new ways to do limb reanimation are tried. Tapping it says so and stays on the tab you were on |
| Favorites | the scripts you pinned with the heart, hats and limbs together |
| Recent | the scripts you ran lately |
| Setup | how scripts run: Run & Stop (respawn when stopped, one script at a time, Smart Stop, script prints, looking for new scripts), Right now (stop all scripts, respawn, clear the recent list) and Hats & alignment. These used to be in Settings > Scripts |

The Hat and Limb tabs are one list each, sorted by name, with no headings. The folders below `Hat` or `Limb` don't change that.

Each row shows the name (never a file ending), "by" and the first credit (with "+2" when there are more), and a small state on the right:

| state | colour | means |
|---|---|---|
| Running | green | the script is running |
| Starting | yellow | the reanimation or the script is still starting |
| Error | red | the script hit an error, the Console has the text |

On Favorites and Recent the second line says "Hat" or "Limb" and then "by" and the first credit. The search box matches the name, the folder and the credits.

A card that cannot be used says why in its own line (an executor function that is missing, for example), and starting a script that needs it shows the same reason as a notification. Picking a card while a script runs is allowed: the pick counts from the next start.

How the hub decides if a script is a hat or a limb script, first match wins:

1. a `@kind hat` or `@kind limb` line in the script's header
2. `"kind"` in its `manifest.json` entry
3. the first folder (`Scripts/Hat/...` or `Scripts/Limb/...`)
4. hat, for a script that has none of those

## How the Main Scripts changed

Each Main Script is the file from `Main Scripts.zip` (for Addict, Commander V2, InternalWar, Master Chief and Reality Orb Glitcher, the `Addict_1.lua`, `CommanderV2_2.lua`, `InternalWar_FDless.lua`, `MasterChief.txt.lua.txt` and `RealityOrbGlitcherConvert.lua.txt` files the owner sent) plus one recorded patch in `patches/<Name>.patch` (a unified diff from that file to the shipped file). Undo the patch and you get the original back byte for byte. `python3 -I Testing/verify_patches.py --only main --zip "Main Scripts.zip" --originals <folder with the five files>` does that for all eleven and also checks that every hunk lies inside one of the named blocks in `Testing/patch_blocks.json`. Nothing else was touched: no tidy-ups, no renames, nothing that changes how a script plays with a keyboard and mouse.

| patch | hunks | lines added | lines removed |
|---|---|---|---|
| `Addict.patch` | 13 | 202 | 515 |
| `CommanderV2.patch` | 13 | 202 | 533 |
| `DubstepGun.patch` | 14 | 214 | 558 |
| `InternalWar.patch` | 13 | 155 | 172 |
| `LastStar.patch` | 4 | 16 | 3 |
| `MasterChief.patch` | 15 | 1078 | 738 |
| `RealityOrbGlitcher.patch` | 3 | 682 | 2 |
| `NeptunianV.patch` | 11 | 183 | 510 |
| `NeptunianVGun.patch` | 12 | 210 | 532 |
| `TheHotline.patch` | 15 | 196 | 516 |
| `TheSniper.patch` | 14 | 204 | 539 |

What the patches take out:

1. **On-screen buttons and the aim cross.** The round skill buttons the scripts drew for touch players and the "+" in the middle of the screen. Last Star is the exception: it keeps its three phone controls (attacks, form change and song mute), because they are the only thing that supports it on touch.
2. **Grey Roblox pop-ups.** Every grey Roblox pop-up (the notification call of `SetCore`): the "Using FDless loaded by previously executed scripts" notice, the credit banners, and the scripts' own notice functions. What matters now shows as a hub toast ("This executor has no replicatesignal, break joints method 4 is off", a script's own messages). Without the hub a script writes to the output with `warn`. The credits are in the details page of each script and in Settings > About > Credits.
3. **The alignment panels inside the scripts.** The `LCGunAlign` window that Dubstep Gun, Neptunian V Gun, The Hotline, The Sniper, Addict and Commander V2 carry, Neptunian V's own panel and InternalWar's Titan hats panel. The hub's Alignment window does the job now: each script publishes an adapter in `getgenv().AtsukoAlign` and keeps its own file and format. Last Star never had a panel. InternalWar keeps its Titan Scale panel, it opens with `-size` or the Titan size button in the Alignment window.

What the patches add:

4. **The hats you pick for one script.** Main Scripts > Setup > Hats & alignment can give a hat a job in one script (see "Hats for one script" below). The patches add the few lines that look at those hats first.

4b. **The two halves of the LC gun.** When the gun a script picks is LC Gun 1 or LC Gun 2, The Hotline, The Sniper, Addict, Commander V2, Neptunian V Gun and Dubstep Gun hold it where Uhhhhhh holds it (the hub's hat list knows the offsets) and hang the other half on it at the joint the two always have, so they are one gun wherever the script moves it. Stopping the script, or the gun changing, puts the other half back where you wear it. Snake Banisher V3 holds each half in its own slot the same way.

4c. **Each hat keeps its own alignment spot.** The Hotline, The Sniper, Addict, Commander V2, Neptunian V Gun, Dubstep Gun (original), Master Chief and Neptunian V tell the hub which hat is on each tab of the Alignment window (`AL.hat(tab)` gives the hat's mesh id, a key, and its name; the gun scripts put it in `C.alignHat`). Snake Banisher V3 does the same in its own file. The hub saves the spot you give a hat under that hat in `AtsukoHub/alignment_user.lua` (`spots`), puts it back whenever that hat is picked again, and starts every other hat you added from the default spot instead of the last hat's. The script's own gun keeps the spot you had saved before this update. Neptunian V keys the spot by sword and hat. Dubstep Gun (hub) moves all of its gun hats together and Studio Dummy V4 already saves one spot per gun by itself, so those two are unchanged.

5. **Master Chief's own reanimate.** Master Chief came with the Emper reanimate, which builds a rig called `non` and moves your hats onto it. The patch takes that reanimate out (its two grey pop-ups too, the credit one becomes a hub toast) and puts in `MC`, a small adapter: it runs on the reanimation you picked, builds an invisible doll with the same parts and joints in place of `workspace.non`, and moves the reanimation's joints from the doll every frame, the way Dubstep Gun (Hub) does. The script's own code runs as it was, with a few lines pointed at `MC`: the velocity, the ground and the move direction come from the reanimation, `rootpart.Anchored` holds you in place while you shoot (`MC.hold`), the X dash moves the reanimation (`MC.push`) instead of setting the root's velocity, the gun hats go on its Rifle, Shotgun and Bullet parts (`MC.arm`), and the loops end when the script stops. The gun models come from `rbxassetid://10170990440` like before (`MC.objects`): it asks up to three times and tries `GetObjects`, `GetObjectsAsync`, `getobjects` and `InsertService:LoadLocalAsset` in that order. If nothing comes back it builds stand-in guns with the same parts and welds, says why in a toast and fits the gun hats by their size. The catalog guns are looked up one at a time, after the model, and only for a gun slot that no worn hat filled. Its rig hats (the free fedora rig, the white and black limb sets) are in the script's own hat list and in `Alignment/alignment.lua`.

6. **Reality Orb Glitcher's own reanimate.** The file came converted for an FDless it downloaded from a gist (`reanimation.start`, with `FDless.character` as the body). The patch swaps that download for a small bridge: it runs on the reanimation you picked, builds an invisible body with the same parts and joints, keeps it where the reanimation is, and copies the script's pose to the reanimation every frame. A dash or a fly from the script moves the reanimation, and standing still for an attack holds it too. Every hat you wear that isn't a body part flies around the orb on a slowly turning ball, so other players see the orb as your hats. Its effects come from `rbxassetid://106767142974276` like before; if Roblox sends nothing it uses plain effects and says so. The patch adds one more line after the orb is made, telling the bridge which part is the orb.

Last Star also loses one chat line, the one that named the converter (deliberately; nothing else in the file names the converter and it is not added back anywhere). Its two FDless notices go like the others.

## Where the old panel controls went

| old control | now |
|---|---|
| Stop (panel header) | Deanimate on the Reanimate bar |
| Fade, minimise, close | the Alignment window is a normal hub window: it has its own minimise and close buttons and can be moved and resized. There is no Fade button |
| Tabs, value rows, step rows (Move step, Turn step), Save, Undo, Reset, Reload | the same controls in the hub's Alignment window |
| Copy | the Alignment window's Copy button (it copies the rows that count for the tab you are on) |
| Flip | the Alignment window's Flip |
| Roll (upside down? tap this) | a button row in the Alignment window (Dubstep Gun, Neptunian V Gun, The Sniper and Neptunian V; The Hotline never had it) |
| Equip, Find sword, Sword switch (Neptunian V) | button rows in the Alignment window: Equip / Unequip, Find sword, Switch sword |
| Hat Sword and Hat Gun switches (Neptunian V Gun), Hat Gun (Addict, Commander V2) | toggle rows in the Alignment window |
| InternalWar's Titan hats panel (Void and UGC sets) | nine tabs in the Alignment window: Head, Torso, Arms and Legs for the Void hats, then UGC Torso, UGC R Arm, UGC L Arm, UGC R Leg and UGC L Leg. The Titan size button opens its Titan Scale panel |
| the round Align button | removed. The script's own key (`P` in Neptunian V, InternalWar and the gun scripts, `J` in Snake Banisher, Right Ctrl in Studio Dummy), `-align` in chat and the Alignment button on the Reanimate bar open the hub's window; the script's key just forwards to it |
| the red ball on the muzzle | still shown while the Alignment window is open |

## What a phone player without a keyboard can no longer reach

The owner asked for the button pads to go and for no replacement, so these skills are keyboard-only now:

| script | still works on a phone | needs a keyboard now |
|---|---|---|
| Neptunian V | tap to attack, walking; Equip / Unequip, Find sword, Switch sword and Roll as buttons in the Alignment window | Q smack, E spin, Z, X, C, R jump, V teleport, 1 to 5 modes, L mute |
| Neptunian V Gun | tap for the sword combo | Q sword / gun mode, Z, X, C, V, the run key |
| Dubstep Gun (Original) | the Alignment window only | shooting (a tap does nothing in this script) and the songs on Z, X, C, V, B, L, K |
| Addict | walking, the chat commands, the Alignment window | Z shoot, X pistol, C slash, T sit, Shift + Right Ctrl emotes |
| Commander V2 | walking, the chat commands, the Alignment window | Z shoot, X shockwaves, C rain, V slam, E dash, Q warp, T taunt |
| InternalWar | walking, `-size`, `-hats`, `-music`, `-stop` and the Alignment window | Z punch, E throw, R uppercut, T roar, Y take on. The skill list on the left of a PC screen is gone too, because its lines were buttons |
| Master Chief | tap to shoot, walking, the Alignment window | Q swap rifle and shotgun, Z grenade, X dash, 2 run. It never had a pad, these were always keys |
| Reality Orb Glitcher | walking, the orb | Q E R T Y modes, Z flower, N and M fly, L mute, B damage. It never had a pad |
| The Hotline | tap to shoot | Z grenade, T taunt, M song |
| The Sniper | tap to fire | F aim, Z scope, C crouch, R reload |
| Last Star | everything, its phone controls stay | nothing |
| Studio Dummy V4 | the Alignment window | attack (E), teleport (Z), modes (M, N), fly (F), spawn (R); the hub's Emotes page still works |
| Snake Banisher V3, Dubstep Gun (Hub) | no change, they never had a pad | their key skills, as before |
| AK-47, Banisher, Linked Sword, R6 | a tap is M1, walking, and every key and setting as a hub command | nothing, Uhhhhhh's own buttons are not shown |

On a phone, Dubstep Gun (Original), Neptunian V Gun, The Sniper, Addict and Commander V2 aim at the middle of the screen, and the "+" that showed where is gone.

## Alignment files

Nothing about the saved files changed, so everything you saved before still loads:

| script | file |
|---|---|
| Dubstep Gun (Original) and Dubstep Gun (Hub) | `DubstepGunAlign.json` |
| Addict | `AddictAlign.json` |
| Commander V2 | `CommanderV2Align.json` |
| InternalWar | `InternalWarAlign.json` |
| Master Chief | `MasterChiefAlign.json` (new, a Rifle tab and a Shotgun tab) |
| Reality Orb Glitcher | `RealityOrbAlign.json` (new, an Orb tab that moves and turns the ball of hats) |
| Neptunian V Gun | `NeptunianVAlign.json` |
| The Hotline | `HotlineAlign.json` |
| The Sniper | `SniperAlign.json` |
| Neptunian V | `NeptunianFDlessAlign.json` |
| Snake Banisher V3 | `LCGunAlign.json` |
| Studio Dummy V4 | `StudioDummyAlign.json` |
| AK-47 | `AK47Align.json` (new, Gun, Aiming and Bullet tabs; Aiming moves the rifle only while you shoot) |
| Banisher | `BanisherAlign.json` (new, a Gun tab and a Bullet tab) |
| Linked Sword | `LinkedSwordAlign.json` (new, Sword, Bazooka and Bullet tabs) |

On top of these, the spot you give a hat in the Alignment window is saved under that hat in `AtsukoHub/alignment_user.lua` (`spots`), so each hat keeps its own and a new hat starts from the default (see 4c above).

Both Dubstep Guns use the same file name, as they always did, but they keep different numbers in it. Saving in one rewrites the file with only its own numbers, so if you use both, line the second one up again after saving in the first. Which hats each script uses, with their mesh ids and alignments, is listed in `Alignment/alignment.lua`.

## Hats for one script

Main Scripts > Setup > Hats & alignment has a "Used for" row with three choices: Rig, Weapon and One script. Rig: the hat becomes a body part in Script Reanimate and FDless, on every reanimation. Weapon opens a second row with Gun, Sword, Shotgun and Rifle. Gun: every script with a gun job uses it (AK-47, Addict, Banisher, Commander V2, Dubstep Gun, Linked Sword for its bazooka, Master Chief for its rifle and shotgun, Neptunian V Gun, Snake Banisher V3 for its first gun, Studio Dummy V4, The Hotline, The Sniper). An LC gun half stays out of Master Chief unless you say rifle or shotgun yourself, because it can't join the other half. Sword: every script with a sword job uses it (Linked Sword, Neptunian V, Neptunian V Gun). Shotgun and Rifle: every script with a shotgun or a rifle job uses it (Master Chief). One script: pick a script and a second row asks what the hat does there, and only that script uses it. Weapon and one script hats count the next time a script starts; the weapon ones are saved under `shared`. The rows you add are saved in `AtsukoHub/alignment_user.lua` under `scripts`, and the hub hands them to the scripts through `getgenv().AtsukoAlignment` (`match(script, job, hat)`, `mine(script, job)` and `offset(row)`). Rows you added count, and so do the shipped `shared` rows in `Alignment/alignment.lua` (Uhhhhhh's guns, swords, bullets and auras), so every script, ported or not, takes those hats too. A script's own shipped rows stay a list to read.

| script | jobs | what a picked hat does |
|---|---|---|
| AK-47 | gun, bullet | it is the rifle (first choice), or the hat that flies with the bullets and hides under you in between |
| Addict | gun, bullet | it is the sniper in your hand (first choice), or the hat that flashes as the bullet |
| Banisher | gun, bullet | it is the gun in your hand, or the hat that flies with the shots and bombs |
| Book Reader | book | it is the book you hold up and read (first choice, before the How To Read Book and hats with book in their name) |
| Commander V2 | gun, bullet | it is the gun in your hand (first choice), or the bullet |
| Dubstep Gun | gun, aura | Original: it is an extra gun the script fits into your hand, sitting where its alignment says when it has one. Hub: gun and aura hats are lined up with the gun and the blast like the script's own |
| InternalWar | head, torso, right arm, left arm, right leg, left leg | it goes on that Titan part before the Void hats and the UGC limb set are looked for. Head uses the Void tab, the rest use their UGC tab |
| Linked Sword | sword, gun, bullet | it is the sword, the rocket launcher, or the hat that rides the rocket |
| Master Chief | rifle, shotgun, bullet | it is the rifle or the shotgun (first choice, before the script's own list), or the bullet. With an alignment it sits where that says, without one it is fitted by its size like the catalog guns |
| Neptunian V | sword | it counts as a sword and uses the first sword's alignment |
| Neptunian V Gun | sword, gun, slash, bullet | it ranks first for that job |
| Snake Banisher V3 | gun 1, gun 2 | it goes in front of that slot's list |
| Studio Dummy V4 | gun, screen, head, bullet | its mesh goes in front of that list, its name or words join the word list |
| The Hotline | gun, bullet | it is a gun, or the bullet |
| The Sniper | gun, bullet | it ranks first among the guns, or it is the bullet |

**Two parts of one weapon.** `add <id> <id>` with two parts of the same gun or sword (part 1 and part 2, top and bottom, 1/2 and 2/2) saves them as one weapon. The fit comes from where each part sits when you wear it, so the second part rides on the first exactly as it looks on your avatar. The row keeps the second part as `mate` and the fit as `rel`, and every script that holds that weapon joins them: the Main Scripts and the movesets through `getgenv().AtsukoAlignment.join(fd, hat)`, Studio Dummy V4 and Dubstep Gun (Hub) too (`mate(hat)` gives the other part). Two different weapons (a rifle and a pistol, or a left and a right sword) stay two hats, and if the hub can't tell where a part is worn it says so and adds them as two. The LC gun still works as before.

Last Star is not in the list: its six wing swords are found by their textures and each sits on its own wing, so a new hat has no job there.

## Adding your own script

Put the file in a folder here and it shows up by itself.

| script | put it in | start from |
|---|---|---|
| a hat script | `Scripts/Hat/MyScript.lua` (a folder below `Hat/` is fine too, it only keeps the files tidy) | `_TEMPLATE_HAT.lua` |
| a limb script | `Scripts/Limb/MyScript.lua`, or `Scripts/Limb/MyGroup/MyScript.lua` | `_TEMPLATE_LIMB.lua` |

Both templates are small and work as they are. Each one shows a notice with `AtsukoHub.Notify`, registers commands (`hello`, `loud` as a toggle, `quit`, and `where` in the limb one), says goodbye from `AtsukoHub.OnStop`, and also runs when you paste it outside the hub. They are hidden from the list because their names start with `_`. `_TEMPLATE.lua` is the older, longer example with the alignment adapter in it.

### What a script can use

The hub gives every script a table named `AtsukoHub`:

| name | what it is |
|---|---|
| `AtsukoHub.Version`, `.Name`, `.Path` | the hub version and this script's name and path |
| `AtsukoHub.Notify(title, text, kind, seconds)` | a hub notification. `kind` is `"info"`, `"ok"`, `"warn"` or `"error"` |
| `AtsukoHub.OnStop(fn)` | `fn` runs when the script is stopped. Use it to put things back |
| `AtsukoHub.Stop()` | stops this script |
| `AtsukoHub.Commands.register(list, { short = "name" })` | adds your commands to the hub's command box and chat prefix. Each one has `id`, `name`, `desc`, `usage` and `run`, and `kind = "toggle"` makes the toggle's state arrive as `context.state` |
| `AtsukoHub.Commands.declare(names, opts)` | lists command names your script handles itself |
| `AtsukoHub.Reanim` | which reanimation the script runs on, see below |
| `AtsukoHub.UI` | the hub's own ui for your script, see below. Use it instead of making a ScreenGui |

`AtsukoHub.Reanim` is filled in when the script starts:

| field | what it is |
|---|---|
| `Kind` | `"hat"` or `"limb"` |
| `Provider` | the reanimation's id: `"atsuko"`, `"fdless"`, `"gelatek"` or `"uhhhhhh"` |
| `Clone` | the clone model the limb reanimation made (Gelatek has one, so `Clone.Name` works there), or nil |
| `Stop()` | stops the reanimation and with it the script. It does not ask the "Stopping respawns you" question that the Reanimate button asks for Gelatek, because the script chose it. Gelatek still respawns you |

`AtsukoHub.UI` draws with the hub, in the hub's colors, and everything it makes goes away when the script stops:

| name | what it is |
|---|---|
| `UI.menu({ title, icon, tabs, build, opened, closed })` | a menu in a hub window. The menu button at the top of Main Scripts opens the newest one. `build(m, tab)` fills it with `m.section(text)`, `m.note(text)`, `m.toggle(title, desc, get, set)`, `m.choice(title, { { value, label }, ... }, get, set)`, `m.slider(title, min, max, step, get, set, fmt)`, `m.action(text, icon, fn)`, `m.buttons({ { icon, text, fn }, ... })` and `m.list(get)`, where `get()` gives rows of `{ title, sub, picks = { { text, on, fn }, ... } }`. It returns a handle with `:open()`, `:close()`, `:toggle()`, `:isOpen()`, `:refresh()`, `:rebuild()` and `:destroy()` |
| `UI.layer()` | a see-through frame across the screen inside the hub's ScreenGui, under the hub, for things like touch circles |
| `UI.new(class, props, parent)`, `UI.corner(o, px)`, `UI.stroke(o, color, thickness, transparency)`, `UI.tween(o, seconds, props)` | the hub's helpers |
| `UI.color(name)` | a hub color: `"accent"`, `"text"`, `"sub"`, `"panel"`, `"card"` and the rest |
| `UI.busy()` | true while the hub is open |

A script started from the Main Scripts tab sees the reanimation it was started on. A script started any other way (from the editor, say) sees nil fields, so read them the way the templates do. A script that stops itself with `AtsukoHub.Stop()` leaves the reanimation on, and `AtsukoHub.Reanim.Stop()` takes both down.

### Names, credits and the reanimation

For a script that comes with the hub, add an entry to `manifest.json` and leave the file alone. Each key is the script's path.

| field | what it does |
|---|---|
| `name` | the name on the row. Without it the file name is tidied up (no ending, no leading number, underscores become spaces) |
| `kind` | `"hat"` or `"limb"` |
| `reanim` | the reanimations the script can run on, as ids. Every shipped hat script lists both hat ones and runs on your pick. With one id the script always runs on that one, and the hub says so when it starts |
| `needsfd` | `true` for a script that carries or needs FDless. The hub keeps the flag for the details page; nothing acts on it yet |
| `credit` | the people to credit, as a list |
| `desc` | the text on the details page |

For a script of your own that you don't want to touch the manifest for, write the same things as lines at the top of the file. A line looks like `-- @name My Script` and the hub reads the first 6000 characters.

| line | same as |
|---|---|
| `@name` | `name` |
| `@kind hat` or `@kind limb` | `kind` |
| `@reanim fdless, atsuko` (or `any`) | `reanim` |
| `@needsfd` (or `@needsfd true`) | `needsfd` |
| `@credit A, B` and `@author A, B` | `credit` |
| `@desc words` | `desc` |

When both are there the script's own line wins and the manifest fills in what the file leaves out.
