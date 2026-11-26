local function hubNotify(title, text, kind, dur)
	local env = (typeof(getgenv) == "function" and getgenv()) or _G
	local f = env.AtsukoNotify
	if type(f) == "function" then
		return pcall(f, title, text, kind, dur)
	end
	return pcall(warn, "[" .. tostring(title) .. "] " .. tostring(text))
end
local FD = (function()
--!optimize 2
if _G.GenesisFDless then 
	return _G.GenesisFDless 
end


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
local vmagnitude=vector.magnitude
local vnormalize=vector.normalize

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
local angles=CFrame.fromEulerAngles
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

	{PartName="Head",meshid="11601535857",C0=angles(0,3.141592653589793,0)},

	{PartName="Left Arm",meshid="13831073174",C0=cfMul(cf(0.017,0,-0.23),angles(-1.4835298641951802,-0.15707963267948966,2.199114857512855))},
	{PartName="Right Arm",meshid="13839903766",C0=cfMul(cf(0,-0.62,-0.01),angles(1.6580627893946132,0.15707963267948966,-2.199114857512855))},

	{PartName="Left Leg",meshid="11159370334",textureid="11159285454",C0=angles(1.5707963267948966,0,1.5707963267948966)},

	{PartName="Right Leg",meshid="12652772399",textureid="12652775021",C0=cf(0,-0.125,0)},

	{PartName="Torso",meshid="14768666349"},
	{PartName="Torso",meshid="14241018198"},
	{PartName="Torso",meshid="13421774668"},
	{PartName="Left Leg",meshid="14255522247",C0=angles(1.5707963267948966,0,1.5707963267948966)},
	{PartName="Right Leg",meshid="14255522247",C0=angles(-1.5707963267948966,0,1.5707963267948966)},
	{PartName="Left Arm",meshid="14768684979",C0=angles(0,0,1.5707963267948966)},
	{PartName="Right Arm",meshid="14768684979",C0=angles(0,0,1.5707963267948966)},

	{PartName="Head",meshid="13953154391"},
	{PartName="Torso",meshid="13778226115"},
	{PartName="Left Leg",meshid="11159370334",textureid="11159284657",C0=angles(1.5707963267948966,0,1.5707963267948966)},
	{PartName="Right Leg",meshid="11263221350",textureid="11263219250",C0=angles(-1.5707963267948966,0,1.5707963267948966)},
	{PartName="Left Arm",meshid="12344207333",C0=angles(2,0,0)},
	{PartName="Right Arm",meshid="12344206657",C0=angles(2,0,0)},

	{PartName="Torso",meshid="110684113028749"},
	{PartName="Head",meshid="13058343355",C0=angles(0,3.141592653589793,0)},
	{PartName="Left Leg",meshid="139733645770094",C0=angles(0,0,1.5707963267948966)},
	{PartName="Right Leg",meshid="99608462237958",C0=angles(0,0,1.5707963267948966)},
	{PartName="Left Arm",meshid="90736849096372",C0=angles(0,0,1.5707963267948966)},
	{PartName="Right Arm",meshid="105141400603933",C0=angles(0,0,1.5707963267948966)},
	{PartName="Head",meshid="13953153289"},
	{PartName="Left Leg",meshid="17387586286",C0=angles(1.5707963267948966,0,1.5707963267948966)},
	{PartName="Right Leg",meshid="17387586286",C0=angles(-1.5707963267948966,0,1.5707963267948966)},
	{PartName="Left Arm",meshid="17374767929",C0=angles(1.5707963267948966,0,1.5707963267948966)},
	{PartName="Right Arm",meshid="17374767929",C0=angles(-1.5707963267948966,0,1.5707963267948966)},
	{PartName="Left Leg",meshid="125405780718494",C0=angles(1.5707963267948966,0,1.5707963267948966)},
	{PartName="Right Leg",meshid="125405780718494",C0=angles(-1.5707963267948966,0,1.5707963267948966)},
	{PartName="Left Arm",meshid="125405780718494",C0=angles(1.5707963267948966,0,1.5707963267948966)},
	{PartName="Right Arm",meshid="125405780718494",C0=angles(-1.5707963267948966,0,1.5707963267948966)},

	{PartName="Head",meshid="13953094351"},
	{PartName="Torso",meshid="127552124837034",C0=angles(0,0,1.5707963267948966)},
	{PartName="Left Leg",meshid="121304376791439"},
	{PartName="Right Leg",meshid="121304376791439"},
	{PartName="Left Arm",meshid="117287001096396"},
	{PartName="Right Arm",meshid="117287001096396"},

	{PartName="Head",meshid="13058309233",C0=angles(0,3.141592653589793,0)},
	{PartName="Torso",meshid="18640899369"},
	{PartName="Left Leg",meshid="18640901641"},
	{PartName="Right Leg",meshid="18640901641"},
	{PartName="Left Arm",meshid="18640914129"},
	{PartName="Right Arm",meshid="18640914129"},
	{PartName="Torso",meshid="126825022897778"},
	{PartName="Left Leg",textureid="73798034827573",C0=angles(0,0,1.5707963267948966)},
	{PartName="Right Leg",textureid="73798034827573",C0=angles(0,0,1.5707963267948966)},
	{PartName="Left Arm",textureid="135650240593878",C0=angles(0,0,1.5707963267948966)},
	{PartName="Right Arm",textureid="135650240593878",C0=angles(0,0,1.5707963267948966)},

	{PartName="Torso",meshid="126825022897778"},

	{PartName="Torso",meshid="139792224823925"},
	{PartName="Left Leg",meshid="83395427313429",C0=angles(0,0,1.5707963267948966)},
	{PartName="Right Leg",meshid="83395427313429",C0=angles(0,0,1.5707963267948966)},
	{PartName="Left Arm",meshid="105263225400272",C0=angles(0,0,1.5707963267948966)},
	{PartName="Right Arm",meshid="105263225400272",C0=angles(0,0,1.5707963267948966)},

	{PartName="Head",AccessoryName="Accessory (autorig_Head)"},
	{PartName="Torso",AccessoryName="Accessory (autorig_Torso)"},
	{PartName="Left Leg",AccessoryName="Accessory (autorig_LeftLeg)"},
	{PartName="Right Leg",AccessoryName="Accessory (autorig_RightLeg)"},
	{PartName="Left Arm",AccessoryName="Accessory (autorig_LeftArm)"},
	{PartName="Right Arm",AccessoryName="Accessory (autorig_RightArm)"},

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
local placeholders=placeholders~=false
local clickfling=false
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
			if v then
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

	local novoid=true
	local antivoid=true
	local speedlimit=3000
	local retVelTime=0.51
	local walkSpeed=16
	local jumpPower=50
	local gravity=196.2
	local ctrlclicktp=ctrltp

	if stopreanimate() then return end

	local cam=nil
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
	local camOverride=nil
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
			if IsA(v,"Script") then
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
	local inputBlocker=nil

	tinsert(cons,Connect(insGet(uis,"TouchStarted"),function(inputObject,gp)
		if insGet(gs,"MenuIsOpen") or GetFocusedTextBox(uis) then
			return
		end

		if inputBlocker and inputBlocker(inputObject) then
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
		elseif gp then
			return
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
		if b or (inputBlocker and inputBlocker(a)) then return end
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
		elseif antivoid then
			Yvel=0
			onground=false
		else
			Yvel=Yvel-gravity*delta
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

		if camOverride then
			local ok,ncf=pcall(camOverride,camcf)
			if ok and typeof(ncf)=="CFrame" then
				camcf=ncf
				insSet(cam,"CFrame",camcf)
			end
		end
		refreshjointsI(rootpart)
		tclear(refreshedjoints)

		local sine15=sine*15
		local idlerv=v3(sin(sine15),sin(sine15+1.0471975511965976),sin(sine15+2.0943951023931953))
		local idleoff=idlerv*0.003910064697265625

		local claimpos=insGet(primarypart,"Position")

		for i,v in next,cframes do
			local part=i.p
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
					if mag<0.11730194091796875 then
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
							if a>0 then
								insSet(part,"AssemblyLinearVelocity",v3_net+offsetToPrimaryPart*v3_101/((25.01+sqrt(a))/wsGravity))
							else
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

	local refreshjoints=function(v)
		refreshjointsI(v)
		tclear(refreshedjoints)
	end

	local legcfR=cf(1,-1,0)
	local legcfL=cf(-1,-1,0)
	local raydir=v3_010*-2
	local raycastlegs=function()
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

	local velbycfrvec=function()
		local fw=cfGet(cfr,"LookVector")*xzvel/walkSpeed
		local rt=cfGet(cfr,"RightVector")*xzvel/walkSpeed
		return v3Get(fw,"X")+v3Get(fw,"Z"),v3Get(rt,"X")+v3Get(rt,"Z")
	end

	local lastvel=v3_0
	local velchg1=v3_0
	local velchgbycfrvec=function()
		velchg1=velchg1+(lastvel-xzvel)
		lastvel=xzvel
		velchg1=velchg1-velchg1*(deltaTime/2)
		local fw=cfGet(cfr,"LookVector")*velchg1/32
		local rt=cfGet(cfr,"RightVector")*velchg1/32
		return v3Get(fw,"X")+v3Get(fw,"Z"),v3Get(rt,"X")+v3Get(rt,"Z")
	end

	local lastYvel=0
	local velYchg1=0
	local velYchg=function()
		velYchg1=clamp(velYchg1+(lastYvel-Yvel),-50,50)
		lastYvel=Yvel
		velYchg1=velYchg1-velYchg1*(deltaTime/2)
		return velYchg1
	end

	local rotToMouse=function(alpha)
		local pos1=pos*v3_010+cfGet(insGet(mouse,"Hit"),"Position")*v3_101
		if pos~=pos1 then
			cfr=Lerp(cfr,cfl(pos,pos1),alpha or deltaTime)
		end
	end

	local glitchJoint=function(joint,targetGlitchTime,delayFrom,delayTo,radiansFrom,radiansTo) 
		if sine>targetGlitchTime then
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
	local setCfr=function(v)
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
	local getVel=function()
		return xzvel+v3_010*Yvel
	end
	local setShiftlock=function(b)
		shiftlock=allowshiftlock and (b==true)
	end
	local getShiftlock=function()
		return shiftlock
	end
	local getCamCF=function()
		return camcf
	end
	local isFirstPerson=function()
		return firstperson
	end
	local setCameraMoveable=function(b)
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
		setShiftlock=setShiftlock,
		getShiftlock=getShiftlock,
		setInputBlocker=function(f)
			inputBlocker=f
		end,
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
		YvelSign=YvelSign,
		setAntivoid=function(b)
			antivoid=b~=false
		end,
		getAntivoid=function()
			return antivoid
		end,
		setCamZoom=function(m)
			cammag=math.min(m,0)
			firstperson=cammag>=0
		end,
		getCamZoom=function()
			return cammag
		end,
		setCamOverride=function(f)
			camOverride=f
		end
	}
end

local gp=function(p,n,c)
	return QueryDescendants(p,">"..c.."[Name=\""..n.."\"]")[1]
end

_G.GenesisFDless={reanimate=reanimate,stopreanimate=stopreanimate,gp=gp,rs=rs,insSet=insSet,insGet=insGet,cfMul=cfMul,mouse=mouse,isReanimated=function() return c end}
return _G.GenesisFDless
end)()

local function LCCore(FD, CFG)
	local C = {}
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local UIS = game:GetService("UserInputService")
	local HttpService = game:GetService("HttpService")
	local StarterGui = game:GetService("StarterGui")
	local lp = Players.LocalPlayer
	local V3, CFn, ANG, C3 = Vector3.new, CFrame.new, CFrame.Angles, Color3.new
	local rad, floor, random, min, max = math.rad, math.floor, math.random, math.min, math.max
	local osclock = os.clock
	local IDENT = CFrame.identity
	local KEYBOARD = Enum.UserInputType.Keyboard
	local MB1 = Enum.UserInputType.MouseButton1
	local TOUCH = Enum.UserInputType.Touch

	if type(_G.LCFD_Stop) == "function" then
		pcall(_G.LCFD_Stop)
	end
	if FD.isReanimated() then
		FD.stopreanimate()
	end
	local fd = FD.reanimate()
	if not fd then
		fd = FD.reanimate()
	end
	if not fd then
		warn("[LC] FDless did not start")
		return nil
	end
	C.fd = fd
	C.alive = true
	C.time = 0
	C.ticks = 0
	C.frame = 0
	C.dt = 1 / 60
	C.pow = 1
	C.neon = C3(1, 1, 1)
	C.state = "Idle"

	local function r6(name)
		for p in pairs(fd.cframes) do
			if type(p) == "table" and p.Name == name and rawget(p, "m") == nil then
				return p
			end
		end
		return fd.getPart(name)
	end
	C.Root = r6("HumanoidRootPart")
	C.Torso = r6("Torso")
	C.Head = r6("Head")
	C.RightArm = r6("Right Arm")
	C.LeftArm = r6("Left Arm")
	C.RightLeg = r6("Right Leg")
	C.LeftLeg = r6("Left Leg")
	C.RootJoint = fd.getJoint("RootJoint")
	C.Neck = fd.getJoint("Neck")
	C.RightShoulder = fd.getJoint("Right Shoulder")
	C.LeftShoulder = fd.getJoint("Left Shoulder")
	C.RightHip = fd.getJoint("Right Hip")
	C.LeftHip = fd.getJoint("Left Hip")
	local cframes = fd.cframes
	function C.cf(part)
		return cframes[part] or IDENT
	end

	local cons, cleanups = {}, {}
	function C.connect(sig, fn)
		local c = sig:Connect(fn)
		cons[#cons + 1] = c
		return c
	end
	function C.onStop(fn)
		cleanups[#cleanups + 1] = fn
	end
	local errs = {}
	function C.err(e)
		e = tostring(e)
		if not errs[e] then
			errs[e] = true
			warn("[LC] " .. e)
		end
	end

	local Effects = Instance.new("Folder")
	Effects.Name = "LCFX" .. random(1000, 9999)
	Effects.Parent = workspace
	C.Effects = Effects

	function C.guiParent()
		local ok, h = pcall(function()
			return gethui and gethui()
		end)
		if ok and typeof(h) == "Instance" then
			return h
		end
		local cg = game:FindFirstChildOfClass("CoreGui")
		if cg and pcall(function()
			return cg:FindFirstChildOfClass("ScreenGui")
		end) then
			return cg
		end
		return lp:FindFirstChildOfClass("PlayerGui")
	end

	function C.notify(title, text, dur)
		hubNotify(title, text, "info", dur)
	end

	local waiters = {}
	function C.swait(n)
		if not C.alive then
			coroutine.yield()
		end
		n = tonumber(n) or 1
		if n < 1 then
			n = 1
		end
		waiters[#waiters + 1] = {coroutine.running(), floor(n)}
		coroutine.yield()
		if not C.alive then
			coroutine.yield()
		end
	end

	function C.clerp(a, b, t)
		if t >= 1 then
			return b
		elseif t <= 0 then
			return a
		end
		local p = C.pow
		if p ~= 1 then
			t = 1 - (1 - t) ^ p
		end
		return a:Lerp(b, t)
	end

	function C.newPart(props)
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Locked = true
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Material = Enum.Material.Neon
		local parent = Effects
		if props then
			for k, v in pairs(props) do
				if k == "Parent" then
					parent = v
				else
					p[k] = v
				end
			end
		end
		p.Parent = parent
		return p
	end

	function C.toColor(c)
		local t = typeof(c)
		if t == "Color3" then
			return c
		elseif t == "BrickColor" then
			return c.Color
		elseif t == "string" then
			return BrickColor.new(c).Color
		end
		return C3(1, 1, 1)
	end

	local mats = {}
	local function matEnum(m)
		if typeof(m) == "EnumItem" then
			return m
		end
		m = m or "Neon"
		local e = mats[m]
		if e == nil then
			local ok, r = pcall(function()
				return Enum.Material[m]
			end)
			e = ok and r or Enum.Material.Neon
			mats[m] = e
		end
		return e
	end

	local mrp = RaycastParams.new()
	mrp.FilterType = Enum.RaycastFilterType.Exclude
	mrp.RespectCanCollide = true
	local hitFrame, hitCF = -1, CFn()
	function C.mouseHit()
		if hitFrame == C.frame then
			return hitCF
		end
		hitFrame = C.frame
		local cam = workspace.CurrentCamera
		if not cam then
			return hitCF
		end
		local loc = UIS:GetMouseLocation()
		local ray = cam:ViewportPointToRay(loc.X, loc.Y)
		local list = {Effects}
		if lp.Character then
			list[2] = lp.Character
		end
		mrp.FilterDescendantsInstances = list
		local res = workspace:Raycast(ray.Origin, ray.Direction * 1000, mrp)
		local pos = res and res.Position or (ray.Origin + ray.Direction * 1000)
		hitCF = CFrame.lookAt(ray.Origin, pos).Rotation + pos
		return hitCF
	end

	local rrp = RaycastParams.new()
	rrp.FilterType = Enum.RaycastFilterType.Exclude
	rrp.RespectCanCollide = true
	function C.ray(origin, dir, range, extra)
		local list = {Effects}
		if lp.Character then
			list[2] = lp.Character
		end
		if typeof(extra) == "Instance" then
			list[#list + 1] = extra
		end
		rrp.FilterDescendantsInstances = list
		local d = dir.Magnitude > 0 and dir.Unit or V3(0, -1, 0)
		local res = workspace:Raycast(origin, d * (range or 999), rrp)
		if res then
			return res.Instance, res.Position, res.Normal
		end
		return nil, origin + d * (range or 999), V3(0, 1, 0)
	end

	function C.rootCF()
		return cframes[C.Root] or IDENT
	end
	function C.setRoot(cf)
		fd.setCfr(cf)
	end
	function C.face(pos, alpha)
		local cf = C.rootCF()
		local p = cf.Position
		local flat = V3(pos.X, p.Y, pos.Z)
		if (flat - p).Magnitude < 0.05 then
			return
		end
		local goal = CFrame.lookAt(p, flat)
		if alpha and alpha < 1 then
			goal = cf:Lerp(goal, alpha)
		end
		fd.setCfr(goal)
	end
	function C.vel()
		local ok, v = pcall(fd.getVel)
		return ok and v or V3()
	end

	local liveSounds = 0
	function C.sound(id, vol, pitch, looped)
		if not C.alive or id == nil then
			return nil
		end
		if liveSounds >= 24 and not looped then
			return nil
		end
		local s = Instance.new("Sound")
		local sid = tostring(id)
		if not sid:find("://", 1, true) then
			sid = "rbxassetid://" .. sid
		end
		s.SoundId = sid
		s.Volume = min(tonumber(vol) or 1, 10)
		s.PlaybackSpeed = tonumber(pitch) or 1
		s.Looped = looped == true
		s.Parent = Effects
		s:Play()
		if not looped then
			liveSounds += 1
			local done = false
			local function fin()
				if done then
					return
				end
				done = true
				liveSounds -= 1
				s:Destroy()
			end
			s.Ended:Once(fin)
			task.delay(15, fin)
		end
		return s
	end

	local music = Instance.new("Sound")
	music.Name = "Music"
	music.Looped = true
	music.Volume = 4
	music.Parent = Effects
	C.music = music
	local pendingMusic = nil
	function C.clearPendingMusic()
		pendingMusic = nil
	end
	function C.asset(file)
		local f = getcustomasset or getsynasset
		if not f then
			return nil
		end
		local okFile, has = pcall(function()
			return isfile and isfile(file)
		end)
		if not (okFile and has) then
			return nil
		end
		local ok, r = pcall(f, file)
		if ok then
			return r
		end
		return nil
	end
	function C.setMusic(file, vol, pos, speed)
		if vol then
			music.Volume = min(vol, 10)
		end
		music.PlaybackSpeed = speed or 1
		if file then
			local id = C.asset(file)
			if id then
				music.SoundId = id
				pendingMusic = nil
			else
				pendingMusic = {file, vol, pos, speed}
			end
		end
		music:Play()
		if pos then
			music.TimePosition = pos
			if not music.IsLoaded then
				music.Loaded:Once(function()
					music.TimePosition = pos
				end)
			end
		end
	end
	function C.download(list)
		task.spawn(function()
			if not (writefile and isfile) then
				return
			end
			local first = true
			for _, it in ipairs(list) do
				local okF, has = pcall(isfile, it[1])
				if okF and not has then
					if first then
						first = false
						C.notify("Addict", "Downloading music...", 4)
					end
					local ok, data = pcall(function()
						return game:HttpGet(it[2])
					end)
					if ok and type(data) == "string" and #data > 2000 and (data:sub(1, 3) == "ID3" or data:byte(1) == 255) then
						pcall(writefile, it[1], data)
					end
				end
				if pendingMusic and pendingMusic[1] == it[1] and C.alive then
					local pm = pendingMusic
					C.setMusic(pm[1], pm[2], pm[3], pm[4])
				end
			end
		end)
	end

	local MESH = {
		Wave = "20329976", Ring = "559831844", Slash = "662586858", ["Round Slash"] = "662585058",
		Swirl = "168892432", Skull = "4770583", Crystal = "9756362", Star = "2760116123",
	}
	C.MESH = MESH
	local pool, fx = {}, {}
	local MAXFX = CFG.maxEffects or 220
	local HIDE = CFn(0, -4000, 0)
	local function grab(kind)
		local list = pool[kind]
		if list and #list > 0 then
			local o = list[#list]
			list[#list] = nil
			return o
		end
		local p = C.newPart({Size = V3(1, 1, 1), Name = "fx"})
		local m
		if kind == "Box" then
			m = Instance.new("BlockMesh")
		elseif kind == "Cyl" then
			m = Instance.new("CylinderMesh")
		else
			m = Instance.new("SpecialMesh")
			if kind == "Sphere" then
				m.MeshType = Enum.MeshType.Sphere
			elseif kind == "Brick" then
				m.MeshType = Enum.MeshType.Brick
			else
				m.MeshType = Enum.MeshType.FileMesh
				m.MeshId = "rbxassetid://" .. string.sub(kind, 2)
			end
		end
		m.Parent = p
		return {p = p, m = m, kind = kind}
	end
	local function release(o)
		o.p.Transparency = 1
		local list = pool[o.kind]
		if not list then
			list = {}
			pool[o.kind] = list
		end
		if #list < 80 and C.alive then
			o.p.CFrame = HIDE
			list[#list + 1] = o
		else
			o.p:Destroy()
		end
	end
	function C.fxCount()
		return #fx
	end

	function C.Effect(T)
		if not C.alive or #fx >= MAXFX then
			return nil
		end
		local TYPE = T.EffectType or "Sphere"
		local kind
		if TYPE == "Sphere" then
			kind = "Sphere"
		elseif TYPE == "Block" or TYPE == "Box" then
			kind = "Box"
		elseif TYPE == "Brick" then
			kind = "Brick"
		else
			local id = T.MeshId or MESH[TYPE]
			if not id then
				return nil
			end
			kind = "F" .. tostring(id)
		end
		local SIZE = T.Size or V3(1, 1, 1)
		local ENDSIZE = T.Size2 or V3()
		local TR = T.Transparency or 0
		local TR2 = T.Transparency2 or 1
		local CF0 = T.CFrame or C.cf(C.Torso)
		local TIME = max(1, tonumber(T.Time) or 45)
		local scale
		if T.RawScale then
			scale = SIZE
		elseif TYPE == "Ring" then
			scale = V3(SIZE.X, SIZE.X, 0.1)
		elseif TYPE == "Slash" or TYPE == "Round Slash" then
			scale = V3(SIZE.X / 10, 0, SIZE.X / 10)
		else
			scale = SIZE
		end
		local boom = T.UseBoomerangMath == true
		local B1 = 1 + (T.Boomerang or 0) / 50
		local B2 = 1 + (T.SizeBoomerang or 0) / 50
		local growth = boom and (SIZE - ENDSIZE) * (B2 + 1) or (SIZE - ENDSIZE)
		local spd
		if T.MoveToPos then
			spd = (CF0.Position - T.MoveToPos).Magnitude / TIME
			if boom then
				spd *= B1
			end
		end
		local randRot = T.RandomSpin or TYPE == "Block"
		local cf = CF0
		if randRot then
			cf = CF0 * ANG(rad(random(0, 360)), rad(random(0, 360)), rad(random(0, 360)))
		end
		local o = grab(kind)
		local p, m = o.p, o.m
		p.Color = C.toColor(T.Color)
		p.Material = matEnum(T.Material)
		p.Transparency = TR
		m.Scale = scale
		m.Offset = TYPE == "Wave" and V3(0, 0, -scale.Z / 8) or V3()
		p.CFrame = cf
		local rot
		local rx, ry, rz = tonumber(T.RotationX) or 0, tonumber(T.RotationY) or 0, tonumber(T.RotationZ) or 0
		if not randRot and (rx ~= 0 or ry ~= 0 or rz ~= 0) then
			rot = ANG(rad(rx), rad(ry), rad(rz))
		end
		fx[#fx + 1] = {
			o = o, L = 0, T = TIME, cf = cf, cf0 = CF0, scale = scale, growth = growth, boom = boom,
			B1 = B1, B2 = B2, tr = TR, dtr = (TR - TR2) / TIME, rot = rot, randRot = randRot,
			mv = T.MoveToPos, spd = spd, wave = TYPE == "Wave", rainbow = T.Rainbow, rcol = T.RandomColor,
		}
		if T.SoundID and T.SoundPitch and T.SoundVolume then
			C.sound(T.SoundID, T.SoundVolume, T.SoundPitch)
		end
		return p
	end

	function C.beam(a, b, width, T, color, tr0, tr1, widthZ, rcol)
		local dist = (a - b).Magnitude
		if not C.alive or dist < 0.05 or #fx >= MAXFX then
			return nil
		end
		local o = grab("Cyl")
		local p = o.p
		p.Size = V3(width, dist, widthZ or width)
		p.Color = C.toColor(color)
		p.Material = Enum.Material.Neon
		tr0 = tr0 or 0
		p.Transparency = tr0
		local cf = CFrame.lookAt(a, b) * CFn(0, 0, -dist / 2) * ANG(rad(90), 0, 0)
		p.CFrame = cf
		T = max(1, T or 25)
		fx[#fx + 1] = {o = o, L = 0, T = T, cf = cf, fixed = true, tr = tr0, dtr = (tr0 - (tr1 or 1)) / T, rcol = rcol}
		return p
	end

	local bmP, bmC = {}, {}
	local function stepFX()
		local n = #fx
		if n == 0 then
			return
		end
		local i, cnt = 1, 0
		while i <= n do
			local e = fx[i]
			e.L += 1
			local L, T = e.L, e.T
			if L > T + 1 then
				release(e.o)
				fx[i] = fx[n]
				fx[n] = nil
				n -= 1
			else
				local p = e.o.p
				if not e.fixed then
					local m = e.o.m
					if e.boom then
						e.scale -= e.growth * ((1 - (L / T) * e.B2) * e.B2 / T)
					else
						e.scale -= e.growth / T
					end
					m.Scale = e.scale
					if e.wave then
						m.Offset = V3(0, 0, -e.scale.Z / 8)
					end
				end
				e.tr -= e.dtr
				p.Transparency = e.tr
				local cf = e.cf
				if e.randRot then
					cf = e.cf0 * ANG(rad(random(0, 360)), rad(random(0, 360)), rad(random(0, 360)))
				elseif e.rot then
					cf *= e.rot
				end
				if e.mv then
					local pos = cf.Position
					local d = e.mv - pos
					local mag = d.Magnitude
					if mag > 1e-3 then
						local s = e.spd
						if e.boom then
							s *= (1 - (L / T) * e.B1)
						end
						cf = cf.Rotation + (pos + d / mag * s)
					end
				end
				e.cf = cf
				if e.rainbow then
					p.Color = C.neon
				elseif e.rcol then
					p.Color = BrickColor.random().Color
				end
				cnt += 1
				bmP[cnt] = p
				bmC[cnt] = cf
				i += 1
			end
		end
		if cnt > 0 then
			if not pcall(workspace.BulkMoveTo, workspace, bmP, bmC, Enum.BulkMoveMode.FireCFrameChanged) then
				for k = 1, cnt do
					bmP[k].CFrame = bmC[k]
				end
			end
			table.clear(bmP)
			table.clear(bmC)
		end
	end

	function C.lightning(from, to, segs, offset, color, timer, sSize, eSize, trans, boomer, sBoomer, trans2, rainbow)
		local magz = (from - to).Magnitude
		if magz < 0.1 or not C.alive then
			return
		end
		local times = math.clamp(math.floor(math.min(segs or 10, magz / 12)), 1, 10)
		local curpos = from
		local step = magz / times
		for i = 1, times do
			local cf, len
			if i == times then
				len = (curpos - to).Magnitude
				if len < 0.05 then
					break
				end
				cf = CFrame.lookAt(curpos, to) * CFn(0, 0, -len / 2)
			else
				local off = V3(random(0, 1) == 0 and -offset or offset, random(0, 1) == 0 and -offset or offset, random(0, 1) == 0 and -offset or offset)
				local trol = (CFrame.lookAt(curpos, to) * CFn(0, 0, step)).Position + off
				len = step
				cf = CFrame.lookAt(curpos, trol) * CFn(0, 0, step / 2)
			end
			curpos = (cf * CFn(0, 0, step / 2)).Position
			C.Effect({
				Time = timer, EffectType = "Box", Size = V3(sSize, sSize, len), Size2 = V3(eSize, eSize, len),
				Transparency = trans, Transparency2 = trans2 or 1, CFrame = cf, Material = "Neon", Color = color,
				UseBoomerangMath = boomer, Boomerang = 0, SizeBoomerang = sBoomer, Rainbow = rainbow,
			})
		end
	end

	function C.fireArc(part, to, ticks, height, destroyAtEnd)
		local dir = CFrame.lookAt(part.Position, to)
		local dist = (part.Position - to).Magnitude
		for i = 1, ticks do
			C.swait()
			if not part.Parent then
				return
			end
			part.CFrame = dir * CFn(0, ticks / 200 + (ticks / height - i * 2 / height), -dist / ticks)
			dir = part.CFrame
		end
		if destroyAtEnd then
			part:Destroy()
		end
	end

	local anchor = C.newPart({Name = "HeadAnchor", Transparency = 1, Size = V3(1, 1, 1)})
	C.anchor = anchor
	local FONTS = {"Antique", "Arcade", "Arial", "ArialBold", "Bodoni", "Cartoon", "Code", "Fantasy", "Garamond", "Highway", "SciFi", "SourceSans", "SourceSansBold", "SourceSansItalic", "SourceSansLight", "SourceSansSemibold"}
	function C.chat(text, opts)
		opts = opts or {}
		task.spawn(function()
			local old = anchor:FindFirstChild("TalkBB")
			if old then
				old:Destroy()
			end
			local bb = Instance.new("BillboardGui")
			bb.Name = "TalkBB"
			bb.Size = UDim2.new(0, 9999, 2, 0)
			bb.StudsOffset = V3(0, opts.offset or 3, 0)
			bb.Adornee = anchor
			bb.Parent = anchor
			local labels = {}
			for k = 1, 2 do
				local t = Instance.new("TextLabel")
				t.BackgroundTransparency = 1
				t.BorderSizePixel = 0
				t.Text = ""
				t.Font = opts.font or Enum.Font.Code
				t.TextScaled = true
				t.TextStrokeTransparency = 0
				t.TextStrokeColor3 = opts.stroke or C3(1, 1, 1)
				t.Size = UDim2.fromScale(1, 1)
				t.Parent = bb
				labels[k] = t
			end
			local a, b = labels[1], labels[2]
			local n = #text
			local total = n + 180 + 50
			for t = 1, total do
				C.swait()
				if not bb.Parent then
					return
				end
				if opts.colA then
					a.TextColor3 = opts.colA()
				end
				if opts.colB then
					b.TextColor3 = opts.colB()
				end
				if opts.glitchy then
					local f = Enum.Font[FONTS[random(1, #FONTS)]]
					a.Font = f
					b.Font = f
				end
				if t <= n then
					local s = string.sub(text, 1, t)
					a.Text = s
					b.Text = s
				end
				if t <= n + 180 then
					a.Position = UDim2.new(0, random(-3, 3), 0, random(-3, 3))
					b.Position = UDim2.new(0, random(-3, 3), 0, random(-3, 3))
				else
					local k = (t - n - 180) / 50
					a.Position -= UDim2.new(0, random(-3, 3), 0, random(-3, 3))
					b.Position = a.Position - UDim2.new(0, random(-3, 3), 0, random(-3, 3))
					a.Rotation += random(-2, 2)
					b.Rotation += random(-2, 2)
					a.TextStrokeTransparency = k
					a.TextTransparency = k
					b.TextStrokeTransparency = k
					b.TextTransparency = k
				end
			end
			bb:Destroy()
		end)
	end

	C.GunJoint = {C0 = CFn(0.05, -1, -0.15) * ANG(rad(-90), 0, 0)}
	local GUN_IDS = CFG.gunIds or {}
	local DEFAULT = {{0, 0, 0, 0, 0, 0}, {0, 0, 0, 0, 0, 0}, {0, 0, 0, 0, 0, 0}, {0, 0, 0, 0, 0, 0}, {0, 0, 0, 0, 0, 0}, {0, 0, 0, 0, 0, 0}, {0, 0, 0, 0, 0, 0}}
	local VAL = {}
	local OFF = {}
	for s = 1, 7 do
		VAL[s] = table.clone(DEFAULT[s])
	end
	local function rebuild(s)
		local v = VAL[s]
		OFF[s] = CFn(v[1], v[2], v[3]) * ANG(rad(v[4]), rad(v[5]), rad(v[6]))
	end
	for s = 1, 7 do
		rebuild(s)
	end
	local FILE = CFG.alignFile or "LCGunAlign.json"
	local SLOTKEY = {"gun1", "gun2", "muzzle", "railgun", "sword", "swordback", "gunship"}
	local function loadAlign()
		if not (isfile and readfile) then
			return false, "your executor can't read files"
		end
		local ok, has = pcall(isfile, FILE)
		if not ok or not has then
			return false, "no saved alignment yet"
		end
		local ok2, txt = pcall(readfile, FILE)
		if not ok2 or type(txt) ~= "string" then
			return false, "couldn't read " .. FILE
		end
		local ok3, data = pcall(function()
			return HttpService:JSONDecode(txt)
		end)
		if not ok3 or type(data) ~= "table" then
			return false, FILE .. " is damaged"
		end
		for s = 1, 7 do
			local a = data[SLOTKEY[s]]
			if type(a) == "table" then
				for k = 1, 6 do
					local n = tonumber(a[k])
					if n and n == n and math.abs(n) < 1e5 then
						VAL[s][k] = n
					end
				end
				rebuild(s)
			end
		end
		return true
	end
	local function saveAlign()
		if not writefile then
			return false, "your executor can't save files"
		end
		local txt = HttpService:JSONEncode({v = 1, gun1 = VAL[1], gun2 = VAL[2], muzzle = VAL[3], railgun = VAL[4], sword = VAL[5], swordback = VAL[6], gunship = VAL[7]})
		local ok, e = pcall(writefile, FILE, txt)
		if not ok then
			return false, tostring(e)
		end
		return true
	end
	loadAlign()

	local gunEntry, gunJoint = {}, {}
	C.gunEntry = gunEntry
	function C.alignOff(s)
		return OFF[s]
	end
	function C.alignVal(s)
		return VAL[s]
	end
	local NGUNS = 3
	local OFFIDX = {1, 2, 4}
	local GRIP0 = C.GunJoint.C0
	local RAIL_C1 = CFn(-1.2, 0.5, 0, 0, 0.707106769, 0.707106829, 0, -0.707106829, 0.707106769, 1, 0, 0)
	local HAND = CFn(0.05, -1, 0.15) * ANG(rad(180), rad(180), 0)
	local BASE = {IDENT, IDENT, GRIP0:Inverse() * HAND * RAIL_C1:Inverse()}
	local MUZZLE_ATT = {
		{"77229698901212", CFn(2.29999971, 0.0999908447, 0, -4.37114878e-08, 1, 2.18948799e-06, 1.39334895e-14, -2.18948799e-06, 1, 1, 4.37114878e-08, 8.17722897e-14)},
		{"4615369575", CFn(1.98886108, -1.84744835, 0, 0, 0.707105279, 0.707108319, 0, -0.707108319, 0.707105279, 1, 0, 0)},
	}
	local function findGun(slot)
		for pass = 1, 2 do
			for _, id in ipairs(GUN_IDS[slot] or {}) do
				for e in pairs(cframes) do
					if type(e) == "table" then
						local m, t = rawget(e, "m"), rawget(e, "t")
						if type(m) == "string" and m:find(id[1], 1, true) and (pass == 2 or id[2] == nil or (type(t) == "string" and t:find(id[2], 1, true))) then
							return e
						end
					end
				end
			end
		end
		return nil
	end
	local function refreshGuns()
		for s = 1, NGUNS do
			local e = gunEntry[s]
			if not e or cframes[e] == nil then
				gunEntry[s] = findGun(s)
				gunJoint[s] = nil
			end
		end
	end
	refreshGuns()
	function C.gunFound(s)
		local e = gunEntry[s]
		return e ~= nil and rawget(e, "p") ~= nil
	end
	C.gunsHeld = true
	C.gunArm = C.RightArm
	local origJoint = setmetatable({}, {__mode = "k"})
	local function applyGuns()
		local grip = C.GunJoint.C0
		local held = C.gunsHeld ~= false
		for s = 1, NGUNS do
			local e = gunEntry[s]
			if e then
				local j = gunJoint[s]
				if not j or j.Part0 ~= e then
					j = fd.getPartJoint(e)
					gunJoint[s] = j
				end
				if j then
					local o = origJoint[j]
					if not o then
						o = {j.Part1, j.C0, j.C1}
						origJoint[j] = o
					end
					if held then
						j.Part1 = C.gunArm or C.RightArm
						j.C0 = IDENT
						j.C1 = grip * BASE[s] * OFF[OFFIDX[s]]
					else
						j.Part1, j.C0, j.C1 = o[1], o[2], o[3]
					end
				end
			end
		end
	end
	function C.gripCF()
		return C.cf(C.gunArm or C.RightArm) * C.GunJoint.C0
	end
	local function muzzleAtt(e)
		local m = rawget(e, "m")
		if type(m) ~= "string" then
			return nil
		end
		for _, a in ipairs(MUZZLE_ATT) do
			if m:find(a[1], 1, true) then
				return a[2]
			end
		end
		return nil
	end
	function C.muzzleCF()
		local g = C.gripCF()
		if C.gunsHeld ~= false then
			for _, s in ipairs({1, 2, 3}) do
				local e = gunEntry[s]
				if e and cframes[e] ~= nil and rawget(e, "p") then
					local att = muzzleAtt(e)
					if not att then
						break
					end
					local v = VAL[3]
					local rot = g.Rotation * ANG(rad(v[4]), rad(v[5]), rad(v[6]))
					local tip = (cframes[e] * att).Position
					return rot + tip + g.Rotation * V3(v[1], v[2], v[3] - DEFAULT[3][3])
				end
			end
		end
		return g * OFF[3]
	end

	local lastT = 0
	local lastLerp = osclock()
	local function frame(state)
		if not C.alive then
			return
		end
		local dt = C.time - lastT
		lastT = C.time
		lastLerp = osclock()
		if dt > 0.1 then
			dt = 0.1
		elseif dt < 0 then
			dt = 0
		end
		C.dt = dt
		C.state = state
		C.pow = dt * 60
		if C.animate then
			local ok, e = pcall(C.animate, state, dt)
			if not ok then
				C.err(e)
			end
		end
		C.pow = 1
		applyGuns()
		anchor.CFrame = C.cf(C.Head)
		if C.alignFrame then
			C.alignFrame()
		end
		if C.afterFrame then
			local ok, e = pcall(C.afterFrame, dt)
			if not ok then
				C.err(e)
			end
		end
	end
	fd.addmode("default", {
		idle = function()
			frame("Idle")
		end,
		walk = function()
			frame("Walk")
		end,
		jump = function()
			frame("Jump")
		end,
		fall = function()
			frame("Fall")
		end,
	})

	local acc, gunScan, lastStep = 0, 0, osclock()
	C.connect(RunService.Stepped, function(_, dt)
		if not C.alive then
			return
		end
		local nowc = osclock()
		if nowc - lastStep > 1 then
			lastLerp = nowc
		end
		lastStep = nowc
		if nowc - lastLerp > 2 then
			C.stop(false)
			return
		end
		C.frame += 1
		dt = math.min(dt or 0, 0.25)
		C.time += dt
		gunScan += dt
		if gunScan > 0.5 then
			gunScan = 0
			refreshGuns()
		end
		acc += dt
		local n = floor(acc * 60)
		acc -= n / 60
		if n > 4 then
			n = 4
			acc = 0
		end
		for _ = 1, n do
			C.ticks += 1
			if C.tick then
				local ok, e = pcall(C.tick)
				if not ok then
					C.err(e)
				end
			end
			local list = waiters
			waiters = {}
			for k = 1, #list do
				local w = list[k]
				w[2] -= 1
				if w[2] <= 0 then
					local ok, e = pcall(task.spawn, w[1])
					if not ok then
						C.err(e)
					end
				else
					waiters[#waiters + 1] = w
				end
			end
			stepFX()
		end
	end)

	C.keysDown = {}
	C.touchTaps = setmetatable({}, {__mode = "k"})
	C.connect(UIS.InputBegan, function(io, gp)
		if io.UserInputType == KEYBOARD then
			if gp or UIS:GetFocusedTextBox() then
				return
			end
			local name = string.lower(io.KeyCode.Name)
			C.keysDown[name] = true
			if name == (CFG.alignKey or "j") and C.toggleAlign and not (UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.RightShift)) then
				C.toggleAlign()
				return
			end
			if C.keyDown then
				task.spawn(C.keyDown, name)
			end
		elseif io.UserInputType == MB1 then
			if gp then
				return
			end
			if C.click then
				task.spawn(C.click)
			end
		elseif io.UserInputType == TOUCH then
			if not gp then
				C.touchTaps[io] = {osclock(), io.Position}
			end
		end
	end)
	C.connect(UIS.InputEnded, function(io)
		if io.UserInputType == KEYBOARD then
			local name = string.lower(io.KeyCode.Name)
			C.keysDown[name] = nil
			if C.keyUp then
				task.spawn(C.keyUp, name)
			end
		elseif io.UserInputType == MB1 then
			if C.clickUp then
				task.spawn(C.clickUp)
			end
		elseif io.UserInputType == TOUCH then
			local t = C.touchTaps[io]
			C.touchTaps[io] = nil
			if t and osclock() - t[1] < 0.3 and (io.Position - t[2]).Magnitude < 25 and C.click then
				task.spawn(C.click)
			end
		end
	end)

	function C.stop(stopReanimate)
		if not C.alive then
			return
		end
		C.alive = false
		if _G.LCFD_Stop == C.stop then
			_G.LCFD_Stop = nil
		end
		for _, c in ipairs(cons) do
			pcall(function()
				c:Disconnect()
			end)
		end
		for _, f in ipairs(cleanups) do
			pcall(f)
		end
		pcall(function()
			Effects:Destroy()
		end)
		if C.gui then
			pcall(function()
				C.gui:Destroy()
			end)
		end
		if stopReanimate == true or (stopReanimate ~= false and osclock() - lastLerp < 1) then
			pcall(FD.stopreanimate)
		end
	end
	_G.LCFD_Stop = C.stop

	local TAB = {"Gun", "Muzzle", "Head", "Torso", "Arms", "Legs"}
	local genv = (typeof(getgenv) == "function" and getgenv()) or _G
	local AL = {version = 1, title = "Addict", tabs = TAB, file = FILE, dirty = false, open = false, key = CFG.alignKeyText or string.upper(CFG.alignKey or "j")}
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
	function AL.alive()
		return C.alive
	end
	function AL.focus(s)
		if VAL[s] then
			cur = s
		end
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
		rebuild(s)
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
		rebuild(s)
		AL.dirty = true
		AL.later()
	end
	function AL.reset(s)
		AL.put(s, DEFAULT[s])
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
			if my == AL.tok and AL.dirty and C.alive and AL.save() then
				fire("saved")
			end
		end)
	end
	function AL.load()
		local ok, e = loadAlign()
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
	function AL.found()
		return C.foundText and C.foundText() or ""
	end
	function AL.hat(s)
		if C.alignHat then
			return C.alignHat(s)
		end
		return nil
	end
	AL.optList = {{"hatgun", "Hat Gun"}, {"roll", "Roll (upside down? tap this)", "button"}}
	AL.optsSaved = false
	function AL.opts()
		return {hatgun = not C.hatOn or C.hatOn("gun") == true}
	end
	function AL.setOpt(name, on)
		local v = VAL[cur]
		if name == "roll" and v then
			AL.set(cur, 4, v[4] + 180)
		elseif name == "hatgun" and C.toggleHat and C.hatOn then
			if (C.hatOn("gun") == true) ~= (on == true) then
				C.toggleHat("gun")
			end
		end
	end
	function C.toggleAlign()
		local h = hub()
		if h and type(h.Align) == "function" then
			pcall(h.Align)
		else
			C.notify(AL.title, "Open Atsuko Hub to line things up, the alignment lives there now", 5)
		end
	end
	function C.alignOpen()
		return AL.open
	end
	function C.alignTab()
		return cur
	end
	genv.AtsukoAlign = AL
	do
		local h = hub()
		if h and type(h.AlignReady) == "function" then
			pcall(h.AlignReady)
		end
	end

	local marker = C.newPart({Name = "AlignMarker", Shape = Enum.PartType.Ball, Size = V3(0.4, 0.4, 0.4), Color = C3(1, 0.25, 0.3), Transparency = 1})
	C.onStop(function()
		if AL.dirty then
			pcall(saveAlign)
			AL.dirty = false
		end
		AL.open = false
		if genv.AtsukoAlign == AL then
			genv.AtsukoAlign = nil
		end
		fire("stop")
		local h = hub()
		if h and type(h.AlignReady) == "function" then
			pcall(h.AlignReady)
		end
	end)

	function C.alignFrame()
		if AL.open then
			marker.Transparency = 0.15
			marker.CFrame = C.muzzleCF()
		elseif marker.Transparency < 1 then
			marker.Transparency = 1
		end
	end

	return C
end
local ADD = {
	Gun = "87566002870491",
	GunWords = {"sakura", "sniper"},
	Bullet = "4307568890",
	HatGun = true,
	ClientWeapons = "auto",
	Size = 1,
	Tall = "auto",
	NameTag = true,
	Visualizer = true,
	CamShake = true,
	Music = true,
	MusicVolume = 3,
	WalkSpeed = 16,
	AlignKey = "p",
	EmotesUrl = "https://raw.githubusercontent.com/atsukohakari/Studio-Dummy-V3/main/StudioDummyEmotes.lua",
}

if not game:IsLoaded() then
	game.Loaded:Wait()
end

local C = LCCore(FD, {gunIds = {}, alignFile = "AddictAlign.json", alignKey = ADD.AlignKey, maxEffects = 420})
if not C then
	return
end
local fd = C.fd

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local lp = Players.LocalPlayer
local CF, VT, C3 = CFrame.new, Vector3.new, Color3.new
local ANG = CFrame.Angles
local RAD, RND, SIN, COS = math.rad, math.random, math.sin, math.cos
local CLAMP = math.clamp
local IDENT = CFrame.identity
local RJ, Neck, RS, LS, RH, LH = C.RootJoint, C.Neck, C.RightShoulder, C.LeftShoulder, C.RightHip, C.LeftHip
local FX = C.Effects
local onPhone = UIS.TouchEnabled and not UIS.KeyboardEnabled
local WHITE, BLACK, RED = C3(1, 1, 1), C3(0, 0, 0), C3(1, 0, 0)

local function inst(class, parent, props)
	local o = Instance.new(class)
	if props then
		for k, v in pairs(props) do
			o[k] = v
		end
	end
	if parent then
		o.Parent = parent
	end
	return o
end
local function now()
	return C.time
end
local function A(x, y, z)
	return ANG(RAD(x), RAD(y), RAD(z))
end
local function note(text)
	C.notify("Addict", text, 4)
end
local function sine()
	return now() * 40
end
local function loudGrey()
	local l = C.music.IsPlaying and math.clamp((tonumber(C.music.PlaybackLoudness) or 0) / 500, 0, 1) or 0
	return C3(l, l, l)
end

local P = {}
P.ROOTC0 = A(-90, 0, 180)
P.NECKC0 = CF(0, 1, 0) * A(-90, 0, 180)
P.RSC0 = CF(-0.5, 0, 0) * A(0, 90, 0)
P.LSC0 = CF(0.5, 0, 0) * A(0, -90, 0)
P.RJC1 = CF(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0)
P.NKC1 = CF(0, -0.5, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0)
P.RSC1 = CF(-0.5, 0.5, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0)
P.LSC1 = CF(0.5, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0)
P.RHC1 = CF(0.5, 1, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0)
P.LHC1 = CF(-0.5, 1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0)
P.SPD = 0.5 / 3
P.HIDE = CF(0, -4000, 0)
P.UP = ADD.Tall == false and 0 or 2.55
local function up(z)
	return P.ROOTC0 * CF(0, 0, P.UP + (z or 0))
end

local KEYS = {"RJ", "NK", "RS", "LS", "RH", "LH", "RJ1", "NK1", "RH1", "LH1"}
local J = {
	RJ = P.ROOTC0, NK = P.NECKC0, RS = CF(1.5, 0.5, 0) * P.RSC0, LS = CF(-1.5, 0.5, 0) * P.LSC0, RH = CF(1, -1, 0) * A(0, 90, 0), LH = CF(-1, -1, 0) * A(0, -90, 0),
	RJ1 = P.RJC1, NK1 = P.NKC1, RH1 = P.RHC1, LH1 = P.LHC1,
}
local goal, base = {}, {}
local function T(cf, a)
	return {cf, a}
end
local function set(g)
	for k, v in pairs(g) do
		goal[k] = v
	end
end
local function hold(g, n)
	set(g)
	C.swait(n)
end

local S = {attack = false, rooted = false, sitting = false, padHeld = {}, state = "idle"}
local MUS = {}
local EM = {k = 0}
local SZ = {goal = ADD.Size or 1, k = 1, file = "AddictSettings.json"}
pcall(function()
	if isfile and isfile(SZ.file) then
		local t = HttpService:JSONDecode(readfile(SZ.file))
		if type(t) == "table" and type(t.size) == "number" and t.size == t.size then
			SZ.goal = CLAMP(t.size, 0.3, 10)
		end
	end
end)
SZ.k = SZ.goal
local function sz(cf)
	local k = SZ.k
	return k == 1 and cf or (CF(cf.Position * k) * cf.Rotation)
end
local function setRootCF(cf)
	fd.setCfr(cf)
	fd.cframes[C.Root] = cf
end
local function AimPoint()
	if onPhone then
		local cam = workspace.CurrentCamera
		if cam then
			local vp = cam.ViewportSize
			local r = cam:ViewportPointToRay(vp.X / 2, vp.Y / 2)
			local _, pos = C.ray(r.Origin, r.Direction, 1000)
			return pos
		end
	end
	return C.mouseHit().Position
end
local aimOn, aimRot = false, nil
local function stepAim(dt)
	if not aimOn then
		aimRot = nil
		return
	end
	local cf = C.rootCF()
	local p = AimPoint()
	local d = VT(p.X - cf.X, 0, p.Z - cf.Z)
	aimRot = aimRot or cf.Rotation
	if d.Magnitude > 1 then
		aimRot = aimRot:Lerp(CFrame.lookAt(Vector3.zero, d), 1 - math.exp(-16 * dt))
	end
	setRootCF(aimRot + cf.Position)
end

local function idOf(s)
	return type(s) == "string" and (s:match("%d+") or "") or ""
end
local function squash(s)
	return (string.lower(tostring(s or "")):gsub("[^%w]", ""))
end
local function accName(e)
	local ok, n = pcall(function()
		return rawget(e, "p").Parent.Name
	end)
	return ok and type(n) == "string" and n or ""
end
local function hubJob(slot, e)
	local A = ((typeof(getgenv) == "function" and getgenv()) or _G).AtsukoAlignment
	if type(A) ~= "table" or type(A.match) ~= "function" or type(e) ~= "table" then
		return nil
	end
	local ok, row = pcall(A.match, "Addict", slot, {mesh = idOf(rawget(e, "m")), tex = idOf(rawget(e, "t")), name = accName(e)})
	return ok and type(row) == "table" and row.src == "user" and row or nil
end
local function hubHold(e)
	local A = ((typeof(getgenv) == "function" and getgenv()) or _G).AtsukoAlignment
	if type(A) ~= "table" or type(A.hold) ~= "function" or type(e) ~= "table" then
		return nil
	end
	local ok, h = pcall(A.hold, {mesh = rawget(e, "m"), tex = rawget(e, "t")})
	return ok and type(h) == "table" and h or nil
end
local function hubJoin(e)
	local A = ((typeof(getgenv) == "function" and getgenv()) or _G).AtsukoAlignment
	if type(A) ~= "table" or type(A.join) ~= "function" or type(e) ~= "table" then
		return nil
	end
	local ok, undo = pcall(A.join, fd, e)
	return ok and type(undo) == "function" and undo or nil
end
local function hatOk(h)
	return h.e ~= nil and h.j ~= nil and fd.cframes[h.e] ~= nil
end
local function restore(h)
	local j, home = h.j, h.home
	h.glued = false
	if h.unjoin then
		h.unjoin()
	end
	h.unjoin, h.joinFor = nil, nil
	if j and home then
		pcall(function()
			j.Part1, j.C0, j.C1 = home[1], home[2], home[3]
		end)
	end
end
local function sizeOf(e)
	local s = VT(1, 1, 1)
	pcall(function()
		s = rawget(e, "p").Size
	end)
	return s
end
local RIG = {
	{key = "head", part = C.Head, mesh = "17375312569", cf = CF(0, 2.75, 0) * ANG(0, 3.15, 0), tab = 3},
	{key = "torso", part = C.Torso, mesh = "17269636541", cf = IDENT, tab = 4},
	{key = "rarm", part = C.RightArm, mesh = "17269487439", cf = CF(1.35, -0.005, 0) * ANG(0, 0, 1.57), tab = 5},
	{key = "larm", part = C.LeftArm, mesh = "17269487439", cf = CF(-1.35, -0.005, 0) * ANG(0, 0, 1.57), tab = 5, left = true},
	{key = "rleg", part = C.RightLeg, mesh = "17269487439", cf = CF(0.45, -1.85, 0) * ANG(0, -1.57, -1.57), tab = 6},
	{key = "lleg", part = C.LeftLeg, mesh = "17269487439", cf = CF(-0.45, -1.85, 0) * ANG(0, -1.57, -1.57), tab = 6, left = true},
	{key = "rpg", part = C.RightArm, mesh = "17386451149", cf = CF(1.15, -2.15, -1.15) * ANG(0, 1.57, -1.57)},
	{key = "jaw", part = C.RightArm, mesh = "17386444997", cf = CF(1.15, -7.35, -1.38) * ANG(0, 1.57, -1.57)},
}
local ROCK = {key = "rock", mesh = idOf(tostring(ADD.Bullet or "")), nextScan = 0}
local MESHHATS = table.clone(RIG)
if ROCK.mesh ~= "" then
	MESHHATS[#MESHHATS + 1] = ROCK
end
local GUN = {key = "gun", id = tostring(ADD.Gun or ""), words = ADD.GunWords or {}, nextScan = 0}
do
	local n = tonumber(GUN.id)
	if n then
		task.spawn(function()
			pcall(function()
				local acc = game:GetObjects("rbxassetid://" .. n)[1]
				local hd = acc and (acc:FindFirstChild("Handle") or acc:FindFirstChildWhichIsA("BasePart", true))
				if hd then
					if hd:IsA("MeshPart") then
						GUN.cmesh = idOf(hd.MeshId)
					else
						local sm = hd:FindFirstChildOfClass("SpecialMesh")
						if sm then
							GUN.cmesh = idOf(sm.MeshId)
						end
					end
				end
				if acc and (acc:IsA("Accoutrement") or acc:IsA("Accessory")) then
					GUN.name = squash(acc.Name)
				end
			end)
			pcall(function()
				local pi = game:GetService("MarketplaceService"):GetProductInfo(n, Enum.InfoType.Asset)
				if type(pi) == "table" and type(pi.Name) == "string" then
					GUN.name2 = squash(pi.Name)
				end
			end)
			GUN.nextScan = 0
		end)
	end
end
local function gunRank(e)
	if hubJob("gun", e) then
		return 1
	end
	local m, t = idOf(rawget(e, "m")), idOf(rawget(e, "t"))
	if GUN.id ~= "" and (m == GUN.id or t == GUN.id) then
		return 1
	end
	if GUN.cmesh and GUN.cmesh ~= "" and m == GUN.cmesh then
		return 1
	end
	local n = squash(accName(e))
	if n == "" then
		return nil
	end
	if (GUN.name and n == GUN.name) or (GUN.name2 and n == GUN.name2) then
		return 2
	end
	local count = 0
	for _, w in ipairs(GUN.words) do
		local s = squash(w)
		if s ~= "" then
			if not n:find(s, 1, true) then
				return nil
			end
			count += 1
		end
	end
	return count > 0 and 3 or nil
end
local function sortedAxes(s)
	local ax = {VT(1, 0, 0), VT(0, 1, 0), VT(0, 0, 1)}
	local sz3 = {s.X, s.Y, s.Z}
	local idx = {1, 2, 3}
	table.sort(idx, function(a, b)
		return sz3[a] > sz3[b]
	end)
	return ax[idx[1]], ax[idx[2]], ax[idx[3]], sz3[idx[1]], sz3[idx[2]], sz3[idx[3]]
end
local GRIP = CFrame.fromMatrix(VT(1.15, -2.15, 0), VT(0, -1, 0), VT(0, 0, -1))
local GRIPROT = GRIP.Rotation
local function fitGun(h)
	local barrel, up, _, L, Hh = sortedAxes(sizeOf(h.e))
	local rest = h.home[3] * h.home[2]:Inverse()
	local waist = rest.Position.Y < -0.4
	local b = rest:VectorToWorldSpace(barrel)
	if (waist and b.Y > 0) or (not waist and b.Y < 0) then
		barrel = -barrel
	end
	local w = rest:VectorToWorldSpace(up)
	if waist then
		if w.Z > 0 then
			up = -up
		end
	elseif w.Y + 0.5 * w.Z < 0 then
		up = -up
	end
	local m = CFrame.fromMatrix(Vector3.zero, barrel, up, barrel:Cross(up))
	h.cf = CF(0.26 * L, 0.33 * Hh, 0) * m:Inverse()
	h.fwd = barrel
	h.tip = barrel * (L / 2)
	local known = hubHold(h.e)
	if known then
		h.cf, h.fwd, h.tip = known.fit, known.hatFwd, known.hatTip
	end
end
local function scanHats()
	local t = os.clock()
	local claimed = {}
	for _, h in ipairs(MESHHATS) do
		if hatOk(h) then
			claimed[h.e] = true
		end
	end
	if hatOk(GUN) then
		claimed[GUN.e] = true
	end
	local function take(h, e)
		local j = fd.getPartJoint(e)
		h.e, h.j, h.home = e, j, {j.Part1, j.C0, j.C1}
		claimed[e] = true
	end
	for _, h in ipairs(MESHHATS) do
		if not hatOk(h) and t >= (h.nextScan or 0) then
			h.nextScan = t + 0.5
			if h.e then
				restore(h)
			end
			h.e, h.j, h.home = nil, nil, nil
			for e in pairs(fd.cframes) do
				if type(e) == "table" and rawget(e, "m") ~= nil and rawget(e, "p") and not claimed[e] and (idOf(rawget(e, "m")) == h.mesh or (h == ROCK and hubJob("bullet", e) ~= nil)) and fd.getPartJoint(e) then
					take(h, e)
					break
				end
			end
		end
	end
	if not hatOk(GUN) and t >= GUN.nextScan then
		GUN.nextScan = t + 0.5
		if GUN.e then
			restore(GUN)
		end
		GUN.e, GUN.j, GUN.home, GUN.cf = nil, nil, nil, nil
		local best, bestRank = nil, math.huge
		for e in pairs(fd.cframes) do
			if type(e) == "table" and rawget(e, "m") ~= nil and rawget(e, "p") and not claimed[e] then
				local r = gunRank(e)
				if r and r < bestRank and fd.getPartJoint(e) then
					best, bestRank = e, r
				end
			end
		end
		if best then
			take(GUN, best)
			pcall(fitGun, GUN)
		end
	end
end
C.onStop(function()
	for _, h in ipairs(MESHHATS) do
		restore(h)
	end
	restore(GUN)
end)
local useHat = {gun = ADD.HatGun ~= false}
C.hatOn = function(k)
	return useHat[k]
end
C.toggleHat = function(k)
	if useHat[k] == nil then
		return
	end
	useHat[k] = not useHat[k]
	note("hat gun " .. (useHat[k] and "on" or "off, the og weapons show"))
end
local function gunHat()
	return useHat.gun and hatOk(GUN) and GUN.cf and GUN or nil
end
local function glue(h, part, rel)
	local j = h.j
	if h.key == "gun" and h.joinFor ~= h.e then
		h.joinFor = h.e
		h.unjoin = hubJoin(h.e)
	end
	h.glued = true
	j.Part1 = part
	j.C0 = IDENT
	j.C1 = rel
end
C.alignHat = function(s)
	local g = (s == 1 or s == 2) and gunHat() or nil
	local e = g and g.e or nil
	if type(e) ~= "table" then
		return nil
	end
	local m, t = rawget(e, "m"), rawget(e, "t")
	local id = (type(m) == "string" and string.match(m, "(%d+)%D*$")) or (type(t) == "string" and string.match(t, "(%d+)%D*$")) or nil
	if not id then
		return nil
	end
	local name = nil
	pcall(function()
		name = rawget(e, "p").Parent.Name
	end)
	return id, id, type(name) == "string" and name or nil
end
C.foundText = function()
	local n = 0
	for _, h in ipairs(RIG) do
		if hatOk(h) then
			n += 1
		end
	end
	local g = gunHat()
	local gun = not useHat.gun and "off" or (g and (accName(g.e) ~= "" and accName(g.e) or "yes") or "no")
	return "Void rig: " .. n .. " of " .. #RIG .. " | Gun: " .. gun .. " | Bullet: " .. (hatOk(ROCK) and "golem rock" or "no") .. " | Size: " .. SZ.goal
end
local function clientOn()
	local c = ADD.ClientWeapons
	return c == true or (c == "auto" and gunHat() == nil)
end
local function mirror(cf)
	local x, y, z, a, b, c, d, e, f, g, h, i = cf:GetComponents()
	return CF(-x, y, z, a, -b, -c, -d, e, f, -g, h, i)
end

local OGW = {models = {}, holes = {}, shown = {}, order = {"AK", "Robotarm", "UltraGun", "Pistol", "Katana"}}
task.spawn(function()
	local ok, s = pcall(function()
		return game:GetObjects("rbxassetid://9504104358")[1]
	end)
	if not ok or not s or not C.alive then
		return
	end
	for _, name in ipairs(OGW.order) do
		local m = s:FindFirstChild(name)
		local ra = m and m:FindFirstChild("RightArm")
		local ref = ra and ra:FindFirstChild("REF")
		if ref and ref:IsA("BasePart") then
			local inv = ref.CFrame:Inverse()
			local list = {}
			for _, d in ipairs(m:GetDescendants()) do
				if d:IsA("BasePart") then
					local off = inv * d.CFrame
					if d.Name == "Hole" and d.Parent and d.Parent.Name == "Weapon" then
						OGW.holes[name] = off
					end
					if d.Transparency < 1 then
						local c = d:Clone()
						for _, x in ipairs(c:GetDescendants()) do
							if x:IsA("JointInstance") or x:IsA("WeldConstraint") or x:IsA("BasePart") or x:IsA("LuaSourceContainer") or x:IsA("Sound") then
								x:Destroy()
							end
						end
						c.Anchored, c.CanCollide, c.CanQuery, c.CanTouch, c.CastShadow = true, false, false, false, false
						c.CFrame = P.HIDE
						c.Parent = FX
						list[#list + 1] = {p = c, off = off, tr = c.Transparency}
					end
				end
			end
			OGW.models[name] = list
		end
	end
end)
local tag, tagText
if ADD.NameTag ~= false then
	tag = inst("BillboardGui", nil, {Name = "NameBillboard", AlwaysOnTop = true, Size = UDim2.new(7, 35, 3, 15), StudsOffset = VT(0, 2, 0), MaxDistance = 10000, Adornee = C.anchor})
	tagText = inst("TextLabel", tag, {
		BackgroundTransparency = 1, TextScaled = false, BorderSizePixel = 0, Text = "A D D I C T", Font = Enum.Font.Antique, TextSize = 30,
		TextStrokeTransparency = 0, Size = UDim2.new(1, 0, 0.5, 0), TextColor3 = BLACK, TextStrokeColor3 = BLACK,
	})
	tag.Parent = FX
end

local W = {}
local function holeCF(kind)
	local h = gunHat()
	if h then
		local hc = W.gunBase * GRIPROT * h.cf
		local pos = hc * h.tip
		return CFrame.lookAt(pos, pos + hc:VectorToWorldSpace(h.fwd)) * A(-90, 0, 0) * C.alignOff(2)
	end
	local off = OGW.holes[kind == "pistol" and "Pistol" or "AK"] or OGW.holes.AK
	if off then
		return W.rarm * sz(off) * C.alignOff(2)
	end
	return W.rarm * sz(CF(1.15, -4.2, -1.15)) * A(180, 0, 0) * C.alignOff(2)
end
local function rigCF(h)
	local o = h.tab and C.alignOff(h.tab) or IDENT
	if h.left then
		o = mirror(o)
	end
	local cf = sz(h.cf)
	return CF(cf.Position + o.Position) * o.Rotation * cf.Rotation
end
C.muzzleCF = function()
	if not W.rarm then
		return CF()
	end
	local tab = C.alignTab and C.alignTab() or 1
	for _, h in ipairs(RIG) do
		if h.tab == tab and not h.left then
			return (W.parts[h.part] or W.root) * rigCF(h)
		end
	end
	return holeCF("ak")
end
C.gripCF = function()
	return W.rarm or CF()
end

local BS = {Vector3.zero, Vector3.zero, -10}
local function setBullet(hole, target)
	local d = target - hole
	BS[1] = hole
	BS[2] = d.Magnitude > 256 and hole + d.Unit * 256 or target
	BS[3] = now()
end
local function rockCF(root)
	if BS[3] < now() - 0.5 then
		return root * CF(0, -12, 0)
	end
	local at = (now() // 0.05) % 2 == 0 and BS[1] or BS[2]
	return ANG(RND() * math.pi * 2, RND() * math.pi * 2, RND() * math.pi * 2) + at
end

local SH = {t = 0, n = 0, mag = 0, last = os.clock()}
local function shake(ticks, mag)
	if ADD.CamShake == false then
		return
	end
	local left = SH.n > 0 and SH.mag * (1 - SH.t / SH.n) or 0
	if mag >= left then
		SH.t, SH.n, SH.mag = 0, ticks, mag
	end
end
pcall(fd.setCamOverride, function(cam)
	local t = os.clock()
	local dt = math.min(t - SH.last, 0.1)
	SH.last = t
	if SH.n <= 0 or SH.t >= SH.n then
		return cam
	end
	SH.t += dt * 60
	local m = SH.mag * math.max(1 - SH.t / SH.n, 0)
	local function r()
		return (RND() * 2 - 1) * m
	end
	return cam * CF(r(), r() * 0.25, r())
end)
C.onStop(function()
	pcall(fd.setCamOverride, nil)
end)

local M = {}
local function heldKey(k)
	return C.keysDown[k] or S.padHeld[k]
end
local function legsIdle(a)
	return T(function()
		return CF(1, -1 - 0.05 * COS(sine() / 12), -0.01) * A(0, 75, 0) * A(-8, 0, 0)
	end, a), T(function()
		return CF(-1, -1 - 0.05 * COS(sine() / 12), -0.01) * A(0, -50, 0) * A(-8, 0, 0)
	end, a)
end
local function waveFX(hole, pos, color, sounds)
	C.Effect({Time = 25, EffectType = "Wave", Size = VT(0.3, 0, 0.3), Size2 = VT(1, 1.5, 1), Transparency = 0, Transparency2 = 1, CFrame = hole, MoveToPos = (hole * CF(0, 0.5, 0)).Position, RotationY = -15, Material = "Neon", Color = color, SoundID = sounds[1], SoundPitch = RND(8, 11) / 10, SoundVolume = 1})
	C.Effect({Time = 25, EffectType = "Wave", Size = VT(0.3, 0, 0.3), Size2 = VT(2, 0.5, 2), Transparency = 0, Transparency2 = 1, CFrame = hole, RotationY = 5, Material = "Neon", Color = color, SoundID = sounds[2], SoundPitch = RND(8, 11) / 10, SoundVolume = 8})
	local back = CFrame.lookAt(pos, hole.Position) * A(-90, 0, 0)
	C.Effect({Time = 25, EffectType = "Wave", Size = VT(0.3, 0, 0.3), Size2 = VT(2, 0.5, 2), Transparency = 0, Transparency2 = 1, CFrame = back, RotationY = -5, Material = "Neon", Color = color, SoundID = sounds[3], SoundPitch = RND(8, 11) / 10, SoundVolume = 1})
	C.Effect({Time = 25, EffectType = "Wave", Size = VT(0.3, 0, 0.3), Size2 = VT(2, 0.5, 2), Transparency = 0, Transparency2 = 1, CFrame = back, RotationY = 5, Material = "Neon", Color = color, SoundID = sounds[3], SoundPitch = RND(8, 11) / 10, SoundVolume = 1})
end
local function fire(kind)
	local hole = holeCF(kind)
	local from = hole.Position
	local _, pos = C.ray(from, AimPoint() - from, 1000)
	C.beam(from, pos, 0.25, 5, RED, 0.5, 1)
	setBullet(from, pos)
	if kind == "pistol" then
		waveFX(hole, pos, RED, {nil, 904440937, nil})
	else
		waveFX(hole, pos, RED, {541909814, 1905402432, 541909814})
	end
	shake(6, 0.08)
end
local function akRaise(lsZ)
	local a = P.SPD
	return {
		RJ = T(up(), a), NK = T(P.NECKC0, a), RS = T(CF(1.5, 0.5, 0) * A(90, 90, 0) * P.RSC0, a),
		LS = T(CF(0.2, 0.8, lsZ) * A(90, 0, 50) * P.LSC0, a), RH = T(CF(1, -1, 0) * A(0, 90, 0), a), LH = T(CF(-1, -1, 0) * A(0, -90, 0), a),
	}
end
local function akAim(kick)
	local a = P.SPD
	local rh, lh = legsIdle(0.15 / 3)
	return {
		RJ = T(up() * A(0, 0, 45), a), NK = T(P.NECKC0 * A(0, 0, -45), a),
		RS = T(kick and CF(0.5, 0.5, 2) * A(110, 0, 45) * P.RSC0 or CF(1.15, 0.5, 0) * A(90, 0, 45) * P.RSC0, a),
		LS = T(CF(-1.5, 0.5, 0) * A(0, 20, -20) * P.LSC0, a), RH = rh, LH = lh,
	}
end
function M.shot()
	aimOn = true
	hold(akRaise(-2.5), 13)
	C.sound(1905403158, 10, 1.5)
	hold(akRaise(-1.5), 16)
	hold(akRaise(-2.5), 16)
	repeat
		hold(akAim(false), 3)
		fire("ak")
		set(akAim(true))
		for _ = 1, 4 do
			if RND(1, 30) == 10 then
				J.NK = J.NK:Lerp(P.NECKC0 * A(RND(-25, 25) - 4 * COS(sine() / 12), RND(-25, 25), -45), 0.5)
			end
			C.swait(1)
		end
	until not heldKey("z") or not C.alive
end
function M.pistol()
	aimOn = true
	local a = P.SPD
	local g = {
		RJ = T(up() * A(0, 0, 90), a), NK = T(P.NECKC0 * A(0, 0, -90), a), RS = T(CF(1.5, 0.5, 0) * A(90, 0, 90) * P.RSC0, a),
		LS = T(CF(-1.5, 0.6, 0) * A(-45, 0, 45) * P.LSC0, a), RH = T(CF(1, -1, 0) * A(0, 90, 0) * A(-8, 0, 0), a), LH = T(CF(-1, -1, 0) * A(0, -90, 0) * A(-8, 0, 0), a),
	}
	hold(g, 13)
	repeat
		g.NK = T(P.NECKC0 * A(0, 0, -90), a)
		g.RS = T(CF(1.5, 0.5, 0) * A(90, 0, 90) * P.RSC0, a)
		hold(g, 7)
		fire("pistol")
		g.NK = T(P.NECKC0 * A(0, 0, -90), 0.25 / 3)
		g.RS = T(CF(1.5, 0.5, 0) * A(90, 15, 90) * P.RSC0, a)
		hold(g, 10)
	until not heldKey("x") or not C.alive
end
function M.slash()
	S.rooted = true
	aimOn = true
	local root = W.root
	for _ = 1, 4 do
		C.Effect({EffectType = "Sphere", Size = Vector3.zero, Size2 = VT(30, 30, 30), Transparency = 0, Transparency2 = 1, Time = 15, CFrame = root, Material = "Neon", Color = BLACK})
	end
	local stop = false
	task.spawn(function()
		while not stop and C.alive do
			local col = loudGrey()
			for _ = 1, 5 do
				C.Effect({Time = 15, EffectType = "Crystal", Size = VT(1, 5, 1), Size2 = VT(1, 25, 1), Transparency = 0, Transparency2 = 1, CFrame = W.rarm * A(RND(0, 360), RND(0, 360), RND(0, 360)), Material = "Glass", Color = col})
			end
			C.swait(1)
		end
	end)
	local a = P.SPD
	set({
		RJ = T(up(-0.1) * A(0, 0, -75), a), NK = T(P.NECKC0 * A(0, 0, 75), a),
		RS = T(CF(1.5, 0.5, 0) * A(90, -45, 45) * P.RSC0, a), LS = T(CF(-0.2, 0.5, -1) * A(0, 0, 90) * P.LSC0, a),
		RH = T(CF(1, -0.5, -0.5) * A(0, 90, 0) * A(-8, 0, 0), a), LH = T(CF(-1, -1, -0.01) * A(-45, -90, 0) * A(-8, 0, 0), a),
	})
	for _ = 1, 30 do
		C.Effect({EffectType = "Ring3", MeshId = "3270017", Size = Vector3.zero, Size2 = VT(5, 5, 0), Transparency = 0.5, Transparency2 = 1, Time = 5, CFrame = CF(W.root.Position - VT(0, 3 * SZ.k, 0)) * A(90, 0, 0), Material = "Neon", Color = BLACK})
		C.swait(1)
	end
	local legs = {RH = T(CF(1, -1, -0.01) * A(0, 90, 0) * A(-8, 0, 0), 0.4), LH = T(CF(-1, -1, -0.01) * A(0, -90, 0) * A(-8, 0, 0), 0.4)}
	hold({RJ = T(up() * A(0, 0, 75), 0.4), NK = T(P.NECKC0 * A(0, 0, -75), 0.4), RS = T(CF(1.5, 0.5, 0) * A(90, -45, 0) * P.RSC0, 0.4), LS = T(CF(-1.5, 0.5, -1) * A(90, 0, 75) * P.LSC0, 0.4), RH = legs.RH, LH = legs.LH}, 4)
	C.sound("rbxasset://sounds/swordlunge.wav", 10, 0.6)
	C.sound(62339698, 10, 0.4)
	root = W.root
	local col = loudGrey()
	C.Effect({Time = 25, EffectType = "Block", Size = VT(5, 5, 5), Size2 = VT(100, 100, 100), Transparency = 0, Transparency2 = 1, CFrame = root * A(RND(-5, 5), RND(-360, 360), RND(-5, 5)), Material = "Neon", Color = col, SoundID = 3923230963, SoundPitch = 1, SoundVolume = 10})
	for _ = 1, 3 do
		C.Effect({Time = 25, EffectType = "Slash", Size = Vector3.zero, Size2 = VT(1, 0, 1), Transparency = 0, Transparency2 = 1, CFrame = root * CF(0, -4 * SZ.k, 0) * A(RND(-5, 5), RND(-360, 360), RND(-5, 5)), RotationY = RND(-1, 1), Material = "Neon", Color = col})
	end
	stop = true
	shake(30, 1.6)
	hold({RJ = T(up() * A(0, 0, 75), 0.5), NK = T(P.NECKC0 * A(0, 0, -75), 0.5), RS = T(CF(1, 0.5, -1) * A(90, 0, -75) * P.RSC0, 0.5), LS = T(CF(-1.5, 0.5, -1) * A(90, 0, 75) * P.LSC0, 0.5), RH = legs.RH, LH = legs.LH}, 30)
end
function M.sit()
	S.rooted = true
	S.sitting = true
	local a = P.SPD
	set({
		RJ = T(P.ROOTC0 * CF(0, 0, -1.70) * A(-40, 0, 0), a), NK = T(P.NECKC0, a),
		RS = T(CF(1.5, 0.3, 0.10) * A(-40, 0, 0) * P.RSC0, a), LS = T(CF(-1.5, 0.3, 0.10) * A(-40, 0, 0) * P.LSC0, 0.15 / 3),
		RH = T(CF(1, -1, 0) * A(45, 90, 0) * A(-8, 0, 0), a), LH = T(CF(-1, -1, 0) * A(45, -90, 0) * A(-8, 0, 0), a),
	})
	repeat
		C.swait(1)
	until not S.sitting or not C.alive
end

local MOVES = {z = M.shot, x = M.pistol, c = M.slash}
local function runMove(f)
	if S.attack or not C.alive then
		return
	end
	S.attack = true
	local ok, e = pcall(f)
	if not ok then
		C.err(e)
	end
	if C.alive then
		table.clear(goal)
		aimOn = false
		S.rooted = false
		S.sitting = false
		S.attack = false
	end
end

do
	local EMOTE_PARTS = {Torso = C.Torso, Head = C.Head, ["Right Arm"] = C.RightArm, ["Left Arm"] = C.LeftArm, ["Right Leg"] = C.RightLeg, ["Left Leg"] = C.LeftLeg}
	local host = {
		note = note,
		accent = RED,
		parent = FX,
		rootCF = function()
			return C.rootCF()
		end,
		partCF = function(name)
			local p = EMOTE_PARTS[name]
			return p and C.cf(p)
		end,
		moveRoot = function(cf)
			if not C.ray(cf.Position + VT(0, 1, 0), VT(0, -1, 0), 40 * math.max(SZ.k, 1)) then
				return false
			end
			setRootCF(cf)
			return true
		end,
		ignore = function(o, on)
			local list = type(fd.characters) == "table" and fd.characters
			if not (list and fd.refreshrayfilter) then
				return
			end
			EM.ignores = EM.ignores or {}
			if on and typeof(o) == "Instance" then
				local key = {}
				EM.ignores[key] = o
				list[key] = o
			else
				for key in pairs(EM.ignores) do
					list[key] = nil
				end
				table.clear(EM.ignores)
			end
			pcall(fd.refreshrayfilter)
		end,
		canEmote = function()
			if S.attack then
				return false, "not while you're attacking"
			end
			return true
		end,
		onEmote = function(on)
			EM.on = on
		end,
	}
	pcall(function()
		host.gui = C.guiParent()
	end)
	local function ver(text)
		return tonumber(type(text) == "string" and text:match("local E = {version = (%d+)") or "") or 0
	end
	local function getLib(quiet)
		local lib = rawget(_G, "StudioDummyEmotes")
		pcall(function()
			if type(lib) ~= "table" and getgenv then
				lib = getgenv().StudioDummyEmotes
			end
		end)
		if type(lib) ~= "table" or type(lib.attach) ~= "function" then
			lib = nil
		end
		local have = lib and tonumber(lib.version) or 0
		local src
		pcall(function()
			if isfile("StudioDummyEmotes.lua") then
				src = readfile("StudioDummyEmotes.lua")
			end
		end)
		if type(ADD.EmotesUrl) == "string" and ADD.EmotesUrl ~= "" and not EM.checked then
			if not (src or lib) and not quiet then
				note("getting the emotes...")
			end
			local ok, web = pcall(function()
				return game:HttpGet(ADD.EmotesUrl)
			end)
			if ok and type(web) == "string" and web:find("StudioDummyEmotes", 1, true) and ver(web) > 0 then
				EM.checked = true
				if ver(web) > ver(src) then
					src = web
					pcall(function()
						writefile("StudioDummyEmotes.lua", web)
					end)
				end
			end
		end
		if src and ver(src) > have and loadstring then
			local fn = loadstring(src, "=StudioDummyEmotes")
			if fn then
				local ok, r = pcall(fn)
				if ok and type(r) == "table" and type(r.attach) == "function" then
					if lib and lib ~= r then
						pcall(lib.detach)
					end
					lib = r
				end
			end
		end
		return lib
	end
	function EM.get(quiet)
		if EM.lib then
			return EM.lib
		end
		if EM.busy then
			if not quiet then
				EM.openAfter = true
				note("getting the emotes...")
			end
			return nil
		end
		EM.busy = true
		local ok, lib = pcall(getLib, quiet)
		EM.busy = false
		if not C.alive then
			return nil
		end
		if not ok or type(lib) ~= "table" then
			if not quiet or EM.openAfter then
				note("couldn't get the emotes. put StudioDummyEmotes.lua in your executor's workspace folder (or run it), then try again")
			end
			EM.openAfter = false
			return nil
		end
		EM.lib = lib
		pcall(lib.attach, host)
		if EM.openAfter then
			EM.openAfter = false
			pcall(lib.toggle, true)
		end
		return lib
	end
	C.onStop(function()
		local lib = EM.lib
		EM.lib, EM.on = nil, false
		if lib then
			pcall(lib.detach)
		end
	end)
	function EM.over(pos, full)
		local lib = EM.lib
		if not (lib and lib.isOver and pos) then
			return false
		end
		local ok, r = pcall(lib.isOver, pos, full)
		return ok and r == true
	end
	pcall(function()
		if type(fd.setInputBlocker) == "function" then
			fd.setInputBlocker(function(io)
				return EM.over(io.Position)
			end)
		end
	end)
	function EM.stop()
		if EM.lib then
			local ok, r = pcall(EM.lib.stop)
			return ok and r
		end
		return false
	end
	function EM.step(dt)
		local lib = EM.lib
		local pose = nil
		if lib and lib.step then
			local ok, p = pcall(lib.step, dt)
			if ok then
				pose = p
			end
		end
		if EM.on and not pose then
			EM.on = false
		end
		EM.k = CLAMP(EM.k + (pose and dt or -dt) / 0.3, 0, 1)
		local want = pose ~= nil
		if lib and not want then
			local ok, a, b = pcall(lib.playing)
			want = ok and (a ~= nil or b ~= nil)
		end
		EM.music = want
		return pose
	end
	task.delay(2, function()
		if C.alive and not EM.lib then
			EM.get(true)
		end
	end)
end
local function emoteCmd(rawArg, open)
	local lib = EM.get()
	if not lib then
		return
	end
	local a = string.lower(rawArg or "")
	if open or a == "" or a == "list" or a == "open" then
		lib.toggle(true)
	elseif a == "stop" or a == "off" then
		note(lib.stop() and "dance stopped" or "not dancing")
	elseif a == "close" or a == "hide" then
		lib.toggle(false)
	elseif a == "random" then
		if lib.state ~= "ready" then
			note("still getting the dances ready, try again in a sec")
		else
			lib.random()
		end
	elseif a:match("^volume") then
		local n = tonumber(a:match("^volume%s*(%-?[%d%.]+)$") or "")
		if n and n == n then
			lib.setVolume(n)
			lib.save()
			note(string.format("dance volume: %g", lib.volume))
		else
			note(string.format("dance volume is %g. -emote volume (number), 1 is normal", lib.volume))
		end
	elseif lib.state ~= "ready" then
		note("still getting the dances ready, try again in a sec")
	else
		local m = lib.find(rawArg)
		if m then
			lib.play(m)
			note("dancing: " .. m.Name)
		else
			note("no dance called " .. rawArg .. ". Shift + Right Ctrl shows them all")
		end
	end
end

C.keyDown = function(k)
	if k == "rightcontrol" and (UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.RightShift)) or k == "emotes" then
		local lib = EM.get()
		if lib then
			lib.toggle()
		end
		return
	end
	if k == "t" then
		if S.sitting then
			S.sitting = false
		elseif not S.attack then
			EM.stop()
			runMove(M.sit)
		end
		return
	end
	local f = MOVES[k]
	if f and not S.attack then
		EM.stop()
		runMove(f)
	end
end

local function sizeCmd(arg)
	local a = string.lower(arg or ""):gsub("x$", "")
	if a == "" then
		note(string.format("size is %g. -size (number), like -size 2 or -size 0.5. -size 1 is the og size", SZ.goal))
		return
	end
	local n = (a == "normal" or a == "reset") and 1 or tonumber(a)
	if not n or n ~= n then
		note("-size (number), like -size 2 or -size 0.5")
		return
	end
	SZ.goal = CLAMP(n, 0.3, 10)
	pcall(function()
		writefile(SZ.file, HttpService:JSONEncode({size = SZ.goal}))
	end)
	note(string.format("size: %g", SZ.goal))
end

local function visualizer()
	local m = C.music
	local L = m.IsPlaying and tonumber(m.PlaybackLoudness) or 0
	if L < 1 or not MUS.color3 then
		return
	end
	local root = C.rootCF()
	local hit, g = C.ray(root.Position, VT(0, -1, 0), 300)
	if not hit then
		return
	end
	local k = L / 75 * (MUS.size or 1)
	local col = BLACK:Lerp(MUS.color3(), CLAMP(0.2 + L / 140, 0, 1))
	local mat = MUS.neon == false and "SmoothPlastic" or "Neon"
	local floor = CF(g + VT(0, 0.05, 0)) * root.Rotation * ANG(0, RAD(L / 666), 0)
	C.Effect({EffectType = "Sphere", Time = 12, Size = VT(10 * k, 0, k), Size2 = VT(k, 0.5, 7 * k), Transparency = 0, Transparency2 = 1, CFrame = floor, Color = col, Material = mat})
	C.Effect({EffectType = "Sphere", Time = 12, Size = VT(k, 0, 10 * k), Size2 = VT(7 * k, 0.69, k), Transparency = 0, Transparency2 = 1, CFrame = floor, Color = col, Material = mat})
	C.Effect({EffectType = "Sphere", Time = 12, Size = VT(4 * k, 0, 4 * k), Size2 = VT(4 * k, 0.5, 4 * k), Transparency = 0, Transparency2 = 1, CFrame = floor, Color = col, Material = mat})
end
local padTick = 0
C.tick = function()
	padTick += 1
	if padTick % 2 == 1 and MUS.vis ~= false then
		visualizer()
	end
end

local chatCons = {}
local lastCmd, lastAt, lastSrc = "", 0, nil
local function onChat(msg, src)
	if type(msg) ~= "string" then
		return
	end
	local raw = msg:gsub("^%s+", ""):gsub("%s+$", "")
	local body = string.lower(raw)
	local name, rest = body:match("^%-(%a+)%s*(.*)$")
	local rawRest = raw:match("^%-%a+%s*(.*)$") or ""
	local ok = name == "music" or name == "size" or name == "emote" or name == "emotes" or name == "dance" or name == "align" or name == "stop" or name == "hatgun"
	if not ok then
		return
	end
	local t = os.clock()
	if body == lastCmd and src ~= lastSrc and t - lastAt < 5 then
		return
	end
	lastCmd, lastAt, lastSrc = body, t, src
	if name == "music" then
		if MUS.command then
			MUS.command(rest)
		end
	elseif name == "size" then
		sizeCmd(rest)
	elseif name == "emote" or name == "emotes" or name == "dance" then
		task.spawn(emoteCmd, rawRest, name == "emotes")
	elseif name == "align" then
		if C.toggleAlign then
			C.toggleAlign()
		end
	elseif name == "hatgun" then
		C.toggleHat("gun")
	else
		task.spawn(C.stop)
	end
end
pcall(function()
	chatCons[#chatCons + 1] = lp.Chatted:Connect(function(m)
		onChat(m, "chatted")
	end)
end)
pcall(function()
	local TCS = game:GetService("TextChatService")
	chatCons[#chatCons + 1] = TCS.SendingMessage:Connect(function(message)
		onChat(message.Text, "textchat")
	end)
end)
C.onStop(function()
	for _, c in ipairs(chatCons) do
		pcall(function()
			c:Disconnect()
		end)
	end
end)

local function setupMusic()
	local HS = game:GetService("HttpService")
	local TS = game:GetService("TweenService")
	local SAVE, FOLDER = "AddictMusic.json", "AddictMusic"
	MUS.list = {}
	MUS.cur = nil
	MUS.loop = true
	MUS.vol = ADD.MusicVolume or 2.5
	MUS.color = {255, 0, 0}
	MUS.rainbow = false
	MUS.neon = true
	MUS.vis = ADD.Visualizer ~= false
	MUS.size = 1
	MUS.rspeed = 0.15
	MUS.pos = nil
	pcall(function()
		if makefolder and isfolder and not isfolder(FOLDER) then
			makefolder(FOLDER)
		end
	end)
	pcall(function()
		if isfile and isfile(SAVE) then
			local t = HS:JSONDecode(readfile(SAVE))
			if type(t) == "table" then
				for _, k in ipairs({"cur", "loop", "vol", "rainbow", "neon", "vis", "size", "rspeed"}) do
					if t[k] ~= nil then
						MUS[k] = t[k]
					end
				end
				if type(t.color) == "table" and #t.color == 3 then
					MUS.color = t.color
				end
				if type(t.pos) == "table" and #t.pos == 2 then
					MUS.pos = t.pos
				end
			end
		end
	end)
	local saveAt = nil
	local function save()
		saveAt = os.clock() + 0.6
	end
	local function doSave()
		saveAt = nil
		pcall(function()
			writefile(SAVE, HS:JSONEncode({cur = MUS.cur, loop = MUS.loop, vol = MUS.vol, color = MUS.color, rainbow = MUS.rainbow, neon = MUS.neon, vis = MUS.vis, size = MUS.size, rspeed = MUS.rspeed, pos = MUS.pos}))
		end)
	end

	local function fileName(path)
		return path:match("([^/\\]+)$") or path
	end
	local function scan()
		local seen, out = {}, {}
		local function add(dir)
			local ok, files = pcall(listfiles, dir)
			if not ok or type(files) ~= "table" then
				return
			end
			for _, f in ipairs(files) do
				f = tostring(f)
				local base = fileName(f)
				local ext = base:lower():match("%.(%w+)$")
				if (ext == "mp3" or ext == "ogg" or ext == "wav") and not seen[base:lower()] then
					seen[base:lower()] = true
					out[#out + 1] = {path = f, name = (base:gsub("%.%w+$", ""))}
				end
			end
		end
		if listfiles then
			add(FOLDER)
			add("CommanderMusic")
			add("")
		end
		table.sort(out, function(a, b)
			return a.name:lower() < b.name:lower()
		end)
		MUS.list = out
	end
	local function indexOf(name)
		for i, e in ipairs(MUS.list) do
			if e.name == name then
				return i
			end
		end
		return nil
	end
	local refresh = function() end
	function MUS.play(e)
		if not e then
			return false
		end
		local get = getcustomasset or getsynasset
		local ok, id = pcall(function()
			return get(e.path)
		end)
		if not ok or not id then
			C.notify("Addict", "couldn't load " .. e.name, 3)
			return false
		end
		C.clearPendingMusic()
		local m = C.music
		m.SoundId = id
		m.PlaybackSpeed = e.name:lower() == "addict" and 0.95 or 1
		m.Looped = MUS.loop
		m.Volume = MUS.vol
		m.TimePosition = 0
		m:Play()
		MUS.cur = e.name
		save()
		refresh(true)
		return true
	end
	function MUS.playId(n)
		C.clearPendingMusic()
		local m = C.music
		m.SoundId = "rbxassetid://" .. n
		m.PlaybackSpeed = 1
		m.Looped = MUS.loop
		m.Volume = MUS.vol
		m.TimePosition = 0
		m:Play()
		MUS.cur = "rbxassetid " .. n
		refresh(true)
	end
	function MUS.stop()
		C.clearPendingMusic()
		C.music:Stop()
		MUS.cur = nil
		save()
		refresh(true)
	end
	function MUS.step(d)
		if #MUS.list == 0 then
			return
		end
		local i = MUS.cur and indexOf(MUS.cur) or 0
		i = (i - 1 + d) % #MUS.list + 1
		MUS.play(MUS.list[i])
	end
	local function find(arg)
		local n = tonumber(arg)
		if n and n == math.floor(n) and MUS.list[n] then
			return MUS.list[n]
		end
		local a = arg:lower()
		for _, e in ipairs(MUS.list) do
			if e.name:lower() == a then
				return e
			end
		end
		for _, e in ipairs(MUS.list) do
			if e.name:lower():find(a, 1, true) then
				return e
			end
		end
		return nil
	end
	C.connect(C.music.Ended, function()
		if not MUS.loop and MUS.cur and indexOf(MUS.cur) then
			MUS.step(1)
		end
	end)

	local TH = {
		bg = Color3.fromRGB(12, 13, 18), card = Color3.fromRGB(23, 25, 33), card2 = Color3.fromRGB(33, 36, 47), line = Color3.fromRGB(50, 54, 72),
		text = Color3.fromRGB(242, 244, 252), muted = Color3.fromRGB(148, 154, 178), dim = Color3.fromRGB(98, 104, 128),
		a1 = Color3.fromRGB(128, 92, 255), a2 = Color3.fromRGB(56, 170, 255),
	}
	local BOLD, MED, REG = Enum.Font.GothamBold, Enum.Font.GothamMedium, Enum.Font.Gotham
	local W, H, IW = 340, 598, 308
	local function corner(o, r)
		inst("UICorner", o, {CornerRadius = UDim.new(0, r)})
		return o
	end
	local function stroke(o, col, th, tr)
		return inst("UIStroke", o, {Color = col, Thickness = th or 1, Transparency = tr or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border})
	end
	local function grad(o, rot, t0, t1)
		local g = inst("UIGradient", o, {Color = ColorSequence.new(TH.a1, TH.a2), Rotation = rot or 0})
		if t0 then
			g.Transparency = NumberSequence.new(t0, t1 or t0)
		end
		return g
	end
	local function frame(parent, props)
		local f = inst("Frame", nil, {BorderSizePixel = 0, BackgroundColor3 = TH.card})
		for k, v in pairs(props) do
			f[k] = v
		end
		f.Parent = parent
		return f
	end
	local function txt(parent, props)
		local l = inst("TextLabel", nil, {BackgroundTransparency = 1, Font = REG, TextSize = 12, TextColor3 = TH.text, TextXAlignment = Enum.TextXAlignment.Left})
		for k, v in pairs(props) do
			l[k] = v
		end
		l.Parent = parent
		return l
	end
	local function btn(parent, props, r)
		local b = inst("TextButton", nil, {AutoButtonColor = true, BackgroundColor3 = TH.card2, BorderSizePixel = 0, Font = MED, TextSize = 12, TextColor3 = TH.text, Text = ""})
		for k, v in pairs(props) do
			b[k] = v
		end
		corner(b, r or 8)
		b.Parent = parent
		return b
	end
	local function tween(o, t, props, style)
		local ok = pcall(function()
			TS:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props):Play()
		end)
		if not ok then
			for k, v in pairs(props) do
				o[k] = v
			end
		end
	end
	local function fmtTime(t)
		t = math.max(math.floor(tonumber(t) or 0), 0)
		return string.format("%d:%02d", t // 60, t % 60)
	end
	local eqs = {}
	local function equalizer(parent, n, w, gap, maxH, minH, color, x, y)
		local e = {bars = {}, maxH = maxH, minH = minH}
		for i = 1, n do
			e.bars[i] = corner(frame(parent, {Size = UDim2.fromOffset(w, minH), AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromOffset(x + (i - 1) * (w + gap), y), BackgroundColor3 = color}), math.floor(w / 2))
		end
		eqs[#eqs + 1] = e
		return e
	end

	local gui = inst("ScreenGui", nil, {Name = "AddictMusic", ResetOnSpawn = false, DisplayOrder = 61, ZIndexBehavior = Enum.ZIndexBehavior.Sibling})
	gui.Parent = C.guiParent()
	C.onStop(function()
		if saveAt then
			doSave()
		end
		pcall(function()
			gui:Destroy()
		end)
	end)
	local win = frame(gui, {Name = "Music", Size = UDim2.fromOffset(W, H), BackgroundColor3 = TH.bg, BackgroundTransparency = 0.03, Visible = false, Active = true, ClipsDescendants = true})
	corner(win, 16)
	stroke(win, TH.line, 1, 0.15)
	local scale = inst("UIScale", win, {Scale = 1})
	local topLine = corner(frame(win, {Size = UDim2.new(1, -40, 0, 3), Position = UDim2.fromOffset(20, 0), BackgroundColor3 = TH.text}), 2)
	grad(topLine)

	local head = frame(win, {Size = UDim2.new(1, 0, 0, 58), BackgroundTransparency = 1, Active = true})
	local badge = corner(frame(head, {Size = UDim2.fromOffset(36, 36), Position = UDim2.fromOffset(16, 12), BackgroundColor3 = TH.text}), 11)
	grad(badge, 45)
	equalizer(badge, 3, 5, 3, 22, 6, TH.text, 8, 29)
	txt(head, {Size = UDim2.fromOffset(180, 20), Position = UDim2.fromOffset(62, 12), Font = BOLD, TextSize = 17, Text = "Music"})
	local subTitle = txt(head, {Size = UDim2.fromOffset(190, 14), Position = UDim2.fromOffset(62, 33), TextColor3 = TH.muted, TextSize = 11, Text = ""})
	local minB = btn(head, {Size = UDim2.fromOffset(30, 30), Position = UDim2.new(1, -82, 0, 14), Text = "–", Font = BOLD, TextSize = 16}, 15)
	local closeB = btn(head, {Size = UDim2.fromOffset(30, 30), Position = UDim2.new(1, -46, 0, 14), Text = "×", Font = BOLD, TextSize = 18}, 15)

	local tabs = corner(frame(win, {Size = UDim2.fromOffset(IW, 36), Position = UDim2.fromOffset(16, 62)}), 11)
	local tabHi = corner(frame(tabs, {Size = UDim2.new(0.5, -4, 1, -6), Position = UDim2.fromOffset(3, 3), BackgroundColor3 = TH.text}), 9)
	grad(tabHi)
	local tabSongs = btn(tabs, {Size = UDim2.fromScale(0.5, 1), BackgroundTransparency = 1, AutoButtonColor = false, Font = BOLD, TextSize = 13, Text = "Songs"})
	local tabVis = btn(tabs, {Size = UDim2.fromScale(0.5, 1), Position = UDim2.fromScale(0.5, 0), BackgroundTransparency = 1, AutoButtonColor = false, Font = BOLD, TextSize = 13, Text = "Visualizer"})
	local function page()
		return inst("ScrollingFrame", win, {
			Size = UDim2.new(1, 0, 1, -110), Position = UDim2.fromOffset(0, 106), BackgroundTransparency = 1, BorderSizePixel = 0,
			ScrollBarThickness = 3, ScrollBarImageColor3 = TH.line, ScrollingDirection = Enum.ScrollingDirection.Y, CanvasSize = UDim2.new(),
		})
	end
	local pageSongs, pageVis = page(), page()
	pageVis.Visible = false

	local sliders = {}
	local function slider(parent, y, name, fill, get, set, show)
		txt(parent, {Size = UDim2.fromOffset(70, 20), Position = UDim2.fromOffset(16, y), TextColor3 = TH.muted, Font = MED, Text = name})
		local track = corner(frame(parent, {Size = UDim2.fromOffset(IW - 128, 6), Position = UDim2.fromOffset(92, y + 7), BackgroundColor3 = TH.card2, Active = true}), 3)
		local f = corner(frame(track, {Size = UDim2.fromScale(0, 1), BackgroundColor3 = fill or TH.text}), 3)
		if not fill then
			grad(f)
		end
		local knob = corner(frame(track, {Size = UDim2.fromOffset(14, 14), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), BackgroundColor3 = TH.text}), 7)
		local val = txt(parent, {Size = UDim2.fromOffset(44, 20), Position = UDim2.new(0, IW - 28, 0, y), TextXAlignment = Enum.TextXAlignment.Right, Font = MED, Text = ""})
		local s = {}
		function s.show()
			local k = math.clamp(get(), 0, 1)
			f.Size = UDim2.fromScale(k, 1)
			knob.Position = UDim2.fromScale(k, 0.5)
			val.Text = show()
		end
		function s.at(x)
			local w = track.AbsoluteSize.X
			if w <= 0 then
				return
			end
			set(math.clamp((x - track.AbsolutePosition.X) / w, 0, 1))
			s.show()
		end
		track.InputBegan:Connect(function(io)
			if io.UserInputType == Enum.UserInputType.MouseButton1 or io.UserInputType == Enum.UserInputType.Touch then
				s.drag = true
				s.at(io.Position.X)
			end
		end)
		sliders[#sliders + 1] = s
		s.show()
		return s
	end
	local function switch(parent, y, name, get, flip)
		local row = corner(frame(parent, {Size = UDim2.fromOffset(IW, 36), Position = UDim2.fromOffset(16, y), BackgroundColor3 = TH.card}), 10)
		txt(row, {Size = UDim2.new(1, -70, 1, 0), Position = UDim2.fromOffset(12, 0), Font = MED, Text = name})
		local trk = corner(frame(row, {Size = UDim2.fromOffset(40, 22), Position = UDim2.new(1, -52, 0, 7), BackgroundColor3 = TH.card2}), 11)
		local g = grad(trk)
		local knob = corner(frame(trk, {Size = UDim2.fromOffset(18, 18), Position = UDim2.fromOffset(2, 2), BackgroundColor3 = TH.text}), 9)
		local hit = btn(row, {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, AutoButtonColor = false})
		local sw = {}
		function sw.show()
			local on = get()
			g.Enabled = on
			trk.BackgroundColor3 = on and TH.text or TH.card2
			tween(knob, 0.15, {Position = UDim2.fromOffset(on and 20 or 2, 2)})
		end
		hit.MouseButton1Click:Connect(function()
			flip()
			sw.show()
		end)
		sw.show()
		return sw
	end

	local nowCard = corner(frame(pageSongs, {Size = UDim2.fromOffset(IW, 142), Position = UDim2.fromOffset(16, 0)}), 14)
	stroke(nowCard, TH.line, 1, 0.5)
	local tint = corner(frame(nowCard, {Size = UDim2.fromScale(1, 1), BackgroundColor3 = TH.text}), 14)
	grad(tint, 20, 0.8, 0.96)
	local art = corner(frame(nowCard, {Size = UDim2.fromOffset(62, 62), Position = UDim2.fromOffset(14, 14), BackgroundColor3 = TH.text}), 12)
	grad(art, 45)
	equalizer(art, 5, 6, 4, 42, 8, TH.text, 8, 52)
	local title = txt(nowCard, {Size = UDim2.new(1, -104, 0, 20), Position = UDim2.fromOffset(90, 18), Font = BOLD, TextSize = 15, TextTruncate = Enum.TextTruncate.AtEnd, Text = ""})
	local sub = txt(nowCard, {Size = UDim2.new(1, -104, 0, 16), Position = UDim2.fromOffset(90, 42), TextColor3 = TH.muted, TextSize = 11, TextTruncate = Enum.TextTruncate.AtEnd, Text = ""})
	local mode = txt(nowCard, {Size = UDim2.new(1, -104, 0, 14), Position = UDim2.fromOffset(90, 60), TextColor3 = TH.dim, TextSize = 10, Font = MED, Text = ""})
	local tCur = txt(nowCard, {Size = UDim2.fromOffset(36, 12), Position = UDim2.fromOffset(14, 86), TextColor3 = TH.muted, TextSize = 10, Text = "0:00"})
	local tLen = txt(nowCard, {Size = UDim2.fromOffset(36, 12), Position = UDim2.new(1, -50, 0, 86), TextColor3 = TH.muted, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Right, Text = "0:00"})
	local bar = corner(frame(nowCard, {Size = UDim2.new(1, -112, 0, 4), Position = UDim2.fromOffset(56, 90), BackgroundColor3 = TH.card2, Active = true}), 2)
	local barFill = corner(frame(bar, {Size = UDim2.fromScale(0, 1), BackgroundColor3 = TH.text}), 2)
	grad(barFill)
	local barKnob = corner(frame(bar, {Size = UDim2.fromOffset(10, 10), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), BackgroundColor3 = TH.text}), 5)
	bar.InputBegan:Connect(function(io)
		if io.UserInputType == Enum.UserInputType.MouseButton1 or io.UserInputType == Enum.UserInputType.Touch then
			local m = C.music
			local w = bar.AbsoluteSize.X
			local len = tonumber(m.TimeLength) or 0
			if w > 0 and len > 0 then
				m.TimePosition = math.clamp((io.Position.X - bar.AbsolutePosition.X) / w, 0, 1) * len
			end
		end
	end)
	local loopB = btn(nowCard, {Size = UDim2.fromOffset(62, 28), Position = UDim2.fromOffset(14, 104), Font = BOLD, TextSize = 11}, 14)
	local prevB = btn(nowCard, {Size = UDim2.fromOffset(34, 34), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, -50, 0, 101), Text = "«", Font = BOLD, TextSize = 20}, 17)
	local playB = btn(nowCard, {Size = UDim2.fromOffset(42, 42), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 97), BackgroundColor3 = TH.text, Text = ""}, 21)
	grad(playB, 45)
	local playIcon = txt(playB, {Size = UDim2.fromScale(1, 1), Position = UDim2.fromOffset(2, 0), TextXAlignment = Enum.TextXAlignment.Center, Font = BOLD, TextSize = 16, Text = "▶"})
	local pauseIcon = frame(playB, {Size = UDim2.fromOffset(14, 16), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 1, Visible = false})
	corner(frame(pauseIcon, {Size = UDim2.fromOffset(5, 16), BackgroundColor3 = TH.text}), 2)
	corner(frame(pauseIcon, {Size = UDim2.fromOffset(5, 16), Position = UDim2.fromOffset(9, 0), BackgroundColor3 = TH.text}), 2)
	local nextB = btn(nowCard, {Size = UDim2.fromOffset(34, 34), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 50, 0, 101), Text = "»", Font = BOLD, TextSize = 20}, 17)
	local stopB = btn(nowCard, {Size = UDim2.fromOffset(62, 28), Position = UDim2.new(1, -76, 0, 104), Font = BOLD, TextSize = 11, Text = "Stop"}, 14)

	slider(pageSongs, 154, "Volume", nil, function()
		return MUS.vol / 10
	end, function(k)
		MUS.vol = math.floor(k * 100 + 0.5) / 10
		C.music.Volume = MUS.vol
		save()
	end, function()
		return math.floor(MUS.vol * 10 + 0.5) .. "%"
	end)
	local searchBox = corner(frame(pageSongs, {Size = UDim2.fromOffset(IW - 92, 36), Position = UDim2.fromOffset(16, 186)}), 10)
	stroke(searchBox, TH.line, 1, 0.4)
	local search = inst("TextBox", searchBox, {
		Size = UDim2.new(1, -24, 1, 0), Position = UDim2.fromOffset(12, 0), BackgroundTransparency = 1, ClearTextOnFocus = false,
		Font = REG, TextSize = 12, TextColor3 = TH.text, PlaceholderText = "Search your songs", PlaceholderColor3 = TH.dim, Text = "", TextXAlignment = Enum.TextXAlignment.Left,
	})
	local refreshB = btn(pageSongs, {Size = UDim2.fromOffset(84, 36), Position = UDim2.new(0, 16 + IW - 84, 0, 186), Font = BOLD, Text = "Refresh"}, 10)
	local list = inst("ScrollingFrame", pageSongs, {
		Size = UDim2.fromOffset(IW, 218), Position = UDim2.fromOffset(16, 232), BackgroundColor3 = TH.card, BorderSizePixel = 0,
		ScrollBarThickness = 3, ScrollBarImageColor3 = TH.line, CanvasSize = UDim2.new(), ScrollingDirection = Enum.ScrollingDirection.Y,
	})
	corner(list, 12)
	txt(pageSongs, {Size = UDim2.fromOffset(IW, 26), Position = UDim2.fromOffset(16, 456), TextColor3 = TH.dim, TextSize = 10, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, Text = "chat: -music 2 plays song 2, -music name plays it by name, -music close hides this"})
	pageSongs.CanvasSize = UDim2.fromOffset(0, 486)
	local rows, rowEq = {}, nil
	local function drawList()
		for _, r in ipairs(rows) do
			r:Destroy()
		end
		table.clear(rows)
		if rowEq then
			for i, e in ipairs(eqs) do
				if e == rowEq then
					table.remove(eqs, i)
					break
				end
			end
			rowEq = nil
		end
		local q = string.lower(search.Text or "")
		local y = 6
		for i, e in ipairs(MUS.list) do
			if q == "" or e.name:lower():find(q, 1, true) then
				local playing = e.name == MUS.cur
				local r = btn(list, {Size = UDim2.new(1, -16, 0, 38), Position = UDim2.fromOffset(6, y), BackgroundColor3 = playing and TH.text or TH.card2, BackgroundTransparency = playing and 0 or (i % 2 == 0 and 0.35 or 0.6)}, 10)
				if playing then
					grad(r, 0, 0.55, 0.75)
				end
				local num = corner(frame(r, {Size = UDim2.fromOffset(26, 26), Position = UDim2.fromOffset(7, 6), BackgroundColor3 = playing and TH.text or TH.bg, BackgroundTransparency = playing and 0.75 or 0.2}), 13)
				txt(num, {Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, Font = BOLD, TextSize = 11, TextColor3 = playing and TH.text or TH.muted, Text = tostring(i)})
				txt(r, {Size = UDim2.new(1, -78, 1, 0), Position = UDim2.fromOffset(42, 0), TextTruncate = Enum.TextTruncate.AtEnd, Font = playing and BOLD or MED, TextSize = 12, Text = e.name})
				if playing then
					rowEq = equalizer(r, 3, 3, 2, 16, 4, TH.text, IW - 44, 27)
				end
				r.MouseButton1Click:Connect(function()
					MUS.play(e)
				end)
				rows[#rows + 1] = r
				y += 42
			end
		end
		if #MUS.list == 0 then
			local empty = frame(list, {Size = UDim2.new(1, -12, 0, 120), Position = UDim2.fromOffset(6, 6), BackgroundTransparency = 1})
			txt(empty, {Size = UDim2.new(1, 0, 0, 20), Position = UDim2.fromOffset(8, 18), Font = BOLD, TextSize = 13, Text = "No songs yet"})
			txt(empty, {Size = UDim2.new(1, -16, 0, 70), Position = UDim2.fromOffset(8, 42), TextColor3 = TH.muted, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, Text = "Put .mp3 files in your executor's workspace/" .. FOLDER .. " folder (or right in workspace), then press Refresh."})
			rows[#rows + 1] = empty
			y = 130
		elseif #rows == 0 then
			rows[#rows + 1] = txt(list, {Size = UDim2.new(1, -24, 0, 40), Position = UDim2.fromOffset(12, 8), TextColor3 = TH.muted, Text = "Nothing matches \"" .. search.Text .. "\""})
			y = 56
		end
		list.CanvasSize = UDim2.fromOffset(0, y + 4)
	end

	local prev = corner(frame(pageVis, {Size = UDim2.fromOffset(IW, 96), Position = UDim2.fromOffset(16, 0)}), 14)
	stroke(prev, TH.line, 1, 0.5)
	local dot = corner(frame(prev, {Size = UDim2.fromOffset(64, 64), Position = UDim2.fromOffset(16, 16)}), 32)
	local dotRing = stroke(dot, TH.text, 3, 0.4)
	local hexL = txt(prev, {Size = UDim2.fromOffset(120, 22), Position = UDim2.fromOffset(96, 14), Font = BOLD, TextSize = 18, Text = ""})
	local rgbL = txt(prev, {Size = UDim2.fromOffset(200, 16), Position = UDim2.fromOffset(96, 38), TextColor3 = TH.muted, TextSize = 11, Text = ""})
	local hexWrap = corner(frame(prev, {Size = UDim2.fromOffset(IW - 112, 26), Position = UDim2.fromOffset(96, 58), BackgroundColor3 = TH.card2}), 8)
	local hexBox = inst("TextBox", hexWrap, {
		Size = UDim2.new(1, -16, 1, 0), Position = UDim2.fromOffset(8, 0), BackgroundTransparency = 1, ClearTextOnFocus = true,
		Font = MED, TextSize = 11, TextColor3 = TH.text, PlaceholderText = "type a hex code, like #FF2D55", PlaceholderColor3 = TH.dim, Text = "", TextXAlignment = Enum.TextXAlignment.Left,
	})
	local swShow = switch(pageVis, 108, "Show the visualizer", function()
		return MUS.vis
	end, function()
		MUS.vis = not MUS.vis
		save()
	end)
	local swRgb = switch(pageVis, 150, "RGB (goes through every color)", function()
		return MUS.rainbow
	end, function()
		MUS.rainbow = not MUS.rainbow
		save()
		refresh()
	end)
	local swNeon = switch(pageVis, 192, "Neon glow", function()
		return MUS.neon
	end, function()
		MUS.neon = not MUS.neon
		save()
	end)
	txt(pageVis, {Size = UDim2.fromOffset(IW, 16), Position = UDim2.fromOffset(16, 238), TextColor3 = TH.dim, Font = BOLD, TextSize = 10, Text = "COLORS"})
	local grid = frame(pageVis, {Size = UDim2.fromOffset(IW, 130), Position = UDim2.fromOffset(16, 258), BackgroundTransparency = 1})
	inst("UIGridLayout", grid, {CellSize = UDim2.fromOffset(22, 22), CellPadding = UDim2.fromOffset(4, 4), SortOrder = Enum.SortOrder.LayoutOrder})
	local PALETTE = {}
	for i = 0, 11 do
		PALETTE[#PALETTE + 1] = Color3.fromHSV(i / 12, 1, 1)
	end
	for i = 0, 11 do
		PALETTE[#PALETTE + 1] = Color3.fromHSV(i / 12 + 1 / 24, 0.85, 1)
	end
	for i = 0, 11 do
		PALETTE[#PALETTE + 1] = Color3.fromHSV(i / 12, 0.45, 1)
	end
	for i = 0, 11 do
		PALETTE[#PALETTE + 1] = Color3.fromHSV(i / 12, 1, 0.55)
	end
	for i = 0, 11 do
		PALETTE[#PALETTE + 1] = Color3.fromHSV(0, 0, 1 - i / 11)
	end
	local function c255(c)
		return {math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5)}
	end
	local swatches = {}
	local rgbSliders = {}
	local function setColor(c)
		MUS.color = c
		MUS.rainbow = false
		save()
		refresh()
	end
	for i, c in ipairs(PALETTE) do
		local b = btn(grid, {LayoutOrder = i, BackgroundColor3 = c, AutoButtonColor = true}, 6)
		local ring = stroke(b, TH.text, 2, 1)
		swatches[i] = {b = b, ring = ring, c = c255(c)}
		b.MouseButton1Click:Connect(function()
			setColor(c255(c))
		end)
	end
	txt(pageVis, {Size = UDim2.fromOffset(IW, 16), Position = UDim2.fromOffset(16, 394), TextColor3 = TH.dim, Font = BOLD, TextSize = 10, Text = "MIX"})
	local fills = {Color3.fromRGB(255, 70, 90), Color3.fromRGB(70, 220, 120), Color3.fromRGB(70, 140, 255)}
	for k, name in ipairs({"Red", "Green", "Blue"}) do
		rgbSliders[k] = slider(pageVis, 414 + (k - 1) * 28, name, fills[k], function()
			return MUS.color[k] / 255
		end, function(v)
			local c = {MUS.color[1], MUS.color[2], MUS.color[3]}
			c[k] = math.floor(v * 255 + 0.5)
			MUS.color = c
			MUS.rainbow = false
			save()
			refresh()
		end, function()
			return tostring(MUS.color[k])
		end)
	end
	slider(pageVis, 504, "RGB speed", nil, function()
		return MUS.rspeed
	end, function(v)
		MUS.rspeed = math.max(math.floor(v * 100 + 0.5) / 100, 0.01)
		save()
	end, function()
		return string.format("%.2f", MUS.rspeed)
	end)
	slider(pageVis, 532, "Size", nil, function()
		return (MUS.size - 0.25) / 2.75
	end, function(v)
		MUS.size = math.floor((0.25 + v * 2.75) * 100 + 0.5) / 100
		save()
	end, function()
		return string.format("%.2fx", MUS.size)
	end)
	pageVis.CanvasSize = UDim2.fromOffset(0, 566)
	hexBox.FocusLost:Connect(function()
		local s = (hexBox.Text or ""):gsub("%s", "")
		local h = s:match("^#?(%x%x%x%x%x%x)$")
		local c
		if h then
			c = {tonumber(h:sub(1, 2), 16), tonumber(h:sub(3, 4), 16), tonumber(h:sub(5, 6), 16)}
		else
			local r, g, b = s:match("^(%d+),(%d+),(%d+)$")
			if r then
				c = {math.clamp(tonumber(r), 0, 255), math.clamp(tonumber(g), 0, 255), math.clamp(tonumber(b), 0, 255)}
			end
		end
		hexBox.Text = ""
		if c then
			setColor(c)
		end
	end)

	function refresh(redrawList)
		local n = #MUS.list
		subTitle.Text = n .. (n == 1 and " song" or " songs") .. "  ·  workspace/" .. FOLDER
		local i = MUS.cur and indexOf(MUS.cur)
		title.Text = MUS.cur or "Nothing playing"
		sub.Text = i and ("Track " .. i .. " of " .. n) or (MUS.cur and "Roblox audio" or "Pick a song below")
		mode.Text = MUS.loop and "REPEATS THIS SONG" or "PLAYS THE NEXT SONG"
		loopB.Text = MUS.loop and "Repeat" or "Next"
		loopB.BackgroundColor3 = TH.card2
		local c = MUS.color
		local col = Color3.fromRGB(c[1], c[2], c[3])
		dot.BackgroundColor3 = col
		dotRing.Color = col
		hexL.Text = MUS.rainbow and "RGB" or string.format("#%02X%02X%02X", c[1], c[2], c[3])
		rgbL.Text = MUS.rainbow and "going through every color" or string.format("R %d  ·  G %d  ·  B %d", c[1], c[2], c[3])
		for _, s in ipairs(swatches) do
			local on = not MUS.rainbow and s.c[1] == c[1] and s.c[2] == c[2] and s.c[3] == c[3]
			s.ring.Transparency = on and 0 or 1
		end
		for _, s in ipairs(rgbSliders) do
			s.show()
		end
		swRgb.show()
		if redrawList then
			drawList()
		end
	end
	local onVis = false
	local function showTab(vis)
		onVis = vis
		pageSongs.Visible = not vis
		pageVis.Visible = vis
		tween(tabHi, 0.2, {Position = vis and UDim2.new(0.5, 1, 0, 3) or UDim2.fromOffset(3, 3)})
		tabSongs.TextColor3 = vis and TH.muted or TH.text
		tabVis.TextColor3 = vis and TH.text or TH.muted
	end
	tabSongs.MouseButton1Click:Connect(function()
		showTab(false)
	end)
	tabVis.MouseButton1Click:Connect(function()
		showTab(true)
	end)
	prevB.MouseButton1Click:Connect(function()
		MUS.step(-1)
	end)
	nextB.MouseButton1Click:Connect(function()
		MUS.step(1)
	end)
	stopB.MouseButton1Click:Connect(MUS.stop)
	playB.MouseButton1Click:Connect(function()
		local m = C.music
		if m.IsPlaying then
			m:Pause()
		elseif m.SoundId ~= "" and MUS.cur then
			m:Resume()
		else
			MUS.play(MUS.list[MUS.cur and indexOf(MUS.cur) or 1])
		end
	end)
	loopB.MouseButton1Click:Connect(function()
		MUS.loop = not MUS.loop
		C.music.Looped = MUS.loop
		save()
		refresh()
	end)
	refreshB.MouseButton1Click:Connect(function()
		scan()
		refresh(true)
	end)
	pcall(function()
		search:GetPropertyChangedSignal("Text"):Connect(drawList)
	end)
	search.FocusLost:Connect(drawList)

	local fit, open, small, token = 1, false, false, 0
	local function viewport()
		local cam = workspace.CurrentCamera
		local vp = cam and cam.ViewportSize or Vector2.new(800, 600)
		if vp.X <= 0 or vp.Y <= 0 then
			vp = Vector2.new(800, 600)
		end
		return vp
	end
	local function place(x, y)
		local vp = viewport()
		local w, h = W * fit, (small and 58 or H) * fit
		x = math.clamp(x, 0, math.max(vp.X - w, 0))
		y = math.clamp(y, 0, math.max(vp.Y - h, 0))
		win.Position = UDim2.fromOffset(x, y)
	end
	local function doFit()
		local vp = viewport()
		fit = math.clamp(math.min((vp.Y - 24) / H, (vp.X - 24) / W), 0.4, 1)
		local p = MUS.pos
		if p then
			place(p[1], p[2])
		else
			place(vp.X - W * fit - 16, 12)
		end
	end
	function MUS.open()
		token += 1
		if not open then
			open = true
			doFit()
			scale.Scale = fit * 0.94
			win.Visible = true
			tween(scale, 0.22, {Scale = fit}, Enum.EasingStyle.Back)
		end
		scan()
		refresh(true)
	end
	function MUS.close()
		if not open then
			return
		end
		open = false
		token += 1
		local my = token
		tween(scale, 0.12, {Scale = fit * 0.94})
		task.delay(0.12, function()
			if token == my then
				win.Visible = false
			end
		end)
	end
	function MUS.isOpen()
		return open
	end
	closeB.MouseButton1Click:Connect(MUS.close)
	minB.MouseButton1Click:Connect(function()
		small = not small
		minB.Text = small and "+" or "–"
		tween(win, 0.2, {Size = UDim2.fromOffset(W, small and 58 or H)})
		tabs.Visible = not small
		pageSongs.Visible = not small and not onVis
		pageVis.Visible = not small and onVis
	end)
	local dragging, dragFrom, startPos = false, nil, nil
	head.InputBegan:Connect(function(io)
		if io.UserInputType == Enum.UserInputType.MouseButton1 or io.UserInputType == Enum.UserInputType.Touch then
			dragging, dragFrom, startPos = true, io.Position, win.Position
		end
	end)
	C.connect(UIS.InputChanged, function(io)
		if io.UserInputType == Enum.UserInputType.MouseMovement or io.UserInputType == Enum.UserInputType.Touch then
			if dragging then
				local d = io.Position - dragFrom
				place(startPos.X.Offset + d.X, startPos.Y.Offset + d.Y)
			end
			for _, s in ipairs(sliders) do
				if s.drag then
					s.at(io.Position.X)
				end
			end
		end
	end)
	C.connect(UIS.InputEnded, function(io)
		if io.UserInputType == Enum.UserInputType.MouseButton1 or io.UserInputType == Enum.UserInputType.Touch then
			if dragging then
				dragging = false
				MUS.pos = {win.Position.X.Offset, win.Position.Y.Offset}
				save()
			end
			for _, s in ipairs(sliders) do
				s.drag = false
			end
		end
	end)
	pcall(function()
		C.connect(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"), function()
			if open then
				doFit()
				scale.Scale = fit
			end
		end)
	end)

	local lastTime = 0
	function MUS.frame()
		if saveAt and os.clock() >= saveAt then
			doSave()
		end
		if not open or small then
			return
		end
		local m = C.music
		local len = tonumber(m.TimeLength) or 0
		local pos = tonumber(m.TimePosition) or 0
		local k = len > 0 and math.clamp(pos / len, 0, 1) or 0
		barFill.Size = UDim2.fromScale(k, 1)
		barKnob.Position = UDim2.fromScale(k, 0.5)
		local t = os.clock()
		if t - lastTime > 0.2 then
			lastTime = t
			tCur.Text = fmtTime(pos)
			tLen.Text = fmtTime(len)
			local playing = m.IsPlaying
			playIcon.Visible = not playing
			pauseIcon.Visible = playing
		end
		local loud = m.IsPlaying and math.clamp((tonumber(m.PlaybackLoudness) or 0) / 400, 0, 1) or 0
		for _, e in ipairs(eqs) do
			for i, b in ipairs(e.bars) do
				local wob = 0.5 + 0.5 * math.sin(t * (7 + i * 1.7) + i * 1.3)
				local h = e.minH + (e.maxH - e.minH) * math.clamp(loud * (0.45 + 0.75 * wob), 0, 1)
				b.Size = UDim2.fromOffset(b.Size.X.Offset, h)
			end
		end
		if MUS.rainbow then
			local col = MUS.color3()
			dot.BackgroundColor3 = col
			dotRing.Color = col
		end
	end
	function MUS.color3()
		if MUS.rainbow then
			return Color3.fromHSV((now() * MUS.rspeed) % 1, 1, 1)
		end
		local c = MUS.color
		return Color3.fromRGB(c[1], c[2], c[3])
	end
	function MUS.command(arg)
		arg = arg:gsub("^%s+", ""):gsub("%s+$", "")
		local la = arg:lower()
		if arg == "" or la == "open" then
			MUS.open()
			return
		end
		if la == "close" or la == "hide" then
			MUS.close()
			return
		end
		scan()
		refresh(true)
		local e = find(arg)
		if e then
			MUS.play(e)
			return
		end
		if la == "stop" or la == "off" then
			MUS.stop()
			return
		end
		local n = tonumber(arg)
		if n and n >= 10000 and n == math.floor(n) then
			MUS.playId(n)
			return
		end
		C.notify("Addict", "no song " .. arg .. " (there's " .. #MUS.list .. " in your list, chat -music to see them)", 4)
	end
	showTab(false)
	swShow.show()
	swNeon.show()
	scan()
	refresh(true)

	if ADD.Music ~= false then
		local last = MUS.cur and indexOf(MUS.cur)
		if not (last and MUS.play(MUS.list[last])) then
			MUS.cur = nil
			C.setMusic("Addict.mp3", MUS.vol, nil, 0.95)
			if not C.asset("Addict.mp3") then
				C.music.SoundId = "rbxassetid://2256171111"
				C.music.PlaybackSpeed = 0.95
				C.music:Play()
			end
			C.download({{"Addict.mp3", "https://drive.usercontent.google.com/download?id=1TMLt79qoxsCzGGr99bMu68kgwKJd98dK&export=download&authuser=2&confirm=t&uuid=b57b864f-a062-4c0c-9b9a-82c20196830f&at=AENtkXa1foobVGjPZZQ9YPPW7IDp:1733244712812"}})
		end
		refresh(true)
	end
end
setupMusic()

local yaw = {last = nil, rate = 0}
local function basePose(dt)
	local vel = C.vel()
	local speed = VT(vel.X, 0, vel.Z).Magnitude
	local ground = fd.isOnGround()
	if not ground and vel.Y > 1 then
		S.state = "jump"
	elseif not ground and vel.Y < -1 then
		S.state = "fall"
	elseif ground and speed < 1 then
		S.state = "idle"
	elseif ground then
		S.state = "walk"
	end
	local root = C.rootCF()
	if yaw.last and dt > 0 then
		local _, ry = (yaw.last:ToObjectSpace(root)):ToEulerAnglesYXZ()
		yaw.rate = yaw.rate + (CLAMP(ry / dt, -20, 20) - yaw.rate) * math.min(dt * 10, 1)
	end
	yaw.last = root.Rotation
	local s = sine()
	local st = S.state
	local ws = ADD.WalkSpeed or 16
	local wsv = 6 / (ws / 16)
	if st == "walk" and not EM.on then
		local a1, a2 = 2 * (ws / 16) / 3, 0.2 * (ws / 16) / 3
		base.RJ1 = T(P.ROOTC0 * CF(0, 0, -0.15 * COS(s / (wsv / 2))) * ANG(0, -yaw.rate / 75, 0), a1)
		base.NK1 = T(CF(0, -0.5, 0) * A(-90, 0, 180) * ANG(RAD(2.5 * SIN(s / (wsv / 2))), 0, -yaw.rate / 30), a2)
		base.RH1 = T(CF(0.5, 0.875 - 0.125 * SIN(s / wsv), -0.125 * COS(s / wsv)) * A(0, 90, 0) * ANG(-yaw.rate / 75, 0, RAD(25 * COS(s / wsv))), a2)
		base.LH1 = T(CF(-0.5, 0.875 + 0.125 * SIN(s / wsv), 0.125 * COS(s / wsv)) * A(0, -90, 0) * ANG(yaw.rate / 75, 0, RAD(25 * COS(s / wsv))), a2)
	else
		local a = 0.2 / 3
		base.RJ1, base.NK1, base.RH1, base.LH1 = T(P.RJC1, a), T(P.NKC1, a), T(P.RHC1, a), T(P.LHC1, a)
	end
	if st == "jump" or st == "fall" then
		local a = 0.2 / 3
		base.RJ = T(P.ROOTC0, a)
		base.NK = T(P.NECKC0 * A(-20, 0, 0), a)
		base.RS = T(CF(1.5, 0.5, 0) * A(45, 0, 25) * P.RSC0, 0.15 / 3)
		base.LS = T(CF(-1.5, 0.5, 0) * A(-40, 0, -20) * P.LSC0, a)
		base.RH = T(CF(1, -1, -0.3) * A(0, 90, 0) * A(-5, 0, -20), a)
		base.LH = T(CF(-1, -1, -0.3) * A(0, -90, 0) * A(-5, 0, 20), a)
	elseif st == "idle" then
		base.NK = T(P.NECKC0 * A(2 + 6 * SIN(s / 15), 0, -25), 1)
		base.RJ = T(P.ROOTC0 * CF(0, -0.1 * COS(s / 30), P.UP + 0.1 * COS(s / 15)) * A(5 * COS(s / 30), 0, 25), 1 / 3)
		base.RS = T(CF(1.5, 0.5, 0) * A(165 + 6 * COS(s / 30), 0, 12) * P.RSC0, 0.15 / 3)
		base.LS = T(CF(-1.5, 0.5, 0) * A(6 * COS(s / 30), 0, -12) * P.LSC0, 0.15 / 3)
		base.RH = T(CF(1, -1 - 0.1 * COS(s / 15), -0.01) * A(0, 75, 0) * A(-6 - 2.5 * COS(s / 30), 0, 5 * COS(s / 30)), 1 / 3)
		base.LH = T(CF(-1, -1 - 0.1 * COS(s / 15), -0.01) * A(0, -75, 0) * A(-6 + 2.5 * COS(s / 30), 0, -5 * COS(s / 30)), 1 / 3)
	else
		base.RJ = T(up() * A(5, 0, 0), 0.15 / 3)
		base.NK = T(P.NECKC0 * A(RND(-15, 25) - 2.5 * SIN(s / 12), RND(-15, 25), RND(-15, 25)), 1 / 3)
		base.RS = T(CF(1.5, 0.5, 0) * A(145, 0, 5) * P.RSC0, 0.35 / 3)
		base.LS = T(CF(-1.5, 0.5, 0) * A(-35 * COS(s / wsv), 0, -5) * P.LSC0, 0.35 / 3)
		base.RH = T(CF(1, -1 - 0.15 * COS(s / wsv * 2), -1 + 0.2 * COS(s / wsv)) * A(0, 90, 0) * A(0, 0, -15), 2 / 3)
		base.LH = T(CF(-1, -1 - 0.15 * COS(s / wsv * 2), -1 - 0.2 * COS(s / wsv)) * A(0, -90, 0) * A(0, 0, 15), 2 / 3)
	end
	if not S.attack and C.alignOpen and C.alignOpen() and C.alignTab and C.alignTab() <= 2 then
		local g = akAim(false)
		base.RJ, base.NK, base.RS, base.LS = g.RJ, g.NK, g.RS, g.LS
	end
end

local lastRooted, lastHip = nil, nil
local C1STD = {RJ = P.RJC1, NK = P.NKC1, RS = P.RSC1, LS = P.LSC1, RH = P.RHC1, LH = P.LHC1}
local EMKEYS = {"RJ", "NK", "RS", "LS", "RH", "LH"}
C.animate = function(_, dt)
	dt = dt or 1 / 60
	local p = dt * 60
	if SZ.k ~= SZ.goal then
		SZ.k += (SZ.goal - SZ.k) * (1 - math.exp(-dt * 3))
		if math.abs(SZ.goal - SZ.k) < 1e-3 then
			SZ.k = SZ.goal
		end
	end
	local tall = ADD.Tall == true or (ADD.Tall ~= false and hatOk(RIG[5]) and hatOk(RIG[6]))
	local upGoal = tall and 2.55 or 0
	if not P.picked and P.scanned then
		P.picked = true
		P.UP = upGoal
	end
	if P.UP ~= upGoal then
		P.UP += (upGoal - P.UP) * (1 - math.exp(-dt * 6))
		if math.abs(upGoal - P.UP) < 1e-3 then
			P.UP = upGoal
		end
	end
	local hip = (SZ.k - 1) * (2 - 0.7 * P.UP / 2.55)
	if lastHip ~= hip then
		lastHip = hip
		pcall(fd.setHipHeight, hip)
	end
	local speedK = EM.on and EM.lib and EM.lib.speedK or 1
	pcall(fd.setWalkSpeed, S.rooted and 0 or (ADD.WalkSpeed or 16) * SZ.k * speedK)
	if S.rooted ~= lastRooted then
		lastRooted = S.rooted
		pcall(fd.setJumpPower, S.rooted and 0 or 50)
	end
	local ok, e = pcall(stepAim, dt)
	if not ok then
		C.err(e)
	end
	basePose(dt)
	for _, k in ipairs(KEYS) do
		local g = goal[k] or base[k]
		if g then
			local target = g[1]
			if type(target) == "function" then
				target = target()
			end
			J[k] = J[k]:Lerp(target, 1 - (1 - g[2]) ^ p)
		end
	end
	local ep = EM.step(dt)
	if ep then
		local w = (ep.w or 1) * EM.k
		for i, k in ipairs(EMKEYS) do
			if typeof(ep[i]) == "CFrame" then
				local pose = ep[i]
				if i == 1 then
					pose = CF(0, P.UP, 0) * pose
				end
				J[k] = J[k]:Lerp(pose * C1STD[k], w)
			end
		end
	end
	local rjC1 = ep and P.RJC1 or J.RJ1
	local nkC1 = ep and P.NKC1 or J.NK1
	local rhC1 = ep and P.RHC1 or J.RH1
	local lhC1 = ep and P.LHC1 or J.LH1
	RJ.C0, RJ.C1 = sz(J.RJ), sz(rjC1)
	Neck.C0, Neck.C1 = sz(J.NK), sz(nkC1)
	RS.C0, RS.C1 = sz(J.RS), sz(P.RSC1)
	LS.C0, LS.C1 = sz(J.LS), sz(P.LSC1)
	RH.C0, RH.C1 = sz(J.RH), sz(rhC1)
	LH.C0, LH.C1 = sz(J.LH), sz(lhC1)
	if MUS.vol then
		local want = EM.music and 0 or MUS.vol
		local v = C.music.Volume
		if math.abs(v - want) > 0.01 then
			C.music.Volume = v + (want - v) * math.min(dt * 6, 1)
		end
	end
	local root = C.rootCF()
	local rootInv = root:Inverse()
	W.root = root
	W.torso = root * sz(J.RJ) * sz(rjC1):Inverse()
	W.head = W.torso * sz(J.NK) * sz(nkC1):Inverse()
	W.rarm = W.torso * sz(J.RS) * sz(P.RSC1):Inverse()
	W.larm = W.torso * sz(J.LS) * sz(P.LSC1):Inverse()
	W.rleg = W.torso * sz(J.RH) * sz(rhC1):Inverse()
	W.lleg = W.torso * sz(J.LH) * sz(lhC1):Inverse()
	W.parts = {[C.Head] = W.head, [C.Torso] = W.torso, [C.RightArm] = W.rarm, [C.LeftArm] = W.larm, [C.RightLeg] = W.rleg, [C.LeftLeg] = W.lleg}
	W.gunBase = W.rarm * CF(GRIP.Position * SZ.k) * C.alignOff(1)
	for _, h in ipairs(RIG) do
		if hatOk(h) then
			glue(h, h.part, rigCF(h))
		end
	end
	local gn = gunHat()
	if gn then
		local rel = rootInv * W.gunBase * GRIPROT * gn.cf
		glue(gn, C.Root, rel)
	elseif GUN.glued and hatOk(GUN) then
		restore(GUN)
	end
	if hatOk(ROCK) then
		glue(ROCK, C.Root, rootInv * rockCF(root))
	end
	local n, bp, bc = 0, {}, {}
	local function put(part, cf)
		n += 1
		bp[n] = part
		bc[n] = cf
	end
	local showW = clientOn()
	for name, list in pairs(OGW.models) do
		local want = showW
		if OGW.shown[name] ~= want then
			OGW.shown[name] = want
			for _, c in ipairs(list) do
				c.p.Transparency = want and c.tr or 1
				if not want then
					put(c.p, P.HIDE)
				end
			end
		end
		if want then
			for _, c in ipairs(list) do
				put(c.p, W.rarm * sz(c.off))
			end
		end
	end
	if tag then
		local col = loudGrey()
		tagText.TextColor3 = col
		tagText.Rotation = 5 * COS(sine() / 32)
		tag.StudsOffset = VT(0, 2 * SZ.k, 0)
	end
	if n > 0 and not pcall(workspace.BulkMoveTo, workspace, bp, bc, Enum.BulkMoveMode.FireCFrameChanged) then
		for k = 1, n do
			bp[k].CFrame = bc[k]
		end
	end
end

C.afterFrame = function()
	scanHats()
	P.scanned = true
	if MUS.frame then
		MUS.frame()
	end
end
