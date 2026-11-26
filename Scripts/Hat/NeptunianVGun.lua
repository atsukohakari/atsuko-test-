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
						C.notify("Neptunian V", "Downloading music...", 4)
					end
					local ok, data = pcall(function()
						return game:HttpGet(it[2])
					end)
					if ok and type(data) == "string" and #data > 2000 then
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

	local TAB = {"Sword", "Gun", "Muzzle", "Slash"}
	local genv = (typeof(getgenv) == "function" and getgenv()) or _G
	local AL = {version = 1, title = "Neptunian V", tabs = TAB, file = FILE, dirty = false, open = false, key = CFG.alignKeyText or string.upper(CFG.alignKey or "j")}
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
	AL.optList = {{"hatsword", "Hat Sword"}, {"hatgun", "Hat Gun"}, {"roll", "Roll (upside down? tap this)", "button"}}
	AL.optsSaved = false
	function AL.opts()
		return {hatsword = not C.hatOn or C.hatOn("sword") == true, hatgun = not C.hatOn or C.hatOn("gun") == true}
	end
	function AL.setOpt(name, on)
		local v = VAL[cur]
		if name == "roll" and v then
			AL.set(cur, 4, v[4] + 180)
		elseif (name == "hatsword" or name == "hatgun") and C.toggleHat and C.hatOn then
			local k = name == "hatsword" and "sword" or "gun"
			if (C.hatOn(k) == true) ~= (on == true) then
				C.toggleHat(k)
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
local NEP = {
	Sword = "4506945409",
	SwordWords = {"greatsword"},
	GripInset = 0.1,
	Scythe = "98316054675010",
	ScytheWords = {"pink", "scythe"},
	ScytheGrip = 0.2,
	Gun = "12215889472",
	GunWords = {"toy", "gun"},
	Revolver = "12830338562",
	RevolverWords = {"cyber", "revolver"},
	HatSword = true,
	HatGun = true,
	Slash = "7583370812",
	SlashWords = {"nebula", "blade"},
	Bullet = "4307568890",
	ClientWeapons = "auto",
	Gauntlet = true,
	WalkSpeed = 16,
	RunSpeed = 26,
	RunKey = "leftcontrol",
	AlignKey = "p",
}

if not game:IsLoaded() then
	game.Loaded:Wait()
end

local C = LCCore(FD, {gunIds = {}, alignFile = "NeptunianVAlign.json", alignKey = NEP.AlignKey, maxEffects = 320})
if not C then
	return
end
local fd = C.fd

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local lp = Players.LocalPlayer
local CF, VT, C3 = CFrame.new, Vector3.new, Color3.new
local ANG, EUL = CFrame.Angles, CFrame.fromEulerAnglesXYZ
local RAD, RND, SIN, COS = math.rad, math.random, math.sin, math.cos
local CLAMP = math.clamp
local IDENT = CFrame.identity
local RJ, Neck, RS, LS, RH, LH = C.RootJoint, C.Neck, C.RightShoulder, C.LeftShoulder, C.RightHip, C.LeftHip
local FX = C.Effects
local onPhone = UIS.TouchEnabled and not UIS.KeyboardEnabled
local PURPLE, BLUE, RED, WHITE = BrickColor.new("Royal purple").Color, BrickColor.new("Bright blue").Color, BrickColor.new("Really red").Color, C3(1, 1, 1)

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
local function snd(id, vol, pitch)
	return C.sound(id, vol or 1, pitch or 1)
end

local P = {}
P.RootCF = EUL(-1.57, 0, 3.14)
P.RJC1 = CF(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, -0)
P.necko = CF(0, 1, 0, -1, -0, -0, 0, 0, 1, 0, 1, 0)
P.necko2 = CF(0, -0.5, 0, -1, -0, -0, 0, 0, 1, 0, 1, 0)
P.LHC0 = CF(-1, -1, 0, -0, -0, -1, 0, 1, 0, 1, 0, 0)
P.LHC1 = CF(-0.5, 1, 0, -0, -0, -1, 0, 1, 0, 1, 0, 0)
P.RHC0 = CF(1, -1, 0, 0, 0, 1, 0, 1, 0, -1, -0, -0)
P.RHC1 = CF(0.5, 1, 0, 0, 0, 1, 0, 1, 0, -1, -0, -0)
P.ARM1 = CF(0, 0.5, 0)
P.HWC1i = CF(-0.069039166, -0.113463402, 1.04289675, -1, 2.17809955e-007, -5.96046519e-008, -5.96047656e-008, -4.97983308e-007, 1, 2.17809927e-007, 1, 4.97983308e-007):Inverse()
P.HWATK = CF(0, -1, -1) * A(-90, 0, 0)
P.HWSPIN = CF(0, -.5, -.5) * A(-35, 0, 0)
P.LW25 = CF(-1.45, 0.5, 0) * A(0, 0, -25)
P.RW25 = CF(1.45, 0.5, 0) * A(0, 0, 25)
P.LWAIM = CF(-1.45, 0.5, 0) * A(170, 0, -90)
P.LWAIM2 = CF(-1.45, 0.5, 0) * A(170, 0, -50)
P.RWHOLD = CF(1.5, 0.5, 0) * A(-35, 90, 0)
P.RWUP = CF(1, 0.5, -.5) * A(0, -80, -80) * A(-75, 0, 0)
P.RWOUT = CF(1.5, 0.5, 0) * A(0, 70, 90) * A(-75, 0, 0)
P.RWSWING = CF(1.5, 0.5, 0) * A(0, -90, -90) * A(90, 0, 0)
P.RWBACK = CF(1, 0.5, -.5) * A(0, -90, -90) * A(-75, 0, 0)

local KEYS = {"RJ", "NK", "NK1", "RW", "RW1", "LW", "LW1", "RH", "LH", "HW"}
local J = {RJ = P.RootCF, NK = P.necko, NK1 = P.necko2, RW = CF(1.5, 0.5, 0), RW1 = P.ARM1, LW = CF(-1.5, 0.5, 0), LW1 = P.ARM1, RH = P.RHC0, LH = P.LHC0, HW = IDENT}
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

local running = false
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
	if d.Magnitude > 2 then
		aimRot = aimRot:Lerp(CFrame.lookAt(Vector3.zero, d), 1 - math.exp(-14 * dt))
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
	local ok, row = pcall(A.match, "Neptunian V Gun", slot, {mesh = idOf(rawget(e, "m")), tex = idOf(rawget(e, "t")), name = accName(e)})
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
local HUBJOB = {sword = "sword", scythe = "sword", gun = "gun", revolver = "gun", slash = "slash", rock = "bullet"}
local H = {}
local HATLIST = {}
local function hatDef(key, id, words, mesh)
	local h = {key = key, id = tostring(id or ""), words = words or {}, mesh = mesh and tostring(mesh) or nil, nextScan = 0}
	H[key] = h
	HATLIST[#HATLIST + 1] = h
	local n = tonumber(h.id)
	if n then
		task.spawn(function()
			pcall(function()
				local acc = game:GetObjects("rbxassetid://" .. n)[1]
				local hd = acc and (acc:FindFirstChild("Handle") or acc:FindFirstChildWhichIsA("BasePart", true))
				if hd then
					if hd:IsA("MeshPart") then
						h.cmesh = idOf(hd.MeshId)
					else
						local sm = hd:FindFirstChildOfClass("SpecialMesh")
						if sm then
							h.cmesh = idOf(sm.MeshId)
						end
					end
				end
				if acc and (acc:IsA("Accoutrement") or acc:IsA("Accessory")) then
					h.name = squash(acc.Name)
					h.title = acc.Name
				end
			end)
			pcall(function()
				local pi = game:GetService("MarketplaceService"):GetProductInfo(n, Enum.InfoType.Asset)
				if type(pi) == "table" and type(pi.Name) == "string" then
					h.name2 = squash(pi.Name)
					h.title = pi.Name
				end
			end)
			h.nextScan = 0
		end)
	end
	return h
end
hatDef("sword", NEP.Sword, NEP.SwordWords)
hatDef("scythe", NEP.Scythe, NEP.ScytheWords)
hatDef("gun", NEP.Gun, NEP.GunWords)
hatDef("revolver", NEP.Revolver, NEP.RevolverWords)
hatDef("slash", NEP.Slash, NEP.SlashWords)
hatDef("rock", "", {}, NEP.Bullet)
local function hatRank(h, e)
	if HUBJOB[h.key] and hubJob(HUBJOB[h.key], e) then
		return 1
	end
	local m, t = idOf(rawget(e, "m")), idOf(rawget(e, "t"))
	if h.mesh and m == h.mesh then
		return 1
	end
	if h.id ~= "" and (m == h.id or t == h.id) then
		return 1
	end
	if h.cmesh and h.cmesh ~= "" and m == h.cmesh then
		return 1
	end
	if h.mesh then
		return nil
	end
	local n = squash(accName(e))
	if n == "" then
		return nil
	end
	if (h.name and n == h.name) or (h.name2 and n == h.name2) then
		return 2
	end
	local count = 0
	for _, w in ipairs(h.words) do
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
local function sortedAxes(s)
	local ax = {VT(1, 0, 0), VT(0, 1, 0), VT(0, 0, 1)}
	local sz = {s.X, s.Y, s.Z}
	local idx = {1, 2, 3}
	table.sort(idx, function(a, b)
		return sz[a] > sz[b]
	end)
	return ax[idx[1]], ax[idx[2]], ax[idx[3]], sz[idx[1]], sz[idx[2]], sz[idx[3]]
end
local function fitSword(h)
	local long, width, _, L = sortedAxes(sizeOf(h.e))
	local rest = h.home[3] * h.home[2]:Inverse()
	local hilt = rest:VectorToWorldSpace(long).Y >= 0 and long or -long
	local inset = NEP.GripInset or 0.1
	local grip = hilt * (L / 2 - inset * L)
	h.fit = CFrame.fromMatrix(grip, hilt:Cross(width), hilt, width):Inverse()
	h.blade = L * (1 - inset)
end
local function fitScythe(h)
	local stick, side, _, L, Wd, Th = sortedAxes(sizeOf(h.e))
	local rest = h.home[3] * h.home[2]:Inverse()
	if rest:VectorToWorldSpace(stick).Y < 0 then
		stick = -stick
	end
	pcall(function()
		for _, o in ipairs(rawget(h.e, "p"):GetChildren()) do
			if o:IsA("Attachment") then
				if o.Position:Dot(side) > Wd * 0.12 then
					side = -side
				end
				break
			end
		end
	end)
	local grip = NEP.ScytheGrip or 0.2
	local m = CFrame.fromMatrix(Vector3.zero, stick:Cross(side), -stick, -side)
	h.fit = CF(0, -(0.5 - grip) * L, -math.max(Wd - Th, 0) / 2) * m:Inverse()
	h.blade = L * (1 - grip)
end
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
	h.fit = CF(L / 2 - 0.2, 0.11, 0) * m:Inverse()
	h.tip = CF(L - 0.2, 0.11 + 0.25 * Hh, 0)
	local known = hubHold(h.e)
	if known then
		h.fit, h.tip = known.fit, CF(known.tip)
	end
end
local function fitSlash(h)
	local long, _, thin = sortedAxes(sizeOf(h.e))
	h.fit = CFrame.fromMatrix(Vector3.zero, long, thin, long:Cross(thin)):Inverse()
end
local FITS = {sword = fitSword, scythe = fitScythe, gun = fitGun, revolver = fitGun, slash = fitSlash}
local function scanHats()
	local t = os.clock()
	local claimed = {}
	for _, h in ipairs(HATLIST) do
		if hatOk(h) then
			claimed[h.e] = true
		end
	end
	for _, h in ipairs(HATLIST) do
		if not hatOk(h) and t >= h.nextScan then
			h.nextScan = t + 0.5
			if h.e then
				restore(h)
			end
			h.e, h.j, h.home, h.fit = nil, nil, nil, nil
			local best, bestRank = nil, math.huge
			for e in pairs(fd.cframes) do
				if type(e) == "table" and rawget(e, "m") ~= nil and rawget(e, "p") and not claimed[e] then
					local r = hatRank(h, e)
					if r and r < bestRank and fd.getPartJoint(e) then
						best, bestRank = e, r
					end
				end
			end
			if best then
				local j = fd.getPartJoint(best)
				h.e, h.j, h.home = best, j, {j.Part1, j.C0, j.C1}
				claimed[best] = true
				if FITS[h.key] then
					pcall(FITS[h.key], h)
				end
			end
		end
	end
end
C.onStop(function()
	for _, h in ipairs(HATLIST) do
		restore(h)
	end
end)
local useHat = {sword = NEP.HatSword ~= false, gun = NEP.HatGun ~= false}
C.hatOn = function(k)
	return useHat[k]
end
C.toggleHat = function(k)
	if useHat[k] == nil then
		return
	end
	useHat[k] = not useHat[k]
	C.notify("Neptunian V", (k == "sword" and "hat sword " or "hat gun ") .. (useHat[k] and "on" or "off, the og one shows"), 2)
end
local function worn(a, b)
	if hatOk(a) and a.fit then
		return a
	end
	if b and hatOk(b) and b.fit then
		return b
	end
	return nil
end
local function swordHat()
	return useHat.sword and worn(H.sword, H.scythe) or nil
end
local function gunHat()
	return useHat.gun and worn(H.gun, H.revolver) or nil
end
local function glue(h, rel)
	local j = h.j
	if (h.key == "gun" or h.key == "revolver") and h.joinFor ~= h.e then
		h.joinFor = h.e
		h.unjoin = hubJoin(h.e)
	end
	h.glued = true
	j.Part1 = C.Root
	j.C0 = IDENT
	j.C1 = rel
end
C.alignHat = function(s)
	local h = nil
	if s == 1 then
		h = swordHat()
	elseif s == 2 or s == 3 then
		h = gunHat()
	elseif s == 4 then
		h = worn(H.slash)
	end
	local e = h and h.e or nil
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
	local function yn(h, k)
		if k and not useHat[k] then
			return "off"
		end
		return h and (accName(h.e) ~= "" and accName(h.e) or "yes") or "no"
	end
	return "Sword: " .. yn(swordHat(), "sword") .. " | Gun: " .. yn(gunHat(), "gun") .. " | Slash: " .. yn(worn(H.slash)) .. " | Bullet: " .. (hatOk(H.rock) and "golem rock" or "no")
end

local K, Pu, B, G, Wh = "Black", "Royal purple", "Bright blue", "Mid gray", "Institutional white"
local ME, NE, SP = Enum.Material.Metal, Enum.Material.Neon, Enum.Material.SmoothPlastic
local SWORD_PARTS = {
	{G, ME, "b", {0.275, 1.7351, 0.2804}, {0.35, 1.05, 0.5}, {0, 0, 0}, {0, 0, 0}},
	{K, ME, "w", {0.275, 0.228, 0.2134}, {0.57, 0.125, 0.375}, {0, 0, 0}, {0, -1.7666, -0.2977, -1, 0, 0, 0, 1, 0, 0, 0, -1}},
	{K, ME, "b", {0.275, 0.2141, 0.2054}, {0.57, 0.75, 0.75}, {0, 0, 0}, {0, -1.8625, -0.3412}},
	{K, ME, "w", {0.275, 0.228, 0.2134}, {0.57, 0.125, 0.375}, {0, 0, 0}, {0, -1.7666, -0.3691}},
	{K, ME, "w", {0.275, 0.252, 0.2134}, {0.57, 0.125, 0.375}, {0, 0, 0}, {0, -1.9541, -0.3691, -1, 0, 0, 0, -1, 0, 0, 0, 1}},
	{K, ME, "w", {0.275, 0.252, 0.2134}, {0.57, 0.125, 0.375}, {0, 0, 0}, {0, -1.9541, -0.2977, 1, 0, 0, 0, -1, 0, 0, 0, -1}},
	{Pu, NE, "w", {0.496, 0.2, 0.2804}, {1, 0.3, 0.5}, {0, 0, 0}, {-0.0313, -1.9618, 0.3556, 0, -1, 0, -0.7071, 0, 0.7071, -0.7071, 0, -0.7071}},
	{K, ME, "b", {0.275, 0.4131, 0.6224}, {0.4, 1.05, 0.5}, {0, 0, 0}, {0, -1.8253, 0.1745, -1, 0, 0, 0, -0.7071, -0.7071, 0, -0.7071, 0.7071}},
	{K, ME, "w", {0.275, 0.2041, 0.2874}, {0.5, 0.5, 0.5}, {0, 0, 0}, {0, -1.1671, 0.059, -1, 0, 0, 0, -1, 0, 0, 0, 1}},
	{K, ME, "b", {0.275, 0.2211, 0.4484}, {0.55, 1.05, 0.8}, {0, 0, 0}, {0, -2.3508, -0.103, -1, 0, 0, 0, -1, 0, 0, 0, 1}},
	{B, NE, "w", {0.275, 0.2, 0.2134}, {0.55, 0.25, 0.5}, {0, 0, 0}, {0, -1.7197, -0.4004}},
	{K, SP, "w", {0.275, 0.207, 0.3034}, {0.525, 0.5, 0.5}, {0, 0, 0}, {0, -2.0287, -0.2787, 1, 0, 0, 0, -1, 0, 0, 0, -1}},
	{K, SP, "w", {0.275, 0.207, 0.3034}, {0.525, 0.5, 0.5}, {0, 0, 0}, {0, -2.0287, -0.4194, -1, 0, 0, 0, -1, 0, 0, 0, 1}},
	{K, SP, "b", {0.275, 0.224, 0.3754}, {0.5, 0.7, 0.5}, {0, 0, 0}, {0, -2.1605, -0.5084, -1, 0, 0, 0, -1, 0, 0, 0, 1}},
	{Pu, NE, "w", {0.405, 0.2, 0.2804}, {1, 0.3, 0.5}, {0, 0, 0}, {0.0313, -2.1094, -0.934, 0, 1, 0, -0.866, 0, 0.5, 0.5, 0, 0.866}},
	{K, ME, "b", {0.275, 0.2031, 0.2344}, {0.5, 0.5025, 0.4}, {0, 0, 0}, {0, 1.1089, 0.0585, -1, 0, 0, 0, 0.9848, -0.1736, 0, -0.1736, -0.9848}},
	{K, ME, "b", {0.275, 0.4091, 0.3604}, {0.35, 1, 1}, {0, 0, 0}, {0, -1.8185, -0.7498, 1, 0, 0, 0, 0.9659, -0.2588, 0, 0.2588, 0.9659}},
	{K, SP, "w", {0.275, 0.2, 0.3034}, {0.525, 0.5, 0.5}, {0, 0, 0}, {0, -1.6885, -0.4194}},
	{B, NE, "w", {0.275, 0.207, 0.2134}, {0.55, 0.25, 0.5}, {0, 0, 0}, {0, -1.9975, -0.4004, -1, 0, 0, 0, -1, 0, 0, 0, 1}},
	{K, ME, "b", {0.275, 0.4375, 0.25}, {0.5, 1, 0.25}, {0, 0, 0}, {0, 1.4912, -0.1147, 1, 0, 0, 0, 0.8387, -0.5446, 0, 0.5446, 0.8387}},
	{Pu, NE, "w", {0.405, 0.2, 0.2804}, {1, 0.3, 0.5}, {0, 0, 0}, {-0.0312, -2.1094, -0.934, 0, -1, 0, 0.866, 0, 0.5, -0.5, 0, 0.866}},
	{K, ME, "b", {0.275, 0.4091, 0.2684}, {0.35, 1, 1}, {0, 0, 0}, {0, -2.4261, -0.5489, 1, 0, 0, 0, 0.866, 0.5, 0, -0.5, 0.866}},
	{K, ME, "c", {0.275, 0.6981, 0.3724}, {0.455, 1, 1}, {0, 0, 0}, {0, -1.5145, 0.0117}},
	{K, SP, "w", {0.275, 0.2, 0.3034}, {0.525, 0.5, 0.5}, {0, 0, 0}, {0, -1.6885, -0.2787, -1, 0, 0, 0, 1, 0, 0, 0, -1}},
	{B, NE, "b", {0.275, 0.3301, 0.2144}, {0.45, 1, 0.1}, {0, 0, 0}, {0, -2.9871, -0.0055, -1, 0, 0, 0, 0.9222, 0.3867, 0, 0.3867, -0.9222}},
	{K, ME, "w", {0.275, 0.2, 0.3034}, {0.5, 0.5, 0.5}, {0, 0, 0}, {0, -1.2041, -0.1381, -1, 0, 0, 0, 1, 0, 0, 0, -1}},
	{Pu, NE, "w", {0.496, 0.2, 0.2804}, {1, 0.3, 0.5}, {0, 0, 0}, {0.0313, -1.9618, 0.3556, 0, 1, 0, 0.7071, 0, 0.7071, 0.7071, 0, -0.7071}},
	{Pu, NE, "w", {0.496, 0.2, 0.2804}, {1, 0.3, 0.5}, {0, 0, 0}, {-0.0312, -1.0575, 0.3556, 0, -1, 0, -0.7071, 0, -0.7071, 0.7071, 0, -0.7071}},
	{K, ME, "w", {0.275, 0.2, 0.3034}, {0.5, 0.5, 0.5}, {0, 0, 0}, {0, -1.2041, -0.2787}},
	{K, ME, "b", {0.275, 0.7451, 0.2804}, {0.4, 1.05, 0.5}, {0, 0, 0}, {0, -0.3025, -0.0938}},
	{K, ME, "b", {0.275, 0.4151, 0.2344}, {0.5, 1.05, 0.4}, {0, 0, 0}, {0, 0.66, -0.1351}},
	{K, ME, "w", {0.275, 0.6301, 0.2804}, {0.395, 0.75, 0.25}, {0, 0, 0}, {0, -1.2536, -0.3929}},
	{K, ME, "b", {0.275, 0.2481, 0.3114}, {0.4, 1.05, 0.5}, {0, 0, 0}, {0, -0.955, -0.1408}},
	{K, ME, "w", {0.26, 0.375, 0.2188}, {0.3, 1, 1}, {0, 0, 0}, {0, 1.5082, -0.1253}},
	{K, ME, "w", {0.275, 0.3551, 0.2834}, {0.4, 0.56, 0.5}, {0, 0, 0}, {0, -0.913, -0.282}},
	{K, ME, "b", {0.275, 0.2031, 0.2344}, {0.5, 1.05, 0.4}, {0, 0, 0}, {0, 0.7654, -0.1575, 1, 0, 0, 0, 0.9848, 0.1736, 0, -0.1736, 0.9848}},
	{K, ME, "w", {0.275, 0.3551, 0.4164}, {0.5, 0.56, 0.5}, {0, 0, 0}, {0, -0.5224, -0.125}},
	{Pu, NE, "w", {0.496, 0.2, 0.2804}, {1, 0.3, 0.5}, {0, 0, 0}, {0.0313, -1.0575, 0.3556, 0, 1, 0, 0.7071, 0, -0.7071, -0.7071, 0, -0.7071}},
	{Pu, NE, "w", {0.643, 0.2, 0.2804}, {1, 0.3, 0.5}, {0, 0, 0}, {0.0313, -1.5145, 0.5117, 0, 1, 0, 1, 0, 0, 0, 0, -1}},
	{K, ME, "b", {0.275, 0.5411, 0.3674}, {0.5, 1.05, 0.6}, {0, 0, 0}, {0, -1.7921, 0.0442, -1, 0, 0, 0, -1, 0, 0, 0, 1}},
	{K, ME, "b", {0.275, 0.6301, 0.2804}, {0.4, 1.05, 0.5}, {0, 0, 0}, {0, 0.5525, -0.0938}},
	{G, ME, "b", {0.275, 0.2161, 0.2804}, {0.35, 1.05, 0.5}, {0, 0, 0}, {0, -0.8662, 0.0317, 1, 0, 0, 0, 0.7071, 0.7071, 0, -0.7071, 0.7071}},
	{K, ME, "b", {0.275, 0.3091, 0.3434}, {0.35, 1, 1}, {0, 0, 0}, {0, -2.0393, -0.729, 1, 0, 0, 0, 0.866, 0.5, 0, -0.5, 0.866}},
	{K, ME, "b", {0.275, 0.9981, 0.2804}, {0.4, 1.05, 0.5}, {0, 0, 0}, {0, -0.429, -0.0938}},
	{K, ME, "w", {0.275, 0.4051, 0.2114}, {0.5, 0.56, 0.5}, {0, 0, 0}, {0, -0.4466, -0.0735}},
	{K, ME, "b", {0.275, 0.4131, 0.6224}, {0.4, 1.05, 0.5}, {0, 0, 0}, {0, -1.1941, 0.1745, 1, 0, 0, 0, 0.7071, 0.7071, 0, -0.7071, 0.7071}},
	{Pu, NE, "c", {0.275, 0.3201, 0.3164}, {0.4575, 1, 1}, {0, 0, 0}, {0, -1.5145, 0.0117}},
	{K, ME, "w", {0.275, 0.3221, 0.3634}, {0.5, 1, 1}, {0, 0, 0}, {0, -0.9604, 0.0574, -1, 0, 0, 0, 1, 0, 0, 0, -1}},
	{K, ME, "b", {0.275, 0.5141, 0.6224}, {0.4, 1.05, 0.5}, {0, 0, 0}, {0, -1.5145, 0.2871}},
	{K, ME, "w", {0.275, 0.2041, 0.2104}, {0.5, 0.5, 0.5}, {0, 0, 0}, {0, -1.1202, -0.0676, 1, 0, 0, 0, -1, 0, 0, 0, -1}},
	{B, NE, "b", {0.275, 0.2611, 0.2454}, {0.375, 1.05, 0.5}, {0, 0, 0}, {0, 0.202, -0.0983}},
	{K, ME, "w", {0.275, 0.2061, 0.2804}, {0.4, 0.56, 0.5}, {0, 0, 0}, {0, 0.1374, -0.0938}},
	{K, ME, "b", {0.275, 0.5781, 0.2344}, {0.5, 1.05, 0.4}, {0, 0, 0}, {0, 1.2972, 0.0232, -1, 0, 0, 0, 1, 0, 0, 0, -1}},
	{K, ME, "w", {0.26, 0.2255, 0.2101}, {0.5, 1, 1}, {0, 0, 0}, {0.0017, 0.7467, -0.0056, 1, 0, 0, 0, -1, 0, 0, 0, -1}},
	{K, ME, "w", {0.275, 0.2141, 0.2344}, {0.5, 0.56, 0.4}, {0, 0, 0}, {0, 0.382, -0.1351, 1, 0, 0, 0, -1, 0, 0, 0, -1}},
	{K, ME, "w", {0.27, 0.2188, 0.2344}, {0.5, 0.5, 0.5}, {0, 0, 0}, {0, 1.6488, 0.0388, -1, 0, 0, 0, 1, 0, 0, 0, -1}},
	{B, NE, "b", {0.2, 0.4495, 0.2366}, {0.5, 1, 0.25}, {0, 0, 0}, {0, 1.1297, -0.2217, 1, 0, 0, 0, 0.9659, 0.2588, 0, -0.2588, 0.9659}},
	{B, NE, "b", {0.2, 0.4688, 0.221}, {0.5, 1, 0.25}, {0, 0, 0}, {0, 1.5004, -0.1576, 1, 0, 0, 0, 0.8387, -0.5446, 0, 0.5446, 0.8387}},
	{B, NE, "b", {0.275, 0.3521, 0.2144}, {0.45, 0.5, 0.1}, {0, 0, 0}, {0, -4.9781, 0.1382, -1, 0, 0, 0, 0.3173, -0.9483, 0, -0.9483, -0.3173}},
	{Pu, NE, "w", {0.288, 0.2, 0.2784}, {1, 0.3, 0.5}, {0, 0, 0}, {-0.0312, -3.0827, -0.3571, 0, -1, 0, 0.932, 0, -0.3624, 0.3624, 0, 0.932}},
	{Pu, NE, "b", {0.2, 0.217, 0.2004}, {0.56, 0.2, 0.6}, {0, 0, 0}, {0, -3.5333, 0.1852, -1, 0, 0, 0, -0.9222, -0.3867, 0, -0.3867, 0.9222}},
	{Pu, NE, "w", {0.49, 0.2, 0.2904}, {1, 0.3, 0.5}, {0, 0, 0}, {-0.0312, -2.7432, -0.323, 0, -1, 0, 0.9999, 0, 0.0131, -0.0131, 0, 0.9999}},
	{B, NE, "b", {0.275, 0.2471, 0.2144}, {0.45, 0.6, 0.1}, {0, 0, 0}, {0, -5.5748, 0.1909, -1, 0, 0, 0, 0.7009, 0.7133, 0, 0.7133, -0.7009}},
	{B, NE, "b", {0.275, 0.6211, 0.2144}, {0.45, 1, 0.1}, {0, 0, 0}, {0, -3.4454, -0.0596, -1, 0, 0, 0, 0.9984, -0.0567, 0, -0.0567, -0.9984}},
	{Pu, NE, "w", {0.94, 0.2, 0.2854}, {1, 0.3, 0.5}, {0, 0, 0}, {0.0313, -6.8847, 0.1742, 0, 1, 0, -0.7193, 0, 0.6947, 0.6947, 0, 0.7193}},
	{K, ME, "b", {0.275, 0.8451, 0.4224}, {0.4, 1, 0.5}, {0, 0, 0}, {0, -3.2564, 0.005, -1, 0, 0, 0, 1, 0, 0, 0, -1}},
	{B, NE, "b", {0.275, 1.0461, 0.2144}, {0.45, 0.9, 0.1}, {0, 0, 0}, {0, -6.0967, 0.2049, -1, 0, 0, 0, 0.9936, -0.1132, 0, -0.1132, -0.9936}},
	{Pu, NE, "w", {0.49, 0.2, 0.2904}, {1, 0.3, 0.5}, {0, 0, 0}, {0.0313, -2.7432, -0.323, 0, 1, 0, -0.9999, 0, 0.0131, 0.0131, 0, 0.9999}},
	{K, ME, "b", {0.275, 1.4601, 0.4224}, {0.4, 1, 0.5}, {0, 0, 0}, {0, -5.8725, 0.1705, -1, 0, 0, 0, 0.9936, -0.1132, 0, -0.1132, -0.9936}},
	{Pu, NE, "w", {0.21, 0.2, 0.2854}, {0.5, 0.3, 0.5}, {0, 0, 0}, {0.0313, -7.2109, 0.5046, 0, 1, 0, -0.0175, 0, 0.9998, 0.9998, 0, 0.0175}},
	{Pu, NE, "w", {1.785, 0.2, 0.3014}, {1, 0.3, 0.5}, {0, 0, 0}, {-0.0312, -5.6956, -0.2204, 0, -1, 0, 0.9945, 0, 0.1045, -0.1045, 0, 0.9945}},
	{B, NE, "b", {0.275, 0.6781, 0.2144}, {0.45, 0.8, 0.1}, {0, 0, 0}, {0, -5.2659, 0.2255, -1, 0, 0, 0, 0.9984, -0.0567, 0, -0.0567, -0.9984}},
	{Pu, NE, "w", {0.21, 0.2, 0.2854}, {0.5, 0.3, 0.5}, {0, 0, 0}, {-0.0312, -7.2109, 0.5046, 0, -1, 0, 0.0175, 0, 0.9998, -0.9998, 0, 0.0175}},
	{B, NE, "b", {0.275, 0.4701, 0.2144}, {0.45, 0.7, 0.1}, {0, 0, 0}, {0, -6.6673, 0.3724, -1, 0, 0, 0, 0.7009, -0.7132, 0, -0.7132, -0.7009}},
	{Pu, NE, "w", {0.288, 0.2, 0.2784}, {1, 0.3, 0.5}, {0, 0, 0}, {0.0313, -3.0827, -0.3571, 0, 1, 0, -0.932, 0, -0.3624, -0.3624, 0, 0.932}},
	{B, NE, "b", {0.275, 0.5331, 0.2144}, {0.45, 0.9, 0.1}, {0, 0, 0}, {0, -4.1025, 0.1289, -1, 0, 0, 0, 0.9984, -0.0567, 0, -0.0567, -0.9984}},
	{Pu, NE, "b", {0.2, 0.217, 0.2004}, {0.56, 0.2, 0.6}, {0, 0, 0}, {0, -3.6895, 0.1852, -1, 0, 0, 0, -0.9222, -0.3867, 0, -0.3867, 0.9222}},
	{K, ME, "b", {0.275, 0.2351, 1.6694}, {0.4, 1.05, 1}, {0, 0, 0}, {0, -5.6932, -0.0292, 1, 0, 0, 0, -0.1132, 0.9936, 0, -0.9936, -0.1132}},
	{B, NE, "b", {0.275, 0.4801, 0.2144}, {0.45, 1, 0.1}, {0, 0, 0}, {0, -2.606, 0.0516, -1, 0, 0, 0, 1, 0, 0, 0, -1}},
	{K, ME, "b", {0.275, 0.2351, 1.6694}, {0.4, 1.05, 1}, {0, 0, 0}, {0, -4.045, -0.1705, 1, 0, 0, 0, -0.0567, 0.9984, 0, -0.9984, -0.0567}},
	{B, NE, "b", {0.275, 0.2371, 0.2144}, {0.45, 0.8, 0.1}, {0, 0, 0}, {0, -3.8141, 0.0424, -1, 0, 0, 0, 0.57, -0.8216, 0, -0.8216, -0.57}},
	{K, ME, "b", {0.275, 1.6571, 0.3594}, {0.4, 1, 0.5}, {0, 0, 0}, {0, -4.3953, 0.2181, -1, 0, 0, 0, 0.9984, -0.0567, 0, -0.0567, -0.9984}},
	{K, ME, "b", {0.275, 0.4881, 0.3594}, {0.4, 1, 0.5}, {0, 0, 0}, {0, -2.6131, 0.2013, -1, 0, 0, 0, 0.9936, 0.1132, 0, 0.1132, -0.9936}},
	{K, ME, "b", {0.275, 0.2211, 0.6554}, {0.4, 1.05, 0.9}, {0, 0, 0}, {0, -3.0047, -0.1302, 1, 0, 0, 0, 0.3827, 0.9239, 0, -0.9239, 0.3827}},
	{Pu, NE, "b", {0.2, 0.217, 0.2004}, {0.56, 0.2, 0.6}, {0, 0, 0}, {0, -3.7677, 0.1852, -1, 0, 0, 0, -0.9222, -0.3867, 0, -0.3867, 0.9222}},
	{K, ME, "b", {0.275, 0.4881, 0.4184}, {0.4, 1, 0.9}, {0, 0, 0}, {0, -2.61, -0.0504, -1, 0, 0, 0, 1, 0, 0, 0, -1}},
	{Pu, NE, "b", {0.2, 0.217, 0.2004}, {0.56, 0.2, 0.6}, {0, 0, 0}, {0, -3.6114, 0.1852, -1, 0, 0, 0, -0.9222, -0.3867, 0, -0.3867, 0.9222}},
	{B, NE, "b", {0.275, 0.2651, 0.2144}, {0.45, 0.9, 0.1}, {0, 0, 0}, {0, -4.4394, 0.074, -1, 0, 0, 0, 0.8434, 0.5373, 0, 0.5373, -0.8434}},
	{K, ME, "b", {0.275, 0.6181, 0.2094}, {0.4, 1, 0.9}, {0, 0, 0}, {0, -2.675, -0.1549, -1, 0, 0, 0, 1, 0, 0, 0, -1}},
	{K, ME, "b", {0.275, 0.4841, 0.2274}, {0.35, 0.3, 1}, {0, 0, 0}, {0, -2.5714, -0.3667, 1, 0, 0, 0, 0.7071, -0.7071, 0, 0.7071, 0.7071}},
	{B, NE, "b", {0.275, 0.4541, 0.2144}, {0.45, 0.9, 0.1}, {0, 0, 0}, {0, -4.752, 0.0378, -1, 0, 0, 0, 0.9936, -0.1132, 0, -0.1132, -0.9936}},
	{K, ME, "b", {0.275, 1.6571, 0.4224}, {0.4, 1, 0.5}, {0, 0, 0}, {0, -4.4051, 0.0439, -1, 0, 0, 0, 0.9984, -0.0567, 0, -0.0567, -0.9984}},
	{K, ME, "w", {0.275, 0.4461, 0.4964}, {0.4, 1, 0.9}, {0, 0, 0}, {0, -6.9311, 0.3131, 1, 0, 0, 0, 0, 1, 0, -1, 0}},
	{Pu, NE, "w", {0.422, 0.2, 0.2804}, {1, 0.3, 0.5}, {0, 0, 0}, {0.0313, -1.4221, -0.7823, 0, 1, 0, -0.7071, 0, -0.7071, -0.7071, 0, 0.7071}},
	{K, SP, "b", {0.275, 0.2771, 0.7024}, {0.55, 0.5, 0.8}, {0, 0, 0}, {0, -2.4478, -0.103, -1, 0, 0, 0, -1, 0, 0, 0, 1}},
	{K, ME, "b", {0.275, 0.4221, 0.4124}, {0.5, 1.05, 0.5}, {0, 0, 0}, {0, -1.7458, 0.0842, -1, 0, 0, 0, -0.9659, 0.2588, 0, 0.2588, 0.9659}},
	{K, ME, "w", {0.275, 0.207, 0.3034}, {0.5, 0.5, 0.5}, {0, 0, 0}, {0, -1.7006, -0.2787, -1, 0, 0, 0, -1, 0, 0, 0, 1}},
	{Pu, NE, "w", {0.422, 0.2, 0.2804}, {1, 0.3, 0.5}, {0, 0, 0}, {-0.0312, -1.4221, -0.7823, 0, -1, 0, 0.7071, 0, -0.7071, 0.7071, 0, 0.7071}},
	{Pu, NE, "b", {0.275, 0.2041, 0.4644}, {0.525, 1.05, 0.8}, {0, 0, 0}, {0, -2.2759, -0.103, -1, 0, 0, 0, -1, 0, 0, 0, 1}},
	{K, SP, "w", {0.275, 0.233, 0.2954}, {0.5, 1, 0.25}, {0, 0, 0}, {0, -2.2782, -0.5376, 1, 0, 0, 0, 0, 1, 0, -1, 0}},
	{K, ME, "b", {0.275, 0.2211, 0.4184}, {0.55, 1.05, 0.9}, {0, 0, 0}, {0, -2.5737, -0.0402, 1, 0, 0, 0, 0.7071, 0.7071, 0, -0.7071, 0.7071}},
	{Wh, ME, "w", {0.275, 0.2001, 0.2874}, {0.56, 1, 0.9}, {0, 0, 0}, {0, -2.4678, -0.201, 1, 0, 0, 0, 0, 1, 0, -1, 0}},
	{K, SP, "w", {0.275, 0.217, 0.2954}, {0.5, 0.75, 0.25}, {0, 0, 0}, {0, -2.4657, -0.4282, 1, 0, 0, 0, 0, 1, 0, -1, 0}},
	{K, ME, "b", {0.275, 0.2211, 0.4184}, {0.55, 1.05, 0.9}, {0, 0, 0}, {0, -2.5737, -0.1629, -1, 0, 0, 0, 0.7071, 0.7071, 0, 0.7071, -0.7071}},
	{K, ME, "w", {0.275, 0.207, 0.3034}, {0.5, 0.5, 0.5}, {0, 0, 0}, {0, -1.7006, -0.1381, 1, 0, 0, 0, -1, 0, 0, 0, -1}},
	{K, ME, "b", {0.275, 0.3311, 0.4124}, {0.5, 1.05, 0.5}, {0, 0, 0}, {0, -2.0412, 0.0452, -1, 0, 0, 0, -0.7071, -0.7071, 0, -0.7071, 0.7071}},
	{K, ME, "b", {0.275, 0.7091, 0.4744}, {0.5, 1.05, 0.8}, {0, 0, 0}, {0, -1.8761, -0.1968, -1, 0, 0, 0, -1, 0, 0, 0, 1}},
	{K, ME, "b", {0.275, 0.2771, 0.2274}, {0.35, 0.3, 1}, {0, 0, 0}, {0, -2.6474, -0.4366, 1, 0, 0, 0, 0.866, -0.5, 0, 0.5, 0.866}},
	{Wh, ME, "w", {0.275, 0.2001, 0.2874}, {0.56, 1, 0.9}, {0, 0, 0}, {0, -2.4678, -0.0069, -1, 0, 0, 0, 0, 1, 0, 1, 0}},
	{K, ME, "b", {0.275, 0.8451, 0.3594}, {0.35, 1, 0.5}, {0, 0, 0}, {0, -3.2564, 0.1795, -1, 0, 0, 0, 1, 0, 0, 0, -1}},
	{Pu, NE, "w", {0.453, 0.2, 0.2804}, {1, 0.3, 0.5}, {0, 0, 0}, {-0.0312, -1.7635, -0.973, 0, -1, 0, 0.9659, 0, -0.2588, 0.2588, 0, 0.9659}},
	{Pu, NE, "w", {0.453, 0.2, 0.2804}, {1, 0.3, 0.5}, {0, 0, 0}, {0.0313, -1.7635, -0.973, 0, 1, 0, -0.9659, 0, -0.2588, -0.2588, 0, 0.9659}},
	{K, ME, "w", {0.26, 0.3125, 0.3201}, {0.5, 1, 1}, {0, 0, 0}, {0.0017, 1.0167, -0.0666}},
	{K, ME, "c", {0.275, 0.6981, 0.7324}, {0.425, 1, 1}, {0, 0, 0}, {0, -1.5145, 0.0117}},
	{B, SP, "c", {0.275, 0.6981, 0.5344}, {0.4525, 1, 1}, {0, 0, 0}, {0, -1.5145, 0.0117}},
	{K, SP, "w", {0.275, 0.3681, 0.3784}, {0.4, 1, 1}, {0, 0, 0}, {0, -1.4937, -0.5095}},
	{K, ME, "b", {0.275, 0.5671, 0.3114}, {0.4, 1.05, 0.5}, {0, 0, 0}, {0, -0.9945, -0.1408}},
	{K, ME, "b", {0.275, 0.4183, 0.25}, {0.5, 1, 0.25}, {0, 0, 0}, {0, 1.1272, -0.1705, 1, 0, 0, 0, 0.9659, 0.2588, 0, -0.2588, 0.9659}},
	{K, ME, "b", {0.275, 0.4031, 0.3524}, {0.35, 1, 1}, {0, 0, 0}, {0, -1.5934, -0.6022, 1, 0, 0, 0, 0.7071, -0.7071, 0, 0.7071, 0.7071}},
	{Pu, NE, "w", {1.625, 0.2, 0.2964}, {1, 0.3, 0.5}, {0, 0, 0}, {-0.0312, -4.0009, -0.3604, 0, -1, 0, 0.9986, 0, 0.0523, -0.0523, 0, 0.9986}},
	{Pu, NE, "w", {0.94, 0.2, 0.2854}, {1, 0.3, 0.5}, {0, 0, 0}, {-0.0312, -6.8847, 0.1742, 0, -1, 0, 0.7193, 0, 0.6947, -0.6947, 0, 0.7193}},
	{Pu, NE, "w", {1.625, 0.2, 0.2964}, {1, 0.3, 0.5}, {0, 0, 0}, {0.0313, -4.0009, -0.3604, 0, 1, 0, -0.9986, 0, 0.0523, 0.0523, 0, 0.9986}},
	{K, ME, "b", {0.275, 1.6621, 0.3594}, {0.4, 1, 0.5}, {0, 0, 0}, {0, -5.9531, 0.3554, -1, 0, 0, 0, 0.9936, -0.1132, 0, -0.1132, -0.9936}},
	{Pu, NE, "w", {1.785, 0.2, 0.3014}, {1, 0.3, 0.5}, {0, 0, 0}, {0.0313, -5.6956, -0.2204, 0, 1, 0, -0.9945, 0, 0.1045, 0.1045, 0, 0.9945}},
	{K, ME, "w", {0.275, 0.2041, 0.2074}, {0.5, 0.5, 0.5}, {0, 0, 0}, {0, -1.1671, 0.1752, 1, 0, 0, 0, -1, 0, 0, 0, -1}},
	{K, ME, "b", {0.275, 0.2231, 0.2344}, {0.5, 1, 0.4}, {0, 0, 0}, {0, 0.9626, 0.0594, -1, 0, 0, 0, 0.9962, 0.0872, 0, 0.0872, -0.9962}},
	{K, ME, "w", {0.275, 0.2441, 0.4164}, {0.5, 0.56, 0.5}, {0, 0, 0}, {0, -0.687, -0.125, 1, 0, 0, 0, -1, 0, 0, 0, -1}},
	{K, ME, "w", {0.275, 0.2061, 0.2804}, {0.4, 0.56, 0.5}, {0, 0, 0}, {0, 0.1686, -0.0938, 1, 0, 0, 0, -1, 0, 0, 0, -1}},
	{K, ME, "b", {0.275, 0.3981, 0.3034}, {0.5, 1, 1}, {0, 0, 0}, {0, -1.4541, -0.2006}},
	{B, NE, "b", {0.275, 0.2391, 0.2054}, {0.55, 1, 1}, {0, 0, 0}, {0, -1.856, -0.3412}},
	{B, NE, "c", {0.275, 0.6981, 0.5344}, {0.4525, 1, 1}, {0, 0, 0}, {0, -1.5145, 0.0117}},
	{K, SP, "w", {0.275, 0.316, 0.3104}, {0.5, 1, 0.5}, {0, 0, 0}, {0, -2.0832, -0.5791, -1, 0, 0, 0, 1, 0, 0, 0, -1}},
	{Pu, NE, "w", {0.496, 0.2, 0.2804}, {1, 0.3, 0.5}, {0, 0, 0}, {0.0313, -1.0575, 0.3556, 0, 1, 0, 0.7071, 0, -0.7071, -0.7071, 0, -0.7071}},
	{B, NE, "w", {0.275, 0.207, 0.2134}, {0.55, 0.25, 0.5}, {0, 0, 0}, {0, -1.9975, -0.2977, 1, 0, 0, 0, -1, 0, 0, 0, -1}},
	{K, ME, "b", {0.275, 0.3111, 0.2674}, {0.495, 1, 1}, {0, 0, 0}, {0, -1.9439, -0.475, -1, 0, 0, 0, -1, 0, 0, 0, 1}},
	{B, NE, "w", {0.275, 0.2, 0.2134}, {0.55, 0.25, 0.5}, {0, 0, 0}, {0, -1.7197, -0.2977, -1, 0, 0, 0, 1, 0, 0, 0, -1}},
	{Pu, NE, "w", {0.643, 0.2, 0.2804}, {1, 0.3, 0.5}, {0, 0, 0}, {0.0313, -1.5145, 0.5117, 0, 1, 0, 1, 0, 0, 0, 0, -1}},
	{Pu, NE, "w", {0.496, 0.2, 0.2804}, {1, 0.3, 0.5}, {0, 0, 0}, {-0.0313, -1.9618, 0.3556, 0, -1, 0, -0.7071, 0, 0.7071, -0.7071, 0, -0.7071}},
	{Pu, NE, "w", {0.643, 0.2, 0.2804}, {1, 0.3, 0.5}, {0, 0, 0}, {-0.0312, -1.5145, 0.5117, 0, -1, 0, -1, 0, 0, 0, 0, -1}},
	{K, ME, "b", {0.275, 0.5771, 0.3034}, {0.4, 0.87, 0.5}, {0, 0, 0}, {0, -1.2624, -0.2787}},
	{K, ME, "w", {0.275, 0.3041, 0.2674}, {0.495, 1, 1}, {0, 0, 0}, {0, -1.6404, -0.475}},
	{K, SP, "b", {0.275, 0.3301, 0.2264}, {0.4, 1, 1}, {0, 0, 0}, {0, -1.8409, -0.5855}},
	{K, ME, "w", {0.26, 0.5781, 0.2188}, {0.3, 1, 1}, {0, 0, 0}, {0.0017, 1.0402, -0.1253, -1, 0, 0, 0, -1, 0, 0, 0, 1}},
	{K, SP, "b", {0.275, 0.2391, 0.3034}, {0.525, 1, 1}, {0, 0, 0}, {0, -1.856, -0.3412}},
	{Pu, NE, "w", {0.423, 0.2, 0.2804}, {1, 0.3, 0.5}, {0, 0, 0}, {-0.0312, -2.5153, -0.6996, 0, -1, 0, 0.866, 0, 0.5, -0.5, 0, 0.866}},
	{Pu, NE, "b", {0.275, 0.2371, 0.3754}, {0.525, 1.05, 0.8}, {0, 0, 0}, {0, -2.3366, -0.1942, -1, 0, 0, 0, -0.9239, -0.3827, 0, -0.3827, 0.9239}},
	{K, SP, "b", {0.275, 0.411, 0.4694}, {0.5, 0.85, 0.7}, {0, 0, 0}, {0, -2.254, -0.3504, -1, 0, 0, 0, -1, 0, 0, 0, 1}},
	{Pu, NE, "w", {0.293, 0.2, 0.2804}, {1, 0.3, 0.5}, {0, 0, 0}, {-0.0312, -2.7339, -0.5045, 0, -1, 0, 0.5, 0, 0.866, -0.866, 0, 0.5}},
	{K, SP, "w", {0.275, 0.316, 0.3034}, {0.5, 1, 0.5}, {0, 0, 0}, {0, -2.0832, -0.7319, -1, 0, 0, 0, -1, 0, 0, 0, 1}},
	{K, SP, "c", {0.275, 0.6981, 0.6384}, {0.45, 1, 1}, {0, 0, 0}, {0, -1.5145, 0.0117}},
	{Pu, NE, "w", {0.293, 0.2, 0.2804}, {1, 0.3, 0.5}, {0, 0, 0}, {0.0313, -2.7339, -0.5045, 0, 1, 0, -0.5, 0, 0.866, 0.866, 0, 0.5}},
	{Pu, NE, "b", {0.275, 0.2381, 0.3814}, {0.525, 1.05, 0.8}, {0, 0, 0}, {0, -2.3474, -0.0105, 1, 0, 0, 0, -0.9239, -0.3827, 0, 0.3827, -0.9239}},
	{K, ME, "b", {0.275, 0.2351, 0.5864}, {0.4, 1.05, 1}, {0, 0, 0}, {0, -6.6683, 0.2315, 1, 0, 0, 0, -0.7132, 0.7009, 0, -0.7009, -0.7132}},
	{K, ME, "b", {0.275, 0.2812, 0.2344}, {0.5, 1.05, 0.4}, {0, 0, 0}, {0, 1.4613, 0.0232, -1, 0, 0, 0, 0.9848, 0.1736, 0, 0.1736, -0.9848}},
	{Pu, NE, "w", {0.423, 0.2, 0.2804}, {1, 0.3, 0.5}, {0, 0, 0}, {0.0313, -2.5153, -0.6996, 0, 1, 0, -0.866, 0, 0.5, 0.5, 0, 0.866}},
	{K, ME, "b", {0.275, 0.2871, 0.2274}, {0.35, 1, 1}, {0, 0, 0}, {0, -2.5265, -0.4481}},
	{K, ME, "b", {0.275, 0.2251, 0.4234}, {0.4, 1, 0.5}, {0, 0, 0}, {0, -2.349, 0.227, -1, 0, 0, 0, 0.96, 0.2798, 0, 0.2798, -0.96}},
	{K, ME, "b", {0.275, 0.2211, 0.4084}, {0.55, 1.05, 0.8}, {0, 0, 0}, {0, -2.3875, -0.1494, -1, 0, 0, 0, -0.9659, -0.2588, 0, -0.2588, 0.9659}},
	{K, ME, "b", {0.275, 0.2211, 0.4084}, {0.55, 1.05, 0.8}, {0, 0, 0}, {0, -2.3875, -0.0556, 1, 0, 0, 0, -0.9659, -0.2588, 0, 0.2588, -0.9659}},
}
local GAUNTLET_PARTS = {
	{K, SP, {1.1, 0.4, 1.1}, {0, -0.45, 0}}, {Pu, NE, {1.075, 0.45, 1.075}, {0, -0.45, 0}}, {K, SP, {1.05, 0.485, 1.05}, {0, -0.45, 0}},
	{K, SP, {1.2, 0.5, 0.5}, {-0.05, -0.45, 0}}, {B, NE, {1.185, 0.525, 0.525}, {-0.05, -0.45, 0}}, {K, SP, {1.15, 0.585, 0.585}, {-0.05, -0.45, 0}},
	{B, NE, {1, 0.35, 0.35}, {0.075, -0.45, 0}}, {B, NE, {0.65, 0.05, 1.15}, {-0.15, -0.365, 0}}, {B, NE, {0.65, 0.05, 1.15}, {-0.15, -0.465, 0}},
	{B, NE, {0.65, 0.05, 1.15}, {-0.15, -0.565, 0}}, {Pu, NE, {0.25, 0.25, 1.15}, {0.35, -0.45, 0}},
}
local GUN_PARTS = {
	{K, SP, {0.75, 0.4, 0.4}, {0.1, -1, 0}}, {K, SP, {0.45, 1, 0.45}, {0.35, -1.5, 0}}, {Pu, NE, {0.375, 0.965, 0.375}, {0.35, -1.55, 0}},
	{K, SP, {0.385, 0.535, 0.4625}, {0.415, -1.5, 0}}, {B, NE, {0.325, 0.585, 0.455}, {0.415, -1.5, 0}}, {K, SP, {0.325, 1.5, 0.325}, {0.35, -2.25, 0}},
	{"Really black", SP, {0.25, 0.25, 0.25}, {0.35, -2.9, 0}},
}
local function buildParts(list, name, sword)
	local out = {}
	for i, d in ipairs(list) do
		local p = C.newPart({Name = name, Transparency = 1, CFrame = CF(0, -4000, 0), Color = BrickColor.new(d[1]).Color, Material = d[2]})
		if sword then
			p.Size = VT(d[4][1], d[4][2], d[4][3])
			local m = inst("SpecialMesh", p)
			m.MeshType = d[3] == "w" and Enum.MeshType.Wedge or (d[3] == "c" and Enum.MeshType.Cylinder or Enum.MeshType.Brick)
			m.Scale = VT(d[5][1], d[5][2], d[5][3])
			m.Offset = VT(d[6][1], d[6][2], d[6][3])
			local o = d[7]
			out[i] = {p = p, off = #o == 3 and CF(o[1], o[2], o[3]) or CF(table.unpack(o))}
		else
			p.Size = VT(1, 1, 1)
			inst("SpecialMesh", p, {MeshType = Enum.MeshType.Brick, Scale = VT(d[3][1], d[3][2], d[3][3])})
			out[i] = {p = p, off = CF(d[4][1], d[4][2], d[4][3])}
		end
	end
	return out
end
local CL = {sword = buildParts(SWORD_PARTS, "SwordPart", true), gun = buildParts(GUN_PARTS, "GunPart"), gauntlet = buildParts(GAUNTLET_PARTS, "GauntletPart")}
local shown = {}
local function clientOn(h)
	local c = NEP.ClientWeapons
	return c == true or (c == "auto" and h == nil)
end

local HITSOUNDS = {199149137, 199149186, 199149221, 199149235, 199149269, 199149297}
local victims = setmetatable({}, {__mode = "k"})
local npcs, npcAt = {}, -10
local function bodyOf(m)
	return m:FindFirstChild("HumanoidRootPart") or m:FindFirstChild("Torso") or m:FindFirstChild("UpperTorso") or m:FindFirstChild("Head")
end
local function targets()
	local list = {}
	local mine = lp.Character
	pcall(function()
		for _, pl in ipairs(Players:GetPlayers()) do
			if pl ~= lp and pl.Character and pl.Character ~= mine then
				list[#list + 1] = pl.Character
			end
		end
	end)
	if now() - npcAt > 2 then
		npcAt = now()
		npcs = {}
		pcall(function()
			for _, m in ipairs(workspace:GetChildren()) do
				if m:IsA("Model") and m ~= mine and m:FindFirstChildOfClass("Humanoid") then
					local ok, pl = pcall(Players.GetPlayerFromCharacter, Players, m)
					if not (ok and pl) then
						npcs[#npcs + 1] = m
					end
				end
			end
		end)
	end
	for _, m in ipairs(npcs) do
		if m.Parent then
			list[#list + 1] = m
		end
	end
	return list
end
local function popNumber(m, n)
	local head = m:FindFirstChild("Head") or bodyOf(m)
	if not head then
		return
	end
	local bb = inst("BillboardGui", nil, {Name = "DamageNumber", Size = UDim2.new(0, 100, 0, 40), StudsOffset = VT(0, 2.5, 0), Adornee = head, AlwaysOnTop = true})
	local t = inst("TextLabel", bb, {
		BackgroundTransparency = 1, BorderSizePixel = 0, Text = tostring(n), Font = Enum.Font.SourceSansBold, TextSize = 26,
		TextStrokeTransparency = 0, TextColor3 = RED, TextStrokeColor3 = C3(0, 0, 0), Size = UDim2.new(1, 0, 1, 0),
	})
	bb.Parent = FX
	local s = C.sound(HITSOUNDS[RND(1, #HITSOUNDS)], 1.25, 1)
	task.spawn(function()
		for i = 1, 30 do
			C.swait(1)
			bb.StudsOffset = VT(0, 2.5 + i * 0.05, 0)
			if i > 15 then
				t.TextTransparency = (i - 15) / 15
				t.TextStrokeTransparency = (i - 15) / 15
			end
		end
		bb:Destroy()
	end)
	return s
end
local function hit(m, lo, hi, delay)
	local tm = now()
	if (victims[m] or 0) > tm then
		return false
	end
	victims[m] = tm + (delay or 0.2)
	popNumber(m, RND(lo, hi))
	return true
end
local function near(pos, r, lo, hi, delay)
	for _, m in ipairs(targets()) do
		local b = bodyOf(m)
		if b and (b.Position - pos).Magnitude <= r then
			hit(m, lo, hi, delay)
		end
	end
end
local function alongLine(a, b, r, lo, hi, delay)
	local d = b - a
	local len = d.Magnitude
	if len < 1e-3 then
		return
	end
	local u = d / len
	for _, m in ipairs(targets()) do
		local p = bodyOf(m)
		if p then
			local v = p.Position - a
			local t = CLAMP(v:Dot(u), 0, len)
			if (v - u * t).Magnitude <= r then
				hit(m, lo, hi, delay)
			end
		end
	end
end

local W = {}
local function bladeLen()
	local h = swordHat()
	return h and h.blade or 7.2
end
local function swordTip()
	return W.sword * CF(0, -bladeLen(), 0)
end
local function bladeMid()
	return W.sword * CF(0, -bladeLen() * 0.62, 0) * CFrame.fromMatrix(Vector3.zero, VT(0, -1, 0), VT(0, 0, 1), VT(-1, 0, 0))
end
local function gunMuzzle()
	local h = gunHat()
	if h then
		return W.grip * h.tip * C.alignOff(3)
	end
	return W.larm * CF(0.35, -2.9, 0) * CFrame.fromMatrix(Vector3.zero, VT(0, -1, 0), VT(1, 0, 0), VT(0, 0, 1)) * C.alignOff(3)
end
C.muzzleCF = function()
	if not W.sword then
		return CF()
	end
	local tab = C.alignTab and C.alignTab() or 1
	if tab == 2 or tab == 3 then
		return gunMuzzle()
	elseif tab == 4 then
		return W.slashPreview or swordTip()
	end
	return CF(swordTip().Position)
end
C.gripCF = function()
	return W.sword or CF()
end

local anims = {}
local function anim(dur, fn, done)
	local a = {t0 = now(), d = dur, fn = fn, done = done}
	anims[#anims + 1] = a
	pcall(fn, 0)
	return a
end
local function runAnims()
	local tm = now()
	local i = 1
	while i <= #anims do
		local a = anims[i]
		local k = a.d > 0 and math.min((tm - a.t0) / a.d, 1) or 1
		local ok = pcall(a.fn, k)
		if k >= 1 or not ok then
			if a.done then
				pcall(a.done)
			end
			table.remove(anims, i)
		else
			i += 1
		end
	end
end
local function stretch(cf, size, color, s0, grow, ticks, fade)
	local p = C.newPart({Name = "Stretch", Size = VT(size, size, size), Color = color, Transparency = 0, CFrame = cf})
	local m = inst("SpecialMesh", p, {MeshType = Enum.MeshType.Sphere, Scale = s0})
	anim(ticks / 60, function(a)
		local n = a * ticks
		m.Scale = VT(math.max(s0.X + grow.X * n, 0.05), math.max(s0.Y + grow.Y * n, 0.05), math.max(s0.Z + grow.Z * n, 0.05))
		p.Transparency = math.min(n * fade, 1)
	end, function()
		p:Destroy()
	end)
	return p
end
local function flash(cf, size, color, add, ticks)
	C.Effect({EffectType = "Sphere", CFrame = cf, Size = VT(size, size, size), Size2 = VT(size + add, size + add, size + add), Transparency = 0, Transparency2 = 1, Time = ticks, Color = color})
end
local function laser(len, width, color, ticks, fadeTicks, grow, onTick)
	local p = C.newPart({Name = "Laser", Size = VT(width, len, width), Color = color, Transparency = 0})
	local m = inst("SpecialMesh", p, {MeshType = Enum.MeshType.Sphere})
	local total = ticks + (fadeTicks or 0)
	local function place()
		local mz = gunMuzzle().Position
		local d = AimPoint() - mz
		d = d.Magnitude > 0.05 and d.Unit or W.root.LookVector
		p.CFrame = CFrame.lookAt(mz + d * len / 2, mz + d * len) * ANG(math.pi / 2, 0, 0)
		return mz, mz + d * len
	end
	anim(total / 60, function(a)
		local n = a * total
		local from, to2 = place()
		if n <= ticks then
			m.Scale = VT(1 + (grow or 0) * n, 1, 1 + (grow or 0) * n)
		else
			local f = (n - ticks) / math.max(fadeTicks, 1)
			local w = 1 + (grow or 0) * ticks
			m.Scale = VT(w * (1 - f) + 0.01, 1, w * (1 - f) + 0.01)
			p.Transparency = f
		end
		if onTick then
			onTick(from, to2, n)
		end
	end, function()
		p:Destroy()
	end)
	return p
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

local SL = nil
local function slashCF()
	local s = SL
	if not s then
		return nil
	end
	local t = now() - s.t0
	if t < s.dur then
		local p = s.start + s.dir * (s.speed * t)
		s.pos = p
		return s.rot + p, 0
	end
	local back = (t - s.dur) / 0.4
	if back < 1 then
		s.from = s.from or s.pos or s.start
		return s.rot + s.from:Lerp(W.torso.Position, back * back * (3 - 2 * back)), back
	end
	SL = nil
	return nil
end
local slashGhost = C.newPart({Name = "SlashGhost", Size = VT(15, 0.6, 3), Color = PURPLE, Transparency = 1, CFrame = CF(0, -4000, 0)})
inst("SpecialMesh", slashGhost, {MeshType = Enum.MeshType.Sphere})
local slashFX = C.newPart({Name = "SlashFX", Size = VT(1, 1, 1), Transparency = 1, CFrame = CF(0, -4000, 0)})
local slashPE = inst("ParticleEmitter", slashFX, {
	Texture = "rbxassetid://745304849", LightEmission = 1, Color = ColorSequence.new(PURPLE), Rate = 220, Lifetime = NumberRange.new(0.5),
	Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 3), NumberSequenceKeypoint.new(1, 0)}),
	Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)}),
	Speed = NumberRange.new(0), Rotation = NumberRange.new(-500, 500), RotSpeed = NumberRange.new(-500, 500), Enabled = false,
})

local trailPart = C.newPart({Name = "SwordTrail", Size = VT(0.2, 0.2, 0.2), Transparency = 1, CFrame = CF(0, -4000, 0)})
local trailA0 = inst("Attachment", trailPart, {Name = "T0"})
local trailA1 = inst("Attachment", trailPart, {Name = "T1"})
local swordTrail = inst("Trail", trailPart, {
	Attachment0 = trailA0, Attachment1 = trailA1, LightEmission = 1, Lifetime = 0.35, MinLength = 0, Enabled = false,
	Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1)}), Color = ColorSequence.new(PURPLE, BLUE),
})

local M = {}
local S = {attack = false, gunmode = false, combo = 1, blade = nil, bash = nil, padHeld = {}}
local function swordMove()
	swordTrail.Enabled = true
end
local function aimDir(from)
	local d = AimPoint() - from
	return d.Magnitude > 0.05 and d.Unit or W.root.LookVector
end
local function fireShot(lo, hi)
	local mz = gunMuzzle()
	local from = mz.Position
	snd(604905243, 1, 1)
	flash(mz, 1, PURPLE, 2.1, 21)
	local hitPart, pos = C.ray(from, aimDir(from), 256)
	setBullet(from, pos)
	C.beam(from, pos, 0.3, 10, PURPLE, 0, 1)
	flash(CF(pos), 0.8, PURPLE, 2, 14)
	local o = hitPart
	for _ = 1, 3 do
		o = o and o.Parent
		if o and o ~= lp.Character and o:FindFirstChildOfClass("Humanoid") then
			hit(o, lo, hi, 0.05)
			break
		end
	end
	near(pos, 2.5, lo, hi, 0.05)
end
local function aimPose()
	return {RJ = T(P.RootCF * A(0, 0, -90), .3), NK = T(P.necko * A(5, 0, 90), .3), RW = T(P.RW25, .3), LW = T(P.LWAIM, .3)}
end

function M.atk1()
	swordMove()
	S.blade = {7, 9}
	hold({RW = T(P.RWSWING, .4), LW = T(P.LW25, .3)}, 11)
	snd(199150686, 1, 1)
	hold({NK = T(P.necko * A(0, 0, -20), .4), RJ = T(P.RootCF * CF(0, 0, -.5) * A(0, 0, 25), .4), RW = T(CF(1, 0.5, -.5) * A(0, -90, -100) * A(-75, 0, 0), .4), LW = T(P.LW25, .3), HW = T(P.HWATK, .4)}, 11)
end
function M.atk2()
	swordMove()
	S.blade = {7, 9}
	hold({RW = T(P.RWBACK, .4), LW = T(P.LW25, .3), HW = T(P.HWATK, .4)}, 11)
	snd(199146359, 1, 1)
	hold({NK = T(P.necko * A(0, 0, 40), .4), RJ = T(P.RootCF * CF(0, 0, -.5) * A(0, 0, -45), .4), RW = T(P.RWSWING, .4), LW = T(P.LW25, .3), HW = T(P.HWSPIN, .4)}, 11)
end
function M.atk3()
	local g = aimPose()
	hold(g, 21)
	fireShot(9, 12)
	g.LW = T(P.LWAIM2, .3)
	hold(g, 21)
end
function M.atk4()
	hold({RJ = T(P.RootCF * A(0, 0, 80), .3), NK = T(P.necko * A(5, 0, -80), .3), RW = T(P.RW25, .3), LW = T(P.LWAIM, .3)}, 21)
	snd(199145204, 1, 1)
	S.bash = {8, 10}
	hold(aimPose(), 11)
	S.bash = nil
	snd(604905243, 1.25, 0.9)
	local mz = gunMuzzle()
	setBullet(mz.Position, mz.Position + aimDir(mz.Position) * 5)
	stretch(mz, 5, PURPLE, VT(.25, .25, .25), VT(.15, .15, .15), 21, 0.05)
	near(mz.Position, 7, 9, 11, 0.3)
	local g = aimPose()
	g.LW = T(P.LWAIM2, .3)
	hold(g, 21)
end

function M.bladespin()
	swordMove()
	S.blade = {5, 7}
	hold({RJ = T(P.RootCF * CF(0, 0, -.5) * A(0, 0, -10), .4), RW = T(P.RWBACK, .4), LW = T(P.LW25, .3), HW = T(P.HWATK, .4)}, 11)
	for _ = 0, 2 do
		snd(199146359, 1.15, 1.05)
		for _, deg in ipairs({90, 180, 240, 360}) do
			S.blade = {5, 7}
			hold({NK = T(P.necko, .4), RJ = T(P.RootCF * CF(0, 0, -.5) * A(0, 0, deg), .4), RW = T(P.RWSWING, .4), LW = T(P.LW25, .3), HW = T(P.HWSPIN, .4)}, 3)
		end
	end
end
local function chargeUp(n)
	hold({NK = T(P.necko * A(5, 0, -90), .3), RJ = T(P.RootCF * A(0, 0, 90), .4), RW = T(P.RWUP, .4), LW = T(P.LW25, .3), HW = T(P.HWATK, .4)}, n)
end
function M.flashingslash()
	chargeUp(21)
	swordMove()
	snd(540358153, 1, 0.9)
	local mid = bladeMid()
	stretch(mid, 0.5, WHITE, VT(1, 1, 1), VT(7.5, -0.01, -0.01), 21, 0.05)
	S.blade = {13, 16}
	alongLine(mid.Position - mid.RightVector * 40, mid.Position + mid.RightVector * 40, 3, 13, 16, 0.3)
	hold({NK = T(P.necko * A(5, 0, -90), .3), RJ = T(P.RootCF * CF(0, -2.5, 0) * A(0, 0, 90), .3), RW = T(P.RWOUT, .5), LW = T(P.LW25, .3), HW = T(P.HWATK, .4)}, 21)
end
function M.enerwave()
	hold({NK = T(P.necko * A(5, 0, 0), .3), RJ = T(P.RootCF, .4), RW = T(P.RWUP, .4), LW = T(P.LW25, .3), HW = T(P.HWATK, .4)}, 11)
	swordMove()
	snd(540358153, 1, 0.9)
	local root = W.root
	SL = {t0 = now(), start = (W.torso + W.torso.LookVector * 5).Position, dir = root.LookVector, rot = root.Rotation, speed = 150, dur = 1.3, hits = {}}
	hold({NK = T(P.necko * A(5, 0, 30), .3), RJ = T(P.RootCF * CF(0, 0, -.5) * A(0, 0, -30), .3), RW = T(P.RWOUT, .3), LW = T(P.LW25, .3), HW = T(P.HWATK, .4)}, 21)
end
function M.executionstab()
	chargeUp(51)
	swordMove()
	snd(540358153, 1.5, 0.75)
	local mid = bladeMid()
	stretch(mid, 1, RED, VT(1, 1, 1), VT(15, -0.02, -0.02), 51, 0.05)
	local dir = mid.RightVector
	local from = swordTip().Position
	if dir:Dot(W.root.LookVector) < 0 then
		dir = -dir
		from = mid.Position
	end
	setBullet(from, from + dir * 220)
	alongLine(mid.Position - dir * 30, from + dir * 220, 4, 50, 60, 0.5)
	S.blade = {50, 60}
	hold({NK = T(P.necko * A(5, 0, -90), .3), RJ = T(P.RootCF * A(0, 0, 90), .3), RW = T(P.RWOUT, .5), LW = T(P.LW25, .3), HW = T(P.HWATK, .4)}, 51)
end

local function heldKey(k)
	return C.keysDown[k] or S.padHeld[k]
end
function M.repeatbullet()
	local g = aimPose()
	hold(g, 4)
	S.shots = 3
	while S.shots > 0 and C.alive do
		S.shots -= 1
		fireShot(9, 10)
		g.LW = T(P.LWAIM2, .3)
		hold(g, 4)
		if S.shots == 0 and heldKey("z") then
			S.shots = 1
		end
		if S.shots > 0 then
			g.LW = T(P.LWAIM, .3)
			hold(g, 4)
		end
	end
	S.shots = nil
end
function M.stickybomb()
	local g = aimPose()
	hold(g, 21)
	snd(604905243, 1, 1)
	local mz = gunMuzzle()
	local from = mz.Position
	local _, pos = C.ray(from, aimDir(from), 200)
	local glow = C.newPart({Name = "Sticky", Size = VT(1.6, 1.6, 1.6), Color = PURPLE, Transparency = 0.3, CFrame = CF(from)})
	inst("SpecialMesh", glow, {MeshType = Enum.MeshType.Sphere})
	local dist = (pos - from).Magnitude
	setBullet(from, pos)
	anim(math.max(dist / 400, 0.04), function(a)
		glow.CFrame = CF(from:Lerp(pos, a))
	end, function()
		snd(604906197, 1, 1)
		near(pos, 3, 1, 3, 0.2)
		task.spawn(function()
			for _ = 0, 4 do
				glow.Color = RED
				task.wait(0.25)
				glow.Color = PURPLE
				task.wait(0.25)
			end
			glow:Destroy()
			if not C.alive then
				return
			end
			snd(412755503, 1, 0.875)
			setBullet(pos, pos + VT(0, 3, 0))
			stretch(CF(pos), 10, PURPLE, VT(0.1, 0.1, 0.1), VT(0.05, 0.05, 0.05), 20, 0.05)
			near(pos, 12, 16, 19, 0.5)
		end)
	end)
	g.LW = T(P.LWAIM2, .3)
	hold(g, 21)
end
function M.yep()
	hold(aimPose(), 21)
	snd(178452221, 1, 1)
	laser(75, 2.5, PURPLE, 10, 0, 0.1, function(a, b)
		setBullet(a, b)
		alongLine(a, b, 2.5, 17, 20, 0.3)
	end)
	C.swait(10)
end
function M.test()
	local g = aimPose()
	hold(g, 21)
	snd(412756262, 1, 0.95)
	local ba = C.newPart({Name = "Charge", Size = VT(1, 1, 1), Color = PURPLE, Transparency = 1, CFrame = gunMuzzle()})
	local za = inst("SpecialMesh", ba, {MeshType = Enum.MeshType.Sphere, Scale = VT(5, 5, 5)})
	anim(50 / 60, function(a)
		local n = a * 50
		ba.CFrame = gunMuzzle()
		ba.Transparency = math.max(1 - n * 0.1, 0)
		za.Scale = VT(5, 5, 5) * (1 - a)
	end)
	C.swait(50)
	for _, s in ipairs({{412756199, .95}, {412756123, .95}, {412755564, .95}, {178452221, .6}, {87767777, 1}}) do
		snd(s[1], 1, s[2])
	end
	local loop = C.sound(445796828, 2.5, 0.75, true)
	za.Scale = VT(5, 5, 5)
	ba.Transparency = 0
	anim(100 / 60, function(a)
		ba.CFrame = gunMuzzle()
		ba.Transparency = a * 2.5
		za.Scale = VT(5, 5, 5) + VT(1, 1, 1) * (a * 100)
	end, function()
		ba:Destroy()
	end)
	laser(400, 10, PURPLE, 100, 20, 0.01, function(a, b, n)
		if n <= 100 then
			setBullet(a, b)
		end
		alongLine(a, b, 6, 22, 28, 0.3)
	end)
	C.swait(100)
	if loop then
		anim(20 / 60, function(a)
			loop.Volume = 2.5 * (1 - a)
		end, function()
			loop:Destroy()
		end)
	end
	C.swait(20)
end

local SWORDKEYS = {z = M.bladespin, x = M.flashingslash, c = M.enerwave, v = M.executionstab}
local GUNKEYS = {z = M.repeatbullet, x = M.stickybomb, c = M.yep, v = M.test}
local COMBO = {M.atk1, M.atk2, M.atk3, M.atk4}
local function runMove(f)
	if S.attack or not C.alive then
		return
	end
	S.attack = true
	aimOn = true
	local ok, e = pcall(f)
	if not ok then
		C.err(e)
	end
	if C.alive then
		table.clear(goal)
		S.blade, S.bash, S.shots = nil, nil, nil
		aimOn = false
		swordTrail.Enabled = false
		S.attack = false
	end
end
C.keyDown = function(k)
	if k == string.lower(NEP.RunKey or "") then
		running = true
		return
	end
	if k == "q" then
		S.gunmode = not S.gunmode
		C.notify("Neptunian V", S.gunmode and "gun mode" or "sword mode", 2)
		return
	end
	if k == "z" and S.shots then
		S.shots = math.max(S.shots, 3)
		return
	end
	local f = (S.gunmode and GUNKEYS or SWORDKEYS)[k]
	if f then
		runMove(f)
	end
end
C.keyUp = function(k)
	if k == string.lower(NEP.RunKey or "") then
		running = false
	end
end
C.click = function()
	if S.attack then
		return
	end
	local f = COMBO[S.combo]
	S.combo = S.combo % #COMBO + 1
	runMove(f)
end

local function hitChecks()
	if S.blade and W.sword then
		local len = bladeLen()
		for _, f in ipairs({0.35, 0.6, 0.85}) do
			near((W.sword * CF(0, -len * f, 0)).Position, 2.6, S.blade[1], S.blade[2], 0.2)
		end
	end
	if S.bash and W.larm then
		near(gunMuzzle().Position, 3, S.bash[1], S.bash[2], 0.3)
	end
	local s = SL
	if s and s.pos then
		near(s.pos, 6, 10, 13, 0.4)
	end
end

C.tick = function()
	hitChecks()
end

local chatCons = {}
local lastCmd, lastAt = "", 0
local function onChat(msg)
	if type(msg) ~= "string" then
		return
	end
	local body = string.lower(msg)
	body = body:gsub("^%s+", "")
	body = body:gsub("%s+$", "")
	if body ~= "-align" and body ~= "-stop" and body ~= "-hatsword" and body ~= "-hatgun" then
		return
	end
	local t = os.clock()
	if body == lastCmd and t - lastAt < 1 then
		return
	end
	lastCmd, lastAt = body, t
	if body == "-align" then
		if C.toggleAlign then
			C.toggleAlign()
		end
	elseif body == "-hatsword" then
		C.toggleHat("sword")
	elseif body == "-hatgun" then
		C.toggleHat("gun")
	else
		task.spawn(C.stop)
	end
end
pcall(function()
	chatCons[#chatCons + 1] = lp.Chatted:Connect(onChat)
end)
pcall(function()
	local TCS = game:GetService("TextChatService")
	chatCons[#chatCons + 1] = TCS.SendingMessage:Connect(function(message)
		onChat(message.Text)
	end)
end)
C.onStop(function()
	for _, c in ipairs(chatCons) do
		pcall(function()
			c:Disconnect()
		end)
	end
end)

local phase = 0
local function basePose(dt)
	local vel = C.vel()
	local speed = VT(vel.X, 0, vel.Z).Magnitude
	local ground = fd.isOnGround()
	local s = now() * 60
	local state
	if not ground then
		state = vel.Y > 0 and "jump" or "fall"
	elseif speed < 1 then
		state = "idle"
	elseif speed < 22 then
		state = "walk"
	else
		state = "run"
	end
	if state == "walk" or state == "run" then
		phase += dt * math.max(speed, 6) * 0.72
	end
	local cw, breath = COS(phase), COS(s / 32)
	local gun = S.gunmode
	if state == "jump" then
		base.NK = T(P.necko * EUL(-0.2, 0, 0), .3)
		base.RJ = T(P.RootCF, .3)
		base.RW = T(CF(1.5, 0.5, 0) * EUL(-.5, 0, .5) * A(-25, 105, 0), .3)
		base.LW = T(gun and CF(-1.35, 0.5, 0) * A(150, 20, -90) or CF(-1.5, 0.5, 0) * EUL(-.5, 0, -.5), .3)
		base.RH = T(CF(1, -1, -.3) * EUL(-0.5, 1.57, 0) * EUL(-.2, 0, 0), .2)
		base.LH = T(CF(-1, -1, -.3) * EUL(-0.5, -1.57, 0) * EUL(-.2, 0, 0), .2)
	elseif state == "fall" then
		base.NK = T(P.necko * EUL(0.4, 0, 0), .3)
		base.RJ = T(P.RootCF, .3)
		base.RW = T(CF(1.5, 0.5, 0) * EUL(0.3, 0, 0.2) * A(-25, 115, 0), .3)
		base.LW = T(gun and CF(-1.35, 0.5, 0) * A(160, 20, -90) or CF(-1.5, 0.5, 0) * EUL(0.3, 0, -0.2), .3)
		base.RH = T(CF(1, -1, 0) * EUL(0.4, 1.57, 0), .2)
		base.LH = T(CF(-1, -1, 0) * EUL(-0.2, -1.57, 0), .2)
	elseif state == "idle" then
		base.RH = T(CF(1, -1 - 0.05 * breath, 0) * A(0, 90, 0), .3)
		base.LH = T(CF(-1, -1 - 0.05 * breath, 0) * A(0, -90, 0), .3)
		base.RW = T(P.RWHOLD * A(-25 + 5 * breath, 15, 0), .3)
		if gun then
			base.RJ = T(P.RootCF * CF(0, 0, 0.05 * breath) * A(0, 0, -60), .3)
			base.NK = T(P.necko * A(0, 0, 60), .3)
			base.LW = T(CF(-1.35, 0.5, 0) * A(180, 30, -90), .3)
		else
			base.RJ = T(P.RootCF * CF(0, 0, 0.05 * breath) * A(0, 0, -35), .3)
			base.NK = T(P.necko * A(0, 0, 35), .3)
			base.LW = T(CF(-1.5, 0.5, 0) * A(0, 0, -25 + 2.5 * breath), .3)
		end
	elseif state == "walk" then
		local legs = RAD(50) * cw
		base.RH = T(CF(1, -1 - 0.05 * breath, 0) * A(0, 90, 0) * ANG(0, 0, legs), .3)
		base.LH = T(CF(-1, -1 - 0.05 * breath, 0) * A(0, -90, 0) * ANG(0, 0, legs), .3)
		base.RJ = T(P.RootCF * CF(0, 0, 0.06 * COS(phase * 2)) * A(5, 0, 3 * SIN(phase)), .3)
		base.NK = T(P.necko * A(5, 0, -3 * SIN(phase)), .3)
		base.RW = T(CF(1.5, 0.5, 0) * A(-55, 90, 0) * A(-15, 0, 0), .3)
		if gun then
			base.LW = T(CF(-1.5, 0.45, 0) * A(55, 0, 25), .3)
		else
			base.LW = T(CF(-1.5, 0.5, 0) * ANG(RAD(22) * cw, 0, 0) * A(-15, 0, -25), .3)
		end
	else
		local legs = RAD(75) * cw
		base.RH = T(CF(1, -1 - 0.05 * breath, 0) * A(0, 90, 0) * ANG(0, 0, legs), .3)
		base.LH = T(CF(-1, -1 - 0.05 * breath, 0) * A(0, -90, 0) * ANG(0, 0, legs), .3)
		base.RJ = T(P.RootCF * CF(0, 0, -0.25 + 0.1 * COS(phase * 2)) * A(35, 0, 4 * SIN(phase)), .3)
		base.NK = T(P.necko * A(-5, 0, -4 * SIN(phase)), .3)
		base.RW = T(CF(1.5, 0.5, 0) * A(-50, -60, 25), .3)
		base.LW = T(gun and CF(-1.5, 0.45, 0) * A(55, 0, 25) or CF(-1.5, 0.5, 0) * ANG(RAD(35) * cw, 0, 0) * A(-50, 0, -25), .3)
	end
	base.NK1 = T(P.necko2, .3)
	base.RW1 = T(P.ARM1, .3)
	base.LW1 = T(P.ARM1, .3)
	base.HW = T(IDENT, .3)
end

C.animate = function(_, dt)
	dt = dt or 1 / 60
	local p = dt * 60
	pcall(fd.setWalkSpeed, running and (NEP.RunSpeed or 26) or (NEP.WalkSpeed or 16))
	local ok, e = pcall(stepAim, dt)
	if not ok then
		C.err(e)
	end
	basePose(dt)
	for _, k in ipairs(KEYS) do
		local g = goal[k] or base[k]
		if g then
			J[k] = J[k]:Lerp(g[1], 1 - (1 - g[2]) ^ p)
		end
	end
	RJ.C0, RJ.C1 = J.RJ, P.RJC1
	Neck.C0, Neck.C1 = J.NK, J.NK1
	RS.C0, RS.C1 = J.RW, J.RW1
	LS.C0, LS.C1 = J.LW, J.LW1
	RH.C0, RH.C1 = J.RH, P.RHC1
	LH.C0, LH.C1 = J.LH, P.LHC1
	local root = C.rootCF()
	local rootInv = root:Inverse()
	W.root = root
	W.torso = root * J.RJ * P.RJC1:Inverse()
	W.rarm = W.torso * J.RW * J.RW1:Inverse()
	W.larm = W.torso * J.LW * J.LW1:Inverse()
	W.handle = W.rarm * J.HW * P.HWC1i
	W.sword = W.handle * C.alignOff(1)
	W.grip = W.larm * CFrame.fromMatrix(VT(0.05, -1, 0), VT(0, -1, 0), VT(1, 0, 0), VT(0, 0, 1)) * C.alignOff(2)
	local sw, gn = swordHat(), gunHat()
	for _, h in ipairs({H.sword, H.scythe}) do
		if h == sw then
			glue(h, rootInv * W.sword * h.fit)
		elseif h.glued and hatOk(h) then
			restore(h)
		end
	end
	for _, h in ipairs({H.gun, H.revolver}) do
		if h == gn then
			glue(h, rootInv * W.grip * h.fit)
		elseif h.glued and hatOk(h) then
			restore(h)
		end
	end
	local rk = H.rock
	local rc = rockCF(root)
	if hatOk(rk) then
		glue(rk, rootInv * rc)
	end
	local sl = H.slash
	local scf, back = slashCF()
	local tab = C.alignOpen and C.alignOpen() and C.alignTab and C.alignTab() or 0
	W.slashPreview = nil
	if not scf and tab == 4 then
		scf, back = root * CF(0, 0.5, -6), 0
		W.slashPreview = scf
	end
	local ghost = false
	if scf then
		local full = scf * C.alignOff(4)
		if hatOk(sl) and sl.fit then
			glue(sl, rootInv * full * sl.fit)
		elseif clientOn(worn(sl)) and back < 1 then
			ghost = true
			slashGhost.Transparency = 0.2 + 0.8 * back
		end
		slashFX.CFrame = full
		slashPE.Enabled = SL ~= nil and back == 0
	else
		slashPE.Enabled = false
		if hatOk(sl) then
			glue(sl, CF(0, -12, 0))
		end
	end
	if not ghost and slashGhost.Transparency < 1 then
		slashGhost.Transparency = 1
	end
	local n, bp, bc = 0, {}, {}
	local function put(part, cf)
		n += 1
		bp[n] = part
		bc[n] = cf
	end
	local wants = {sword = clientOn(sw), gun = clientOn(gn), gauntlet = NEP.Gauntlet ~= false}
	for key, list in pairs(CL) do
		local want = wants[key]
		if want then
			local at = key == "sword" and W.handle or W.larm
			for _, c in ipairs(list) do
				put(c.p, at * c.off)
			end
		end
		if want ~= shown[key] then
			shown[key] = want
			for _, c in ipairs(list) do
				c.p.Transparency = want and 0 or 1
				if not want then
					put(c.p, CF(0, -4000, 0))
				end
			end
		end
	end
	local len = bladeLen()
	put(trailPart, W.sword)
	put(slashGhost, ghost and slashFX.CFrame or CF(0, -4000, 0))
	trailA0.Position = VT(0, -len * 0.3, 0)
	trailA1.Position = VT(0, -len, 0)
	if not pcall(workspace.BulkMoveTo, workspace, bp, bc, Enum.BulkMoveMode.FireCFrameChanged) then
		for k = 1, n do
			bp[k].CFrame = bc[k]
		end
	end
end

C.afterFrame = function()
	scanHats()
	runAnims()
end

C.notify("Neptunian V", "Q switches sword / gun. click = combo, Z X C V = skills (they change with the mode). hold " .. tostring(NEP.RunKey) .. " to run. " .. string.upper(NEP.AlignKey) .. " = align panel (Stop is in there too)", 10)
