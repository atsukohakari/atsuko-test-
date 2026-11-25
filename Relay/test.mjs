import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join as joinPath } from "node:path";

const here = dirname(fileURLToPath(import.meta.url));
let source = readFileSync(joinPath(here, "worker.js"), "utf8");
source = source.replace('import { DurableObject } from "cloudflare:workers";', "class DurableObject { constructor(ctx, env) {} }");

class FakeSocket {
	constructor(name) {
		this.name = name;
		this.got = [];
		this.closed = null;
		this.att = null;
		this.peer = null;
	}
	serializeAttachment(v) {
		this.att = JSON.parse(JSON.stringify(v));
	}
	deserializeAttachment() {
		return this.att;
	}
	send(text) {
		if (this.closed) {
			throw new Error("closed");
		}
		this.got.push(JSON.parse(text));
	}
	close(code, reason) {
		this.closed = [code, reason];
	}
}

let made = 0;
globalThis.WebSocketPair = class {
	constructor() {
		made += 1;
		const client = new FakeSocket("client" + made);
		const server = new FakeSocket("server" + made);
		client.peer = server;
		server.peer = client;
		this[0] = client;
		this[1] = server;
	}
};
const RealResponse = globalThis.Response;
globalThis.Response = class {
	constructor(body, init) {
		this.body = body;
		this.status = (init && init.status) || 200;
		this.webSocket = init && init.webSocket;
	}
	async text() {
		return String(this.body);
	}
};

const mod = await import("data:text/javascript;base64," + Buffer.from(source).toString("base64"));
const { Room } = mod;
const worker = mod.default;

let fails = 0;
let passes = 0;
function ok(cond, label) {
	if (cond) {
		passes += 1;
	} else {
		fails += 1;
		console.log("FAIL", label);
	}
}

const sockets = [];
const ctx = {
	acceptWebSocket(ws) {
		sockets.push(ws);
	},
	getWebSockets() {
		return sockets.filter((s) => !s.closed);
	},
};
const room = new Room(ctx, {});

function req(url, upgrade) {
	const headers = new Map();
	if (upgrade) {
		headers.set("Upgrade", "websocket");
	}
	return { url, headers: { get: (k) => headers.get(k) || null } };
}

async function join(u) {
	const res = await room.fetch(req("https://relay.test/room/1-abc?u=" + u, true));
	return res;
}

const plain = await room.fetch(req("https://relay.test/room/1-abc?u=7", false));
ok(plain.status === 426, "a normal request is told to use a WebSocket");
const nobody = await room.fetch(req("https://relay.test/room/1-abc", true));
ok(nobody.status === 400, "a connection must say who it is");

const ra = await join(7);
ok(ra.status === 101 && ra.webSocket, "the first player joins");
const a = sockets[sockets.length - 1];
const rb = await join(8);
const b = sockets[sockets.length - 1];
ok(rb.status === 101, "a second player joins");
ok(a.got.some((m) => m.k === "join" && m.u === 8), "the first hears the second join");

await room.webSocketMessage(a, JSON.stringify({ k: "f", t: 1, o: [[1, 0, 0, 0, 0, 0, 0]] }));
const f = b.got.find((m) => m.k === "f");
ok(f && f.u === 7, "a frame reaches the other player stamped with who sent it");
ok(!a.got.some((m) => m.k === "f"), "and isn't echoed back");

await room.webSocketMessage(a, JSON.stringify({ k: "a", u: 8, o: [] }));
const spoof = b.got.filter((m) => m.k === "a").pop();
ok(spoof && spoof.u === 7, "saying you're someone else doesn't work");

await room.webSocketMessage(a, JSON.stringify({ k: "ping" }));
const pong = a.got.find((m) => m.k === "pong");
ok(pong && pong.n === 2, "a ping gets how many are in the room");

const before = b.got.length;
await room.webSocketMessage(a, "not json");
await room.webSocketMessage(a, "[1,2,3]");
await room.webSocketMessage(a, JSON.stringify({ nok: 1 }));
await room.webSocketMessage(a, "x".repeat(60000));
ok(b.got.length === before, "junk is dropped");

a.att.t = Date.now();
a.att.n = 0;
for (let i = 0; i < 60; i += 1) {
	await room.webSocketMessage(a, JSON.stringify({ k: "f", t: i, o: [] }));
}
const flood = b.got.filter((m) => m.k === "f").length;
ok(flood <= 41, "at most forty messages a second from one player: " + flood);

const rc = await join(7);
ok(a.closed && a.closed[0] === 4000, "joining again from another game window closes the old one");
const c = sockets[sockets.length - 1];

await room.webSocketClose(c, 1000, "bye");
ok(b.got.some((m) => m.k === "bye" && m.u === 7), "leaving tells the others");

const top = await worker.fetch(req("https://relay.test/", false), {});
ok(top.status === 200, "the front page says it's up");
let asked = null;
const env = {
	ROOMS: {
		idFromName(name) {
			asked = name;
			return name;
		},
		get() {
			return { fetch: async () => new Response("room", { status: 200 }) };
		},
	},
};
await worker.fetch(req("https://relay.test/room/123-a-b-c?u=1", true), env);
ok(asked === "123-a-b-c", "each Roblox server gets its own room");
await worker.fetch(req("https://relay.test/room/../x", true), env);
ok(asked === "123-a-b-c", "odd room names are refused");

globalThis.Response = RealResponse;
console.log(passes + " passed, " + fails + " failed");
process.exit(fails === 0 ? 0 : 1);
