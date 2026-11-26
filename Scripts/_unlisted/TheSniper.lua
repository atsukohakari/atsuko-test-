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
						C.notify("The Sniper", "Downloading music...", 4)
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

	local TAB = {"Gun", "Muzzle", "Scope"}
	local genv = (typeof(getgenv) == "function" and getgenv()) or _G
	local AL = {version = 1, title = "The Sniper", tabs = TAB, file = FILE, dirty = false, open = false, key = CFG.alignKeyText or string.upper(CFG.alignKey or "j")}
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
	AL.optList = {{"roll", "Roll (upside down? tap this)", "button"}}
	AL.optsSaved = false
	function AL.opts()
		return {}
	end
	function AL.setOpt(name, on)
		local v = VAL[cur]
		if name == "roll" and v then
			AL.set(cur, 4, v[4] + 180)
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
	genv.AtsukoAlign = AL
	do
		local h = hub()
		if h and type(h.AlignReady) == "function" then
			pcall(h.AlignReady)
		end
	end

	local marker = C.newPart({Name = "MuzzleMarker", Shape = Enum.PartType.Ball, Size = V3(0.4, 0.4, 0.4), Color = C3(1, 0.25, 0.3), Transparency = 1})
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
local SNIPER = {
	Guns = {"87566002870491", "131577122939956"},
	GunWords = {{"sakura", "sniper"}, {"blaster", "rifle"}},
	Bullet = "4307568890",
	BulletHideDepth = 20,
	BulletSpeed = 2600,
	BulletRange = 256,
	Range = 1500,
	Ammo = 10,
	AlignKey = "p",
}

if not game:IsLoaded() then
	game.Loaded:Wait()
end

local StarterGui = game:GetService("StarterGui")
local function note(text, dur)
	hubNotify("The Sniper", text, "info", dur)
end
local VERSION = 3
local old = _G.TheSniperCommands
if type(old) == "table" then
	if type(old.kill) == "function" and (old.version or 0) < VERSION then
		pcall(old.kill)
	else
		note('Do "-run" to run the script, and "-stop" to stop the script.')
		return
	end
end

local OPT = {zoom = false, unli = false, nocd = false}
local current = nil
local lastRigCF = nil

local function startSniper()
	local C = LCCore(FD, {gunIds = {}, alignFile = "SniperAlign.json", alignKey = SNIPER.AlignKey, maxEffects = 220})
	if not C then
		return
	end
	local fd = C.fd
	current = C
	C.onStop(function()
		if current == C then
			current = nil
		end
	end)

	local Players = game:GetService("Players")
	local UIS = game:GetService("UserInputService")
	local lp = Players.LocalPlayer
	local CF, VT, C3 = CFrame.new, Vector3.new, Color3.new
	local ANG = CFrame.Angles
	local RAD, ABS = math.rad, math.abs
	local IDENT = CFrame.identity
	local RightArm, LeftArm = C.RightArm, C.LeftArm
	local RJ, Ne, RW, LW, RH, LH = C.RootJoint, C.Neck, C.RightShoulder, C.LeftShoulder, C.RightHip, C.LeftHip

	RW.C1 = CF(0, 0.5, 0)
	LW.C1 = CF(0, 0.5, 0)
	local LHCF = ANG(0, RAD(-90), 0)
	local RHCF = ANG(0, RAD(90), 0)

	local attack = false
	local Aiming = false
	local Crouching = false
	local Zoomed = false
	local Ammo = SNIPER.Ammo
	local Depleted = false
	local reloading = false
	local camKick = 0

	local function CreateSound(id, vol, pitch)
		return C.sound(id, vol, pitch)
	end

	local onPhone = UIS.TouchEnabled and not UIS.KeyboardEnabled
	local aimCenter = false
	local function AimPoint()
		if onPhone or aimCenter then
			local cam = workspace.CurrentCamera
			if cam then
				local vp = cam.ViewportSize
				local ray = cam:ViewportPointToRay(vp.X / 2, vp.Y / 2)
				local _, pos = C.ray(ray.Origin, ray.Direction, SNIPER.Range)
				return pos
			end
		end
		return C.mouseHit().Position
	end

	local BARREL, TOP = VT(-1, 0, 0), VT(0, 1, 0)

	local GUN = {e = nil, j = nil, home = nil, base = IDENT, size = VT(1, 1, 1), nextScan = 0}
	local INFO = {}
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
		local ok, row = pcall(A.match, "The Sniper", slot, {mesh = idOf(rawget(e, "m")), tex = idOf(rawget(e, "t")), name = accName(e)})
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
	for i, gid in ipairs(SNIPER.Guns) do
		local info = {}
		INFO[i] = info
		task.spawn(function()
			local id = tonumber(gid)
			if not id then
				return
			end
			pcall(function()
				local list = game:GetObjects("rbxassetid://" .. id)
				local acc = list and list[1]
				if not acc then
					return
				end
				local h = acc:FindFirstChild("Handle") or acc:FindFirstChildWhichIsA("BasePart", true)
				if h then
					if h:IsA("MeshPart") then
						info.mesh = idOf(h.MeshId)
					else
						local sm = h:FindFirstChildOfClass("SpecialMesh")
						if sm then
							info.mesh = idOf(sm.MeshId)
						end
					end
				end
				if acc:IsA("Accoutrement") or acc:IsA("Accessory") then
					info.name = squash(acc.Name)
					info.title = info.title or acc.Name
				end
			end)
			pcall(function()
				local pi = game:GetService("MarketplaceService"):GetProductInfo(id, Enum.InfoType.Asset)
				if type(pi) == "table" and type(pi.Name) == "string" then
					info.title = pi.Name
					info.name2 = squash(pi.Name)
				end
			end)
			GUN.nextScan = 0
		end)
	end
	local function isRock(e)
		return idOf(rawget(e, "m")) == SNIPER.Bullet or hubJob("bullet", e) ~= nil
	end
	local function gunRank(e)
		if hubJob("gun", e) then
			return 1
		end
		local m, t = idOf(rawget(e, "m")), idOf(rawget(e, "t"))
		local n = squash(accName(e))
		for i, gid in ipairs(SNIPER.Guns) do
			local info = INFO[i] or {}
			if gid ~= "" and (m == gid or t == gid) then
				return i
			end
			if info.mesh and info.mesh ~= "" and m == info.mesh then
				return i
			end
			if n ~= "" and ((info.name and info.name ~= "" and n == info.name) or (info.name2 and info.name2 ~= "" and n == info.name2)) then
				return i
			end
		end
		if n == "" then
			return nil
		end
		for i, words in ipairs(SNIPER.GunWords) do
			local count = 0
			for _, w in ipairs(words) do
				local s = squash(w)
				if s ~= "" then
					if not n:find(s, 1, true) then
						count = -1
						break
					end
					count += 1
				end
			end
			if count > 0 then
				return 100 + i
			end
		end
		return nil
	end

	local function fitGun(e, home)
		local p = rawget(e, "p")
		local s = VT(1, 1, 1)
		pcall(function()
			s = p.Size
		end)
		GUN.size = s
		local rest = home[3] * home[2]:Inverse()
		local held = false
		pcall(function()
			for _, a in ipairs(p:GetChildren()) do
				if a:IsA("Attachment") and (a.Name == "RightGripAttachment" or a.Name == "LeftGripAttachment") then
					held = true
				end
			end
		end)
		if not held and (home[1] == RightArm or home[1] == LeftArm) and (rest.Position - VT(0, -1, 0)).Magnitude < 1.2 then
			held = true
		end
		local barrel, up, grip
		if held then
			barrel = rest:VectorToObjectSpace(VT(0, 0, -1))
			up = rest:VectorToObjectSpace(VT(0, 1, 0))
			grip = rest:PointToObjectSpace(VT(0, -1, 0))
		else
			local ax = {VT(1, 0, 0), VT(0, 1, 0), VT(0, 0, 1)}
			local sz = {s.X, s.Y, s.Z}
			local idx = {1, 2, 3}
			table.sort(idx, function(a, b)
				return sz[a] > sz[b]
			end)
			barrel, up = ax[idx[1]], ax[idx[2]]
			if rest:VectorToWorldSpace(barrel).Y < 0 then
				barrel = -barrel
			end
			local w = rest:VectorToWorldSpace(up)
			if w.Y + 0.5 * w.Z < 0 then
				up = -up
			end
			grip = -barrel * (0.28 * sz[idx[1]]) - up * (0.25 * sz[idx[2]])
		end
		local L = ABS(barrel.X) * s.X + ABS(barrel.Y) * s.Y + ABS(barrel.Z) * s.Z
		local H = ABS(up.X) * s.X + ABS(up.Y) * s.Y + ABS(up.Z) * s.Z
		local M = CFrame.fromMatrix(Vector3.zero, barrel, up, barrel:Cross(up))
		local T = CFrame.fromMatrix(Vector3.zero, BARREL, TOP, BARREL:Cross(TOP))
		local R = (T * M:Inverse()).Rotation
		GUN.base = R * CF(-grip)
		GUN.L, GUN.H = L, H
		GUN.center = R:VectorToWorldSpace(-grip)
		GUN.held = held
		local known = hubHold(e)
		if known then
			local T2 = CFrame.fromMatrix(Vector3.zero, BARREL, TOP, BARREL:Cross(TOP))
			GUN.base = T2 * known.fit
			GUN.center = GUN.base.Position
			GUN.held = true
		end
	end
	local function findGun()
		if GUN.unjoin then
			GUN.unjoin()
			GUN.unjoin = nil
		end
		GUN.e, GUN.j, GUN.home = nil, nil, nil
		local best, bestRank = nil, math.huge
		for e in pairs(fd.cframes) do
			if type(e) == "table" and rawget(e, "m") ~= nil and not isRock(e) then
				local r = gunRank(e)
				if r and r < bestRank and fd.getPartJoint(e) then
					best, bestRank = e, r
				end
			end
		end
		if best then
			local j = fd.getPartJoint(best)
			GUN.e, GUN.j = best, j
			GUN.home = {j.Part1, j.C0, j.C1}
			fitGun(best, GUN.home)
			GUN.unjoin = hubJoin(best)
		end
	end
	local pose = {gun = CF(0.8, 0, -1) * ANG(0, math.pi / 2, 0), eye = VT(0, 1.6, -0.6), scope = VT(0.4, 1.4, -1)}
	local function gunFrame()
		return C.rootCF() * pose.gun
	end
	local function updateGun()
		local now = os.clock()
		if (not GUN.e or fd.cframes[GUN.e] == nil) and now >= GUN.nextScan then
			GUN.nextScan = now + 0.5
			findGun()
		end
		local j = GUN.j
		if j then
			j.Part1 = C.Root
			j.C0 = IDENT
			j.C1 = pose.gun * C.alignOff(1) * GUN.base
		end
	end
	C.onStop(function()
		local j, home = GUN.j, GUN.home
		if j and home then
			j.Part1, j.C0, j.C1 = home[1], home[2], home[3]
		end
		if GUN.unjoin then
			GUN.unjoin()
			GUN.unjoin = nil
		end
	end)
	local TURN = ANG(0, math.pi / 2, 0)
	C.muzzleCF = function()
		local g = gunFrame()
		local fwd = g:VectorToWorldSpace(BARREL)
		local j = GUN.j
		if j then
			local hat = C.rootCF() * j.C1
			local s = GUN.size / 2
			local reach = ABS(hat.RightVector:Dot(fwd)) * s.X + ABS(hat.UpVector:Dot(fwd)) * s.Y + ABS(hat.LookVector:Dot(fwd)) * s.Z
			return (g.Rotation * TURN + (hat.Position + fwd * reach)) * C.alignOff(2)
		end
		return (g.Rotation * TURN + g * VT(-5.5, 0.65, 0)) * C.alignOff(2)
	end
	C.gripCF = function()
		return gunFrame()
	end

	local ROCK = {e = nil, j = nil, home = nil, flight = nil, nextScan = 0}
	local function RockShot(from, to)
		local d = to - from
		if d.Magnitude > SNIPER.BulletRange then
			to = from + d.Unit * SNIPER.BulletRange
		end
		local dur = math.max((to - from).Magnitude / SNIPER.BulletSpeed, 0.05)
		ROCK.flight = {from = from, to = to, t0 = os.clock(), dur = dur}
	end
	local function rockTrail(on)
		local p = ROCK.e and rawget(ROCK.e, "p")
		if ROCK.trailPart ~= p then
			if ROCK.trail then
				for _, o in ipairs(ROCK.trail) do
					pcall(o.Destroy, o)
				end
			end
			ROCK.trail, ROCK.trailPart = nil, p
			if p then
				pcall(function()
					local a0 = Instance.new("Attachment")
					a0.Name = "SniperTrail0"
					a0.Position = VT(0, 0.6, 0)
					local a1 = Instance.new("Attachment")
					a1.Name = "SniperTrail1"
					a1.Position = VT(0, -0.6, 0)
					local tl = Instance.new("Trail")
					tl.Attachment0 = a0
					tl.Attachment1 = a1
					tl.Texture = "rbxassetid://1978704853"
					tl.LightEmission = 1
					tl.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)})
					tl.Color = ColorSequence.new(C3(1, 0.85, 0.2), C3(1, 1, 0))
					tl.Lifetime = 0.3
					tl.MinLength = 0
					tl.Enabled = false
					a0.Parent = p
					a1.Parent = p
					tl.Parent = p
					ROCK.trail = {tl, a0, a1}
				end)
			end
		end
		local tr = ROCK.trail
		if tr and tr[1].Enabled ~= on then
			tr[1].Enabled = on
		end
	end
	local function updateRock()
		local now = os.clock()
		if (not ROCK.e or fd.cframes[ROCK.e] == nil) and now >= ROCK.nextScan then
			ROCK.nextScan = now + 0.5
			ROCK.e, ROCK.j, ROCK.home = nil, nil, nil
			for e in pairs(fd.cframes) do
				if type(e) == "table" and isRock(e) then
					local j = fd.getPartJoint(e)
					if j then
						ROCK.e, ROCK.j, ROCK.home = e, j, {j.Part1, j.C0, j.C1}
						break
					end
				end
			end
		end
		local j = ROCK.j
		if not j then
			return
		end
		local f = ROCK.flight
		if f then
			local t = now - f.t0
			local barrel = C.muzzleCF().Position
			local pos, dir
			if t < f.dur then
				pos = f.from:Lerp(f.to, t / f.dur)
				dir = f.to - f.from
			elseif t < f.dur + 0.05 then
				pos = f.to
				dir = f.to - f.from
			elseif t < f.dur * 2 + 0.05 then
				pos = f.to:Lerp(barrel, (t - f.dur - 0.05) / f.dur)
				dir = barrel - f.to
			else
				ROCK.flight = nil
			end
			if ROCK.flight then
				f.frames = (f.frames or 0) + 1
				rockTrail(f.frames > 1)
				local world = dir.Magnitude > 0.01 and (CFrame.lookAt(pos, pos + dir) * ANG(0, 0, t * 25)) or CF(pos)
				j.Part1 = C.Root
				j.C0 = IDENT
				j.C1 = C.rootCF():Inverse() * world
				return
			end
		end
		rockTrail(false)
		j.Part1 = C.Root
		j.C0 = IDENT
		j.C1 = CF(0, -SNIPER.BulletHideDepth, 0)
	end
	C.onStop(function()
		if ROCK.trail then
			for _, o in ipairs(ROCK.trail) do
				pcall(o.Destroy, o)
			end
		end
		local j, home = ROCK.j, ROCK.home
		if j and home then
			j.Part1, j.C0, j.C1 = home[1], home[2], home[3]
		end
	end)

	C.alignHat = function(s)
		local e = GUN.e
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
		local g
		if GUN.e then
			g = "Gun: " .. (accName(GUN.e) ~= "" and accName(GUN.e) or "found")
		else
			local names = {}
			for i, gid in ipairs(SNIPER.Guns) do
				names[#names + 1] = (INFO[i] and INFO[i].title) or gid
			end
			g = "Gun: not found, wear " .. table.concat(names, " or ")
		end
		local r = ROCK.e and "Bullet: golem rock" or "Bullet: no golem rock"
		return g .. " | " .. r
	end

	local hitCooldown = setmetatable({}, {__mode = "k"})
	local function hitMark(hum)
		local head = hum.Parent and hum.Parent:FindFirstChild("Head")
		if not head or (hitCooldown[hum] and os.clock() < hitCooldown[hum]) then
			return
		end
		hitCooldown[hum] = os.clock() + 0.3
		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.new(1, 0, 1, 0)
		bb.Adornee = head
		bb.StudsOffset = VT(math.random(-3, 3), math.random(3, 5), math.random(-3, 3))
		local tl = Instance.new("TextLabel")
		tl.Size = UDim2.new(3, 3, 3, 3)
		tl.BackgroundTransparency = 1
		tl.Text = "999999999-"
		tl.TextColor3 = BrickColor.new("Dark stone grey").Color
		tl.TextStrokeColor3 = BrickColor.new("Navy blue").Color
		tl.TextStrokeTransparency = 0
		tl.TextSize = 18
		tl.Font = Enum.Font.ArialBold
		tl.Parent = bb
		bb.Parent = head
		CreateSound(199149297, 1, 1)
		task.spawn(function()
			task.wait(1)
			for _ = 1, 10 do
				task.wait(0.1)
				bb.StudsOffset += VT(0, 0.1, 0)
			end
			bb:Destroy()
		end)
	end
	local function hitAround(pos)
		for _, c in ipairs(workspace:GetChildren()) do
			local hum = c:FindFirstChildOfClass("Humanoid")
			local head = c:FindFirstChild("Head")
			if hum and head and c ~= lp.Character and c.Name ~= lp.Name and (head.Position - pos).Magnitude <= 5 then
				hitMark(hum)
			end
		end
	end
	local YELLOW = C3(1, 1, 0)
	local function Shoot()
		local muzzle = C.muzzleCF()
		local from = muzzle.Position
		local to = AimPoint()
		local dir = to - from
		dir = dir.Magnitude > 1e-3 and dir.Unit or muzzle.LookVector
		if not OPT.unli then
			Ammo -= 1
			if Ammo <= 0 then
				Ammo = 0
				Depleted = true
			end
		end
		local hit, pos = C.ray(from, dir, SNIPER.Range)
		RockShot(from, pos)
		local dist = (pos - from).Magnitude
		C.Effect({Time = 12, EffectType = "Box", Size = VT(.01, .01, .01), Size2 = VT(.7, .7, .7), Transparency = 0, Transparency2 = 1, CFrame = muzzle, RotationX = math.random(-20, 20), RotationY = math.random(-20, 20), RotationZ = math.random(-20, 20), Material = "Neon", Color = YELLOW})
		if dist > 0.05 then
			C.Effect({Time = 8, EffectType = "Box", Size = VT(0, 0, dist), Size2 = VT(0.1, 0.1, dist), Transparency = 0, Transparency2 = 1, CFrame = CF(from, pos) * CF(0, 0, -dist / 2), Material = "Neon", Color = YELLOW})
		end
		C.Effect({Time = 20, EffectType = "Round Slash", Size = VT(.01, .01, .01), Size2 = VT(.025, .01, .025), Transparency = 0, Transparency2 = 1, CFrame = muzzle * ANG(RAD(math.random(-360, 360)), RAD(math.random(-360, 360)), RAD(math.random(-360, 360))), Material = "Neon", Color = YELLOW})
		if hit then
			hitAround(pos)
		end
	end

	local RJ_C1, NE_C1 = RJ.C1, Ne.C1
	local SH_R, SH_L = VT(1.5, 0.5, 0), VT(-1.5, 0.5, 0)
	local HAND = 1.35
	local EYE = VT(0, 0.1, -0.62)
	local DOWN = VT(0, -1, 0)
	local GUN_FWD = CFrame.fromMatrix(Vector3.zero, VT(0, 0, 1), VT(0, 1, 0), VT(-1, 0, 0))
	local CARRY
	do
		local d = VT(0.16, 0.79, 0.59).Unit
		local top = VT(0, 0.3, -1)
		top = (top - d * top:Dot(d)).Unit
		local x = -d
		CARRY = CFrame.fromMatrix(VT(0.73, 0.11, -0.9), x, top, x:Cross(top))
	end

	local function ease(x)
		x = math.clamp(x, 0, 1)
		return x * x * (3 - 2 * x)
	end
	local function seg(t, a, b)
		return ease((t - a) / (b - a))
	end
	local function ramp(v, on, time, dt)
		return math.clamp(v + (on and dt or -dt) / time, 0, 1)
	end
	local function toward(v, goal, rate, dt)
		return v + (goal - v) * (1 - math.exp(-rate * dt))
	end
	local function armTo(sh, target)
		local d = target - sh
		local len = d.Magnitude
		local dir = len > 1e-3 and d / len or DOWN
		local axis = DOWN:Cross(dir)
		local s = axis.Magnitude
		local rot
		if s < 1e-4 then
			rot = dir.Y < 0 and IDENT or ANG(math.pi, 0, 0)
		else
			rot = CFrame.fromAxisAngle(axis / s, math.atan2(s, DOWN:Dot(dir)))
		end
		return CF(target - dir * HAND) * rot
	end

	local walk = {w = 0, phase = 0, dir = VT(0, 0, -1), speed = 0}
	local function stepWalk(state, dt)
		local flat = C.vel() * VT(1, 0, 1)
		local speed = flat.Magnitude
		walk.speed = speed
		local air = state == "Jump" or state == "Fall"
		local goal = air and 0 or math.clamp((speed - 0.5) / 3.5, 0, 1)
		walk.w = toward(walk.w, goal, 8, dt)
		walk.phase = (walk.phase + dt * math.clamp(speed, 4, 16) * 0.95) % (math.pi * 2)
		if speed > 0.3 then
			walk.dir = walk.dir:Lerp(C.rootCF():VectorToObjectSpace(flat.Unit), 1 - math.exp(-dt * 10))
		end
	end

	local A = {aim = 0, scope = 0, crouch = 0, air = 0, pitch = 0, t = 0}
	local act = nil
	local shots = {}
	local function addKick(power)
		shots[#shots + 1] = {os.clock(), power}
		if #shots > 8 then
			table.remove(shots, 1)
		end
	end
	local function kickNow(now)
		local k = 0
		for i = #shots, 1, -1 do
			local t = now - shots[i][1]
			if t > 0.8 then
				table.remove(shots, i)
			elseif t > 0 then
				local x = t / 0.07
				k += shots[i][2] * x * math.exp(1 - x)
			end
		end
		return k
	end
	local function play(kind, dur, sounds)
		local my = {kind = kind, t0 = os.clock(), dur = dur}
		act = my
		local nextSound = 1
		while C.alive and act == my do
			local p = (os.clock() - my.t0) / dur
			while sounds and sounds[nextSound] and p >= sounds[nextSound][1] do
				CreateSound(sounds[nextSound][2], sounds[nextSound][3] or 1, 1)
				nextSound += 1
			end
			if p >= 1 then
				break
			end
			C.swait(1)
		end
		if act == my then
			act = nil
		end
	end

	local function gunPoints()
		local L, H = GUN.L or 6, GUN.H or 1.6
		local center = GUN.center or VT(-0.28 * L, 0.25 * H, 0)
		return {
			L = L,
			H = H,
			butt = center + VT(0.5 * L, 0, 0),
			scope = C.alignOff(1) * (center + VT(0.04 * L, 0.45 * H, 0)),
			forend = VT(-math.clamp(0.3 * L, 1.1, 2), center.Y - 0.32 * H, 0),
			handle = VT(center.X + 0.22 * L, center.Y + 0.1 * H, -0.4),
			mag = VT(center.X + 0.12 * L, center.Y - 0.5 * H, 0),
		}
	end

	C.animate = function(state, dt)
		dt = math.min(dt or 1 / 60, 0.1)
		local now = os.clock()
		A.t += dt
		local t = A.t
		if Aiming then
			fd.setWalkSpeed(Crouching and 5 or 10)
			local at = AimPoint()
			local d = (at - C.rootCF().Position) * VT(1, 0, 1)
			if d.Magnitude > 2.5 then
				C.face(at, 1 - math.exp(-dt * 16))
			end
		else
			fd.setWalkSpeed(16)
		end
		stepWalk(state, dt)
		local air = state == "Jump" or state == "Fall"
		A.aim = ramp(A.aim, Aiming, 0.32, dt)
		A.scope = ramp(A.scope, Aiming and Zoomed, 0.28, dt)
		A.crouch = ramp(A.crouch, Aiming and Crouching, 0.3, dt)
		A.air = ramp(A.air, air, 0.18, dt)
		local goal = 0
		if Aiming then
			local d = AimPoint() - C.rootCF() * VT(0, 1.5, 0)
			local flat = VT(d.X, 0, d.Z).Magnitude
			goal = math.clamp(math.atan2(d.Y, math.max(flat, 4)), RAD(-55), RAD(55))
		end
		A.pitch = toward(A.pitch, goal, 12, dt)
		local k, ks, kc, ka = ease(A.aim), ease(A.scope), ease(A.crouch), ease(A.air)
		local w, sn = walk.w, math.sin(walk.phase)
		local kick = kickNow(now)
		camKick = kick * 0.3
		local pitch = A.pitch + (RAD(0.3) * math.sin(t * 1.3) + RAD(0.4) * w * math.sin(walk.phase * 2)) * k
		local boltP, relP
		if act then
			local p = math.clamp((now - act.t0) / act.dur, 0, 1)
			if act.kind == "bolt" then
				boltP = p
			else
				relP = p
			end
		end
		local G = gunPoints()

		local yaw = RAD(-14) + RAD(-56) * k
		local lean = RAD(5) * w * (1 - k) + (RAD(6) - pitch * 0.3) * k + RAD(8) * kc
		local roll = -RAD(4) * k - RAD(10) * ks
		local breath = 0.03 * math.sin(t * 1.7)
		local mv = ANG(0, yaw, 0):VectorToObjectSpace(walk.dir)
		local fwd, side = -mv.Z, mv.X
		local bob = -0.12 * w * math.abs(fwd) * sn * sn * (1 - ka)
		local Ryaw = ANG(0, yaw, 0)
		local Rlr = ANG(-lean, 0, roll)
		local steady = CF(0, -0.65 * kc, 0) * Rlr * Ryaw
		local Tr = CF(0, bob + breath, 0) * steady
		RJ.C0 = Tr * RJ_C1
		local Ti = Tr:Inverse()

		local unlean = Ryaw:Inverse() * Rlr:Inverse() * Ryaw
		local amp = (RAD(38) + RAD(-8) * k) * (1 - 0.55 * kc)
		local swing = amp * w * fwd * sn * (1 - ka)
		local open = amp * 0.9 * w * math.abs(side) * (1 - ka)
		local oR, oL = open * (0.5 + 0.5 * sn), open * (0.5 - 0.5 * sn)
		local stance = RAD(3) + RAD(4) * k + RAD(38) * kc
		RH.C0 = CF(1, -1, 0) * unlean * ANG(swing + RAD(30) * ka, 0, stance + oR + RAD(6) * ka) * RHCF
		LH.C0 = CF(-1, -1, 0) * unlean * ANG(-swing - RAD(12) * ka, 0, -(stance + oL + RAD(6) * ka)) * LHCF

		local rot = ANG(pitch + kick, 0, 0) * GUN_FWD
		local pocket = steady * VT(0.9, 0.7, -0.42)
		local gAim = CF(pocket - rot:VectorToWorldSpace(G.butt - VT(kick * 2, 0, 0))) * rot
		local hp = RAD(-4) * (1 - k) + (pitch * 0.75 - RAD(2)) * k + (pitch * 0.25 - RAD(5)) * ks + kick * 0.35
		local hr = -RAD(6) * k - RAD(16) * ks
		local neck = Tr * VT(0, 1, 0)
		local head = CF(neck) * CFrame.fromEulerAnglesYXZ(hp, 0, hr) * CF(0, 0.5, 0)
		if ks > 0 then
			local dir = -rot.RightVector
			local sAt = gAim * G.scope
			local eye = head * EYE
			local off = eye - (sAt + dir * (eye - sAt):Dot(dir))
			local lean2 = -off * 0.45
			if lean2.Magnitude > 0.35 then
				lean2 = lean2.Unit * 0.35
			end
			local gunMove = off + lean2 + ANG(pitch, 0, 0):VectorToWorldSpace(C.alignOff(3).Position)
			head = head + lean2 * ks
			gAim = gAim + gunMove * ks
		end
		Ne.C0 = (Ti * head) * NE_C1

		local g = (Tr * CARRY * ANG(RAD(3) * w * sn, 0, 0)):Lerp(gAim, k)
		local boltE = 0
		if boltP then
			boltE = seg(boltP, 0, 0.15) * (1 - seg(boltP, 0.62, 0.8))
			g = g * CF(0, -0.25 * boltE, 0.1 * boltE) * ANG(RAD(-16) * boltE, 0, 0)
		end
		local relE = 0
		if relP then
			relE = seg(relP, 0, 0.14) * (1 - seg(relP, 0.84, 0.98))
			local gRel = CF(pocket - rot:VectorToWorldSpace(G.butt)) * rot * CF(0.45, -0.45, 0.35) * ANG(RAD(28), 0, RAD(-6))
			g = g:Lerp(gRel, relE)
		end
		pose.gun = g
		pose.eye = head * EYE
		pose.scope = g * G.scope

		local rTarget = g.Position
		if boltP then
			local p = boltP
			local hand = seg(p, 0, 0.16) * (1 - seg(p, 0.64, 0.8))
			local liftUp = seg(p, 0.16, 0.24) * (1 - seg(p, 0.52, 0.6))
			local pull = seg(p, 0.26, 0.4) * (1 - seg(p, 0.4, 0.52))
			local handle = g * (G.handle + VT(pull * 0.13 * G.L, liftUp * 0.18, 0))
			rTarget = rTarget:Lerp(handle, hand)
		end
		RW.C0 = armTo(SH_R, Ti * rTarget)

		local lTarget = g * G.forend
		local lHold = k
		if relP then
			local p = relP
			local mag = g * G.mag
			local pulled = mag + g:VectorToWorldSpace(VT(0, -0.5, 0))
			local belt = Tr * VT(-0.9, -1, -0.4)
			local pos = lTarget:Lerp(mag, seg(p, 0.05, 0.18))
			pos = pos:Lerp(pulled, seg(p, 0.2, 0.32))
			pos = pos:Lerp(belt, seg(p, 0.34, 0.48))
			pos = pos:Lerp(pulled, seg(p, 0.5, 0.62))
			pos = pos:Lerp(mag, seg(p, 0.62, 0.7))
			pos = pos:Lerp(lTarget, seg(p, 0.74, 0.88))
			lTarget = pos
			lHold = math.max(lHold, relE, seg(p, 0, 0.08) * (1 - seg(p, 0.9, 1)))
		end
		local free = CF(SH_L) * ANG(swing * 0.9 + RAD(4) + RAD(2) * math.sin(t * 1.7), 0, -RAD(5) - RAD(25) * ka)
		local held = armTo(SH_L, Ti * lTarget)
		LW.C0 = lHold <= 0 and free or lHold >= 1 and held or free:Lerp(held, lHold)
	end

	local Reload
	local function quickFire()
		if reloading then
			return
		end
		CreateSound(132572951, 1, .9)
		CreateSound(130767489, .7, 1.2)
		Shoot()
		addKick(RAD(5))
		if Depleted and C.alive then
			Reload()
		end
	end
	local BOLT_SOUNDS = {{0.27, 146740582, 0.7}}
	local function Fire()
		if not Aiming or Depleted then
			return
		end
		if OPT.nocd then
			quickFire()
			return
		end
		if attack then
			return
		end
		attack = true
		CreateSound(132572951, 1, .9)
		CreateSound(130767489, .7, 1.2)
		Shoot()
		addKick(RAD(8))
		C.swait(14)
		play("bolt", 0.8, BOLT_SOUNDS)
		attack = false
		if Depleted and C.alive then
			Reload()
		end
	end
	Reload = function()
		if attack then
			return
		end
		attack = true
		reloading = true
		local quick = OPT.nocd
		play("reload", quick and 0.75 or 1.5, {{0.22, 131045401}, {0.68, 131045429}})
		Ammo = SNIPER.Ammo
		reloading = false
		if Depleted then
			Depleted = false
			if not quick then
				play("bolt", 0.8, BOLT_SOUNDS)
			end
		end
		attack = false
	end

	local fov0, zoom0 = nil, nil
	local scope = {k = 0, eye = 0, last = os.clock(), fp = false, hidden = false, fovSet = false, icon = false}
	local function hideOwn(on)
		if on == scope.hidden then
			return
		end
		scope.hidden = on
		for e in pairs(fd.cframes) do
			local p = type(e) == "table" and e ~= ROCK.e and rawget(e, "p")
			if p then
				pcall(function()
					p.LocalTransparencyModifier = on and 1 or 0
				end)
			end
		end
	end
	local function scopeIcon(on)
		if on == scope.icon then
			return
		end
		scope.icon = on
		pcall(function()
			UIS.MouseIcon = on and "rbxassetid://18006519" or ""
		end)
	end
	local function camStep(base)
		local now = os.clock()
		local dt = math.min(now - scope.last, 0.1)
		scope.last = now
		local cam = workspace.CurrentCamera
		local want = Zoomed and OPT.zoom
		if want and scope.k <= 0 then
			fov0 = cam and cam.FieldOfView or 70
			pcall(function()
				zoom0 = fd.getCamZoom()
			end)
		end
		if not want and scope.fp then
			scope.fp = false
			pcall(fd.setCamZoom, zoom0 or -12)
		end
		scopeIcon(want)
		scope.k = math.clamp(scope.k + (want and dt or -dt) / 0.4, 0, 1)
		local onScope = Zoomed and not attack and not reloading
		scope.eye = math.clamp(scope.eye + (onScope and dt or -dt) / 0.22, 0, 1)
		if scope.k <= 0 then
			if scope.fovSet then
				scope.fovSet = false
				if cam then
					cam.FieldOfView = fov0 or 70
				end
				hideOwn(false)
			end
			return nil
		end
		if want and scope.k >= 1 and not scope.fp then
			scope.fp = true
			pcall(fd.setCamZoom, 0)
		end
		local s = ease(scope.k)
		local e = ease(scope.eye)
		local root = C.rootCF()
		local pos = (root * pose.eye):Lerp(root * pose.scope, e)
		local target = CF(pos) * base.Rotation * ANG(camKick, 0, 0)
		if cam then
			local t0, t1 = math.tan(RAD(fov0 or 70) / 2), math.tan(RAD(10) / 2)
			local z = s * (0.35 + 0.65 * e)
			cam.FieldOfView = math.deg(2 * math.atan(t0 + (t1 - t0) * z))
			scope.fovSet = true
		end
		hideOwn(s > 0.6)
		return base:Lerp(target, s)
	end
	pcall(fd.setCamOverride, camStep)
	local function setZoom(on)
		if on == Zoomed then
			return
		end
		CreateSound(on and 180144779 or 190623951, 1, 1)
		Zoomed = on
	end
	C.onStop(function()
		pcall(fd.setCamOverride, nil)
		hideOwn(false)
		scopeIcon(false)
		pcall(function()
			if scope.fovSet then
				workspace.CurrentCamera.FieldOfView = fov0 or 70
			end
		end)
	end)

	local function toggleAim()
		Aiming = not Aiming
		if not Aiming then
			setZoom(false)
		end
	end
	C.keyDown = function(k)
		if k == "r" then
			Reload()
		elseif k == "f" then
			toggleAim()
		elseif k == "c" then
			if Aiming then
				Crouching = not Crouching
			end
		elseif k == "z" then
			if Zoomed then
				setZoom(false)
			elseif Aiming then
				setZoom(true)
			end
		elseif k == "fire" then
			aimCenter = true
			Fire()
		end
	end
	C.click = function()
		aimCenter = false
		Fire()
	end

	C.tick = function()
		lastRigCF = C.rootCF()
	end

	C.afterFrame = function()
		updateGun()
		updateRock()
	end
	C.optChanged = function(name)
		if name == "unli" and OPT.unli and not reloading then
			Ammo = SNIPER.Ammo
			Depleted = false
		end
	end
	return C
end

local function keysNote(C)
	C.notify("The Sniper", "F aim, then click / tap to fire (it reloads by itself when it's empty). Z scope, C crouch, R reload. " .. string.upper(SNIPER.AlignKey) .. " opens the align panel (Gun / Muzzle / Scope, Flip / Roll if the gun is backwards or upside down).\nChat: -unli bullet, -no cooldown, -stop", 12)
end

local busy = false
local stops = 0
local lastCmdAt = -10
local placeToken = 0
local lpp = game:GetService("Players").LocalPlayer

local function placeAt(cf)
	if not cf then
		return
	end
	placeToken += 1
	local my = placeToken
	local target = CFrame.new(cf.Position + Vector3.new(0, 0.5, 0)) * (cf - cf.Position)
	local function put(ch)
		local hrp = ch:WaitForChild("HumanoidRootPart", 5)
		if not hrp or placeToken ~= my then
			return
		end
		for _ = 1, 12 do
			if placeToken ~= my or hrp.Parent ~= ch then
				return
			end
			pcall(function()
				ch:PivotTo(target)
				hrp.AssemblyLinearVelocity = Vector3.zero
			end)
			task.wait(0.05)
		end
	end
	local ch = lpp.Character
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	if ch and hum and hum.Health > 0 and ch:FindFirstChild("HumanoidRootPart") then
		task.spawn(put, ch)
	end
	local con
	con = lpp.CharacterAdded:Connect(function(newc)
		con:Disconnect()
		if placeToken == my then
			put(newc)
		end
	end)
	task.delay(20, function()
		if con.Connected then
			con:Disconnect()
		end
	end)
end

local stopCmd
local function runCmd()
	if busy or os.clock() - lastCmdAt < 2 then
		return
	end
	lastCmdAt = os.clock()
	placeToken += 1
	if current and current.alive then
		note("already running, type -stop to stop")
		return
	end
	busy = true
	local myStop = stops
	local ok, res = pcall(startSniper)
	busy = false
	if stops ~= myStop then
		if current and current.alive then
			pcall(current.stop, true)
		end
		current = nil
		return
	end
	if not ok then
		warn("[The Sniper] " .. tostring(res))
		note("couldnt start, check F9")
		if current and current.alive then
			pcall(current.stop, true)
		end
		current = nil
	elseif not (current and current.alive) then
		note("reanimate didnt start, try -run again")
	else
		current.requestStop = function()
			stopCmd()
		end
		keysNote(current)
	end
end
stopCmd = function(noPlace)
	stops += 1
	busy = false
	lastCmdAt = os.clock()
	local spot = (current and current.alive and current.rootCF()) or lastRigCF
	local did = false
	if current and current.alive then
		local c = current
		current = nil
		pcall(c.stop, true)
		did = true
	end
	current = nil
	if type(_G.LCFD_Stop) == "function" then
		pcall(_G.LCFD_Stop, true)
		did = true
	end
	local ok, re = pcall(FD.isReanimated)
	if ok and re then
		pcall(FD.stopreanimate)
		did = true
	end
	if did and noPlace ~= true then
		task.spawn(placeAt, spot)
	end
	lastRigCF = nil
	note(did and "stopped. -run to start again" or "not running. type -run to start")
end

local function onOff(arg, cur)
	arg = string.lower(arg or "")
	if arg == "on" or arg == "enable" or arg == "true" or arg == "1" then
		return true
	elseif arg == "off" or arg == "disable" or arg == "false" or arg == "0" then
		return false
	end
	return not cur
end
local function setOpt(name, on)
	OPT[name] = on
	if current and current.alive and current.optChanged then
		pcall(current.optChanged, name)
	end
end
local function zoomCmd(arg)
	setOpt("zoom", onOff(arg, OPT.zoom))
	note(OPT.zoom and "zoom on: Z looks through the scope" or "zoom off: Z just brings the scope up to your eye")
end
local function unliCmd(arg)
	setOpt("unli", onOff(arg, OPT.unli))
	note(OPT.unli and "unli bullets on: it never runs out" or "unli bullets off: " .. SNIPER.Ammo .. " a magazine again")
end
local function cooldownCmd(arg)
	setOpt("nocd", onOff(arg, OPT.nocd))
	note(OPT.nocd and "no cooldown on: every click shoots" or "no cooldown off: you work the bolt after each shot again")
end

local lastCmd, lastAt = "", 0
local function onChat(msg)
	if type(msg) ~= "string" then
		return
	end
	msg = msg:gsub("\226\128\147", "-"):gsub("\226\128\148", "-"):gsub("\226\136\146", "-"):gsub("\226\128\139", "")
	local m = (msg:gsub("^%s+", ""):gsub("%s+$", ""))
	local body
	if string.lower(m:sub(1, 3)) == "/e " then
		body = m:sub(4)
	elseif m:sub(1, 1) == "-" then
		body = m
	else
		return
	end
	body = string.lower((body:gsub("^%s+", ""):gsub("^%-", "")))
	local name, arg = body:match("^(%S+)%s*(.-)%s*$")
	if not name then
		return
	end
	local run
	if name == "run" or name == "stop" then
		run = name
	elseif name == "zoom" then
		run = "zoom"
	elseif name == "unli" or name == "unlimited" or name == "unlibullet" or name == "unlibullets" or name == "unliammo" then
		run = "unli"
		arg = arg:gsub("^bullets?%s*", ""):gsub("^ammo%s*", "")
	elseif name == "nocooldown" or name == "nocd" then
		run = "cd"
	elseif name == "no" and (arg:match("^cooldown") or arg:match("^cd")) then
		run = "cd"
		arg = arg:gsub("^cooldown%s*", ""):gsub("^cd%s*", "")
	elseif name == "cooldown" then
		run = "cd"
		arg = "off"
	else
		return
	end
	local now = os.clock()
	if body == lastCmd and now - lastAt < 1 then
		return
	end
	lastCmd, lastAt = body, now
	if run == "run" then
		task.spawn(runCmd)
	elseif run == "stop" then
		task.spawn(stopCmd)
	elseif run == "zoom" then
		zoomCmd(arg)
	elseif run == "unli" then
		unliCmd(arg)
	else
		cooldownCmd(arg)
	end
end
local chatCons = {}
pcall(function()
	chatCons[#chatCons + 1] = lpp.Chatted:Connect(onChat)
end)
pcall(function()
	local TCS = game:GetService("TextChatService")
	chatCons[#chatCons + 1] = TCS.SendingMessage:Connect(function(message)
		onChat(message.Text)
	end)
	chatCons[#chatCons + 1] = TCS.MessageReceived:Connect(function(message)
		local src = message.TextSource
		if src and src.UserId == lpp.UserId then
			onChat(message.Text)
		end
	end)
end)
_G.TheSniperCommands = {
	version = VERSION,
	run = runCmd,
	stop = stopCmd,
	kill = function()
		for _, c in ipairs(chatCons) do
			pcall(function()
				c:Disconnect()
			end)
		end
		if current and current.alive then
			pcall(current.stop, true)
		end
		current = nil
	end,
}
note('Do "-run" to run the script, and "-stop" to stop the script.')
