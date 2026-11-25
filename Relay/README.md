# Live relay

Roblox only shows other players your hats moving. Everything your scripts make on your screen (bullets, beams, auras, particles, sounds) stays on your screen. The relay is a tiny server that lets hub users in the same Roblox server send each other their fake body and every effect, so they see yours and you see theirs.

It runs free on Cloudflare. You set it up once and everyone using your hub uses it.

## Set it up (about 10 minutes)

1. Make a free account at [dash.cloudflare.com](https://dash.cloudflare.com).
2. Install [Node.js](https://nodejs.org) (the LTS one).
3. Open a terminal in this `Relay` folder and run:

   ```
   npx wrangler login
   ```

   A browser opens, tap Allow.
4. Then run:

   ```
   npx wrangler deploy
   ```

   At the end it prints a link like `https://atsuko-relay.yourname.workers.dev`. Open it in a browser, it should say "Atsuko Hub relay is up".
5. Put that link in `Hub/relay.txt` with `wss://` in front instead of `https://`:

   ```
   wss://atsuko-relay.yourname.workers.dev
   ```

6. Upload `Hub/relay.txt` to GitHub. Every hub picks it up the next time it starts.

To try a link before uploading it, paste it in main scripts > setup > live view > relay link. That box wins over `Hub/relay.txt`. Clear it to go back.

## What people see

- main scripts > setup > live view shows if it's connected and how many hub users it's showing.
- Show mine: your fake body, the parts your scripts make and their sounds go out while you're reanimated or a script has something on screen. Deanimating stops it, and their screens clear right away.
- See theirs: their body and effects show on your screen, smooth even while their real body keeps respawning. Hide their real body only shows the live one.
- Their sounds: how loud their sounds are for you.
- Someone you blocked in hub chat is never shown.

## What it sends

Your Roblox user id, the server you're in, and the positions, sizes, colors, meshes and sounds of your fake body and your scripts' parts. Nothing is saved on the server, it only passes messages between people in the same Roblox server.

Only Roblox assets come through (meshes, textures and sounds from Roblox), and every part is anchored, can't be touched and has a size limit, so nobody can break anyone's game with it.

## Free plan limits

Cloudflare's free plan gives 100,000 requests and 13,000 GB-s of Durable Object time a day. A room is awake while someone in it shares, which works out to roughly a day's worth of hours of people being reanimated, counted across everyone. If it runs out, the relay stops until 00:00 UTC and the hub says it can't reach it. The $5 Workers plan lifts the limits a lot.

## Files

| file | what it is |
|---|---|
| `worker.js` | the server: one room per Roblox server, passes messages, stamps who sent each one, limits sizes and speed |
| `wrangler.toml` | the Cloudflare setup |
| `test.mjs` | `node test.mjs` checks the server without Cloudflare |
