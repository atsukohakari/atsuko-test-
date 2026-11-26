local genv = (typeof(getgenv) == "function" and getgenv()) or _G

local function hubRead(path)
	local base = type(genv.AtsukoHubRaw) == "string" and genv.AtsukoHubRaw or "https://raw.githubusercontent.com/atsukohakari/atsuko-test-/main/"
	local ok, src = pcall(function()
		if type(genv.AtsukoHubRead) == "function" then
			local got = genv.AtsukoHubRead(path)
			if got or genv.AtsukoHubLocal then
				return got
			end
		end
		return game:HttpGet(base .. path)
	end)
	return ok and type(src) == "string" and src or nil
end

local Kit = genv.AtsukoMoveset
if type(Kit) ~= "table" or (tonumber(Kit.version) or 0) < 1 then
	local src = hubRead("Hub/Moveset.lua")
	local fn = src and loadstring(src, "=Moveset")
	local ok, got = false, nil
	if fn then
		ok, got = pcall(fn)
	end
	Kit = ok and type(got) == "table" and got or nil
end

local Uhh = { version = 1, Kit = Kit }

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local V3, CF = Vector3.new, CFrame.new
local CFI = CFrame.identity
local ZERO = Vector3.zero
local XZ = V3(1, 0, 1)

local KNOWN = {
	{
		MeshId = "17269814619", TextureId = "",
		C0 = CFrame.new(-0.15, 0, 0),
		C1 = CFrame.new(-2.2, 2, -1.5) * CFrame.Angles(0, math.rad(90), 0),
		Limb = "Torso", Group = "LeftWing"
	},
	{
		MeshId = "17269824947", TextureId = "",
		C0 = CFrame.new(0.15, 0, 0),
		C1 = CFrame.new(-2.2, 2, 1.5) * CFrame.Angles(0, math.rad(90), 0),
		Limb = "Torso", Group = "RightWing"
	},
	{
		MeshId = "17326555172", TextureId = "",
		C0 = CFrame.new(0, 0, 0.6) * CFrame.Angles(0, 0, math.rad(115)) * CFrame.Angles(0, math.rad(90), 0) * CFrame.new(0, -2, 0),
		C1 = CFrame.new(-0.0023765564, 5.41595364, 9.20755196, -1, 0, 0, 0, -0.519688249, -0.85435611, 0, -0.854355931, 0.519688308),
		Limb = "Torso", Group = "Sword",
		Attachments = {
			SwordAttachment = CFrame.new(-0.00199868693, -2.37924528, -3.60738397, -1, 8.74227766e-08, 0, -4.54321416e-08, -0.519683123, -0.85435909, -7.46904405e-08, -0.85435909, 0.519683123),
		}
	},
	{
		MeshId = "17326476901", TextureId = "",
		C0 = CFrame.new(0, 0, 0.6) * CFrame.Angles(0, 0, math.rad(115)) * CFrame.Angles(0, math.rad(90), 0) * CFrame.new(0, -2, 0),
		C1 = CFrame.new(-0.00237464905, 1.96199441, 2.19341898, -1, 0, 0, 0, -0.519688249, -0.85435611, 0, -0.854355931, 0.519688308),
		Limb = "Torso", Group = "Sword"
	},
	{
		MeshId = "77229698901212", TextureId = "",
		C0 = CFrame.new(-1.20000005, -0.5, -0.5, 1, 2.29397301e-09, 2.62201709e-08, 2.62201709e-08, -0.173648342, -0.98480773, 2.29397301e-09, 0.98480773, -0.173648342),
		C1 = CFrame.new(-4.80999994, -1.22500002, 0, -4.37113883e-08, 1, 4.37113883e-08, -0, -4.37113883e-08, 1, 1, 4.37113883e-08, 1.91068547e-15),
		Limb = "Torso", Group = "Gun",
		Attachments = {
			GunAttachment = CFrame.new(2.29999971, 0.0999908447, 0, -4.37114878e-08, 1, 2.18948799e-06, 1.39334895e-14, -2.18948799e-06, 1, 1, 4.37114878e-08, 8.17722897e-14),
		}
	},
	{
		MeshId = "76443789550926", TextureId = "",
		C0 = CFrame.new(-1.20000005, -0.5, -0.5, 1, 2.29397301e-09, 2.62201709e-08, 2.62201709e-08, -0.173648342, -0.98480773, 2.29397301e-09, 0.98480773, -0.173648342),
		C1 = CFrame.new(0.5, -1, 0, -4.37113883e-08, 1, 4.37113883e-08, -0, -4.37113883e-08, 1, 1, 4.37113883e-08, 1.91068547e-15),
		Limb = "Torso", Group = "Gun"
	},
	{
		MeshId = "4315410540", TextureId = "",
		C0 = CFrame.new(0, 0, 0.6) * CFrame.Angles(0, 0, math.rad(-160)) * CFrame.Angles(0, math.rad(90), 0) * CFrame.new(0, -3, 0),
		C1 = CFrame.new(2, 2, 0, 0, -0.707106769, 0.707106769, 0, -0.707106769, -0.707106769, 1, 0, 0),
		Limb = "Torso", Group = "Sword",
		Attachments = {
			SwordAttachment = CFrame.new(-2.44241333, -2.44241714, 0, 0, -0.707105994, 0.707107544, 0, -0.707107544, -0.707105994, 1, 0, 0),
		}
	},
	{
		MeshId = "5254583415", TextureId = "",
		C0 = CFrame.new(0, 0, 0.6) * CFrame.Angles(0, 0, math.rad(135)) * CFrame.Angles(0, math.rad(90), 0) * CFrame.new(0, -4, 0),
		C1 = CFrame.new(0, 2.5711503, -3.06417799, 1, 0, 0, 0, -0.642787635, -0.766044438, 0, 0.766044438, -0.642787635),
		Limb = "Torso", Group = "Sword",
		Attachments = {
			SwordAttachment = CFrame.new(0, -3.14966202, 3.75361824, 1, 0, 0, 0, -0.642789066, -0.766043246, 0, 0.766043246, -0.642789066),
		}
	},
	{
		MeshId = "5278721954", TextureId = "",
		C0 = CFrame.new(0, 0, 0.6) * CFrame.Angles(0, 0, math.rad(135)) * CFrame.Angles(0, math.rad(90), 0) * CFrame.new(0, -4, 0),
		C1 = CFrame.new(0, 2.5711503, -3.06417799, 1, 0, 0, 0, -0.642787635, -0.766044438, 0, 0.766044438, -0.642787635),
		Limb = "Torso", Group = "Sword",
		Attachments = {
			SwordAttachment = CFrame.new(0, -3.14966202, 3.75361824, 1, 0, 0, 0, -0.642789066, -0.766043246, 0, 0.766043246, -0.642789066),
		}
	},
	{
		MeshId = "12798770968", TextureId = "",
		C0 = CFrame.new(0, 0, 0.6) * CFrame.Angles(0, 0, math.rad(-135)) * CFrame.Angles(0, math.rad(90), 0) * CFrame.new(0, -3, 0),
		C1 = CFrame.new(0, 0, 2.8, -1, 0, 0, -0, 0, -1, 0, -1, 0),
		Limb = "Torso", Group = "Sword",
		Attachments = {
			SwordAttachment = CFrame.new(0, -0.600002289, -3.50000024, -1, -1.50995589e-07, 5.1107946e-13, 3.55270555e-14, -3.62001674e-06, -1, 1.50995589e-07, -1, 3.62001674e-06),
		}
	},
	{
		MeshId = "15188973493", TextureId = "",
		C0 = CFrame.new(-1.2, -0.5, -0.8, 1, 0, 0, 0, -0.342020363, -0.939692557, 0, 0.939692557, -0.342020363),
		C1 = CFrame.new(0, 0.1, -1.5, 1, 0, 0, 0, -0.173648342, -0.98480773, 0, 0.98480773, -0.173648342),
		Limb = "Torso", Group = "Sword",
		Attachments = {
			SwordAttachment = CFrame.new(0, -0.445755005, 1.95225215, 1, 0, 0, 0, -0.173646465, -0.984808147, 0, 0.984808147, -0.173646465),
		}
	},
	{
		MeshId = "7547179386", TextureId = "",
		C0 = CFrame.new(0, 0, 0.6) * CFrame.Angles(0, 0, math.rad(-135)) * CFrame.Angles(0, math.rad(90), 0) * CFrame.new(0, -2, 0),
		C1 = CFrame.new(1.2, 1.6, 0, 0.0560226142, -0.64034164, 0.766044438, 0.0667650923, -0.763129413, -0.642787635, 0.99619472, 0.0871556699, 0),
		Limb = "Torso", Group = "Sword",
		Attachments = {
			SwordAttachment = CFrame.new(-1.85699463, -2.21307373, 0.252754211, 0.0560226217, -0.640343368, 0.766043067, 0.0667650998, -0.763128042, -0.642789364, 0.99619472, 0.0871556848, 1.56462193e-07),
		}
	},
	{
		MeshId = "6309353955", TextureId = "",
		C0 = CFrame.new(1.2, -0.5, -2, 1, 0, 0, 0, -0.342020363, -0.939692557, 0, 0.939692557, -0.342020363),
		C1 = CFrame.new(3, 1.89999998, 0, -8.1469814e-08, -0.829037607, -0.559192836, -8.44357686e-08, -0.559192836, 0.829037607, -1, 1.1475742e-07, -2.44430947e-08),
		Limb = "Torso", Group = "Sword",
		Attachments = {
			SwordAttachment = CFrame.new(-2.20946121, -1.73155212, 0, -8.1470084e-08, -0.829036415, -0.559194624, -8.44359747e-08, -0.559194624, 0.829036415, -1, 1.1475781e-07, -2.4442862e-08),
		}
	},
	{
		MeshId = "6410486978", TextureId = "",
		C0 = CFrame.new(-1.2, -0.5, -2, 1, 0, 0, 0, -0.342020363, -0.939692557, 0, 0.939692557, -0.342020363),
		C1 = CFrame.new(3, 1.89999998, 0, -8.1469814e-08, -0.829037607, -0.559192836, -8.44357686e-08, -0.559192836, 0.829037607, -1, 1.1475742e-07, -2.44430947e-08),
		Limb = "Torso", Group = "Sword",
		Attachments = {
			SwordAttachment = CFrame.new(-2.20946121, -1.73155212, 0, -8.1470084e-08, -0.829036415, -0.559194624, -8.44359747e-08, -0.559194624, 0.829036415, -1, 1.1475781e-07, -2.4442862e-08),
		}
	},
	{
		MeshId = "72666399517938", TextureId = "",
		C0 = CFrame.new(0, 0, 0.6) * CFrame.Angles(0, 0, math.rad(160)) * CFrame.Angles(0, math.rad(90), 0) * CFrame.new(0, -2, 0),
		C1 = CFrame.new(0, 7.62939e-06, 3.5, 0, 0, -1, 1, 0, 0, 0, -1, 0),
		Limb = "Torso", Group = "Sword",
		Attachments = {
			SwordAttachment = CFrame.new(0, 0, -4.75, 0, 0, -1, 1, 0, 0, 0, -1, 0),
		}
	},
	{
		MeshId = "6410486686", TextureId = "",
		C0 = CFrame.new(-1.2, -0.5, -2, 1, 0, 0, 0, -0.342020363, -0.939692557, 0, 0.939692557, -0.342020363),
		C1 = CFrame.new(3, 1.89999998, 0, -8.1469814e-08, -0.829037607, -0.559192836, -8.44357686e-08, -0.559192836, 0.829037607, -1, 1.1475742e-07, -2.44430947e-08),
		Limb = "Torso", Group = "Sword",
		Attachments = {
			SwordAttachment = CFrame.new(-2.20946121, -1.73155212, 0, -8.1470084e-08, -0.829036415, -0.559194624, -8.44359747e-08, -0.559194624, 0.829036415, -1, 1.1475781e-07, -2.4442862e-08),
		}
	},
	{
		MeshId = "119971563288138", TextureId = "",
		C0 = CFrame.new(0, 0, 0.6) * CFrame.Angles(0, 0, math.rad(160)) * CFrame.Angles(0, math.rad(90), 0) * CFrame.new(0, -4, 0),
		C1 = CFrame.new(3.06418, 2.57115, -7.62939e-06, 0, -0.766044, 0.642788, 0, -0.642788, -0.766044, 1, 0, 0),
		Limb = "Torso", Group = "Sword",
		Attachments = {
			SwordAttachment = CFrame.new(-4.02173, -3.37464, 0, 0, -0.766044, 0.642788, 0, -0.642788, -0.766044, 1, 0, 0),
		}
	},
	{
		MeshId = "14774841896", TextureId = "",
		C0 = CFrame.new(1.20208192, -1.20208192, 0.55, 0, -0.707107008, -0.707107008, 0, 0.707107008, -0.707107008, 1, 0, 0),
		C1 = CFrame.new(0, -1.7, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0),
		Limb = "Torso", Group = "Sword",
		Attachments = {
			SwordAttachment = CFrame.new(0, 2.19592, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0),
		}
	},
	{
		MeshId = "11146163759", TextureId = "",
		C0 = CFrame.new(0.89952, 1.57356, 0.5, 0, -0.5, -0.866025, 0, -0.866025, 0.5, -1, 0, 0),
		C1 = CFrame.new(1.77452, 1.57356, 0, 0, -0.5, -0.866025, 0, -0.866025, 0.5, -1, 0, 0),
		Limb = "Torso", Group = "Sword",
		Attachments = {
			SwordAttachment = CFrame.new(-2.73025, -2.97893, 0, 0, -0.5, -0.866025, 0, -0.866025, 0.5, -1, 0, 0),
		}
	},
	{
		MeshId = "74355154044660", TextureId = "",
		C0 = CFrame.new(-1, -0.581861, -1.99411, 1, 0, 0, 0, -0.258819, -0.965926, 0, 0.965926, -0.258819),
		C1 = CFrame.new(0, 0.793139, -1.99411, 1, 0, 0, 0, -0.258819, -0.965926, 0, 0.965926, -0.258819),
		Limb = "Torso", Group = "Sword",
		Attachments = {
			SwordAttachment = CFrame.new(0, -0.349528, 2.75336, 1, 0, 0, 0, -0.258819, -0.965926, 0, 0.965926, -0.258819),
		}
	},
	{
		MeshId = "109821286447824", TextureId = "",
		C0 = CFrame.new(-0.883884, 0.883884, 0.5, 0, 0.707107, 0.707107, 0, -0.707107, 0.707107, 1, 0, 0),
		C1 = CFrame.new(-0.883884, 0.883884, 0, 0, 0.707107, 0.707107, 0, -0.707107, 0.707107, 1, 0, 0),
		Limb = "Torso", Group = "Sword",
		Attachments = {
			SwordAttachment = CFrame.new(0, -0.349528, 2.75336, 1, 0, 0, 0, -0.258819, -0.965926, 0, 0.965926, -0.258819),
		}
	},
	{
		MeshId = "133701648178658", TextureId = "",
		C0 = CFrame.new(-0.883884, 0.883884, 0.5, 0, 0.707107, 0.707107, 0, -0.707107, 0.707107, 1, 0, 0),
		C1 = CFrame.new(-0.883884, 0.883884, 0, 0, 0.707107, 0.707107, 0, -0.707107, 0.707107, 1, 0, 0),
		Limb = "Torso", Group = "Sword",
		Attachments = {
			SwordAttachment = CFrame.new(0, -0.349528, 2.75336, 1, 0, 0, 0, -0.258819, -0.965926, 0, 0.965926, -0.258819),
		}
	},
	{
		MeshId = "76880052752134", TextureId = "",
		C0 = CFrame.new(-0.475349, 1.50762, 0.5, 0.0262082, 0.299562, -0.953717, -0.0831219, -0.950088, -0.300706, -0.996195, 0.0871557, 0),
		C1 = CFrame.new(-0.475349, 1.50762, -0.1383, 0.0262082, 0.299562, -0.953717, -0.0831219, -0.950088, -0.300706, -0.996195, 0.0871557, 0),
		Limb = "Torso", Group = "Sword",
		Attachments = {
			SwordAttachment = CFrame.new(0.93079, -2.35394, 0.220899, 0.0262081, 0.299562, -0.953717, -0.083122, -0.950088, -0.300707, -0.996195, 0.0871558, 0),
		}
	},
	{
		MeshId = "14525254277", TextureId = "",
		C0 = CFrame.new(-1.41421, 1.41421, 0.55, 0, 0.707107, 0.707107, 0, -0.707107, 0.707107, 1, 0, 0),
		C1 = CFrame.new(-1.41421, 1.41421, 0, 0, 0.707107, 0.707107, 0, -0.707107, 0.707107, 1, 0, 0),
		Limb = "Torso", Group = "Sword",
		Attachments = {
			SwordAttachment = CFrame.new(1.89036, -1.89036, 0, 0, 0.707107, 0.707107, 0, -0.707107, 0.707107, 1, 0, 0),
		}
	},
	{
		MeshId = "4615369575", TextureId = "",
		C0 = CFrame.new(-1.2, -0.5, -0.8, 1, 0, 0, 0, -0.342020363, -0.939692557, 0, 0.939692557, -0.342020363),
		C1 = CFrame.new(-1.2, 0.5, 0, 0, 0.707106769, 0.707106829, 0, -0.707106829, 0.707106769, 1, 0, 0),
		Limb = "Torso", Group = "Gun",
		Attachments = {
			GunAttachment = CFrame.new(1.98886108, -1.84744835, 0, 0, 0.707105279, 0.707108319, 0, -0.707108319, 0.707105279, 1, 0, 0),
		}
	},
	{
		MeshId = "17364671821", TextureId = "",
		C0 = CFrame.new(0, 0, 0.6) * CFrame.Angles(0, 0, math.rad(-60)) * CFrame.Angles(0, math.rad(90), 0) * CFrame.new(0, -2, 0),
		C1 = CFrame.new(0, 0.4, 1.7, -1, 0, 0, 0, 0, -1, 0, -1, 0),
		Limb = "Torso", Group = "Gun",
		Attachments = {
			GunAttachment = CFrame.new(0, 0.200004578, -2.09999967, -1, -1.50995902e-07, -3.03469733e-13, -1.39334811e-14, 2.10206508e-06, -1, 1.50995902e-07, -1, -2.10206508e-06),
		}
	},
	{
		MeshId = "17174159690", TextureId = "",
		C0 = CFrame.new(0, 0, 0.6) * CFrame.Angles(0, 0, math.rad(-60)) * CFrame.Angles(0, math.rad(90), 0) * CFrame.new(0, -2, 0),
		C1 = CFrame.new(0, 0.4, 1.7, -1, 0, 0, 0, 0, -1, 0, -1, 0),
		Limb = "Torso", Group = "Gun",
		Attachments = {
			GunAttachment = CFrame.new(0, 0.200004578, -2.09999967, -1, -1.50995902e-07, -3.03469733e-13, -1.39334811e-14, 2.10206508e-06, -1, 1.50995902e-07, -1, -2.10206508e-06),
		}
	},
	{
		MeshId = "6774736084", TextureId = "",
		C0 = CFrame.new(0, 0, 0.6) * CFrame.Angles(0, 0, math.rad(-60)) * CFrame.Angles(0, math.rad(90), 0) * CFrame.new(0, -2, 0),
		C1 = CFrame.new(0, 0.4, 1.7, -1, 0, 0, 0, 0, -1, 0, -1, 0),
		Limb = "Torso", Group = "Gun",
		Attachments = {
			GunAttachment = CFrame.new(0, -0.1, -2.5, -1, -1.50995902e-07, -3.03469733e-13, -1.39334811e-14, 2.10206508e-06, -1, 1.50995902e-07, -1, -2.10206508e-06),
		}
	},
	{
		MeshId = "14847654884", TextureId = "",
		C0 = CFrame.new(-1, -0.699999988, 0.600000024, -4.37113883e-08, 0.939692676, 0.342020035, 0, 0.342020035, -0.939692676, -1, -4.10752712e-08, -1.49501709e-08),
		C1 = CFrame.new(-1.29999995, -0.300000012, 0, -4.37113883e-08, 1, -4.37113883e-08, -0, -4.37113883e-08, -1, -1, -4.37113883e-08, 1.91068547e-15) * CFrame.Angles(0, math.pi, 0),
		Limb = "Torso", Group = "Gun",
		Attachments = {
			GunAttachment = CFrame.new(2.70000005, 0.400001526, 0, -4.37113883e-08, 1, -4.37113883e-08, -0, -4.37113883e-08, -1, -1, -4.37113883e-08, 1.91068547e-15),
		}
	},
	{
		MeshId = "15033232117", TextureId = "",
		C0 = CFrame.new(0, 0, 0.6) * CFrame.Angles(0, 0, math.rad(10)) * CFrame.Angles(0, math.rad(90), 0) * CFrame.new(0, -1, 0),
		C1 = CFrame.new(0, 0, -1, 1, 0, 0, 0, 0, -1, 0, 1, 0) * CFrame.Angles(0, math.pi, 0),
		Limb = "Torso", Group = "Gun",
		Attachments = {
			GunAttachment = CFrame.new(0, 0.5, 2.2, 1, 0, 0, 0, 0, -1, 0, 1, 0),
		}
	},
	{
		MeshId = "5548423017", TextureId = "",
		C0 = CFrame.new(0, 0, 0.6) * CFrame.Angles(0, 0, math.rad(140)) * CFrame.Angles(0, math.rad(90), 0) * CFrame.new(0, -1, 0),
		C1 = CFrame.new(0.795753, 1.12828, 0, 0, -0.5, -0.866025, 0, -0.866025, 0.5, -1, 0, 0),
		Limb = "Torso", Group = "Gun",
		Attachments = {
			GunAttachment = CFrame.new(-1.83702, -1.68181, 0, 0, -0.5, -0.866025, 0, -0.866025, 0.5, -1, 0, 0),
		}
	},
	{
		MeshId = "15172160708", TextureId = "",
		C0 = CFrame.new(0, 0, 0.6) * CFrame.Angles(0, 0, math.rad(-135)) * CFrame.Angles(0, math.rad(90), 0) * CFrame.new(0, -1, 0),
		C1 = CFrame.new(1.7586, 1.47563, -0.658649, -0.642788, -0.754406, 0.133022, 0.766044, -0.633022, 0.111619, 0, 0.173648, 0.984808),
		Limb = "Torso", Group = "Gun",
		Attachments = {
			GunAttachment = CFrame.new(-1.62243, -1.1982, 0.101089, -0.642788, -0.754406, 0.133022, 0.766044, -0.633022, 0.111619, 0, 0.173648, 0.984808),
		}
	},
	{
		MeshId = "105473254683766", TextureId = "",
		C0 = CFrame.new(0, 0, 0.6) * CFrame.Angles(0, 0, math.rad(-135)) * CFrame.Angles(0, math.rad(90), 0) * CFrame.new(0, -1, 0),
		C1 = CFrame.new(0.849705, -0.429243, 7.62939e-06, 0, -0.766044, -0.642788, 0, -0.642788, 0.766044, -1, 0, 0),
		Limb = "Torso", Group = "Gun",
		Attachments = {
			GunAttachment = CFrame.new(-1.80395, -1.35052, 0, 0, -0.766044, -0.642788, 0, -0.642788, 0.766044, -1, 0, 0),
		}
	},
	{
		MeshId = "17550839817", TextureId = "",
		C0 = CFrame.new(0, 0, 1) * CFrame.Angles(0, 0, math.rad(45)) * CFrame.Angles(0, math.rad(90), 0) * CFrame.new(0, -1, -1),
		C1 = CFrame.new(-1.02899, 0.127609, 0, 0, 0.5, 0.866025, 0, -0.866025, 0.5, 1, 0, 0),
		Limb = "Torso", Group = "Gun",
		Attachments = {
			GunAttachment = CFrame.new(1.76228, -2.30232, 0, 0, 0.5, 0.866026, 0, -0.866026, 0.5, 1, 0, 0),
		}
	},
	{
		MeshId = "15489673737", TextureId = "",
		C0 = CFrame.new(0, 0, 0.6) * CFrame.Angles(0, 0, math.rad(50)) * CFrame.Angles(0, math.rad(90), 0) * CFrame.new(0, -1, -0.8),
		C1 = CFrame.new(-0.75, -0.5, 0, 0, 1, 0, 0, 0, 1, 1, 0, 0),
		Limb = "Torso", Group = "Gun",
		Attachments = {
			GunAttachment = CFrame.new(2.5, 0.5, 0, 0, 1, 0, 0, 0, 1, 1, 0, 0),
		}
	},
	{
		MeshId = "123846958006279", TextureId = "",
		C0 = CFrame.new(0, 0, 0.4) * CFrame.Angles(0, 0, math.rad(40)) * CFrame.Angles(0, math.rad(90), 0) * CFrame.new(0, -1, -0.8),
		C1 = CFrame.new(-0.404778, -0.695232, 0, 0, 1, 0, 0, 0, 1, 1, 0, 0),
		Limb = "Torso", Group = "Gun",
		Attachments = {
			GunAttachment = CFrame.new(3.13571, 0.22408, 0, 0, 1, 0, 0, 0, 1, 1, 0, 0),
		}
	},
	{
		MeshId = "7203730183", TextureId = "",
		C0 = CFrame.new(-0.560375, -0.0214996, 1, 0, -0.766044, 0.642788, 0, 0.642788, 0.766044, -1, 0, 0),
		C1 = CFrame.new(-0.560375, -0.0214996, 0, 0, -0.766044, 0.642788, 0, 0.642788, 0.766044, -1, 0, 0),
		Limb = "Torso", Group = "Gun",
		Attachments = {
			GunAttachment = CFrame.new(-1.54091, 2.19454, 0, 0, -0.766044, 0.642788, 0, 0.642788, 0.766044, -1, 0, 0),
		}
	},
	{
		MeshId = "89681297163766", TextureId = "",
		C0 = CFrame.new(0, 0, 0.5) * CFrame.Angles(0, 0, math.rad(50)) * CFrame.Angles(0, math.rad(90), 0) * CFrame.new(0, 1, 0),
		C1 = CFrame.new(-0.75, 0, 0.375, 0, -1, 0, -1, 0, 0, 0, 0, -1),
		Limb = "Torso", Group = "Gun",
		Attachments = {
			GunAttachment = CFrame.new(-2.2117, 0, -0.08, 0, -1, 0, -1, 0, 0, 0, 0, -1),
		}
	},
	{
		MeshId = "77214452514875", TextureId = "",
		C0 = CFrame.new(0, 0, 0.5) * CFrame.Angles(0, 0, math.rad(50)) * CFrame.Angles(0, math.rad(90), 0) * CFrame.new(0, -1, 0),
		C1 = CFrame.new(-1, -1, 0, 0, -1, 0, 0, 0, 1, -1, 0, 0),
		Limb = "Torso", Group = "Gun",
		Attachments = {
			GunAttachment = CFrame.new(-7, 0.75, -0.08, 0, -1, 0, 0, 0, 1, -1, 0, 0),
		}
	},
	{
		MeshId = "14890477660", TextureId = "",
		C0 = CFrame.new(1.06066, 0.530329, 0.5, 0, 0.707107, -0.707107, 0, 0.707107, 0.707107, 1, 0, 0),
		C1 = CFrame.new(1.06066, 0.530329, 0, 0, 0.707107, -0.707107, 0, 0.707107, 0.707107, 1, 0, 0),
		Limb = "Torso", Group = "Gun",
		Attachments = {
			GunAttachment = CFrame.new(1.32582, 1.5026, 0, 0, 0.707107, -0.707107, 0, 0.707107, 0.707107, 1, 0, 0),
		}
	},
	{
		MeshId = "89921454026819", TextureId = "",
		C0 = CFrame.new(0, 0, 0.5) * CFrame.Angles(0, 0, math.rad(50)) * CFrame.Angles(0, math.rad(90), 0) * CFrame.new(0, 1, 0),
		C1 = CFrame.new(0.375, 0, 0.75, 0, 0, -1, -1, 0, 0, 0, 1, 0),
		Limb = "Torso", Group = "Gun",
		Attachments = {
			GunAttachment = CFrame.new(-0.0799999, 0, 2.2117, 0, 0, -1, -1, 0, 0, 0, 1, 0),
		}
	},
	{
		MeshId = "10703925099", TextureId = "",
		C0 = CFrame.new(0, 1, 0, 1, 0, 0, 0, -1, 0, 0, 0, -1),
		C1 = CFrame.new(0, 0.5, 0, 1, 0, 0, 0, -1, 0, 0, 0, -1),
		Limb = "Torso", Group = "Gun",
		Attachments = {
			GunAttachment = CFrame.new(0, -0.5, -0.52, 1, 0, 0, 0, -1, 0, 0, 0, -1),
		}
	},
	{
		MeshId = "6449532798", TextureId = "",
		C0 = CFrame.new(0, 0, 0.6) * CFrame.Angles(0, 0, math.rad(40)) * CFrame.Angles(0, math.rad(90), 0) * CFrame.new(0, -1, 0),
		C1 = CFrame.new(0, -1.375, -7.62939e-06, 0, 0, -1, 0, 1, 0, 1, 0, 0),
		Limb = "Torso", Group = "Gun",
		Attachments = {
			GunAttachment = CFrame.new(-0.375, 1.375, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0),
		}
	},
	{
		MeshId = "3729241578", TextureId = "",
		C0 = CFrame.new(-1.1, -0.5, 0, 1, 0, 0, 0, -1, 0, 0, 0, -1),
		C1 = CFrame.new(0, 0.875, 0.125, 1, 0, 0, 0, -1, 0, 0, 0, -1),
		Limb = "Torso", Group = "Gun",
		Attachments = {
			GunAttachment = CFrame.new(0, -0.875, -0.25, 1, 0, 0, 0, -1, 0, 0, 0, -1),
		}
	},
	{
		MeshId = "18894853727", TextureId = "",
		C0 = CFrame.new(1.1, -0.5, 0, 1, 0, 0, 0, -1, 0, 0, 0, -1),
		C1 = CFrame.new(0, 0.525084, -0.375, -1, 0, 0, 0, -1, 0, 0, 0, 1),
		Limb = "Torso", Group = "Gun",
		Attachments = {
			GunAttachment = CFrame.new(0, -0.75, 0.125, -1, 0, 0, 0, -1, 0, 0, 0, 1),
		}
	},
	{
		MeshId = "4307568890", TextureId = "",
		C0 = CFrame.new(0, 1.2, 0) * CFrame.Angles(0, math.pi, 0),
		C1 = CFrame.identity,
		Limb = "Left Arm", Group = "Bullet"
	},
	{
		MeshId = "128216670", TextureId = "",
		C0 = CFrame.new(2, 2, 0),
		C1 = CFrame.identity,
		Limb = "Torso", Group = "Bullet"
	},
	{
		MeshId = "190770677", TextureId = "",
		C0 = CFrame.new(0, 0.5, 0),
		C1 = CFrame.identity,
		Limb = "Head", Group = "Bullet"
	},
	{
		MeshId = "16755023375", TextureId = "",
		C0 = CFrame.new(0, -24, 0),
		C1 = CFrame.new(0, 0, 0),
		Limb = "HumanoidRootPart", Group = "GunAura"
	},
	{
		MeshId = "94891594182553", TextureId = "",
		C0 = CFrame.new(0, -24, 0),
		C1 = CFrame.new(0, 0, 0),
		Limb = "HumanoidRootPart", Group = "GunAura"
	},
	{
		MeshId = "5486588848", TextureId = "",
		C0 = CFrame.new(-0.15, 0, 0),
		C1 = CFrame.new(-1.75, -1, 0, -1, 0, 0, 0, 1, 0, 0, 0, -1),
		Limb = "Torso", Group = "LeftWing"
	},
	{
		MeshId = "5593756557", TextureId = "",
		C0 = CFrame.new(0.15, 0, 0),
		C1 = CFrame.new(1.75, -1, 0, -1, 0, 0, 0, 1, 0, 0, 0, -1),
		Limb = "Torso", Group = "RightWing"
	},
}

Uhh.KNOWN = KNOWN

Uhh.R6 = {
	{ "RootJoint", "HumanoidRootPart", "Torso", "root", CF(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0), CF(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0) },
	{ "Neck", "Torso", "Head", "neck", CF(0, 1, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0), CF(0, -0.5, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0) },
	{ "Right Shoulder", "Torso", "Right Arm", "rarm", CF(1, 0.5, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), CF(-0.5, 0.5, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0) },
	{ "Left Shoulder", "Torso", "Left Arm", "larm", CF(-1, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0), CF(0.5, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0) },
	{ "Right Hip", "Torso", "Right Leg", "rleg", CF(1, -1, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), CF(0.5, 1, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0) },
	{ "Left Hip", "Torso", "Left Leg", "lleg", CF(-1, -1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0), CF(-0.5, 1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0) },
}
Uhh.SIZES = {
	HumanoidRootPart = V3(2, 2, 1),
	Torso = V3(2, 2, 1),
	Head = V3(2, 1, 1),
	["Right Arm"] = V3(1, 2, 1),
	["Left Arm"] = V3(1, 2, 1),
	["Right Leg"] = V3(1, 2, 1),
	["Left Leg"] = V3(1, 2, 1),
}
Uhh.GROUP_OF_SLOT = { gun = "Gun", sword = "Sword", bullet = "Bullet" }
Uhh.GRIP = { Gun = 0.65, Sword = 0.4 }

function Uhh.RandomString(length)
	length = length or math.random(32, 256)
	local str = ""
	for _ = 1, length do
		str ..= string.char(math.random(32, 126))
	end
	return str
end

function Uhh.digits(v)
	if type(v) ~= "string" then
		v = v ~= nil and tostring(v) or ""
	end
	return string.match(v, "(%d+)%D*$") or ""
end

function Uhh.idMatch(a, b)
	a = a or ""
	b = b or ""
	if #b == 0 then
		return true
	end
	if #a == 0 then
		return false
	end
	return Uhh.digits(a) == b
end

function Uhh.known(mesh, tex)
	for _, data in ipairs(KNOWN) do
		if Uhh.idMatch(mesh, data.MeshId) and Uhh.idMatch(tex, data.TextureId) then
			return data
		end
	end
	return nil
end

function Uhh.signal()
	local s = { list = {} }
	local function connect(_, f)
		local c = { Connected = true, f = f }
		function c.Disconnect()
			c.Connected = false
			local i = table.find(s.list, c)
			if i then
				table.remove(s.list, i)
			end
		end
		c.disconnect = c.Disconnect
		s.list[#s.list + 1] = c
		return c
	end
	s.Connect, s.connect = connect, connect
	function s.Once(_, f)
		local c
		c = connect(nil, function(...)
			c.Disconnect()
			f(...)
		end)
		return c
	end
	function s.Fire(_, ...)
		s.fire(...)
	end
	function s.fire(...)
		for _, c in ipairs(table.clone(s.list)) do
			if c.Connected then
				task.spawn(c.f, ...)
			end
		end
	end
	return s
end

function Uhh.gripC1(size, group)
	local fit, long = Kit.fit(size)
	local d = math.max(long / 2 - (Uhh.GRIP[group] or 0), 0)
	return (CF(0, d, 0) * CFrame.Angles(-math.pi / 2, 0, 0) * fit):Inverse()
end

function Uhh.new(cfg)
	cfg = type(cfg) == "table" and cfg or {}
	local TITLE = tostring(cfg.title or "Moveset")
	if type(Kit) ~= "table" then
		warn("[" .. TITLE .. "] couldn't load Hub/Moveset.lua")
		return nil
	end
	local jobs = cfg.jobs or {}
	local K = Kit.start({ title = TITLE, jobs = jobs, alignHint = cfg.hint, short = cfg.short, talks = false, music = false })
	if not K then
		return nil
	end
	local fd = K.fd
	local LP = Players.LocalPlayer
	local U = { K = K, title = TITLE, records = {} }
	local conns = {}
	local function on(sig, f)
		local ok, c = pcall(function()
			return sig:Connect(f)
		end)
		if ok and c then
			conns[#conns + 1] = c
		end
		return c
	end

	local rootPart = K.part("HumanoidRootPart")
	local function baseCF()
		local c = rootPart and fd.cframes[rootPart]
		return typeof(c) == "CFrame" and c or K.rootCF()
	end

	local model = Instance.new("Model")
	model.Name = "AtsukoFigure"
	local parts = {}
	local start = baseCF()
	for name, size in pairs(Uhh.SIZES) do
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Transparency = 1
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Massless = true
		p.Anchored = true
		p.CFrame = start
		p.Parent = model
		parts[name] = p
	end
	local realHum = Instance.new("Humanoid")
	pcall(function()
		realHum.RigType = Enum.HumanoidRigType.R6
		realHum.RequiresNeck = false
		realHum.BreakJointsOnDeath = false
		realHum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		realHum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
		realHum.EvaluateStateMachine = false
	end)
	realHum.Parent = model
	local animator = Instance.new("Animator")
	animator.Parent = realHum
	local motors = {}
	for _, d in ipairs(Uhh.R6) do
		local m = Instance.new("Motor6D")
		m.Name = d[1]
		m.Part0 = parts[d[2]]
		m.Part1 = parts[d[3]]
		m.C0 = d[5]
		m.C1 = d[6]
		m.Parent = d[1] == "RootJoint" and parts.HumanoidRootPart or parts.Torso
		motors[#motors + 1] = { m = m, p0 = d[2], p1 = d[3], key = d[4] }
	end
	model.PrimaryPart = parts.HumanoidRootPart
	model.Parent = K.fxFolder
	U.model, U.parts, U.humanoid, U.animator = model, parts, realHum, animator

	local world = {}
	U.world = world
	local function solve(base)
		world.HumanoidRootPart = base
		for _, d in ipairs(motors) do
			local m = d.m
			local t = CFI
			pcall(function()
				t = m.Transform
			end)
			d.rel = m.C0 * t * m.C1:Inverse()
			world[d.p1] = world[d.p0] * d.rel
		end
		for name, cf in pairs(world) do
			local p = parts[name]
			if p then
				p.CFrame = cf
			end
		end
	end
	solve(start)

	local ST = Enum.HumanoidStateType
	local st = { state = ST.Running, ground = true, run = nil, dir = ZERO, move = ZERO, extra = ZERO, jump = false, touchJump = false }
	U.state = st
	local sig = { Running = Uhh.signal(), Climbing = Uhh.signal(), StateChanged = Uhh.signal(), Jumping = Uhh.signal(), FreeFalling = Uhh.signal(), Died = Uhh.signal(), Seated = Uhh.signal() }
	local function setState(new)
		if new == nil or new == st.state then
			return
		end
		local old = st.state
		st.state = new
		sig.StateChanged.fire(old, new)
		if new == ST.Jumping then
			sig.Jumping.fire(true)
		elseif new == ST.Freefall then
			sig.FreeFalling.fire(true)
		end
	end

	local F = {}
	local hv = { Name = "Humanoid", ClassName = "Humanoid", WalkSpeed = 16, JumpPower = 50, JumpHeight = 7.2, UseJumpPower = true, AutoRotate = true, PlatformStand = false, Sit = false, EvaluateStateMachine = true, Health = 100, MaxHealth = 100, HipHeight = 0, RigType = Enum.HumanoidRigType.R6 }
	local hm = {}
	function hm.GetState()
		return st.state
	end
	function hm.ChangeState(_, s)
		setState(s)
	end
	function hm.GetMoveVelocity()
		return st.move
	end
	function hm.LoadAnimation(_, anim)
		return animator:LoadAnimation(anim)
	end
	function hm.GetPlayingAnimationTracks()
		local ok, list = pcall(function()
			return animator:GetPlayingAnimationTracks()
		end)
		return ok and list or {}
	end
	function hm.Move() end
	function hm.MoveTo() end
	function hm.TakeDamage() end
	function hm.SetStateEnabled() end
	function hm.GetStateEnabled()
		return true
	end
	function hm.GetAccessories()
		return {}
	end
	function hm.IsA(_, c)
		return c == "Humanoid" or c == "Instance"
	end
	function hm.FindFirstChild(_, n)
		return realHum:FindFirstChild(n)
	end
	function hm.FindFirstChildOfClass(_, c)
		return realHum:FindFirstChildOfClass(c)
	end
	function hm.GetAttribute(_, k)
		return realHum:GetAttribute(k)
	end
	function hm.SetAttribute(_, k, v)
		realHum:SetAttribute(k, v)
	end
	local hp = setmetatable({}, {
		__index = function(_, k)
			if k == "MoveDirection" then
				return st.dir
			elseif k == "Jump" then
				return st.jump
			elseif k == "RootPart" or k == "Torso" then
				return parts.HumanoidRootPart
			elseif k == "Parent" then
				return F
			elseif k == "FloorMaterial" then
				return st.ground and Enum.Material.Plastic or Enum.Material.Air
			end
			local s = sig[k]
			if s then
				return s
			end
			local f = hm[k]
			if f then
				return f
			end
			local v = hv[k]
			if v ~= nil then
				return v
			end
			local ok, r = pcall(function()
				return realHum[k]
			end)
			if ok then
				if type(r) == "function" then
					return function(_, ...)
						return r(realHum, ...)
					end
				end
				return r
			end
			return nil
		end,
		__newindex = function(_, k, v)
			hv[k] = v
			if k == "WalkSpeed" and type(fd.setWalkSpeed) == "function" then
				pcall(fd.setWalkSpeed, tonumber(v) or 16)
			elseif k == "JumpPower" and type(fd.setJumpPower) == "function" then
				pcall(fd.setJumpPower, tonumber(v) or 50)
			end
		end,
		__tostring = function()
			return "Humanoid"
		end,
	})
	U.hum = hp

	local fm = {}
	function fm.FindFirstChild(_, n, r)
		if n == "Humanoid" then
			return hp
		end
		return model:FindFirstChild(n, r)
	end
	function fm.WaitForChild(_, n)
		return fm.FindFirstChild(nil, n)
	end
	function fm.FindFirstChildOfClass(_, c)
		if c == "Humanoid" then
			return hp
		end
		return model:FindFirstChildOfClass(c)
	end
	function fm.FindFirstChildWhichIsA(_, c)
		if c == "Humanoid" then
			return hp
		end
		return model:FindFirstChildWhichIsA(c)
	end
	function fm.GetScale()
		return 1
	end
	function fm.GetAttribute(_, k)
		if k == "IsDancing" then
			return K.dancing()
		end
		return model:GetAttribute(k)
	end
	function fm.GetChildren()
		return model:GetChildren()
	end
	function fm.GetDescendants()
		return model:GetDescendants()
	end
	function fm.GetPivot()
		return parts.HumanoidRootPart.CFrame
	end
	function fm.IsA(_, c)
		return model:IsA(c)
	end
	setmetatable(F, {
		__index = function(_, k)
			local f = fm[k]
			if f then
				return f
			end
			if k == "Humanoid" then
				return hp
			end
			local ok, r = pcall(function()
				return model[k]
			end)
			if ok then
				if type(r) == "function" then
					return function(_, ...)
						return r(model, ...)
					end
				end
				return r
			end
			return nil
		end,
		__newindex = function(_, k, v)
			pcall(function()
				model[k] = v
			end)
		end,
		__tostring = function()
			return model.Name
		end,
	})
	U.figure = F
	function U.real(x)
		if x == F then
			return model
		elseif x == hp then
			return realHum
		end
		return x
	end

	local CA = { _Actions = {}, _ActionsMap = {}, held = {} }
	local actions, actionsmap = CA._Actions, CA._ActionsMap
	function CA:RunBinding(caac, input)
		local state = input.UserInputState
		CA.held[caac.Name] = state == Enum.UserInputState.Begin or state == Enum.UserInputState.Change
		local s, result = xpcall(caac.Callback, function(m)
			warn("[" .. TITLE .. "] " .. tostring(m))
		end, caac.Name, state, input)
		if s and result == Enum.ContextActionResult.Sink then
			return true
		end
		return false
	end
	function CA:OnInput(input, gpe)
		if input.UserInputType ~= Enum.UserInputType.Keyboard and gpe then
			return
		end
		for i = #actions, 1, -1 do
			local caac = actions[i]
			local exec = false
			for _, v in caac.Inputs do
				if v == input.UserInputType then
					exec = true
					break
				end
				if input.UserInputType == Enum.UserInputType.Keyboard and v == input.KeyCode then
					exec = true
					break
				end
			end
			if exec and CA:RunBinding(caac, input) then
				return
			end
		end
	end
	function CA:UnbindAllActions()
		table.clear(actions)
		table.clear(actionsmap)
		table.clear(CA.held)
	end
	function CA:BindAction(name, callback, _, ...)
		assert(type(name) == "string")
		assert(type(callback) == "function")
		CA:UnbindAction(name)
		local caac = { Name = name, Callback = callback, Inputs = { ... } }
		table.insert(actions, caac)
		actionsmap[name] = caac
	end
	function CA:UnbindAction(name)
		local caac = actionsmap[name]
		if caac then
			local i = table.find(actions, caac)
			if i then
				table.remove(actions, i)
			end
			actionsmap[name] = nil
			CA.held[name] = nil
		end
	end
	function CA:SetTitle(name, title)
		local caac = actionsmap[name]
		if caac then
			caac.Title = title
		end
	end
	function CA:SetImage() end
	function CA:SetPosition() end
	function CA:Tap(input)
		for _, caac in ipairs(table.clone(actions)) do
			if caac.Title == "M1" then
				CA:RunBinding(caac, input)
			end
		end
	end
	U.ContextActions = CA

	local mouseDown = false
	local hookedJump = nil
	local function hookJump()
		local pg = LP:FindFirstChildOfClass("PlayerGui")
		local touchGui = pg and pg:FindFirstChild("TouchGui")
		local frame = touchGui and touchGui:FindFirstChild("TouchControlFrame")
		local jb = frame and frame:FindFirstChild("JumpButton")
		if not jb or jb == hookedJump then
			return
		end
		hookedJump = jb
		on(jb.InputBegan, function()
			st.touchJump = true
		end)
		on(jb.InputEnded, function()
			st.touchJump = false
		end)
	end
	local function onInput(input, gpe)
		local ok, box = pcall(function()
			return UserInputService:GetFocusedTextBox()
		end)
		if ok and box then
			return
		end
		CA:OnInput(input, gpe)
	end
	local taps = {}
	on(UserInputService.InputBegan, function(input, gpe)
		local kind = input.UserInputType
		if kind == Enum.UserInputType.MouseButton1 and not gpe then
			mouseDown = true
		end
		onInput(input, gpe)
		if kind == Enum.UserInputType.Touch and not gpe then
			taps[input] = true
			CA:Tap(input)
		end
	end)
	on(UserInputService.InputChanged, onInput)
	on(UserInputService.InputEnded, function(input, gpe)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			mouseDown = false
		end
		onInput(input, gpe)
		if taps[input] then
			taps[input] = nil
			CA:Tap(input)
		end
	end)
	local jumpTick = 0
	on(RunService.Heartbeat, function(dt)
		jumpTick -= dt
		if jumpTick <= 0 then
			jumpTick = 1
			hookJump()
		end
	end)
	function U.firing()
		if mouseDown then
			return true
		end
		for name, caac in pairs(actionsmap) do
			if CA.held[name] and caac.Title == "M1" then
				return true
			end
		end
		return false
	end

	local function keyDir()
		local cam = workspace.CurrentCamera
		if not cam then
			return ZERO
		end
		local f, r = 0, 0
		pcall(function()
			if UserInputService:IsKeyDown(Enum.KeyCode.W) then
				f += 1
			end
			if UserInputService:IsKeyDown(Enum.KeyCode.S) then
				f -= 1
			end
			if UserInputService:IsKeyDown(Enum.KeyCode.D) then
				r += 1
			end
			if UserInputService:IsKeyDown(Enum.KeyCode.A) then
				r -= 1
			end
		end)
		if f == 0 and r == 0 then
			return ZERO
		end
		local look, right = cam.CFrame.LookVector * XZ, cam.CFrame.RightVector * XZ
		if look.Magnitude < 1e-3 or right.Magnitude < 1e-3 then
			return ZERO
		end
		local d = look.Unit * f + right.Unit * r
		return d.Magnitude > 1e-3 and d.Unit or ZERO
	end
	local function jumpHeld()
		local down = false
		pcall(function()
			down = UserInputService:IsKeyDown(Enum.KeyCode.Space)
		end)
		if down or st.touchJump then
			return true
		end
		pcall(function()
			down = UserInputService:IsGamepadButtonDown(Enum.UserInputType.Gamepad1, Enum.KeyCode.ButtonA)
		end)
		return down == true
	end

	local controls, cmdIds = {}, {}
	local pendingText = nil
	local function control(kind, text, value, a, b, c)
		local ctl = { kind = kind, text = tostring(text or ""), value = value, min = a, max = b, step = c, desc = pendingText }
		ctl.Changed = Uhh.signal()
		pendingText = nil
		controls[#controls + 1] = ctl
		return ctl
	end
	U.Util_CreateSwitch = function(_, text, value)
		return control("switch", text, value == true)
	end
	U.Util_CreateSlider = function(_, text, value, min, max, step)
		return control("slider", text, tonumber(value) or 0, tonumber(min) or 0, tonumber(max) or 100, tonumber(step) or 1)
	end
	U.Util_CreateDropdown = function(_, text, array, value)
		local ctl = control("dropdown", text, value)
		ctl.options = type(array) == "table" and array or {}
		return ctl
	end
	U.Util_CreateText = function(_, text)
		pendingText = tostring(text or "")
		return { Text = pendingText }
	end
	U.Util_CreateButton = function(_, text)
		local ctl = control("button", text)
		ctl.Activated = Uhh.signal()
		ctl.MouseButton1Click = ctl.Activated
		return ctl
	end
	U.Util_CreateTextbox = function(_, text)
		local ctl = control("textbox", text, "")
		ctl.FocusLost = Uhh.signal()
		return ctl
	end
	U.Util_CreateSeparator = function() end
	U.Util_CreateCanvas = function()
		return Instance.new("Frame")
	end
	U.Util_CreateScrollCanvas = function()
		return Instance.new("Frame")
	end

	local mod = nil
	local folder = "AtsukoHub/movesets"
	local function configFile()
		local id = mod and (mod.InternalName or mod.Name) or TITLE
		return folder .. "/" .. tostring(id):gsub("[^%w]", "") .. ".json"
	end
	local function saveConfig()
		if not (mod and type(mod.SaveConfig) == "function" and writefile) then
			return
		end
		local ok, data = pcall(mod.SaveConfig)
		if not ok or type(data) ~= "table" then
			return
		end
		pcall(function()
			if makefolder and isfolder and not isfolder("AtsukoHub") then
				makefolder("AtsukoHub")
			end
			if makefolder and isfolder and not isfolder(folder) then
				makefolder(folder)
			end
		end)
		pcall(writefile, configFile(), HttpService:JSONEncode(data))
	end
	local function loadConfig()
		if not (mod and type(mod.LoadConfig) == "function" and isfile and readfile) then
			return
		end
		local okH, has = pcall(isfile, configFile())
		if not okH or not has then
			return
		end
		local ok, data = pcall(function()
			return HttpService:JSONDecode(readfile(configFile()))
		end)
		if ok and type(data) == "table" then
			pcall(mod.LoadConfig, data)
		end
	end
	local function setControl(ctl, v)
		ctl.value = v
		ctl.Changed.fire(v)
		task.defer(saveConfig)
	end
	local function idOf(text)
		local id = string.lower((string.gsub(text, "[^%w]", "")))
		if id == "" then
			id = "option"
		end
		local base, n = id, 1
		while cmdIds[id] do
			n += 1
			id = base .. n
		end
		cmdIds[id] = true
		return id
	end
	local function commands()
		for _, ctl in ipairs(controls) do
			local name = ctl.text
			if ctl.kind == "switch" then
				local id = idOf(name)
				K.command({ id = id, name = name, desc = ctl.desc or (name .. ", on or off"), usage = id, kind = "toggle", run = function(_, ctx)
					local v
					if ctx and ctx.state ~= nil then
						v = ctx.state
					else
						v = not ctl.value
					end
					setControl(ctl, v)
					K.say(name .. ": " .. (v and "on" or "off"), "info", 2)
				end })
			elseif ctl.kind == "slider" then
				local id = idOf(name)
				K.command({ id = id, name = name, desc = ctl.desc or (name .. ", " .. ctl.min .. " to " .. ctl.max), usage = id .. " <" .. ctl.min .. "-" .. ctl.max .. ">", run = function(arg)
					local n = tonumber(arg)
					if n then
						local step = ctl.step > 0 and ctl.step or 1
						n = math.clamp(math.floor((n - ctl.min) / step + 0.5) * step + ctl.min, ctl.min, ctl.max)
						setControl(ctl, n)
					end
					K.say(name .. ": " .. tostring(ctl.value), "info", 2)
				end })
			elseif ctl.kind == "dropdown" then
				local id = idOf(name)
				K.command({ id = id, name = name, desc = ctl.desc or name, usage = id .. " <" .. table.concat(ctl.options, "|") .. ">", run = function(arg)
					for _, o in ipairs(ctl.options) do
						if arg and string.lower(tostring(o)) == string.lower(arg) then
							setControl(ctl, o)
						end
					end
					K.say(name .. ": " .. tostring(ctl.value), "info", 2)
				end })
			elseif ctl.kind == "button" then
				local id = idOf(name)
				K.command({ id = id, name = name, desc = ctl.desc or name, usage = id, run = function()
					ctl.Activated.fire()
				end })
			end
		end
	end

	local function skills()
		local names = {}
		for line in string.gmatch(type(mod.Description) == "string" and mod.Description or "", "[^\n]+") do
			local k, n = string.match(line, "^%s*(.-)%s+%-%s+(.-)%s*$")
			if k and n then
				names[string.lower(k)] = { key = k, name = n }
				names[string.lower(n)] = { key = k, name = n }
			end
		end
		for _, caac in ipairs(actions) do
			local title = caac.Title or ""
			if title ~= "M1" then
				local info = names[string.lower(title)] or { key = title, name = title ~= "" and title or caac.Name }
				local code = Enum.KeyCode.Unknown
				for _, v in ipairs(caac.Inputs) do
					if typeof(v) == "EnumItem" and v.EnumType == Enum.KeyCode then
						code = v
						break
					end
				end
				local id = idOf(info.name)
				K.command({ id = id, name = info.name, desc = info.key .. " - " .. info.name, usage = id, run = function()
					local input = { UserInputType = Enum.UserInputType.Keyboard, KeyCode = code, UserInputState = Enum.UserInputState.Begin }
					CA:RunBinding(caac, input)
					task.delay(0.1, function()
						input.UserInputState = Enum.UserInputState.End
						if actionsmap[caac.Name] == caac then
							CA:RunBinding(caac, input)
						end
					end)
				end })
			end
		end
	end

	local music, musicName = nil, nil
	local musicOn = cfg.music ~= false
	function U.SetOverrideMovesetMusic(soundid, soundname, volume)
		if not music then
			music = Instance.new("Sound")
			music.Name = "MovesetMusic"
			music.Looped = true
			music.Parent = K.fxFolder
		end
		if soundid and soundid ~= "" then
			music.SoundId = soundid
			music.Volume = volume or 1
			music.TimePosition = 0
			musicName = soundname
			if musicOn then
				music:Play()
			end
		else
			music:Stop()
		end
	end
	function U.GetOverrideMovesetMusicTime()
		return music and music.TimePosition or 0
	end
	function U.SetOverrideMovesetMusicTime(t)
		if music then
			music.TimePosition = t
		end
	end
	function U.SetOverrideMovesetMusicSpeed(speed)
		if music then
			music.PlaybackSpeed = speed
		end
	end
	function U.AssetGetPathFromFilename(file)
		return Kit.ROOT .. tostring(file)
	end
	function U.AssetGetContentId(file)
		local id = Kit.asset(file)
		return id or ""
	end
	U.ReanimCamera = workspace.CurrentCamera
	U.FallenPartsDestroyHeight = workspace.FallenPartsDestroyHeight
	U.RandomString = Uhh.RandomString

	function U.ReanimateFling(target)
		if typeof(target) ~= "Instance" then
			return false
		end
		local m = target
		if m:IsA("BasePart") then
			m = m.Parent
			if m and (m:IsA("Accessory") or m:IsA("Tool")) then
				m = m.Parent
			end
		end
		if not m or m == LP.Character or m == model then
			return false
		end
		local h = m:FindFirstChildOfClass("Humanoid")
		local root = (h and h.RootPart) or m:FindFirstChild("HumanoidRootPart")
		if not root or type(fd.fling) ~= "function" then
			return false
		end
		local ok, r = pcall(fd.fling, root)
		return ok and r ~= false
	end

	local chatted = { Event = Uhh.signal() }
	U.OnPlayerChatted = chatted
	local lastChat, lastChatAt = nil, 0
	local function heard(plr, text)
		if type(text) ~= "string" then
			return
		end
		local now = os.clock()
		if lastChat == text and now - lastChatAt < 1 then
			return
		end
		lastChat, lastChatAt = text, now
		chatted.Event.fire(plr, text)
	end
	on(LP.Chatted, function(text)
		heard(LP, text)
	end)
	pcall(function()
		local TCS = game:GetService("TextChatService")
		on(TCS.MessageReceived, function(msg)
			local src = msg.TextSource
			local plr = src and Players:GetPlayerByUserId(src.UserId)
			if plr then
				heard(plr, msg.Text)
			end
		end)
	end)

	local HR = { HatCFrameOverride = {}, HatMapSummary = "" }
	U.HatReanimator = HR
	local list = U.records
	local recs = {}
	local function limbOf(e)
		if type(fd.rigHat) == "function" then
			local okR, r = pcall(fd.rigHat, e)
			if okR then
				return r ~= nil
			end
		end
		local ok, j = pcall(fd.getPartJoint, e)
		if not ok or type(j) ~= "table" then
			return true
		end
		local p1 = j.Part1
		for _, limb in pairs(Kit.LIMBS) do
			if limb ~= "Head" and p1 == K.part(limb) and (typeof(j.C1) ~= "CFrame" or j.C1 == CFI) then
				return true
			end
		end
		return false
	end
	local function accName(e)
		local ok, n = pcall(function()
			return rawget(e, "p").Parent.Name
		end)
		return ok and type(n) == "string" and n or ""
	end
	local function sizeOf(e)
		local ok, s = pcall(function()
			return rawget(e, "p").Size
		end)
		return ok and typeof(s) == "Vector3" and s or V3(1, 1, 1)
	end
	local function wordsHit(A, name)
		if type(A) ~= "table" or type(A.rows) ~= "function" or name == "" then
			return false
		end
		local ok, rows = pcall(A.rows, TITLE, "bulletwords")
		if not ok or type(rows) ~= "table" then
			return false
		end
		local low = string.lower(name)
		for _, row in ipairs(rows) do
			for _, w in ipairs(type(row) == "table" and type(row.words) == "table" and row.words or {}) do
				if type(w) == "string" and w ~= "" and string.find(low, string.lower(w), 1, true) then
					return true
				end
			end
		end
		return false
	end
	local function classify(e)
		local A, W = genv.AtsukoAlignment, genv.AtsukoEmoteWeapons
		local hi = { mesh = Uhh.digits(rawget(e, "m")), tex = Uhh.digits(rawget(e, "t")), name = accName(e) }
		local rec = { e = e, MeshId = hi.mesh, TextureId = hi.tex, Name = hi.name, C1 = CFI, Scale = 1 }
		local group, row, src = nil, nil, nil
		if type(A) == "table" and type(A.match) == "function" then
			for slot, g in pairs(Uhh.GROUP_OF_SLOT) do
				local ok, r = pcall(A.match, TITLE, slot, hi, e)
				if ok and type(r) == "table" then
					local rank = r.src == "user" and 1 or 3
					if not src or rank < src then
						group, row, src = g, r, rank
					end
				end
			end
		end
		local data = not limbOf(e) and Uhh.known(hi.mesh, hi.tex) or nil
		if data and not (src == 1) then
			group, row = data.Group, nil
		end
		if not group and wordsHit(A, hi.name) then
			group = "Bullet"
			rec.weak = true
		end
		if not group and type(W) == "table" and type(W.kind) == "function" then
			local ok, k = pcall(W.kind, hi.mesh, hi.tex, hi.name)
			if ok and (k == "gun" or k == "sword") then
				group = k == "gun" and "Gun" or "Sword"
				rec.weak = true
			end
		end
		rec.Group = group
		if data then
			rec.C1 = data.C1 or CFI
			rec.Attachments = data.Attachments
			rec.rest = { C0 = data.C0, C1 = data.C1 or CFI, Limb = data.Limb }
			rec.known = true
		elseif group == "Gun" or group == "Sword" then
			rec.C1 = Uhh.gripC1(sizeOf(e), group)
		end
		if row and type(A.offset) == "function" then
			local ok, c = pcall(A.offset, row)
			if ok and typeof(c) == "CFrame" then
				rec.extra = c
			end
		end
		return rec
	end
	local function take(rec)
		if rec.taken then
			return true
		end
		local ok, j = pcall(fd.getPartJoint, rec.e)
		if not ok or type(j) ~= "table" then
			return false
		end
		rec.j = j
		rec.home = { j.Part1, j.C0, j.C1 }
		rec.taken = true
		return true
	end
	local function release(rec)
		if rec.taken and rec.j and rec.home then
			pcall(function()
				rec.j.Part1, rec.j.C0, rec.j.C1 = rec.home[1], rec.home[2], rec.home[3]
			end)
		end
		rec.taken = false
	end
	local function wanted(e)
		local A = genv.AtsukoAlignment
		if type(A) ~= "table" or type(A.weapon) ~= "function" then
			return false
		end
		local ok, w = pcall(A.weapon, { mesh = Uhh.digits(rawget(e, "m")), tex = Uhh.digits(rawget(e, "t")), name = accName(e), acc = accName(e) })
		return ok and w == true
	end
	local function scan()
		local seen = {}
		for _, e in ipairs(K.hats()) do
			seen[e] = true
			if not recs[e] and (not limbOf(e) or wanted(e)) then
				local rec = classify(e)
				rec.Index = #list + 1
				recs[e] = rec
				list[#list + 1] = rec
			end
		end
		for i = #list, 1, -1 do
			local rec = list[i]
			if not seen[rec.e] or fd.cframes[rec.e] == nil then
				release(rec)
				recs[rec.e] = nil
				table.remove(list, i)
			end
		end
	end
	U.scan = scan
	function U.rescan()
		for _, rec in ipairs(list) do
			release(rec)
		end
		table.clear(list)
		table.clear(recs)
		scan()
	end
	local lead = {}
	local function override(rec)
		local grouped = rec.Group ~= nil and (not rec.weak or lead[rec.Group] == rec)
		for _, data in ipairs(HR.HatCFrameOverride) do
			if type(data) == "table" and not data.Disable then
				if data.Group and grouped and rec.Group == data.Group then
					if data.Limb then
						return { C0 = data.C0 or data.Offset or CFI, C1 = rec.C1 * (data.C1 or CFI), Limb = data.Limb }
					end
					return { C0 = data.C0 or data.CFrame or CFI, C1 = rec.C1 * (data.C1 or CFI) }
				end
				if data.MeshId or data.TextureId or data.Name then
					local ok = true
					if data.MeshId then
						ok = ok and Uhh.idMatch(rec.MeshId, data.MeshId)
					end
					if data.TextureId then
						ok = ok and Uhh.idMatch(rec.TextureId, data.TextureId)
					end
					if data.Name then
						ok = ok and rec.Name == data.Name
					end
					if ok then
						return { C0 = data.C0, C1 = data.C1, Offset = data.Offset or data.CFrame, Limb = data.Limb, exact = true }
					end
				end
				if data.Index and grouped and rec.Index == data.Index then
					return { C0 = data.C0 or data.CFrame or CFI, C1 = rec.C1 * (data.C1 or CFI) }
				end
			end
		end
		return rec.rest
	end
	local function place(ov)
		if not ov then
			return nil
		end
		if ov.Limb then
			local limb = world[ov.Limb]
			if not limb then
				return nil
			end
			if ov.C0 and ov.C1 then
				return limb * ov.C0 * ov.C1:Inverse()
			end
			if ov.Offset then
				return limb * ov.Offset
			end
			return nil
		end
		if ov.C0 and ov.C1 then
			return ov.C0 * ov.C1:Inverse()
		end
		return nil
	end
	local groups = cfg.groups or {}
	local aim = cfg.aim
	local aimBlend = 0
	local function offsetOf(group)
		local job = groups[group]
		local off = job and K.offset(job) or CFI
		if aim and job == aim.base and aimBlend > 1e-3 then
			off = off * CFI:Lerp(K.offset(aim.job), aimBlend)
		end
		return off
	end
	local function hatCF(rec)
		if rec.taken and rec.cf then
			return rec.cf
		end
		local c = fd.cframes[rec.e]
		return typeof(c) == "CFrame" and c or nil
	end
	local function placeHats()
		local rp = rootPart or K.part("HumanoidRootPart")
		local rootCF = rp and fd.cframes[rp]
		if typeof(rootCF) ~= "CFrame" then
			return
		end
		local inv = rootCF:Inverse()
		table.clear(lead)
		for _, rec in ipairs(list) do
			local g = rec.Group
			if g and not rec.weak then
				lead[g] = true
			end
		end
		for _, rec in ipairs(list) do
			local g = rec.Group
			if g and rec.weak and lead[g] == nil then
				lead[g] = rec
			end
		end
		for _, rec in ipairs(list) do
			local ov = override(rec)
			local cf = place(ov)
			if cf then
				cf = cf * (rec.extra or CFI)
				if rec.Group then
					cf = cf * offsetOf(rec.Group)
				end
				if take(rec) then
					rec.cf = cf
					rec.j.Part1, rec.j.C0, rec.j.C1 = rp, CFI, inv * cf
				end
			else
				release(rec)
				rec.cf = nil
			end
		end
	end
	function HR.GetAttachmentCFrame(name)
		for _, rec in ipairs(list) do
			local att = rec.Attachments and rec.Attachments[name]
			if att then
				local cf = hatCF(rec)
				if cf then
					return cf * att
				end
			end
		end
		return nil
	end
	function HR.GetHatMap()
		local out = {}
		for i, rec in ipairs(list) do
			out[i] = { MeshId = rec.MeshId, TextureId = rec.TextureId, Name = rec.Name, Group = rec.Group, C1 = rec.C1, Index = rec.Index }
		end
		return out
	end
	function HR.GetHatCFrameMeshAndTexture(mesh, tex, name)
		for _, rec in ipairs(list) do
			if rec.MeshId == Uhh.digits(mesh) and rec.TextureId == Uhh.digits(tex) and (not name or rec.Name == name) then
				return hatCF(rec)
			end
		end
		return nil
	end

	local AL = K.AL
	local jobKeys = {}
	for i, j in ipairs(jobs) do
		jobKeys[i] = j[1]
	end
	local function groupsOf(job)
		if aim and job == aim.job then
			job = aim.base
		end
		local out = {}
		for g, j in pairs(groups) do
			if j == job then
				out[#out + 1] = g
			end
		end
		return out
	end
	local function firstOf(job)
		local gs = groupsOf(job)
		local best = nil
		for _, rec in ipairs(list) do
			for _, g in ipairs(gs) do
				if rec.Group == g and (not best or (rec.taken and not best.taken)) then
					best = rec
				end
			end
		end
		return best
	end
	U.firstOf = firstOf
	function AL.found()
		local out, done = {}, {}
		for i, job in ipairs(jobKeys) do
			local key = (aim and job == aim.job) and aim.base or job
			if not done[key] then
				done[key] = true
				local rec = firstOf(job)
				out[#out + 1] = tostring(jobs[i][2]) .. ": " .. (rec and (rec.Name ~= "" and rec.Name or "found") or "not found")
			end
		end
		return table.concat(out, "  ·  ")
	end
	function AL.hat(s)
		local rec = firstOf(jobKeys[s])
		if not rec then
			return nil
		end
		return rec.MeshId, rec.TextureId, rec.Name ~= "" and rec.Name or nil
	end

	local lastErr = nil
	local lastStep = 0
	local ready = false
	local scanAt = 0
	local function step(dt, kind, joints)
		if not ready or not mod then
			return
		end
		lastStep = os.clock()
		local base = baseCF()
		local vfd = K.vel()
		local ground = kind ~= "jump" and kind ~= "fall"
		if ground and not st.ground then
			st.extra = V3(st.extra.X, 0, st.extra.Z)
		end
		local want = (kind == "jump" and ST.Jumping) or (kind == "fall" and ST.Freefall) or ST.Running
		if st.state ~= want then
			if ground and not st.ground then
				setState(ST.Landed)
			end
			setState(want)
		end
		local vel = vfd + st.extra
		local flat = V3(vfd.X, 0, vfd.Z)
		st.move = flat
		st.dir = flat.Magnitude > 0.5 and flat.Unit or keyDir()
		st.jump = jumpHeld()
		if ground then
			local speed = V3(vel.X, 0, vel.Z).Magnitude
			if st.run == nil or math.abs(speed - st.run) > 0.1 then
				st.run = speed
				sig.Running.fire(speed)
			end
		else
			st.run = nil
		end
		st.ground = ground
		aimBlend = Kit.toward(aimBlend, U.firing() and 1 or 0, 16, dt)
		local root = parts.HumanoidRootPart
		root.CFrame = base
		pcall(function()
			root.AssemblyLinearVelocity = vel
		end)
		pcall(function()
			root.Velocity = vel
		end)
		pcall(function()
			root.AssemblyAngularVelocity = ZERO
		end)
		pcall(function()
			root.RotVelocity = ZERO
		end)
		local ok, err = pcall(mod.Update, dt, F)
		if not ok and err ~= lastErr then
			lastErr = err
			warn("[" .. TITLE .. "] " .. tostring(err))
		end
		local after = root.CFrame
		local nextCF = nil
		if (after.Position - base.Position).Magnitude > 1e-3 or after.LookVector:Dot(base.LookVector) < 0.99999 then
			nextCF = after
		end
		local w = ZERO
		pcall(function()
			w = root.AssemblyAngularVelocity
		end)
		if w.Magnitude < 1e-4 then
			pcall(function()
				w = root.RotVelocity
			end)
		end
		if math.abs(w.Y) > 1e-4 then
			nextCF = (nextCF or base) * CFrame.Angles(0, math.clamp(w.Y * math.min(dt, 1 / 60), -math.pi, math.pi), 0)
		end
		local v2 = vel
		pcall(function()
			v2 = root.Velocity
		end)
		if (v2 - vel).Magnitude < 1e-3 then
			pcall(function()
				v2 = root.AssemblyLinearVelocity
			end)
		end
		local dv = v2 - vel
		if dv.Magnitude > 1e-3 then
			st.extra += dv
		end
		if ground then
			st.extra = V3(st.extra.X * math.exp(-10 * dt), math.max(st.extra.Y, 0), st.extra.Z * math.exp(-10 * dt))
		end
		if st.extra.Magnitude > 500 then
			st.extra = st.extra.Unit * 500
		elseif st.extra.Magnitude < 0.05 then
			st.extra = ZERO
		end
		if st.extra ~= ZERO then
			nextCF = (nextCF or base) + st.extra * dt
		end
		if nextCF and type(fd.setCfr) == "function" then
			pcall(fd.setCfr, nextCF)
		end
		solve(base)
		if joints then
			for _, d in ipairs(motors) do
				K.goal[d.key] = d.rel
				K.cur[d.key] = d.rel
			end
		end
		local now = os.clock()
		if now >= scanAt then
			scanAt = now + 1
			local A = genv.AtsukoAlignment
			local rev = type(A) == "table" and A.rev or nil
			if rev ~= U.alignRev then
				U.alignRev = rev
				U.rescan()
			else
				scan()
			end
		end
		placeHats()
	end
	U.step = step

	function U.add(factory)
		U.factory = factory
	end
	function U.module()
		return mod
	end

	function U.run()
		if type(U.factory) ~= "function" then
			K.say("This script has no moveset in it", "error", 5)
			K.stop()
			return nil
		end
		local okF, m = pcall(U.factory)
		if not okF or type(m) ~= "table" then
			K.say("Couldn't start: " .. tostring(m), "error", 6)
			K.stop()
			return nil
		end
		mod = m
		loadConfig()
		if type(mod.Config) == "function" then
			local okC, errC = pcall(mod.Config, nil)
			if not okC then
				warn("[" .. TITLE .. "] " .. tostring(errC))
			end
		end
		commands()
		K.command({ id = idOf("music"), name = "Music", desc = "Turns the moveset's song on or off", usage = "music", kind = "toggle", run = function(_, ctx)
			if ctx and ctx.state ~= nil then
				musicOn = ctx.state
			else
				musicOn = not musicOn
			end
			if music then
				if musicOn then
					music:Play()
				else
					music:Stop()
				end
			end
			K.say(musicOn and ("Music on" .. (musicName and (": " .. musicName) or "")) or "Music off", "info", 2)
		end })
		for _, file in ipairs(type(mod.Assets) == "table" and mod.Assets or {}) do
			pcall(Kit.asset, file)
		end
		table.clear(HR.HatCFrameOverride)
		local A = genv.AtsukoAlignment
		U.alignRev = type(A) == "table" and A.rev or nil
		scan()
		solve(baseCF())
		if type(mod.Init) == "function" then
			local okI, errI = pcall(mod.Init, F)
			if not okI then
				warn("[" .. TITLE .. "] " .. tostring(errI))
			end
		end
		skills()
		ready = true
		K.frame(function(_, s)
			step(s.dt, s.kind, true)
		end)
		K.run()
		on(RunService.Heartbeat, function(dt)
			if K.alive and ready and os.clock() - lastStep > 0.12 then
				step(math.clamp(dt, 1 / 240, 1 / 15), "idle", false)
			end
		end)
		if type(mod.Description) == "string" and mod.Description ~= "" then
			K.say(mod.Description, "info", 7)
		end
		if cfg.need then
			task.delay(4, function()
				if K.alive and not firstOf(cfg.need) then
					K.say("No " .. cfg.need .. " hat found. Wear one or say add " .. cfg.need .. " <hat id>", "info", 5)
				end
			end)
		end
		return mod
	end

	K.onStop(function()
		ready = false
		if mod and type(mod.Destroy) == "function" then
			pcall(mod.Destroy, F)
		end
		saveConfig()
		for _, rec in ipairs(list) do
			release(rec)
		end
		pcall(function()
			CA:UnbindAllActions()
		end)
		for _, c in ipairs(conns) do
			pcall(function()
				c:Disconnect()
			end)
		end
		table.clear(conns)
		for _, t in ipairs(hm.GetPlayingAnimationTracks()) do
			pcall(function()
				t:Stop(0)
			end)
		end
		if type(fd.setWalkSpeed) == "function" then
			pcall(fd.setWalkSpeed, 16)
		end
		if type(fd.setJumpPower) == "function" then
			pcall(fd.setJumpPower, 50)
		end
		pcall(function()
			model:Destroy()
		end)
		if cfg.global and genv[cfg.global] == U then
			genv[cfg.global] = nil
		end
	end)
	if cfg.global then
		genv[cfg.global] = U
	end
	return U
end

genv.AtsukoUhh = Uhh
return Uhh
