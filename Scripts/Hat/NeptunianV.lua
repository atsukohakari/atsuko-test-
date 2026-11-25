--[[
	Neptunian V  |  FDless edition
	Original limb script converted to run on the FDless reanimate (embedded below).

	Keys:  F equip / unequip     LMB 3-hit combo (equipped)
	       Q smack   E darkspin   Z spinnyblade   X eightbit megablade   C blade spin   (equipped)
	       R super jump   V teleport to mouse   L mute music
	       1 / 2 / 3 / 4 / 5 change mode (speed + music + idle / walk animations)
	Chat:  /stop (turn everything off)   /sword (re-find the sword)   /sit   /glitch (mode 4 only)   id/<soundid>   pitch/<n>   vol/<n>   skip/<seconds>

	Swords: Corrupt Demonic Greatsword, Hacklords Venom Greatsword or The Beasthammer - wear one before running the
	       script (or tap Find sword / type /sword after putting it on). The Align panel switches between them.
]]

-- ====================================== SWORDS + ALIGN ======================================
-- Supported swords (wear one before running the script - no server command is used):
--   Corrupt Demonic Greatsword   https://www.roblox.com/catalog/4506945409
--   Hacklords Venom Greatsword   https://www.roblox.com/catalog/121290673270759
--   The Beasthammer              https://www.roblox.com/catalog/90947601297494
-- "words" = lowercase pieces of the accessory name used to recognise it.
-- align = {X, Y, Z, rotX, rotY, rotZ} in studs / degrees: sword = in hand (equipped), swordback = on your back,
-- base = how the hat sits in the hand before the align is applied {rotX, rotY, rotZ}.
-- Every sword keeps its OWN alignment. Use the on-screen "Align" button (top left, or P) to change them live;
-- Save writes NeptunianFDlessAlign.json and it is loaded again next time you run the script.
local SWORDS = {
	{key = "corrupt", name = "Corrupt Demonic Greatsword", id = 4506945409, words = {"corrupt", "demonic"},
		align = {sword = {0.5, 2.9, -0.4, 0, 0, -140}, swordback = {-0.6, 2.9, 0, 0, 0, -45}, base = {0, 0, 90}}},
	{key = "venom", name = "Hacklords Venom Greatsword", id = 121290673270759, words = {"venom", "hacklord"},
		align = {sword = {0.5, 2.9, -0.4, 0, 0, -140}, swordback = {-0.6, 2.9, 0, 0, 0, -45}, base = {0, 0, 90}}},
	{key = "beast", name = "The Beasthammer", id = 90947601297494, words = {"beasthammer", "beast hammer", "beast"},
		align = {sword = {0.5, 2.9, -0.4, 0, 0, -140}, swordback = {-0.6, 2.9, 0, 0, 0, -45}, base = {0, 0, 90}}},
}

-- the sword that is active right now (filled in by the script from SWORDS[...].align, edited by the Align panel)
local ALIGN = {
	sword     = {0.5, 2.9, -0.4, 0, 0, -140},
	swordback = {-0.6, 2.9, 0, 0, 0, -45},
}

local CONFIG = {
	SwordAccessoryName = "",    -- optional: exact name of the accessory if your sword has a custom name (uses the first sword's align)
	SwordMeshId = "",            -- optional: digits of the sword's MeshId if auto detection ever fails
	SwordTextureId = "",         -- optional: digits of the sword's TextureId
	-- how the hat sits in the hand BEFORE the ALIGN above is applied (degrees, XYZ).
	-- Tweak this first if the blade points the wrong way (Base tab in the align panel).
	SwordBaseRotation = {0, 0, 90},
	AssetFolder = "NeptunianAssets",
	AlignFile = "NeptunianFDlessAlign.json",
	IgnoreMenusOnTap = false,    -- true = a tap on the joystick area / chat / topbar does not attack (default: tapping the screen always attacks)
}


local function hubNotify(title, text, kind, dur)
	local env = (typeof(getgenv) == "function" and getgenv()) or _G
	local f = env.AtsukoNotify
	if type(f) == "function" then
		return pcall(f, title, text, kind, dur)
	end
	return pcall(warn, "[" .. tostring(title) .. "] " .. tostring(text))
end
-- FDless reanimate (MyWorld, continued by rqz) - embedded so this script is self-contained
do
local __fdless = function()
--!optimize 2
--no need to load the whole thing cuz u can use the last one
if _G.GenesisFDless then 
	return _G.GenesisFDless 
end

--oh you're still here? queue the reanimate

--[[
	FDless Reanimate by MyWorld continued by rqz
	"var"
	Patchma Hub Discord: https://discord.com/invite/QMy5f6DrbH
]]

--no need to get and index the library tables with function names every time the script uses them
local osclock=os.clock
local tspawn=task.spawn
local tdelay=task.delay
local twait=task.wait
local schar=string.char
local ssub=string.sub
local sfind=string.find
local supper=string.upper
local mrandom=math.random
local sin=math.sin
local cos=math.cos
local abs=math.abs
local min=math.min
local sqrt=math.sqrt
local clamp=math.clamp
local tinsert=table.insert
local tclear=table.clear
local tclone=table.clone
local tfind=table.find
local cyield=coroutine.yield
local cresume=coroutine.resume
local crunning=coroutine.running
local vmagnitude=vector.magnitude --faster than indexing with Magnitude
local vnormalize=vector.normalize --faster than indexing with Unit

--the script doesnt have to read global varaibles every time to get them
--why not have them saved in local varaibles for faster access times
local next=next
local pcall=pcall
local xpcall=xpcall
local type=type
local typeof=typeof
local game=game
local sethiddenproperty=sethiddenproperty or set_hidden_property or sethiddenprop
local setscriptable=setscriptable or set_scriptable
local replicatesignal=replicatesignal or replicate_signal

local i=Instance.new 
local v2=Vector2.new 
local v3=Vector3.new
local c3=Color3.new 
local cf=CFrame.new
local cfl=CFrame.lookAt
local angles=CFrame.fromEulerAngles --faster than .Angles
local u2=UDim2.new 
local e=Enum 
local rp=RaycastParams.new 
local cs=ColorSequence.new 
local csk=ColorSequenceKeypoint.new 

local sine=osclock()
local deltaTime=0
local v3_0=v3()
local v3_101=v3(1,0,1)
local v3_010=v3(0,1,0)
local cf_0=cf()
local v3_xz=v3_101*10
local v3_xzL=v3_101*250.1
local v3_net=v3_010*25.01

local enumphysics=e.HumanoidStateType.Physics
local enumragdoll=e.HumanoidStateType.Ragdoll
local enumrunning=e.HumanoidStateType.Running
local enumseated=e.HumanoidStateType.Seated
local enumMD=e.MouseBehavior.Default

local sm=v3_010/2
local dense=PhysicalProperties.new(100,0,0,100,100)
local light=PhysicalProperties.new(0.0001,0,0,100,100)
local humstatesbl=e.HumanoidStateType:GetEnumItems()
table.remove(humstatesbl,tfind(humstatesbl,enumrunning))
table.remove(humstatesbl,tfind(humstatesbl,e.HumanoidStateType.None))

--not "local function rs" to not assign debug names
local rs=function()
	local s=""
	for i=1,mrandom(8,15) do
		if mrandom(2)==2 then
			s=s..schar(mrandom(65,90))
		else
			s=s..schar(mrandom(97,122))
		end
	end
	return s
end

--it runs even faster if u call __index and __newindex metamethods directly
local getMetamethodFromErrorStack=function(userdata,f,test)
	local ret=nil
	xpcall(f,function()
		ret=debug.info(2,"f")
	end,userdata,nil,0)
	if (type(ret)~="function") or not test(ret) then
		return f
	end
	return ret
end
local insSet=getMetamethodFromErrorStack(game,function(a,b,c) a[b]=c end,function(f) local a=i("Folder") local b=rs() f(a,"Name",b) return a.Name==b end)
local insGet=getMetamethodFromErrorStack(game,function(a,b) return a[b] end,function(f) local a=i("Folder") local b=rs() a.Name=b return f(a,"Name")==b end)
local cfGet=getMetamethodFromErrorStack(cf_0,function(a,b) return a[b] end,function(f) return f(cf(1,2,3),"Position")==v3(1,2,3) end)
local cfMul=getMetamethodFromErrorStack(cf_0,function(a,b) return a*b end,function(f) return angles(1,2,3)*angles(1,2,3)==f(angles(1,2,3),angles(1,2,3)) end)
local cfAdd=getMetamethodFromErrorStack(cf_0,function(a,b) return a+b end,function(f) return cf(1,2,3)+v3(1,2,3)==f(cf(1,2,3),v3(1,2,3)) end)
local v3Get=getMetamethodFromErrorStack(v3_0,function(a,b) return a[b] end,function(f) return v3(1,2,3).Unit==f(v3(1,2,3),"Unit") end)
local v2Get=getMetamethodFromErrorStack(v2(),function(a,b) return a[b] end,function(f) return f(v2(1,2),"Y")==2 end)
--multiplying and adding vector3 is faster if you use the * and + operators
--its faster to multiply X and Y of vector2 than to multiply vector2 and then get X and Y from it

--no need to index instances every time to call their functions
local Clone=insGet(game,"Clone")
local ClearAllChildren=insGet(game,"ClearAllChildren")
local Destroy=insGet(game,"Destroy")
local IsA=insGet(game,"IsA")
local FindFirstChildOfClass=insGet(game,"FindFirstChildOfClass")
local FindFirstChildWhichIsA=insGet(game,"FindFirstChildWhichIsA")
local GetChildren=insGet(game,"GetChildren")
local IsDescendantOf=insGet(game,"IsDescendantOf")
local QueryDescendants=insGet(game,"QueryDescendants")
local GetPropertyChangedSignal=insGet(game,"GetPropertyChangedSignal")

--findfirstchildofclass faster than getservice
local plrs=FindFirstChildOfClass(game,"Players")
local rus=FindFirstChildOfClass(game,"RunService")
local ws=FindFirstChildOfClass(game,"Workspace")
local uis=FindFirstChildOfClass(game,"UserInputService")
local gs=FindFirstChildOfClass(game,"GuiService")
local sg=FindFirstChildOfClass(game,"StarterGui")
local lp=insGet(plrs,"LocalPlayer")
local pg=FindFirstChildOfClass(lp,"PlayerGui")
local mouse=insGet(lp,"GetMouse")(lp)
local preanimation=insGet(rus,"PreAnimation")
local stepped=insGet(rus,"Stepped")
local heartbeat=insGet(rus,"Heartbeat")
local renderstepped=insGet(rus,"RenderStepped")

local GetPlayers=insGet(plrs,"GetPlayers")
local BreakJoints=insGet(i("Model"),"BreakJoints")
local ChangeState=insGet(i("Humanoid"),"ChangeState")
local SetStateEnabled=insGet(i("Humanoid"),"SetStateEnabled")
local GetJoints=insGet(insGet(ws,"Terrain"),"GetJoints")
local SetCore=insGet(sg,"SetCore")
local SetCoreGuiEnabled=insGet(sg,"SetCoreGuiEnabled")
local GetCoreGuiEnabled=insGet(sg,"GetCoreGuiEnabled")
local Raycast=insGet(ws,"Raycast")
local Connect=heartbeat.Connect
local Disconnect=Connect(GetPropertyChangedSignal(game,"CreatorId"),type).Disconnect
local Wait=heartbeat.Wait
local GetMouseLocation=insGet(uis,"GetMouseLocation")
local GetFocusedTextBox=insGet(uis,"GetFocusedTextBox")
local GetMouseDelta=insGet(uis,"GetMouseDelta")
local IsMouseButtonPressed=insGet(uis,"IsMouseButtonPressed")
local IsKeyDown=insGet(uis,"IsKeyDown")

local Inverse=cfGet(cf_0,"Inverse")
local Lerp=cfGet(cf_0,"Lerp")

local aligns={
	--[[
		example: 
		{PartName="Right Arm",meshid="123456789",textureid="123456789",AccessoryName="Name",C0=cf(1,2,3)*angles(1,2,3)},

		PartName (required) - the name of the body part you want to align the hat to
		meshid (optional) - mesh id of the mesh of the accessory you want to align
		textureid (optional) - texture id of the mesh of the accessory you want to align
		AccessoryName (optional) - instance name of the accessory you want to align 
		C0 (optional) - offset from the target body part to the accessory (defaults to cf(0,0,0) if unspecified)
		
		accessories will align to the first entry whose criteria they match
		(unspecified meshid/textureid/accessoryname accepts all accessories)
		
		each entry aligns one accessory at most
	]]

	-- unknown head
	{PartName="Head",meshid="11601535857",C0=angles(0,3.141592653589793,0)},

	-- patchma gear arms
	{PartName="Left Arm",meshid="13831073174",C0=cfMul(cf(0.017,0,-0.23),angles(-1.4835298641951802,-0.15707963267948966,2.199114857512855))},
	{PartName="Right Arm",meshid="13839903766",C0=cfMul(cf(0,-0.62,-0.01),angles(1.6580627893946132,0.15707963267948966,-2.199114857512855))},

	-- patchma yellow leg
	{PartName="Left Leg",meshid="11159370334",textureid="11159285454",C0=angles(1.5707963267948966,0,1.5707963267948966)},

	-- patchma lego piece leg
	{PartName="Right Leg",meshid="12652772399",textureid="12652775021",C0=cf(0,-0.125,0)},

	-- offsale white rig
	-- a ton of offsaled black torso's
	{PartName="Torso",meshid="14768666349"},
	{PartName="Torso",meshid="14241018198"},
	{PartName="Torso",meshid="13421774668"},
	{PartName="Left Leg",meshid="14255522247",C0=angles(1.5707963267948966,0,1.5707963267948966)},
	{PartName="Right Leg",meshid="14255522247",C0=angles(-1.5707963267948966,0,1.5707963267948966)},
	{PartName="Left Arm",meshid="14768684979",C0=angles(0,0,1.5707963267948966)},
	{PartName="Right Arm",meshid="14768684979",C0=angles(0,0,1.5707963267948966)},

	-- og fur body, r15 arms, smiley legs rig
	{PartName="Head",meshid="13953154391"},
	{PartName="Torso",meshid="13778226115"},
	{PartName="Left Leg",meshid="11159370334",textureid="11159284657",C0=angles(1.5707963267948966,0,1.5707963267948966)},
	{PartName="Right Leg",meshid="11263221350",textureid="11263219250",C0=angles(-1.5707963267948966,0,1.5707963267948966)},
	{PartName="Left Arm",meshid="12344207333",C0=angles(2,0,0)},
	{PartName="Right Arm",meshid="12344206657",C0=angles(2,0,0)},

	-- torso for both "white limbs black torso rig" and "black rig"
	{PartName="Torso",meshid="110684113028749"},
	-- white limbs black torso rig
	{PartName="Head",meshid="13058343355",C0=angles(0,3.141592653589793,0)},
	{PartName="Left Leg",meshid="139733645770094",C0=angles(0,0,1.5707963267948966)},
	{PartName="Right Leg",meshid="99608462237958",C0=angles(0,0,1.5707963267948966)},
	{PartName="Left Arm",meshid="90736849096372",C0=angles(0,0,1.5707963267948966)},
	{PartName="Right Arm",meshid="105141400603933",C0=angles(0,0,1.5707963267948966)},
	-- head for black rigs
	{PartName="Head",meshid="13953153289"},
	-- lay offsale black rig
	{PartName="Left Leg",meshid="17387586286",C0=angles(1.5707963267948966,0,1.5707963267948966)},
	{PartName="Right Leg",meshid="17387586286",C0=angles(-1.5707963267948966,0,1.5707963267948966)},
	{PartName="Left Arm",meshid="17374767929",C0=angles(1.5707963267948966,0,1.5707963267948966)},
	{PartName="Right Arm",meshid="17374767929",C0=angles(-1.5707963267948966,0,1.5707963267948966)},
	-- 7ws offsale black rig
	{PartName="Left Leg",meshid="125405780718494",C0=angles(1.5707963267948966,0,1.5707963267948966)},
	{PartName="Right Leg",meshid="125405780718494",C0=angles(-1.5707963267948966,0,1.5707963267948966)},
	{PartName="Left Arm",meshid="125405780718494",C0=angles(1.5707963267948966,0,1.5707963267948966)},
	{PartName="Right Arm",meshid="125405780718494",C0=angles(-1.5707963267948966,0,1.5707963267948966)},

	-- meshless rig
	{PartName="Head",meshid="13953094351"},
	{PartName="Torso",meshid="127552124837034",C0=angles(0,0,1.5707963267948966)},
	{PartName="Left Leg",meshid="121304376791439"},
	{PartName="Right Leg",meshid="121304376791439"},
	{PartName="Left Arm",meshid="117287001096396"},
	{PartName="Right Arm",meshid="117287001096396"},

	-- head for noob rig
	{PartName="Head",meshid="13058309233",C0=angles(0,3.141592653589793,0)},
	-- lay offsale noob rig
	{PartName="Torso",meshid="18640899369"},
	{PartName="Left Leg",meshid="18640901641"},
	{PartName="Right Leg",meshid="18640901641"},
	{PartName="Left Arm",meshid="18640914129"},
	{PartName="Right Arm",meshid="18640914129"},
	-- 7ws offsale noob rig
	{PartName="Torso",meshid="126825022897778"},
	{PartName="Left Leg",textureid="73798034827573",C0=angles(0,0,1.5707963267948966)},
	{PartName="Right Leg",textureid="73798034827573",C0=angles(0,0,1.5707963267948966)},
	{PartName="Left Arm",textureid="135650240593878",C0=angles(0,0,1.5707963267948966)},
	{PartName="Right Arm",textureid="135650240593878",C0=angles(0,0,1.5707963267948966)},

	-- white torso
	{PartName="Torso",meshid="126825022897778"},

	-- lay onsale gray torso white arm black leg rig
	{PartName="Torso",meshid="139792224823925"},
	{PartName="Left Leg",meshid="83395427313429",C0=angles(0,0,1.5707963267948966)},
	{PartName="Right Leg",meshid="83395427313429",C0=angles(0,0,1.5707963267948966)},
	{PartName="Left Arm",meshid="105263225400272",C0=angles(0,0,1.5707963267948966)},
	{PartName="Right Arm",meshid="105263225400272",C0=angles(0,0,1.5707963267948966)},

	-- shownape/geecee auto rig
	{PartName="Head",AccessoryName="Accessory (autorig_Head)"},
	{PartName="Torso",AccessoryName="Accessory (autorig_Torso)"},
	{PartName="Left Leg",AccessoryName="Accessory (autorig_LeftLeg)"},
	{PartName="Right Leg",AccessoryName="Accessory (autorig_RightLeg)"},
	{PartName="Left Arm",AccessoryName="Accessory (autorig_LeftArm)"},
	{PartName="Right Arm",AccessoryName="Accessory (autorig_RightArm)"},

	-- free rig
	--[[{PartName="Left Arm",meshid="4324138105",textureid="4324138210",C0=angles(-1.6144295580947547,1.5707963267948966,0)*cf(-0.125,0.3,0)},
	{PartName="Left Arm",meshid="4154474745",textureid="4154474807",C0=angles(1.5271630954950384,-1.5707963267948966,0)*cf(-0.125,-0.3,0)},
	{PartName="Right Arm",meshid="3030546036",textureid="3650191503",C0=angles(1.5271630954950384,1.5707963267948966,0)*cf(0.125,-0.3,0)},
	{PartName="Right Arm",meshid="3030546036",textureid="3443321249",C0=angles(-1.6144295580947547,-1.5707963267948966,0)*cf(0.125,0.3,0)},
	{PartName="Left Leg",meshid="3030546036",textureid="3360974849",C0=angles(1.5271630954950384,1.5707963267948966,0)*cf(-0.125,-0.35,0)},
	{PartName="Left Leg",meshid="3030546036",textureid="3360978739",C0=angles(-1.6144295580947547,-1.5707963267948966,0)*cf(-0.125,0.3,0)},
	{PartName="Right Leg",meshid="3030546036",textureid="3033898741",C0=angles(1.5271630954950384,-1.5707963267948966,0)*cf(0.125,-0.35,0)},
	{PartName="Right Leg",meshid="3030546036",textureid="3409604993",C0=angles(-1.6144295580947547,1.5707963267948966,0)*cf(0.125,0.3,0)},
	{PartName="Torso",meshid="4819720316",textureid="4819722776",C0=angles(0,0,0.2617993877991494)}]]
	{PartName="Torso",meshid="4819720316",textureid="4819722776",C0=angles(0,0,0.2617993877991494)},
	{PartName="Left Leg",meshid="4094864753",textureid="4094881938",C0=angles(0,0,-1.5707963267948966)},
	{PartName="Right Leg",meshid="4154474745",textureid="4154474807",C0=angles(0,0,1.5707963267948966)},
	{PartName="Left Arm",meshid="4489232754",textureid="4489233876",C0=angles(0,0,-1.5707963267948966)},
	{PartName="Right Arm",meshid="4324138105",textureid="4391374782",C0=angles(0,0,1.5707963267948966)},
}

local makeplaceholder=function(v)
	if not insGet(v,"Archivable") then
		insSet(v,"Archivable",true)
	end
	v=Clone(v)
	local mesh=FindFirstChildOfClass(v,"SpecialMesh")
	if mesh then
		insSet(mesh,"Parent",nil)
		ClearAllChildren(v)
		ClearAllChildren(mesh)
		insSet(mesh,"Name",rs())
		insSet(mesh,"Parent",v)
	else
		ClearAllChildren(v)
	end
	insSet(v,"Name",rs())
	insSet(v,"Anchored",true)
	insSet(v,"CanCollide",false)
	insSet(v,"Transparency",0.25)
	return v
end
local emptyfunction=function() end

local fling=fling~=false
local allowshiftlock=allowshiftlock~=false
local ctrltp=ctrltp~=false
--local invisiblekeybind=false --invisiblekeybind~=false
--local invisibleoffset=(type(invisibleoffset)=="number" and v3_010*-invisibleoffset) or v3_010*-100
local placeholders=placeholders~=false
local clickfling=clickfling==true
local flingdirection=(type(flingdirection)=="number" and flingdirection) or 0
local flingoffset=nil
local flingvel=nil
local flingrotvel=nil
if flingdirection==0 then
	flingoffset=-v3_010
	flingvel=v3(0,16000,0)
	flingrotvel=v3(16000,0,16000)
elseif flingdirection==1 then
	flingoffset=v3_010
	flingvel=v3(0,-16000,0)
	flingrotvel=v3(16000,0,16000)
elseif flingdirection==2 then
	flingoffset=v3(-0.5,0,0)
	flingvel=v3(16000,0,0)
	flingrotvel=v3(0,16000,0)
end
local flingtargetting=(type(flingtargetting)=="number" and flingtargetting) or 3
if (flingtargetting==3) and not sethiddenproperty then
	flingtargetting=2
end
if (flingtargetting==2) and not setscriptable then
	flingtargetting=0
end	
local highlightflingtargets=highlightflingtargets~=false
--local rainbowflinghighlights=rainbowflinghighlights~=false
local discharscripts=discharscripts~=false and function(v) if IsA(v,"Script") then insSet(v,"Disabled",true) end end
local flingchangestate=(type(flingchangestate)=="number" and flingchangestate) or 3
local respawntp=(type(respawntp)=="number" and respawntp) or 3
local disguiscripts=disguiscripts~=false
local breakjointsmethod=(type(breakjointsmethod)=="number" and breakjointsmethod) or 1
if (breakjointsmethod==4) and not replicatesignal then
	hubNotify("FDless", "This executor has no replicatesignal, break joints method 4 is off", "warn", 6)
	breakjointsmethod=1
end
local simrad=simrad~=false
local hidedeatheffect=hidedeatheffect~=false

local c=nil
local cons={}
local cframes={}
local hrpcon0=nil
local hrpcon1=nil
local flingtable={}
local plrcleanups={}
local onnewcamera=nil
local stopreanimate=function() 
	if c then
		c=nil
		for i,v in next,cframes do
			local p=i.v
			if p then
				Destroy(p)
			end
		end
		tclear(cframes)
		if hrpcon0 then
			Disconnect(hrpcon0)
			Disconnect(hrpcon1)
			hrpcon0=nil
		end
		for i,v in next,flingtable do
			if v then --it could be false
				Destroy(v)
			end
		end
		tclear(flingtable)
		for i,v in next,cons do
			Disconnect(v)
		end
		tclear(cons)
		for i,cleanupfunc in next,plrcleanups do
			cleanupfunc()
		end
		tclear(plrcleanups)
		insSet(uis,"MouseBehavior",enumMD)
		onnewcamera()
		return true
	end
	return false
end
local reanimate=function()
	--[[
		FDless reanimate by MyWorld continued by rqz
		optimize the optimized
	]]

	local novoid=true --prevents parts from going under workspace.FallenPartsDestroyHeight if you control them
	local speedlimit=3000 --makes your parts move slower if the magnitude of their velocity is higher than this
	local retVelTime=0.51 --time that claimed parts have velocity to reclaim in case u lose them
	local walkSpeed=16 --your walkspeed (can be changed at runtime)
	local jumpPower=50 --your jump power (can be changed at runtime)
	local gravity=196.2 --how fast the characters velocity decreases while falling (can be changed at runtime)
	local ctrlclicktp=ctrltp --makes you teleport where u point ur mouse cursor at when click and hold ctrl down
	--local invisible = false --moves your parts underground so you are not visible by pressing "i"

	if stopreanimate() then return end

	local cam=nil
	--theres a way to have ws.currentcamera nil on heartbeat and still have the game run normally
	local refcam=function()
		local newcam=insGet(ws,"CurrentCamera")
		while not newcam do
			Wait(GetPropertyChangedSignal(ws,"CurrentCamera"))
			newcam=insGet(ws,"CurrentCamera")
		end
		cam=newcam
	end
	refcam()
	local camcf=insGet(cam,"CFrame")
	local enumCamS=e.CameraType.Scriptable
	local camt=insGet(cam,"CameraType")
	local camcon0=nil
	local camcon1=nil
	local camcon2=nil
	onnewcamera=function()
		refcam()
		if camcon0 then 
			Disconnect(camcon0)
			Disconnect(camcon1)
			camcon0=nil
		end
		if not c then 
			if insGet(cam,"CameraType")==enumCamS then
				insSet(cam,"CameraType",camt)
			end
			return Disconnect(camcon2) 
		end
		camcon0=Connect(GetPropertyChangedSignal(cam,"CFrame"),function()
			if insGet(cam,"CFrame")~=camcf then
				insSet(cam,"CFrame",camcf)
			end
		end)
		camcon1=Connect(GetPropertyChangedSignal(cam,"CameraType"),function()
			if insGet(cam,"CameraType")~=enumCamS then
				insSet(cam,"CameraType",enumCamS)
			end
		end)
		if insGet(cam,"CameraType")~=enumCamS then
			insSet(cam,"CameraType",enumCamS)
		end
		if insGet(cam,"CFrame")~=camcf then
			insSet(cam,"CFrame",camcf)
		end
	end
	camcon2=Connect(GetPropertyChangedSignal(ws,"CurrentCamera"),onnewcamera)

	local wsGravity=insGet(ws,"Gravity")
	tinsert(cons,Connect(GetPropertyChangedSignal(ws,"Gravity"),function()
		wsGravity=insGet(ws,"Gravity")
	end))

	local fpdh=insGet(ws,"FallenPartsDestroyHeight")
	novoid=novoid and (fpdh+1)

	local cfr=nil
	c=insGet(lp,"Character")
	if c and IsDescendantOf(c,ws) then
		cfr=QueryDescendants(c,">BasePart#HumanoidRootPart")[1] or QueryDescendants(c,">BasePart#Torso")[1] or QueryDescendants(c,">BasePart#UpperTorso")[1] or FindFirstChildWhichIsA(c,"BasePart")
		if cfr then
			cfr=insGet(cfr,"CFrame")
		else
			cfr=cfMul(insGet(cam,"Focus"),cf(0,-1.5,0))
		end
	else
		c=true
		cfr=cfMul(insGet(cam,"Focus"),cf(0,-1.5,0))
	end

	onnewcamera()

	local Yvel=0
	local pos=cfGet(cfr,"Position")
	cfr=cfl(pos,pos+cfGet(cfr,"LookVector")*v3_101)
	local primarypart=nil
	local shiftlock=false
	local firstperson=false
	local xzvel=v3_0
	local v3_0150=v3_010*1.5
	local camcfLV=cfGet(camcf,"LookVector")
	local camrot=cfl(v3_0,camcfLV)
	local camrotX,camrotY=cfGet(camrot,"ToEulerAnglesYXZ")(camrot)
	local camcfRV=cfGet(camrot,"RightVector")
	local cammag=-vmagnitude((cfGet(camcf,"Position")-(pos+v3_0150)))

	local R6parts={ 
		head={Name="Head"},
		torso={Name="Torso"},
		root={Name="HumanoidRootPart"},
		leftArm={Name="Left Arm"},
		rightArm={Name="Right Arm"},
		leftLeg={Name="Left Leg"},
		rightLeg={Name="Right Leg"}
	}
	local rootpart=R6parts.root
	for i,v in next,R6parts do
		cframes[v]=cfr
	end
	local joints={
		{
			Name="Neck",
			Part0=R6parts.torso,Part1=R6parts.head,
			C0=cf(0,1,0,-1,0,0,0,0,1,0,1,-0),
			C1=cf(0,-0.5,0,-1,0,0,0,0,1,0,1,-0)
		},
		{
			Name="RootJoint",
			Part0=rootpart,Part1=R6parts.torso,
			C0=cf(0,0,0,-1,0,0,0,0,1,0,1,-0),
			C1=cf(0,0,0,-1,0,0,0,0,1,0,1,-0)
		},
		{
			Name="Right Shoulder",
			Part0=R6parts.torso,Part1=R6parts.rightArm,
			C0=cf(1,0.5,0,0,0,1,0,1,-0,-1,0,0),
			C1=cf(-0.5,0.5,0,0,0,1,0,1,-0,-1,0,0)
		},
		{
			Name="Left Shoulder",
			Part0=R6parts.torso,Part1=R6parts.leftArm,
			C0=cf(-1,0.5,0,0,0,-1,0,1,0,1,0,0),
			C1=cf(0.5,0.5,0,0,0,-1,0,1,0,1,0,0)
		},
		{
			Name="Right Hip",
			Part0=R6parts.torso,Part1=R6parts.rightLeg,
			C0=cf(1,-1,0,0,0,1,0,1,-0,-1,0,0),
			C1=cf(0.5,1,0,0,0,1,0,1,-0,-1,0,0)
		},
		{
			Name="Left Hip",
			Part0=R6parts.torso,Part1=R6parts.leftLeg,
			C0=cf(-1,-1,0,0,0,-1,0,1,0,1,0,0),
			C1=cf(-0.5,1,0,0,0,-1,0,1,0,1,0,0)
		}
	}

	local refreshedjoints={}
	local refreshjointsI=nil
	refreshjointsI=function(part)
		refreshedjoints[part]=true
		for i,v in next,joints do
			local part0=v.Part0
			local part1=v.Part1
			if part1 and (part0==part) then
				cframes[part1]=cfMul(cframes[part],cfMul(v.C0,Inverse(v.C1)))
				if not refreshedjoints[part1] then
					refreshjointsI(part1)
				end
			elseif part0 and (part1==part) then
				cframes[part0]=cfMul(cframes[part],cfMul(v.C1,Inverse(v.C0)))
				if not refreshedjoints[part0] then
					refreshjointsI(part0)
				end
			end
		end
	end
	refreshjointsI(rootpart)
	tclear(refreshedjoints)

	local attachments={
		RightShoulderAttachment={R6parts.rightArm,cf(0,1,0,1,0,0,0,1,0,0,0,1)},
		RightGripAttachment={R6parts.rightArm,cf(0,-1,0,1,0,0,0,1,0,0,0,1)},
		LeftFootAttachment={R6parts.leftLeg,cf(0,-1,0,1,0,0,0,1,0,0,0,1)},
		LeftShoulderAttachment={R6parts.leftArm,cf(0,1,0,1,0,0,0,1,0,0,0,1)},
		LeftGripAttachment={R6parts.leftArm,cf(0,-1,0,1,0,0,0,1,0,0,0,1)},
		RootAttachment={rootpart,cf(0,0,0,1,0,0,0,1,0,0,0,1)},
		RightFootAttachment={R6parts.rightLeg,cf(0,-1,0,1,0,0,0,1,0,0,0,1)},
		NeckAttachment={R6parts.torso,cf(0,1,0,1,0,0,0,1,0,0,0,1)},
		BodyFrontAttachment={R6parts.torso,cf(0,0,-0.5,1,0,0,0,1,0,0,0,1)},
		BodyBackAttachment={R6parts.torso,cf(0,0,0.5,1,0,0,0,1,0,0,0,1)},
		LeftCollarAttachment={R6parts.torso,cf(-1,1,0,1,0,0,0,1,0,0,0,1)},
		RightCollarAttachment={R6parts.torso,cf(1,1,0,1,0,0,0,1,0,0,0,1)},
		WaistFrontAttachment={R6parts.torso,cf(0,-1,-0.5,1,0,0,0,1,0,0,0,1)},
		WaistCenterAttachment={R6parts.torso,cf(0,-1,0,1,0,0,0,1,0,0,0,1)},
		WaistBackAttachment={R6parts.torso,cf(0,-1,0.5,1,0,0,0,1,0,0,0,1)},
		HairAttachment={R6parts.head,cf(0,0.6,0,1,0,0,0,1,0,0,0,1)},
		HatAttachment={R6parts.head,cf(0,0.6,0,1,0,0,0,1,0,0,0,1)},
		FaceFrontAttachment={R6parts.head,cf(0,0,-0.6,1,0,0,0,1,0,0,0,1)},
		FaceCenterAttachment={R6parts.head,cf(0,0,0,1,0,0,0,1,0,0,0,1)}
	}

	local getPart=function(name,blacklist)
		if blacklist then
			for i,v in next,cframes do
				if (i.Name==name) and not tfind(blacklist,i) then
					return i
				end
			end
		else
			for i,v in next,cframes do
				if i.Name==name then
					return i
				end
			end
		end
		return nil
	end

	local getJoint=function(name)
		for i,v in next,joints do
			if v.Name==name then
				return v
			end
		end
		return {C0=cf_0,C1=cf_0}
	end

	local getPartFromMesh=function(m,t,blacklist)
		if blacklist then
			for v,_ in next,cframes do
				if v.m and (not tfind(blacklist,v)) and sfind(v.m,m) and sfind(v.t,t) then
					return v
				end
			end
		else
			for v,_ in next,cframes do
				if v.m and sfind(v.m,m) and sfind(v.t,t) then
					return v
				end
			end
		end
		local p={m=m,t=t}
		cframes[p]=cfr
		local j={C0=cf_0,C1=cf_0,Part0=p}
		p.j=j
		return p
	end
	local getPartJoint=function(p)
		if cframes[p] then
			local j=p.j
			if j then
				return j
			end
			for i,v in next,joints do
				if v.Part0==p then
					return v
				end
			end
			for i,v in next,joints do
				if v.Part1==p then
					return v
				end
			end
		end
		return nil
	end

	local getAccWeldFromMesh=function(m,t)
		return getPartJoint(getPartFromMesh(m,t))
	end

	local raycastparams=rp()
	raycastparams.FilterType=e.RaycastFilterType.Exclude
	raycastparams.RespectCanCollide=true
	local rayfilter={}
	local characters={}
	local refreshrayfilter=function()
		tclear(rayfilter)
		for i,v in next,characters do
			tinsert(rayfilter,v)
		end
		raycastparams.FilterDescendantsInstances=rayfilter
	end
	local rootparts={}
	for i,v in next,aligns do
		v.p=getPart(v.PartName)
		if not v.meshid then
			v.meshid=""
		end 
		if not v.textureid then
			v.textureid=""
		end 
	end
	local makePartCons=function(p,t)
		if (t.p==p) and insGet(p,"Anchored") then
			t.p=nil
		end
		local con0=Connect(GetPropertyChangedSignal(p,"Anchored"),function()
			if insGet(p,"Anchored") then
				if t.p==p then
					t.c=nil
					t.p=nil
				end
			elseif not t.p then
				t.p=p
			end
		end)
		local con1=nil
		con1=Connect(insGet(p,"AncestryChanged"),function()
			if not IsDescendantOf(p,ws) then
				Disconnect(con0)
				Disconnect(con1)
				if t.p==p then
					t.p=nil
				end
			end
		end)
	end
	local ondes=function(v)
		if IsA(v,"Attachment") then
			local v1=attachments[insGet(v,"Name")]
			if v1 then
				local p=insGet(v,"Parent")
				if insGet(p,"Parent")~=c then
					local meshid=nil
					local textureid=nil
					if IsA(p,"MeshPart") then
						meshid=insGet(p,"MeshId")
						textureid=insGet(p,"TextureID")
					elseif IsA(p,"BasePart") then
						local sm=FindFirstChildOfClass(p,"SpecialMesh")
						if sm then
							meshid=insGet(sm,"MeshId")
							textureid=insGet(sm,"TextureId")
						else
							return
						end
					else
						return
					end
					for i,_ in next,cframes do
						if (meshid==i.m) and (textureid==i.t) then
							local p1=i.p
							if p1 then
								if p1==p then
									return
								end
							else
								i.p=p
								makePartCons(p,i)
								return
							end
						else
							local j=i.j
							if j and sfind(meshid,i.m) and sfind(textureid,i.t) then
								i.m=meshid
								i.t=textureid
								i.l=insGet(p,"Position")
								i.p=p
								makePartCons(p,i)
								i.j=nil
								i.Name=insGet(p,"Name")
								j.C0=insGet(v,"CFrame")
								j.C1=v1[2]
								j.Part1=v1[1]
								tinsert(joints,j)
								return
							end
						end
					end
					local n=insGet(insGet(p,"Parent"),"Name")
					for i,l in next,aligns do
						if l.p and sfind(meshid,l.meshid) and sfind(textureid,l.textureid) and ((not l.AccessoryName) or (l.AccessoryName==n)) then
							local t={Name=insGet(p,"Name"),l=insGet(p,"Position"),m=meshid,t=textureid,p=p}
							makePartCons(p,t)
							if placeholders then
								t.v=makeplaceholder(p)
								t.b=false
							end
							cframes[t]=insGet(p,"CFrame")
							tinsert(joints,{Part0=t,Part1=l.p,C0=l.C0 or cf_0,C1=cf_0})
							l.p=nil
							return
						end
					end
					local t={Name=insGet(p,"Name"),l=insGet(p,"Position"),m=meshid,t=textureid,p=p}
					makePartCons(p,t)
					if placeholders then
						t.v=makeplaceholder(p)
						t.b=false
					end
					cframes[t]=insGet(p,"CFrame")
					tinsert(joints,{Part0=t,Part1=v1[1],C0=insGet(v,"CFrame"),C1=v1[2]})
				end
			end
		end
	end

	local simradv=1000
	local enumH=e.CoreGuiType.Health
	local onplayer=function(v)
		simradv=simradv+1000
		local lastc=nil
		local con0=nil
		local con1=nil
		local oncharacter=function()
			local newc=insGet(v,"Character")
			if newc and (newc~=lastc) then
				lastc=newc

				if con0 then
					Disconnect(con0)
					Disconnect(con1)
					con0=nil
				end

				characters[v]=newc
				refreshrayfilter()

				local hrp=QueryDescendants(newc,">BasePart#HumanoidRootPart")[1]
				if hrp then
					rootparts[v]=hrp
				else
					local refresh=true					
					local threshold=false
					tdelay(0.5,function()
						refresh=true
						threshold=true
					end)
					con0=Connect(preanimation,function()
						if refresh then
							if threshold then
								hrp=QueryDescendants(newc,">BasePart#HumanoidRootPart")[1] or QueryDescendants(newc,">BasePart#Torso")[1] or QueryDescendants(newc,">BasePart#UpperTorso")[1] or FindFirstChildWhichIsA(newc,"BasePart")
							else
								hrp=QueryDescendants(newc,">BasePart#HumanoidRootPart")[1]
							end
							if hrp then
								rootparts[v]=hrp
								Disconnect(con0)
								Disconnect(con1)
								con0=nil
								return
							end
							refresh=false
						end
					end)
					con1=Connect(insGet(newc,"ChildAdded"),function()
						refresh=true
					end)
				end
			end
		end

		local charcon=Connect(GetPropertyChangedSignal(v,"Character"),oncharacter)
		oncharacter()
		plrcleanups[v]=function()
			simradv=simradv-1000
			characters[v]=nil
			rootparts[v]=nil
			if con0 then
				Disconnect(con0)
				Disconnect(con1)
				con0=nil
			end
			Disconnect(charcon)
		end
	end
	tinsert(cons,Connect(insGet(plrs,"PlayerRemoving"),function(v)
		local cleanup=plrcleanups[v]
		if cleanup then
			cleanup()
			plrcleanups[v]=nil
		end
	end))
	for i,v in next,GetPlayers(plrs) do simradv=simradv+1000 if v~=lp then tspawn(onplayer,v) end end
	tinsert(cons,Connect(insGet(plrs,"PlayerAdded"),onplayer))
	if disguiscripts then
		tinsert(cons,Connect(insGet(pg,"DescendantAdded"),function(v)
			if IsA(v,"Script") then --mind Enum.RunContext.Client
				insSet(v,"Disabled",true) 
			end
		end))
	end

	local lastc=nil
	local oncharacter=function()
		local newc=insGet(lp,"Character")
		if newc and (newc~=lastc) then
			lastc=newc

			if hrpcon0 then
				Disconnect(hrpcon0)
				Disconnect(hrpcon1)
				hrpcon0=nil
			end

			if discharscripts then
				Connect(insGet(newc,"DescendantAdded"),discharscripts)
				for i,v in next,QueryDescendants(newc,"Script") do
					insSet(v,"Disabled",true)
				end
			end

			characters[lp]=newc
			refreshrayfilter()

			local hrp=QueryDescendants(newc,">BasePart#HumanoidRootPart")[1]
			if not hrp then
				local refresh=true
				local threshold=false
				tdelay(0.5,function()
					refresh=true
					threshold=true
				end)
				local thread=crunning()
				hrpcon1=Connect(preanimation,function()
					if refresh then
						if threshold then
							hrp=QueryDescendants(newc,">BasePart#HumanoidRootPart")[1] or QueryDescendants(newc,">BasePart#Torso")[1] or QueryDescendants(newc,">BasePart#UpperTorso")[1] or FindFirstChildWhichIsA(newc,"BasePart")
						else
							hrp=QueryDescendants(newc,">BasePart#HumanoidRootPart")[1]
						end
						if hrp then
							Disconnect(hrpcon0)
							Disconnect(hrpcon1)
							hrpcon0=nil
							cresume(thread)
							return
						end
						refresh=false
					end
				end)
				hrpcon0=Connect(insGet(newc,"ChildAdded"),function()
					refresh=true
				end)
				cyield()
				Wait(stepped)
			end

			c=newc
			if next(flingtable) then
				local hum=FindFirstChildOfClass(c,"Humanoid")
				if hum then
					if flingchangestate==3 then
						ChangeState(hum,enumphysics)
						SetStateEnabled(hum,enumseated,false)
					elseif flingchangestate==1 then
						ChangeState(hum,enumphysics)
					else
						if flingchangestate==2 then
							SetStateEnabled(hum,enumseated,false)
						end
						if flingtargetting~=0 then
							ChangeState(hum,enumragdoll)
							SetStateEnabled(hum,enumrunning,false)
						end
					end
				end
				twait(0.25)
				for i1,v in next,tclone(flingtable) do
					if not c then
						return
					end
					if flingtargetting==3 then
						sethiddenproperty(hrp,"PhysicsRepRootPart",i1)
					elseif flingtargetting==2 then
						setscriptable(hrp,"PhysicsRepRootPart",true)
						insSet(hrp,"PhysicsRepRootPart",i1)
						setscriptable(hrp,"PhysicsRepRootPart",false)
					elseif flingtargetting==1 then
						local hrpcpp=insGet(hrp,"CustomPhysicalProperties")
						local tparent=insGet(i1,"Parent")
						local tcfr=insGet(i1,"CFrame")

						local model=i("Model")
						local hum=i("Humanoid",model)
						for i,v in next,humstatesbl do
							SetStateEnabled(hum,v,false)
						end

						local restorejoints={}
						for i,v in next,GetJoints(hrp) do
							restorejoints[v]=insGet(v,"Parent")
							insSet(v,"Parent",nil)
						end
						for i,v in next,GetJoints(i1) do
							restorejoints[v]=insGet(v,"Parent")
							insSet(v,"Parent",nil)
						end

						local tcfr1=cf(cfGet(tcfr,"Position")+v3_010*mrandom(10000,20000))
						insSet(i1,"Parent",ws)
						insSet(i1,"CFrame",tcfr1)
						insSet(hrp,"Parent",model)
						insSet(hrp,"CFrame",tcfr1+(insGet(hrp,"Size")+insGet(i1,"Size"))*sm)
						insSet(i1,"CustomPhysicalProperties",dense)
						insSet(hrp,"CustomPhysicalProperties",light)
						insSet(model,"Parent",ws)
						ChangeState(hum,enumrunning)
						if not insGet(i1,"CanCollide") then
							insSet(i1,"CanCollide",true)
						end
						Wait(stepped)
						for i,v in next,restorejoints do
							insSet(i,"Parent",v)
						end
						insSet(i1,"CFrame",tcfr)
						insSet(i1,"Parent",tparent)
						insSet(hrp,"CustomPhysicalProperties",hrpcpp)
						insSet(hrp,"Parent",newc)
						Destroy(model)
					end
					local startpos=insGet(i1,"Position")
					local stoptime=sine+(((flingtargetting~=0) and 0.1) or 3)
					while true do
						if insGet(i1,"Anchored") or not IsDescendantOf(i1,ws) then
							break
						end
						if vmagnitude(startpos-insGet(i1,"Position"))>200 then
							break
						end
						if flingtargetting~=0 then
							local tcf=cfAdd(insGet(i1,"CFrame"),flingoffset)
							if novoid and (cfGet(tcf,"Y")<novoid) then
								tcf=cfAdd(tcf,v3_010*(novoid-cfGet(tcf,"Y")))
							end
							insSet(hrp,"CFrame",tcf)
							insSet(hrp,"AssemblyLinearVelocity",flingvel)
						else
							local tcf=cfAdd(insGet(i1,"CFrame"),insGet(i1,"AssemblyLinearVelocity")*(sin(sine*15)+1)+flingoffset)
							if novoid and (cfGet(tcf,"Y")<novoid) then
								tcf=cfAdd(tcf,v3_010*(novoid-cfGet(tcf,"Y")))
							end
							insSet(hrp,"CFrame",tcf)
							insSet(hrp,"AssemblyLinearVelocity",insGet(i1,"AssemblyLinearVelocity")*v3_101*75)
						end
						insSet(hrp,"AssemblyAngularVelocity",flingrotvel)
						if sine>stoptime then
							break
						end
						twait()
					end
					if v then
						Destroy(v)
					end
					flingtable[i1]=nil
				end
				if flingtargetting==3 then
					sethiddenproperty(hrp,"PhysicsRepRootPart",nil)
				elseif flingtargetting==2 then
					setscriptable(hrp,"PhysicsRepRootPart",true)
					insSet(hrp,"PhysicsRepRootPart",nil)
					setscriptable(hrp,"PhysicsRepRootPart",false)
				elseif flingtargetting==1 then
					SetStateEnabled(hum,enumrunning,true)
					ChangeState(hum,enumrunning)
				end
				if respawntp==0 then
					insSet(hrp,"AssemblyLinearVelocity",v3_0)
					insSet(hrp,"AssemblyAngularVelocity",v3_0)
					insSet(hrp,"CFrame",cfr)
					twait(0.3)
				end
			end
			if respawntp==0 then
				twait()
			elseif respawntp==1 then
				local startpos=pos+v3(mrandom(-32,32),0,mrandom(-32,32))
				local dir=nil
				local poscheck=true
				while poscheck do
					poscheck=false
					for i,v in next,rootparts do
						local diff=(startpos-insGet(v,"Position"))*v3_101
						if vmagnitude(diff)<10 then
							poscheck=true
							dir=dir or (vnormalize(diff)*3)
							startpos=startpos+dir
						end
					end
					local diff=(startpos-pos)*v3_101
					if vmagnitude(diff)<10 then
						poscheck=true
						dir=dir or (vnormalize(diff)*3)
						startpos=startpos+dir
					end
				end
				startpos=cfAdd(cfGet(cfr,"Rotation"),startpos)
				insSet(hrp,"CFrame",startpos)
				insSet(hrp,"AssemblyLinearVelocity",v3_0)
				insSet(hrp,"AssemblyAngularVelocity",v3_0)
				twait(0.3)
			elseif respawntp==2 then
				insSet(hrp,"CFrame",cfAdd(cfr,cfGet(cfr,"RightVector")*3.5-cfGet(cfr,"LookVector")*3.5))
				insSet(hrp,"AssemblyLinearVelocity",v3_0)
				insSet(hrp,"AssemblyAngularVelocity",v3_0)
				twait(0.3)
			elseif respawntp==3 then
				local t=osclock()+0.3
				local startcf=cfAdd(cfMul(cfGet(cfr,"Rotation"),angles(1.5707963267948966,0,0)),pos*v3_101+v3_010*min(fpdh+30,v3Get(pos,"Y")-5))
				while twait() do
					insSet(hrp,"CFrame",startcf)
					insSet(hrp,"AssemblyLinearVelocity",v3_0)
					insSet(hrp,"AssemblyAngularVelocity",v3_0)
					if osclock()>t then
						break
					end
				end
			end
			if newc~=c then
				return
			end
			primarypart=insGet(newc,"PrimaryPart") or hrp
			if hidedeatheffect and GetCoreGuiEnabled(sg,enumH) then
				SetCoreGuiEnabled(sg,enumH,false)
			end
			if breakjointsmethod==4 then
				local h=FindFirstChildOfClass(newc,"Humanoid")
				if h then
					replicatesignal(insGet(h,"ServerBreakJoints"))
				else
					BreakJoints(newc)
				end
			elseif breakjointsmethod==1 then
				BreakJoints(newc)
				local h=FindFirstChildOfClass(newc,"Humanoid")
				if h then
					insSet(h,"Health",0)
				end
			elseif breakjointsmethod==2 then
				local h=FindFirstChildOfClass(newc,"Humanoid")
				if h then
					insSet(h,"Health",0)
				else
					BreakJoints(newc)
				end
			else
				BreakJoints(newc)
			end
			cons.ondes=Connect(insGet(newc,"DescendantAdded"),ondes)
			for i,v in next,QueryDescendants(newc,"Attachment") do
				ondes(v)
			end
		end
	end
	tinsert(cons,Connect(GetPropertyChangedSignal(lp,"Character"),oncharacter))
	oncharacter()

	local setsimrad=emptyfunction
	if simrad then
		setsimrad=function()
			if pcall(insSet,lp,"SimulationRadius",simradv) then
				setsimrad=function()
					insSet(lp,"SimulationRadius",simradv)
				end
			else
				setsimrad=emptyfunction
			end
		end
	end

	local mradN05=-0.008726646259971648
	local pi2=math.pi/2-0.0001
	local npi2=-pi2
	local KeyCode=e.KeyCode
	local enumYXZ=e.RotationOrder.YXZ
	local enumMB2=e.UserInputType.MouseButton2
	local enumMLCP=e.MouseBehavior.LockCurrentPosition
	local enumMLC=(insGet(uis,"TouchEnabled") and enumMLCP) or e.MouseBehavior.LockCenter 
	local enumMW=e.UserInputType.MouseWheel
	local enumMM=e.UserInputType.MouseMovement

	local mouseBehavior=insGet(uis,"MouseBehavior")
	tinsert(cons,Connect(GetPropertyChangedSignal(uis,"MouseBehavior"),function()
		if insGet(uis,"MouseBehavior")~=mouseBehavior then
			insSet(uis,"MouseBehavior",mouseBehavior)
		end
	end))

	local mode="default"
	local defaultmode={}
	local modes={default=defaultmode}

	local lerpsIdle=emptyfunction
	local lerpsWalk=emptyfunction
	local lerpsJump=emptyfunction
	local lerpsFall=emptyfunction

	local addmode=function(key,mode)
		if (type(key)~="string") or (type(mode)~="table") then
			return
		end
		for i,v in next,mode do
			if type(v)~="function" then
				mode[i]=nil
			end
		end
		if key=="default" then
			defaultmode=mode
			modes.default=mode
			lerpsIdle=mode.idle or emptyfunction
			lerpsWalk=mode.walk or emptyfunction
			lerpsJump=mode.jump or emptyfunction
			lerpsFall=mode.fall or emptyfunction
			if mode.modeEntered then
				mode.modeEntered()
			end
		elseif #key==1 then
			key=KeyCode[supper(ssub(key,1,1))]
			modes[key]=mode
		end
	end

	local keyW=KeyCode.W
	local Wpressed=IsKeyDown(uis,keyW)
	local keyA=KeyCode.A
	local Apressed=IsKeyDown(uis,keyA)
	local keyS=KeyCode.S
	local Spressed=IsKeyDown(uis,keyS)
	local keyD=KeyCode.D
	local Dpressed=IsKeyDown(uis,keyD)
	local keySpace=KeyCode.Space
	local jumpingInput=IsKeyDown(uis,keySpace)

	local FWmovement=0
	local RTmovement=0
	local isWalking=false
	local refreshKeyboardMovement=function()
		if Wpressed then if Spressed then if Dpressed then if Apressed then isWalking=false else FWmovement=0 RTmovement=1 isWalking=true end else if Apressed then FWmovement=0 RTmovement=-1 isWalking=true else isWalking=false end end else FWmovement=1 if Dpressed then if Apressed then RTmovement=0 else RTmovement=1 end else if Apressed then RTmovement=-1 else RTmovement=0 end end isWalking=true end else if Spressed then FWmovement=-1 if Dpressed then if Apressed then RTmovement=0 else RTmovement=1 end else if Apressed then RTmovement=-1 else RTmovement=0 end end isWalking=true else if Dpressed then if Apressed then isWalking=false else FWmovement=0 RTmovement=1 isWalking=true end else if Apressed then FWmovement=0 RTmovement=-1 isWalking=true else isWalking=false end end end end
	end
	refreshKeyboardMovement()

	local keyShift=KeyCode.LeftShift
	--local keyI=KeyCode.I
	tinsert(cons,Connect(insGet(uis,"InputBegan"),function(a)
		if insGet(gs,"MenuIsOpen") or GetFocusedTextBox(uis) then
			return
		end
		a=insGet(a,"KeyCode")
		if a==keyW then
			Wpressed=true
			refreshKeyboardMovement()
		elseif a==keyA then
			Apressed=true
			refreshKeyboardMovement()
		elseif a==keyS then
			Spressed=true
			refreshKeyboardMovement()
		elseif a==keyD then
			Dpressed=true
			refreshKeyboardMovement()
		elseif a==keySpace then
			jumpingInput=true
		elseif a==keyShift then
			shiftlock=allowshiftlock and not shiftlock
			--elseif invisiblekeybind and a==keyI then
			--invisible=not invisible
		elseif modes[a] then
			local modeLeft=modes[mode].modeLeft
			if modeLeft then
				modeLeft()
			end
			if mode==a then
				mode="default"
			else
				mode=a
			end
			local modet=modes[mode]
			lerpsIdle=modet.idle or defaultmode.idle or emptyfunction
			lerpsWalk=modet.walk or defaultmode.walk or emptyfunction
			lerpsJump=modet.jump or defaultmode.jump or emptyfunction
			lerpsFall=modet.fall or defaultmode.fall or emptyfunction
			if modes[mode].modeEntered then
				modes[mode].modeEntered()
			end
		end
	end))
	tinsert(cons,Connect(insGet(uis,"InputEnded"),function(a)
		a=insGet(a,"KeyCode")
		if a==keyW then
			Wpressed=false
			refreshKeyboardMovement()
		elseif a==keyA then
			Apressed=false
			refreshKeyboardMovement()
		elseif a==keyS then
			Spressed=false
			refreshKeyboardMovement()
		elseif a==keyD then
			Dpressed=false
			refreshKeyboardMovement()
		elseif a==keySpace then
			jumpingInput=false
		end
	end))

	local thumbstickEndX=0
	local thumbstickStartY=0

	local thumbstickSizeMultiplier=0

	local jumpStartX=0
	local jumpStartY=0
	local jumpEndX=0
	local jumpEndY=0

	local thumbstickInputObject=nil
	local jumpInputObject=nil
	local cameraRotateInputObject=nil
	local cameraZoomInputObject=nil

	local thumbstickTouchStart=v3_0
	local cameraZoomInputMagnitude=0

	tinsert(cons,Connect(insGet(uis,"TouchStarted"),function(inputObject)
		if insGet(gs,"MenuIsOpen") or GetFocusedTextBox(uis) then
			return
		end

		local touchPos=insGet(inputObject,"Position")
		local touchX=v3Get(touchPos,"X")
		local touchY=v3Get(touchPos,"Y")

		if (not thumbstickInputObject) and touchX<thumbstickEndX and touchY>thumbstickStartY then
			thumbstickInputObject=inputObject
			thumbstickTouchStart=insGet(inputObject,"Position")
			isWalking=false
		elseif (not jumpInputObject) and touchY>jumpStartY and touchX>jumpStartX and touchX<jumpEndX and touchY<jumpEndY then
			jumpInputObject=inputObject
			jumpingInput=true
		elseif not cameraRotateInputObject then
			cameraRotateInputObject=inputObject
		else
			cameraZoomInputObject=inputObject
			cameraZoomInputMagnitude=vmagnitude(insGet(cameraRotateInputObject,"Position")-insGet(cameraZoomInputObject,"Position"))
		end
	end))
	local cameraMoveable=true
	tinsert(cons,Connect(insGet(uis,"TouchMoved"),function(inputObject)
		local touchPos=insGet(inputObject,"Position")
		local touchX=v3Get(touchPos,"X")
		local touchY=v3Get(touchPos,"Y")
		if inputObject==thumbstickInputObject then
			local direction=insGet(inputObject,"Position")-thumbstickTouchStart
			local directionMag=vmagnitude(direction)/thumbstickSizeMultiplier
			if directionMag>0.05 then
				isWalking=true
				direction=vnormalize(direction)*min(1,(directionMag-0.05)/0.95) 
				FWmovement=-v3Get(direction,"Y")
				RTmovement=v3Get(direction,"X")
			else
				isWalking=false
			end
		elseif inputObject==jumpInputObject then
			jumpingInput=touchY>jumpStartY and touchX>jumpStartX and touchX<jumpEndX and touchY<jumpEndY
		else
			if cameraZoomInputObject then
				local newMagnitude=vmagnitude(insGet(cameraRotateInputObject,"Position")-insGet(cameraZoomInputObject,"Position"))
				cammag=cammag+(newMagnitude-cameraZoomInputMagnitude)*0.04*(0.75-cammag/4)
				cameraZoomInputMagnitude=newMagnitude
				if cammag<0 then
					firstperson=false
				else
					cammag=0
					firstperson=true
				end
			elseif (inputObject==cameraRotateInputObject) and cameraMoveable then
				local rotation=GetMouseDelta(uis)
				camrotX=clamp(v2Get(rotation,"Y")*mradN05+camrotX,npi2,pi2)
				camrotY=v2Get(rotation,"X")*mradN05+camrotY
				camrot=angles(camrotX,camrotY,0,enumYXZ)
				camcfLV=cfGet(camrot,"LookVector")
				camcfRV=cfGet(camrot,"RightVector")
			end
		end
	end))
	tinsert(cons,Connect(insGet(uis,"TouchEnded"),function(inputObject)
		if inputObject==thumbstickInputObject then
			thumbstickInputObject=nil
			isWalking=false
		elseif inputObject==jumpInputObject then
			jumpInputObject=nil
			jumpingInput=false
		elseif inputObject==cameraRotateInputObject then
			cameraRotateInputObject=nil
			cameraZoomInputObject=nil
		elseif inputObject==cameraZoomInputObject then
			cameraZoomInputObject=nil
		end
	end))

	local refreshTouchRegions=function()
		local sX=insGet(mouse,"ViewSizeX")
		local sY=insGet(mouse,"ViewSizeY")
		local isSmallScreen=min(sX,sY)<=500

		sY=sY+insGet(gs,"TopbarInset").Height

		thumbstickEndX=sX*0.4
		thumbstickStartY=(sY+0)*0.333

		if isSmallScreen then
			thumbstickSizeMultiplier=35
			jumpStartX=sX-95
			jumpStartY=sY-90
			jumpEndX=jumpStartX+70
			jumpEndY=jumpStartY+70
		else
			thumbstickSizeMultiplier=60
			jumpStartX=sX-170
			jumpStartY=sY-210
			jumpEndX=jumpStartX+120
			jumpEndY=jumpStartY+120
		end
	end
	tinsert(cons,Connect(GetPropertyChangedSignal(mouse,"ViewSizeX"),refreshTouchRegions))
	tinsert(cons,Connect(GetPropertyChangedSignal(mouse,"ViewSizeY"),refreshTouchRegions))
	tinsert(cons,Connect(GetPropertyChangedSignal(gs,"TopbarInset"),refreshTouchRegions))
	refreshTouchRegions()

	local mouseCameraMove=false
	tinsert(cons,Connect(insGet(uis,"InputChanged"),function(a,b)
		if b then return end
		local inputType=insGet(a,"UserInputType")
		if mouseCameraMove and (inputType==enumMM) and cameraMoveable then
			local rotation=GetMouseDelta(uis)
			camrotX=clamp(v2Get(rotation,"Y")*mradN05+camrotX,npi2,pi2)
			camrotY=v2Get(rotation,"X")*mradN05+camrotY
			camrot=angles(camrotX,camrotY,0,enumYXZ)
			camcfLV=cfGet(camrot,"LookVector")
			camcfRV=cfGet(camrot,"RightVector")
		elseif inputType==enumMW then
			cammag=cammag+v3Get(insGet(a,"Position"),"Z")*(0.75-cammag/4)
			if cammag<0 then
				firstperson=false
			else
				cammag=0
				firstperson=true
			end
		end
	end))

	if fling then
		local guiparent=FindFirstChildOfClass(game,"CoreGui")
		if not pcall(FindFirstChildOfClass,guiparent,"ScreenGui") then
			guiparent=pg
		end
		fling=function(target)
			if typeof(target)~="Instance" then 
				target=insGet(mouse,"Target")
				if not target then
					return false
				end
			end
			if not IsDescendantOf(target,ws) then
				return false
			end
			if IsA(target,"BasePart") or IsA(target,"Humanoid") then 
				target=insGet(target,"Parent") 
				if IsA(target,"Accoutrement") then
					target=insGet(target,"Parent")
				end
			end
			if (not IsA(target,"Model")) or (target==c) then
				return false
			end
			local targetpart=QueryDescendants(target,">BasePart#Torso")[1] or QueryDescendants(target,">BasePart#UpperTorso")[1]
			if (not targetpart) or (flingtable[targetpart]~=nil) then
				return false
			end
			if highlightflingtargets then
				local h=i("Highlight")
				insSet(h,"Name",rs())
				insSet(h,"Adornee",target)
				insSet(h,"OutlineColor",c3(1,0,0))
				insSet(h,"Parent",guiparent)
				flingtable[targetpart]=h
			else
				flingtable[targetpart]=false
			end
			return true
		end
		--[[if highlightflingtargets and rainbowflinghighlights then
			local c3hsv=Color3.fromHSV
			tinsert(cons,Connect(insGet(rus,"RenderStepped"),function()
				local c=c3hsv((sine*0.3)%1,1,1)
				for i,v in next,flingtable do
					insSet(v,"OutlineColor",c)
				end
			end))
		end]]
	else
		fling=emptyfunction
	end

	if ctrlclicktp then
		ctrlclicktp=KeyCode.LeftControl
		local tpoff=v3_010*3
		if clickfling then
			tinsert(cons,Connect(insGet(mouse,"Button1Down"),function()
				if insGet(mouse,"Target") then
					if IsKeyDown(uis,ctrlclicktp) then
						pos=cfGet(insGet(mouse,"Hit"),"Position")+tpoff
						cfr=cfl(pos,pos+camcfLV*v3_101)
						xzvel=v3_0
						Yvel=0
					else
						fling()
					end
				end
			end))
		else
			tinsert(cons,Connect(insGet(mouse,"Button1Down"),function()
				if insGet(mouse,"Target") and IsKeyDown(uis,ctrlclicktp) then
					pos=cfGet(insGet(mouse,"Hit"),"Position")+tpoff
					cfr=cfl(pos,pos+camcfLV*v3_101)
					xzvel=v3_0
					Yvel=0
				end
			end))
		end
	elseif clickfling then
		tinsert(cons,Connect(insGet(mouse,"Button1Down"),fling))
	end

	local hhOff=3
	local hhOff1=3.01
	local setHipHeight=function(n)
		hhOff=n+3
		hhOff1=n+3.01
	end

	local noYvelTime=1
	local lastsine=sine
	local onground=nil
	local mainFunction=function()
		sine=osclock()
		local delta=sine-lastsine
		deltaTime=min(delta*10,1)
		lastsine=sine

		if shiftlock then
			if allowshiftlock then
				if mouseBehavior~=enumMLC then
					mouseBehavior=enumMLC
					insSet(uis,"MouseBehavior",mouseBehavior)
				end
				mouseCameraMove=true
			else
				shiftlock=false
			end
		elseif firstperson then
			if mouseBehavior~=enumMLC then
				mouseBehavior=enumMLC
				insSet(uis,"MouseBehavior",mouseBehavior)
			end
			mouseCameraMove=true
		elseif IsMouseButtonPressed(uis,enumMB2) then
			if mouseBehavior~=enumMLCP then
				mouseBehavior=enumMLCP
				insSet(uis,"MouseBehavior",mouseBehavior)
			end
			mouseCameraMove=true
		else
			if mouseBehavior~=enumMD then
				mouseBehavior=enumMD
				insSet(uis,"MouseBehavior",mouseBehavior)
			end
			mouseCameraMove=false
		end

		local raycastresult=Raycast(ws,pos,v3_010*(fpdh-v3Get(pos,"Y")),raycastparams)
		if raycastresult then
			onground=raycastresult.Distance<hhOff1
			if onground then
				Yvel=0
				pos=pos+v3_010*(v3Get(raycastresult.Position,"Y")+hhOff-v3Get(pos,"Y"))*min(delta*20,1)
				if jumpingInput and (jumpPower>0) then
					Yvel=jumpPower
					onground=false
				end
			else
				Yvel=Yvel-gravity*delta
				raycastresult=v3Get(raycastresult.Position,"Y")
				if v3Get(pos,"Y")+Yvel*delta<raycastresult then
					Yvel=0
					pos=pos+v3_010*(raycastresult+hhOff-v3Get(pos,"Y"))
				end
			end
		else
			Yvel=0
			onground=false
		end

		if firstperson then
			if isWalking then
				if walkSpeed==0 then
					xzvel=v3_0
					if onground then
						cfr=cfl(pos,pos+camcfLV*v3_101)
						camcf=cfAdd(camrot,pos+v3_0150)
						cframes[rootpart]=cfr
						insSet(cam,"CFrame",camcf)
						lerpsIdle()
						noYvelTime=min(noYvelTime+delta*0.3,1)
						xzvel=xzvel*(1-noYvelTime)
					elseif Yvel>0 then
						pos=pos+v3_010*Yvel*delta
						cfr=cfl(pos,pos+camcfLV*v3_101)
						camcf=cfAdd(camrot,pos+v3_0150)
						cframes[rootpart]=cfr
						insSet(cam,"CFrame",camcf)
						lerpsJump()
						noYvelTime=0
					else
						pos=pos+v3_010*Yvel*delta
						cfr=cfl(pos,pos+camcfLV*v3_101)
						camcf=cfAdd(camrot,pos+v3_0150)
						cframes[rootpart]=cfr
						insSet(cam,"CFrame",camcf)
						lerpsFall()
						noYvelTime=0
					end
				else
					xzvel=vnormalize(vnormalize(camcfLV*v3_101)*FWmovement+vnormalize(camcfRV*v3_101)*RTmovement)*walkSpeed
					if onground then
						pos=pos+xzvel*delta
						cfr=cfl(pos,pos+camcfLV*v3_101)
						camcf=cfAdd(camrot,pos+v3_0150)
						cframes[rootpart]=cfr
						insSet(cam,"CFrame",camcf)
						lerpsWalk()
						noYvelTime=min(noYvelTime+delta*0.3,1)
						xzvel=xzvel*(1-noYvelTime)
					elseif Yvel>0 then
						pos=pos+(xzvel+v3_010*Yvel)*delta
						cfr=cfl(pos,pos+camcfLV*v3_101)
						camcf=cfAdd(camrot,pos+v3_0150)
						cframes[rootpart]=cfr
						insSet(cam,"CFrame",camcf)
						lerpsJump()
						noYvelTime=0
					else 
						pos=pos+(xzvel+v3_010*Yvel)*delta
						cfr=cfl(pos,pos+camcfLV*v3_101)
						camcf=cfAdd(camrot,pos+v3_0150)
						cframes[rootpart]=cfr
						insSet(cam,"CFrame",camcf)
						lerpsFall()
						noYvelTime=0
					end
				end
			else
				xzvel=v3_0
				if onground then
					cfr=cfl(pos,pos+camcfLV*v3_101)
					camcf=cfAdd(camrot,pos+v3_0150)
					cframes[rootpart]=cfr
					insSet(cam,"CFrame",camcf)
					lerpsIdle()
					noYvelTime=min(noYvelTime+delta*0.3,1)
					xzvel=xzvel*(1-noYvelTime)
				elseif Yvel>0 then
					pos=pos+v3_010*Yvel*delta
					cfr=cfl(pos,pos+camcfLV*v3_101)
					camcf=cfAdd(camrot,pos+v3_0150)
					cframes[rootpart]=cfr
					insSet(cam,"CFrame",camcf)
					lerpsJump()
					noYvelTime=0
				else
					pos=pos+v3_010*Yvel*delta
					cfr=cfl(pos,pos+camcfLV*v3_101)
					camcf=cfAdd(camrot,pos+v3_0150)
					cframes[rootpart]=cfr
					insSet(cam,"CFrame",camcf)
					lerpsFall()
					noYvelTime=0
				end
			end
		elseif shiftlock then	
			if isWalking then
				if walkSpeed==0 then
					xzvel=v3_0
					if onground then
						cfr=cfl(pos,pos+camcfLV*v3_101)
						camcf=cfAdd(camrot,pos+v3_0150+camcfRV*1.75+camcfLV*cammag)
						cframes[rootpart]=cfr
						insSet(cam,"CFrame",camcf)
						lerpsIdle()
						noYvelTime=min(noYvelTime+delta*0.3,1)
						xzvel=xzvel*(1-noYvelTime)
					elseif Yvel>0 then
						pos=pos+v3_010*Yvel*delta
						cfr=cfl(pos,pos+camcfLV*v3_101)
						camcf=cfAdd(camrot,pos+v3_0150+camcfRV*1.75+camcfLV*cammag)
						cframes[rootpart]=cfr
						insSet(cam,"CFrame",camcf)
						lerpsJump()
						noYvelTime=0
					else
						pos=pos+v3_010*Yvel*delta
						cfr=cfl(pos,pos+camcfLV*v3_101)
						camcf=cfAdd(camrot,pos+v3_0150+camcfRV*1.75+camcfLV*cammag)
						cframes[rootpart]=cfr
						insSet(cam,"CFrame",camcf)
						lerpsFall()
						noYvelTime=0
					end
				else
					xzvel=vnormalize(vnormalize(camcfLV*v3_101)*FWmovement+vnormalize(camcfRV*v3_101)*RTmovement)*walkSpeed
					if onground then
						pos=pos+xzvel*delta
						cfr=cfl(pos,pos+camcfLV*v3_101)
						camcf=cfAdd(camrot,pos+v3_0150+camcfRV*1.75+camcfLV*cammag)
						cframes[rootpart]=cfr
						insSet(cam,"CFrame",camcf)
						lerpsWalk()
						noYvelTime=min(noYvelTime+delta*0.3,1)
						xzvel=xzvel*(1-noYvelTime)
					elseif Yvel>0 then
						pos=pos+(xzvel+v3_010*Yvel)*delta
						cfr=cfl(pos,pos+camcfLV*v3_101)
						camcf=cfAdd(camrot,pos+v3_0150+camcfRV*1.75+camcfLV*cammag)
						cframes[rootpart]=cfr
						insSet(cam,"CFrame",camcf)
						lerpsJump()
						noYvelTime=0
					else
						pos=pos+(xzvel+v3_010*Yvel)*delta
						cfr=cfl(pos,pos+camcfLV*v3_101)
						camcf=cfAdd(camrot,pos+v3_0150+camcfRV*1.75+camcfLV*cammag)
						cframes[rootpart]=cfr
						insSet(cam,"CFrame",camcf)
						lerpsFall()
						noYvelTime=0
					end
				end
			else
				xzvel=v3_0
				if onground then
					cfr=cfl(pos,pos+camcfLV*v3_101)
					camcf=cfAdd(camrot,pos+v3_0150+camcfRV*1.75+camcfLV*cammag)
					cframes[rootpart]=cfr
					insSet(cam,"CFrame",camcf)
					lerpsIdle()
					noYvelTime=min(noYvelTime+delta*0.3,1)
					xzvel=xzvel*(1-noYvelTime)
				elseif Yvel>0 then
					pos=pos+v3_010*Yvel*delta
					cfr=cfl(pos,pos+camcfLV*v3_101)
					camcf=cfAdd(camrot,pos+v3_0150+camcfRV*1.75+camcfLV*cammag)
					cframes[rootpart]=cfr
					insSet(cam,"CFrame",camcf)
					lerpsJump()
					noYvelTime=0
				else
					pos=pos+v3_010*Yvel*delta
					cfr=cfl(pos,pos+camcfLV*v3_101)
					camcf=cfAdd(camrot,pos+v3_0150+camcfRV*1.75+camcfLV*cammag)
					cframes[rootpart]=cfr
					insSet(cam,"CFrame",camcf)
					lerpsFall()
					noYvelTime=0
				end
			end
		else
			if isWalking then
				if walkSpeed==0 then
					xzvel=v3_0
					if onground then
						cfr=cfAdd(cfGet(cfr,"Rotation"),pos)
						camcf=cfAdd(camrot,pos+v3_0150+camcfLV*cammag)
						cframes[rootpart]=cfr
						insSet(cam,"CFrame",camcf)
						lerpsIdle()
						noYvelTime=min(noYvelTime+delta*0.3,1)
						xzvel=xzvel*(1-noYvelTime)
					elseif Yvel>0 then
						pos=pos+v3_010*Yvel*delta
						cfr=cfAdd(cfGet(cfr,"Rotation"),pos)
						camcf=cfAdd(camrot,pos+v3_0150+camcfLV*cammag)
						cframes[rootpart]=cfr
						insSet(cam,"CFrame",camcf)
						lerpsJump()
						noYvelTime=0
					else
						pos=pos+v3_010*Yvel*delta
						cfr=cfAdd(cfGet(cfr,"Rotation"),pos)
						camcf=cfAdd(camrot,pos+v3_0150+camcfLV*cammag)
						cframes[rootpart]=cfr
						insSet(cam,"CFrame",camcf)
						lerpsFall()
						noYvelTime=0
					end
				else
					xzvel=vnormalize(vnormalize(camcfLV*v3_101)*FWmovement+vnormalize(camcfRV*v3_101)*RTmovement)*walkSpeed
					if onground then
						pos=pos+xzvel*delta
						cfr=cfAdd(Lerp(cfGet(cfr,"Rotation"),cfl(v3_0,xzvel),deltaTime),pos)
						camcf=cfAdd(camrot,pos+v3_0150+camcfLV*cammag)
						cframes[rootpart]=cfr
						insSet(cam,"CFrame",camcf)
						lerpsWalk()
						noYvelTime=min(noYvelTime+delta*0.3,1)
						xzvel=xzvel*(1-noYvelTime)
					elseif Yvel>0 then
						pos=pos+(xzvel+(v3_010*Yvel))*delta
						cfr=cfAdd(Lerp(cfGet(cfr,"Rotation"),cfl(v3_0,xzvel),deltaTime),pos)
						camcf=cfAdd(camrot,pos+v3_0150+camcfLV*cammag)
						cframes[rootpart]=cfr
						insSet(cam,"CFrame",camcf)
						lerpsJump()
						noYvelTime=0
					else
						pos=pos+(xzvel+(v3_010*Yvel))*delta
						cfr=cfAdd(Lerp(cfGet(cfr,"Rotation"),cfl(v3_0,xzvel),deltaTime),pos)
						camcf=cfAdd(camrot,pos+v3_0150+camcfLV*cammag)
						cframes[rootpart]=cfr
						insSet(cam,"CFrame",camcf)
						lerpsFall()
						noYvelTime=0
					end
				end
			else
				xzvel=v3_0
				if onground then
					cfr=cfAdd(cfGet(cfr,"Rotation"),pos)
					camcf=cfAdd(camrot,pos+v3_0150+camcfLV*cammag)
					cframes[rootpart]=cfr
					insSet(cam,"CFrame",camcf)
					lerpsIdle()
					noYvelTime=min(noYvelTime+delta*0.3,1)
					xzvel=xzvel*(1-noYvelTime)
				elseif Yvel>0 then
					pos=pos+v3_010*Yvel*delta
					cfr=cfAdd(cfGet(cfr,"Rotation"),pos)
					camcf=cfAdd(camrot,pos+v3_0150+camcfLV*cammag)
					cframes[rootpart]=cfr
					insSet(cam,"CFrame",camcf)
					lerpsJump()
					noYvelTime=0
				else
					pos=pos+v3_010*Yvel*delta
					cfr=cfAdd(cfGet(cfr,"Rotation"),pos)
					camcf=cfAdd(camrot,pos+v3_0150+camcfLV*cammag)
					cframes[rootpart]=cfr
					insSet(cam,"CFrame",camcf)
					lerpsFall()
					noYvelTime=0
				end
			end
		end

		refreshjointsI(rootpart)
		tclear(refreshedjoints)

		local sine15=sine*15
		local idlerv=v3(sin(sine15),sin(sine15+1.0471975511965976),sin(sine15+2.0943951023931953))
		local idleoff=idlerv*0.003910064697265625 --0.0156402587890625/4

		local claimpos=insGet(primarypart,"Position")

		for i,v in next,cframes do
			local part=i.p
			--if invisible then
			--v=cfAdd(v,invisibleoffset)
			--end
			if part then
				if (insGet(part,"ReceiveAge")==0) and not GetJoints(part)[1] then
					local placeholder=i.v
					local vpos=cfGet(v,"Position")
					if novoid and (v3Get(vpos,"Y")<novoid) then
						v=cfAdd(v,v3_010*(novoid-v3Get(vpos,"Y")))
					end
					local lastpos=i.l
					local vel=(vpos-lastpos)/delta
					local mag=vmagnitude(vel)
					if mag<0.11730194091796875 then --0.0156402587890625*15/2
						if placeholder and i.b then
							insSet(placeholder,"Parent",nil)
							i.b=false
						end
						i.l=cfGet(v,"Position")
						v=cfAdd(v,idleoff)
					elseif mag>speedlimit then
						if placeholder then
							insSet(placeholder,"CFrame",v)
							if not i.b then
								insSet(placeholder,"Parent",ws)
								i.b=true
							end
						end
						vel=vnormalize(vel)*speedlimit
						local newpos=lastpos+vel*delta
						v=cfAdd(cfGet(v,"Rotation"),newpos)
						i.l=newpos
					else
						if placeholder and i.b then
							insSet(placeholder,"Parent",nil)
							i.b=false
						end
						i.l=cfGet(v,"Position")
					end
					local claimtime=i.c
					if claimtime then
						if (sine-claimtime)<retVelTime then
							local offsetToPrimaryPart=claimpos-cfGet(v,"Position")
							local a=625.5001+wsGravity*-2*v3Get(offsetToPrimaryPart,"Y")
							if a>0 then --part can reach primary part
								insSet(part,"AssemblyLinearVelocity",v3_net+offsetToPrimaryPart*v3_101/((25.01+sqrt(a))/wsGravity))
							else --part cant reach primary part so at least aim for closest point
								insSet(part,"AssemblyLinearVelocity",v3_net+offsetToPrimaryPart*v3_101/(30.010999900019996/wsGravity))
							end
						else
							local vel1=vel*noYvelTime+xzvel
							if vmagnitude(vel1)>25.01 then
								insSet(part,"AssemblyLinearVelocity",vnormalize(vel1)*v3_xzL+v3_net)
							else
								insSet(part,"AssemblyLinearVelocity",vel1*v3_xz+v3_net)
							end
						end
					else
						i.c=sine
						local vel1=vel*noYvelTime+xzvel
						if vmagnitude(vel1)>25.01 then
							insSet(part,"AssemblyLinearVelocity",vnormalize(vel1)*v3_xzL+v3_net)
						else
							insSet(part,"AssemblyLinearVelocity",vel1*v3_xz+v3_net)
						end
					end
					insSet(part,"CFrame",v)
					insSet(part,"AssemblyAngularVelocity",idlerv)
				else
					i.c=nil
					i.l=insGet(part,"Position")
					local placeholder=i.v
					if placeholder then
						insSet(placeholder,"CFrame",v)
						if not i.b then
							insSet(placeholder,"Parent",ws)
							i.b=true
						end
					end
				end
			else
				local placeholder=i.v
				if placeholder then
					insSet(placeholder,"CFrame",v)
					if not i.b then
						insSet(placeholder,"Parent",ws)
						i.b=true
					end
				end
			end
		end

		setsimrad()
	end

	sine=osclock()
	lastsine=sine
	tinsert(cons,Connect(heartbeat,mainFunction))
	mainFunction()

	local refreshjoints=function(v) --use this on the main part if u have parts that
		refreshjointsI(v) --are connected with each other but arent connected to rootpart
		tclear(refreshedjoints)
	end

	local legcfR=cf(1,-1,0)
	local legcfL=cf(-1,-1,0)
	local raydir=v3_010*-2
	local raycastlegs=function() --this returns 2 values: right leg raycast offset, left leg raycast offset
		local rY=Raycast(ws,cfGet(cfMul(cfr,legcfR),"Position"),raydir,raycastparams)
		local lY=Raycast(ws,cfGet(cfMul(cfr,legcfL),"Position"),raydir,raycastparams)
		if rY then
			if lY then
				return v3Get(rY.Position,"Y")-(v3Get(pos,"Y")-3),v3Get(lY.Position,"Y")-(v3Get(pos,"Y")-3)
			else
				return v3Get(rY.Position,"Y")-(v3Get(pos,"Y")-3),0
			end
		elseif lY then
			return 0,v3Get(lY.Position,"Y")-(v3Get(pos,"Y")-3)
		else
			return 0,0
		end
	end

	local velbycfrvec=function() --this returns 2 values: forward/backwards movement (from -1 to 1), right/left movement (from -1 to 1)
		local fw=cfGet(cfr,"LookVector")*xzvel/walkSpeed
		local rt=cfGet(cfr,"RightVector")*xzvel/walkSpeed
		return v3Get(fw,"X")+v3Get(fw,"Z"),v3Get(rt,"X")+v3Get(rt,"Z")
	end

	local lastvel=v3_0
	local velchg1=v3_0
	local velchgbycfrvec=function() --this returns 2 values: forward/backwards velocity change, right/left velocity change
		velchg1=velchg1+(lastvel-xzvel) --i recommend setting velchg1 to v3_0 when u start using this function or it will look worse
		lastvel=xzvel
		velchg1=velchg1-velchg1*(deltaTime/2)
		local fw=cfGet(cfr,"LookVector")*velchg1/32
		local rt=cfGet(cfr,"RightVector")*velchg1/32
		return v3Get(fw,"X")+v3Get(fw,"Z"),v3Get(rt,"X")+v3Get(rt,"Z")
	end

	local lastYvel=0
	local velYchg1=0
	local velYchg=function() --this returns Y axis velocity change
		velYchg1=clamp(velYchg1+(lastYvel-Yvel),-50,50) --i recommend setting velYchg1 to 0 when u start using this function or it will look worse
		lastYvel=Yvel
		velYchg1=velYchg1-velYchg1*(deltaTime/2)
		return velYchg1
	end

	local rotToMouse=function(alpha) --this rotates ur character towards your mouse hit position
		local pos1=pos*v3_010+cfGet(insGet(mouse,"Hit"),"Position")*v3_101
		if pos~=pos1 then --could make nan rotation
			cfr=Lerp(cfr,cfl(pos,pos1),alpha or deltaTime)
		end
	end

	local glitchJoint=function(joint,targetGlitchTime,delayFrom,delayTo,radiansFrom,radiansTo) 
		if sine>targetGlitchTime then --example usage: local glitchtime=0 addMode("x",{idle=function() glitchtime=glitchJoint(joint,glitchtime,0.2,0.4,-0.1,0.1) end})
			radiansFrom=radiansFrom*100
			radiansTo=radiansTo*100
			joint.C0=cfMul(joint.C0,angles(mrandom(radiansFrom,radiansTo)/100,mrandom(radiansFrom,radiansTo)/100,mrandom(radiansFrom,radiansTo)/100)) 
			return sine+mrandom(delayFrom*100,delayTo*100)/100
		end
		return targetGlitchTime
	end

	local setWalkSpeed=function(n)
		if type(n)~="number" then
			n=16
		end
		walkSpeed=n
	end
	local setJumpPower=function(n)
		if type(n)~="number" then
			n=50
		end
		jumpPower=n
	end
	local setGravity=function(n)
		if type(n)~="number" then
			n=196.2
		end
		gravity=n
	end
	local setCfr=function(v) --sets character cframe
		if typeof(v)=="CFrame" then
			local newpos=cfGet(v,"Position")
			camcf=cfAdd(camcf,newpos-pos)
			insSet(cam,"CFrame",camcf)
			cfr=v
			pos=newpos
		elseif typeof(v)=="Vector3" then
			camcf=cfAdd(camcf,v-pos)
			insSet(cam,"CFrame",camcf)
			cfr=cfAdd(cfGet(cfr,"Rotation"),v)
			pos=v
		end
	end
	local getVel=function() --returns character velocity
		return xzvel+v3_010*Yvel --important: use only in lerps or it might not work
	end
	local getCamCF=function() --returns camera cframe
		return camcf
	end
	local isFirstPerson=function() --returns true if user is in first person camera mode
		return firstperson
	end
	local setCameraMoveable=function(b) --prevents the player from moving his camera
		cameraMoveable=b
	end
	local isOnGround=function()
		return onground
	end
	local isWalking=function()
		return isWalking
	end
	local YvelSign=function()
		return Yvel>0
	end

	return {
		cframes=cframes,
		joints=joints,
		fling=fling,
		predictionfling=fling,
		refreshjoints=refreshjoints,
		raycastlegs=raycastlegs,
		velbycfrvec=velbycfrvec,
		velchgbycfrvec=velchgbycfrvec,
		velYchg=velYchg,
		addmode=addmode,
		getPart=getPart,
		getPartFromMesh=getPartFromMesh,
		getAccWeldFromMesh=getAccWeldFromMesh,
		getJoint=getJoint,
		getPartJoint=getPartJoint,
		rotToMouse=rotToMouse,
		glitchJoint=glitchJoint,
		setWalkSpeed=setWalkSpeed,
		setJumpPower=setJumpPower,
		setGravity=setGravity,
		setCfr=setCfr,
		getVel=getVel,
		getCamCF=getCamCF,
		isFirstPerson=isFirstPerson,
		setHipHeight=setHipHeight,
		characters=characters,
		refreshrayfilter=function()
			for i,v in next,characters do
				if i==v then
					pcall(insSet,QueryDescendants(i,">BasePart#HumanoidRootPart")[1],"Anchored",true)
				end
			end
			refreshrayfilter()
		end,
		setCameraMoveable=setCameraMoveable,
		isOnGround=isOnGround,
		isWalking=isWalking,
		YvelSign=YvelSign
	}
end

-- gp backwards compatibility \240\159\151\191
local gp=function(p,n,c)
	return QueryDescendants(p,">"..c.."[Name=\""..n.."\"]")[1]
end

-- again no need to load the whole thing cuz u can use the last one
_G.GenesisFDless={reanimate=reanimate,stopreanimate=stopreanimate,gp=gp,rs=rs,insSet=insSet,insGet=insGet,cfMul=cfMul,mouse=mouse,isReanimated=function() return c end}
return _G.GenesisFDless
end
__fdless()
end


----------------------------------------------------------------------------------------------------
-- runtime setup
----------------------------------------------------------------------------------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

if not game:IsLoaded() then game.Loaded:Wait() end

local plr = Players.LocalPlayer
Player = plr
local mouse = plr:GetMouse()
local cam = workspace.CurrentCamera

local function notify(text, dur)
	hubNotify("Neptunian", text, "info", dur)
end

-- running it twice? clean the previous run first
do
	local old = _G.NeptunianFDless
	if type(old) == "table" and type(old.cleanup) == "function" then
		pcall(old.cleanup)
	end
end
local NEP = {conns = {}, alive = true}
_G.NeptunianFDless = NEP
local function track(c) NEP.conns[#NEP.conns + 1] = c return c end

-- assets (music): downloaded in the background so the script starts instantly ---------------------
local ASSET_DIR = CONFIG.AssetFolder
local ASSET_URL = "https://github.com/Jskfhggjxu/nep-remake-tory-assets/blob/main/"
local ASSET_FILES = {
	["Neptunian V.mp3"] = "Neptunian%20V.mp3",
	["censored.mp3"] = "censored.mp3",
	["CRAZED.mp3"] = "CRAZED.mp3",
	["BloodDrain_Again.mp3"] = "BloodDrain_Again.mp3",
	["BigBlack.mp3"] = "BigBlack.mp3",
}
pcall(function() if not isfolder(ASSET_DIR) then makefolder(ASSET_DIR) end end)
local function haveAsset(name)
	local ok, has = pcall(isfile, ASSET_DIR .. "/" .. name)
	return ok and has
end
local function getAsset(name)
	if not haveAsset(name) then return "" end
	local ok, res = pcall(function() return getcustomasset(ASSET_DIR .. "/" .. name) end)
	if ok and res then return res end
	return ""
end
local function fetchAsset(name)
	if haveAsset(name) then return true end
	local okd, content = pcall(function() return game:HttpGet(ASSET_URL .. ASSET_FILES[name] .. "?raw=true") end)
	if okd and content and #content > 0 then
		pcall(writefile, ASSET_DIR .. "/" .. name, content)
		return true
	end
	warn("[Neptunian] could not download " .. name)
	return false
end
-- sets kan.SoundId as soon as the file is available (downloads it first if needed)
function NEP_track(name)
	task.spawn(function()
		if fetchAsset(name) and NEP.alive and kan then
			kan.SoundId = getAsset(name)
		end
	end)
end
task.spawn(function()
	for name in pairs(ASSET_FILES) do
		if not NEP.alive then return end
		fetchAsset(name)
	end
end)

-- sword accessory: the Corrupt Demonic Greatsword you already wear --------------------------------------
-- (no server command is used; the hat has to be on your character before / while the script runs)
local function swordDefFor(name)
	name = tostring(name):lower()
	for _, def in ipairs(SWORDS) do
		for _, w in ipairs(def.words) do
			if name:find(w, 1, true) then return def end
		end
	end
	if CONFIG.SwordAccessoryName ~= "" and name == CONFIG.SwordAccessoryName:lower() then return SWORDS[1] end
	return nil
end

local char0 = plr.Character or plr.CharacterAdded:Wait()
local chosen = nil          -- {acc, handle, md, size, def, key}

local function hubSword(md, name)
	local A = ((typeof(getgenv) == "function" and getgenv()) or _G).AtsukoAlignment
	if type(A) ~= "table" or type(A.match) ~= "function" then
		return nil
	end
	local ok, row = pcall(A.match, "Neptunian V", "sword", {mesh = md, name = name})
	if ok and type(row) == "table" and row.src == "user" then
		return SWORDS[1]
	end
	return nil
end

local function handleInfo(acc)
	local h = acc:FindFirstChild("Handle")
	if not h or not h:IsA("BasePart") then return nil end
	local mid
	if h:IsA("MeshPart") then
		mid = h.MeshId
	else
		local sm = h:FindFirstChildOfClass("SpecialMesh")
		if sm then mid = sm.MeshId end
	end
	local md = mid and tostring(mid):match("(%d+)%s*$") or nil
	local back = false
	for _, a in ipairs(h:GetChildren()) do
		if a:IsA("Attachment") and a.Name:lower():find("back", 1, true) then back = true end
	end
	local def = swordDefFor(acc.Name) or hubSword(md, acc.Name)
	return {acc = acc, handle = h, md = md, size = h.Size.Magnitude, back = back, def = def, key = def and def.key}
end

local function pickSword()
	local best, bestScore = nil, 0
	local seen = {}
	for _, c in ipairs({plr.Character, char0}) do
		if c and not seen[c] then
			seen[c] = true
			for _, acc in ipairs(c:GetChildren()) do
				if acc:IsA("Accessory") then
					local info = handleInfo(acc)
					if info then
						local score = 0
						if info.def then score = score + 100 end
						if CONFIG.SwordMeshId ~= "" and info.md == tostring(CONFIG.SwordMeshId) then score = score + 100 end
						if info.back then score = score + 10 end
						if info.size > 4 then score = score + 20 end
						if info.size > 7 then score = score + 10 end
						if score > bestScore then best, bestScore = info, score end
					end
				end
			end
		end
	end
	if bestScore >= 100 or bestScore >= 30 then return best end
	return nil
end

-- every recognised sword that is worn (in SWORDS order)
local function scanSwords()
	local out, seen = {}, {}
	for _, c in ipairs({plr.Character, char0}) do
		if c then
			for _, acc in ipairs(c:GetChildren()) do
				if acc:IsA("Accessory") then
					local info = handleInfo(acc)
					if info and info.def and not seen[info.handle] then
						seen[info.handle] = true
						out[#out + 1] = info
					end
				end
			end
		end
	end
	local order = {}
	for i, def in ipairs(SWORDS) do order[def.key] = i end
	table.sort(out, function(a, b) return order[a.key] < order[b.key] end)
	return out
end

function NEP_applySwordKey(key)
	NEP.swordKey = key
	if NEP_setSwordKey then NEP_setSwordKey(key) end
end

-- pick it BEFORE FDless takes the character over
chosen = pickSword()
local swordCache = scanSwords()
if chosen and chosen.key then NEP_applySwordKey(chosen.key) end

-- start FDless right away ------------------------------------------------------------------------------
local FD = _G.GenesisFDless
pcall(FD.stopreanimate)
local RE = FD.reanimate()
if type(RE) ~= "table" then
	notify("FDless could not start.")
	return
end
local cframes = RE.cframes

local swordJoint = nil

local function findTracked()
	if not chosen then return nil end
	local okc, res = pcall(function()
		for t in pairs(RE.cframes) do
			if type(t) == "table" and t.m then
				local byPart = chosen.handle and t.p == chosen.handle
				local byMesh = chosen.md and tostring(t.m):find(chosen.md, 1, true)
				if byPart or byMesh then
					for _, j in ipairs(RE.joints) do
						if j.Part0 == t then return j end
					end
				end
			end
		end
		return nil
	end)
	if okc then return res end
	return nil
end

-- background watcher: finds the greatsword, attaches it, keeps trying for a while ----------------------
function NEP_findSword(force)
	if force then chosen = nil end
	if NEP.finding then return end
	NEP.finding = true
	task.spawn(function()
		local t0 = os.clock()
		local warned, placeholder = false, false
		while NEP.alive and os.clock() - t0 < 90 do
			if not chosen then
				chosen = pickSword()
				if chosen and chosen.key then NEP_applySwordKey(chosen.key) end
			end
			if chosen then
				local j = findTracked()
				if j then
					swordJoint = j
					notify(((chosen.def and chosen.def.name) or "Sword") .. " attached.", 4)
					break
				end
				if not placeholder and chosen.md and os.clock() - t0 > 3 then
					placeholder = true
					local okj, pj = pcall(RE.getAccWeldFromMesh, chosen.md, "")
					if okj and pj and not swordJoint then swordJoint = pj end
				end
			end
			if not warned and os.clock() - t0 > 10 and not swordJoint then
				warned = true
				notify("Can't find a supported sword on you (Corrupt Demonic / Hacklords Venom Greatsword / The Beasthammer) - wear one, then tap Find sword or type /sword.", 8)
			end
			task.wait(0.3)
		end
		NEP.finding = false
	end)
end
NEP_findSword()

-- switch between the swords you are wearing (Sword button in the Align panel)
function NEP_cycleSword()
	local list = scanSwords()
	local have = {}
	for _, s in ipairs(list) do have[s.handle] = true end
	for _, s in ipairs(swordCache) do
		if not have[s.handle] then list[#list + 1] = s end
	end
	if #list == 0 then
		notify("No supported sword on your character - wear one, then tap Find sword.", 5)
		return
	end
	local idx = 0
	for i, s in ipairs(list) do
		if chosen and s.handle == chosen.handle then idx = i end
	end
	local nxt = list[idx % #list + 1]
	if chosen and nxt.handle == chosen.handle then
		notify("Only " .. nxt.def.name .. " is on you.", 4)
		return
	end
	chosen = nxt
	swordJoint = nil
	NEP_applySwordKey(nxt.key)
	NEP_findSword()
	notify("Using " .. nxt.def.name, 3)
end

-- R6 parts / joints of the FDless virtual rig ---------------------------------------------------------
local jRoot, jNeck = RE.getJoint("RootJoint"), RE.getJoint("Neck")
local jRS, jLS = RE.getJoint("Right Shoulder"), RE.getJoint("Left Shoulder")
local jRH, jLH = RE.getJoint("Right Hip"), RE.getJoint("Left Hip")
local FDP = {
	root = jRoot.Part0, torso = jRoot.Part1, head = jNeck.Part1,
	rarm = jRS.Part1, larm = jLS.Part1, rleg = jRH.Part1, lleg = jLH.Part1,
}
-- the limb script uses welds with 1.5 stud shoulders, so the shoulder joints are rebuilt that way
jRS.C0 = CFrame.new(1.5, 0.5, 0); jRS.C1 = CFrame.new(0, 0.5, 0)
jLS.C0 = CFrame.new(-1.5, 0.5, 0); jLS.C1 = CFrame.new(0, 0.5, 0)
local iRoot, iNeck = jRoot.C1:Inverse(), jNeck.C1:Inverse()
local iRS, iLS = jRS.C1:Inverse(), jLS.C1:Inverse()
local iRH, iLH = jRH.C1:Inverse(), jLH.C1:Inverse()

-- container for every effect + invisible stand-ins for the limbs ---------------------------------------
local function randName()
	local t = {}
	for i = 1, math.random(8, 14) do t[i] = string.char(math.random(97, 122)) end
	return table.concat(t)
end
local fx = Instance.new("Model")
fx.Name = randName()
fx.Parent = workspace
char = fx
Character = fx

local function standIn(name, size)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Transparency = 1
	p.Locked = true
	p.Parent = fx
	return p
end
root = standIn("HumanoidRootPart", Vector3.new(2, 2, 1))
tors = standIn("Torso", Vector3.new(2, 2, 1))
hed = standIn("Head", Vector3.new(2, 1, 1))
rarm = standIn("Right Arm", Vector3.new(1, 2, 1))
larm = standIn("Left Arm", Vector3.new(1, 2, 1))
rleg = standIn("Right Leg", Vector3.new(1, 2, 1))
lleg = standIn("Left Leg", Vector3.new(1, 2, 1))
Torso, Head, RootPart = tors, hed, root
RightArm, LeftArm, RightLeg, LeftLeg = rarm, larm, rleg, lleg
rl, ll, ra, la = rleg, lleg, rarm, larm
Root = root

-- humanoid stand-in: WalkSpeed / JumpPower go to FDless ----------------------------------------------
local humStore = {WalkSpeed = 16, JumpPower = 50, Health = 100, MaxHealth = 100, CameraOffset = Vector3.new(), PlatformStand = false, Jump = false}
hum = setmetatable({}, {
	__index = humStore,
	__newindex = function(_, k, v)
		humStore[k] = v
		if k == "WalkSpeed" and type(v) == "number" then
			RE.setWalkSpeed(v)
		elseif k == "JumpPower" and type(v) == "number" then
			RE.setJumpPower(v)
		end
	end,
})
Humanoid = hum
RE.setWalkSpeed(16)
RE.setJumpPower(50)

-- shorthand used all over the original code ------------------------------------------------------------
local it, vt, bc, br = Instance.new, Vector3.new, BrickColor.new, BrickColor.random
local cf, ceuler, euler, angles = CFrame.new, CFrame.fromEulerAnglesXYZ, CFrame.fromEulerAnglesXYZ, CFrame.Angles
local RootCF = euler(-1.57, 0, 3.14)
local necko = cf(0, 1, 0, -1, -0, -0, 0, 0, 1, 0, 1, 0)

-- logic joints: the animation code writes C0 here at a fixed 60Hz, the display copy is interpolated -------
local LJ = {}
local function mkLogic(fdj, c0)
	local L = {C0 = c0, p = c0, c = c0, fd = fdj}
	LJ[#LJ + 1] = L
	return L
end
local RW, LW = mkLogic(jRS, jRS.C0), mkLogic(jLS, jLS.C0)
local RH, LH = mkLogic(jRH, jRH.C0), mkLogic(jLH, jLH.C0)
local RootJoint, Neck = mkLogic(jRoot, jRoot.C0), mkLogic(jNeck, jNeck.C0)

-- scheduler: swait = wait N logic ticks (1 tick = 1/60 s, independent of the real frame rate) -------------
local TICK = 1 / 60
local tickCount = 0
local waiting = {}
function swait(num)
	local frames = 1
	if num and num > 0 then frames = math.floor(num) + 1 end
	waiting[#waiting + 1] = {coroutine.running(), tickCount + frames}
	coroutine.yield()
end

function so(id, par, vol, pit)
	coroutine.resume(coroutine.create(function()
		local sou = Instance.new("Sound", par or workspace)
		sou.Volume = vol
		sou.Pitch = pit or 1
		sou.SoundId = id
		swait()
		sou:Play()
		game:GetService("Debris"):AddItem(sou, 6)
	end))
end

-- frame independent lerp (CFrame:Lerp is a quaternion slerp, same maths as the old clerp) -----------------
function clerp(a, b, t)
	return a:Lerp(b, t)
end

-- weapon "weld" stand-in (the sword used to be welded to the torso / right arm) ------------------------------
local ww ={Part0 = tors, C0 = CFrame.new(), C1 = cf(-3, 0, -0.5) * CFrame.Angles(0, 0, math.rad(-40))}
ww.p, ww.c = ww.C1, ww.C1
local partToFD = {[root] = FDP.root, [tors] = FDP.torso, [hed] = FDP.head, [rarm] = FDP.rarm, [larm] = FDP.larm, [rleg] = FDP.rleg, [lleg] = FDP.lleg}
weaponweld = setmetatable({}, {
	__index = function(_, k) return ww[k] end,
	__newindex = function(_, k, v)
		if k == "Part0" and v ~= ww.Part0 then
			-- keep the sword exactly where it is when it changes hands (torso <-> right arm)
			local oldHolder = cframes[partToFD[ww.Part0]]
			local newHolder = cframes[partToFD[v]]
			if oldHolder and newHolder then
				local world = oldHolder * ww.C0 * ww.C1:Inverse()
				local c1 = world:Inverse() * newHolder * ww.C0
				ww.C1, ww.p, ww.c = c1, c1, c1
			end
			ww.Part0 = v
		else
			ww[k] = v
		end
	end,
})

-- tiny RbxUtility.Create replacement --------------------------------------------------------------------------
local function Create(className)
	return function(props)
		local o = Instance.new(className)
		local parent
		for k, v in pairs(props) do
			if k == "Parent" then
				parent = v
			elseif type(k) == "number" then
				v.Parent = o
			elseif k ~= "Events" then
				o[k] = v
			end
		end
		if parent then o.Parent = parent end
		return o
	end
end

-- fling through FDless ----------------------------------------------------------------------------------------
local flingDebounce = setmetatable({}, {__mode = "k"})
function NEP_fling(dude, force)
	if typeof(dude) ~= "Instance" or type(RE.fling) ~= "function" then return false end
	local model = dude
	if model:IsA("Humanoid") or model:IsA("BasePart") then model = model.Parent end
	if model and model:IsA("Accoutrement") then model = model.Parent end
	if not model or not model:IsA("Model") or model == plr.Character then return false end
	local now = os.clock()
	if not force and flingDebounce[model] and now - flingDebounce[model] < 1.5 then return false end
	flingDebounce[model] = now
	local ok, res = pcall(RE.fling, model)
	return ok and res == true
end

function NEP_setRoot(c)
	RE.setCfr(c)
	root.CFrame = c
end

-- globals the original code expects ---------------------------------------------------------------------------
attacktype = 1
cloaked = false
attack = false
attackdebounce = false
deb = false
equipped = false
combo = 0
mana = 0
attackmode = "none"
idle = 0
Anim = "Idle"
Effects = {}
sine = 0
change = 1
Speed = 16
rotVelY = 0
velNow = Vector3.new()


----------------------------------------------------------------------------------------------------
-- original helpers / effects / attacks
----------------------------------------------------------------------------------------------------

function CameraShake(Times, Power)
coroutine.resume(coroutine.create(function()
FV = Instance.new("BoolValue", Character)
FV.Name = "CameraShake"
for ShakeNum=1,Times do
swait()
local ef=Power
  if ef>=1 then
   Humanoid.CameraOffset = Vector3.new(math.random(-ef,ef),math.random(-ef,ef),math.random(-ef,ef))
  else
   ef=Power*10
   Humanoid.CameraOffset = Vector3.new(math.random(-ef,ef)/10,math.random(-ef,ef)/10,math.random(-ef,ef)/10)
  end	
end
Humanoid.CameraOffset = Vector3.new(0,0,0)
FV:Destroy()
end))
end

CamShake=function(Part,Distan,Power,Times) 
local de=Part.Position
for i,v in pairs(workspace:children()) do
 if v:IsA("Model") and v:findFirstChild("Humanoid") then
for _,c in pairs(v:children()) do
if c.ClassName=="Part" and (c.Position - de).magnitude < Distan then
local Noob=v.Humanoid
if Noob~=nil then
if Noob:FindFirstChild("CamShake")==nil then-- and Noob == Character then
--[[local ss=script.CamShake:clone()
ss.Parent=Noob
ss.Power.Value=Power
ss.Times.Value=Times
ss.Disabled=false]]
CameraShake(Times, Power)
end
end
end
end
end
end
end

function chatfunc(text,color,typet,font,timeex)
local chat = coroutine.wrap(function()
if Character:FindFirstChild("TalkingBillBoard")~= nil then
Character:FindFirstChild("TalkingBillBoard"):destroy()
end
local naeeym2 = Instance.new("BillboardGui",Character)
naeeym2.Size = UDim2.new(0,100,0,40)
naeeym2.StudsOffset = Vector3.new(0,3,0)
naeeym2.Adornee = Character.Head
naeeym2.Name = "TalkingBillBoard"
local tecks2 = Instance.new("TextLabel",naeeym2)
tecks2.BackgroundTransparency = 1
tecks2.BorderSizePixel = 0
tecks2.Text = ""
tecks2.Font = font
tecks2.TextSize = 30
tecks2.TextStrokeTransparency = 0
tecks2.TextColor3 = color
tecks2.TextStrokeColor3 = Color3.new(0,0,0)
tecks2.Size = UDim2.new(1,0,0.5,0)
local tecks3 = Instance.new("TextLabel",naeeym2)
tecks3.BackgroundTransparency = 1
tecks3.BorderSizePixel = 0
tecks3.Text = ""
tecks3.Font = font
tecks3.TextSize = 30
tecks3.TextStrokeTransparency = 0
if typet == "Inverted" then
tecks3.TextColor3 = Color3.new(0,0,0)
tecks3.TextStrokeColor3 = color
elseif typet == "Normal" then
tecks3.TextColor3 = color
tecks3.TextStrokeColor3 = Color3.new(0,0,0)
end
tecks3.Size = UDim2.new(1,0,0.5,0)
coroutine.resume(coroutine.create(function()
while true do
swait(1)
if chaosmode == true then
tecks2.TextColor3 = BrickColor.random().Color
tecks3.TextStrokeColor3 = BrickColor.random().Color
end
end
end))
for i = 0, 74*timeex do
swait()
tecks2.Text = text
tecks3.Text = text
end
local randomrot = math.random(1,2)
if randomrot == 1 then
for i = 1, 50 do
swait()
tecks2.Text = text
tecks3.Text = text
tecks2.TextStrokeTransparency = tecks2.TextStrokeTransparency +.04
tecks2.TextTransparency = tecks2.TextTransparency + .04
tecks3.TextStrokeTransparency = tecks2.TextStrokeTransparency +.04
tecks3.TextTransparency = tecks2.TextTransparency + .04
end
elseif randomrot == 2 then
	for i = 1, 50 do
swait()
tecks2.Text = text
tecks3.Text = text
tecks2.TextStrokeTransparency = tecks2.TextStrokeTransparency +.04
tecks2.TextTransparency = tecks2.TextTransparency + .04
tecks3.TextStrokeTransparency = tecks2.TextStrokeTransparency +.04
tecks3.TextTransparency = tecks2.TextTransparency + .04
end
end
naeeym2:Destroy()
end)
chat()
end

CFuncs = {	
	["Part"] = {
		Create = function(Parent, Material, Reflectance, Transparency, BColor, Name, Size)
			local Part = Create("Part"){
				Parent = Parent,
				Reflectance = Reflectance,
				Transparency = Transparency,
				CanCollide = false,
				Locked = true,
				BrickColor = BrickColor.new(tostring(BColor)),
				Name = Name,
				Size = Size,
				Material = Material,
			}
			RemoveOutlines(Part)
			return Part
		end;
	};
	
	["Mesh"] = {
		Create = function(Mesh, Part, MeshType, MeshId, OffSet, Scale)
			local Msh = Create(Mesh){
				Parent = Part,
				Offset = OffSet,
				Scale = Scale,
			}
			if Mesh == "SpecialMesh" then
				Msh.MeshType = MeshType
				Msh.MeshId = MeshId
			end
			return Msh
		end;
	};
	
	["Mesh"] = {
		Create = function(Mesh, Part, MeshType, MeshId, OffSet, Scale)
			local Msh = Create(Mesh){
				Parent = Part,
				Offset = OffSet,
				Scale = Scale,
			}
			if Mesh == "SpecialMesh" then
				Msh.MeshType = MeshType
				Msh.MeshId = MeshId
			end
			return Msh
		end;
	};
	
	["Weld"] = {
		Create = function(Parent, Part0, Part1, C0, C1)
			local Weld = Create("Weld"){
				Parent = Parent,
				Part0 = Part0,
				Part1 = Part1,
				C0 = C0,
				C1 = C1,
			}
			return Weld
		end;
	};

	["Sound"] = {
		Create = function(id, par, vol, pit) 
			coroutine.resume(coroutine.create(function()
				local S = Create("Sound"){
					Volume = vol,
					Pitch = pit or 1,
					SoundId = id,
					Parent = par or workspace,
				}
				wait() 
				S:play() 
				game:GetService("Debris"):AddItem(S, 10)
			end))
		end;
	};

["LongSound"] = {
		Create = function(id, par, vol, pit) 
			coroutine.resume(coroutine.create(function()
				local S = Create("Sound"){
					Volume = vol,
					Pitch = pit or 1,
					SoundId = id,
					Parent = par or workspace,
				}
				wait() 
				S:play() 
				game:GetService("Debris"):AddItem(S, 30)
			end))
		end;
	};
	
	["ParticleEmitter"] = {
		Create = function(Parent, Color1, Color2, LightEmission, Size, Texture, Transparency, ZOffset, Accel, Drag, LockedToPart, VelocityInheritance, EmissionDirection, Enabled, LifeTime, Rate, Rotation, RotSpeed, Speed, VelocitySpread)
			local fp = Create("ParticleEmitter"){
				Parent = Parent,
				Color = ColorSequence.new(Color1, Color2),
				LightEmission = LightEmission,
				Size = Size,
				Texture = Texture,
				Transparency = Transparency,
				ZOffset = ZOffset,
				Acceleration = Accel,
				Drag = Drag,
				LockedToPart = LockedToPart,
				VelocityInheritance = VelocityInheritance,
				EmissionDirection = EmissionDirection,
				Enabled = Enabled,
				Lifetime = LifeTime,
				Rate = Rate,
				Rotation = Rotation,
				RotSpeed = RotSpeed,
				Speed = Speed,
				VelocitySpread = VelocitySpread,
			}
			return fp
		end;
	};

	CreateTemplate = {
	
	};
}



New = function(Object, Parent, Name, Data)
	local Object = Instance.new(Object)
	for Index, Value in pairs(Data or {}) do
		Object[Index] = Value
	end
	Object.Parent = Parent
	Object.Name = Name
	return Object
end
local m = char
function CreateParta(parent,transparency,reflectance,material,brickcolor)
local p = Instance.new("Part")
p.TopSurface = 0
p.BottomSurface = 0
p.Parent = parent
p.Size = Vector3.new(0.05,0.05,0.05)
p.Transparency = transparency
p.Reflectance = reflectance
p.CanCollide = false
p.Locked = true
p.BrickColor = brickcolor
p.Material = material
return p
end

function CreateMesh(parent,meshtype,x1,y1,z1)
local mesh = Instance.new("SpecialMesh",parent)
mesh.MeshType = meshtype
mesh.Scale = Vector3.new(x1*20,y1*20,z1*20)
return mesh
end

function CreateSpecialMesh(parent,meshid,x1,y1,z1)
local mesh = Instance.new("SpecialMesh",parent)
mesh.MeshType = "FileMesh"
mesh.MeshId = meshid
mesh.Scale = Vector3.new(x1,y1,z1)
return mesh
end


function CreateSpecialGlowMesh(parent,meshid,x1,y1,z1)
local mesh = Instance.new("SpecialMesh",parent)
mesh.MeshType = "FileMesh"
mesh.MeshId = meshid
mesh.TextureId = "http://www.roblox.com/asset/?id=269748808"
mesh.Scale = Vector3.new(x1,y1,z1)
mesh.VertexColor = Vector3.new(parent.BrickColor.r, parent.BrickColor.g, parent.BrickColor.b)
return mesh
end

function CreateWeld(parent,part0,part1,C1X,C1Y,C1Z,C1Xa,C1Ya,C1Za,C0X,C0Y,C0Z,C0Xa,C0Ya,C0Za)
local weld = Instance.new("Weld")
weld.Parent = parent
weld.Part0 = part0
weld.Part1 = part1
weld.C1 = CFrame.new(C1X,C1Y,C1Z)*CFrame.Angles(C1Xa,C1Ya,C1Za)
weld.C0 = CFrame.new(C0X,C0Y,C0Z)*CFrame.Angles(C0Xa,C0Ya,C0Za)
return weld
end
---- WEAPON OR STUFF
-- The sword itself is now the Corrupt Demonic Greatsword hat (positioned every frame in applyPose).
-- "rarmor" is the invisible anchor the old sword was welded to; effects, sounds and the trail still use it.
local rarmor = CreateParta(m,1,0,"SmoothPlastic",BrickColor.Random())
rarmor.Anchored = true
rarmor.CanQuery = false
rarmor.CanTouch = false
local A0 = Instance.new("Attachment",rarmor)
A0.Position = Vector3.new(-2.5,0.25,0)
local A1 = Instance.new("Attachment",rarmor)
A1.Position = Vector3.new(-7.5,0.4,0)
tl1 = Instance.new('Trail',rarmor)
tl1.Attachment0 = A0
tl1.Attachment1 = A1
tl1.Texture = "http://www.roblox.com/asset/?id=1978704853"
tl1.LightEmission = 1
tl1.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0),NumberSequenceKeypoint.new(1, 1)})
tl1.Color = ColorSequence.new(BrickColor.new('Royal purple').Color)
tl1.Lifetime = 0.6
tl1.Enabled = false

--------------- WINGS (anchored, positioned every frame relative to the torso)
local mainpart = CreateParta(m,1,0,"SmoothPlastic",BrickColor.Random())
mainpart.Anchored = true
mainpart.CanQuery = false
mainpart.CanTouch = false
local wingRel = {}
local function makeWing(sx, sy, sz, c1)
	local w = CreateParta(m,1,0,"Neon",BrickColor.new("Alder"))
	CreateMesh(w,"Wedge",sx,sy,sz)
	w.Anchored = true
	w.CanQuery = false
	w.CanTouch = false
	wingRel[#wingRel + 1] = {w, c1:Inverse()}
	return w
end
local wng1a = makeWing(0.1,4,4, CFrame.new(0,-2,-2.5)*CFrame.Angles(math.rad(0),math.rad(70),math.rad(5)))
local wng2a = makeWing(0.1,4,4, CFrame.new(0,-2,-2.5)*CFrame.Angles(math.rad(0),math.rad(-70),math.rad(-5)))
local wng1b = makeWing(0.1,1.5,3, CFrame.new(0,-1,-2.25)*CFrame.Angles(math.rad(180),math.rad(-110),math.rad(-5)))
local wng2b = makeWing(0.1,1.5,3, CFrame.new(0,-1,-2.25)*CFrame.Angles(math.rad(180),math.rad(110),math.rad(5)))
------

function lerp(object, newCFrame, alpha)
  return object:lerp(newCFrame, alpha)
end

function RemoveOutlines(part)
  part.TopSurface, part.BottomSurface, part.LeftSurface, part.RightSurface, part.FrontSurface, part.BackSurface = 10, 10, 10, 10, 10, 10
end
function CreatePart(Parent, Material, Reflectance, Transparency, BColor, Name, Size)
  local Part = Create("Part")({
    Parent = Parent,
    Reflectance = Reflectance,
    Transparency = Transparency,
    CanCollide = false,
    Locked = true,
    BrickColor = BrickColor.new(tostring(BColor)),
    Name = Name,
    Size = Size,
    Material = Material
  })
  Part.CustomPhysicalProperties = PhysicalProperties.new(0.001, 0.001, 0.001, 0.001, 0.001)
  RemoveOutlines(Part)
  return Part
end
function CreateMesh(Mesh, Part, MeshType, MeshId, OffSet, Scale)
  local Msh = Create(Mesh)({
    Parent = Part,
    Offset = OffSet,
    Scale = Scale
  })
  if Mesh == "SpecialMesh" then
    Msh.MeshType = MeshType
    Msh.MeshId = MeshId
  end
  return Msh
end
function CreateWeld(Parent, Part0, Part1, C0, C1)
  local Weld = Create("Weld")({
    Parent = Parent,
    Part0 = Part0,
    Part1 = Part1,
    C0 = C0,
    C1 = C1
  })
  return Weld
end
function NoOutline(Part)
Part.TopSurface,Part.BottomSurface,Part.LeftSurface,Part.RightSurface,Part.FrontSurface,Part.BackSurface = 10,10,10,10,10,10
end
function part(formfactor,parent,reflectance,transparency,brickcolor,name,size)
local fp=it("Part")
fp.formFactor=formfactor 
fp.Parent=parent
fp.Reflectance=reflectance
fp.Transparency=transparency
fp.CanCollide=false 
fp.Locked=true
fp.BrickColor=brickcolor
fp.Name=name
fp.Size=size
fp.Position=Torso.Position 
NoOutline(fp)
fp.Material="SmoothPlastic"
fp:BreakJoints()
return fp 
end 
 
function mesh(Mesh,part,meshtype,meshid,offset,scale)
local mesh=it(Mesh) 
mesh.Parent=part
if Mesh=="SpecialMesh" then
mesh.MeshType=meshtype
if meshid~="nil" then
mesh.MeshId="http://www.roblox.com/asset/?id="..meshid
end
end
mesh.Offset=offset
mesh.Scale=scale
return mesh
end
 
function weld(parent,part0,part1,c0)
local weld=it("Weld") 
weld.Parent=parent
weld.Part0=part0 
weld.Part1=part1 
weld.C0=c0
return weld
end
local function CFrameFromTopBack(at, top, back)
local right = top:Cross(back)
return CFrame.new(at.x, at.y, at.z,
right.x, top.x, back.x,
right.y, top.y, back.y,
right.z, top.z, back.z)
end

function Triangle(a, b, c)
local edg1 = (c-a):Dot((b-a).unit)
local edg2 = (a-b):Dot((c-b).unit)
local edg3 = (b-c):Dot((a-c).unit)
if edg1 <= (b-a).magnitude and edg1 >= 0 then
a, b, c = a, b, c
elseif edg2 <= (c-b).magnitude and edg2 >= 0 then
a, b, c = b, c, a
elseif edg3 <= (a-c).magnitude and edg3 >= 0 then
a, b, c = c, a, b
else
assert(false, "unreachable")
end
 
local len1 = (c-a):Dot((b-a).unit)
local len2 = (b-a).magnitude - len1
local width = (a + (b-a).unit*len1 - c).magnitude
 
local maincf = CFrameFromTopBack(a, (b-a):Cross(c-b).unit, -(b-a).unit)
 
local list = {}
 
if len1 > 0.01 then
local w1 = Instance.new('WedgePart', m)
game:GetService("Debris"):AddItem(w1,5)
w1.Material = "SmoothPlastic"
w1.FormFactor = 'Custom'
w1.BrickColor = BrickColor.new("Really red")
w1.Transparency = 0
w1.Reflectance = 0
w1.Material = "SmoothPlastic"
w1.CanCollide = false
local l1 = Instance.new("PointLight",w1)
l1.Color = Color3.new(170,0,0)
NoOutline(w1)
local sz = Vector3.new(0.2, width, len1)
w1.Size = sz
local sp = Instance.new("SpecialMesh",w1)
sp.MeshType = "Wedge"
sp.Scale = Vector3.new(0,1,1) * sz/w1.Size
w1:BreakJoints()
w1.Anchored = true
w1.Parent = workspace
w1.Transparency = 0.7
table.insert(Effects,{w1,"Disappear",.01})
w1.CFrame = maincf*CFrame.Angles(math.pi,0,math.pi/2)*CFrame.new(0,width/2,len1/2)
table.insert(list,w1)
end
 
if len2 > 0.01 then
local w2 = Instance.new('WedgePart', m)
game:GetService("Debris"):AddItem(w2,5)
w2.Material = "SmoothPlastic"
w2.FormFactor = 'Custom'
w2.BrickColor = BrickColor.new("Really red")
w2.Transparency = 0
w2.Reflectance = 0
w2.Material = "SmoothPlastic"
w2.CanCollide = false
local l2 = Instance.new("PointLight",w2)
l2.Color = Color3.new(170,0,0)
NoOutline(w2)
local sz = Vector3.new(0.2, width, len2)
w2.Size = sz
local sp = Instance.new("SpecialMesh",w2)
sp.MeshType = "Wedge"
sp.Scale = Vector3.new(0,1,1) * sz/w2.Size
w2:BreakJoints()
w2.Anchored = true
w2.Parent = workspace
w2.Transparency = 0.7
table.insert(Effects,{w2,"Disappear",.01})
w2.CFrame = maincf*CFrame.Angles(math.pi,math.pi,-math.pi/2)*CFrame.new(0,width/2,-len1 - len2/2)
table.insert(list,w2)
end
return unpack(list)
end
 

function Damagefunc(Part, hit, minim, maxim, knockback, Type, Property, Delay, HitSound, HitPitch)
  if hit.Parent == nil then
    return
  end
  if hit.Parent:FindFirstChild("Invincible") then
    return
  end
  local h = hit.Parent:FindFirstChildOfClass("Humanoid")
  for _, v in pairs(hit.Parent:children()) do
    if v:IsA("Humanoid") then
      h = v
      h.MaxHealth = 100
    end
  end
  local plr = game:GetService("Players").LocalPlayer
  if h ~= nil and hit.Parent.Name ~= plr.Name and hit.Parent:FindFirstChild("Torso") ~= nil or h ~= nil and hit.Parent.Name ~= plr.Name and hit.Parent:FindFirstChild("UpperTorso") ~= nil then
    if hit.Parent:findFirstChild("DebounceHit") ~= nil and hit.Parent.DebounceHit.Value == true then
      return
    end
    if HitSound ~= nil and HitPitch ~= nil then
      CFuncs.Sound.Create(HitSound, hit, 1, HitPitch)
    end
    local Damage = math.random(minim, maxim)
    local blocked = false
    local block = hit.Parent:findFirstChild("Block")
    if block ~= nil and block.className == "IntValue" and block.Value > 0 then
      blocked = true
      block.Value = block.Value - 1
    end
    local isFakeKill = false
    h.MaxHealth = 100
    if blocked == false then
      local nextHealth = h.Health - Damage
      if nextHealth <= 0 and h.Parent.Name ~= "Hologram" then
        h.Health = 1
        isFakeKill = true
        local inv = Instance.new("BoolValue")
        inv.Name = "Invincible"
        inv.Parent = hit.Parent
        game:GetService("Debris"):AddItem(inv, 2)
        dmg(h.Parent)
        coroutine.wrap(function()
            wait() 
            if h and h.Parent then
                h.Health = h.MaxHealth
            end
        end)()
      else
        h.Health = nextHealth
      end
      ShowDamage(Part.CFrame * CFrame.new(0, 0, Part.Size.Z / 2).p + Vector3.new(0, 1.5, 0), -Damage, 1.5, Part.BrickColor.Color)
    else
      local nextHealth = h.Health - (Damage / 2)
      if nextHealth <= 0 and h.Parent.Name ~= "Hologram" then
        h.Health = 1
        isFakeKill = true
        local inv = Instance.new("BoolValue")
        inv.Name = "Invincible"
        inv.Parent = hit.Parent
        game:GetService("Debris"):AddItem(inv, 2)
        dmg(h.Parent)
        coroutine.wrap(function()
            wait()
            if h and h.Parent then h.Health = h.MaxHealth end
        end)()
      else
        h.Health = nextHealth
      end
      ShowDamage(Part.CFrame * CFrame.new(0, 0, Part.Size.Z / 2).p + Vector3.new(0, 1.5, 0), -Damage, 1.5, Part.BrickColor.Color)
    end
    if isFakeKill then
        local debounce = Instance.new("BoolValue")
        debounce.Name = "DebounceHit"
        debounce.Parent = hit.Parent
        debounce.Value = true
        game:GetService("Debris"):AddItem(debounce, Delay)
        local c = Instance.new("ObjectValue")
        c.Name = "creator"
        c.Value = plr
        c.Parent = h
        game:GetService("Debris"):AddItem(c, 0.5)
        return 
    end
    if Type == "Knockdown" then
      local hum = hit.Parent.Humanoid
      hum.PlatformStand = true
      coroutine.resume(coroutine.create(function(HHumanoid)
        swait(1)
        if HHumanoid then HHumanoid.PlatformStand = false end
      end), hum)
    elseif Type == "Leech" then
      if hum ~= nil and hum.Health < hum.MaxHealth then
          hum.Health = hum.Health + 10
      end
    elseif Type == "UpKnock" then
      local hum = hit.Parent.Humanoid
      hum.PlatformStand = true
      coroutine.resume(coroutine.create(function(HHumanoid)
        swait(5)
        if HHumanoid then HHumanoid.PlatformStand = false end
      end), hum)
    elseif Type == "Freeze" then
      local targetTorso = hit.Parent:FindFirstChild("Torso") or hit.Parent:FindFirstChild("UpperTorso")
      if targetTorso then
          targetTorso.Anchored = true
          coroutine.resume(coroutine.create(function(Part)
            swait(1.5)
            if Part then Part.Anchored = false end
          end), targetTorso)
      end
    end
    local c = Instance.new("ObjectValue")
    c.Name = "creator"
    c.Value = plr
    c.Parent = h
    game:GetService("Debris"):AddItem(c, 0.5)
  end
end





function ShowDamage(Pos, Text, Time, Color)
  local Rate = 0.1
  local Pos = Pos or Vector3.new(0, 0, 0)
  local Text = Text or ""
  local Time = Time or 2
  local Color = Color or Color3.new(1, 0, 1)
  local EffectPart = CreatePart(workspace, "SmoothPlastic", 0, 1, BrickColor.new(Color), "Effect", Vector3.new(0, 0, 0))
  EffectPart.Anchored = true
  local BillboardGui = Create("BillboardGui")({
    Size = UDim2.new(3, 0, 3, 0),
    Adornee = EffectPart,
    Parent = EffectPart
  })
  local TextLabel = Create("TextLabel")({
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 1, 0),
    Text = Text,
    TextColor3 = Color3.new(1,1,1),
    TextStrokeColor3 = Color3.new(0,0,0),
    TextStrokeTransparency = 0.25,
    TextScaled = true,
    Font = Enum.Font.Fantasy,
    TextSize = 24,
    Parent = BillboardGui
  })
  game.Debris:AddItem(EffectPart, Time + 0.1)
  EffectPart.Parent = game:GetService("Workspace")
  delay(0, function()
    local Frames = Time / Rate
    for Frame = 1, Frames do
      swait(Rate)
      local Percent = Frame / Frames
      TextLabel.Text = Text
      EffectPart.CFrame = CFrame.new(Pos) + Vector3.new(0, Percent*2, 0)
    end
    for Frame = 1, Frames do
      swait(Rate)
      local Percent = Frame / Frames
      TextLabel.Text = Text
    end
    for Frame = 1, Frames do
      swait(Rate)
      local Percent = Frame / Frames
      TextLabel.TextTransparency = Percent
      TextLabel.Text = Text
      TextLabel.TextStrokeTransparency = Percent
    end
    if EffectPart and EffectPart.Parent then
      EffectPart:Destroy()
    end
  end)
end

function MagniDamage(Part, magni, mindam, maxdam, knock, Type, Sound)
  for _, c in pairs(workspace:children()) do
    local hum = c:findFirstChildOfClass("Humanoid")
    if hum ~= nil then
      local head = c:findFirstChild("Torso")
      if head ~= nil then
        local targ = head.Position - Part.Position
        local mag = targ.magnitude
        if magni >= mag and c.Name ~= plr.Name then
          Damagefunc(head, head, mindam, maxdam, knock, Type, root, 0.1, "rbxassetid://" .. Sound, 1)
        end
      end
      local head = c:findFirstChild("UpperTorso")
      if head ~= nil then
        local targ = head.Position - Part.Position
        local mag = targ.magnitude
        if magni >= mag and c.Name ~= plr.Name then
          Damagefunc(head, head, mindam, maxdam, knock, Type, root, 0.1, "rbxassetid://" .. Sound, 1)
        end
      end
    end
  end
end


function rayCast(Pos, Dir, Max, Ignore)  -- Origin Position , Direction, MaxDistance , IgnoreDescendants
return game:service("Workspace"):FindPartOnRay(Ray.new(Pos, Dir.unit * (Max or 999.999)), Ignore) 
end 
----

function dmg(dude)
    if dude and dude.Name ~= plr.Name then
        local val = Instance.new("BoolValue", dude)
        val.Name = "IsHit"
        targetted = nil
        CFuncs["Sound"].Create("rbxassetid://62339698", char, 0.25, 0.285)
        coroutine.resume(coroutine.create(function()
            for i, v in pairs(dude:GetChildren()) do
                if v:IsA("Part") or v:IsA("MeshPart") then
                    coroutine.resume(coroutine.create(function()
                        if typeof(sphere2) == "function" then
                            for i = 0, 1 do
                                sphere2(1, "Add", v.CFrame * CFrame.Angles(math.rad(math.random(-360, 360)), math.rad(math.random(-360, 360)), math.rad(math.random(-360, 360))), vt(1, 1, 1), -0.01, 10, -0.01, BrickColor.new("Royal purple"), BrickColor.new("Royal purple").Color)
                            end
                        end
                        CFuncs["Sound"].Create("rbxassetid://763718160", v, 0.75, 1.1)
                        CFuncs["Sound"].Create("rbxassetid://782353443", v, 1, 1)
                    end))
                    NEP_fling(dude)
                end
            end
        end))
    end
end


function sphere(bonuspeed,type,pos,scale,value,color)
local type = type
local rng = Instance.new("Part", char)
        rng.Anchored = true
        rng.BrickColor = color
        rng.CanCollide = false
        rng.FormFactor = 3
        rng.Name = "Ring"
        rng.Material = "Neon"
        rng.Size = Vector3.new(1, 1, 1)
        rng.Transparency = 0
        rng.TopSurface = 0
        rng.BottomSurface = 0
        rng.CFrame = pos
        local rngm = Instance.new("SpecialMesh", rng)
        rngm.MeshType = "Sphere"
rngm.Scale = scale
if rainbowmode == true then
rng.Color = Color3.new(r/255,g/255,b/255)
end
local scaler2 = 1
if type == "Add" then
scaler2 = 1*value
elseif type == "Divide" then
scaler2 = 1/value
end
coroutine.resume(coroutine.create(function()
for i = 0,10/bonuspeed,0.1 do
swait()
if rainbowmode == true then
rng.Color = Color3.new(r/255,g/255,b/255)
end
if type == "Add" then
scaler2 = scaler2 - 0.01*value/bonuspeed
elseif type == "Divide" then
scaler2 = scaler2 - 0.01/value*bonuspeed
end
if chaosmode == true then
rng.BrickColor = BrickColor.random()
end
rng.Transparency = rng.Transparency + 0.01*bonuspeed
rngm.Scale = rngm.Scale + Vector3.new(scaler2*bonuspeed, scaler2*bonuspeed, scaler2*bonuspeed)
end
rng:Destroy()
end))
end

function sphere2(bonuspeed,type,pos,scale,value,value2,value3,color,color3)
local type = type
local rng = Instance.new("Part", char)
        rng.Anchored = true
        rng.BrickColor = color
        rng.Color = color3
        rng.CanCollide = false
        rng.FormFactor = 3
        rng.Name = "Ring"
        rng.Material = "Neon"
        rng.Size = Vector3.new(1, 1, 1)
        rng.Transparency = 0
        rng.TopSurface = 0
        rng.BottomSurface = 0
        rng.CFrame = pos
        local rngm = Instance.new("SpecialMesh", rng)
        rngm.MeshType = "Sphere"
rngm.Scale = scale
local scaler2 = 1
local scaler2b = 1
local scaler2c = 1
if type == "Add" then
scaler2 = 1*value
scaler2b = 1*value2
scaler2c = 1*value3
elseif type == "Divide" then
scaler2 = 1/value
scaler2b = 1/value2
scaler2c = 1/value3
end
coroutine.resume(coroutine.create(function()
for i = 0,10/bonuspeed,0.1 do
swait()
if type == "Add" then
scaler2 = scaler2 - 0.01*value/bonuspeed
scaler2b = scaler2b - 0.01*value/bonuspeed
scaler2c = scaler2c - 0.01*value/bonuspeed
elseif type == "Divide" then
scaler2 = scaler2 - 0.01/value*bonuspeed
scaler2b = scaler2b - 0.01/value*bonuspeed
scaler2c = scaler2c - 0.01/value*bonuspeed
end
rng.Transparency = rng.Transparency + 0.01*bonuspeed
rngm.Scale = rngm.Scale + Vector3.new(scaler2*bonuspeed, scaler2b*bonuspeed, scaler2c*bonuspeed)
end
rng:Destroy()
end))
end

function block(bonuspeed,type,pos,scale,value,value2,value3,color,color3)
local type = type
local rng = Instance.new("Part", char)
        rng.Anchored = true
        rng.BrickColor = color
        rng.Color = color3
        rng.CanCollide = false
        rng.FormFactor = 3
        rng.Name = "Ring"
        rng.Material = "Neon"
        rng.Size = Vector3.new(1, 1, 1)
        rng.Transparency = 0
        rng.TopSurface = 0
        rng.BottomSurface = 0
        rng.CFrame = pos
        local rngm = Instance.new("SpecialMesh", rng)
        rngm.MeshType = "Brick"
rngm.Scale = scale
local scaler2 = 1
local scaler2b = 1
local scaler2c = 1
if type == "Add" then
scaler2 = 1*value
scaler2b = 1*value2
scaler2c = 1*value3
elseif type == "Divide" then
scaler2 = 1/value
scaler2b = 1/value2
scaler2c = 1/value3
end
coroutine.resume(coroutine.create(function()
for i = 0,10/bonuspeed,0.1 do
swait()
if type == "Add" then
scaler2 = scaler2 - 0.01*value/bonuspeed
scaler2b = scaler2b - 0.01*value/bonuspeed
scaler2c = scaler2c - 0.01*value/bonuspeed
elseif type == "Divide" then
scaler2 = scaler2 - 0.01/value*bonuspeed
scaler2b = scaler2b - 0.01/value*bonuspeed
scaler2c = scaler2c - 0.01/value*bonuspeed
end
rng.CFrame = rng.CFrame*CFrame.Angles(math.rad(math.random(-360,360)),math.rad(math.random(-360,360)),math.rad(math.random(-360,360)))
rng.Transparency = rng.Transparency + 0.01*bonuspeed
rngm.Scale = rngm.Scale + Vector3.new(scaler2*bonuspeed, scaler2b*bonuspeed, scaler2c*bonuspeed)
end
rng:Destroy()
end))
end


-- first vector is Position
-- second vector is Orientation

function darkspin()
attack = true
hum.WalkSpeed = 16
hum.JumpPower = 0
CFuncs["Sound"].Create("rbxassetid://1368583274", root, 4.5, 1)
local bgui = Instance.new("BillboardGui",root)
bgui.Size = UDim2.new(25, 0, 25, 0)
local imgc = Instance.new("ImageLabel",bgui)
imgc.BackgroundTransparency = 1
imgc.ImageTransparency = 1
imgc.Size = UDim2.new(1,0,1,0)
imgc.Image = "rbxassetid://997291547"
imgc.ImageColor3 = Color3.new(0,0.5,1)
local imgc2 = imgc:Clone()
imgc2.Parent = bgui
imgc2.Position = UDim2.new(-0.5,0,-0.5,0)
imgc2.Size = UDim2.new(2,0,2,0)
imgc2.ImageColor3 = Color3.new(0.5,0,1)
for i = 0, 1, 0.1 do
		swait()
bgui.Size = bgui.Size - UDim2.new(0.25, 0, 0.25, 0)
hum.CameraOffset = vt(math.random(-10,10)/50,math.random(-10,10)/50,math.random(-10,10)/50)
	RH.C0=clerp(RH.C0,cf(1,-0.5,0)*angles(math.rad(0),math.rad(90),math.rad(0))*angles(math.rad(-3),math.rad(-40),math.rad(10)),.2)
LH.C0=clerp(LH.C0,cf(-1,-1,0)*angles(math.rad(0),math.rad(-90),math.rad(0))*angles(math.rad(-3),math.rad(1),math.rad(20)),.2)
RootJoint.C0=clerp(RootJoint.C0,RootCF*cf(0.1,0.2,-0.3)*angles(math.rad(10),math.rad(0),math.rad(50)),.3)
Neck.C0=clerp(Neck.C0,necko*angles(math.rad(5),math.rad(0),math.rad(-50)),.3)
RW.C0=clerp(RW.C0,cf(1.25,0.5,-0.65)*angles(math.rad(100),math.rad(0),math.rad(-23)),.3)
LW.C0=clerp(LW.C0,cf(-1.45,0.5,0.1)*angles(math.rad(110),math.rad(0),math.rad(-85)),.3)
weaponweld.C1=clerp(weaponweld.C1,cf(0,1,0)*angles(math.rad(0),math.rad(0),math.rad(0)),.3)
end
imgc.ImageTransparency = 1
hum.CameraOffset = vt(0,0,0)
for i = 0, 9 do
end
CFuncs["Sound"].Create("rbxassetid://430315987", root, 1.5, 1)
CFuncs["Sound"].Create("rbxassetid://1295446488", root, 3, 1)
for x = 0, 20 do
CFuncs["Sound"].Create("rbxassetid://200633281", rarmor, 1, 1.05)
CFuncs["Sound"].Create("rbxassetid://161006195", rarmor, 1.5, 1.025)
MagniDamage(tors, 10, 60,85, 0, "Normal",153092213)
CFuncs["Sound"].Create("rbxassetid://200632992", rarmor, 1.25, 1)
for i = 0, 1, 0.6 do
		swait()
NEP_setRoot(root.CFrame + root.CFrame.lookVector*6)
root.Velocity = vt(0,0,0)
	RH.C0=clerp(RH.C0,cf(1,-1,0)*angles(math.rad(0),math.rad(90),math.rad(0))*angles(math.rad(-3),math.rad(0),math.rad(0)),.2)
LH.C0=clerp(LH.C0,cf(-1,-1,0)*angles(math.rad(0),math.rad(-90),math.rad(0))*angles(math.rad(-3),math.rad(0),math.rad(0)),.2)
RootJoint.C0=clerp(RootJoint.C0,RootCF*cf(0,0,0.5)*angles(math.rad(0),math.rad(0),math.rad(90)),.3)
Neck.C0=clerp(Neck.C0,necko*angles(math.rad(4),math.rad(0),math.rad(-60)),.3)
RW.C0=clerp(RW.C0,cf(1.45,0.5,0.1)*angles(math.rad(90),math.rad(0),math.rad(90)),.3)
LW.C0=clerp(LW.C0,cf(-1.45,0.5,0.1)*angles(math.rad(90),math.rad(0),math.rad(-90)),.3)
weaponweld.C1=clerp(weaponweld.C1,cf(0,0,0)*angles(math.rad(90),math.rad(0),math.rad(-90)),.3)
end
CFuncs["Sound"].Create("rbxassetid://200632992", rarmor, 1.25, 1)
MagniDamage(tors, 10, 60,85, 0, "Normal",153092213)
for i = 0, 1, 0.6 do
		swait()
NEP_setRoot(root.CFrame + root.CFrame.lookVector*4)
root.Velocity = vt(0,0,0)
	RH.C0=clerp(RH.C0,cf(1,-1,0)*angles(math.rad(0),math.rad(90),math.rad(0))*angles(math.rad(-3),math.rad(0),math.rad(0)),.2)
LH.C0=clerp(LH.C0,cf(-1,-1,0)*angles(math.rad(0),math.rad(-90),math.rad(0))*angles(math.rad(-3),math.rad(0),math.rad(0)),.2)
RootJoint.C0=clerp(RootJoint.C0,RootCF*cf(0,0,0.5)*angles(math.rad(90),math.rad(0),math.rad(90)),.3)
Neck.C0=clerp(Neck.C0,necko*angles(math.rad(4),math.rad(0),math.rad(-60)),.3)
RW.C0=clerp(RW.C0,cf(1.45,0.5,0.1)*angles(math.rad(90),math.rad(0),math.rad(90)),.3)
LW.C0=clerp(LW.C0,cf(-1.45,0.5,0.1)*angles(math.rad(90),math.rad(0),math.rad(-90)),.3)
weaponweld.C1=clerp(weaponweld.C1,cf(0,0,0)*angles(math.rad(90),math.rad(0),math.rad(-90)),.3)
end
CFuncs["Sound"].Create("rbxassetid://200632992", rarmor, 1.25, 1)
MagniDamage(tors, 10, 60,85, 0, "Normal",153092213)
for i = 0, 1, 0.6 do
		swait()
NEP_setRoot(root.CFrame + root.CFrame.lookVector*5)
root.Velocity = vt(0,0,0)
	RH.C0=clerp(RH.C0,cf(1,-1,0)*angles(math.rad(0),math.rad(90),math.rad(0))*angles(math.rad(-3),math.rad(0),math.rad(0)),.2)
LH.C0=clerp(LH.C0,cf(-1,-1,0)*angles(math.rad(0),math.rad(-90),math.rad(0))*angles(math.rad(-3),math.rad(0),math.rad(0)),.2)
RootJoint.C0=clerp(RootJoint.C0,RootCF*cf(0,0,0.5)*angles(math.rad(180),math.rad(0),math.rad(90)),.3)
Neck.C0=clerp(Neck.C0,necko*angles(math.rad(4),math.rad(0),math.rad(-60)),.3)
RW.C0=clerp(RW.C0,cf(1.45,0.5,0.1)*angles(math.rad(90),math.rad(0),math.rad(90)),.3)
LW.C0=clerp(LW.C0,cf(-1.45,0.5,0.1)*angles(math.rad(90),math.rad(0),math.rad(-90)),.3)
weaponweld.C1=clerp(weaponweld.C1,cf(0,0,0)*angles(math.rad(90),math.rad(0),math.rad(-90)),.3)
end
CFuncs["Sound"].Create("rbxassetid://200632992", rarmor, 1.25, 1)
MagniDamage(tors, 10, 60,85, 0, "Normal",153092213)
for i = 0, 1, 0.6 do
		swait()
NEP_setRoot(root.CFrame + root.CFrame.lookVector*4)
root.Velocity = vt(0,0,0)
	RH.C0=clerp(RH.C0,cf(1,-1,0)*angles(math.rad(0),math.rad(90),math.rad(0))*angles(math.rad(-3),math.rad(0),math.rad(0)),.2)
LH.C0=clerp(LH.C0,cf(-1,-1,0)*angles(math.rad(0),math.rad(-90),math.rad(0))*angles(math.rad(-3),math.rad(0),math.rad(0)),.2)
RootJoint.C0=clerp(RootJoint.C0,RootCF*cf(0,0,0.5)*angles(math.rad(270),math.rad(0),math.rad(90)),.3)
Neck.C0=clerp(Neck.C0,necko*angles(math.rad(4),math.rad(0),math.rad(-60)),.3)
RW.C0=clerp(RW.C0,cf(1.45,0.5,0.1)*angles(math.rad(90),math.rad(0),math.rad(90)),.3)
LW.C0=clerp(LW.C0,cf(-1.45,0.5,0.1)*angles(math.rad(90),math.rad(0),math.rad(-90)),.3)
weaponweld.C1=clerp(weaponweld.C1,cf(0,0,0)*angles(math.rad(90),math.rad(0),math.rad(-90)),.3)
end
end
hum.WalkSpeed = 0
for i = 0, 5, 0.1 do
		swait()
	RH.C0=clerp(RH.C0,cf(1,-1,0)*angles(math.rad(0),math.rad(90),math.rad(0))*angles(math.rad(-3),math.rad(0),math.rad(-20)),.2)
LH.C0=clerp(LH.C0,cf(-1,-0.6,-0.5)*angles(math.rad(0),math.rad(-90),math.rad(0))*angles(math.rad(-3),math.rad(20),math.rad(-12)),.2)
RootJoint.C0=clerp(RootJoint.C0,RootCF*cf(0.1,0.2,-0.35)*angles(math.rad(10),math.rad(0),math.rad(-40)),.2)
Neck.C0=clerp(Neck.C0,necko*angles(math.rad(5),math.rad(0),math.rad(40)),.2)
RW.C0=clerp(RW.C0,cf(1.45,0.5,0)*angles(math.rad(90),math.rad(0),math.rad(110)),.2)
LW.C0=clerp(LW.C0,cf(-1.45,0.5,0)*angles(math.rad(45),math.rad(0),math.rad(-20)),.2)
weaponweld.C1=clerp(weaponweld.C1,cf(2,0,0)*angles(math.rad(90),math.rad(0),math.rad(-90)),.2)
end
bgui:Destroy()
attack = false
hum.WalkSpeed = Speed
hum.JumpPower = 50
end

function eightbitmegablade()
attack = true
hum.WalkSpeed = 0
hum.JumpPower = 0
CFuncs["Sound"].Create("rbxassetid://1368583274", larm, 4.5, 1.2)
local OverCut = false

coroutine.resume(coroutine.create(function()
while true do
swait()
if OverCut == false then
cam.CFrame = lerp(cam.CFrame, root.CFrame * cf(1, 1.5, -6) * ceuler(math.rad(10), math.rad(170), math.rad(-20)), 0.1)
else
break
end
end
end))
for i = 0, 4, 0.1 do
swait()
sphere2(5,"Add",larm.CFrame*CFrame.new(0,-1.5,0)*CFrame.Angles(math.rad(math.random(-360,360)),math.rad(math.random(-360,360)),math.rad(math.random(-360,360))),vt(1,1,1),-0.01,0.1,-0.01,BrickColor.new("Toothpaste"),BrickColor.new("Toothpaste").Color)
slash(math.random(20,40)/10,5,true,"Round","Add","Out",larm.CFrame*CFrame.new(0,-1.5,0)*CFrame.Angles(math.rad(math.random(-360,360)),math.rad(math.random(-360,360)),math.rad(math.random(-360,360))),vt(0.025,0.001,0.025),-0.025,BrickColor.new("White"))
RH.C0=clerp(RH.C0,cf(1,-1,0)*angles(math.rad(0),math.rad(90),math.rad(0))*angles(math.rad(-6),math.rad(0),math.rad(-6)),.3)
LH.C0=clerp(LH.C0,cf(-1,-1,0)*angles(math.rad(0),math.rad(-90),math.rad(0))*angles(math.rad(-3),math.rad(30),math.rad(3)),.3)
RootJoint.C0=clerp(RootJoint.C0,RootCF*cf(0,0,0)*angles(math.rad(0),math.rad(0),math.rad(-50)),.3)
Neck.C0=clerp(Neck.C0,necko*angles(math.rad(-15),math.rad(5),math.rad(50)),.3)
RW.C0=clerp(RW.C0,cf(1.45,0.5,0.1)*angles(math.rad(-13),math.rad(-40),math.rad(20)),.3)
LW.C0=clerp(LW.C0,cf(-1.45,0.5,0.1)*angles(math.rad(170),math.rad(10),math.rad(0)),.3)
weaponweld.C1=clerp(weaponweld.C1,cf(0,1,0)*angles(math.rad(0),math.rad(130),math.rad(0)),.3)
end
OverCut = true
local orb = Instance.new("Part", char)
orb.Anchored = true
orb.BrickColor = BrickColor.new("Toothpaste")
orb.CanCollide = false
orb.FormFactor = 3
orb.Name = "Ring"
orb.Material = "Neon"
orb.Size = Vector3.new(1, 1, 1)
orb.Transparency = 0.5
orb.TopSurface = 0
orb.BottomSurface = 0
local orbm = Instance.new("SpecialMesh", orb)
orbm.MeshType = "FileMesh"
orbm.MeshId = "rbxassetid://361629844"
orbm.Scale = vt(30,60,60)
orb.CFrame = root.CFrame*CFrame.new(0,50,0)
for i = 0, 24 do
end
CFuncs["Sound"].Create("rbxassetid://1368637781", orb, 7.5, 1)
local a = Instance.new("Part",workspace)
a.Name = "Direction"	
a.Anchored = true
a.Transparency = 1
a.CanCollide = false
local ray = Ray.new(
orb.CFrame.p,                           -- origin
(mouse.Hit.p - orb.CFrame.p).unit * 500 -- direction
) 
local ignore = orb
local hit, position, normal = workspace:FindPartOnRay(ray, ignore)
a.BottomSurface = 10
a.TopSurface = 10
local distance = (orb.CFrame.p - position).magnitude
a.Size = Vector3.new(0.1, 0.1, 0.1)
a.CFrame = CFrame.new(orb.CFrame.p, position) * CFrame.new(0, 0, 0)
orb.CFrame = a.CFrame
for i = 0, 7, 0.1 do
swait()
ray = Ray.new(
orb.CFrame.p,                           -- origin
(mouse.Hit.p - orb.CFrame.p).unit * 500 -- direction
) 
hit, position, normal = workspace:FindPartOnRay(ray, ignore)
distance = (orb.CFrame.p - position).magnitude
a.CFrame = CFrame.new(orb.CFrame.p, position) * CFrame.new(0, 0, 0)
orb.CFrame = a.CFrame
cam.CFrame = lerp(cam.CFrame, root.CFrame * cf(20, 65, 55) * ceuler(math.rad(-20), math.rad(0), math.rad(10)), 0.2)
RH.C0=clerp(RH.C0,cf(1,-1,0)*angles(math.rad(0),math.rad(90),math.rad(0))*angles(math.rad(-6),math.rad(0),math.rad(-6)),.3)
LH.C0=clerp(LH.C0,cf(-1,-1,0)*angles(math.rad(0),math.rad(-90),math.rad(0))*angles(math.rad(-3),math.rad(40),math.rad(3)),.3)
RootJoint.C0=clerp(RootJoint.C0,RootCF*cf(0,0,0)*angles(math.rad(0),math.rad(0),math.rad(-90)),.3)
Neck.C0=clerp(Neck.C0,necko*angles(math.rad(5),math.rad(0),math.rad(90)),.3)
RW.C0=clerp(RW.C0,cf(1.45,0.5,0.1)*angles(math.rad(-13),math.rad(-20),math.rad(20)),.3)
LW.C0=clerp(LW.C0,cf(-1.25,0.5,-0.5)*angles(math.rad(100),math.rad(0),math.rad(60)),.3)
weaponweld.C1=clerp(weaponweld.C1,cf(0,1,0)*angles(math.rad(0),math.rad(130),math.rad(0)),.3)
end

orb.Anchored = false
a:Destroy()
local bv = Instance.new("BodyVelocity")
bv.maxForce = Vector3.new(1e9, 1e9, 1e9)
bv.velocity = orb.CFrame.lookVector*250
bv.Parent = orb
local hitted = false
CFuncs["Sound"].Create("rbxassetid://466493476", orb, 7.5, 0.7)
waveEff(2,"Add","Out",orb.CFrame*CFrame.Angles(math.rad(90),math.rad(math.random(-360,360)),0),vt(5,1,5),0.5,0.1,BrickColor.new("Cyan"))
coroutine.resume(coroutine.create(function()
while true do
swait(2)
if hitted == false and orb.Parent ~= nil then
elseif hitted == true and orb.Parent == nil then
break
end
end
end))
orb.Touched:connect(function(hit) 
if hitted == false and hit.Parent ~= char then
hitted = true
MagniDamage(orb, 30, 72,95, 0, "Normal",153092213)
CFuncs["Sound"].Create("rbxassetid://763717897", orb, 10, 1)
CFuncs["Sound"].Create("rbxassetid://1295446488", orb, 9, 0.75)
for i = 0, 24 do
end
orb.Anchored = true
orb.Transparency = 1
coroutine.resume(coroutine.create(function()
for i = 0, 4, 0.1 do
swait()
hum.CameraOffset = vt(math.random(-10,10)/25,math.random(-10,10)/25,math.random(-10,10)/25)
end
hum.CameraOffset = vt(0,0,0)
end))
wait(10)
orb:Destroy()
end
end)
game:GetService("Debris"):AddItem(orb, 10)
for i = 0, 2, 0.1 do
swait()
RH.C0=clerp(RH.C0,cf(1,-1,0)*angles(math.rad(0),math.rad(90),math.rad(0))*angles(math.rad(-6),math.rad(0),math.rad(-6)),.3)
LH.C0=clerp(LH.C0,cf(-1,-1,0)*angles(math.rad(0),math.rad(-90),math.rad(0))*angles(math.rad(-3),math.rad(30),math.rad(3)),.3)
RootJoint.C0=clerp(RootJoint.C0,RootCF*cf(0,-0.4,0)*angles(math.rad(0),math.rad(0),math.rad(-70)),.3)
Neck.C0=clerp(Neck.C0,necko*angles(math.rad(5),math.rad(0),math.rad(70)),.3)
RW.C0=clerp(RW.C0,cf(1.45,0.5,0.1)*angles(math.rad(-13),math.rad(-40),math.rad(20)),.3)
LW.C0=clerp(LW.C0,cf(-1.45,0.5,0.1)*angles(math.rad(90),math.rad(0),math.rad(-80)),.3)
weaponweld.C1=clerp(weaponweld.C1,cf(0,1,0)*angles(math.rad(0),math.rad(130),math.rad(0)),.3)
end
attack = false
hum.WalkSpeed = Speed
hum.JumpPower = 50
end



function smack()
attack = true
hum.WalkSpeed = 3
hum.JumpPower = 0
CFuncs["Sound"].Create("rbxassetid://1368598393", rarmor, 2, 1)
CFuncs["Sound"].Create("rbxassetid://1368583274", rarmor, 2.5, 1)
for x = 0, 1 do
CFuncs["Sound"].Create("rbxassetid://200633108", rarmor, 2, 1.05)
CFuncs["Sound"].Create("rbxassetid://234365573", rarmor, 2.5, 1.025)
for i = 0, 1, 0.6 do
		swait()
	RH.C0=clerp(RH.C0,cf(1,-0.5,-0.5)*angles(math.rad(0),math.rad(90),math.rad(0))*angles(math.rad(-3),math.rad(0),math.rad(-10)),.2)
LH.C0=clerp(LH.C0,cf(-1,-1,0)*angles(math.rad(-55),math.rad(-90),math.rad(0))*angles(math.rad(-3),math.rad(30),math.rad(0)),.2)
RootJoint.C0=clerp(RootJoint.C0,RootCF*cf(0,0.25,0)*angles(math.rad(-60),math.rad(0),math.rad(-0)),.3)
Neck.C0=clerp(Neck.C0,necko*angles(math.rad(64),math.rad(0),math.rad(0)),.3)
RW.C0=clerp(RW.C0,cf(1.45,0.5,0.1)*angles(math.rad(90),math.rad(0),math.rad(80)),.3)
LW.C0=clerp(LW.C0,cf(-1.45,0.5,0.1)*angles(math.rad(90),math.rad(0),math.rad(-60)),.3)
weaponweld.C1=clerp(weaponweld.C1,cf(0,1,0)*angles(math.rad(0 + -0 * math.sin(sine / 0.5)),math.rad(-90 + -5 * math.sin(sine / 40)),math.rad(0 + -0.1 * math.sin(sine / 0.5))),.3)
end
end
wait(0.08)
local hitb = CreateParta(m,1,1,"SmoothPlastic",BrickColor.Random())
hitb.Anchored = true
hitb.CFrame = root.CFrame + root.CFrame.lookVector*8
hitb.CFrame = hitb.CFrame*CFrame.new(0,1,0)
MagniDamage(hitb, 8, 92,158, 0, "Normal",153092213)
for i = 0, 24 do
end
CFuncs["Sound"].Create("rbxassetid://313205954", root, 4,1)
CFuncs["Sound"].Create("rbxassetid://1368637781", rarmor, 4,1)
CFuncs["Sound"].Create("rbxassetid://763718160", rarmor, 5, 1.1)
CFuncs["Sound"].Create("rbxassetid://782353443", rarmor, 6, 1)
--CFuncs["Sound"].Create("rbxassetid://1548538202", rarmor, 4,1)
for i = 0, 2, 0.1 do
		swait()
MagniDamage(hitb, 8, 92,158, 0, "Normal",153092213)
hum.CameraOffset = vt(math.random(-10,10)/25,math.random(-10,10)/25,math.random(-10,10)/25)
	RH.C0=clerp(RH.C0,cf(1,-1,-0.5)*angles(math.rad(20),math.rad(90),math.rad(0))*angles(math.rad(-3),math.rad(-20),math.rad(-10)),.9)
LH.C0=clerp(LH.C0,cf(-1,-1,0)*angles(math.rad(15),math.rad(-90),math.rad(0))*angles(math.rad(-3),math.rad(0),math.rad(0)),.9)
RootJoint.C0=clerp(RootJoint.C0,RootCF*cf(0,-0.5,0)*angles(math.rad(30),math.rad(0),math.rad(0)),.9)
Neck.C0=clerp(Neck.C0,necko*angles(math.rad(10),math.rad(0),math.rad(0)),.9)
RW.C0=clerp(RW.C0,cf(1.45,0.5,0.1)*angles(math.rad(90),math.rad(0),math.rad(70)),.9)
LW.C0=clerp(LW.C0,cf(-1.45,0.5,0.1)*angles(math.rad(10),math.rad(0),math.rad(-60)),.9)
weaponweld.C1=clerp(weaponweld.C1,cf(0,1,0)*angles(math.rad(0 + -0 * math.sin(sine / 0.5)),math.rad(-90 + -5 * math.sin(sine / 40)),math.rad(0 + -0.1 * math.sin(sine / 0.5))),.3)
end
hum.CameraOffset = vt(0,0,0)
hitb:Destroy()
attack = false
hum.WalkSpeed = Speed
hum.JumpPower = 50
end


function sphereMK(bonuspeed,FastSpeed,type,pos,x1,y1,z1,value,color,color3,outerpos)
local type = type
local rng = Instance.new("Part", char)
        rng.Anchored = true
        rng.BrickColor = color
        rng.Color = color3
        rng.CanCollide = false
        rng.FormFactor = 3
        rng.Name = "Ring"
        rng.Material = "Neon"
        rng.Size = Vector3.new(1, 1, 1)
        rng.Transparency = 0
        rng.TopSurface = 0
        rng.BottomSurface = 0
        rng.CFrame = pos
rng.CFrame = rng.CFrame + rng.CFrame.lookVector*outerpos
        local rngm = Instance.new("SpecialMesh", rng)
        rngm.MeshType = "Sphere"
rngm.Scale = vt(x1,y1,z1)
if rainbowmode == true then
rng.Color = Color3.new(r/255,g/255,b/255)
end
local scaler2 = 1
local speeder = FastSpeed
if type == "Add" then
scaler2 = 1*value
elseif type == "Divide" then
scaler2 = 1/value
end
coroutine.resume(coroutine.create(function()
for i = 0,10/bonuspeed,0.1 do
swait()
if rainbowmode == true then
rng.Color = Color3.new(r/255,g/255,b/255)
end
if type == "Add" then
scaler2 = scaler2 - 0.01*value/bonuspeed
elseif type == "Divide" then
scaler2 = scaler2 - 0.01/value*bonuspeed
end
if chaosmode == true then
rng.BrickColor = BrickColor.random()
end
speeder = speeder - 0.01*FastSpeed*bonuspeed
rng.CFrame = rng.CFrame + rng.CFrame.lookVector*speeder*bonuspeed
rng.Transparency = rng.Transparency + 0.01*bonuspeed
rngm.Scale = rngm.Scale + Vector3.new(scaler2*bonuspeed, scaler2*bonuspeed, 0)
end
rng:Destroy()
end))
end

function waveEff(bonuspeed,type,typeoftrans,pos,scale,value,value2,color)
local type = type
local rng = Instance.new("Part", char)
        rng.Anchored = true
        rng.BrickColor = color
        rng.CanCollide = false
        rng.FormFactor = 3
        rng.Name = "Ring"
        rng.Material = "Neon"
        rng.Size = Vector3.new(1, 1, 1)
        rng.Transparency = 0
if typeoftrans == "In" then
rng.Transparency = 1
end
        rng.TopSurface = 0
        rng.BottomSurface = 0
        rng.CFrame = pos
        local rngm = Instance.new("SpecialMesh", rng)
        rngm.MeshType = "FileMesh"
rngm.MeshId = "rbxassetid://20329976"
rngm.Scale = scale
local scaler2 = 1
local scaler2b = 1
if type == "Add" then
scaler2 = 1*value
scaler2b = 1*value2
elseif type == "Divide" then
scaler2 = 1/value
scaler2b = 1/value2
end
local randomrot = math.random(1,2)
coroutine.resume(coroutine.create(function()
for i = 0,10/bonuspeed,0.1 do
swait()
if type == "Add" then
scaler2 = scaler2 - 0.01*value/bonuspeed
scaler2b = scaler2b - 0.01*value/bonuspeed
elseif type == "Divide" then
scaler2 = scaler2 - 0.01/value*bonuspeed
scaler2b = scaler2b - 0.01/value*bonuspeed
end
if randomrot == 1 then
rng.CFrame = rng.CFrame*CFrame.Angles(0,math.rad(5*bonuspeed/2),0)
elseif randomrot == 2 then
rng.CFrame = rng.CFrame*CFrame.Angles(0,math.rad(-5*bonuspeed/2),0)
end
if typeoftrans == "Out" then
rng.Transparency = rng.Transparency + 0.01*bonuspeed
elseif typeoftrans == "In" then
rng.Transparency = rng.Transparency - 0.01*bonuspeed
end
rngm.Scale = rngm.Scale + Vector3.new(scaler2*bonuspeed, scaler2b*bonuspeed, scaler2*bonuspeed)
end
rng:Destroy()
end))
end

function slash(bonuspeed,rotspeed,rotatingop,typeofshape,type,typeoftrans,pos,scale,value,color)
local type = type
local rotenable = rotatingop
local rng = Instance.new("Part", char)
        rng.Anchored = true
        rng.BrickColor = color
        rng.CanCollide = false
        rng.FormFactor = 3
        rng.Name = "Ring"
        rng.Material = "Neon"
        rng.Size = Vector3.new(1, 1, 1)
        rng.Transparency = 0
if typeoftrans == "In" then
rng.Transparency = 1
end
        rng.TopSurface = 0
        rng.BottomSurface = 0
        rng.CFrame = pos
        local rngm = Instance.new("SpecialMesh", rng)
        rngm.MeshType = "FileMesh"
if typeofshape == "Normal" then
rngm.MeshId = "rbxassetid://662586858"
elseif typeofshape == "Round" then
rngm.MeshId = "rbxassetid://662585058"
end
rngm.Scale = scale
local scaler2 = 1/10
if type == "Add" then
scaler2 = 1*value/10
elseif type == "Divide" then
scaler2 = 1/value/10
end
local randomrot = math.random(1,2)
coroutine.resume(coroutine.create(function()
for i = 0,10/bonuspeed,0.1 do
swait()
if type == "Add" then
scaler2 = scaler2 - 0.01*value/bonuspeed/10
elseif type == "Divide" then
scaler2 = scaler2 - 0.01/value*bonuspeed/10
end
if rotenable == true then
if randomrot == 1 then
rng.CFrame = rng.CFrame*CFrame.Angles(0,math.rad(rotspeed*bonuspeed/2),0)
elseif randomrot == 2 then
rng.CFrame = rng.CFrame*CFrame.Angles(0,math.rad(-rotspeed*bonuspeed/2),0)
end
end
if typeoftrans == "Out" then
rng.Transparency = rng.Transparency + 0.01*bonuspeed
elseif typeoftrans == "In" then
rng.Transparency = rng.Transparency - 0.01*bonuspeed
end
rngm.Scale = rngm.Scale + Vector3.new(scaler2*bonuspeed/10, 0, scaler2*bonuspeed/10)
end
rng:Destroy()
end))
end

function FindNearestTorso(Position, Distance, SinglePlayer)
	if SinglePlayer then
		return (SinglePlayer.Torso.CFrame.p - Position).magnitude < Distance
	end
	local List = {}
	for i, v in pairs(workspace:GetChildren()) do
		if v:IsA("Model") then
			if v:findFirstChild("Torso") or v:findFirstChild("UpperTorso") then
				if v ~= Character then
					if (v.Head.Position - Position).magnitude <= Distance then
						table.insert(List, v)
					end 
				end 
			end 
		end 
	end
	return List
end


local dashing = false
local floatmode = false
local OWS = hum.WalkSpeed
equipped = false

------------------
function equip()
	attack = true
	equipped = true
	hum.WalkSpeed = 0
tl1.Enabled = true
for i = 0, 9 do
slash(math.random(10,50)/10,3,true,"Round","Add","Out",root.CFrame*CFrame.new(0,-3,0)*CFrame.Angles(math.rad(math.random(-10,10)),math.rad(math.random(-360,360)),math.rad(math.random(-10,10))),vt(0.05,0.01,0.05),math.random(25,50)/250,BrickColor.new("White"))
end
CFuncs["Sound"].Create("rbxassetid://1368637781", rarmor, 2.5, 1.25)
CFuncs["Sound"].Create("rbxassetid://200633077", rarmor, 1, 1)
CFuncs["Sound"].Create("rbxassetid://169380495", rarmor, 0.5, 1.1)
sphere2(5,"Add",root.CFrame,vt(5,5,5),0.25,0.25,0.25,BrickColor.new("Cyan"),BrickColor.new("Cyan").Color)
sphere2(6,"Add",root.CFrame,vt(5,5,5),0.25,0.25,0.25,BrickColor.new("Royal purple"),BrickColor.new("Royal purple").Color)
	for i = 0, 2, 0.1 do
		swait()
hum.CameraOffset = vt(math.random(-5,5)/50,math.random(-5,5)/50,math.random(-5,5)/50)
sphere2(5,"Add",rarmor.CFrame*CFrame.new(math.random(-8,-2),0,0)*CFrame.Angles(math.rad(math.random(-360,360)),math.rad(math.random(-360,360)),math.rad(math.random(-360,360))),vt(0.1,0.1,0.1),0,0.1,0,BrickColor.new("Cyan"),BrickColor.new("Cyan").Color)
waveEff(5,"Add","Out",root.CFrame*CFrame.new(0,-3,0)*CFrame.Angles(0,math.rad(math.random(-360,360)),0),vt(5,0.25,5),0.05,0.015,BrickColor.new("Cyan"))
waveEff(5,"Add","Out",root.CFrame*CFrame.new(0,-3,0)*CFrame.Angles(0,math.rad(math.random(-360,360)),0),vt(10,0.25,10),0.05,0.015,BrickColor.new("Royal purple"))
	RH.C0=clerp(RH.C0,cf(1,-1,0)*angles(math.rad(0),math.rad(90),math.rad(0))*angles(math.rad(-3),math.rad(0),math.rad(0)),.2)
LH.C0=clerp(LH.C0,cf(-1,-1,0)*angles(math.rad(0),math.rad(-90),math.rad(0))*angles(math.rad(-3),math.rad(10),math.rad(0)),.2)
RootJoint.C0=clerp(RootJoint.C0,RootCF*cf(0,0,0)*angles(math.rad(0),math.rad(0),math.rad(-10)),.3)
Neck.C0=clerp(Neck.C0,necko*angles(math.rad(2),math.rad(0),math.rad(-20)),.3)
RW.C0=clerp(RW.C0,cf(1.45,0.5,0.1)*angles(math.rad(-20),math.rad(-30),math.rad(130)),.3)
LW.C0=clerp(LW.C0,cf(-1.45,0.5,0.1)*angles(math.rad(-13),math.rad(10),math.rad(-10)),.3)
end
hum.CameraOffset = vt(0,0,0)
weaponweld.Part0 = rarm
for i = 0, 2, 0.1 do
		swait()
sphere2(5,"Add",rarmor.CFrame*CFrame.new(math.random(-8,-2),0,0)*CFrame.Angles(math.rad(math.random(-360,360)),math.rad(math.random(-360,360)),math.rad(math.random(-360,360))),vt(0.1,0.1,0.1),0,0.1,0,BrickColor.new("Cyan"),BrickColor.new("Cyan").Color)
	RH.C0=clerp(RH.C0,cf(1,-1,0)*angles(math.rad(0),math.rad(90),math.rad(0))*angles(math.rad(-3),math.rad(-40),math.rad(0)),.2)
LH.C0=clerp(LH.C0,cf(-1,-1,0)*angles(math.rad(0),math.rad(-90),math.rad(0))*angles(math.rad(-3),math.rad(1),math.rad(5)),.2)
RootJoint.C0=clerp(RootJoint.C0,RootCF*cf(0.1,0.1,0)*angles(math.rad(0),math.rad(0),math.rad(40)),.3)
Neck.C0=clerp(Neck.C0,necko*angles(math.rad(2),math.rad(0),math.rad(-40)),.3)
RW.C0=clerp(RW.C0,cf(1.25,0.5,-0.65)*angles(math.rad(100),math.rad(0),math.rad(-23)),.3)
LW.C0=clerp(LW.C0,cf(-1.45,0.5,0.1)*angles(math.rad(110),math.rad(0),math.rad(-85)),.3)
weaponweld.C1=clerp(weaponweld.C1,cf(0,1,0)*angles(math.rad(0),math.rad(0),math.rad(0)),.3)
end
local hitb = CreateParta(m,1,1,"SmoothPlastic",BrickColor.Random())
hitb.Anchored = true
hitb.CFrame = root.CFrame + root.CFrame.lookVector*4
MagniDamage(hitb, 4, 40,73, 0, "Normal",153092213)
slash(5,5,true,"Round","Add","Out",hitb.CFrame*CFrame.Angles(0,math.rad(math.random(-360,360)),0),vt(0.05,0.01,0.05),0.01,BrickColor.new("White"))
CFuncs["Sound"].Create("rbxassetid://200633196", rarmor, 1, 1.05)
CFuncs["Sound"].Create("rbxassetid://200633108", rarmor, 1.5, 1.025)
CFuncs["Sound"].Create("rbxassetid://234365549", rarmor, 1, 1)
for i = 0, 2, 0.1 do
		swait()
sphere2(5,"Add",rarmor.CFrame*CFrame.new(math.random(-8,-2),0,0)*CFrame.Angles(math.rad(math.random(-360,360)),math.rad(math.random(-360,360)),math.rad(math.random(-360,360))),vt(0.1,0.1,0.1),0,0.1,0,BrickColor.new("Cyan"),BrickColor.new("Cyan").Color)
	RH.C0=clerp(RH.C0,cf(1,-1,0)*angles(math.rad(0),math.rad(90),math.rad(0))*angles(math.rad(-3),math.rad(0),math.rad(-20)),.2)
LH.C0=clerp(LH.C0,cf(-1,-1,0)*angles(math.rad(0),math.rad(-90),math.rad(0))*angles(math.rad(-3),math.rad(50),math.rad(0)),.2)
RootJoint.C0=clerp(RootJoint.C0,RootCF*cf(-0.1,-0.25,0)*angles(math.rad(10),math.rad(0),math.rad(-50)),.3)
Neck.C0=clerp(Neck.C0,necko*angles(math.rad(2),math.rad(0),math.rad(50)),.3)
RW.C0=clerp(RW.C0,cf(1.45,0.5,0.1)*angles(math.rad(80),math.rad(0),math.rad(70)),.3)
LW.C0=clerp(LW.C0,cf(-1.45,0.5,0.1)*angles(math.rad(100),math.rad(0),math.rad(-50)),.3)
weaponweld.C1=clerp(weaponweld.C1,cf(0,1,0)*angles(math.rad(0),math.rad(0),math.rad(-40)),.3)
end
hitb:Destroy()
hum.WalkSpeed = 24
OWS = hum.WalkSpeed
	attack = false
end

function unequip()
	attack = true
	equipped = false
	hum.WalkSpeed = 0
hum.WalkSpeed = 16
OWS = hum.WalkSpeed
tl1.Enabled = false
CFuncs["Sound"].Create("rbxassetid://200633029", rarmor, 1, 1)
weaponweld.C1=clerp(weaponweld.C1,cf(-3,0,-0.5)*angles(math.rad(0),math.rad(0),math.rad(-40)),.5)
weaponweld.Part0 = tors
	attack = false
end

------------------
function attackone()
attack = true
hum.WalkSpeed = 4
for i = 0, 2, 0.1 do
		swait()
	RH.C0=clerp(RH.C0,cf(1,-1,0)*angles(math.rad(0),math.rad(90),math.rad(0))*angles(math.rad(-3),math.rad(-40),math.rad(0)),.2)
LH.C0=clerp(LH.C0,cf(-1,-1,0)*angles(math.rad(0),math.rad(-90),math.rad(0))*angles(math.rad(-3),math.rad(1),math.rad(5)),.2)
RootJoint.C0=clerp(RootJoint.C0,RootCF*cf(0.1,0.1,0)*angles(math.rad(0),math.rad(0),math.rad(40)),.3)
Neck.C0=clerp(Neck.C0,necko*angles(math.rad(2),math.rad(0),math.rad(-40)),.3)
RW.C0=clerp(RW.C0,cf(1.25,0.5,-0.65)*angles(math.rad(100),math.rad(0),math.rad(-23)),.3)
LW.C0=clerp(LW.C0,cf(-1.45,0.5,0.1)*angles(math.rad(110),math.rad(0),math.rad(-85)),.3)
weaponweld.C1=clerp(weaponweld.C1,cf(0,1,0)*angles(math.rad(0),math.rad(0),math.rad(0)),.3)
end
local hitb = CreateParta(m,1,1,"SmoothPlastic",BrickColor.Random())
hitb.Anchored = true
hitb.CFrame = root.CFrame + root.CFrame.lookVector*4
MagniDamage(hitb, 4, 24,30, 0, "Normal",153092213)
CFuncs["Sound"].Create("rbxassetid://200633196", rarmor, 1, 1.05)
CFuncs["Sound"].Create("rbxassetid://200633108", rarmor, 1.5, 1.025)
CFuncs["Sound"].Create("rbxassetid://234365549", rarmor, 1, 1)
for i = 0, 1, 0.1 do
		swait()
	RH.C0=clerp(RH.C0,cf(1,-1,0)*angles(math.rad(0),math.rad(90),math.rad(0))*angles(math.rad(-3),math.rad(0),math.rad(-20)),.2)
LH.C0=clerp(LH.C0,cf(-1,-1,0)*angles(math.rad(0),math.rad(-90),math.rad(0))*angles(math.rad(-3),math.rad(50),math.rad(0)),.2)
RootJoint.C0=clerp(RootJoint.C0,RootCF*cf(-0.1,-0.25,0)*angles(math.rad(10),math.rad(0),math.rad(-50)),.3)
Neck.C0=clerp(Neck.C0,necko*angles(math.rad(2),math.rad(0),math.rad(50)),.3)
RW.C0=clerp(RW.C0,cf(1.45,0.5,0.1)*angles(math.rad(80),math.rad(0),math.rad(70)),.3)
LW.C0=clerp(LW.C0,cf(-1.45,0.5,0.1)*angles(math.rad(100),math.rad(0),math.rad(-50)),.3)
weaponweld.C1=clerp(weaponweld.C1,cf(0,1,0)*angles(math.rad(0),math.rad(0),math.rad(-40)),.3)
end
hitb:Destroy()
attack = false
hum.WalkSpeed = 24
end
function attacktwo()
attack = true
hum.WalkSpeed = 4
for i = 0, 1, 0.1 do
		swait()
	RH.C0=clerp(RH.C0,cf(1,-1,0)*angles(math.rad(0),math.rad(90),math.rad(0))*angles(math.rad(-3),math.rad(0),math.rad(0)),.2)
LH.C0=clerp(LH.C0,cf(-1,-1,0)*angles(math.rad(0),math.rad(-90),math.rad(0))*angles(math.rad(-3),math.rad(20),math.rad(5)),.2)
RootJoint.C0=clerp(RootJoint.C0,RootCF*cf(-0.1,0.1,0)*angles(math.rad(0),math.rad(0),math.rad(-40)),.3)
Neck.C0=clerp(Neck.C0,necko*angles(math.rad(2),math.rad(0),math.rad(40)),.3)
RW.C0=clerp(RW.C0,cf(1.25,0.5,-0.65)*angles(math.rad(100),math.rad(0),math.rad(-23)),.3)
LW.C0=clerp(LW.C0,cf(-0.5,0.5,-0.25)*angles(math.rad(90),math.rad(0),math.rad(40)),.3)
weaponweld.C1=clerp(weaponweld.C1,cf(0,1,0)*angles(math.rad(0),math.rad(180),math.rad(0)),.3)
end
local hitb = CreateParta(m,1,1,"SmoothPlastic",BrickColor.Random())
hitb.Anchored = true
hitb.CFrame = root.CFrame + root.CFrame.lookVector*4
MagniDamage(hitb, 4, 24,30, 0, "Normal",153092213)
CFuncs["Sound"].Create("rbxassetid://200633281", rarmor, 1, 1.05)
CFuncs["Sound"].Create("rbxassetid://161006195", rarmor, 1.5, 1.025)
for i = 0, 1, 0.1 do
		swait()
	RH.C0=clerp(RH.C0,cf(1,-1,0)*angles(math.rad(0),math.rad(90),math.rad(0))*angles(math.rad(-3),math.rad(-30),math.rad(0)),.2)
LH.C0=clerp(LH.C0,cf(-1,-1,0)*angles(math.rad(0),math.rad(-90),math.rad(0))*angles(math.rad(-3),math.rad(0),math.rad(20)),.2)
RootJoint.C0=clerp(RootJoint.C0,RootCF*cf(0.2,-0.25,0)*angles(math.rad(10),math.rad(0),math.rad(90)),.3)
Neck.C0=clerp(Neck.C0,necko*angles(math.rad(2),math.rad(0),math.rad(-90)),.3)
RW.C0=clerp(RW.C0,cf(1.45,0.5,0.1)*angles(math.rad(80),math.rad(0),math.rad(20)),.3)
LW.C0=clerp(LW.C0,cf(-1.45,0.5,0.1)*angles(math.rad(100),math.rad(0),math.rad(-50)),.3)
weaponweld.C1=clerp(weaponweld.C1,cf(0,1,0)*angles(math.rad(0),math.rad(180),math.rad(70)),.3)
end
attack = false
hum.WalkSpeed = 24
end
function attackthree()
attack = true
hum.WalkSpeed = 4
for i = 0, 1, 0.1 do
		swait()
	RH.C0=clerp(RH.C0,cf(1,-1,0)*angles(math.rad(0),math.rad(90),math.rad(0))*angles(math.rad(-3),math.rad(-30),math.rad(0)),.2)
LH.C0=clerp(LH.C0,cf(-1,-1,0)*angles(math.rad(0),math.rad(-90),math.rad(0))*angles(math.rad(-3),math.rad(0),math.rad(5)),.2)
RootJoint.C0=clerp(RootJoint.C0,RootCF*cf(-0.1,0.1,0)*angles(math.rad(0),math.rad(0),math.rad(-60)),.3)
Neck.C0=clerp(Neck.C0,necko*angles(math.rad(2),math.rad(0),math.rad(60)),.3)
RW.C0=clerp(RW.C0,cf(1.5,0.5,0)*angles(math.rad(-30),math.rad(0),math.rad(53)),.3)
LW.C0=clerp(LW.C0,cf(-1.5,0.5,0)*angles(math.rad(10),math.rad(0),math.rad(-10)),.3)
weaponweld.C1=clerp(weaponweld.C1,cf(0,1,0)*angles(math.rad(0),math.rad(90),math.rad(-20)),.3)
end
for x = 0, 2 do
CFuncs["Sound"].Create("rbxassetid://200633108", rarmor, 1, 1.05)
CFuncs["Sound"].Create("rbxassetid://234365573", rarmor, 1.5, 1.025)
local hitb = CreateParta(m,1,1,"SmoothPlastic",BrickColor.Random())
hitb.Anchored = true
hitb.CFrame = root.CFrame + root.CFrame.lookVector*4
MagniDamage(hitb, 4, 12,15, 0, "Normal",153092213)
for i = 0, 1, 0.6 do
		swait()
	RH.C0=clerp(RH.C0,cf(1,-1,0)*angles(math.rad(0),math.rad(90),math.rad(0))*angles(math.rad(-3),math.rad(0),math.rad(-10)),.2)
LH.C0=clerp(LH.C0,cf(-1,-1,0)*angles(math.rad(0),math.rad(-90),math.rad(0))*angles(math.rad(-3),math.rad(40),math.rad(20)),.2)
RootJoint.C0=clerp(RootJoint.C0,RootCF*cf(0.2,-0.25,0)*angles(math.rad(-2),math.rad(0),math.rad(80)),.3)
Neck.C0=clerp(Neck.C0,necko*angles(math.rad(4),math.rad(0),math.rad(-80)),.3)
RW.C0=clerp(RW.C0,cf(1.45,0.5,0.1)*angles(math.rad(90),math.rad(0),math.rad(80)),.3)
LW.C0=clerp(LW.C0,cf(-1.45,0.5,0.1)*angles(math.rad(10),math.rad(0),math.rad(-20)),.3)
weaponweld.C1=clerp(weaponweld.C1,cf(0,0,0)*angles(math.rad(0),math.rad(30),math.rad(90)),.3)
end
for i = 0, 1, 0.6 do
		swait()
	RH.C0=clerp(RH.C0,cf(1,-1,0)*angles(math.rad(0),math.rad(90),math.rad(0))*angles(math.rad(-3),math.rad(0),math.rad(-10)),.2)
LH.C0=clerp(LH.C0,cf(-1,-1,0)*angles(math.rad(0),math.rad(-90),math.rad(0))*angles(math.rad(-3),math.rad(40),math.rad(20)),.2)
RootJoint.C0=clerp(RootJoint.C0,RootCF*cf(0.2,-0.25,0)*angles(math.rad(-2),math.rad(0),math.rad(80)),.3)
Neck.C0=clerp(Neck.C0,necko*angles(math.rad(4),math.rad(0),math.rad(-80)),.3)
RW.C0=clerp(RW.C0,cf(1.45,0.5,0.1)*angles(math.rad(90),math.rad(0),math.rad(80)),.3)
LW.C0=clerp(LW.C0,cf(-1.45,0.5,0.1)*angles(math.rad(10),math.rad(0),math.rad(-20)),.3)
weaponweld.C1=clerp(weaponweld.C1,cf(0,0,0)*angles(math.rad(0),math.rad(0),math.rad(180)),.3)
end
for i = 0, 1, 0.6 do
		swait()
	RH.C0=clerp(RH.C0,cf(1,-1,0)*angles(math.rad(0),math.rad(90),math.rad(0))*angles(math.rad(-3),math.rad(0),math.rad(-10)),.2)
LH.C0=clerp(LH.C0,cf(-1,-1,0)*angles(math.rad(0),math.rad(-90),math.rad(0))*angles(math.rad(-3),math.rad(40),math.rad(20)),.2)
RootJoint.C0=clerp(RootJoint.C0,RootCF*cf(0.2,-0.25,0)*angles(math.rad(-2),math.rad(0),math.rad(80)),.3)
Neck.C0=clerp(Neck.C0,necko*angles(math.rad(4),math.rad(0),math.rad(-80)),.3)
RW.C0=clerp(RW.C0,cf(1.45,0.5,0.1)*angles(math.rad(90),math.rad(0),math.rad(80)),.3)
LW.C0=clerp(LW.C0,cf(-1.45,0.5,0.1)*angles(math.rad(10),math.rad(0),math.rad(-20)),.3)
weaponweld.C1=clerp(weaponweld.C1,cf(0,0,0)*angles(math.rad(0),math.rad(-30),math.rad(270)),.3)
end
for i = 0, 1, 0.6 do
		swait()
	RH.C0=clerp(RH.C0,cf(1,-1,0)*angles(math.rad(0),math.rad(90),math.rad(0))*angles(math.rad(-3),math.rad(0),math.rad(-10)),.2)
LH.C0=clerp(LH.C0,cf(-1,-1,0)*angles(math.rad(0),math.rad(-90),math.rad(0))*angles(math.rad(-3),math.rad(40),math.rad(20)),.2)
RootJoint.C0=clerp(RootJoint.C0,RootCF*cf(0.2,-0.25,0)*angles(math.rad(-2),math.rad(0),math.rad(80)),.3)
Neck.C0=clerp(Neck.C0,necko*angles(math.rad(4),math.rad(0),math.rad(-80)),.3)
RW.C0=clerp(RW.C0,cf(1.45,0.5,0.1)*angles(math.rad(90),math.rad(0),math.rad(80)),.3)
LW.C0=clerp(LW.C0,cf(-1.45,0.5,0.1)*angles(math.rad(10),math.rad(0),math.rad(-20)),.3)
weaponweld.C1=clerp(weaponweld.C1,cf(0,0,0)*angles(math.rad(0),math.rad(0),math.rad(0)),.3)
end
end
attack = false
hum.WalkSpeed = 24
end
------------------
function spinnyblade()
attack = true
hum.WalkSpeed = 1
hum.JumpPower = 0
CFuncs["Sound"].Create("rbxassetid://1368583274", root, 4.5, 1)
local bgui = Instance.new("BillboardGui",root)
bgui.Size = UDim2.new(25, 0, 25, 0)
local imgc = Instance.new("ImageLabel",bgui)
imgc.BackgroundTransparency = 1
imgc.ImageTransparency = 1
imgc.Size = UDim2.new(1,0,1,0)
imgc.Image = "rbxassetid://997291547"
imgc.ImageColor3 = Color3.new(0,0.5,1)
local imgc2 = imgc:Clone()
imgc2.Parent = bgui
imgc2.Position = UDim2.new(-0.5,0,-0.5,0)
imgc2.Size = UDim2.new(2,0,2,0)
imgc2.ImageColor3 = Color3.new(0.5,0,1)
for i = 0, 10, 0.1 do
		swait()
imgc.ImageTransparency = imgc.ImageTransparency - 0.01
imgc.Rotation = imgc.Rotation + 1
imgc2.ImageTransparency = imgc2.ImageTransparency - 0.01
imgc2.Rotation = imgc2.Rotation - 1
bgui.Size = bgui.Size - UDim2.new(0.25, 0, 0.25, 0)
slash(math.random(50,100)/10,5,true,"Round","Add","Out",root.CFrame*CFrame.new(0,-3,0)*CFrame.Angles(math.rad(math.random(-10,10)),math.rad(math.random(-360,360)),math.rad(math.random(-10,10))),vt(0.1,0.01,0.1),math.random(25,50)/250,BrickColor.new("White"))
sphere2(5,"Add",rarmor.CFrame*CFrame.new(math.random(-8,-2),0,0)*CFrame.Angles(math.rad(math.random(-360,360)),math.rad(math.random(-360,360)),math.rad(math.random(-360,360))),vt(0.1,0.1,0.1),0,0.1,0,BrickColor.new("Cyan"),BrickColor.new("Cyan").Color)
hum.CameraOffset = vt(math.random(-10,10)/50,math.random(-10,10)/50,math.random(-10,10)/50)
sphereMK(5,math.random(4,25)/45,"Add",root.CFrame*CFrame.new(math.random(-15,15),-20,math.random(-15,15))*CFrame.Angles(math.rad(90 + math.random(-10,10)),math.rad(math.random(-10,10)),math.rad(math.random(-10,10))),0.75,0.75,20,-0.0075,BrickColor.new("Royal purple"),BrickColor.new("Royal purple").Color,0)
sphereMK(5,math.random(1,15)/45,"Add",root.CFrame*CFrame.new(math.random(-15,15),-20,math.random(-15,15))*CFrame.Angles(math.rad(90 + math.random(-25,25)),math.rad(math.random(-25,25)),math.rad(math.random(-25,25))),0.75,0.75,20,-0.0075,BrickColor.new("Cyan"),BrickColor.new("Cyan").Color,0)
waveEff(5,"Add","In",root.CFrame*CFrame.new(0,-3,0)*CFrame.Angles(0,math.rad(math.random(-360,360)),0),vt(15,0.25,15),-0.075,0.05,BrickColor.new("White"))
	RH.C0=clerp(RH.C0,cf(1,-0.5,0)*angles(math.rad(0),math.rad(90),math.rad(0))*angles(math.rad(-3),math.rad(-40),math.rad(10)),.2)
LH.C0=clerp(LH.C0,cf(-1,-1,0)*angles(math.rad(0),math.rad(-90),math.rad(0))*angles(math.rad(-3),math.rad(1),math.rad(20)),.2)
RootJoint.C0=clerp(RootJoint.C0,RootCF*cf(0.1,0.2,-0.3)*angles(math.rad(10),math.rad(0),math.rad(50)),.3)
Neck.C0=clerp(Neck.C0,necko*angles(math.rad(5),math.rad(0),math.rad(-50)),.3)
RW.C0=clerp(RW.C0,cf(1.25,0.5,-0.65)*angles(math.rad(100),math.rad(0),math.rad(-23)),.3)
LW.C0=clerp(LW.C0,cf(-1.45,0.5,0.1)*angles(math.rad(110),math.rad(0),math.rad(-85)),.3)
weaponweld.C1=clerp(weaponweld.C1,cf(0,1,0)*angles(math.rad(0),math.rad(0),math.rad(0)),.3)
end
imgc.ImageTransparency = 1
hum.CameraOffset = vt(0,0,0)
waveEff(2,"Add","Out",root.CFrame*CFrame.new(0,0,0)*CFrame.Angles(math.rad(90),math.rad(math.random(-360,360)),0),vt(6,10,6),0.5,0.8,BrickColor.new("White"))
waveEff(3,"Add","Out",root.CFrame*CFrame.new(0,0,0)*CFrame.Angles(math.rad(90),math.rad(math.random(-360,360)),0),vt(6,10,6),0.5,0.4,BrickColor.new("White"))
waveEff(4,"Add","Out",root.CFrame*CFrame.new(0,0,0)*CFrame.Angles(math.rad(90),math.rad(math.random(-360,360)),0),vt(6,10,6),0.5,0.2,BrickColor.new("White"))
waveEff(5,"Add","Out",root.CFrame*CFrame.new(0,0,0)*CFrame.Angles(math.rad(90),math.rad(math.random(-360,360)),0),vt(6,10,6),0.5,0.1,BrickColor.new("White"))
waveEff(6,"Add","Out",root.CFrame*CFrame.new(0,0,0)*CFrame.Angles(math.rad(90),math.rad(math.random(-360,360)),0),vt(6,10,6),0.5,0.05,BrickColor.new("White"))
for i = 0, 9 do
slash(math.random(10,25)/10,5,true,"Round","Add","Out",root.CFrame*CFrame.new(0,0,math.random(-30,15))*CFrame.Angles(math.rad(90 + math.random(-10,10)),math.rad(math.random(-360,360)),math.rad(math.random(-10,10))),vt(0.1,0.01,0.1),math.random(75,250)/250,BrickColor.new("White"))
end
CFuncs["Sound"].Create("rbxassetid://430315987", root, 1.5, 1)
CFuncs["Sound"].Create("rbxassetid://1295446488", root, 3, 1)
for x = 0, 14 do
CFuncs["Sound"].Create("rbxassetid://200633281", rarmor, 1, 1.05)
CFuncs["Sound"].Create("rbxassetid://161006195", rarmor, 1.5, 1.025)
MagniDamage(tors, 10, 60,85, 0, "Normal",153092213)
CFuncs["Sound"].Create("rbxassetid://200632992", rarmor, 1.25, 1)
slash(5,5,true,"Round","Add","Out",root.CFrame*CFrame.new(0,3,0)*CFrame.Angles(math.rad(math.random(-360,360)),math.rad(math.random(-360,360)),math.rad(math.random(-360,360))),vt(0.05,0.01,0.05),math.random(1,10)/100,BrickColor.new("White"))
for i = 0, 1, 0.6 do
		swait()
sphereMK(2,-1,"Add",root.CFrame*CFrame.new(math.random(-8,8),math.random(-8,8),math.random(-3,8))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),0.5,0.5,math.random(5,25),-0.0075,BrickColor.new("Cyan"),BrickColor.new("Cyan").Color,0)
NEP_setRoot(root.CFrame + root.CFrame.lookVector*2)
root.Velocity = vt(0,0,0)
	RH.C0=clerp(RH.C0,cf(1,-1,0)*angles(math.rad(0),math.rad(90),math.rad(0))*angles(math.rad(-3),math.rad(0),math.rad(0)),.2)
LH.C0=clerp(LH.C0,cf(-1,-1,0)*angles(math.rad(0),math.rad(-90),math.rad(0))*angles(math.rad(-3),math.rad(0),math.rad(0)),.2)
RootJoint.C0=clerp(RootJoint.C0,RootCF*cf(0,0,3)*angles(math.rad(0),math.rad(0),math.rad(90)),.3)
Neck.C0=clerp(Neck.C0,necko*angles(math.rad(4),math.rad(0),math.rad(-60)),.3)
RW.C0=clerp(RW.C0,cf(1.45,0.5,0.1)*angles(math.rad(90),math.rad(0),math.rad(90)),.3)
LW.C0=clerp(LW.C0,cf(-1.45,0.5,0.1)*angles(math.rad(90),math.rad(0),math.rad(-90)),.3)
weaponweld.C1=clerp(weaponweld.C1,cf(0,0,0)*angles(math.rad(90),math.rad(0),math.rad(-90)),.3)
end
slash(5,2.5,true,"Round","Add","Out",root.CFrame*CFrame.new(0,3,0)*CFrame.Angles(math.rad(math.random(-360,360)),math.rad(math.random(-360,360)),math.rad(math.random(-360,360))),vt(0.05,0.01,0.05),math.random(1,10)/100,BrickColor.new("White"))
CFuncs["Sound"].Create("rbxassetid://200632992", rarmor, 1.25, 1)
MagniDamage(tors, 10, 60,85, 0, "Normal",153092213)
for i = 0, 1, 0.6 do
		swait()
sphereMK(2,-1,"Add",root.CFrame*CFrame.new(math.random(-8,8),math.random(-8,8),math.random(-3,8))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),0.5,0.5,math.random(5,25),-0.0075,BrickColor.new("Royal purple"),BrickColor.new("Royal purple").Color,0)
NEP_setRoot(root.CFrame + root.CFrame.lookVector*3)
root.Velocity = vt(0,0,0)
	RH.C0=clerp(RH.C0,cf(1,-1,0)*angles(math.rad(0),math.rad(90),math.rad(0))*angles(math.rad(-3),math.rad(0),math.rad(0)),.2)
LH.C0=clerp(LH.C0,cf(-1,-1,0)*angles(math.rad(0),math.rad(-90),math.rad(0))*angles(math.rad(-3),math.rad(0),math.rad(0)),.2)
RootJoint.C0=clerp(RootJoint.C0,RootCF*cf(0,0,3)*angles(math.rad(90),math.rad(0),math.rad(90)),.3)
Neck.C0=clerp(Neck.C0,necko*angles(math.rad(4),math.rad(0),math.rad(-60)),.3)
RW.C0=clerp(RW.C0,cf(1.45,0.5,0.1)*angles(math.rad(90),math.rad(0),math.rad(90)),.3)
LW.C0=clerp(LW.C0,cf(-1.45,0.5,0.1)*angles(math.rad(90),math.rad(0),math.rad(-90)),.3)
weaponweld.C1=clerp(weaponweld.C1,cf(0,0,0)*angles(math.rad(90),math.rad(0),math.rad(-90)),.3)
end
slash(5,2.5,true,"Round","Add","Out",root.CFrame*CFrame.new(0,3,0)*CFrame.Angles(math.rad(math.random(-360,360)),math.rad(math.random(-360,360)),math.rad(math.random(-360,360))),vt(0.05,0.01,0.05),math.random(1,10)/100,BrickColor.new("White"))
CFuncs["Sound"].Create("rbxassetid://200632992", rarmor, 1.25, 1)
MagniDamage(tors, 10, 60,85, 0, "Normal",153092213)
for i = 0, 1, 0.6 do
		swait()
sphereMK(2,-1,"Add",root.CFrame*CFrame.new(math.random(-8,8),math.random(-8,8),math.random(-3,8))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),0.5,0.5,math.random(5,25),-0.0075,BrickColor.new("Cyan"),BrickColor.new("Cyan").Color,0)
NEP_setRoot(root.CFrame + root.CFrame.lookVector*3)
root.Velocity = vt(0,0,0)
	RH.C0=clerp(RH.C0,cf(1,-1,0)*angles(math.rad(0),math.rad(90),math.rad(0))*angles(math.rad(-3),math.rad(0),math.rad(0)),.2)
LH.C0=clerp(LH.C0,cf(-1,-1,0)*angles(math.rad(0),math.rad(-90),math.rad(0))*angles(math.rad(-3),math.rad(0),math.rad(0)),.2)
RootJoint.C0=clerp(RootJoint.C0,RootCF*cf(0,0,3)*angles(math.rad(180),math.rad(0),math.rad(90)),.3)
Neck.C0=clerp(Neck.C0,necko*angles(math.rad(4),math.rad(0),math.rad(-60)),.3)
RW.C0=clerp(RW.C0,cf(1.45,0.5,0.1)*angles(math.rad(90),math.rad(0),math.rad(90)),.3)
LW.C0=clerp(LW.C0,cf(-1.45,0.5,0.1)*angles(math.rad(90),math.rad(0),math.rad(-90)),.3)
weaponweld.C1=clerp(weaponweld.C1,cf(0,0,0)*angles(math.rad(90),math.rad(0),math.rad(-90)),.3)
end
slash(5,2.5,true,"Round","Add","Out",root.CFrame*CFrame.new(0,3,0)*CFrame.Angles(math.rad(math.random(-360,360)),math.rad(math.random(-360,360)),math.rad(math.random(-360,360))),vt(0.05,0.01,0.05),math.random(1,10)/100,BrickColor.new("White"))
CFuncs["Sound"].Create("rbxassetid://200632992", rarmor, 1.25, 1)
MagniDamage(tors, 10, 60,85, 0, "Normal",153092213)
for i = 0, 1, 0.6 do
		swait()
sphereMK(2,-1,"Add",root.CFrame*CFrame.new(math.random(-8,8),math.random(-8,8),math.random(-3,8))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),0.5,0.5,math.random(5,25),-0.0075,BrickColor.new("Royal purple"),BrickColor.new("Royal purple").Color,0)
NEP_setRoot(root.CFrame + root.CFrame.lookVector*3)
root.Velocity = vt(0,0,0)
	RH.C0=clerp(RH.C0,cf(1,-1,0)*angles(math.rad(0),math.rad(90),math.rad(0))*angles(math.rad(-3),math.rad(0),math.rad(0)),.2)
LH.C0=clerp(LH.C0,cf(-1,-1,0)*angles(math.rad(0),math.rad(-90),math.rad(0))*angles(math.rad(-3),math.rad(0),math.rad(0)),.2)
RootJoint.C0=clerp(RootJoint.C0,RootCF*cf(0,0,3)*angles(math.rad(270),math.rad(0),math.rad(90)),.3)
Neck.C0=clerp(Neck.C0,necko*angles(math.rad(4),math.rad(0),math.rad(-60)),.3)
RW.C0=clerp(RW.C0,cf(1.45,0.5,0.1)*angles(math.rad(90),math.rad(0),math.rad(90)),.3)
LW.C0=clerp(LW.C0,cf(-1.45,0.5,0.1)*angles(math.rad(90),math.rad(0),math.rad(-90)),.3)
weaponweld.C1=clerp(weaponweld.C1,cf(0,0,0)*angles(math.rad(90),math.rad(0),math.rad(-90)),.3)
end
end
hum.WalkSpeed = 0
for i = 0, 5, 0.1 do
		swait()
	RH.C0=clerp(RH.C0,cf(1,-1,0)*angles(math.rad(0),math.rad(90),math.rad(0))*angles(math.rad(-3),math.rad(0),math.rad(-20)),.2)
LH.C0=clerp(LH.C0,cf(-1,-0.6,-0.5)*angles(math.rad(0),math.rad(-90),math.rad(0))*angles(math.rad(-3),math.rad(20),math.rad(-12)),.2)
RootJoint.C0=clerp(RootJoint.C0,RootCF*cf(0.1,0.2,-0.35)*angles(math.rad(10),math.rad(0),math.rad(-40)),.2)
Neck.C0=clerp(Neck.C0,necko*angles(math.rad(5),math.rad(0),math.rad(40)),.2)
RW.C0=clerp(RW.C0,cf(1.45,0.5,0)*angles(math.rad(90),math.rad(0),math.rad(110)),.2)
LW.C0=clerp(LW.C0,cf(-1.45,0.5,0)*angles(math.rad(45),math.rad(0),math.rad(-20)),.2)
weaponweld.C1=clerp(weaponweld.C1,cf(2,0,0)*angles(math.rad(90),math.rad(0),math.rad(-90)),.2)
end
bgui:Destroy()
attack = false
hum.WalkSpeed = 24
hum.JumpPower = 50
end

function eightbitmegablade()
attack = true
hum.WalkSpeed = 0
hum.JumpPower = 0
CFuncs["Sound"].Create("rbxassetid://1368583274", larm, 4.5, 1.2)
local OverCut = false

coroutine.resume(coroutine.create(function()
while true do
swait()
if OverCut == false then
cam.CFrame = lerp(cam.CFrame, root.CFrame * cf(1, 1.5, -6) * ceuler(math.rad(10), math.rad(170), math.rad(-20)), 0.1)
else
break
end
end
end))
for i = 0, 10, 0.1 do
swait()
slash(math.random(50,100)/10,5,true,"Round","Add","Out",root.CFrame*CFrame.new(0,-3,0)*CFrame.Angles(math.rad(math.random(-5,5)),math.rad(math.random(-360,360)),math.rad(math.random(-5,5))),vt(0.05,0.01,0.05),math.random(25,50)/250,BrickColor.new("White"))
sphere2(5,"Add",larm.CFrame*CFrame.new(0,-1.5,0)*CFrame.Angles(math.rad(math.random(-360,360)),math.rad(math.random(-360,360)),math.rad(math.random(-360,360))),vt(1,1,1),-0.01,0.1,-0.01,BrickColor.new("Cyan"),BrickColor.new("Cyan").Color)
slash(math.random(20,40)/10,5,true,"Round","Add","Out",larm.CFrame*CFrame.new(0,-1.5,0)*CFrame.Angles(math.rad(math.random(-360,360)),math.rad(math.random(-360,360)),math.rad(math.random(-360,360))),vt(0.025,0.001,0.025),-0.025,BrickColor.new("White"))
RH.C0=clerp(RH.C0,cf(1,-1,0)*angles(math.rad(0),math.rad(90),math.rad(0))*angles(math.rad(-6),math.rad(0),math.rad(-6)),.3)
LH.C0=clerp(LH.C0,cf(-1,-1,0)*angles(math.rad(0),math.rad(-90),math.rad(0))*angles(math.rad(-3),math.rad(30),math.rad(3)),.3)
RootJoint.C0=clerp(RootJoint.C0,RootCF*cf(0,0,0)*angles(math.rad(0),math.rad(0),math.rad(-50)),.3)
Neck.C0=clerp(Neck.C0,necko*angles(math.rad(-15),math.rad(5),math.rad(50)),.3)
RW.C0=clerp(RW.C0,cf(1.45,0.5,0.1)*angles(math.rad(-13),math.rad(-40),math.rad(20)),.3)
LW.C0=clerp(LW.C0,cf(-1.45,0.5,0.1)*angles(math.rad(170),math.rad(10),math.rad(0)),.3)
weaponweld.C1=clerp(weaponweld.C1,cf(0,1,0)*angles(math.rad(0),math.rad(130),math.rad(0)),.3)
end
OverCut = true
local orb = Instance.new("Part", char)
orb.Anchored = true
orb.BrickColor = BrickColor.new("Toothpaste")
orb.CanCollide = false
orb.FormFactor = 3
orb.Name = "Ring"
orb.Material = "Neon"
orb.Size = Vector3.new(1, 1, 1)
orb.Transparency = 0.5
orb.TopSurface = 0
orb.BottomSurface = 0
local orbm = Instance.new("SpecialMesh", orb)
orbm.MeshType = "FileMesh"
orbm.MeshId = "rbxassetid://361629844"
orbm.Scale = vt(30,60,60)
orb.CFrame = root.CFrame*CFrame.new(0,50,0)
for i = 0, 24 do
slash(math.random(10,30)/10,5,true,"Round","Add","Out",orb.CFrame*CFrame.Angles(math.rad(math.random(-360,360)),math.rad(math.random(-360,360)),math.rad(math.random(-360,360))),vt(0.1,0.001,0.1),math.random(50,400)/420,BrickColor.new("White"))
end
sphere2(2,"Add",orb.CFrame,vt(10,10,10),0.5,0.5,0.5,BrickColor.new("Cyan"),BrickColor.new("Cyan").Color)
sphere2(3,"Add",orb.CFrame,vt(10,10,10),0.75,0.75,0.75,BrickColor.new("Cyan"),BrickColor.new("Cyan").Color)
sphere2(4,"Add",orb.CFrame,vt(10,10,10),1,1,1,BrickColor.new("Cyan"),BrickColor.new("Cyan").Color)
CFuncs["Sound"].Create("rbxassetid://1368637781", orb, 7.5, 1)
local a = Instance.new("Part",workspace)
a.Name = "Direction"	
a.Anchored = true
a.Transparency = 1
a.CanCollide = false
local ray = Ray.new(
orb.CFrame.p,                           -- origin
(mouse.Hit.p - orb.CFrame.p).unit * 500 -- direction
) 
local ignore = orb
local hit, position, normal = workspace:FindPartOnRay(ray, ignore)
a.BottomSurface = 10
a.TopSurface = 10
local distance = (orb.CFrame.p - position).magnitude
a.Size = Vector3.new(0.1, 0.1, 0.1)
a.CFrame = CFrame.new(orb.CFrame.p, position) * CFrame.new(0, 0, 0)
orb.CFrame = a.CFrame
for i = 0, 8, 0.1 do
swait()
sphere2(5,"Add",orb.CFrame*CFrame.new(math.random(-20,20),math.random(-20,20),math.random(-20,20)),vt(1,1,1),0.01,0.01,0.01,BrickColor.new("Royal purple"),BrickColor.new("Royal purple").Color)
ray = Ray.new(
orb.CFrame.p,                           -- origin
(mouse.Hit.p - orb.CFrame.p).unit * 500 -- direction
) 
hit, position, normal = workspace:FindPartOnRay(ray, ignore)
distance = (orb.CFrame.p - position).magnitude
a.CFrame = CFrame.new(orb.CFrame.p, position) * CFrame.new(0, 0, 0)
orb.CFrame = a.CFrame
slash(math.random(50,100)/10,5,true,"Round","Add","Out",root.CFrame*CFrame.new(0,-3,0)*CFrame.Angles(math.rad(math.random(-5,5)),math.rad(math.random(-360,360)),math.rad(math.random(-5,5))),vt(0.05,0.01,0.05),math.random(25,50)/250,BrickColor.new("White"))
cam.CFrame = lerp(cam.CFrame, root.CFrame * cf(20, 65, 55) * ceuler(math.rad(-20), math.rad(0), math.rad(10)), 0.2)
RH.C0=clerp(RH.C0,cf(1,-1,0)*angles(math.rad(0),math.rad(90),math.rad(0))*angles(math.rad(-6),math.rad(0),math.rad(-6)),.3)
LH.C0=clerp(LH.C0,cf(-1,-1,0)*angles(math.rad(0),math.rad(-90),math.rad(0))*angles(math.rad(-3),math.rad(40),math.rad(3)),.3)
RootJoint.C0=clerp(RootJoint.C0,RootCF*cf(0,0,0)*angles(math.rad(0),math.rad(0),math.rad(-90)),.3)
Neck.C0=clerp(Neck.C0,necko*angles(math.rad(5),math.rad(0),math.rad(90)),.3)
RW.C0=clerp(RW.C0,cf(1.45,0.5,0.1)*angles(math.rad(-13),math.rad(-20),math.rad(20)),.3)
LW.C0=clerp(LW.C0,cf(-1.25,0.5,-0.5)*angles(math.rad(100),math.rad(0),math.rad(60)),.3)
weaponweld.C1=clerp(weaponweld.C1,cf(0,1,0)*angles(math.rad(0),math.rad(130),math.rad(0)),.3)
end

orb.Anchored = false
a:Destroy()
local bv = Instance.new("BodyVelocity")
bv.maxForce = Vector3.new(1e9, 1e9, 1e9)
bv.velocity = orb.CFrame.lookVector*250
bv.Parent = orb
local hitted = false
CFuncs["Sound"].Create("rbxassetid://466493476", orb, 7.5, 0.7)
waveEff(2,"Add","Out",orb.CFrame*CFrame.Angles(math.rad(90),math.rad(math.random(-360,360)),0),vt(5,1,5),0.5,0.1,BrickColor.new("Cyan"))
waveEff(4,"Add","Out",orb.CFrame*CFrame.Angles(math.rad(90),math.rad(math.random(-360,360)),0),vt(5,1,5),0.5,0.05,BrickColor.new("Royal purple"))
coroutine.resume(coroutine.create(function()
while true do
swait(2)
if hitted == false and orb.Parent ~= nil then
slash(3,5,true,"Round","Add","Out",orb.CFrame*CFrame.Angles(math.rad(90),math.rad(math.random(-360,360)),0),vt(0.075,0.005,0.075),-0.05,BrickColor.new("White"))
elseif hitted == true and orb.Parent == nil then
break
end
end
end))
orb.Touched:connect(function(hit) 
if hitted == false and hit.Parent ~= char then
hitted = true
MagniDamage(orb, 30, 72,95, 0, "Normal",153092213)
CFuncs["Sound"].Create("rbxassetid://763717897", orb, 10, 1)
CFuncs["Sound"].Create("rbxassetid://1295446488", orb, 9, 0.75)
for i = 0, 24 do
slash(math.random(15,30)/10,5,true,"Round","Add","Out",orb.CFrame*CFrame.Angles(math.rad(math.random(-360,360)),math.rad(math.random(-360,360)),math.rad(math.random(-360,360))),vt(0.01,0.001,0.01),math.random(125,250)/400,BrickColor.new("White"))
end
slash(1,5,true,"Round","Add","Out",orb.CFrame*CFrame.Angles(math.rad(90),math.rad(math.random(-360,360)),0),vt(0.01,0.015,0.01),1.5,BrickColor.new("White"))
slash(1,5,true,"Round","Add","Out",orb.CFrame*CFrame.Angles(math.rad(90),math.rad(math.random(-360,360)),0),vt(0.01,0.01,0.01),2,BrickColor.new("White"))
sphere2(1,"Add",orb.CFrame,vt(10,10,10),1,1,1,BrickColor.new("Cyan"),BrickColor.new("Cyan").Color)
sphere2(1.5,"Add",orb.CFrame,vt(10,10,10),1.1,1.1,1.1,BrickColor.new("Royal purple"),BrickColor.new("Royal purple").Color)
sphere2(2,"Add",orb.CFrame,vt(10,10,10),1.2,1.2,1.2,BrickColor.new("Royal purple"),BrickColor.new("Royal purple").Color)
orb.Anchored = true
orb.Transparency = 1
coroutine.resume(coroutine.create(function()
for i = 0, 4, 0.1 do
swait()
slash(math.random(10,50)/10,5,true,"Round","Add","Out",orb.CFrame*CFrame.Angles(math.rad(90 + math.random(-5,5)),math.rad(math.random(-360,360)),math.rad(math.random(-5,5))),vt(0.01,0.015,0.01),1.5,BrickColor.new("Royal purple"))
hum.CameraOffset = vt(math.random(-10,10)/25,math.random(-10,10)/25,math.random(-10,10)/25)
end
hum.CameraOffset = vt(0,0,0)
end))
wait(10)
orb:Destroy()
end
end)
game:GetService("Debris"):AddItem(orb, 10)
for i = 0, 2, 0.1 do
swait()
slash(math.random(50,100)/10,5,true,"Round","Add","Out",root.CFrame*CFrame.new(0,-3,0)*CFrame.Angles(math.rad(math.random(-5,5)),math.rad(math.random(-360,360)),math.rad(math.random(-5,5))),vt(0.05,0.01,0.05),math.random(25,50)/250,BrickColor.new("White"))
RH.C0=clerp(RH.C0,cf(1,-1,0)*angles(math.rad(0),math.rad(90),math.rad(0))*angles(math.rad(-6),math.rad(0),math.rad(-6)),.3)
LH.C0=clerp(LH.C0,cf(-1,-1,0)*angles(math.rad(0),math.rad(-90),math.rad(0))*angles(math.rad(-3),math.rad(30),math.rad(3)),.3)
RootJoint.C0=clerp(RootJoint.C0,RootCF*cf(0,-0.4,0)*angles(math.rad(0),math.rad(0),math.rad(-70)),.3)
Neck.C0=clerp(Neck.C0,necko*angles(math.rad(5),math.rad(0),math.rad(70)),.3)
RW.C0=clerp(RW.C0,cf(1.45,0.5,0.1)*angles(math.rad(-13),math.rad(-40),math.rad(20)),.3)
LW.C0=clerp(LW.C0,cf(-1.45,0.5,0.1)*angles(math.rad(90),math.rad(0),math.rad(-80)),.3)
weaponweld.C1=clerp(weaponweld.C1,cf(0,1,0)*angles(math.rad(0),math.rad(130),math.rad(0)),.3)
end
attack = false
hum.WalkSpeed = 24
hum.JumpPower = 50
end

function bladespinagain()
attack = true
hum.WalkSpeed = 4
hum.JumpPower = 0
CFuncs["Sound"].Create("rbxassetid://1368598393", rarmor, 2, 1)
CFuncs["Sound"].Create("rbxassetid://1368583274", rarmor, 2.5, 1)
for x = 0, 9 do
slash(5,5,true,"Round","Add","Out",rarmor.CFrame*CFrame.new(0,0,0)*CFrame.Angles(0,0,0),vt(0.05,0.01,0.05),0.05,BrickColor.new("White"))
CFuncs["Sound"].Create("rbxassetid://200633108", rarmor, 2, 1.05)
CFuncs["Sound"].Create("rbxassetid://234365573", rarmor, 2.5, 1.025)
for i = 0, 1, 0.6 do
		swait()
sphereMK(5,math.random(4,25)/45,"Add",root.CFrame*CFrame.new(math.random(-15,15),-20,math.random(-15,15))*CFrame.Angles(math.rad(90 + math.random(-10,10)),math.rad(math.random(-10,10)),math.rad(math.random(-10,10))),0.75,0.75,20,-0.0075,BrickColor.new("Royal purple"),BrickColor.new("Royal purple").Color,0)
sphereMK(5,math.random(1,15)/45,"Add",root.CFrame*CFrame.new(math.random(-15,15),-20,math.random(-15,15))*CFrame.Angles(math.rad(90 + math.random(-25,25)),math.rad(math.random(-25,25)),math.rad(math.random(-25,25))),0.75,0.75,20,-0.0075,BrickColor.new("Cyan"),BrickColor.new("Cyan").Color,0)
slash(math.random(50,100)/10,5,true,"Round","Add","Out",root.CFrame*CFrame.new(0,-3,0)*CFrame.Angles(math.rad(math.random(-5,5)),math.rad(math.random(-360,360)),math.rad(math.random(-5,5))),vt(0.05,0.01,0.05),math.random(25,50)/250,BrickColor.new("White"))
sphere2(5,"Add",rarmor.CFrame*CFrame.new(math.random(-8,-2),0,0)*CFrame.Angles(math.rad(math.random(-360,360)),math.rad(math.random(-360,360)),math.rad(math.random(-360,360))),vt(0.1,0.1,0.1),0,0.1,0,BrickColor.new("Cyan"),BrickColor.new("Cyan").Color)
hum.CameraOffset = vt(math.random(-10,10)/100,math.random(-10,10)/100,math.random(-10,10)/100)
	RH.C0=clerp(RH.C0,cf(1,-1,0)*angles(math.rad(0),math.rad(90),math.rad(0))*angles(math.rad(-3),math.rad(0),math.rad(-10)),.2)
LH.C0=clerp(LH.C0,cf(-1,-1,0)*angles(math.rad(0),math.rad(-90),math.rad(0))*angles(math.rad(-3),math.rad(30),math.rad(0)),.2)
RootJoint.C0=clerp(RootJoint.C0,RootCF*cf(0,0.25,0)*angles(math.rad(0),math.rad(0),math.rad(-60)),.3)
Neck.C0=clerp(Neck.C0,necko*angles(math.rad(4),math.rad(0),math.rad(60)),.3)
RW.C0=clerp(RW.C0,cf(1.45,0.5,0.1)*angles(math.rad(90),math.rad(0),math.rad(80)),.3)
LW.C0=clerp(LW.C0,cf(-1.45,0.5,0.1)*angles(math.rad(90),math.rad(0),math.rad(-60)),.3)
weaponweld.C1=clerp(weaponweld.C1,cf(0,1,0)*angles(math.rad(0),math.rad(0),math.rad(0)),.3)
end
slash(5,5,true,"Round","Add","Out",rarmor.CFrame*CFrame.new(0,0,0)*CFrame.Angles(0,0,0),vt(0.05,0.01,0.05),0.05,BrickColor.new("White"))
for i = 0, 1, 0.6 do
		swait()
sphereMK(5,math.random(4,25)/45,"Add",root.CFrame*CFrame.new(math.random(-15,15),-20,math.random(-15,15))*CFrame.Angles(math.rad(90 + math.random(-10,10)),math.rad(math.random(-10,10)),math.rad(math.random(-10,10))),0.75,0.75,20,-0.0075,BrickColor.new("Royal purple"),BrickColor.new("Royal purple").Color,0)
sphereMK(5,math.random(1,15)/45,"Add",root.CFrame*CFrame.new(math.random(-15,15),-20,math.random(-15,15))*CFrame.Angles(math.rad(90 + math.random(-25,25)),math.rad(math.random(-25,25)),math.rad(math.random(-25,25))),0.75,0.75,20,-0.0075,BrickColor.new("Cyan"),BrickColor.new("Cyan").Color,0)
slash(math.random(50,100)/10,5,true,"Round","Add","Out",root.CFrame*CFrame.new(0,-3,0)*CFrame.Angles(math.rad(math.random(-5,5)),math.rad(math.random(-360,360)),math.rad(math.random(-5,5))),vt(0.05,0.01,0.05),math.random(25,50)/250,BrickColor.new("White"))
sphere2(5,"Add",rarmor.CFrame*CFrame.new(math.random(-8,-2),0,0)*CFrame.Angles(math.rad(math.random(-360,360)),math.rad(math.random(-360,360)),math.rad(math.random(-360,360))),vt(0.1,0.1,0.1),0,0.1,0,BrickColor.new("Cyan"),BrickColor.new("Cyan").Color)
hum.CameraOffset = vt(math.random(-10,10)/100,math.random(-10,10)/100,math.random(-10,10)/100)
	RH.C0=clerp(RH.C0,cf(1,-1,0)*angles(math.rad(0),math.rad(90),math.rad(0))*angles(math.rad(-3),math.rad(0),math.rad(-10)),.2)
LH.C0=clerp(LH.C0,cf(-1,-1,0)*angles(math.rad(0),math.rad(-90),math.rad(0))*angles(math.rad(-3),math.rad(30),math.rad(0)),.2)
RootJoint.C0=clerp(RootJoint.C0,RootCF*cf(0,0.25,0)*angles(math.rad(0),math.rad(0),math.rad(-60)),.3)
Neck.C0=clerp(Neck.C0,necko*angles(math.rad(4),math.rad(0),math.rad(60)),.3)
RW.C0=clerp(RW.C0,cf(1.45,0.5,0.1)*angles(math.rad(90),math.rad(0),math.rad(80)),.3)
LW.C0=clerp(LW.C0,cf(-1.45,0.5,0.1)*angles(math.rad(90),math.rad(0),math.rad(-60)),.3)
weaponweld.C1=clerp(weaponweld.C1,cf(0,1,0)*angles(math.rad(0),math.rad(90),math.rad(0)),.3)
end
slash(5,5,true,"Round","Add","Out",rarmor.CFrame*CFrame.new(0,0,0)*CFrame.Angles(0,0,0),vt(0.05,0.01,0.05),0.05,BrickColor.new("White"))
for i = 0, 1, 0.6 do
		swait()
sphereMK(5,math.random(4,25)/45,"Add",root.CFrame*CFrame.new(math.random(-15,15),-20,math.random(-15,15))*CFrame.Angles(math.rad(90 + math.random(-10,10)),math.rad(math.random(-10,10)),math.rad(math.random(-10,10))),0.75,0.75,20,-0.0075,BrickColor.new("Royal purple"),BrickColor.new("Royal purple").Color,0)
sphereMK(5,math.random(1,15)/45,"Add",root.CFrame*CFrame.new(math.random(-15,15),-20,math.random(-15,15))*CFrame.Angles(math.rad(90 + math.random(-25,25)),math.rad(math.random(-25,25)),math.rad(math.random(-25,25))),0.75,0.75,20,-0.0075,BrickColor.new("Cyan"),BrickColor.new("Cyan").Color,0)
slash(math.random(50,100)/10,5,true,"Round","Add","Out",root.CFrame*CFrame.new(0,-3,0)*CFrame.Angles(math.rad(math.random(-5,5)),math.rad(math.random(-360,360)),math.rad(math.random(-5,5))),vt(0.05,0.01,0.05),math.random(25,50)/250,BrickColor.new("White"))
sphere2(5,"Add",rarmor.CFrame*CFrame.new(math.random(-8,-2),0,0)*CFrame.Angles(math.rad(math.random(-360,360)),math.rad(math.random(-360,360)),math.rad(math.random(-360,360))),vt(0.1,0.1,0.1),0,0.1,0,BrickColor.new("Cyan"),BrickColor.new("Cyan").Color)
hum.CameraOffset = vt(math.random(-10,10)/100,math.random(-10,10)/100,math.random(-10,10)/100)
	RH.C0=clerp(RH.C0,cf(1,-1,0)*angles(math.rad(0),math.rad(90),math.rad(0))*angles(math.rad(-3),math.rad(0),math.rad(-10)),.2)
LH.C0=clerp(LH.C0,cf(-1,-1,0)*angles(math.rad(0),math.rad(-90),math.rad(0))*angles(math.rad(-3),math.rad(30),math.rad(0)),.2)
RootJoint.C0=clerp(RootJoint.C0,RootCF*cf(0,0.25,0)*angles(math.rad(0),math.rad(0),math.rad(-60)),.3)
Neck.C0=clerp(Neck.C0,necko*angles(math.rad(4),math.rad(0),math.rad(60)),.3)
RW.C0=clerp(RW.C0,cf(1.45,0.5,0.1)*angles(math.rad(90),math.rad(0),math.rad(80)),.3)
LW.C0=clerp(LW.C0,cf(-1.45,0.5,0.1)*angles(math.rad(90),math.rad(0),math.rad(-60)),.3)
weaponweld.C1=clerp(weaponweld.C1,cf(0,1,0)*angles(math.rad(0),math.rad(180),math.rad(0)),.3)
end
slash(5,5,true,"Round","Add","Out",rarmor.CFrame*CFrame.new(0,0,0)*CFrame.Angles(0,0,0),vt(0.05,0.01,0.05),0.05,BrickColor.new("White"))
for i = 0, 1, 0.6 do
		swait()
sphereMK(5,math.random(4,25)/45,"Add",root.CFrame*CFrame.new(math.random(-15,15),-20,math.random(-15,15))*CFrame.Angles(math.rad(90 + math.random(-10,10)),math.rad(math.random(-10,10)),math.rad(math.random(-10,10))),0.75,0.75,20,-0.0075,BrickColor.new("Royal purple"),BrickColor.new("Royal purple").Color,0)
sphereMK(5,math.random(1,15)/45,"Add",root.CFrame*CFrame.new(math.random(-15,15),-20,math.random(-15,15))*CFrame.Angles(math.rad(90 + math.random(-25,25)),math.rad(math.random(-25,25)),math.rad(math.random(-25,25))),0.75,0.75,20,-0.0075,BrickColor.new("Cyan"),BrickColor.new("Cyan").Color,0)
slash(math.random(50,100)/10,5,true,"Round","Add","Out",root.CFrame*CFrame.new(0,-3,0)*CFrame.Angles(math.rad(math.random(-5,5)),math.rad(math.random(-360,360)),math.rad(math.random(-5,5))),vt(0.05,0.01,0.05),math.random(25,50)/250,BrickColor.new("White"))
sphere2(5,"Add",rarmor.CFrame*CFrame.new(math.random(-8,-2),0,0)*CFrame.Angles(math.rad(math.random(-360,360)),math.rad(math.random(-360,360)),math.rad(math.random(-360,360))),vt(0.1,0.1,0.1),0,0.1,0,BrickColor.new("Cyan"),BrickColor.new("Cyan").Color)
hum.CameraOffset = vt(math.random(-10,10)/100,math.random(-10,10)/100,math.random(-10,10)/100)
	RH.C0=clerp(RH.C0,cf(1,-1,0)*angles(math.rad(0),math.rad(90),math.rad(0))*angles(math.rad(-3),math.rad(0),math.rad(-10)),.2)
LH.C0=clerp(LH.C0,cf(-1,-1,0)*angles(math.rad(0),math.rad(-90),math.rad(0))*angles(math.rad(-3),math.rad(30),math.rad(0)),.2)
RootJoint.C0=clerp(RootJoint.C0,RootCF*cf(0,0.25,0)*angles(math.rad(0),math.rad(0),math.rad(-60)),.3)
Neck.C0=clerp(Neck.C0,necko*angles(math.rad(4),math.rad(0),math.rad(60)),.3)
RW.C0=clerp(RW.C0,cf(1.45,0.5,0.1)*angles(math.rad(90),math.rad(0),math.rad(80)),.3)
LW.C0=clerp(LW.C0,cf(-1.45,0.5,0.1)*angles(math.rad(90),math.rad(0),math.rad(-60)),.3)
weaponweld.C1=clerp(weaponweld.C1,cf(0,1,0)*angles(math.rad(0),math.rad(270),math.rad(0)),.3)
end
end
local hitb = CreateParta(m,1,1,"SmoothPlastic",BrickColor.Random())
hitb.Anchored = true
hitb.CFrame = root.CFrame + root.CFrame.lookVector*8
hitb.CFrame = hitb.CFrame*CFrame.new(0,1,0)
MagniDamage(hitb, 8, 92,158, 0, "Normal",153092213)
sphere2(5,"Add",hitb.CFrame,vt(2.1,2.1,2),-0.02,-0.02,5,BrickColor.new("Royal purple"),BrickColor.new("Royal purple").Color)
sphere2(5,"Add",hitb.CFrame,vt(2,2,2),-0.02,-0.02,4,BrickColor.new("Cyan"),BrickColor.new("Cyan").Color)
for i = 0, 24 do
slash(math.random(20,100)/10,5,true,"Round","Add","Out",hitb.CFrame*CFrame.new(0,0,math.random(-60,60))*CFrame.Angles(math.rad(90),0,0),vt(0.01,0.01,0.01),math.random(10,100)/1000,BrickColor.new("White"))
end
CFuncs["Sound"].Create("rbxassetid://313205954", root, 4,1)
CFuncs["Sound"].Create("rbxassetid://1368637781", rarmor, 4,1)
CFuncs["Sound"].Create("rbxassetid://763718160", rarmor, 5, 1.1)
CFuncs["Sound"].Create("rbxassetid://782353443", rarmor, 6, 1)
--CFuncs["Sound"].Create("rbxassetid://1548538202", rarmor, 4,1)
for i = 0, 2, 0.1 do
		swait()
MagniDamage(hitb, 8, 92,158, 0, "Normal",153092213)
hum.CameraOffset = vt(math.random(-10,10)/25,math.random(-10,10)/25,math.random(-10,10)/25)
	RH.C0=clerp(RH.C0,cf(1,-1,0)*angles(math.rad(0),math.rad(90),math.rad(0))*angles(math.rad(-3),math.rad(-20),math.rad(-10)),.9)
LH.C0=clerp(LH.C0,cf(-1,-1,0)*angles(math.rad(0),math.rad(-90),math.rad(0))*angles(math.rad(-3),math.rad(0),math.rad(0)),.9)
RootJoint.C0=clerp(RootJoint.C0,RootCF*cf(0,-0.5,0)*angles(math.rad(0),math.rad(0),math.rad(80)),.9)
Neck.C0=clerp(Neck.C0,necko*angles(math.rad(4),math.rad(0),math.rad(-80)),.9)
RW.C0=clerp(RW.C0,cf(1.45,0.5,0.1)*angles(math.rad(90),math.rad(0),math.rad(70)),.9)
LW.C0=clerp(LW.C0,cf(-1.45,0.5,0.1)*angles(math.rad(10),math.rad(0),math.rad(-60)),.9)
weaponweld.C1=clerp(weaponweld.C1,cf(2,0,0)*angles(math.rad(90),math.rad(0),math.rad(-90)),.9)
end
hum.CameraOffset = vt(0,0,0)
hitb:Destroy()
attack = false
hum.WalkSpeed = 24
hum.JumpPower = 50
end




----------------------------------------------------------------------------------------------------
-- super jump (the old version used BodyVelocity on the real root part, FDless moves the rig itself)
----------------------------------------------------------------------------------------------------
local flight = nil
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true
local function refreshRayFilter()
	local list = {fx}
	if plr.Character then list[#list + 1] = plr.Character end
	rayParams.FilterDescendantsInstances = list
end
refreshRayFilter()
track(plr.CharacterAdded:Connect(function() task.defer(refreshRayFilter) end))

function superjump()
	attack = true
	hum.JumpPower = 500
	wng1a.Transparency = wng1a.Transparency - 1
	wng1b.Transparency = wng1b.Transparency - 1
	wng2a.Transparency = wng2a.Transparency - 1
	wng2b.Transparency = wng2b.Transparency - 1
	sphere2(5,"Add",root.CFrame,vt(1,1,1),1.5,1.5,1.5,BrickColor.new("Royal purple"),BrickColor.new("Royal purple").Color)
	sphere2(5,"Add",root.CFrame,vt(1,1,1),1,1,1,BrickColor.new("Cyan"),BrickColor.new("Cyan").Color)
	CFuncs["Sound"].Create("rbxassetid://1368637781", root, 7.5, 1)
	for i = 0, 2, 0.1 do
		swait()
		hum.CameraOffset = vt(math.random(-10,10)/100,math.random(-10,10)/100,math.random(-10,10)/100)
		RH.C0=clerp(RH.C0,cf(1,-0.45,-0.45)*angles(math.rad(0),math.rad(90),math.rad(0))*angles(math.rad(-3),math.rad(0),math.rad(20)),.4)
		LH.C0=clerp(LH.C0,cf(-1,-1,0)*angles(math.rad(0),math.rad(-90),math.rad(0))*angles(math.rad(-3),math.rad(0),math.rad(40)),.4)
		RootJoint.C0=clerp(RootJoint.C0,RootCF*cf(0,-0.5,-1)*angles(math.rad(20),math.rad(0),math.rad(0)),.4)
		Neck.C0=clerp(Neck.C0,necko*angles(math.rad(4),math.rad(0),math.rad(0)),.4)
		RW.C0=clerp(RW.C0,cf(1.45,0.5,0.1)*angles(math.rad(10),math.rad(0),math.rad(40)),.4)
		LW.C0=clerp(LW.C0,cf(-1.45,0.5,0.1)*angles(math.rad(10),math.rad(0),math.rad(-40)),.4)
	end

	-- launch: forward + a little up (same direction the old BodyVelocity pushed), held for ~0.5s, then it is just momentum
	local rcf = root.CFrame
	local dir = (rcf * CFrame.new(0, 1, -4)).Position - rcf.Position
	flight = {pos = rcf.Position, vel = dir.Unit * 125, t = 0, hold = 31 * TICK}
	CFuncs["Sound"].Create("rbxassetid://477843807", root, 7, 1)
	local lat1 = Instance.new("Attachment",larm)
	lat1.Position = Vector3.new(1,-1,0.5)
	local lat2 = Instance.new("Attachment",larm)
	lat2.Position = Vector3.new(-1,-1,-0.5)
	local rat1 = Instance.new("Attachment",rarm)
	rat1.Position = Vector3.new(1,-1,-0.5)
	local rat2 = Instance.new("Attachment",rarm)
	rat2.Position = Vector3.new(-1,-1,0.5)
	local tl1 = Instance.new('Trail',larm)
	tl1.Attachment0 = lat1
	tl1.Attachment1 = lat2
	tl1.Texture = "http://www.roblox.com/asset/?id=1049219073"
	tl1.LightEmission = 1
	tl1.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1),NumberSequenceKeypoint.new(0.05, 0),NumberSequenceKeypoint.new(1, 1)})
	tl1.Color = ColorSequence.new(BrickColor.new('Royal purple').Color,BrickColor.new('Cyan').Color)
	tl1.Lifetime = 5
	local tl2 = tl1:Clone()
	tl2.Attachment0 = rat1
	tl2.Attachment1 = rat2
	tl2.Parent = rarm
	swait()
	sphere2(5,"Add",root.CFrame*CFrame.Angles(math.rad(-45),0,0),vt(25,1,25),0.3,5,0.3,BrickColor.new("Royal purple"),BrickColor.new("Royal purple").Color)
	sphere2(5,"Add",root.CFrame*CFrame.Angles(math.rad(-45),0,0),vt(25,1,25),0.2,4,0.2,BrickColor.new("Cyan"),BrickColor.new("Cyan").Color)
	coroutine.resume(coroutine.create(function()
		for i = 0, 2, 0.1 do
			swait()
			hum.CameraOffset = vt(math.random(-10,10)/50,math.random(-10,10)/50,math.random(-10,10)/50)
		end
		hum.CameraOffset = vt(0,0,0)
		wait(3)
		tl1.Enabled = false
		tl2.Enabled = false
		game:GetService("Debris"):AddItem(tl1, 5)
		game:GetService("Debris"):AddItem(tl2, 5)
		game:GetService("Debris"):AddItem(rat1, 5)
		game:GetService("Debris"):AddItem(rat2, 5)
		game:GetService("Debris"):AddItem(lat1, 5)
		game:GetService("Debris"):AddItem(lat2, 5)
	end))
	CFuncs["Sound"].Create("rbxassetid://1295446488", root, 10, 1)
	for i = 0, 3, 0.1 do
		swait()
		RH.C0=clerp(RH.C0,cf(1,-0.45,-0.45)*angles(math.rad(0),math.rad(90),math.rad(0))*angles(math.rad(-3),math.rad(0),math.rad(-20)),.4)
		LH.C0=clerp(LH.C0,cf(-1,-1,0)*angles(math.rad(0),math.rad(-90),math.rad(0))*angles(math.rad(-3),math.rad(0),math.rad(30)),.4)
		RootJoint.C0=clerp(RootJoint.C0,RootCF*cf(0,-0.75,0)*angles(math.rad(40),math.rad(0),math.rad(0)),.4)
		Neck.C0=clerp(Neck.C0,necko*angles(math.rad(-20),math.rad(0),math.rad(0)),.4)
		RW.C0=clerp(RW.C0,cf(1.45,0.5,0.1)*angles(math.rad(-30),math.rad(0),math.rad(20)),.4)
		LW.C0=clerp(LW.C0,cf(-1.45,0.5,0.1)*angles(math.rad(-30),math.rad(0),math.rad(-20)),.4)
	end
	coroutine.resume(coroutine.create(function()
		for i = 0, 99 do
			swait()
			wng1a.Transparency = wng1a.Transparency + 0.01
			wng1b.Transparency = wng1b.Transparency + 0.01
			wng2a.Transparency = wng2a.Transparency + 0.01
			wng2b.Transparency = wng2b.Transparency + 0.01
		end
	end))
	attack = false
	if equipped == false then
		hum.WalkSpeed = 16
	else
		hum.WalkSpeed = 24
	end
	hum.JumpPower = 50
end

-- moves the rig while a super jump is active (called every real frame)
local function flightStep(dt)
	local f = flight
	if not f then return end
	f.t = f.t + dt
	if f.t > f.hold then
		f.vel = f.vel - Vector3.new(0, 196.2 * dt, 0)
	end
	local step = f.vel * dt
	-- wall: stop the horizontal part
	if step.Magnitude > 0 then
		local wall = workspace:Raycast(f.pos, step + step.Unit * 2, rayParams)
		if wall then
			f.vel = Vector3.new(0, math.min(f.vel.Y, 0), 0)
			step = f.vel * dt
		end
	end
	local np = f.pos + step
	if f.vel.Y <= 0 and f.t > f.hold then
		local down = workspace:Raycast(f.pos, Vector3.new(0, -(3.4 + math.max(0, -step.Y)), 0), rayParams)
		if down then
			RE.setCfr(Vector3.new(np.X, down.Position.Y + 3.1, np.Z))
			flight = nil
			return
		end
	end
	if f.t > 8 then flight = nil return end
	f.pos = np
	RE.setCfr(np)
end

----------------------------------------------------------------------------------------------------
-- music + gui
----------------------------------------------------------------------------------------------------
muter = false
ORVOL = 1.15
ORPIT = 1.01
kan = Instance.new("Sound", plr.PlayerGui)
kan.Name = "nepnepnep"
kan.SoundId = getAsset("Neptunian V.mp3")
kan.Volume = ORVOL
kan.PlaybackSpeed = ORPIT
kan.Pitch = ORPIT
kan.Looped = true
kan.TimePosition = 0
kan:Play()


--------------------------- GUI STUFF
basgui = Instance.new("ScreenGui")
basgui.Parent = plr.PlayerGui
basgui.Name = randName()
basgui.ResetOnSpawn = false
local fullscreenz = it("Frame")
fullscreenz.Parent = basgui
fullscreenz.BackgroundColor3 = Color3.new(255, 255, 255)
fullscreenz.BackgroundTransparency = 1
fullscreenz.BorderColor3 = Color3.new(17, 17, 17)
fullscreenz.Size = UDim2.new(1, 0, 1, 0)
fullscreenz.Position = UDim2.new(0, 0, 0, 0)
imgl2 = Instance.new("ImageLabel",fullscreenz)
imgl2.BackgroundTransparency = 1
imgl2.BorderSizePixel = 0
imgl2.ImageTransparency = 0.5
imgl2.ImageColor3 = Color3.new(1,0,0)
imgl2.Position = UDim2.new(0.75,0,0.55,0)
imgl2.Size = UDim2.new(0,600,0,600)
imgl2.Image = "rbxassetid://320731120"
techc = imgl2:Clone()
techc.Parent = fullscreenz
techc.ImageTransparency = 0.5
techc.Size = UDim2.new(0,700,0,700)
techc.Position = UDim2.new(0.75,-50,0.55,-50)
techc.ImageColor3 = Color3.new(0.5,0,1)
techc.Image = "rbxassetid://521073910"
local circl = imgl2:Clone()
circl.Parent = fullscreenz
circl.ImageTransparency = 0
circl.Size = UDim2.new(0,500,0,500)
circl.Position = UDim2.new(0.75,50,0.55,50)
circl.ImageColor3 = Color3.new(0,0.5,1)
circl.Image = "rbxassetid://997291547"
local circl2 = imgl2:Clone()
circl2.Parent = fullscreenz
circl2.ImageTransparency = 0
circl2.ImageColor3 = Color3.new(0.5,0,1)
circl2.Image = "rbxassetid://997291547"
imgl2b = imgl2:Clone()
imgl2b.Parent = fullscreenz
imgl2b.ImageTransparency = 0
imgl2b.Size = UDim2.new(0,500,0,500)
imgl2b.Position = UDim2.new(0.75,50,0.55,50)
ned = Instance.new("TextLabel",fullscreenz)
ned.ZIndex = 2
ned.Font = "SciFi"
ned.BackgroundTransparency = 1
ned.BorderSizePixel = 0.65
ned.Size = UDim2.new(0.4,0,0.2,0)
ned.Position = UDim2.new(0.6,0,0.8,0)
ned.TextColor3 = BrickColor.new("Royal purple").Color
ned.TextStrokeColor3 = BrickColor.new("Cyan").Color
ned.TextScaled = true
ned.TextStrokeTransparency = 0
ned.Text = "Yeh! Im Tory"
ned.TextSize = 24
ned.Rotation = 1
--ned.TextXAlignment = "Right"
ned.TextYAlignment = "Bottom"
NEP_track("Neptunian V.mp3")

local function guiStep(dt)
	local k = dt * 60
	if muter == false then kan.Volume = ORVOL else kan.Volume = 0 end
	kan.PlaybackSpeed = ORPIT
	kan.Pitch = ORPIT
	kan.Looped = true
	if not kan.IsPlaying then pcall(function() kan:Play() end) end
	local loud = kan.PlaybackLoudness
	techc.Rotation = techc.Rotation + 0.1 * k
	imgl2.Rotation = imgl2.Rotation - loud / 50 * k
	imgl2.ImageColor3 = Color3.new(0.15 + loud / 2500, 0, 0.6 + loud / 1000)
	imgl2b.Rotation = imgl2b.Rotation + loud / 25 * k
	imgl2b.ImageColor3 = Color3.new(0, 0.3 + loud / 1500, 0.6 + loud / 1000)
	ned.Rotation = 0 - 2 * math.cos(sine / 24)
	ned.Position = UDim2.new(0.6, 0 - 10 * math.cos(sine / 32), 0.8, 0 - 10 * math.cos(sine / 45))
end

----------------------------------------------------------------------------------------------------
-- animation step (the old main loop body, runs once per 60Hz logic tick)
----------------------------------------------------------------------------------------------------
BanishMode = 1
function animStep()
    sine = sine + change
    local torvel = (velNow * Vector3.new(1, 0, 1)).Magnitude
local hitfloor = (fdState == "idle" or fdState == "walk") and true or nil
    
    if equipped == true or equipped == false then
        if attack == false then
            idle = idle + 1
        else
            idle = 0
        end
        
if velNow.Y > 1 and hitfloor==nil then 
Anim="Jump"
if attack==false then
RH.C0=clerp(RH.C0,cf(1,-0.35 - 0.05 * math.cos(sine / 25),-0.75)*angles(math.rad(0),math.rad(90),math.rad(0))*angles(math.rad(-5),math.rad(0),math.rad(-20)),.1)
LH.C0=clerp(LH.C0,cf(-1,-1 - 0.05 * math.cos(sine / 25),0)*angles(math.rad(0),math.rad(-90),math.rad(0))*angles(math.rad(-5),math.rad(0),math.rad(20)),.1)
RootJoint.C0=clerp(RootJoint.C0,RootCF*cf(0,0,0 + 0.05 * math.cos(sine / 25))*angles(math.rad(-velNow.Y/6),math.rad(0),math.rad(0)),.1)
Neck.C0=clerp(Neck.C0,necko*angles(math.rad(-2.5),math.rad(0),math.rad(0)),.1)
RW.C0=clerp(RW.C0,cf(1.45,0.5 + 0.1 * math.cos(sine / 25),0)*angles(math.rad(-5),math.rad(0),math.rad(25)),.1)
LW.C0=clerp(LW.C0,cf(-1.45,0.5 + 0.1 * math.cos(sine / 25),0)*angles(math.rad(-5),math.rad(0),math.rad(-25)),.1)
if equipped == false then
weaponweld.C1=clerp(weaponweld.C1,cf(-3,0,-0.5)*angles(math.rad(0),math.rad(0),math.rad(-40)),.3)
else
weaponweld.C1=clerp(weaponweld.C1,cf(0,1,0)*angles(math.rad(0),math.rad(130),math.rad(0)),.3)
end
end
elseif velNow.Y < -1 and hitfloor==nil then 
Anim="Fall"
if attack==false then
RH.C0=clerp(RH.C0,cf(1,-0.35 - 0.05 * math.cos(sine / 25),-0.75)*angles(math.rad(0),math.rad(90),math.rad(0))*angles(math.rad(-5),math.rad(0),math.rad(-20)),.1)
LH.C0=clerp(LH.C0,cf(-1,-1 - 0.05 * math.cos(sine / 25),0)*angles(math.rad(0),math.rad(-90),math.rad(0))*angles(math.rad(-5),math.rad(0),math.rad(20)),.1)
RootJoint.C0=clerp(RootJoint.C0,RootCF*cf(0,0,0 + 0.05 * math.cos(sine / 25))*angles(math.rad(-velNow.Y/6),math.rad(0),math.rad(0)),.1)
Neck.C0=clerp(Neck.C0,necko*angles(math.rad(2.5),math.rad(0),math.rad(0)),.1)
RW.C0=clerp(RW.C0,cf(1.45,0.5 + 0.1 * math.cos(sine / 25),0)*angles(math.rad(-15),math.rad(0),math.rad(55)),.1)
LW.C0=clerp(LW.C0,cf(-1.45,0.5 + 0.1 * math.cos(sine / 25),0)*angles(math.rad(-15),math.rad(0),math.rad(-55)),.1)
if equipped == false then
weaponweld.C1=clerp(weaponweld.C1,cf(-3,0,-0.5)*angles(math.rad(0),math.rad(0),math.rad(-40)),.3)
else
weaponweld.C1=clerp(weaponweld.C1,cf(0,1,0)*angles(math.rad(0),math.rad(130),math.rad(0)),.3)
end
end
elseif torvel<1 and hitfloor~=nil then
Anim="Idle"
if attack==false and BanishMode == 1 then
if equipped == false then
RH.C0=clerp(RH.C0,cf(1,-1 + 0.05 * math.cos(sine / 20)  - 0.02 * math.cos(sine / 40),0)*angles(math.rad(0),math.rad(90),math.rad(0))*angles(math.rad(-3 + 2 * math.cos(sine / 40)),math.rad(-15),math.rad(0 + 2 * math.cos(sine / 20))),.1)
LH.C0=clerp(LH.C0,cf(-1,-1 + 0.05 * math.cos(sine / 20) - 0.02 * math.cos(sine / 40),0)*angles(math.rad(0),math.rad(-90),math.rad(0))*angles(math.rad(-3 - 2 * math.cos(sine / 40)),math.rad(1),math.rad(0 - 2 * math.cos(sine / 20))),.1)
RootJoint.C0=clerp(RootJoint.C0,RootCF*cf(0 + 0.02 * math.cos(sine / 40),0 - 0.02 * math.cos(sine / 40),-0.05 - 0.05 * math.cos(sine / 20))*angles(math.rad(0 + 2 * math.cos(sine / 20)),math.rad(0 + 2 * math.cos(sine / 40)),math.rad(30 + 3 * math.cos(sine / 40))),.1)
Neck.C0=clerp(Neck.C0,necko*angles(math.rad(2),math.rad(0 - 7 * math.cos(sine / 40)),math.rad(-30 - 3 * math.cos(sine / 40))),.1)
RW.C0=clerp(RW.C0,cf(1.45,0.5 + 0.05 * math.cos(sine / 28),0.1)*angles(math.rad(-6 + 5 * math.cos(sine / 26)),math.rad(-10 - 6 * math.cos(sine / 24)),math.rad(13 - 5 * math.cos(sine / 34))),.1)
LW.C0=clerp(LW.C0,cf(-1.4,0.5 + 0.05 * math.cos(sine / 28),0.1)*angles(math.rad(-13 - 1 * math.cos(sine / 25)),math.rad(10 + 2 * math.cos(sine / 24)),math.rad(10 + 2 * math.cos(sine / 34))),.1)
weaponweld.C1=clerp(weaponweld.C1,cf(-3,0,-0.5)*angles(math.rad(0),math.rad(0),math.rad(-40)),.3)
else
RH.C0=clerp(RH.C0,cf(1,-0.5 + -0.266 * math.sin(sine / 20)  - 0.05 * math.sin(sine / 40),-0.25)*angles(math.rad(0),math.rad(90),math.rad(0))*angles(math.rad(-6 + 4 * math.cos(sine / 40)),math.rad(0 - 8 * math.cos(sine / 40)),math.rad(-10 + 5 * math.cos(sine / 20) - 6 * math.cos(sine / 40))),.1)
LH.C0=clerp(LH.C0,cf(-1,-1 + -0.266 * math.sin(sine / 20) - 0.05 * math.sin(sine / 40),0)*angles(math.rad(0),math.rad(-90),math.rad(0))*angles(math.rad(-6 - 4 * math.cos(sine / 40)),math.rad(10 - 8 * math.cos(sine / 40)),math.rad(10 - 5 * math.cos(sine / 20) - 3 * math.cos(sine / 40))),.1)
RootJoint.C0=clerp(RootJoint.C0,RootCF*cf(0 + 0.02 * math.cos(sine / 40),0 - 0.05 * math.cos(sine / 40),1 - 0.266 * math.cos(sine / 20))*angles(math.rad(6 + -5 * math.cos(sine / 20)),math.rad(0 + 5 * math.cos(sine / 40)),math.rad(-20 + 16 * math.cos(sine / 40))),.1)
Neck.C0=clerp(Neck.C0,necko*angles(math.rad(20 - 4 * math.sin(sine / 42)),math.rad(0 - 4 * math.sin(sine / 40)),math.rad(20 - 30 * math.sin(sine / 40))),.1)
RW.C0=clerp(RW.C0,cf(1.45,0.5 + 0.3 * math.sin(sine / 20),0.1)*angles(math.rad(-13 + 3 * math.cos(sine / 26)),math.rad(-20 - 3 * math.cos(sine / 24)),math.rad(20 - 5 * math.cos(sine / 34))),.1)
LW.C0=clerp(LW.C0,cf(-1.45,0.5 + 0.3 * math.sin(sine / 20),0.1)*angles(math.rad(-13 - 3 * math.cos(sine / 25)),math.rad(10 + 3 * math.cos(sine / 24)),math.rad(-10 + 5 * math.cos(sine / 34))),.1)
weaponweld.C1=clerp(weaponweld.C1,cf(0,1,0)*angles(math.rad(0),math.rad(190 + -90 * math.sin(sine / 40)),math.rad(0)),.3)
end
end
if attack==false and BanishMode == 7 then
if equipped == false then
RH.C0=clerp(RH.C0,cf(1,-1 + 0.05 * math.cos(sine / 20)  - 0.02 * math.cos(sine / 40),0)*angles(math.rad(0),math.rad(90),math.rad(0))*angles(math.rad(-3 + 2 * math.cos(sine / 40)),math.rad(-15),math.rad(0 + 2 * math.cos(sine / 20))),.1)
LH.C0=clerp(LH.C0,cf(-1,-1 + 0.05 * math.cos(sine / 20) - 0.02 * math.cos(sine / 40),0)*angles(math.rad(0),math.rad(-90),math.rad(0))*angles(math.rad(-3 - 2 * math.cos(sine / 40)),math.rad(1),math.rad(0 - 2 * math.cos(sine / 20))),.1)
RootJoint.C0=clerp(RootJoint.C0,RootCF*cf(0 + 0.02 * math.cos(sine / 40),0 - 0.02 * math.cos(sine / 40),-0.05 - 0.05 * math.cos(sine / 20))*angles(math.rad(0 + 2 * math.cos(sine / 20)),math.rad(0 + 2 * math.cos(sine / 40)),math.rad(30 + 3 * math.cos(sine / 40))),.1)
Neck.C0=clerp(Neck.C0,necko*angles(math.rad(2),math.rad(0 - 7 * math.cos(sine / 40)),math.rad(-30 - 3 * math.cos(sine / 40))),.1)
RW.C0=clerp(RW.C0,cf(1.45,0.5 + 0.05 * math.cos(sine / 28),0.1)*angles(math.rad(-6 + 5 * math.cos(sine / 26)),math.rad(-10 - 6 * math.cos(sine / 24)),math.rad(13 - 5 * math.cos(sine / 34))),.1)
LW.C0=clerp(LW.C0,cf(-1.4,0.5 + 0.05 * math.cos(sine / 28),0.1)*angles(math.rad(-13 - 1 * math.cos(sine / 25)),math.rad(10 + 2 * math.cos(sine / 24)),math.rad(10 + 2 * math.cos(sine / 34))),.1)
weaponweld.C1=clerp(weaponweld.C1,cf(-3,0,-0.5)*angles(math.rad(0),math.rad(0),math.rad(190 + -600 * math.sin(sine / 40))),.3)
else
RH.C0=clerp(RH.C0,cf(1,-0.5 + -0.266 * math.sin(sine / 20)  - 0.05 * math.sin(sine / 40),-0.25)*angles(math.rad(0),math.rad(90),math.rad(0))*angles(math.rad(-6 + 4 * math.cos(sine / 40)),math.rad(0 - 8 * math.cos(sine / 40)),math.rad(-10 + 5 * math.cos(sine / 20) - 6 * math.cos(sine / 40))),.1)
LH.C0=clerp(LH.C0,cf(-1,-1 + -0.266 * math.sin(sine / 20) - 0.05 * math.sin(sine / 40),0)*angles(math.rad(0),math.rad(-90),math.rad(0))*angles(math.rad(-6 - 4 * math.cos(sine / 40)),math.rad(10 - 8 * math.cos(sine / 40)),math.rad(10 - 5 * math.cos(sine / 20) - 3 * math.cos(sine / 40))),.1)
RootJoint.C0=clerp(RootJoint.C0,RootCF*cf(0 + 0.02 * math.cos(sine / 40),0 - 0.05 * math.cos(sine / 40),1 - 0.266 * math.cos(sine / 20))*angles(math.rad(6 + -5 * math.cos(sine / 20)),math.rad(0 + 5 * math.cos(sine / 40)),math.rad(10 + 16 * math.cos(sine / 40))),.1)
Neck.C0=clerp(Neck.C0,necko*angles(math.rad(1+math.random(-10,10)), math.rad(0+math.random(-10,10)), math.rad(0+math.random(-10,10))),.1)
RW.C0=clerp(RW.C0,cf(1.45,0.5 + 0.3 * math.sin(sine / 20),0.1)*angles(math.rad(10 + 3 * math.cos(sine / 26)),math.rad(8 - 3 * math.cos(sine / 24)),math.rad(20 - 5 * math.cos(sine / 34))),.1)
LW.C0=clerp(LW.C0,cf(-1.45,0.5 + 0.3 * math.sin(sine / 20),0.1)*angles(math.rad(10 - 3 * math.cos(sine / 25)),math.rad(10 + 3 * math.cos(sine / 24)),math.rad(-10 + 5 * math.cos(sine / 34))),.1)
weaponweld.C1=clerp(weaponweld.C1,cf(0.5 + 5 * math.cos(sine / 30),0,-1.5)*angles(math.rad(0),math.rad(0),math.rad(190 + -800 * math.sin(sine / 40))),.3)
end
end
if attack==false and BanishMode == 2 then
if equipped == false then
RH.C0=clerp(RH.C0,cf(1,-1 + 0.05 * math.cos(sine / 20)  - 0.02 * math.cos(sine / 40),0)*angles(math.rad(0),math.rad(90),math.rad(0))*angles(math.rad(-3 + 2 * math.cos(sine / 40)),math.rad(-15),math.rad(0 + 2 * math.cos(sine / 20))),.1)
LH.C0=clerp(LH.C0,cf(-1,-1 + 0.05 * math.cos(sine / 20) - 0.02 * math.cos(sine / 40),0)*angles(math.rad(0),math.rad(-90),math.rad(0))*angles(math.rad(-3 - 2 * math.cos(sine / 40)),math.rad(1),math.rad(0 - 2 * math.cos(sine / 20))),.1)
RootJoint.C0=clerp(RootJoint.C0,RootCF*cf(0 + 0.02 * math.cos(sine / 40),0 - 0.02 * math.cos(sine / 40),-0.05 - 0.05 * math.cos(sine / 20))*angles(math.rad(0 + 2 * math.cos(sine / 20)),math.rad(0 + 2 * math.cos(sine / 40)),math.rad(30 + 3 * math.cos(sine / 40))),.1)
Neck.C0=clerp(Neck.C0,necko*angles(math.rad(-10 - 15 * math.cos(sine / 0.5)),math.rad(5 - 15 * math.cos(sine / 0.5)),math.rad(20 - 20 * math.cos(sine / 0.5))),.1)
RW.C0=clerp(RW.C0,cf(1.45,0.5 + 0.05 * math.cos(sine / 28),0.1)*angles(math.rad(-6 + 5 * math.cos(sine / 26)),math.rad(-10 - 6 * math.cos(sine / 24)),math.rad(13 - 5 * math.cos(sine / 34))),.1)
LW.C0=clerp(LW.C0,cf(-1.4,0.5 + 0.05 * math.cos(sine / 28),0.1)*angles(math.rad(-13 - 1 * math.cos(sine / 25)),math.rad(10 + 2 * math.cos(sine / 24)),math.rad(10 + 2 * math.cos(sine / 34))),.1)
weaponweld.C1=clerp(weaponweld.C1,cf(-3,0,-0.5)*angles(math.rad(0),math.rad(0),math.rad(-40)),.3)
else
RH.C0=clerp(RH.C0,cf(1,-1 + 0.05 * math.cos(sine / 20)  - 0.02 * math.cos(sine / 40),0)*angles(math.rad(0),math.rad(90),math.rad(0))*angles(math.rad(-6 + 4 * math.cos(sine / 40)),math.rad(0 - 8 * math.cos(sine / 40)),math.rad(10 + -5 * math.cos(sine / 40) - 6 * math.cos(sine / 40))),.1)
LH.C0=clerp(LH.C0,cf(-1,-1 + 0.05 * math.cos(sine / 20) - 0.02 * math.cos(sine / 40),0)*angles(math.rad(0),math.rad(-90),math.rad(0))*angles(math.rad(-6 - 4 * math.cos(sine / 40)),math.rad(10 - 8 * math.cos(sine / 40)),math.rad(-10 - -5 * math.cos(sine / 40) - 3 * math.cos(sine / 40))),.1)
RootJoint.C0=clerp(RootJoint.C0,RootCF*cf(0 + 0.02 * math.cos(sine / 40),0 - 0.06 * math.cos(sine / 40),-0.05 - 0.08 * math.cos(sine / 20))*angles(math.rad(22 + -5 * math.cos(sine / 20)),math.rad(1 + 0.5 * math.cos(sine / 40)),math.rad(-10 + 8 * math.cos(sine / 40))),.1)
Neck.C0=clerp(Neck.C0,necko*angles(math.rad(-10 - 15 * math.cos(sine / 0.5)),math.rad(5 - 15 * math.cos(sine / 0.5)),math.rad(20 - 20 * math.cos(sine / 0.5))),.1)
RW.C0=clerp(RW.C0,cf(1.45,0.5 + 0.155 * math.sin(sine / 20),0.1)*angles(math.rad(25 + 3 * math.cos(sine / 26)),math.rad(30 - 3 * math.cos(sine / 24)),math.rad(60 - 5 * math.cos(sine / 34))),.1)
LW.C0=clerp(LW.C0,cf(-1.45,0.5 + 0.155 * math.sin(sine / 20),0.1)*angles(math.rad(25 - 3 * math.cos(sine / 25)),math.rad(10 + 3 * math.cos(sine / 24)),math.rad(-10 + 5 * math.cos(sine / 34))),.1)
weaponweld.C1=clerp(weaponweld.C1,cf(0,1,0)*angles(math.rad(0),math.rad(180 + -360 * math.sin(sine / 40)),math.rad(0)),.3)
end
end

if attack==false and BanishMode == 4 then
if equipped == false then
RH.C0=clerp(RH.C0,cf(1,-1 + 0.05 * math.cos(sine / 20)  - 0.02 * math.cos(sine / 40),0)*angles(math.rad(0),math.rad(90),math.rad(0))*angles(math.rad(-3 + 2 * math.cos(sine / 40)),math.rad(-15),math.rad(0 + 2 * math.cos(sine / 20))),.1)
LH.C0=clerp(LH.C0,cf(-1,-1 + 0.05 * math.cos(sine / 20) - 0.02 * math.cos(sine / 40),0)*angles(math.rad(0),math.rad(-90),math.rad(0))*angles(math.rad(-3 - 2 * math.cos(sine / 40)),math.rad(1),math.rad(0 - 2 * math.cos(sine / 20))),.1)
RootJoint.C0=clerp(RootJoint.C0,RootCF*cf(0 + 0.02 * math.cos(sine / 40),0 - 0.02 * math.cos(sine / 40),-0.05 - 0.05 * math.cos(sine / 20))*angles(math.rad(0 + 2 * math.cos(sine / 20)),math.rad(0 + 2 * math.cos(sine / 40)),math.rad(30 + 3 * math.cos(sine / 40))),.1)
Neck.C0=clerp(Neck.C0,necko*angles(math.rad(-10 - 15 * math.cos(sine / 0.5)),math.rad(5 - 15 * math.cos(sine / 0.5)),math.rad(20 - 20 * math.cos(sine / 0.5))),.1)
RW.C0=clerp(RW.C0,cf(1.45,0.5 + 0.05 * math.cos(sine / 28),0.1)*angles(math.rad(-6 + 5 * math.cos(sine / 26)),math.rad(-10 - 6 * math.cos(sine / 24)),math.rad(13 - 5 * math.cos(sine / 34))),.1)
LW.C0=clerp(LW.C0,cf(-1.4,0.5 + 0.05 * math.cos(sine / 28),0.1)*angles(math.rad(-13 - 1 * math.cos(sine / 25)),math.rad(10 + 2 * math.cos(sine / 24)),math.rad(10 + 2 * math.cos(sine / 34))),.1)
weaponweld.C1=clerp(weaponweld.C1,cf(-3,0,-0.5)*angles(math.rad(0),math.rad(0),math.rad(-40)),.3)
else
RH.C0=clerp(RH.C0,cf(1,-1 + -0.05 * math.cos(sine / 80)  - 0.02 * math.cos(sine / 80),-0)*angles(math.rad(0),math.rad(90),math.rad(0))*angles(math.rad(-6 + 4 * math.cos(sine / 80)),math.rad(10 - 8 * math.cos(sine / 80)),math.rad(10 + -5 * math.cos(sine / 80) - 6 * math.cos(sine / 80))),.1)
LH.C0=clerp(LH.C0,cf(-1,-1 + 0.05 * math.cos(sine / 80) - 0.02 * math.cos(sine / 80),0)*angles(math.rad(0),math.rad(-90),math.rad(0))*angles(math.rad(-6 - 4 * math.cos(sine / 80)),math.rad(10 - 8 * math.cos(sine / 80)),math.rad(-10 - -5 * math.cos(sine / 80) - 6 * math.cos(sine / 80))),.1)
RootJoint.C0=clerp(RootJoint.C0,RootCF*cf(0 + 0.1 * math.cos(sine / 80),0 - 0.095 * math.cos(sine / 80),-0 - 0.122 * math.cos(sine / 40))*angles(math.rad(12.6 + -5 * math.cos(sine / 40)),math.rad(1 + 0.5 * math.cos(sine / 40)),math.rad(-10 + 8 * math.cos(sine / 80))),.1)
Neck.C0=clerp(Neck.C0,necko*angles(math.rad(18+math.random(-30,30)), math.rad(0+math.random(-30,30)), math.rad(0+math.random(-30,30))),.1)
RW.C0=clerp(RW.C0,cf(1.45,0.5 + 0.2 * math.sin(sine / 40),0.1)*angles(math.rad(20+math.random(-10,10)), math.rad(10+math.random(-10,10)), math.rad(12+math.random(-10,10))),.1)
LW.C0=clerp(LW.C0,cf(-1.45,0.5 + 0.2 * math.sin(sine / 40),0.1)*angles(math.rad(25 - 3 * math.cos(sine / 25)),math.rad(30 + 3 * math.sin(sine / 40)),math.rad(-10 + 5 * math.cos(sine / 34))),.1)
weaponweld.C1=clerp(weaponweld.C1,cf(0,1,0)*angles(math.rad(0 + -0.1 * math.sin(sine / 0.5)),math.rad(180 + -90 * math.sin(sine / 40)),math.rad(0 + -0.1 * math.sin(sine / 0.5))),.3)
end
end

if attack==false and BanishMode == 5 then
if equipped == false then
kan.Pitch = 1
RH.C0=clerp(RH.C0,cf(1,-1 + 0.05 * math.cos(sine / 20)  - 0.02 * math.cos(sine / 40),0)*angles(math.rad(0),math.rad(90),math.rad(0))*angles(math.rad(-3 + 2 * math.cos(sine / 40)),math.rad(-15),math.rad(0 + 2 * math.cos(sine / 20))),.1)
LH.C0=clerp(LH.C0,cf(-1,-1 + 0.05 * math.cos(sine / 20) - 0.02 * math.cos(sine / 40),0)*angles(math.rad(0),math.rad(-90),math.rad(0))*angles(math.rad(-3 - 2 * math.cos(sine / 40)),math.rad(1),math.rad(0 - 2 * math.cos(sine / 20))),.1)
RootJoint.C0=clerp(RootJoint.C0,RootCF*cf(0 + 0.02 * math.cos(sine / 40),0 - 0.02 * math.cos(sine / 40),-0.05 - 0.05 * math.cos(sine / 20))*angles(math.rad(0 + 2 * math.cos(sine / 20)),math.rad(0 + 2 * math.cos(sine / 40)),math.rad(-30 + 10 * math.sin(sine / 40))),.1)
Neck.C0=clerp(Neck.C0,necko*angles(math.rad(1+math.random(-10,10)), math.rad(0+math.random(-10,10)), math.rad(0+math.random(-10,10))),.1)
RW.C0=clerp(RW.C0,cf(1.45,0.5 + 0.05 * math.cos(sine / 28),0.1)*angles(math.rad(-6 + 5 * math.cos(sine / 26)),math.rad(-10 - 6 * math.cos(sine / 24)),math.rad(13 - 5 * math.cos(sine / 34))),.1)
LW.C0=clerp(LW.C0,cf(-1.4,0.5 + 0.05 * math.cos(sine / 28),0.1)*angles(math.rad(-13 - 1 * math.cos(sine / 25)),math.rad(10 + 2 * math.cos(sine / 24)),math.rad(10 + 2 * math.cos(sine / 34))),.1)
weaponweld.C1=clerp(weaponweld.C1,cf(-3,0,-0.5)*angles(math.rad(0),math.rad(0),math.rad(-40)),.3)
else
kan.Pitch = 1
RH.C0=clerp(RH.C0,cf(1,-1 + -0.255 * math.cos(sine / 40)  - 0 * math.cos(sine / 40),-0)*angles(math.rad(0),math.rad(90),math.rad(0))*angles(math.rad(-8 + 0 * math.cos(sine / 80)),math.rad(0 - 0 * math.cos(sine / 80)),math.rad(0 + -0 * math.cos(sine / 80) - 0 * math.cos(sine / 40))),.1)
LH.C0=clerp(LH.C0,cf(-1,-1 + -0.255 * math.cos(sine / 40) - 0 * math.cos(sine / 40),0)*angles(math.rad(0),math.rad(-90),math.rad(0))*angles(math.rad(-8 - 0 * math.cos(sine / 80)),math.rad(0 - 0 * math.cos(sine / 80)),math.rad(0 - -0 * math.cos(sine / 80) - 0 * math.cos(sine / 40))),.1)
RootJoint.C0=clerp(RootJoint.C0,RootCF*cf( 0 + 0 * math.cos(sine / 40),0 - 0 * math.cos(sine / 40),0 - -0.255 * math.cos(sine / 40))*angles(math.rad(1 + -0.1 * math.cos(sine / 40)),math.rad(1 + 0.1 * math.cos(sine / 40)),math.rad(-1 + 2 * math.cos(sine / 40))),.1)
Neck.C0=clerp(Neck.C0,necko*angles(math.rad(1+math.random(-10,10)), math.rad(0+math.random(-10,10)), math.rad(0+math.random(-10,10))),.1)
RW.C0=clerp(RW.C0,cf(1.45,0.585 + -0.277 * math.sin(sine / 40),0.1)*angles(math.rad(-20+math.random(-10,10)), math.rad(10+math.random(-10,10)), math.rad(-150+math.random(-10,10))),.1)
LW.C0=clerp(LW.C0,cf(-1.45,0.5 + -0.277 * math.sin(sine / 40),0.1)*angles(math.rad(5 - 3 * math.cos(sine / 25)),math.rad(0 + 10 * math.sin(sine / 40)),math.rad(-12 + -11 * math.cos(sine / 40))),.1)
weaponweld.C1=clerp(weaponweld.C1,cf(0,1,0)*angles(math.rad(0 + -0 * math.sin(sine / 0.5)),math.rad(-90 + -5 * math.sin(sine / 40)),math.rad(0 + -0.1 * math.sin(sine / 0.5))),.3)
end
end

if attack==false and BanishMode == 1000 then
if equipped == false then
RH.C0=clerp(RH.C0,cf(1,-1 + 0.05 * math.cos(sine / 20)  - 0.02 * math.cos(sine / 40),0)*angles(math.rad(0),math.rad(90),math.rad(0))*angles(math.rad(-3 + 2 * math.cos(sine / 40)),math.rad(-15),math.rad(0 + 2 * math.cos(sine / 20))),.1)
LH.C0=clerp(LH.C0,cf(-1,-1 + 0.05 * math.cos(sine / 20) - 0.02 * math.cos(sine / 40),0)*angles(math.rad(0),math.rad(-90),math.rad(0))*angles(math.rad(-3 - 2 * math.cos(sine / 40)),math.rad(1),math.rad(0 - 2 * math.cos(sine / 20))),.1)
RootJoint.C0=clerp(RootJoint.C0,RootCF*cf(0 + 0.02 * math.cos(sine / 40),0 - 0.02 * math.cos(sine / 40),-0.05 - 0.05 * math.cos(sine / 20))*angles(math.rad(0 + 2 * math.cos(sine / 20)),math.rad(0 + 2 * math.cos(sine / 40)),math.rad(30 + 3 * math.cos(sine / 40))),.1)
Neck.C0=clerp(Neck.C0,necko*angles(math.rad(1+math.random(-10,10)), math.rad(0+math.random(-10,10)), math.rad(0+math.random(-10,10))),.1)
RW.C0=clerp(RW.C0,cf(1.45,0.5 + 0.05 * math.cos(sine / 28),0.1)*angles(math.rad(-6 + 5 * math.cos(sine / 26)),math.rad(-10 - 6 * math.cos(sine / 24)),math.rad(13 - 5 * math.cos(sine / 34))),.1)
LW.C0=clerp(LW.C0,cf(-1.4,0.5 + 0.05 * math.cos(sine / 28),0.1)*angles(math.rad(-13 - 1 * math.cos(sine / 25)),math.rad(10 + 2 * math.cos(sine / 24)),math.rad(10 + 2 * math.cos(sine / 34))),.1)
weaponweld.C1=clerp(weaponweld.C1,cf(-3,0,-0.5)*angles(math.rad(0),math.rad(0),math.rad(-40)),.3)
else
RH.C0=clerp(RH.C0,cf(1 + 0 * (1+math.random(-10,10)),-1 + -0.255 * (1+math.random(-10,10))  - 0 * (1+math.random(-10,10)),-0 + 0 * (1+math.random(-10,10)))*angles(math.rad(0),math.rad(90),math.rad(0))*angles(math.rad(-8 + 0 * math.cos(sine / 80)),math.rad(0 - 0 * math.cos(sine / 80)),math.rad(0 + -0 * math.cos(sine / 80) - 0 * math.cos(sine / 40))),.1)
LH.C0=clerp(LH.C0,cf(-1 + 0 * (1+math.random(-10,10)),-1 + -0.255 * (1+math.random(-10,10)) - 0 * (1+math.random(-10,10)),0 + 0 * (1+math.random(-10,10)))*angles(math.rad(0),math.rad(-90),math.rad(0))*angles(math.rad(-8 - 0 * math.cos(sine / 80)),math.rad(0 - 0 * math.cos(sine / 80)),math.rad(0 - -0 * math.cos(sine / 80) - 0 * math.cos(sine / 40))),.1)
RootJoint.C0=clerp(RootJoint.C0,RootCF*cf( 0 + 0 * (1+math.random(-10,10)),0 - 0 * (1+math.random(-10,10)),0 - -0.255 * (1+math.random(-2.5,10)))*angles(math.rad(1 + -0.1 * math.cos(sine / 40)),math.rad(1 + 0.1 * math.cos(sine / 40)),math.rad(-10 + 2 * math.cos(sine / 40))),.1)
Neck.C0=clerp(Neck.C0,necko*angles(math.rad(1+math.random(-10,10)), math.rad(0+math.random(-10,10)), math.rad(0+math.random(-10,10))),.1)
RW.C0=clerp(RW.C0,cf(1.45 + 0 * (1+math.random(-10,10)),0.585 + -0.277 * (1+math.random(-10,10)),-0.15 - 0 * (1+math.random(-10,10)))*angles(math.rad(-20+math.random(-10,10)), math.rad(10+math.random(-10,10)), math.rad(-150+math.random(-10,10))),.1)
LW.C0=clerp(LW.C0,cf(-1.45 + 0 * (1+math.random(-10,10)),0.5 + -0.277 * (1+math.random(-10,10)),0.1 - 0 * (1+math.random(-10,10)))*angles(math.rad(5 - 3 * math.cos(sine / 25)),math.rad(0 + 10 * math.sin(sine / 40)),math.rad(-12 + -11 * math.cos(sine / 40))),.1)
weaponweld.C1=clerp(weaponweld.C1,cf(0,1,0)*angles(math.rad(0 + -0 * math.sin(sine / 0.5)),math.rad(-90 + -5 * math.sin(sine / 40)),math.rad(0 + -0.1 * math.sin(sine / 0.5))),.3)
end
end

if attack==false and BanishMode == "KAR" then
RH.C0=clerp(RH.C0,cf(1,0.255 + 0.05 * math.cos(sine / 20)  - 0.05 * math.cos(sine / 40),-0.8)*angles(math.rad(0),math.rad(90),math.rad(0))*angles(math.rad(-3 + 2 * math.cos(sine / 40)),math.rad(-15),math.rad(0 + 2 * math.cos(sine / 20))),.1)
LH.C0=clerp(LH.C0,cf(-1,-1.45 + 0.05 * math.cos(sine / 20) - 0.02 * math.cos(sine / 40),0)*angles(math.rad(-0),math.rad(-90),math.rad(90))*angles(math.rad(-3 - 2 * math.cos(sine / 40)),math.rad(1),math.rad(0 - 2 * math.cos(sine / 20))),.1)
RootJoint.C0=clerp(RootJoint.C0,RootCF*cf(0 + 0.02 * math.cos(sine / 40),0 - 0.02 * math.cos(sine / 40),-1.25 - 0.05 * math.cos(sine / 20))*angles(math.rad(0 + 2 * math.cos(sine / 20)),math.rad(0 + 2 * math.cos(sine / 40)),math.rad(0 + 3 * math.cos(sine / 40))),.1)
Neck.C0=clerp(Neck.C0,necko*angles(math.rad(-0 - 40 * math.cos(sine / 0.5)),math.rad(2 - 45 * math.cos(sine / 0.5)),math.rad(0 - 40 * math.cos(sine / 0.5))),.1)
RW.C0=clerp(RW.C0,cf(1.45,0.5 + 0.05 * math.cos(sine / 28),0.1)*angles(math.rad(-10 + 5 * math.cos(sine / 26)),math.rad(-10 - 6 * math.cos(sine / 24)),math.rad(-20 - 20 * math.cos(sine / 1))),.1)
LW.C0=clerp(LW.C0,cf(-1.4,0.5 + 0.05 * math.cos(sine / 28),0.1)*angles(math.rad(180 - 1 * math.cos(sine / 25)),math.rad(10 + 2 * math.cos(sine / 24)),math.rad(20 + 2 * math.cos(sine / 1))),.1)
weaponweld.C1=clerp(weaponweld.C1,cf(0,1,0)*angles(math.rad(0),math.rad(190 + -90 * math.sin(sine / 40)),math.rad(0)),.3)
end

if attack==false and BanishMode == 2000 then
RH.C0=clerp(RH.C0,cf(1,-1.45 + 0.05 * math.cos(sine / 20)  - 0.05 * math.cos(sine / 40),0)*angles(math.rad(10),math.rad(90),math.rad(90))*angles(math.rad(-3 + 2 * math.cos(sine / 40)),math.rad(-15),math.rad(0 + 2 * math.cos(sine / 20))),.1)
LH.C0=clerp(LH.C0,cf(-1,-1.45 + 0.05 * math.cos(sine / 20) - 0.05 * math.cos(sine / 40),0)*angles(math.rad(10),math.rad(-90),math.rad(-90))*angles(math.rad(-3 - 2 * math.cos(sine / 40)),math.rad(1),math.rad(0 - 2 * math.cos(sine / 20))),.1)
RootJoint.C0=clerp(RootJoint.C0,RootCF*cf(0 + 0.02 * math.cos(sine / 40),0 - 0.02 * math.cos(sine / 40),-1.75 - 0.05 * math.cos(sine / 20))*angles(math.rad(0 + 2 * math.cos(sine / 20)),math.rad(0 + 2 * math.cos(sine / 40)),math.rad(0 + 3 * math.cos(sine / 40))),.1)
Neck.C0=clerp(Neck.C0,necko*angles(math.rad(-0 - 2 * math.cos(sine / 8)),math.rad(0 - 2 * math.cos(sine / 16)),math.rad(0 - 2 * math.cos(sine / 8))),.1)
RW.C0=clerp(RW.C0,cf(1.45,0.5 + 0.05 * math.cos(sine / 28),0.1)*angles(math.rad(10 + 5 * math.cos(sine / 26)),math.rad(-10 - 4 * math.cos(sine / 24)),math.rad(20 - 2 * math.cos(sine / 24))),.1)
LW.C0=clerp(LW.C0,cf(-1.4,0.5 + 0.05 * math.cos(sine / 28),0.1)*angles(math.rad(10 - 5 * math.cos(sine / 25)),math.rad(10 + 4 * math.cos(sine / 24)),math.rad(-20 + 2 * math.cos(sine / 24))),.1)
weaponweld.C1=clerp(weaponweld.C1,cf(0,1,0)*angles(math.rad(0),math.rad(190 + -90 * math.sin(sine / 40)),math.rad(0)),.3)
end

elseif torvel>2 and torvel<42 and hitfloor~=nil then
Anim="Walk"
if attack==false and BanishMode == 1 then
if equipped == false then
RH.C0=clerp(RH.C0,cf(1,-1 + 0.05 * math.cos(sine / 4),0)*angles(math.rad(0),math.rad(90),math.rad(0))*angles(math.rad(0),math.rad(0 + 5 * math.cos(sine / 8)),math.rad(0 + 45 * math.cos(sine / 8))),.1)
LH.C0=clerp(LH.C0,cf(-1,-1 + 0.05 * math.cos(sine / 4),0)*angles(math.rad(0),math.rad(-90),math.rad(0))*angles(math.rad(0),math.rad(0 + 5 * math.cos(sine / 8)),math.rad(0 + 45 * math.cos(sine / 8))),.1)
RootJoint.C0=clerp(RootJoint.C0,RootCF*cf(0,-0.05,-0.05 + 0.05 * math.cos(sine / 4))*angles(math.rad(5 + 3 * math.cos(sine / 4)),math.rad(0 + rotVelY/1.5),math.rad(0 - rotVelY - 10 * math.cos(sine / 8))),.1)
Neck.C0=clerp(Neck.C0,necko*angles(math.rad(-5 - 5 * math.cos(sine / 4)),math.rad(0 + rotVelY/1.5),math.rad(0 - rotVelY*1.5 + 10 * math.cos(sine / 8))),.1)
RW.C0=clerp(RW.C0,cf(1.5,0.5,0 + 0.25 * math.cos(sine / 8))*angles(math.rad(0 - 50 * math.cos(sine / 8)),math.rad(0),math.rad(5 - 10 * math.cos(sine / 4))),.1)
LW.C0=clerp(LW.C0,cf(-1.5,0.5,0 - 0.25 * math.cos(sine / 8))*angles(math.rad(0 + 50 * math.cos(sine / 8)),math.rad(0),math.rad(-5 + 10 * math.cos(sine / 4))),.1)
weaponweld.C1=clerp(weaponweld.C1,cf(-3,0,-0.5)*angles(math.rad(0),math.rad(0),math.rad(-40)),.3)
else
RH.C0=clerp(RH.C0,cf(1,-0.5 - -0.266 * math.sin(sine / 22),-0.6)*angles(math.rad(-10),math.rad(90),math.rad(-20))*angles(math.rad(0),math.rad(0),math.rad(-4 + 2 * math.sin(sine / 22))),.1)
LH.C0=clerp(LH.C0,cf(-1,-1 - -0.266 * math.sin(sine / 22),-0)*angles(math.rad(10),math.rad(-90),math.rad(20))*angles(math.rad(0),math.rad(0),math.rad(6 + 2 * math.sin(sine / 22))),.1)
RootJoint.C0=clerp(RootJoint.C0,RootCF*cf(0,-0.3,1.1 + 0.34 * math.cos(sine / 22))*angles(math.rad(45 - 2 * math.sin(sine / 22)),math.rad(0 + rotVelY*1.5),math.rad(0 - rotVelY - 10 * math.cos(sine / 22))),.1)
Neck.C0=clerp(Neck.C0,necko*angles(math.rad(-2.5 + 4 * math.cos(sine / 22)),math.rad(0 + rotVelY*1.5),math.rad(0 - rotVelY*1.5 + 10 * math.cos(sine / 22))),.1)
RW.C0=clerp(RW.C0,cf(1.5,0.5,0 + 0.255 * math.sin(sine / 22))*angles(math.rad(-10),math.rad(0),math.rad(15 - 2 * math.cos(sine / 34))),.1)
LW.C0=clerp(LW.C0,cf(-1.5,0.5,0 - 0.255 * math.sin(sine / 22))*angles(math.rad(0 + 3 * math.sin(sine / 22)),math.rad(0),math.rad(-5 + 3 * math.sin(sine / 22))),.1)
weaponweld.C1=clerp(weaponweld.C1,cf(0,1,0)*angles(math.rad(0),math.rad(190 + -90 * math.sin(sine / 40)),math.rad(0)),.3)
end
end
if attack==false and BanishMode == 7 then
if equipped == false then
RH.C0=clerp(RH.C0,cf(1,-1 + 0.05 * math.cos(sine / 4),0)*angles(math.rad(0),math.rad(90),math.rad(0))*angles(math.rad(0),math.rad(0 + 5 * math.cos(sine / 8)),math.rad(0 + 45 * math.cos(sine / 8))),.1)
LH.C0=clerp(LH.C0,cf(-1,-1 + 0.05 * math.cos(sine / 4),0)*angles(math.rad(0),math.rad(-90),math.rad(0))*angles(math.rad(0),math.rad(0 + 5 * math.cos(sine / 8)),math.rad(0 + 45 * math.cos(sine / 8))),.1)
RootJoint.C0=clerp(RootJoint.C0,RootCF*cf(0,-0.05,-0.05 + 0.05 * math.cos(sine / 4))*angles(math.rad(5 + 3 * math.cos(sine / 4)),math.rad(0 + rotVelY/1.5),math.rad(0 - rotVelY - 10 * math.cos(sine / 8))),.1)
Neck.C0=clerp(Neck.C0,necko*angles(math.rad(-5 - 5 * math.cos(sine / 4)),math.rad(0 + rotVelY/1.5),math.rad(0 - rotVelY*1.5 + 10 * math.cos(sine / 8))),.1)
RW.C0=clerp(RW.C0,cf(1.5,0.5,0 + 0.25 * math.cos(sine / 8))*angles(math.rad(0 - 50 * math.cos(sine / 8)),math.rad(0),math.rad(5 - 10 * math.cos(sine / 4))),.1)
LW.C0=clerp(LW.C0,cf(-1.5,0.5,0 - 0.25 * math.cos(sine / 8))*angles(math.rad(0 + 50 * math.cos(sine / 8)),math.rad(0),math.rad(-5 + 10 * math.cos(sine / 4))),.1)
weaponweld.C1=clerp(weaponweld.C1,cf(-3,0,-0.5)*angles(math.rad(0),math.rad(0),math.rad(-40)),.3)
else
RH.C0=clerp(RH.C0,cf(1,-0.5 - -0.266 * math.sin(sine / 22),-0.6)*angles(math.rad(-10),math.rad(90),math.rad(-20))*angles(math.rad(0),math.rad(0),math.rad(-4 + 2 * math.sin(sine / 22))),.1)
LH.C0=clerp(LH.C0,cf(-1,-1 - -0.266 * math.sin(sine / 22),-0)*angles(math.rad(10),math.rad(-90),math.rad(20))*angles(math.rad(0),math.rad(0),math.rad(6 + 2 * math.sin(sine / 22))),.1)
RootJoint.C0=clerp(RootJoint.C0,RootCF*cf(0,-0.3,1.1 + 0.34 * math.cos(sine / 22))*angles(math.rad(45 - 2 * math.sin(sine / 22)),math.rad(0 + rotVelY*1.5),math.rad(0 - rotVelY - 10 * math.cos(sine / 22))),.1)
Neck.C0=clerp(Neck.C0,necko*angles(math.rad(1+math.random(-10,10)), math.rad(0+math.random(-10,10)), math.rad(0+math.random(-10,10))),.1)
RW.C0=clerp(RW.C0,cf(1.5,0.5,0 + 0.255 * math.sin(sine / 22))*angles(math.rad(-10),math.rad(0),math.rad(15 - 2 * math.cos(sine / 34))),.1)
LW.C0=clerp(LW.C0,cf(-1.5,0.5,0 - 0.255 * math.sin(sine / 22))*angles(math.rad(0 + 3 * math.sin(sine / 22)),math.rad(0),math.rad(-5 + 3 * math.sin(sine / 22))),.1)
weaponweld.C1=clerp(weaponweld.C1,cf(0.5 + 5 * math.cos(sine / 30),0,-1.5)*angles(math.rad(0),math.rad(0),math.rad(190 + -800 * math.sin(sine / 40))),.3)
end
end
if attack==false and BanishMode == 2 then
if equipped == false then
RH.C0=clerp(RH.C0,cf(1,-1 + 0.05 * math.cos(sine / 4),0)*angles(math.rad(0),math.rad(90),math.rad(0))*angles(math.rad(0),math.rad(0 + 5 * math.cos(sine / 8)),math.rad(0 + 45 * math.cos(sine / 8))),.1)
LH.C0=clerp(LH.C0,cf(-1,-1 + 0.05 * math.cos(sine / 4),0)*angles(math.rad(0),math.rad(-90),math.rad(0))*angles(math.rad(0),math.rad(0 + 5 * math.cos(sine / 8)),math.rad(0 + 45 * math.cos(sine / 8))),.1)
RootJoint.C0=clerp(RootJoint.C0,RootCF*cf(0,-0.05,-0.05 + 0.05 * math.cos(sine / 4))*angles(math.rad(5 + 3 * math.cos(sine / 4)),math.rad(0 + rotVelY/1.5),math.rad(0 - rotVelY - 10 * math.cos(sine / 8))),.1)
Neck.C0=clerp(Neck.C0,necko*angles(math.rad(-5 - 5 * math.cos(sine / 4)),math.rad(0 + rotVelY/1.5),math.rad(0 - rotVelY*1.5 + 10 * math.cos(sine / 8))),.1)
RW.C0=clerp(RW.C0,cf(1.5,0.5,0 + 0.25 * math.cos(sine / 8))*angles(math.rad(0 - 50 * math.cos(sine / 8)),math.rad(0),math.rad(5 - 10 * math.cos(sine / 4))),.1)
LW.C0=clerp(LW.C0,cf(-1.5,0.5,0 - 0.25 * math.cos(sine / 8))*angles(math.rad(0 + 50 * math.cos(sine / 8)),math.rad(0),math.rad(-5 + 10 * math.cos(sine / 4))),.1)
weaponweld.C1=clerp(weaponweld.C1,cf(-3,0,-0.5)*angles(math.rad(0),math.rad(0),math.rad(-40)),.3)
else
RH.C0=clerp(RH.C0,cf(1,-1 - 0.15 * math.cos(sine / 3),0)*angles(math.rad(0),math.rad(90),math.rad(0))*angles(math.rad(0),math.rad(0),math.rad(0 + 85 * math.cos(sine / 6))),.1)
LH.C0=clerp(LH.C0,cf(-1,-1 - 0.15 * math.cos(sine / 3),0)*angles(math.rad(0),math.rad(-90),math.rad(0))*angles(math.rad(0),math.rad(0),math.rad(0 + 85 * math.cos(sine / 6))),.1)
RootJoint.C0=clerp(RootJoint.C0,RootCF*cf(0,-0.3,-0.05 + 0.15 * math.cos(sine / 3))*angles(math.rad(15 - 4 * math.cos(sine / 3)),math.rad(0 + rotVelY*1.5),math.rad(0 - rotVelY - 10 * math.cos(sine / 6))),.1)
Neck.C0=clerp(Neck.C0,necko*angles(math.rad(-6 - 15 * math.cos(sine / 0.5)),math.rad(6 - 15 * math.cos(sine / 0.5)),math.rad(10 - 20 * math.cos(sine / 0.5))),.1)
RW.C0=clerp(RW.C0,cf(1.5,0.5,0 + 0.25 * math.cos(sine / 4.6))*angles(math.rad(-40),math.rad(0),math.rad(25 - 2 * math.cos(sine / 34))),.1)
LW.C0=clerp(LW.C0,cf(-1.5,0.5,0 - 0.5 * math.cos(sine / 6))*angles(math.rad(0 + 140 * math.cos(sine / 6)),math.rad(0),math.rad(-5 + 20 * math.cos(sine / 3))),.1)
weaponweld.C1=clerp(weaponweld.C1,cf(0,1,0)*angles(math.rad(0),math.rad(190 + -360 * math.sin(sine / 40)),math.rad(0)),.3)
end
end
if attack==false and BanishMode == 4 then
if equipped == false then
RH.C0=clerp(RH.C0,cf(1,-1 + 0.05 * math.cos(sine / 4),0)*angles(math.rad(0),math.rad(90),math.rad(0))*angles(math.rad(0),math.rad(0 + 5 * math.cos(sine / 8)),math.rad(0 + 45 * math.cos(sine / 8))),.1)
LH.C0=clerp(LH.C0,cf(-1,-1 + 0.05 * math.cos(sine / 4),0)*angles(math.rad(0),math.rad(-90),math.rad(0))*angles(math.rad(0),math.rad(0 + 5 * math.cos(sine / 8)),math.rad(0 + 45 * math.cos(sine / 8))),.1)
RootJoint.C0=clerp(RootJoint.C0,RootCF*cf(0,-0.05,-0.05 + 0.05 * math.cos(sine / 4))*angles(math.rad(5 + 3 * math.cos(sine / 4)),math.rad(0 + rotVelY/1.5),math.rad(0 - rotVelY - 10 * math.cos(sine / 8))),.1)
Neck.C0=clerp(Neck.C0,necko*angles(math.rad(20+math.random(-30,30)), math.rad(0+math.random(-30,30)), math.rad(0+math.random(-30,30))),.1)
RW.C0=clerp(RW.C0,cf(1.5,0.5,0 + 0.25 * math.cos(sine / 8))*angles(math.rad(0 - 50 * math.cos(sine / 8)),math.rad(0),math.rad(5 - 10 * math.cos(sine / 4))),.1)
LW.C0=clerp(LW.C0,cf(-1.5,0.5,0 - 0.25 * math.cos(sine / 8))*angles(math.rad(0 + 50 * math.cos(sine / 8)),math.rad(0),math.rad(-5 + 10 * math.cos(sine / 4))),.1)
weaponweld.C1=clerp(weaponweld.C1,cf(-3,0,-0.5)*angles(math.rad(0),math.rad(0),math.rad(-40)),.3)
else
RH.C0=clerp(RH.C0,cf(1,-1 + 0.05 * math.cos(sine / 12),0)*angles(math.rad(0),math.rad(90),math.rad(0))*angles(math.rad(0),math.rad(0 + 5 * math.cos(sine / 16)),math.rad(0 + 22 * math.cos(sine / 16))),.1)
LH.C0=clerp(LH.C0,cf(-1,-1 + 0.05 * math.cos(sine / 12),0)*angles(math.rad(0),math.rad(-90),math.rad(0))*angles(math.rad(0),math.rad(0 + 5 * math.cos(sine / 16)),math.rad(0 + 22 * math.cos(sine / 16))),.1)
RootJoint.C0=clerp(RootJoint.C0,RootCF*cf(0,-0.05,-0.05 + 0.05 * math.cos(sine / 12))*angles(math.rad(10 + 3 * math.cos(sine / 12)),math.rad(0 + rotVelY/1.5),math.rad(0 - rotVelY - 10 * math.cos(sine / 16))),.1)
Neck.C0=clerp(Neck.C0,necko*angles(math.rad(30+math.random(-30,30)), math.rad(0+math.random(-30,30)), math.rad(0+math.random(-30,30))),.1)
RW.C0=clerp(RW.C0,cf(1.5,0.5,0 + 0.25 * math.cos(sine / 16))*angles(math.rad(12 - 12 * math.cos(sine / 16)),math.rad(0),math.rad(5 - 10 * math.cos(sine / 8))),.1)
LW.C0=clerp(LW.C0,cf(-1.5,0.5,0 - 0.25 * math.cos(sine / 16))*angles(math.rad(12 + 12 * math.cos(sine / 16)),math.rad(0),math.rad(-5 + 10 * math.cos(sine / 8))),.1)
weaponweld.C1=clerp(weaponweld.C1,cf(0,1,0)*angles(math.rad(0),math.rad(190 + -100 * math.sin(sine / 80)),math.rad(0)),.3)
end
end

if attack==false and BanishMode == 5 then
if equipped == false then
kan.Pitch = 1
RH.C0=clerp(RH.C0,cf(1,-1 + 0.2 * math.sin(sine / 8),-0.12 + 0.2 * math.cos(sine / 8))*angles(math.rad(0),math.rad(90),math.rad(0))*angles(math.rad(0),math.rad(0 + 5 * math.cos(sine / 8)),math.rad(0 + -40 * math.cos(sine / 8))),.1)
LH.C0=clerp(LH.C0,cf(-1,-1 + -0.2 * math.sin(sine / 8),-0.12 + -0.2 * math.cos(sine / 8))*angles(math.rad(0),math.rad(-90),math.rad(0))*angles(math.rad(0),math.rad(0 + 5 * math.cos(sine / 8)),math.rad(0 + -40 * math.cos(sine / 8))),.1)
RootJoint.C0=clerp(RootJoint.C0,RootCF*cf(0,-0.05,-0.05 + 0.05 * math.cos(sine / 4))*angles(math.rad(10 + 3 * math.cos(sine / 4)),math.rad(0 + rotVelY/1),math.rad(0 - rotVelY - 6 * math.sin(sine / 8))),.1)
Neck.C0=clerp(Neck.C0,necko*angles(math.rad(3+math.random(-10,10)), math.rad(0+math.random(-25,12)), math.rad(0+math.random(-10,10))),.1)
RW.C0=clerp(RW.C0,cf(1.5,0.5,0 + -0.25 * math.sin(sine / 8))*angles(math.rad(12 + 18 * math.cos(sine / 8)),math.rad(0),math.rad(0 + 0 * math.cos(sine / 4))),.1)
LW.C0=clerp(LW.C0,cf(-1.5,0.5,0 - -0.25 * math.sin(sine / 8))*angles(math.rad(12 + -18 * math.cos(sine / 8)),math.rad(0),math.rad(0 + 0 * math.cos(sine / 4))),.1)
weaponweld.C1=clerp(weaponweld.C1,cf(-3,0,-0.5)*angles(math.rad(0),math.rad(0),math.rad(-40)),.3)
else
kan.Pitch = 1
RH.C0=clerp(RH.C0,cf(1,-1 + 0.2 * math.sin(sine / 12),-0.12 + 0.2 * math.cos(sine / 12))*angles(math.rad(0),math.rad(90),math.rad(0))*angles(math.rad(0),math.rad(0 + 5 * math.cos(sine / 12)),math.rad(0 + -22 * math.cos(sine / 12))),.1)
LH.C0=clerp(LH.C0,cf(-1,-1 + -0.2 * math.sin(sine / 12),-0.12 + -0.2 * math.cos(sine / 12))*angles(math.rad(0),math.rad(-90),math.rad(0))*angles(math.rad(0),math.rad(0 + 5 * math.cos(sine / 12)),math.rad(0 + -22 * math.cos(sine / 12))),.1)
RootJoint.C0=clerp(RootJoint.C0,RootCF*cf(0,-0.05,-0.05 + 0.05 * math.cos(sine / 6))*angles(math.rad(10 + 3 * math.cos(sine / 6)),math.rad(0 + rotVelY/0.6),math.rad(0 - rotVelY - 6 * math.sin(sine / 12))),.1)
Neck.C0=clerp(Neck.C0,necko*angles(math.rad(3+math.random(-10,10)), math.rad(0+math.random(-25,12)), math.rad(0+math.random(-10,10))),.1)
RW.C0=clerp(RW.C0,cf(1.5,0.5,0 + -0.25 * math.sin(sine / 12))*angles(math.rad(12 + 18 * math.cos(sine / 12)),math.rad(0),math.rad(0 + 0 * math.cos(sine / 6))),.1)
LW.C0=clerp(LW.C0,cf(-1.5,0.5,0 - -0.25 * math.sin(sine / 12))*angles(math.rad(95 + -3 * math.cos(sine / 12)),math.rad(0),math.rad(0 + 0 * math.cos(sine / 6))),.1)
weaponweld.C1=clerp(weaponweld.C1,cf(0,1,0)*angles(math.rad(0),math.rad(-90 + -2 * math.sin(sine / 80)),math.rad(0)),.3)
end
end

if attack==false and BanishMode == 1000 then
if equipped == false then
RH.C0=clerp(RH.C0,cf(1,-1 + 0.05 * math.cos(sine / 4),0)*angles(math.rad(0),math.rad(90),math.rad(0))*angles(math.rad(0),math.rad(0 + 5 * math.cos(sine / 8)),math.rad(0 + 45 * math.cos(sine / 8))),.1)
LH.C0=clerp(LH.C0,cf(-1,-1 + 0.05 * math.cos(sine / 4),0)*angles(math.rad(0),math.rad(-90),math.rad(0))*angles(math.rad(0),math.rad(0 + 5 * math.cos(sine / 8)),math.rad(0 + 45 * math.cos(sine / 8))),.1)
RootJoint.C0=clerp(RootJoint.C0,RootCF*cf(0,-0.05,-0.05 + 0.05 * math.cos(sine / 4))*angles(math.rad(5 + 3 * math.cos(sine / 4)),math.rad(0 + rotVelY/1.5),math.rad(0 - rotVelY - 10 * math.cos(sine / 8))),.1)
Neck.C0=clerp(Neck.C0,necko*angles(math.rad(20+math.random(-100,100)), math.rad(0+math.random(-100,100)), math.rad(0+math.random(-100,100))),.1)
RW.C0=clerp(RW.C0,cf(1.5,0.5,0 + 0.25 * math.cos(sine / 8))*angles(math.rad(0 - 50 * math.cos(sine / 8)),math.rad(0),math.rad(5 - 10 * math.cos(sine / 4))),.1)
LW.C0=clerp(LW.C0,cf(-1.5,0.5,0 - 0.25 * math.cos(sine / 8))*angles(math.rad(0 + 50 * math.cos(sine / 8)),math.rad(0),math.rad(-5 + 10 * math.cos(sine / 4))),.1)
weaponweld.C1=clerp(weaponweld.C1,cf(-3,0,-0.5)*angles(math.rad(0),math.rad(0),math.rad(-40)),.3)
else
RH.C0=clerp(RH.C0,cf(1 + 0.2 * (1+math.random(-5,5)),-1 + 0.2 * (1+math.random(-5,5)),0 + 0.1 * (1+math.random(-5,5)))*angles(math.rad(0),math.rad(90),math.rad(0))*angles(math.rad(0),math.rad(0 + 5 * math.cos(sine / 18)),math.rad(0 + -22 * math.cos(sine / 18))),.1)
LH.C0=clerp(LH.C0,cf(-1 + 0.2 * (1+math.random(-5,5)),-1 + 0.2 * (1+math.random(-5,5)),0 + -0.1 * (1+math.random(-5,5)))*angles(math.rad(0),math.rad(-90),math.rad(0))*angles(math.rad(0),math.rad(0 + 5 * math.cos(sine / 18)),math.rad(0 + -22 * math.cos(sine / 18))),.1)
RootJoint.C0=clerp(RootJoint.C0,RootCF*cf(-0 + 0.05 * (1+math.random(-10,10)),-0.05 + 0.05 * (1+math.random(-10,10)),-0.05 + 0.05 * (1+math.random(-10,10)))*angles(math.rad(10 + 3 * math.cos(sine / 9)),math.rad(0 + rotVelY/1),math.rad(0 - rotVelY - -6 * math.sin(sine / 18))),.1)
Neck.C0=clerp(Neck.C0,necko*angles(math.rad(3+math.random(-100,100)), math.rad(0+math.random(-100,100)), math.rad(0+math.random(-100,100))),.1)
RW.C0=clerp(RW.C0,cf(1.5 + 0.05 * (1+math.random(-20,20)),0.5 + 0.05 * (1+math.random(-20,20)),0 + 0.05 * (1+math.random(-20,20)))*angles(math.rad(-20+math.random(-10,10)), math.rad(0+math.random(-10,10)), math.rad(215+math.random(-10,10))),.1)
LW.C0=clerp(LW.C0,cf(-1.5 + 0.05 * (1+math.random(-20,20)),0.5 + 0.05 * (1+math.random(-20,20)),0 - -0.25 * (1+math.random(-20,20)))*angles(math.rad(12 + -18 * math.cos(sine / 18)),math.rad(0),math.rad(0 + 0 * math.cos(sine / 9))),.1)
weaponweld.C1=clerp(weaponweld.C1,cf(0,1,0)*angles(math.rad(0),math.rad(-90 + -2 * math.sin(sine / 80)),math.rad(0)),.3)
end
end

if attack==false and BanishMode == 3 then
if equipped == false then
RH.C0=clerp(RH.C0,cf(1,-1 + 0.05 * math.cos(sine / 4),0)*angles(math.rad(0),math.rad(90),math.rad(0))*angles(math.rad(0),math.rad(0 + 5 * math.cos(sine / 8)),math.rad(0 + 45 * math.cos(sine / 8))),.1)
LH.C0=clerp(LH.C0,cf(-1,-1 + 0.05 * math.cos(sine / 4),0)*angles(math.rad(0),math.rad(-90),math.rad(0))*angles(math.rad(0),math.rad(0 + 5 * math.cos(sine / 8)),math.rad(0 + 45 * math.cos(sine / 8))),.1)
RootJoint.C0=clerp(RootJoint.C0,RootCF*cf(0,-0.05,-0.05 + 0.05 * math.cos(sine / 4))*angles(math.rad(5 + 3 * math.cos(sine / 4)),math.rad(0 + rotVelY/1.5),math.rad(0 - rotVelY - 10 * math.cos(sine / 8))),.1)
Neck.C0=clerp(Neck.C0,necko*angles(math.rad(-5 - 5 * math.cos(sine / 4)),math.rad(0 + rotVelY/1.5),math.rad(0 - rotVelY*1.5 + 10 * math.cos(sine / 8))),.1)
RW.C0=clerp(RW.C0,cf(1.5,0.5,0 + 0.25 * math.cos(sine / 8))*angles(math.rad(0 - 50 * math.cos(sine / 8)),math.rad(0),math.rad(5 - 10 * math.cos(sine / 4))),.1)
LW.C0=clerp(LW.C0,cf(-1.5,0.5,0 - 0.25 * math.cos(sine / 8))*angles(math.rad(0 + 50 * math.cos(sine / 8)),math.rad(0),math.rad(-5 + 10 * math.cos(sine / 4))),.1)
weaponweld.C1=clerp(weaponweld.C1,cf(-3,0,-0.5)*angles(math.rad(0),math.rad(0),math.rad(-40)),.3)
else
RH.C0=clerp(RH.C0,cf(1,-1 + 0.05 * math.cos(sine / 4),0)*angles(math.rad(0),math.rad(90),math.rad(0))*angles(math.rad(0),math.rad(0 + 5 * math.cos(sine / 8)),math.rad(0 + 45 * math.cos(sine / 8))),.1)
LH.C0=clerp(LH.C0,cf(-1,-1 + 0.05 * math.cos(sine / 4),0)*angles(math.rad(0),math.rad(-90),math.rad(0))*angles(math.rad(0),math.rad(0 + 5 * math.cos(sine / 8)),math.rad(0 + 45 * math.cos(sine / 8))),.1)
RootJoint.C0=clerp(RootJoint.C0,RootCF*cf(0,-0.05,-0.05 + 0.05 * math.cos(sine / 4))*angles(math.rad(5 + 3 * math.cos(sine / 4)),math.rad(0 + rotVelY/1.5),math.rad(0 - rotVelY - 10 * math.cos(sine / 8))),.1)
Neck.C0=clerp(Neck.C0,necko*angles(math.rad(-0 - 35 * math.cos(sine / 0.5)),math.rad(10 - 30 * math.cos(sine / 0.5)),math.rad(0 - 25 * math.cos(sine / 0.5))),.1)
RW.C0=clerp(RW.C0,cf(1.5,0.5,0 + 0.25 * math.cos(sine / 8))*angles(math.rad(0 - 50 * math.cos(sine / 8)),math.rad(0),math.rad(5 - 10 * math.cos(sine / 4))),.1)
LW.C0=clerp(LW.C0,cf(-1.5,0.5,0 - 0.25 * math.cos(sine / 8))*angles(math.rad(0 + 50 * math.cos(sine / 8)),math.rad(0),math.rad(-5 + 10 * math.cos(sine / 4))),.1)
weaponweld.C1=clerp(weaponweld.C1,cf(0,1,0)*angles(math.rad(0),math.rad(190 + -999 * math.sin(sine / 40)),math.rad(0)),.3)
end
end
elseif torvel>=42 and hitfloor~=nil then
Anim="Run"
if attack==false then
RH.C0=clerp(RH.C0,cf(1,-1 - 0.15 * math.cos(sine / 3),0)*angles(math.rad(0),math.rad(90),math.rad(0))*angles(math.rad(0),math.rad(0),math.rad(0 + 85 * math.cos(sine / 6))),.1)
LH.C0=clerp(LH.C0,cf(-1,-1 - 0.15 * math.cos(sine / 3),0)*angles(math.rad(0),math.rad(-90),math.rad(0))*angles(math.rad(0),math.rad(0),math.rad(0 + 85 * math.cos(sine / 6))),.1)
RootJoint.C0=clerp(RootJoint.C0,RootCF*cf(0,-0.3,-0.05 + 0.15 * math.cos(sine / 3))*angles(math.rad(15 - 4 * math.cos(sine / 3)),math.rad(0 + rotVelY*1.5),math.rad(0 - rotVelY - 10 * math.cos(sine / 6))),.1)
Neck.C0=clerp(Neck.C0,necko*angles(math.rad(-2.5 + 4 * math.cos(sine / 3)),math.rad(0 + rotVelY*1.5),math.rad(0 - rotVelY*1.5 + 10 * math.cos(sine / 6))),.1)
RW.C0=clerp(RW.C0,cf(1.5,0.5,0 + 0.5 * math.cos(sine / 6))*angles(math.rad(0 - 140 * math.cos(sine / 6)),math.rad(0),math.rad(5 - 20 * math.cos(sine / 3))),.1)
LW.C0=clerp(LW.C0,cf(-1.5,0.5,0 - 0.5 * math.cos(sine / 6))*angles(math.rad(0 + 140 * math.cos(sine / 6)),math.rad(0),math.rad(-5 + 20 * math.cos(sine / 3))),.1)
end
end
end
end


----------------------------------------------------------------------------------------------------
-- display: logic poses are interpolated between ticks, so it stays smooth at any frame rate
----------------------------------------------------------------------------------------------------
local poseAlpha = 0
fdState = "idle"
local lastApply = os.clock()
local lastYaw = 0
local function alignCF(t)
	return CFrame.new(t[1], t[2], t[3]) * CFrame.Angles(math.rad(t[4]), math.rad(t[5]), math.rad(t[6]))
end
local GRIP = CFrame.Angles(math.rad(CONFIG.SwordBaseRotation[1]), math.rad(CONFIG.SwordBaseRotation[2]), math.rad(CONFIG.SwordBaseRotation[3]))
local ALIGN_SWORD, ALIGN_BACK = alignCF(ALIGN.sword), alignCF(ALIGN.swordback)
-- one alignment profile per sword: {sword(6), swordback(6), base = {0,0,0,rx,ry,rz}}
local PROFILES, DEFS = {}, {}
local function defaultProfile(def)
	local b = def.align.base
	return {table.clone(def.align.sword), table.clone(def.align.swordback), {0, 0, 0, b[1], b[2], b[3]}}
end
for _, def in ipairs(SWORDS) do
	PROFILES[def.key] = defaultProfile(def)
	DEFS[def.key] = def
end
local activeKey = SWORDS[1].key
local function applyActive()
	local P = PROFILES[activeKey]
	ALIGN.sword, ALIGN.swordback = P[1], P[2]
	CONFIG.SwordBaseRotation = {P[3][4], P[3][5], P[3][6]}
	ALIGN_SWORD, ALIGN_BACK = alignCF(P[1]), alignCF(P[2])
	GRIP = CFrame.Angles(math.rad(P[3][4]), math.rad(P[3][5]), math.rad(P[3][6]))
end
function NEP_setSwordKey(key)
	if not PROFILES[key] then return end
	activeKey = key
	applyActive()
	if NEP.onProfileChanged then NEP.onProfileChanged() end
end
if NEP.swordKey and PROFILES[NEP.swordKey] then activeKey = NEP.swordKey end
applyActive()
local PI2 = math.pi * 2

local function applyPose(state)
	fdState = state
	local now = os.clock()
	local dt = math.max(now - lastApply, 1 / 480)
	lastApply = now

	velNow = flight and flight.vel or RE.getVel()
	local a = poseAlpha

	for i = 1, #LJ do
		local L = LJ[i]
		L.fd.C0 = L.p:Lerp(L.c, a)
	end

	-- fresh pose of every limb (cframes still holds last frame's values at this point)
	local rootCF = cframes[FDP.root]
	local torsoCF = rootCF * jRoot.C0 * iRoot
	local headCF = torsoCF * jNeck.C0 * iNeck
	local rarmCF = torsoCF * jRS.C0 * iRS
	local larmCF = torsoCF * jLS.C0 * iLS
	root.CFrame = rootCF
	tors.CFrame = torsoCF
	hed.CFrame = headCF
	rarm.CFrame = rarmCF
	larm.CFrame = larmCF
	rleg.CFrame = torsoCF * jRH.C0 * iRH
	lleg.CFrame = torsoCF * jLH.C0 * iLH

	-- turning speed for the walk animations
	local _, yaw = rootCF:ToOrientation()
	local d = yaw - lastYaw
	lastYaw = yaw
	if d > math.pi then d = d - PI2 elseif d < -math.pi then d = d + PI2 end
	rotVelY = rotVelY + (d / dt - rotVelY) * math.min(1, dt * 12)
	rotVelY = math.clamp(rotVelY, -15, 15)

	-- sword
	local C1d = ww.p:Lerp(ww.c, a)
	local holder = (ww.Part0 == rarm) and rarmCF or torsoCF
	local rarmorCF = holder * ww.C0 * C1d:Inverse()
	rarmor.CFrame = rarmorCF
	if swordJoint and swordJoint.Part0 then
		swordJoint.Part1 = FDP.torso
		swordJoint.C1 = torsoCF:Inverse() * (rarmorCF * GRIP * (equipped and ALIGN_SWORD or ALIGN_BACK))
	end

	-- wings
	local mainCF = torsoCF * CFrame.new(0, 0.5, 0.75)
	mainpart.CFrame = mainCF
	for i = 1, #wingRel do
		wingRel[i][1].CFrame = mainCF * wingRel[i][2]
	end
end

RE.addmode("default", {
	idle = function() applyPose("idle") end,
	walk = function() applyPose("walk") end,
	jump = function() applyPose("jump") end,
	fall = function() applyPose("fall") end,
})

----------------------------------------------------------------------------------------------------
-- fixed 60Hz logic clock
----------------------------------------------------------------------------------------------------
local acc = 0
local lastErr = 0
local function runTicks(dt)
	acc = acc + math.min(dt, 0.1)
	local n = 0
	while acc >= TICK and n < 6 do
		acc = acc - TICK
		n = n + 1
		tickCount = tickCount + 1
		if #waiting > 0 then
			local due, keep = {}, {}
			for i = 1, #waiting do
				local w = waiting[i]
				if w[2] <= tickCount then due[#due + 1] = w[1] else keep[#keep + 1] = w end
			end
			waiting = keep
			for i = 1, #due do
				if coroutine.status(due[i]) == "suspended" then task.spawn(due[i]) end
			end
		end
		local ok, err = pcall(animStep)
		if not ok and os.clock() - lastErr > 2 then
			lastErr = os.clock()
			warn("[Neptunian] animation error: " .. tostring(err))
		end
		for i = 1, #LJ do
			local L = LJ[i]
			L.p, L.c = L.c, L.C0
		end
		ww.p, ww.c = ww.c, ww.C1
	end
	if acc >= TICK then acc = acc % TICK end
	poseAlpha = acc / TICK
end

track(RunService.Heartbeat:Connect(function(dt)
	if not NEP.alive then return end
	runTicks(dt)
	flightStep(dt)
	guiStep(dt)
end))

----------------------------------------------------------------------------------------------------
-- input
----------------------------------------------------------------------------------------------------
local lastKey = {}
local function handleKey(k)
	if not NEP.alive then return end
	local now = os.clock()
	if lastKey[k] and now - lastKey[k] < 0.06 then return end
	lastKey[k] = now

	if k == "f" and attack == false and equipped == false then
		task.spawn(equip)
	elseif k == "f" and attack == false and equipped == true then
		task.spawn(unequip)
	end
	if k == "2" and attack == false then
		hum.WalkSpeed = 40
		Speed = 40
		kan.Pitch = 1.00
		kan.SoundId = getAsset("BloodDrain_Again.mp3"); NEP_track("BloodDrain_Again.mp3")
		BanishMode = 2
	end
	if k == "1" and attack == false then
		hum.WalkSpeed = 24
		Speed = 24
		kan.Pitch = 1.00
		kan.SoundId = getAsset("Neptunian V.mp3"); NEP_track("Neptunian V.mp3")
		BanishMode = 1
	end
	if k == "3" and attack == false then
		hum.WalkSpeed = 13.8
		Speed = 13.8
		kan.Pitch = 1
		kan.SoundId = getAsset("CRAZED.mp3"); NEP_track("CRAZED.mp3")
		BanishMode = 4
	end
	if k == "4" and attack == false then
		hum.WalkSpeed = 8
		Speed = 8
		kan.Pitch = 1
		kan.SoundId = getAsset("BigBlack.mp3"); NEP_track("BigBlack.mp3")
		BanishMode = 5
	end
	if k == "5" and attack == false then
		hum.WalkSpeed = 35
		Speed = 35
		kan.Pitch = 1
		kan.SoundId = getAsset("censored.mp3"); NEP_track("censored.mp3")
		BanishMode = 7
	end
	if k == "r" and attack == false then
		task.spawn(superjump)
	end
	if k == "v" and attack == false then
		pcall(RE.rotToMouse, 1)
		RE.setCfr(mouse.Hit.Position + Vector3.new(0, 3.3, 0))
	end
	if equipped == true then
		if k == "z" and attack == false then task.spawn(spinnyblade) end
		if k == "x" and attack == false then task.spawn(eightbitmegablade) end
		if k == "q" and attack == false then task.spawn(smack) end
		if k == "e" and attack == false then task.spawn(darkspin) end
		if k == "c" and attack == false then task.spawn(bladespinagain) end
	end
	if k == "l" and muter == false then
		muter = true
		kan.Volume = 0
	elseif k == "l" and muter == true then
		muter = false
		kan.Volume = ORVOL
	end
end

local digitNames = {One = "1", Two = "2", Three = "3", Four = "4", Five = "5"}
track(UserInputService.InputBegan:Connect(function(input, gp)
	if gp or input.UserInputType ~= Enum.UserInputType.Keyboard or UserInputService:GetFocusedTextBox() then return end
	local name = input.KeyCode.Name
	handleKey(digitNames[name] or name:lower())
end))
function NEP_click()
	if not NEP.alive then return end
	if equipped == true then
		if attack == false and attacktype == 1 then
			attacktype = 2
			task.spawn(attackone)
		elseif attack == false and attacktype == 2 then
			attacktype = 3
			task.spawn(attacktwo)
		elseif attack == false and attacktype == 3 then
			attacktype = 1
			task.spawn(attackthree)
		end
	end
end
-- Tap / click anywhere on the screen to attack (same as the original script). Pressing this script's own panel or
-- buttons never swings the sword. Optional: CONFIG.IgnoreMenusOnTap = true also ignores the joystick area / chat / topbar.
NEP.guiPress = 0
local function markGui(obj)
	pcall(function()
		obj.InputBegan:Connect(function(io)
			local t = io.UserInputType
			if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then NEP.guiPress = os.clock() end
		end)
	end)
end
NEP.markGui = markGui
local GuiService = game:GetService("GuiService")
local function rectHit(p, ap, sz, pad)
	return p.X >= ap.X - pad and p.X <= ap.X + sz.X + pad and p.Y >= ap.Y - pad and p.Y <= ap.Y + sz.Y + pad
end
local function menuTouch(pos)
	local inset = GuiService:GetGuiInset()
	local p = Vector2.new(pos.X + inset.X, pos.Y + inset.Y)
	local vp = workspace.CurrentCamera.ViewportSize
	if pos.Y < inset.Y + 6 then return true end
	if p.X < vp.X * 0.45 and p.Y > vp.Y * 0.30 then return true end
	local ok, tcs = pcall(function() return game:GetService("TextChatService") end)
	if ok and tcs then
		for _, name in ipairs({"ChatWindowConfiguration", "ChatInputBarConfiguration"}) do
			local cfg = tcs:FindFirstChild(name)
			if cfg and cfg.Enabled ~= false and cfg.AbsoluteSize and cfg.AbsoluteSize.X > 0 then
				if rectHit(p, cfg.AbsolutePosition, cfg.AbsoluteSize, 10) or rectHit(pos, cfg.AbsolutePosition, cfg.AbsoluteSize, 10) then
					return true
				end
			end
		end
	end
	return false
end
track(mouse.Button1Down:Connect(function()
	if not NEP.alive or UserInputService:GetFocusedTextBox() then return end
	if CONFIG.IgnoreMenusOnTap then
		local okb, blocked = pcall(menuTouch, Vector2.new(mouse.X, mouse.Y))
		if okb and blocked then return end
	end
	task.spawn(function()
		task.wait()                                   -- let our own GUI mark the press first
		if os.clock() - NEP.guiPress < 0.2 then return end
		NEP_click()
	end)
end))

track(plr.Chatted:Connect(function(message)
	if message == "/stop" then
		task.spawn(function() NEP.cleanup() end)
		return
	end
	if message == "/sword" then
		NEP_findSword(true)
		notify("Looking for the greatsword...", 3)
	end
	if message == "/sit" and attack == false then
		Speed = 0
		hum.WalkSpeed = 0
		BanishMode = 2000
	end
	if message == "/glitch" and attack == false and BanishMode == 5 then
		Speed = 8
		hum.WalkSpeed = 8
		BanishMode = 1000
		task.spawn(function()
			kan.Pitch = 0.6
			wait(0.02)
			kan.Pitch = 0.5
			wait(0.02)
			kan.Pitch = 0.467
		end)
	end
	if message:sub(1, 3) == "id/" then
		kan.SoundId = "rbxassetid://" .. message:sub(4)
		kan.TimePosition = 0
		kan:Play()
	elseif message:sub(1, 6) == "pitch/" then
		ORPIT = tonumber(message:sub(7)) or ORPIT
	elseif message:sub(1, 4) == "vol/" then
		ORVOL = tonumber(message:sub(5)) or ORVOL
	elseif message:sub(1, 5) == "skip/" then
		kan.TimePosition = tonumber(message:sub(6)) or 0
	end
end))

do
	local HttpService = game:GetService("HttpService")
	local FILE = CONFIG.AlignFile

	-- values per sword: [1] = in hand, [2] = on back, [3] = base rotation (only the three Turn rows are used)
	local TAB = {"Hand", "Back", "Base"}
	local VAL = PROFILES[activeKey]
	local function rebuild() applyActive() end
	local function loadAlign()
		if not (isfile and readfile) then return false, "your executor can't read files" end
		local ok, has = pcall(isfile, FILE)
		if not ok or not has then return false, "no saved alignment yet" end
		local ok2, txt = pcall(readfile, FILE)
		if not ok2 or type(txt) ~= "string" then return false, "couldn't read " .. FILE end
		local ok3, data = pcall(function() return HttpService:JSONDecode(txt) end)
		if not ok3 or type(data) ~= "table" then return false, FILE .. " is damaged" end
		local profiles = data.profiles
		if type(profiles) ~= "table" and type(data.sword) == "table" then
			profiles = {corrupt = data}           -- file saved by the old single-sword version
		end
		if type(profiles) ~= "table" then return false, FILE .. " is damaged" end
		local keys = {"sword", "swordback", "base"}
		for key, P in pairs(PROFILES) do
			local d = profiles[key]
			if type(d) == "table" then
				for s = 1, 3 do
					local a = d[keys[s]]
					if type(a) == "table" then
						for k = 1, (s == 3 and 3 or 6) do
							local n = tonumber(a[k])
							if n and n == n and math.abs(n) < 1e5 then P[s][s == 3 and k + 3 or k] = n end
						end
					end
				end
			end
		end
		return true
	end
	local function saveAlign()
		if not writefile then return false, "your executor can't save files" end
		local out = {}
		for key, P in pairs(PROFILES) do
			out[key] = {sword = P[1], swordback = P[2], base = {P[3][4], P[3][5], P[3][6]}}
		end
		local ok, e = pcall(function() writefile(FILE, HttpService:JSONEncode({v = 2, profiles = out})) end)
		if not ok then return false, tostring(e) end
		return true
	end
	loadAlign()
	rebuild()

	local genv = (typeof(getgenv) == "function" and getgenv()) or _G
	local AL = {version = 1, title = "Neptunian V", tabs = TAB, file = FILE, dirty = false, open = false, key = "P", marker = false}
	local cur = 1
	local watchers = {}
	local function fire(what)
		for _, f in ipairs(table.clone(watchers)) do
			pcall(f, what)
		end
	end
	local function hub()
		local h = genv.AtsukoHub
		return type(h) == "table" and h or nil
	end
	local function ready()
		local h = hub()
		if h and type(h.AlignReady) == "function" then
			pcall(h.AlignReady)
		end
	end
	function AL.alive()
		return NEP.alive
	end
	function AL.focus(s)
		if TAB[s] then
			cur = s
		end
	end
	function AL.rows(s)
		if s == 3 then
			return {4, 5, 6}
		end
		return nil
	end
	function AL.get(s)
		return VAL[s] and table.clone(VAL[s]) or nil
	end
	function AL.set(s, k, n)
		local v = VAL[s]
		n = tonumber(n)
		if not v or not n or n ~= n or math.abs(n) >= 1e5 then
			return nil
		end
		if k > 3 then
			n = ((n + 180) % 360) - 180
			n = math.floor(n * 10 + 0.5) / 10
		else
			n = math.floor(n * 1000 + 0.5) / 1000
		end
		v[k] = n
		rebuild()
		AL.dirty = true
		AL.later()
		return n
	end
	function AL.put(s, vals)
		if not VAL[s] or type(vals) ~= "table" then
			return
		end
		for k = 1, 6 do
			VAL[s][k] = tonumber(vals[k]) or 0
		end
		rebuild()
		AL.dirty = true
		AL.later()
	end
	function AL.reset(s)
		local P0 = {table.clone(DEFS[activeKey].align.sword), table.clone(DEFS[activeKey].align.swordback), {0, 0, 0, table.unpack(DEFS[activeKey].align.base)}}
		AL.put(s, P0[s])
	end
	function AL.save()
		AL.tok = (AL.tok or 0) + 1
		local ok, e = saveAlign()
		if ok then
			AL.dirty = false
		end
		return ok, e
	end
	function AL.later()
		AL.tok = (AL.tok or 0) + 1
		local my = AL.tok
		task.delay(1.5, function()
			if my == AL.tok and AL.dirty and NEP.alive and AL.save() then
				fire("saved")
			end
		end)
	end
	function AL.load()
		local ok, e = loadAlign()
		rebuild()
		if ok then
			AL.dirty = false
		end
		fire("load")
		return ok, e
	end
	function AL.watch(f)
		watchers[#watchers + 1] = f
		return function()
			local i = table.find(watchers, f)
			if i then
				table.remove(watchers, i)
			end
		end
	end
	function AL.gun()
		return DEFS[activeKey].name
	end
	function AL.hat(s)
		local c = chosen
		local id = c and c.md and tostring(c.md) or nil
		if not id or id == "" or not TAB[s] then
			return nil
		end
		local name = nil
		pcall(function()
			name = c.acc.Name
		end)
		return tostring(activeKey) .. ":" .. id, id, type(name) == "string" and name or nil, true
	end
	function AL.found()
		local name = DEFS[activeKey].name
		if swordJoint and chosen then
			return name .. "  |  attached: " .. tostring(chosen.acc and chosen.acc.Name or "found")
		elseif chosen then
			return name .. "  |  found " .. tostring(chosen.acc and chosen.acc.Name) .. ", hooking it up..."
		end
		return name .. "  |  no sword found - wear one, then tap Find sword"
	end
	function AL.press()
		NEP.guiPress = os.clock()
	end
	AL.optList = {{"equip", "Equip / Unequip", "button", "sword"}, {"find", "Find sword", "button", "search"}, {"sword", "Switch sword", "button", "repeat"}, {"roll", "Roll (upside down? tap this)", "button", "repeat"}}
	AL.optsSaved = false
	function AL.opts()
		return {}
	end
	function AL.setOpt(name)
		if name == "equip" then
			if attack == false then task.spawn(handleKey, "f") end
		elseif name == "find" then
			NEP_findSword(true)
		elseif name == "sword" then
			NEP_cycleSword()
		elseif name == "roll" then
			local v = VAL[cur]
			if v then AL.set(cur, 4, v[4] + 180) end
		end
	end
	function NEP.toggleAlign()
		local h = hub()
		if h and type(h.Align) == "function" then
			pcall(h.Align)
		else
			notify("Open Atsuko Hub to line things up, the alignment lives there now", 5)
		end
	end
	NEP.onProfileChanged = function()
		VAL = PROFILES[activeKey]
		fire("gun")
	end
	function NEP.alignStop()
		if AL.dirty then
			pcall(saveAlign)
			AL.dirty = false
		end
		AL.open = false
		if genv.AtsukoAlign == AL then
			genv.AtsukoAlign = nil
		end
		fire("stop")
		ready()
	end
	genv.AtsukoAlign = AL
	ready()

	track(UserInputService.InputBegan:Connect(function(io, gp)
		if gp or UserInputService:GetFocusedTextBox() then return end
		if io.UserInputType == Enum.UserInputType.Keyboard and io.KeyCode == Enum.KeyCode.P then
			NEP.toggleAlign()
		end
	end))
end

----------------------------------------------------------------------------------------------------
-- cleanup (running the script again, or stopping it from the console with _G.NeptunianFDless.cleanup())
----------------------------------------------------------------------------------------------------
function NEP.cleanup()
	if not NEP.alive then return end
	NEP.alive = false
	flight = nil
	for _, c in ipairs(NEP.conns) do pcall(function() c:Disconnect() end) end
	pcall(function() kan:Destroy() end)
	pcall(function() basgui:Destroy() end)
	pcall(function() fx:Destroy() end)
	if NEP.alignStop then pcall(NEP.alignStop) end
	pcall(function() FD.stopreanimate() end)
end

notify("Loaded - F to equip the greatsword.", 5)
