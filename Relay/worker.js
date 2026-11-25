import { DurableObject } from "cloudflare:workers";

const MAX_PEERS = 60;
const MAX_LEN = 48000;
const MAX_PER_SEC = 40;
const ROOM = /^\/room\/([0-9A-Za-z-]{1,90})$/;

export class Room extends DurableObject {
	constructor(ctx, env) {
		super(ctx, env);
		this.ctx = ctx;
	}

	peers() {
		return this.ctx.getWebSockets();
	}

	broadcast(from, text) {
		for (const peer of this.peers()) {
			if (peer !== from) {
				try {
					peer.send(text);
				} catch (e) {}
			}
		}
	}

	async fetch(request) {
		if (request.headers.get("Upgrade") !== "websocket") {
			return new Response("Atsuko Hub relay", { status: 426 });
		}
		const url = new URL(request.url);
		const u = (url.searchParams.get("u") || "").replace(/[^0-9]/g, "").slice(0, 16);
		if (!u) {
			return new Response("missing user", { status: 400 });
		}
		for (const peer of this.peers()) {
			const a = peer.deserializeAttachment() || {};
			if (a.u === u) {
				try {
					peer.close(4000, "joined again");
				} catch (e) {}
			}
		}
		if (this.peers().length >= MAX_PEERS) {
			return new Response("room full", { status: 503 });
		}
		const pair = new WebSocketPair();
		const [client, server] = Object.values(pair);
		this.ctx.acceptWebSocket(server);
		server.serializeAttachment({ u: u, t: Date.now(), n: 0 });
		this.broadcast(server, JSON.stringify({ k: "join", u: Number(u) }));
		return new Response(null, { status: 101, webSocket: client });
	}

	async webSocketMessage(ws, message) {
		if (typeof message !== "string" || message.length > MAX_LEN) {
			return;
		}
		const a = ws.deserializeAttachment() || {};
		const now = Date.now();
		if (now - (a.t || 0) >= 1000) {
			a.t = now;
			a.n = 0;
		}
		a.n = (a.n || 0) + 1;
		ws.serializeAttachment(a);
		if (a.n > MAX_PER_SEC) {
			return;
		}
		let data;
		try {
			data = JSON.parse(message);
		} catch (e) {
			return;
		}
		if (!data || typeof data !== "object" || Array.isArray(data) || typeof data.k !== "string") {
			return;
		}
		if (data.k === "ping") {
			try {
				ws.send(JSON.stringify({ k: "pong", n: this.peers().length }));
			} catch (e) {}
			return;
		}
		data.u = Number(a.u);
		this.broadcast(ws, JSON.stringify(data));
	}

	gone(ws) {
		const a = ws.deserializeAttachment() || {};
		if (a.u) {
			this.broadcast(ws, JSON.stringify({ k: "bye", u: Number(a.u) }));
		}
	}

	async webSocketClose(ws, code, reason) {
		this.gone(ws);
		try {
			ws.close(code, reason);
		} catch (e) {}
	}

	async webSocketError(ws) {
		this.gone(ws);
	}
}

export default {
	async fetch(request, env) {
		const url = new URL(request.url);
		const m = url.pathname.match(ROOM);
		if (!m) {
			return new Response("Atsuko Hub relay is up", { status: 200 });
		}
		const id = env.ROOMS.idFromName(m[1]);
		return env.ROOMS.get(id).fetch(request);
	},
};
