local Pack = {}

function Pack.init(ctx)
	local kit, Cmd, Kit, LP = ctx.kit, ctx.Cmd, ctx.Kit, ctx.LP
	local RunService = game:GetService("RunService")

	local function camera()
		return workspace.CurrentCamera
	end

	kit.define("camdistance", {
		run = function(arg)
			local n = kit.number(arg, nil, 0.5, 400)
			if not n then
				return false, "Give a distance, like 20"
			end
			LP.CameraMode = Enum.CameraMode.Classic
			LP.CameraMinZoomDistance = n
			LP.CameraMaxZoomDistance = math.max(n, 0.5)
			return true, "The camera sits " .. Kit.formatNumber(n) .. " studs away"
		end,
	})

	kit.define("minzoom", {
		run = function(arg)
			local n = kit.number(arg, nil, 0, 400)
			if not n then
				return false, "Give a distance, like 0.5"
			end
			LP.CameraMinZoomDistance = n
			if LP.CameraMaxZoomDistance < n then
				LP.CameraMaxZoomDistance = n
			end
			return true, "You can zoom in to " .. Kit.formatNumber(n) .. " studs"
		end,
	})

	kit.define("camoffset", {
		run = function(arg)
			local n = kit.numbers(arg, 3)
			if not n then
				return false, "Give x y z, like camoffset 2 0 0, or camoffset 0 0 0 to undo"
			end
			local h = kit.hum()
			if not h then
				return false, "No character right now"
			end
			h.CameraOffset = Vector3.new(Kit.clamp(n[1], -50, 50), Kit.clamp(n[2], -50, 50), Kit.clamp(n[3], -50, 50))
			return true, "Camera offset changed"
		end,
	})

	kit.define("firstperson", {
		run = function()
			LP.CameraMode = Enum.CameraMode.LockFirstPerson
			return true, "First person"
		end,
	})

	kit.define("thirdperson", {
		run = function()
			LP.CameraMode = Enum.CameraMode.Classic
			if LP.CameraMaxZoomDistance < 12 then
				LP.CameraMaxZoomDistance = 128
			end
			if LP.CameraMinZoomDistance > 0.5 then
				LP.CameraMinZoomDistance = 0.5
			end
			return true, "Third person"
		end,
	})

	do
		local before
		kit.define("inviscam", {
			start = function()
				before = LP.DevCameraOcclusionMode
				LP.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam
				return true
			end,
			stop = function()
				LP.DevCameraOcclusionMode = before or Enum.DevCameraOcclusionMode.Zoom
				before = nil
			end,
		})
	end

	do
		local power = 0.4
		local name = "AtsukoCameraShake"
		kit.define("shake", {
			usage = "shake [power]",
			start = function(arg)
				power = kit.number(arg, 0.4, 0.05, 3)
				RunService:BindToRenderStep(name, Enum.RenderPriority.Camera.Value + 1, function()
					local cam = camera()
					if cam then
						local a = (math.random() - 0.5) * power * 0.1
						local b = (math.random() - 0.5) * power * 0.1
						cam.CFrame = cam.CFrame * CFrame.Angles(a, b, 0)
					end
				end)
				kit.bind("shake", {
					Disconnect = function()
						pcall(function()
							RunService:UnbindFromRenderStep(name)
						end)
					end,
				})
				return true
			end,
			update = function(arg)
				power = kit.number(arg, 0.4, 0.05, 3)
			end,
			stop = function() end,
		})
	end

	kit.define("gotocam", {
		run = function()
			local r, cam = kit.root(), camera()
			if not (r and cam) then
				return false, "No character right now"
			end
			r.CFrame = CFrame.new(cam.CFrame.Position)
			return true, "You are where the camera was"
		end,
	})

	kit.define("viewpart", {
		run = function(arg)
			local name = string.match(tostring(arg or ""), "^%s*(.-)%s*$")
			if name == "" then
				return false, "Say the name of the part"
			end
			local hit
			for _, inst in ipairs(workspace:GetDescendants()) do
				if inst.Name == name and inst:IsA("BasePart") then
					hit = inst
					break
				end
			end
			local cam = camera()
			if not (hit and cam) then
				return false, "No part has that name"
			end
			cam.CameraSubject = hit
			return true, "Looking at " .. name .. ". fixcam brings the camera back"
		end,
	})
end

return Pack
