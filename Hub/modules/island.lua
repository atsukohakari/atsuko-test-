local Module = {}

local M = { conns = {}, buses = {}, alive = false }

function Module.init(ctx)
	if M.alive then
		Module.destroy()
	end
	Module.ctx = ctx
	local Core, UI, T, S, L, Bus = ctx.Core, ctx.UI, ctx.T, ctx.S, ctx.L, ctx.Bus
	local NP, Pill, Panel, MP, Root, Spot, Drag = ctx.NP, ctx.Pill, ctx.Panel, ctx.MP, ctx.Root, ctx.Spot, ctx.Drag
	local Island = ctx.Island
	local FONT_B, FONT_M = ctx.FONT_B, ctx.FONT_M
	local TextService, TweenService, UserInputService = ctx.TextService, ctx.TweenService, ctx.UserInputService
	local TOUCH, MOUSE1 = ctx.TOUCH, ctx.MOUSE1

	local IS = Core.loadModule("island_state")
	if not IS then
		error("island_state didn't load")
	end

	local state = IS.new()
	local V = { lyricH = IS.MIN_LYRIC_H, W = IS.BASE_W, key = nil, curText = nil, nextText = nil, slotsReset = true, shimmerTk = 0 }
	V.H = IS.height(V.lyricH)
	V.textW = V.W - 96
	local NPV = { lyOn = true, shown = function()
		return state:isVisible()
	end }

	M.alive = true
	M.frames = {}
	local function track(conn)
		M.conns[#M.conns + 1] = conn
		return conn
	end

	local f = UI.new("Frame", {
		Name = "Island",
		BackgroundColor3 = T.pillBg,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Size = UDim2.fromOffset(150, 26),
		Visible = false,
		ClipsDescendants = true,
		ZIndex = 4001,
		Active = true,
	}, Root)
	local corner = UI.corner(f, 22)
	local stroke = UI.stroke(f, T.stroke, 1, 1)
	local inner = UI.new("Frame", {
		Name = "Inner",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0),
		Size = UDim2.fromOffset(V.W, V.H),
		Visible = false,
		ZIndex = 3991,
	}, f)
	local bg = UI.button(f, { Name = "Bg", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 3990, Text = "" })
	local catcher = UI.button(Root, { Name = "IslandCatcher", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false, ZIndex = 3980, Text = "" })
	M.frames = { f, catcher }

	local slots = {}
	local function makeSlot(name, pos, size, anchor)
		local s = UI.new("Frame", {
			Name = name,
			BackgroundTransparency = 1,
			AnchorPoint = anchor or Vector2.new(0, 0),
			Position = pos,
			Size = size,
			Visible = false,
		}, inner)
		local pop = UI.new("UIScale", { Scale = 1 }, s)
		slots[name] = { frame = s, pos = pos, pop = pop }
		return s
	end

	local artSlot = makeSlot("art", UDim2.fromOffset(43, 43), UDim2.fromOffset(62, 62), Vector2.new(0.5, 0.5))
	local artScale = UI.new("UIScale", { Scale = 0.7 }, artSlot)
	local textSlot = makeSlot("text", UDim2.fromOffset(84, 12), UDim2.new(1, -96, 0, 48))
	local ctlSlot = makeSlot("controls", UDim2.fromOffset(84, 62), UDim2.new(1, -96, 0, 34))
	local progSlot = makeSlot("progress", UDim2.fromOffset(12, 98), UDim2.new(1, -24, 0, 30))
	local lyrSlot = makeSlot("lyrics", UDim2.fromOffset(12, IS.HEAD_H), UDim2.new(1, -24, 0, V.lyricH))

	NPV.root = inner
	NPV.art = NP.art(artSlot, 62, 14, UDim2.fromOffset(0, 0), 22, 5)

	local head = UI.new("Frame", { Name = "Head", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 14) }, textSlot)
	NPV.live = UI.new("Frame", { Name = "Live", BackgroundColor3 = T.dim, Size = UDim2.fromOffset(6, 6), Position = UDim2.fromOffset(0, 4) }, head)
	UI.corner(NPV.live, 3)
	NPV.srcText = UI.label(head, {
		Font = FONT_B,
		TextSize = 9,
		TextColor3 = T.sub,
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -12, 1, 0),
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local titleWin = UI.new("Frame", { Name = "TitleWin", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 16), Size = UDim2.new(1, 0, 0, 18), ClipsDescendants = true }, textSlot)
	NPV.title = UI.label(titleWin, { Font = FONT_B, TextSize = 13, Size = UDim2.fromScale(1, 1), TextTruncate = Enum.TextTruncate.AtEnd })
	local artistWin = UI.new("Frame", { Name = "ArtistWin", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 34), Size = UDim2.new(1, 0, 0, 14), ClipsDescendants = true }, textSlot)
	NPV.artist = UI.label(artistWin, { TextSize = 10, TextColor3 = T.sub, Size = UDim2.fromScale(1, 1), TextTruncate = Enum.TextTruncate.AtEnd })

	local prev = NP.button(ctlSlot, "skip-back", 30, 13, UDim2.new(0, 16, 0.5, 0))
	local play
	play, NPV.playIcon = NP.button(ctlSlot, "play-fill", 34, 14, UDim2.new(0, 56, 0.5, 0), true)
	local nxt = NP.button(ctlSlot, "skip-forward", 30, 13, UDim2.new(0, 96, 0.5, 0))
	local openB = NP.button(ctlSlot, "maximize-2", 30, 13, UDim2.new(1, -16, 0.5, 0))
	local miniB = NP.button(ctlSlot, "picture-in-picture-2", 30, 13, UDim2.new(1, -52, 0.5, 0))

	NP.bar(progSlot, NPV, { Position = UDim2.fromOffset(0, 8), Size = UDim2.new(1, 0, 0, 4) }, true)
	NPV.tcur = UI.label(progSlot, { TextSize = 9, TextColor3 = T.sub, Text = "0:00", Position = UDim2.fromOffset(0, 14), Size = UDim2.new(0.5, 0, 0, 12) })
	NPV.ttotal = UI.label(progSlot, {
		TextSize = 9,
		TextColor3 = T.sub,
		Text = "-:--",
		TextXAlignment = Enum.TextXAlignment.Right,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 14),
		Size = UDim2.new(0.5, 0, 0, 12),
	})

	local words = UI.button(lyrSlot, {
		Name = "Words",
		BackgroundColor3 = T.card,
		BackgroundTransparency = 0.3,
		Size = UDim2.fromScale(1, 1),
		ClipsDescendants = true,
	})
	UI.corner(words, 10)
	local function lyricLabel(size, font, color)
		return UI.label(words, {
			Font = font,
			TextSize = size,
			TextColor3 = color,
			TextWrapped = true,
			TextTruncate = Enum.TextTruncate.None,
			TextYAlignment = Enum.TextYAlignment.Top,
			Position = UDim2.fromOffset(10, 5),
			Size = UDim2.new(1, -20, 0, 28),
			Text = "",
			TextTransparency = 1,
		})
	end
	V.curLabel = lyricLabel(11, FONT_B, T.text)
	V.curOther = lyricLabel(11, FONT_B, T.text)
	V.nextLabel = lyricLabel(9, FONT_M, T.sub)
	V.nextLabel.Size = UDim2.new(1, -20, 0, 14)
	NPV.lyCur = V.curLabel
	NPV.lyNext = V.nextLabel

	local function pillRect()
		local pf = Pill.frame
		local pos, ap, sz = pf.Position, pf.AnchorPoint, pf.Size
		local w = sz.X.Offset + sz.X.Scale * L.W
		local h = sz.Y.Offset + sz.Y.Scale * L.H
		local x = pos.X.Scale * L.W + pos.X.Offset - ap.X * w
		local y = pos.Y.Scale * L.H + pos.Y.Offset - ap.Y * h
		return x, y, w, h
	end

	local function target()
		local px, py, pw, ph = pillRect()
		local w = IS.width(IS.BASE_W, L.W)
		local cx = math.clamp(px + pw / 2, w / 2 + 8, L.W - w / 2 - 8)
		local down = not (Core.barLow and Core.barLow())
		local edgeY = down and py or (py + ph)
		if down then
			edgeY = math.max(8, math.min(edgeY, L.H - 8 - V.H))
		else
			edgeY = math.min(L.H - 8, math.max(edgeY, V.H + 8))
		end
		return cx, edgeY, down, w, pw, ph, px + pw / 2, (down and py or (py + ph))
	end

	local function setShape(cx, edgeY, w, h, down)
		f.AnchorPoint = Vector2.new(0.5, down and 0 or 1)
		f.Position = UDim2.fromOffset(cx, edgeY)
		f.Size = UDim2.fromOffset(w, h)
		inner.AnchorPoint = Vector2.new(0.5, down and 0 or 1)
		inner.Position = UDim2.fromScale(0.5, down and 0 or 1)
		inner.Size = UDim2.fromOffset(w, h)
	end

	local function countLines(text)
		local avail = math.max(60, V.W - 24 - 20)
		local ok, one = pcall(TextService.GetTextSize, TextService, "Ag", 11, FONT_B, Vector2.new(10000, 10000))
		local ok2, all = pcall(TextService.GetTextSize, TextService, text, 11, FONT_B, Vector2.new(avail, 10000))
		if not (ok and ok2) or one.Y <= 0 then
			return 1
		end
		return math.max(1, math.floor(all.Y / one.Y + 0.5))
	end

	local marquees = {}
	local function newMarquee(label, size, font)
		local mq = { tk = 0, text = nil, w = nil }
		function mq.stop()
			mq.tk += 1
			mq.text = nil
			label.Position = UDim2.fromOffset(0, 0)
		end
		function mq.update(force)
			local text = label.Text
			if not force and text == mq.text and V.textW == mq.w then
				return
			end
			mq.text, mq.w = text, V.textW
			mq.tk += 1
			local tk = mq.tk
			label.Position = UDim2.fromOffset(0, 0)
			local ok, sz = pcall(TextService.GetTextSize, TextService, text, size, font, Vector2.new(10000, size + 6))
			local tw = ok and sz.X or 0
			if not S.animations or not state:isOpenish() or not IS.needsMarquee(tw, V.textW) then
				label.Size = UDim2.fromScale(1, 1)
				label.TextTruncate = Enum.TextTruncate.AtEnd
				return
			end
			label.TextTruncate = Enum.TextTruncate.None
			label.Size = UDim2.new(0, tw + 8, 1, 0)
			local dist, secs = IS.marquee(tw, V.textW, 28)
			local function cycle()
				task.delay(1.4, function()
					if mq.tk ~= tk then
						return
					end
					local run = UI.tween(label, secs, { Position = UDim2.fromOffset(-dist, 0) }, Enum.EasingStyle.Linear)
					if not run then
						return
					end
					UI.done(run, function()
						if mq.tk ~= tk then
							return
						end
						task.delay(0.8, function()
							if mq.tk ~= tk then
								return
							end
							label.Position = UDim2.fromOffset(0, 0)
							cycle()
						end)
					end)
				end)
			end
			cycle()
		end
		marquees[#marquees + 1] = mq
		return mq
	end
	local titleMq = newMarquee(NPV.title, 13, FONT_B)
	local artistMq = newMarquee(NPV.artist, 10, FONT_M)

	local function refreshMarquees(force)
		titleMq.update(force)
		artistMq.update(force)
	end

	local function stopMarquees()
		for _, mq in ipairs(marquees) do
			mq.stop()
		end
		NPV.title.Size = UDim2.fromScale(1, 1)
		NPV.artist.Size = UDim2.fromScale(1, 1)
		NPV.title.TextTruncate = Enum.TextTruncate.AtEnd
		NPV.artist.TextTruncate = Enum.TextTruncate.AtEnd
	end

	local function stopShimmer()
		V.shimmerTk += 1
		if V.shimmerTween then
			pcall(function()
				V.shimmerTween:Cancel()
			end)
			V.shimmerTween = nil
		end
	end

	local function startShimmer()
		stopShimmer()
		if not S.animations then
			return
		end
		local tk = V.shimmerTk
		task.delay(0.35, function()
			if tk ~= V.shimmerTk or not state:isVisible() then
				return
			end
			local label = V.curLabel
			V.shimmerTween = TweenService:Create(label, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { TextTransparency = 0.75 })
			V.shimmerTween:Play()
		end)
	end

	local function setLyricHeight(h, animated)
		if h == V.lyricH then
			return
		end
		V.lyricH = h
		V.H = IS.height(h)
		local time = animated and 0.25 or 0
		UI.tween(lyrSlot, time, { Size = UDim2.new(1, -24, 0, h) })
		if state:isVisible() then
			local cx, edgeY, down, w = target()
			UI.tween(f, time, { Size = UDim2.fromOffset(w, V.H), Position = UDim2.fromOffset(cx, edgeY) })
			UI.tween(inner, time, { Size = UDim2.fromOffset(w, V.H) })
			if Island.onMove then
				pcall(Island.onMove)
			end
		else
			inner.Size = UDim2.fromOffset(V.W, V.H)
		end
	end

	local function showLines(cur, nxt, slide, dim, loading)
		local curChanged = cur ~= V.curText
		local nextChanged = nxt ~= V.nextText
		V.curText, V.nextText = cur, nxt
		local curLines = (cur ~= "") and math.min(IS.MAX_CUR_LINES, math.max(1, countLines(cur))) or 1
		local nextY = 5 + curLines * IS.LINE_CUR
		local animated = state:isVisible() and V.slotsReset == false
		setLyricHeight(IS.lyricHeight(cur, nxt, countLines), animated)
		if curChanged then
			stopShimmer()
			local old, new = V.curLabel, V.curOther
			V.curLabel, V.curOther = new, old
			NPV.lyCur = new
			new.Text = cur
			new.TextColor3 = dim and T.sub or T.text
			new.TextTransparency = 1
			new.Position = UDim2.fromOffset(10, 5 + ((slide and animated) and 10 or 0))
			UI.tween(new, 0.28, { Position = UDim2.fromOffset(10, 5), TextTransparency = dim and 0.25 or 0 }, Enum.EasingStyle.Quint)
			UI.tween(old, 0.22, { Position = UDim2.fromOffset(10, (slide and animated) and -5 or 5), TextTransparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			if loading then
				startShimmer()
			end
		end
		if nextChanged or curChanged then
			if nextChanged then
				V.nextLabel.Text = nxt
				V.nextLabel.TextTransparency = 1
			end
			UI.tween(V.nextLabel, 0.22, { Position = UDim2.fromOffset(10, nextY), TextTransparency = 0.1 })
		end
	end

	function NPV.setLines(cur, nxt, synced, res)
		local t1, t2, dim = cur, nxt, false
		local loading = res == nil and cur ~= "" and cur ~= nil and string.find(cur, "Looking", 1, true) ~= nil
		if res and res.status == "plain" and type(res.lines) == "table" then
			local shown = {}
			for _, ln in ipairs(res.lines) do
				if ln.text and ln.text ~= "" then
					shown[#shown + 1] = ln.text
					if #shown == 2 then
						break
					end
				end
			end
			if #shown > 0 then
				t1, t2, dim = shown[1], shown[2] or "", true
			end
		end
		if loading == false and res ~= nil and res.status == "loading" then
			loading = true
		end
		showLines(t1, t2, synced == true, dim, loading)
	end

	local function fracNow()
		local i = NP.info(NP.srcOf(NPV))
		if i.has and i.len and i.len > 0 then
			return math.clamp(i.pos / i.len, 0, 1)
		end
		return 0
	end

	local function resetSlots()
		for name, s in pairs(slots) do
			s.frame.Visible = false
			s.frame.Position = (name == "art") and s.pos or (s.pos + UDim2.fromOffset(0, 8))
			s.pop.Scale = (name == "art") and 1 or 0.94
		end
		artScale.Scale = 0.7
		V.slotsReset = true
	end

	local function revealSlot(name, instant)
		local s = slots[name]
		if not s then
			return
		end
		s.frame.Visible = true
		if instant then
			s.frame.Position = s.pos
			s.pop.Scale = 1
			if name == "art" then
				artScale.Scale = 1
			end
			return
		end
		UI.tween(s.pop, 0.3, { Scale = 1 }, Enum.EasingStyle.Quint)
		UI.tween(s.frame, 0.32, { Position = s.pos }, Enum.EasingStyle.Quint)
		if name == "art" then
			UI.tween(artScale, 0.4, { Scale = 1 }, Enum.EasingStyle.Back)
		end
		if name == "progress" and NPV.fill then
			NPV.fill.Size = UDim2.fromScale(0, 1)
			if NPV.knob then
				NPV.knob.Position = UDim2.fromScale(0, 0.5)
			end
			local frac = fracNow()
			UI.tween(NPV.fill, 0.45, { Size = UDim2.fromScale(frac, 1) }, Enum.EasingStyle.Quint)
			if NPV.knob then
				UI.tween(NPV.knob, 0.45, { Position = UDim2.fromScale(frac, 0.5) }, Enum.EasingStyle.Quint)
			end
		end
	end

	local function restorePill()
		if V.pillZ then
			Pill.frame.ZIndex = V.pillZ
			V.pillZ = nil
		end
	end

	local function hideNow()
		stopMarquees()
		stopShimmer()
		catcher.Visible = false
		f.Visible = false
		f.BackgroundTransparency = 1
		stroke.Transparency = 1
		inner.Visible = false
		resetSlots()
		restorePill()
		if Island.onMove then
			pcall(Island.onMove)
		end
	end

	local function sync()
		Island.open = state:isOpenish()
	end

	local function finishOpen(tk)
		if not state:finish(tk) then
			return
		end
		sync()
		refreshMarquees(true)
	end

	local function finishClose(tk)
		if not state:finish(tk) then
			return
		end
		sync()
		hideNow()
	end

	local function doOpen(tk)
		local cx, edgeY, down, w, pw, ph, pillCx, pillEdge = target()
		V.W = w
		V.textW = w - 96
		local fromPill = not f.Visible
		if fromPill then
			NP.render(NPV)
		end
		if V.pillZ == nil then
			V.pillZ = Pill.frame.ZIndex
		end
		inner.Size = UDim2.fromOffset(w, V.H)
		if fromPill then
			setShape(pillCx, pillEdge, pw, ph, down)
			corner.CornerRadius = UDim.new(0, math.floor(ph / 2))
			f.BackgroundTransparency = 1
			stroke.Transparency = 0.45
			inner.Visible = true
			resetSlots()
			f.Visible = true
		else
			f.AnchorPoint = Vector2.new(0.5, down and 0 or 1)
			inner.AnchorPoint = Vector2.new(0.5, down and 0 or 1)
			inner.Position = UDim2.fromScale(0.5, down and 0 or 1)
		end
		catcher.Visible = true
		Pill.frame.ZIndex = 4000
		f.ZIndex = 4001
		local grow = S.animations and 0.45 or 0
		UI.tween(f, math.min(grow, 0.12), { BackgroundTransparency = 0.04 }, Enum.EasingStyle.Quad)
		local sizeTween = UI.tween(f, grow, { Position = UDim2.fromOffset(cx, edgeY), Size = UDim2.fromOffset(w, V.H) }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		UI.tween(corner, grow, { CornerRadius = UDim.new(0, 22) }, Enum.EasingStyle.Quint)
		UI.tween(stroke, grow, { Transparency = 0.4 })
		inner.Visible = true
		if not S.animations then
			for name in pairs(slots) do
				revealSlot(name, true)
			end
			V.slotsReset = false
			finishOpen(tk)
		else
			local staged = V.slotsReset
			V.slotsReset = false
			for _, st in ipairs(IS.STAGES) do
				if staged then
					task.delay(0.1 + st.delay, function()
						if state:current(tk) and state:isOpenish() then
							revealSlot(st.name, false)
						end
					end)
				else
					revealSlot(st.name, true)
				end
			end
			UI.done(sizeTween, function()
				finishOpen(tk)
			end)
			task.delay(1.2 / math.max(0.5, S.animSpeed), function()
				if state.state == "opening" and state:current(tk) then
					finishOpen(tk)
				end
			end)
		end
		if Island.onMove then
			pcall(Island.onMove)
		end
		if Spot.live() and NP.liveSource() == "spotify" and os.clock() - Spot.lastPoll > 1.5 then
			task.spawn(Spot.poll)
		end
	end

	local function doClose(tk)
		stopMarquees()
		stopShimmer()
		catcher.Visible = false
		if not S.animations then
			finishClose(tk)
			return
		end
		for name, s in pairs(slots) do
			if name ~= "art" then
				UI.tween(s.pop, 0.1, { Scale = 0.94 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			end
		end
		UI.tween(artScale, 0.1, { Scale = 0.7 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.delay(0.08, function()
			if not state:current(tk) or state.state ~= "closing" then
				return
			end
			inner.Visible = false
			if Island.onMove then
				pcall(Island.onMove)
			end
			local _, _, down, _, pw, ph, pillCx, pillEdge = target()
			f.AnchorPoint = Vector2.new(0.5, down and 0 or 1)
			local tw = UI.tween(f, 0.25, { Position = UDim2.fromOffset(pillCx, pillEdge), Size = UDim2.fromOffset(pw, ph) }, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut)
			UI.tween(corner, 0.25, { CornerRadius = UDim.new(0, math.floor(ph / 2)) }, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut)
			UI.tween(stroke, 0.25, { Transparency = 0.45 })
			UI.done(tw, function()
				if not state:current(tk) or state.state ~= "closing" then
					return
				end
				local fade = UI.tween(f, 0.12, { BackgroundTransparency = 1 }, Enum.EasingStyle.Quad)
				UI.tween(stroke, 0.12, { Transparency = 1 })
				UI.done(fade, function()
					finishClose(tk)
				end)
			end)
		end)
		task.delay(1.1 / math.max(0.5, S.animSpeed), function()
			if state.state == "closing" and state:current(tk) then
				finishClose(tk)
			end
		end)
	end

	local function apply(act)
		if act.action == "open" then
			sync()
			doOpen(act.token)
		elseif act.action == "close" then
			sync()
			doClose(act.token)
		elseif act.action == "snap" then
			sync()
			hideNow()
		end
		return act.action
	end

	local function swapContent()
		local act = state:trackChanged()
		if act.action ~= "swap" or state.state ~= "open" or not S.animations then
			return
		end
		for _, name in ipairs({ "art", "text" }) do
			local s = slots[name]
			s.pop.Scale = 0.92
			if name ~= "art" then
				s.frame.Position = s.pos + UDim2.fromOffset(0, 6)
			end
			UI.tween(s.pop, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
			UI.tween(s.frame, 0.3, { Position = s.pos }, Enum.EasingStyle.Quint)
		end
		revealSlot("progress", false)
		refreshMarquees(true)
	end

	function NPV.extra(i)
		if V.key ~= i.key then
			local had = V.key ~= nil
			V.key = i.key
			if had then
				swapContent()
			end
		end
		refreshMarquees(false)
	end

	function Island.tap()
		return apply(state:tap(NP.hasTrack()))
	end

	function Island.show()
		return apply(state:open(NP.hasTrack()))
	end

	function Island.hide(instant)
		if instant then
			return apply(state:snap())
		end
		return apply(state:close())
	end

	function Island.close()
		return apply(state:close())
	end

	function Island.place()
		if state.state == "closed" then
			return
		end
		local cx, edgeY, down, w = target()
		V.W = w
		V.textW = w - 96
		if state.state == "open" then
			setShape(cx, edgeY, w, V.H, down)
			refreshMarquees(true)
		else
			UI.tween(f, 0.2, { Position = UDim2.fromOffset(cx, edgeY), Size = UDim2.fromOffset(w, V.H) })
			UI.tween(inner, 0.2, { Size = UDim2.fromOffset(w, V.H) })
		end
	end

	function Island.sync()
		apply(state:sync(NP.hasTrack()))
	end

	function Island.stateName()
		return state.state
	end

	function Island.bottom()
		if not state:isOpenish() or not f.Visible then
			return nil
		end
		local _, edgeY, down = target()
		if not down then
			return nil
		end
		return edgeY + V.H
	end

	function Island.rect()
		if not state:isOpenish() or not f.Visible then
			return nil
		end
		local cx, edgeY, down, w = target()
		return cx - w / 2, down and edgeY or (edgeY - V.H), w, V.H
	end

	Island.available = true
	Island.v = NPV
	Island.frame = f
	Island.inner = inner
	Island.slots = slots
	Island.catcher = catcher
	Island.bg = bg

	track(bg.Activated:Connect(function()
		Island.tap()
	end))
	track(catcher.Activated:Connect(function()
		Island.close()
	end))
	track(prev.Activated:Connect(function()
		NP.prev()
	end))
	track(play.Activated:Connect(function()
		NP.toggle()
	end))
	track(nxt.Activated:Connect(function()
		NP.next()
	end))
	track(openB.Activated:Connect(function()
		Island.hide()
		Panel.go("player")
		Panel.setTab(MP, 1)
	end))
	track(miniB.Activated:Connect(function()
		Island.hide()
		NP.openMini()
	end))
	track(words.Activated:Connect(function()
		Island.hide()
		Panel.go("player")
		Panel.setTab(MP, 2)
	end))

	track(UserInputService.InputBegan:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.Escape and state:isOpenish() then
			Island.close()
		end
	end))

	local swipe = nil
	track(f.InputBegan:Connect(function(input)
		if input.UserInputType == TOUCH or input.UserInputType == MOUSE1 then
			swipe = { y = input.Position.Y, kind = input.UserInputType }
		end
	end))
	track(UserInputService.InputChanged:Connect(function(input)
		if not swipe or NPV.dragging or Drag.cur then
			return
		end
		local moving = input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement
		if moving and IS.swipeUp(swipe.y, input.Position.Y, 24) then
			swipe = nil
			Island.close()
		end
	end))
	track(UserInputService.InputEnded:Connect(function(input)
		if swipe and (input.UserInputType == swipe.kind) then
			swipe = nil
		end
	end))

	local function onHubHide()
		Island.hide(true)
	end
	Bus.on("hubhide", onHubHide)
	M.buses[#M.buses + 1] = { "hubhide", onHubHide }

	NP.add(NPV)
	Island.sync()
	return Module
end

function Module.destroy()
	if not M.alive then
		return
	end
	M.alive = false
	for _, c in ipairs(M.conns) do
		pcall(function()
			c:Disconnect()
		end)
	end
	M.conns = {}
	local ctx = Module.ctx
	for _, b in ipairs(M.buses) do
		if ctx and ctx.Bus then
			ctx.Bus.off(b[1], b[2])
		end
	end
	M.buses = {}
	for _, fr in ipairs(M.frames or {}) do
		pcall(function()
			fr:Destroy()
		end)
	end
	M.frames = {}
end

return Module
