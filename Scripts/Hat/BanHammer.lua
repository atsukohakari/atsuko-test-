local TITLE = "Ban Hammer"
local HAT_ID = "14464140694"
local HAMMER_MESH, HAMMER_TEX = "14463205245", "14463205530"
local MUSIC_ID, SWING_ID = "15689446096", "6798698437"
local genv = (typeof(getgenv) == "function" and getgenv()) or _G

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CF, ANG = CFrame.new, CFrame.Angles
local sin, rad, min = math.sin, math.rad, math.min

local function say(text, kind, secs)
	local h = genv.AtsukoHub
	if type(h) == "table" and type(h.Notify) == "function" and pcall(h.Notify, TITLE, text, kind or "info", secs or 3) then
		return
	end
	local f = genv.AtsukoNotify
	if type(f) == "function" and pcall(f, TITLE, text, kind or "info", secs or 3) then
		return
	end
	warn("[" .. TITLE .. "] " .. tostring(text))
end

local POSES = {
	default = {
		heavy = false,
		idle = {
			walk = 16,
			jump = 0,
			always = true,
			pose = function(sine)
				return {
					["RootJoint"] = CF(0, -0.15 + (0.2 * sin(sine * 2)), 0) * ANG(-rad(80) + (rad(5) * sin((sine + 0.75) * -2)), 0, rad(180)),
					["Neck"] = CF(0, 1, 0) * ANG(-rad(110) + (rad(5) * sin((sine - 0.125) * -2)), 0, rad(180)),
					["Right Shoulder"] = CF(1, -0.25 + (0.15 * sin((sine + 0.5) * -2)), -0.125) * ANG(rad(140) + (rad(10) * sin((sine + 0.5) * 2)), rad(60), -rad(40)),
					["Left Shoulder"] = CF(-1.125, -0.25, -0.3) * ANG(rad(90) + (rad(10) * sin((sine + 1) * -2)), -rad(120), -rad(40)),
					["Right Hip"] = CF(1, -0.875 + (0.19 * sin(sine * -2)), 0.0775 * sin((sine + 0.95) * -2)) * ANG(-rad(30) + (rad(5) * sin((sine + 0.75) * 2)), rad(70), rad(20)),
					["Left Hip"] = CF(-1, -0.875 + (0.19 * sin(sine * -2)), 0.0775 * sin((sine + 0.95) * -2)) * ANG(-rad(30) + (rad(5) * sin((sine + 0.75) * 2)), -rad(70), -rad(20)),
					["Hammer"] = CF(1.4 + (0.025 * sin((sine + 0.75) * -2)), -0.9 + (0.05 * sin((sine + 0.75) * -2)), -2) * ANG(-rad(180), 0, rad(70) + (rad(5) * sin((sine + 0.75) * -2))),
				}
			end,
		},
		walk = {
			walk = 45,
			jump = 0,
			always = false,
			pose = function(sine)
				return {
					["RootJoint"] = CF(0, 0.2 * sin(sine * 28), 0) * ANG(-rad(120), rad(2.5) * sin(sine * 14), rad(160)),
					["Neck"] = CF(0, 1 + (0.05 * sin((sine + 0.3) * 28)), 0) * ANG(-rad(80) + (rad(5) * sin((sine + 0.375) * 28)), rad(5) + (rad(4) * sin((sine + 0.05) * -14)), -rad(160) + (rad(2.5) * sin((sine - 0.1) * 14))),
					["Right Shoulder"] = CF(0.9, 0.35, -0.25 + (0.5 * sin((sine + 0.5) * 14))) * ANG(rad(50) * sin(sine * -14), rad(100) + (rad(50) * sin((sine + 0.7) * 14)), rad(40) + (rad(90) * sin((sine + 0.5) * -14))),
					["Left Shoulder"] = CF(-1, 0, 0.1) * ANG(-rad(50), -rad(60), rad(100)),
					["Right Hip"] = CF(0.975 + (0.25 * sin((sine + 0.3) * 14)), -1.2 + (sin((sine + 0.075) * 14)), -0.5 + (sin((sine + 0.275) * 14))) * ANG(0, rad(110) + (rad(12.5) * sin((sine + 0.1) * -14)), rad(120) * sin((sine - 0.025) * 14)),
					["Left Hip"] = CF(-1.075 + (0.5 * sin((sine + 0.275) * -14)), -0.95 + (sin((sine + 0.075) * -14)), -0.25 + (sin((sine + 0.275) * -14))) * ANG(0, -rad(70) + (rad(12.5) * sin((sine + 0.1) * -14)), rad(120) * sin((sine - 0.025) * 14)),
					["Hammer"] = CF(0.5, -1.125, 0.5) * ANG(-rad(180), -rad(5), -rad(100)),
				}
			end,
		},
		jump = {
			walk = 45,
			jump = 0,
			always = false,
			pose = function(sine)
				return {
					["RootJoint"] = CF(0, 0.2 * sin(sine * 28), 0) * ANG(-rad(120), rad(2.5) * sin(sine * 14), rad(160)),
					["Neck"] = CF(0, 1 + (0.05 * sin((sine + 0.3) * 28)), 0) * ANG(-rad(80) + (rad(5) * sin((sine + 0.375) * 28)), rad(5) + (rad(4) * sin((sine + 0.05) * -14)), -rad(160) + (rad(2.5) * sin((sine - 0.1) * 14))),
					["Right Shoulder"] = CF(0.9, 0.35, -0.25 + (0.5 * sin((sine + 0.5) * 14))) * ANG(rad(50) * sin(sine * -14), rad(100) + (rad(50) * sin((sine + 0.7) * 14)), rad(40) + (rad(90) * sin((sine + 0.5) * -14))),
					["Left Shoulder"] = CF(-1, 0, 0.1) * ANG(-rad(50), -rad(60), rad(100)),
					["Right Hip"] = CF(0.975 + (0.25 * sin((sine + 0.3) * 14)), -1.2 + (sin((sine + 0.075) * 14)), -0.5 + (sin((sine + 0.275) * 14))) * ANG(0, rad(110) + (rad(12.5) * sin((sine + 0.1) * -14)), rad(120) * sin((sine - 0.025) * 14)),
					["Left Hip"] = CF(-1.075 + (0.5 * sin((sine + 0.275) * -14)), -0.95 + (sin((sine + 0.075) * -14)), -0.25 + (sin((sine + 0.275) * -14))) * ANG(0, -rad(70) + (rad(12.5) * sin((sine + 0.1) * -14)), rad(120) * sin((sine - 0.025) * 14)),
					["Hammer"] = CF(0.5, -1.125, 0.5) * ANG(-rad(180), -rad(5), -rad(100)),
				}
			end,
		},
		fall = {
			walk = 45,
			jump = 0,
			always = false,
			pose = function(sine)
				return {
					["RootJoint"] = CF(0, 0.2 * sin(sine * 28), 0) * ANG(-rad(120), rad(2.5) * sin(sine * 14), rad(160)),
					["Neck"] = CF(0, 1 + (0.05 * sin((sine + 0.3) * 28)), 0) * ANG(-rad(80) + (rad(5) * sin((sine + 0.375) * 28)), rad(5) + (rad(4) * sin((sine + 0.05) * -14)), -rad(160) + (rad(2.5) * sin((sine - 0.1) * 14))),
					["Right Shoulder"] = CF(0.9, 0.35, -0.25 + (0.5 * sin((sine + 0.5) * 14))) * ANG(rad(50) * sin(sine * -14), rad(100) + (rad(50) * sin((sine + 0.7) * 14)), rad(40) + (rad(90) * sin((sine + 0.5) * -14))),
					["Left Shoulder"] = CF(-1, 0, 0.1) * ANG(-rad(50), -rad(60), rad(100)),
					["Right Hip"] = CF(0.975 + (0.25 * sin((sine + 0.3) * 14)), -1.2 + (sin((sine + 0.075) * 14)), -0.5 + (sin((sine + 0.275) * 14))) * ANG(0, rad(110) + (rad(12.5) * sin((sine + 0.1) * -14)), rad(120) * sin((sine - 0.025) * 14)),
					["Left Hip"] = CF(-1.075 + (0.5 * sin((sine + 0.275) * -14)), -0.95 + (sin((sine + 0.075) * -14)), -0.25 + (sin((sine + 0.275) * -14))) * ANG(0, -rad(70) + (rad(12.5) * sin((sine + 0.1) * -14)), rad(120) * sin((sine - 0.025) * 14)),
					["Hammer"] = CF(0.5, -1.125, 0.5) * ANG(-rad(180), -rad(5), -rad(100)),
				}
			end,
		},
	},
	r = {
		heavy = false,
		idle = {
			walk = 135,
			jump = 0,
			always = true,
			pose = function(sine)
				return {
					["RootJoint"] = CF(0.2 * sin((sine + 1.5) * 2), 2.5 + (0.4 * sin(sine * 2)), 0.5 * sin((sine + 0.5) * 2)) * ANG(-rad(100) + (rad(5) * sin(sine * 2)), rad(5) + (rad(5) * sin((sine + 0.5) * 2)), rad(170)),
					["Neck"] = CF(0, 1, 0) * ANG(-rad(95) + (rad(5) * sin(sine * 2)), -rad(5) + (rad(5) * sin((sine + 1) * 2)), rad(190)),
					["Right Shoulder"] = CF(0.9, 0.1 * sin((sine + 0.75) * 2), 0) * ANG(rad(45) + (rad(15) * sin(sine * 2)), rad(70) + (rad(10) * sin((sine + 0.5) * 2)), -rad(240) - (rad(10) * sin(sine * 2))),
					["Left Shoulder"] = CF(-1.2, 0.45 + (0.05 * sin(sine * 2)), 0) * ANG(rad(50) + (rad(5) * sin(sine * 2)), -rad(60) - (rad(5) * sin(sine * 2)), rad(50) + (rad(5) * sin(sine * 2))),
					["Right Hip"] = CF(1, -1 + (0.2 * sin((sine + 0.25) * 2)), -0.2) * ANG(-rad(15) + (rad(10) * sin((sine - 0.25) * 2)), rad(70) + (rad(5) * sin((sine + 0.5) * 2)), rad(10)),
					["Left Hip"] = CF(-1, -1.1 + (0.2 * sin((sine + 0.75) * 2)), 0.1 + (0.15 * sin(sine * -2))) * ANG(-rad(27), -rad(60) + (rad(10) * sin((sine + 0.5) * -2)), -rad(15) * sin(sine * 2)),
					["Hammer"] = CF(0.1 * sin(sine * 2), -1 + (0.2 * sin(sine * 2)), -0.5 + (0.2 * sin(sine * 2))) * ANG(-rad(25) + (rad(5) * sin(sine * 2)), -rad(25) + (rad(5) * sin(sine * 2)), -rad(65) - (rad(8.5) * sin((sine + 0.5) * 2))),
				}
			end,
		},
		walk = {
			walk = 135,
			jump = 0,
			always = false,
			pose = function(sine)
				return {
					["RootJoint"] = CF(0.4 * sin((sine + 1.5) * 2), 2.5 + (0.4 * sin(sine * 2)), 0.25 * sin((sine + 0.5) * 2)) * ANG(-rad(120) + (rad(5) * sin(sine * 2)), rad(5) + (rad(5) * sin((sine + 0.5) * 2)), rad(170)),
					["Neck"] = CF(0, 1, 0) * ANG(-rad(66) + (rad(2.5) * sin(sine * 2)), -rad(5) + (rad(5) * sin((sine + 1) * 2)), rad(190)),
					["Right Shoulder"] = CF(0.9, 0.1 * sin((sine + 0.75) * 2), 0) * ANG(rad(45) + (rad(15) * sin(sine * 2)), rad(70) + (rad(10) * sin((sine + 0.5) * 2)), -rad(240) - (rad(10) * sin(sine * 2))),
					["Left Shoulder"] = CF(-1, 0.3 + (0.05 * sin(sine * 2)), 0) * ANG(-rad(40) - (rad(15) * sin((sine + 0.5) * 2)), -rad(60) + (rad(5) * sin(sine * 2)), -rad(40) - (rad(15) * sin((sine + 0.5) * 2))),
					["Right Hip"] = CF(1, -1.2 + (0.2 * sin((sine + 0.25) * 2)), -0.2) * ANG(-rad(25) + (rad(17.5) * sin((sine - 0.25) * 2)), rad(70) + (rad(5) * sin((sine + 0.5) * 2)), rad(10)),
					["Left Hip"] = CF(-1, -1.4 + (0.3 * sin((sine + 0.75) * 2)), 0.1 + (0.2 * sin(sine * -2))) * ANG(-rad(35), -rad(60) + (rad(10) * sin((sine + 0.5) * -2)), -rad(20) * sin(sine * 2)),
					["Hammer"] = CF(0.1 * sin(sine * 2), -1 + (0.2 * sin(sine * 2)), -0.5 + (0.2 * sin(sine * 2))) * ANG(-rad(25) + (rad(5) * sin(sine * 2)), -rad(25) + (rad(5) * sin(sine * 2)), -rad(65) - (rad(8.5) * sin((sine + 0.5) * 2))),
				}
			end,
		},
		jump = {
			walk = 135,
			jump = 0,
			always = false,
			pose = function(sine)
				return {
					["RootJoint"] = CF(0.4 * sin((sine + 1.5) * 2), 2.5 + (0.4 * sin(sine * 2)), 0.25 * sin((sine + 0.5) * 2)) * ANG(-rad(120) + (rad(5) * sin(sine * 2)), rad(5) + (rad(5) * sin((sine + 0.5) * 2)), rad(170)),
					["Neck"] = CF(0, 1, 0) * ANG(-rad(66) + (rad(2.5) * sin(sine * 2)), -rad(5) + (rad(5) * sin((sine + 1) * 2)), rad(190)),
					["Right Shoulder"] = CF(0.9, 0.1 * sin((sine + 0.75) * 2), 0) * ANG(rad(45) + (rad(15) * sin(sine * 2)), rad(70) + (rad(10) * sin((sine + 0.5) * 2)), -rad(240) - (rad(10) * sin(sine * 2))),
					["Left Shoulder"] = CF(-1, 0.3 + (0.05 * sin(sine * 2)), 0) * ANG(-rad(40) - (rad(15) * sin((sine + 0.5) * 2)), -rad(60) + (rad(5) * sin(sine * 2)), -rad(40) - (rad(15) * sin((sine + 0.5) * 2))),
					["Right Hip"] = CF(1, -1.2 + (0.2 * sin((sine + 0.25) * 2)), -0.2) * ANG(-rad(25) + (rad(17.5) * sin((sine - 0.25) * 2)), rad(70) + (rad(5) * sin((sine + 0.5) * 2)), rad(10)),
					["Left Hip"] = CF(-1, -1.4 + (0.3 * sin((sine + 0.75) * 2)), 0.1 + (0.2 * sin(sine * -2))) * ANG(-rad(35), -rad(60) + (rad(10) * sin((sine + 0.5) * -2)), -rad(20) * sin(sine * 2)),
					["Hammer"] = CF(0.1 * sin(sine * 2), -1 + (0.2 * sin(sine * 2)), -0.5 + (0.2 * sin(sine * 2))) * ANG(-rad(25) + (rad(5) * sin(sine * 2)), -rad(25) + (rad(5) * sin(sine * 2)), -rad(65) - (rad(8.5) * sin((sine + 0.5) * 2))),
				}
			end,
		},
		fall = {
			walk = 135,
			jump = 0,
			always = false,
			pose = function(sine)
				return {
					["RootJoint"] = CF(0.4 * sin((sine + 1.5) * 2), 2.5 + (0.4 * sin(sine * 2)), 0.25 * sin((sine + 0.5) * 2)) * ANG(-rad(120) + (rad(5) * sin(sine * 2)), rad(5) + (rad(5) * sin((sine + 0.5) * 2)), rad(170)),
					["Neck"] = CF(0, 1, 0) * ANG(-rad(66) + (rad(2.5) * sin(sine * 2)), -rad(5) + (rad(5) * sin((sine + 1) * 2)), rad(190)),
					["Right Shoulder"] = CF(0.9, 0.1 * sin((sine + 0.75) * 2), 0) * ANG(rad(45) + (rad(15) * sin(sine * 2)), rad(70) + (rad(10) * sin((sine + 0.5) * 2)), -rad(240) - (rad(10) * sin(sine * 2))),
					["Left Shoulder"] = CF(-1, 0.3 + (0.05 * sin(sine * 2)), 0) * ANG(-rad(40) - (rad(15) * sin((sine + 0.5) * 2)), -rad(60) + (rad(5) * sin(sine * 2)), -rad(40) - (rad(15) * sin((sine + 0.5) * 2))),
					["Right Hip"] = CF(1, -1.2 + (0.2 * sin((sine + 0.25) * 2)), -0.2) * ANG(-rad(25) + (rad(17.5) * sin((sine - 0.25) * 2)), rad(70) + (rad(5) * sin((sine + 0.5) * 2)), rad(10)),
					["Left Hip"] = CF(-1, -1.4 + (0.3 * sin((sine + 0.75) * 2)), 0.1 + (0.2 * sin(sine * -2))) * ANG(-rad(35), -rad(60) + (rad(10) * sin((sine + 0.5) * -2)), -rad(20) * sin(sine * 2)),
					["Hammer"] = CF(0.1 * sin(sine * 2), -1 + (0.2 * sin(sine * 2)), -0.5 + (0.2 * sin(sine * 2))) * ANG(-rad(25) + (rad(5) * sin(sine * 2)), -rad(25) + (rad(5) * sin(sine * 2)), -rad(65) - (rad(8.5) * sin((sine + 0.5) * 2))),
				}
			end,
		},
	},
	e = {
		heavy = true,
		idle = {
			walk = 24,
			jump = 125,
			always = true,
			pose = function(sine)
				return {
					["RootJoint"] = ANG(-rad(100), 0, rad(190)),
					["Neck"] = CF(0, 1, 0) * ANG(-rad(80), 0, rad(170)),
					["Right Shoulder"] = CF(1, 0.3, 0) * ANG(0, rad(60), rad(210)),
					["Left Shoulder"] = CF(-1, 0.5, 0) * ANG(0, -rad(90), -rad(10)),
					["Right Hip"] = CF(1, -1, 0) * ANG(0, rad(90), rad(10)),
					["Left Hip"] = CF(-1, -1, 0) * ANG(0, -rad(80), rad(10)),
					["Hammer"] = CF(1, -1, -0.8) * ANG(0, -rad(15), -rad(90)),
				}
			end,
		},
		walk = {
			walk = 24,
			jump = 125,
			always = true,
			pose = function(sine)
				return {
					["RootJoint"] = ANG(-rad(100), 0, rad(190)),
					["Neck"] = CF(0, 1, 0) * ANG(-rad(80), 0, rad(170)),
					["Right Shoulder"] = CF(1, 0.3, 0) * ANG(0, rad(60), rad(210)),
					["Left Shoulder"] = CF(-1, 0.5, 0) * ANG(rad(50) * sin(sine * 7), -rad(90), 0),
					["Right Hip"] = CF(1, -1, 0) * ANG(rad(50) * sin(sine * 7), rad(90), 0),
					["Left Hip"] = CF(-1, -1, 0) * ANG(rad(50) * sin(sine * -7), -rad(90), 0),
					["Hammer"] = CF(1, -1, -0.8) * ANG(0, -rad(15), -rad(90)),
				}
			end,
		},
		jump = {
			walk = 24,
			jump = 125,
			always = true,
			pose = function(sine)
				return {
					["RootJoint"] = ANG(-rad(100), 0, rad(190)),
					["Neck"] = CF(0, 1, 0) * ANG(-rad(80), 0, rad(170)),
					["Right Shoulder"] = CF(1, 0.3, 0) * ANG(0, rad(60), rad(210)),
					["Left Shoulder"] = CF(-1, 0.5, 0) * ANG(rad(180), -rad(90), 0),
					["Right Hip"] = CF(1, -1, 0) * ANG(0, rad(90), 0),
					["Left Hip"] = CF(-1, -1, 0) * ANG(0, -rad(90), 0),
					["Hammer"] = CF(1, -1, -0.8) * ANG(0, -rad(15), -rad(90)),
				}
			end,
		},
		fall = {
			walk = 24,
			jump = 125,
			always = true,
			pose = function(sine)
				return {
					["RootJoint"] = ANG(-rad(100), 0, rad(190)),
					["Neck"] = CF(0, 1, 0) * ANG(-rad(80), 0, rad(170)),
					["Right Shoulder"] = CF(1, 0.3, 0) * ANG(0, rad(60), rad(210)),
					["Left Shoulder"] = CF(-1, 0.5, 0) * ANG(rad(180), -rad(90), 0),
					["Right Hip"] = CF(1, -1, 0) * ANG(0, rad(90), 0),
					["Left Hip"] = CF(-1, -1, 0) * ANG(0, -rad(90), 0),
					["Hammer"] = CF(1, -1, -0.8) * ANG(0, -rad(15), -rad(90)),
				}
			end,
		},
	},
	q = {
		heavy = true,
		idle = {
			walk = 16,
			jump = 50,
			always = true,
			pose = function(sine)
				return {
					["RootJoint"] = ANG(-rad(90), 0, rad(180)),
					["Neck"] = CF(0, 1, 0) * ANG(-rad(90), 0, rad(180)),
					["Right Shoulder"] = CF(1, 0.5, 0) * ANG(0, rad(90), rad(90)),
					["Left Shoulder"] = CF(-1, 0.5, 0) * ANG(-rad(7.5) * sin(sine * 0.7), -rad(90), 0),
					["Right Hip"] = CF(1, -1, 0) * ANG(-rad(7.5) * sin(sine * 0.7), rad(90), 0),
					["Left Hip"] = CF(-1, -1, 0) * ANG(rad(7.5) * sin(sine * 0.7), -rad(90), 0),
					["Hammer"] = CF(1, -3.6, -1.5) * ANG(rad(90), -rad(40), rad(90)),
				}
			end,
		},
		walk = {
			walk = 16,
			jump = 50,
			always = true,
			pose = function(sine)
				return {
					["RootJoint"] = ANG(-rad(90), 0, rad(180)),
					["Neck"] = CF(0, 1, 0) * ANG(-rad(90), 0, rad(180)),
					["Right Shoulder"] = CF(1, 0.5, 0) * ANG(0, rad(90), rad(90)),
					["Left Shoulder"] = CF(-1, 0.5, 0) * ANG(rad(50) * sin(sine * 7), -rad(90), 0),
					["Right Hip"] = CF(1, -1, 0) * ANG(rad(50) * sin(sine * 7), rad(90), 0),
					["Left Hip"] = CF(-1, -1, 0) * ANG(rad(50) * sin(sine * -7), -rad(90), 0),
					["Hammer"] = CF(1, -3.6, -1.5) * ANG(rad(90), -rad(40), rad(90)),
				}
			end,
		},
		jump = {
			walk = 16,
			jump = 50,
			always = true,
			pose = function(sine)
				return {
					["RootJoint"] = ANG(-rad(90), 0, rad(180)),
					["Neck"] = CF(0, 1, 0) * ANG(-rad(90), 0, rad(180)),
					["Right Shoulder"] = CF(1, 0.5, 0) * ANG(0, rad(90), rad(90)),
					["Left Shoulder"] = CF(-1, 0.5, 0) * ANG(rad(180), -rad(90), 0),
					["Right Hip"] = CF(1, -1, 0) * ANG(0, rad(90), 0),
					["Left Hip"] = CF(-1, -1, 0) * ANG(0, -rad(90), 0),
					["Hammer"] = CF(1, -3.6, -1.5) * ANG(rad(90), -rad(40), rad(90)),
				}
			end,
		},
		fall = {
			walk = 16,
			jump = 50,
			always = true,
			pose = function(sine)
				return {
					["RootJoint"] = ANG(-rad(90), 0, rad(180)),
					["Neck"] = CF(0, 1, 0) * ANG(-rad(90), 0, rad(180)),
					["Right Shoulder"] = CF(1, 0.5, 0) * ANG(0, rad(90), rad(90)),
					["Left Shoulder"] = CF(-1, 0.5, 0) * ANG(rad(180), -rad(90), 0),
					["Right Hip"] = CF(1, -1, 0) * ANG(0, rad(90), 0),
					["Left Hip"] = CF(-1, -1, 0) * ANG(0, -rad(90), 0),
					["Hammer"] = CF(1, -3.6, -1.5) * ANG(rad(90), -rad(40), rad(90)),
				}
			end,
		},
	},
}

local ATTACKS = {
	light = {
		{
			hold = 0.2,
			walk = nil,
			joints = {
				["RootJoint"] = CF(0, 0, 0.1) * ANG(-rad(85), 0, rad(110)),
				["Neck"] = CF(0, 1, 0) * ANG(-rad(95), -rad(10), -rad(120)),
				["Right Shoulder"] = CF(1, 0, -0.25) * ANG(rad(50), rad(40), rad(70)),
				["Left Shoulder"] = CF(1, 0.25, -0.25) * ANG(-rad(40), -rad(160), -rad(120)),
				["Right Hip"] = CF(0.95, -0.8, -0.1) * ANG(-rad(40), rad(50), rad(30)),
				["Left Hip"] = CF(-1, -1, -0.1) * ANG(-rad(40), -rad(70), -rad(30)),
				["Hammer"] = CF(0, -3.75, 0.5) * ANG(rad(120), -rad(100), -rad(140)),
			},
		},
		{
			hold = 0.3,
			walk = nil,
			joints = {
				["RootJoint"] = CF(0, 0, 0) * ANG(-rad(92), 0, rad(180)),
				["Neck"] = CF(0, 1, 0) * ANG(-rad(100), 0, rad(175)),
				["Right Shoulder"] = CF(0.7, 0.4, -0.3) * ANG(0, rad(150), rad(60)),
				["Left Shoulder"] = CF(-0.7, 0.4, -0.3) * ANG(0, -rad(90), -rad(60)),
				["Right Hip"] = CF(1, -1, 0) * ANG(-rad(55), rad(75), rad(63)),
				["Left Hip"] = CF(-1, -1, 0) * ANG(-rad(60), -rad(75), -rad(62)),
				["Hammer"] = CF(3, -3, 0) * ANG(-rad(90), rad(120), 0),
			},
		},
	},
	heavy = {
		{
			hold = 0.5,
			walk = 16,
			joints = {
				["RootJoint"] = ANG(-rad(90), 0, rad(180)),
				["Neck"] = CF(0, 1, 0) * ANG(-rad(90), 0, rad(180)),
				["Right Shoulder"] = CF(1, 0.5, 0) * ANG(0, rad(90), rad(90)),
				["Left Shoulder"] = CF(-1, 0.5, 0) * ANG(0, -rad(90), 0),
				["Right Hip"] = CF(1, -1, 0) * ANG(0, rad(90), rad(25)),
				["Left Hip"] = CF(-1, -1, 0) * ANG(0, -rad(90), rad(75)),
				["Hammer"] = CF(3.5, -2.5, -1.5) * ANG(rad(90), rad(50), rad(90)),
			},
		},
		{
			hold = 0.2,
			walk = 16,
			joints = {
				["RootJoint"] = ANG(-rad(90), 0, rad(180)),
				["Neck"] = CF(0, 1, 0) * ANG(-rad(90), 0, rad(180)),
				["Right Shoulder"] = CF(1, 0.5, 0) * ANG(0, rad(90), rad(90)),
				["Left Shoulder"] = CF(-1, 0.5, 0) * ANG(0, -rad(90), 0),
				["Right Hip"] = CF(1, -1, 0) * ANG(0, rad(90), rad(25)),
				["Left Hip"] = CF(-1, -1, 0) * ANG(0, -rad(90), rad(75)),
				["Hammer"] = CF(3.5, -2.5, -1.5) * ANG(rad(90), rad(50), rad(90)),
			},
		},
	},
}

local function loadLumen()
	local R = genv.LumenReanim
	if type(R) == "table" and type(R.rig) == "function" then
		return R
	end
	local base = type(genv.AtsukoHubRaw) == "string" and genv.AtsukoHubRaw or "https://raw.githubusercontent.com/atsukohakari/Atsuko/main/"
	local ok, src = pcall(function()
		if type(genv.AtsukoHubRead) == "function" then
			local got = genv.AtsukoHubRead("Hub/Reanimate.lua")
			if got or genv.AtsukoHubLocal then
				return got
			end
		end
		return game:HttpGet(base .. "Hub/Reanimate.lua")
	end)
	local fn = ok and type(src) == "string" and loadstring(src, "=Reanimate")
	if fn then
		local ok2, r = pcall(fn)
		if ok2 and type(r) == "table" and type(r.rig) == "function" then
			return r
		end
	end
	return nil
end

local function hatCount()
	local n = 0
	local ok, kids = pcall(function()
		local c = Players.LocalPlayer.Character
		return c and c:GetChildren() or {}
	end)
	for _, v in ipairs(ok and kids or {}) do
		if v:IsA("Accessory") then
			n += 1
		end
	end
	return n
end

local function gameCommand(text)
	local remote = ReplicatedStorage:FindFirstChild("01_server")
	if not (remote and remote:IsA("RemoteEvent")) then
		return false
	end
	return (pcall(remote.FireServer, remote, "cmd", text))
end

local function askForHammer()
	if not gameCommand("-r6") then
		return
	end
	task.wait(2)
	local before = hatCount()
	gameCommand("-gh " .. HAT_ID)
	task.wait(5)
	local deadline = os.clock() + 8
	while hatCount() <= before and os.clock() < deadline do
		task.wait(0.2)
	end
end

local hubFd = genv.AtsukoHatFd
local onHub = type(hubFd) == "table" and type(hubFd.reanimate) == "function" and type(hubFd.stopreanimate) == "function"
local Lumen = nil
if not onHub then
	askForHammer()
	Lumen = loadLumen()
	if not Lumen then
		say("Couldn't load the reanimation", "error", 5)
		return
	end
end

local rig = onHub and hubFd or Lumen.rig({ aligns = {} })
local okFd, fd = pcall(rig.reanimate)
local NEEDS = { "getJoint", "getPart", "getPartFromMesh", "getPartJoint", "addmode", "setWalkSpeed", "setJumpPower" }
local whole = okFd and type(fd) == "table" and type(fd.cframes) == "table"
if whole then
	for _, k in ipairs(NEEDS) do
		if type(fd[k]) ~= "function" then
			whole = false
		end
	end
end
if not whole then
	say("Couldn't reanimate: " .. tostring(okFd and "the reanimation gave no body" or fd), "error", 6)
	return
end

local live = (not onHub) and Lumen.current() or nil
local function reanimOn()
	if onHub then
		local ok, isOn = pcall(hubFd.isReanimated)
		return ok and isOn and true or false
	end
	return Lumen.current() == live and live ~= nil
end
do
	local deadline = os.clock() + 10
	while reanimOn() and live and type(live.isReady) == "function" and not live.isReady() and os.clock() < deadline do
		task.wait()
	end
	if not reanimOn() then
		say("The reanimation stopped", "error", 4)
		return
	end
end

local J, REST = {}, {}
for _, name in ipairs({ "RootJoint", "Neck", "Right Shoulder", "Left Shoulder", "Right Hip", "Left Hip" }) do
	local j = fd.getJoint(name)
	if type(j) == "table" and typeof(j.C0) == "CFrame" then
		J[name], REST[name] = j, j.C0
	else
		say("The body has no " .. name, "error", 5)
		return
	end
end
local hammer = fd.getPartFromMesh(HAMMER_MESH, HAMMER_TEX)
local hammerJoint = hammer and fd.getPartJoint(hammer)
if type(hammerJoint) == "table" and typeof(hammerJoint.C0) == "CFrame" then
	J.Hammer, REST.Hammer = hammerJoint, hammerJoint.C0
end
local head = fd.getPart("Head")

local alive = true
local conns = {}
local sounds = {}
local made = {}
local heavy = false
local attackPose = nil
local sine, alpha, lastTick = os.clock(), 0, os.clock()

local function guiRoot()
	if typeof(gethui) == "function" then
		local ok, g = pcall(gethui)
		if ok and typeof(g) == "Instance" then
			return g
		end
	end
	local ok, core = pcall(function()
		return game:GetService("CoreGui")
	end)
	if ok and core and pcall(function()
		local probe = Instance.new("Folder")
		probe.Parent = core
		probe:Destroy()
	end) then
		return core
	end
	return Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
end

local root = guiRoot()
local tag = Instance.new("BillboardGui")
tag.Name = "BanHammerTag"
tag.AlwaysOnTop = true
tag.ClipsDescendants = true
tag.LightInfluence = 1
tag.Size = UDim2.new(10, 0, 1.75, 0)
tag.StudsOffset = Vector3.new(0, 1.75, 0)
tag.ResetOnSpawn = false
local tagText = Instance.new("TextLabel")
tagText.Font = Enum.Font.Arcade
tagText.Text = "Exotic Ban Hammer Modded By Tory"
tagText.TextColor3 = Color3.new(0.4, 0.4, 0.4)
tagText.TextScaled = true
tagText.TextStrokeTransparency = 0
tagText.TextStrokeColor3 = Color3.new(0, 0.2, 0)
tagText.BackgroundColor3 = Color3.new(0, 0, 0)
tagText.BackgroundTransparency = 0.5
tagText.Size = UDim2.new(1, 0, 0.5, 0)
tagText.Parent = tag
tag.Parent = root
made[#made + 1] = tag

local screen = Instance.new("ScreenGui")
screen.Name = "BanHammerUI"
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = true
local note = Instance.new("TextBox")
note.FontFace = Font.new("rbxasset://fonts/families/PressStart2P.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
note.Text = "wait this by tory?"
note.TextColor3 = Color3.new(1, 1, 1)
note.TextSize = 30
note.TextStrokeTransparency = 0.5
note.TextXAlignment = Enum.TextXAlignment.Left
note.TextYAlignment = Enum.TextYAlignment.Bottom
note.BackgroundColor3 = Color3.new(1, 1, 1)
note.BackgroundTransparency = 0.8
note.BorderColor3 = Color3.new(0, 0, 0)
note.BorderSizePixel = 0
note.Position = UDim2.new(0, 0, 1, -1)
note.Parent = screen
screen.Parent = root
made[#made + 1] = screen

local function play(id, seconds, looped)
	if not alive then
		return
	end
	local s = Instance.new("Sound")
	s.SoundId = "rbxassetid://" .. id
	s.Looped = looped == true
	sounds[s] = true
	s.Parent = workspace
	s:Play()
	task.delay(seconds, function()
		sounds[s] = nil
		s:Destroy()
	end)
end

local function followHead()
	local cf = head and fd.cframes[head]
	if typeof(cf) == "CFrame" then
		tag.StudsOffsetWorldSpace = cf.Position
	end
end

local function apply(target)
	for name, goal in pairs(target) do
		local j = J[name]
		if j then
			j.C0 = j.C0:Lerp(goal, alpha)
		end
	end
	followHead()
end

local function attack()
	if not alive then
		return
	end
	task.spawn(play, SWING_ID, 2, false)
	if attackPose then
		return
	end
	local frames = heavy and ATTACKS.heavy or ATTACKS.light
	attackPose = frames[1]
	task.spawn(function()
		for i, frame in ipairs(frames) do
			if not alive then
				return
			end
			attackPose = frame
			task.wait(frame.hold)
			if i == #frames then
				attackPose = nil
			end
		end
	end)
end

local function handler(mode, state)
	local p = POSES[mode][state]
	return function()
		if not alive then
			return
		end
		local now = os.clock()
		alpha = min((now - lastTick) * 10, 1)
		lastTick, sine = now, now
		if p.always or not attackPose then
			fd.setWalkSpeed(p.walk)
			fd.setJumpPower(p.jump)
		end
		local a = attackPose
		if a then
			if a.walk then
				fd.setWalkSpeed(a.walk)
			end
			apply(a.joints)
		else
			apply(p.pose(sine))
		end
	end
end

for _, mode in ipairs({ "default", "r", "e", "q" }) do
	local isHeavy = POSES[mode].heavy
	fd.addmode(mode, {
		modeEntered = function()
			heavy = isHeavy
		end,
		idle = handler(mode, "idle"),
		walk = handler(mode, "walk"),
		jump = handler(mode, "jump"),
		fall = handler(mode, "fall"),
	})
end

local function stop()
	if not alive then
		return
	end
	alive = false
	attackPose = nil
	for _, c in ipairs(conns) do
		pcall(function()
			c:Disconnect()
		end)
	end
	table.clear(conns)
	for s in pairs(sounds) do
		pcall(function()
			s:Destroy()
		end)
	end
	table.clear(sounds)
	for _, inst in ipairs(made) do
		pcall(function()
			inst:Destroy()
		end)
	end
	table.clear(made)
	for name, c0 in pairs(REST) do
		pcall(function()
			J[name].C0 = c0
		end)
	end
	if genv.AtsukoBanHammer and genv.AtsukoBanHammer.stop == stop then
		genv.AtsukoBanHammer = nil
	end
end

conns[#conns + 1] = UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		attack()
	end
end)

conns[#conns + 1] = RunService.Heartbeat:Connect(function()
	if alive and not reanimOn() then
		stop()
	end
end)

genv.AtsukoBanHammer = {
	poses = POSES,
	attacks = ATTACKS,
	attack = attack,
	stop = stop,
	onHub = onHub,
	joints = J,
	isHeavy = function()
		return heavy
	end,
	attacking = function()
		return attackPose
	end,
	alive = function()
		return alive
	end,
}

do
	local h = genv.AtsukoHub
	if type(h) == "table" and type(h.OnStop) == "function" then
		h.OnStop(function()
			stop()
			pcall(function()
				if rig and rig.stopreanimate then
					rig.stopreanimate()
				end
			end)
		end)
	end
end

task.spawn(play, MUSIC_ID, 9999999, true)

local function holding()
	return J.Hammer ~= nil and type(hammer) == "table" and rawget(hammer, "p") ~= nil
end
task.spawn(function()
	local deadline = os.clock() + 3
	while alive and not holding() and os.clock() < deadline do
		task.wait(0.1)
	end
	if not alive then
		return
	end
	if holding() then
		say("Click to swing. R, E and Q change the mode", "ok", 4)
	else
		say("Wear the Ban Hammer (catalog " .. HAT_ID .. ") to hold it. Click to swing, R, E and Q change the mode", "warn", 6)
	end
end)
