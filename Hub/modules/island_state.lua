local IslandState = {}
IslandState.__index = IslandState

IslandState.BASE_W = 310
IslandState.HEAD_H = 128
IslandState.PAD_BOTTOM = 10
IslandState.MIN_LYRIC_H = 32
IslandState.LINE_CUR = 14
IslandState.LINE_NEXT = 14
IslandState.MAX_CUR_LINES = 2

IslandState.STAGES = {
	{ name = "art", delay = 0.00 },
	{ name = "text", delay = 0.05 },
	{ name = "controls", delay = 0.10 },
	{ name = "progress", delay = 0.15 },
	{ name = "lyrics", delay = 0.21 },
}

function IslandState.new()
	return setmetatable({ state = "closed", token = 0 }, IslandState)
end

local function begin(self, state)
	self.state = state
	self.token = self.token + 1
	return self.token
end

function IslandState:isOpenish()
	return self.state == "opening" or self.state == "open"
end

function IslandState:isVisible()
	return self.state ~= "closed"
end

function IslandState:tap(hasTrack)
	local s = self.state
	if s == "closed" then
		if hasTrack then
			return { action = "open", token = begin(self, "opening") }
		end
		return { action = "home" }
	end
	if s == "opening" or s == "open" then
		return { action = "close", token = begin(self, "closing") }
	end
	if hasTrack then
		return { action = "open", token = begin(self, "opening") }
	end
	return { action = "none" }
end

function IslandState:open(hasTrack)
	if not hasTrack then
		return { action = "none" }
	end
	local s = self.state
	if s == "opening" or s == "open" then
		return { action = "none" }
	end
	return { action = "open", token = begin(self, "opening") }
end

function IslandState:close()
	if self:isOpenish() then
		return { action = "close", token = begin(self, "closing") }
	end
	return { action = "none" }
end

function IslandState:finish(token)
	if token ~= self.token then
		return false
	end
	if self.state == "opening" then
		self.state = "open"
		return true
	end
	if self.state == "closing" then
		self.state = "closed"
		return true
	end
	return false
end

function IslandState:snap()
	local was = self.state
	self.state = "closed"
	self.token = self.token + 1
	if was == "closed" then
		return { action = "none" }
	end
	return { action = "snap", token = self.token }
end

function IslandState:sync(hasTrack)
	if not hasTrack and self:isOpenish() then
		return self:close()
	end
	return { action = "none" }
end

function IslandState:trackChanged()
	if self:isOpenish() then
		return { action = "swap", token = self.token }
	end
	return { action = "none" }
end

function IslandState:current(token)
	return token == self.token
end

function IslandState.width(base, hubWidth)
	local room = hubWidth - 24
	local w = base
	if w > room then
		w = room
	end
	if w < 200 then
		w = math.min(200, room)
	end
	if w < 120 then
		w = 120
	end
	return w
end

function IslandState.lyricHeight(cur, nxt, countLines)
	local curLines = 1
	if cur ~= nil and cur ~= "" then
		curLines = countLines(cur)
		if curLines < 1 then
			curLines = 1
		end
		if curLines > IslandState.MAX_CUR_LINES then
			curLines = IslandState.MAX_CUR_LINES
		end
	end
	local h = 10 + curLines * IslandState.LINE_CUR
	if nxt ~= nil and nxt ~= "" then
		h = h + IslandState.LINE_NEXT
	end
	if h < IslandState.MIN_LYRIC_H then
		h = IslandState.MIN_LYRIC_H
	end
	return h
end

function IslandState.height(lyricH)
	return IslandState.HEAD_H + lyricH + IslandState.PAD_BOTTOM
end

function IslandState.lyricStatus(hasTrack, res)
	if not hasTrack then
		return "none"
	end
	if res == nil then
		return "loading"
	end
	return res.status or "loading"
end

function IslandState.stageDelay(name)
	for _, st in ipairs(IslandState.STAGES) do
		if st.name == name then
			return st.delay
		end
	end
	return 0
end

function IslandState.swipeUp(startY, nowY, threshold)
	return (startY - nowY) >= (threshold or 24)
end

function IslandState.needsMarquee(textWidth, windowWidth)
	return textWidth > windowWidth + 2
end

function IslandState.marquee(textWidth, windowWidth, speed)
	local dist = textWidth - windowWidth + 12
	if dist <= 0 then
		return 0, 0
	end
	return dist, dist / (speed or 28)
end

return IslandState
