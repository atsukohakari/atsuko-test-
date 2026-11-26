local function hubNotify(title, text, kind, dur)
	local env = (typeof(getgenv) == "function" and getgenv()) or _G
	local f = env.AtsukoNotify
	if type(f) == "function" then
		return pcall(f, title, text, kind, dur)
	end
	return pcall(warn, "[" .. tostring(title) .. "] " .. tostring(text))
end
local IW_OK, IW_ERR = pcall(function()
hubNotify("Internal War", "Loading...", "info", 3)
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
local vmagnitude=(type(vector)=="table" and vector.magnitude) or function(v) return v.Magnitude end
local vnormalize=(type(vector)=="table" and vector.normalize) or function(v) return v.Unit end

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
local QueryDescendants
do
	local okq,fq=pcall(insGet,game,"QueryDescendants")
	if okq and type(fq)=="function" then
		QueryDescendants=fq
	else
		QueryDescendants=function(root,sel)
			local direct=string.sub(sel,1,1)==">"
			if direct then
				sel=string.sub(sel,2)
			end
			local class=string.match(sel,"^[%w_]+")
			local nm=string.match(sel,"#([^%[%s]+)") or string.match(sel,"%[Name=\"([^\"]*)\"%]")
			local out={}
			local list=direct and root:GetChildren() or root:GetDescendants()
			for _,o in ipairs(list) do
				if (not class or o:IsA(class)) and (not nm or o.Name==nm) then
					out[#out+1]=o
				end
			end
			return out
		end
	end
end
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
	local smoothNet=true
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
		local netY=25.01
		local idleav=idlerv
		if smoothNet then
			local sm=sine*14
			idlerv=v3(sin(sm),sin(sm*1.0714285714285714+1.0471975511965976),sin(sm*1.1428571428571428+2.0943951023931953))
			idleoff=idlerv*0.001
			idleav=idleoff
			netY=25.01+(sin(sine*0.5)+1)*0.5
		end
		local function netVel(vel1)
			if smoothNet then
				local h=vel1*v3_101
				local m=vmagnitude(h)
				if m>netY then h=h*(netY/m) end
				return v3(v3Get(h,"X"),netY,v3Get(h,"Z"))
			end
			if vmagnitude(vel1)>25.01 then
				return vnormalize(vel1)*v3_xzL+v3_net
			end
			return vel1*v3_xz+v3_net
		end

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
							insSet(part,"AssemblyLinearVelocity",netVel(vel*noYvelTime+xzvel))
						end
					else
						i.c=sine
						insSet(part,"AssemblyLinearVelocity",netVel(vel*noYvelTime+xzvel))
					end
					insSet(part,"CFrame",v)
					insSet(part,"AssemblyAngularVelocity",idleav)
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

local function IWCore(FD, CFG)
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

	if type(_G.IWFD_Stop) == "function" then
		pcall(_G.IWFD_Stop)
	end
	if FD.isReanimated() then
		FD.stopreanimate()
	end
	local fd, fdErr
	for _ = 1, 2 do
		local okR, r = pcall(FD.reanimate)
		if okR then
			fd = r
		else
			fdErr = tostring(r)
		end
		if fd then
			break
		end
	end
	if not fd then
		local why = fdErr or "it returned nothing. Rejoin and run it again, another FDless script can be in the way"
		warn("[Internal War] FDless did not start: " .. why)
		hubNotify("Internal War: FDless did not start", string.sub(why, 1, 200), "error", 25)
		pcall(function()
			if setclipboard then
				setclipboard("Internal War: FDless did not start: " .. why)
			end
		end)
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
	local errs, errCount = {}, 0
	function C.err(e)
		e = tostring(e)
		if not errs[e] then
			errs[e] = true
			warn("[Internal War] " .. e)
			errCount += 1
			if errCount <= 3 then
				C.notify("Internal War error", string.sub(e, 1, 180), 10)
			end
		end
	end

	local Effects = Instance.new("Folder")
	Effects.Name = "IWFX" .. random(1000, 9999)
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
	music.Volume = 1.5
	music.Parent = Effects
	C.music = music

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

	local lastLerp, lastStep = osclock(), osclock()
	local acc = 0
	C.alpha = 1

	function C.start(onFrame)
		local function frame(state)
			if not C.alive then
				return
			end
			lastLerp = osclock()
			C.state = state
			local ok, e = pcall(onFrame, state, C.alpha)
			if not ok then
				C.err(e)
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
			acc += dt
			local n = floor(acc * 60)
			acc -= n / 60
			if n > 4 then
				n = 4
				acc = 0
			end
			for _ = 1, n do
				C.ticks += 1
				if C.snapshot then
					local ok, e = pcall(C.snapshot)
					if not ok then
						C.err(e)
					end
				end
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
			C.alpha = math.clamp(acc * 60, 0, 1)
		end)
	end

	C.keysDown = {}
	C.connect(UIS.InputBegan, function(io, gp)
		if io.UserInputType == KEYBOARD then
			if gp or UIS:GetFocusedTextBox() then
				return
			end
			local name = string.lower(io.KeyCode.Name)
			C.keysDown[name] = true
			if C.keyDown then
				task.spawn(C.keyDown, name)
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
		end
	end)

	function C.stop(stopReanimate)
		if not C.alive then
			return
		end
		C.alive = false
		if _G.IWFD_Stop == C.stop then
			_G.IWFD_Stop = nil
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
	_G.IWFD_Stop = C.stop

	return C
end


local IW = {
	TitanSizeVoid = 1,
	TitanSizeUGC = 1.8,
	AlignKey = "p",
	Music = true,
	MusicVolume = 1.5,
	WalkSpeed = 16,
}

if not game:IsLoaded() then
	game.Loaded:Wait()
end

local C = IWCore(FD, {maxEffects = 420})
if not C then
	return
end
local fd = C.fd

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Debris = game:GetService("Debris")
local lp = Players.LocalPlayer
local CF, VT, C3 = CFrame.new, Vector3.new, Color3.new
local ANGLES = CFrame.Angles
local RAD, MRANDOM, SIN, COS = math.rad, math.random, math.sin, math.cos
local CLAMP = math.clamp
local IDENT = CFrame.identity
local onPhone = UIS.TouchEnabled and not UIS.KeyboardEnabled
local Swait = C.swait
local Effects = C.Effects
local Character = lp.Character

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
local function note(text)
	C.notify("Internal War", text, 4)
end
local function Clerp(a, b, t)
	return a:Lerp(b, t)
end

local Animation_Speed = 3
local Speed = IW.WalkSpeed
local ROOTC0 = CF(0, 0, 0) * ANGLES(RAD(-90), RAD(0), RAD(180))
local NECKC0 = CF(0, 1, 0) * ANGLES(RAD(-90), RAD(0), RAD(180))
local RIGHTSHOULDERC0 = CF(-0.5, 0, 0) * ANGLES(RAD(0), RAD(90), RAD(0))
local LEFTSHOULDERC0 = CF(0.5, 0, 0) * ANGLES(RAD(0), RAD(-90), RAD(0))
local ANIM = "Idle"
local ATTACK = false
local EQUIPPED = false
local Rooted = false
local SINE = 0
local CHANGE = 2 / Animation_Speed
local UNANCHOR = true
local REPLAY = false
local E = 1.32
local ROAR = 528589078
local Disable_Jump = false
local KEY
local ghostOn = false

local DEFSIZE = {void = IW.TitanSizeVoid or 1, ugc = IW.TitanSizeUGC or 1.8}
local SET = {file = "InternalWarSettings.json", void = DEFSIZE.void, ugc = DEFSIZE.ugc}
pcall(function()
	if isfile and isfile(SET.file) then
		local t = HttpService:JSONDecode(readfile(SET.file))
		if type(t) == "table" then
			if type(t.sizeVoid) == "number" and t.sizeVoid == t.sizeVoid then
				SET.void = CLAMP(t.sizeVoid, 0.001, 20)
			end
			if type(t.sizeUgc) == "number" and t.sizeUgc == t.sizeUgc then
				SET.ugc = CLAMP(t.sizeUgc, 0.001, 20)
			end
		end
	end
end)
local function saveSettings()
	pcall(function()
		writefile(SET.file, HttpService:JSONEncode({sizeVoid = SET.void, sizeUgc = SET.ugc}))
	end)
end
local TS = {set = "void", goal = SET.void, k = SET.void}
local T0 = os.clock()
local SIZE, TK = 2, TS.k

local JL = {}
local function newJ(c0, c1)
	local j = {C0 = c0, C1 = c1, pC0 = c0, pC1 = c1}
	JL[#JL + 1] = j
	return j
end
local RSC1 = CF(-0.5, 0.5, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0)
local LSC1 = CF(0.5, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0)
local RootJoint = newJ(ROOTC0, ROOTC0)
local Neck = newJ(NECKC0, CF(0, -0.5, 0) * ANGLES(RAD(-90), RAD(0), RAD(180)))
local RightShoulder = newJ(CF(1.5, 0.5, 0) * RIGHTSHOULDERC0, RSC1)
local LeftShoulder = newJ(CF(-1.5, 0.5, 0) * LEFTSHOULDERC0, LSC1)
local RightHip = newJ(CF(1, -1, 0) * ANGLES(0, RAD(90), 0), CF(0.5, 1, 0) * ANGLES(0, RAD(90), 0))
local LeftHip = newJ(CF(-1, -1, 0) * ANGLES(0, RAD(-90), 0), CF(-0.5, 1, 0) * ANGLES(0, RAD(-90), 0))
local simJ = {RootJoint, Neck, RightShoulder, LeftShoulder, RightHip, LeftHip}
local fdJ = {C.RootJoint, C.Neck, C.RightShoulder, C.LeftShoulder, C.RightHip, C.LeftHip}

local RootJoint2 = newJ(ROOTC0, ROOTC0)
local Neck2 = newJ(NECKC0 * CF(0, 0, SIZE - 1), CF(0, -0.5 * SIZE, 0) * ANGLES(RAD(-90), 0, RAD(180)))
local RightShoulder2 = newJ(CF(1.5 * SIZE, 0.5 * SIZE, 0) * RIGHTSHOULDERC0, CF(0, 0.5 * SIZE, -0.35 * SIZE))
local LeftShoulder2 = newJ(CF(-1.5 * SIZE, 0.5 * SIZE, 0) * LEFTSHOULDERC0, CF(0, 0.5 * SIZE, -0.35 * SIZE))
local RightHip2 = newJ(CF(SIZE, -SIZE, 0) * ANGLES(0, RAD(90), 0), CF(0.5 * SIZE, SIZE, 0) * ANGLES(0, RAD(90), 0))
local LeftHip2 = newJ(CF(-SIZE, -SIZE, 0) * ANGLES(0, RAD(-90), 0), CF(-0.5 * SIZE, SIZE, 0) * ANGLES(0, RAD(-90), 0))

local T = {R2 = C.rootCF() * CF(0, -20 * TK, 5 * TK), pR2 = nil}
T.pR2 = T.R2
local function jv(j, a)
	if a then
		return j.pC0:Lerp(j.C0, a), j.pC1:Lerp(j.C1, a)
	end
	return j.C0, j.C1
end
local function scaleAbout(rp, k, cf)
	if k == 1 then
		return cf
	end
	return CF(rp + (cf.Position - rp) * k) * cf.Rotation
end
local function titanPose(R2, a, out)
	local c0, c1 = jv(RootJoint2, a)
	local torso = R2 * c0 * c1:Inverse()
	local rp = R2.Position
	local k = TK
	out.torso = scaleAbout(rp, k, torso)
	c0, c1 = jv(Neck2, a)
	out.head = scaleAbout(rp, k, torso * c0 * c1:Inverse())
	c0, c1 = jv(RightShoulder2, a)
	out.rarm = scaleAbout(rp, k, torso * c0 * c1:Inverse())
	c0, c1 = jv(LeftShoulder2, a)
	out.larm = scaleAbout(rp, k, torso * c0 * c1:Inverse())
	c0, c1 = jv(RightHip2, a)
	out.rleg = scaleAbout(rp, k, torso * c0 * c1:Inverse())
	c0, c1 = jv(LeftHip2, a)
	out.lleg = scaleAbout(rp, k, torso * c0 * c1:Inverse())
	return out
end
local function ghostTransparency()
	return CLAMP(E + 0.15 * SIN(SINE / 12), 0, 1)
end
local TPcur = {}
local function titanPart(key, bx, by, bz)
	local base = VT(bx, by, bz)
	return setmetatable({}, {
		__index = function(_, k)
			if k == "CFrame" then
				return titanPose(T.R2, nil, TPcur)[key]
			elseif k == "Position" then
				return titanPose(T.R2, nil, TPcur)[key].Position
			elseif k == "Size" then
				return base * SIZE * TK
			elseif k == "Transparency" then
				return ghostTransparency()
			end
			return nil
		end,
		__newindex = function() end,
	})
end
local Head2 = titanPart("head", 1, 1, 1)
local Torso2 = titanPart("torso", 2, 2, 1)
local RightArm2 = titanPart("rarm", 1, 2, 1)
local LeftArm2 = titanPart("larm", 1, 2, 1)
local RightLeg2 = titanPart("rleg", 1, 2, 1)
local LeftLeg2 = titanPart("lleg", 1, 2, 1)
local RootPart2 = setmetatable({}, {
	__index = function(_, k)
		if k == "CFrame" then
			return T.R2
		elseif k == "Position" then
			return T.R2.Position
		end
		return nil
	end,
	__newindex = function(_, k, v)
		if k == "CFrame" then
			T.R2 = v
		end
	end,
})
local SHADOW = setmetatable({}, {
	__index = function(_, k)
		if k == "SetPrimaryPartCFrame" then
			return function(_, cf)
				T.R2 = cf
				T.pR2 = cf
			end
		elseif k == "GetChildren" then
			return function()
				return {}
			end
		end
		return nil
	end,
	__newindex = function(_, k, v)
		if k == "Parent" then
			ghostOn = v ~= nil
		end
	end,
})

local RP = {has = false, cf = IDENT, pcf = IDENT}
local YAW = {last = nil, rate = 0}
local function actualRoot()
	return RP.has and RP.cf or C.rootCF()
end
local RootPart = setmetatable({}, {
	__index = function(_, k)
		if k == "CFrame" then
			return actualRoot()
		elseif k == "Position" then
			return actualRoot().Position
		elseif k == "Orientation" then
			local x, y, z = actualRoot():ToOrientation()
			return VT(math.deg(x), math.deg(y), math.deg(z))
		elseif k == "Velocity" then
			return C.vel()
		elseif k == "RotVelocity" then
			return VT(0, YAW.rate, 0)
		end
		return nil
	end,
	__newindex = function(_, k, v)
		if k == "CFrame" then
			if not RP.has then
				RP.pcf = C.rootCF()
			end
			RP.cf = v
			RP.has = true
		elseif k == "Orientation" then
			local pos = actualRoot().Position
			if not RP.has then
				RP.pcf = C.rootCF()
			end
			RP.cf = CF(pos) * CFrame.fromOrientation(RAD(v.X), RAD(v.Y), RAD(v.Z))
			RP.has = true
		end
	end,
})
local ROT = setmetatable({}, {
	__index = function(_, k)
		if k == "RotVelocity" then
			return VT(0, YAW.rate, 0)
		end
		return nil
	end,
	__newindex = function() end,
})
local Torso, Head, RightArm, LeftArm, RightLeg, LeftLeg = ROT, ROT, ROT, ROT, ROT, ROT

local HS = {walk = Speed}
local Humanoid = setmetatable({}, {
	__index = function(_, k)
		if k == "WalkSpeed" then
			return HS.walk
		end
		return nil
	end,
	__newindex = function(_, k, v)
		if k == "WalkSpeed" and type(v) == "number" then
			HS.walk = v
		end
	end,
})

local function setRootCF(cf)
	fd.setCfr(cf)
	fd.cframes[C.Root] = cf
end

local function TF(x, y, z)
	return RootPart.CFrame * CF(x * TK, y * TK, z * TK)
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
local function newSignal()
	local s = {list = {}}
	function s:connect(fn)
		local c = {fn = fn, dead = false}
		self.list[#self.list + 1] = c
		function c:Disconnect()
			c.dead = true
			local i = table.find(s.list, c)
			if i then
				table.remove(s.list, i)
			end
		end
		return c
	end
	s.Connect = s.connect
	return s
end
local Mouse = setmetatable({KeyDown = newSignal(), KeyUp = newSignal(), Button1Down = newSignal(), Button1Up = newSignal()}, {
	__index = function(_, k)
		if k == "Hit" then
			return CF(AimPoint())
		end
		return nil
	end,
})

local function Raycast(POSITION, DIRECTION, RANGE, IGNORE)
	return C.ray(POSITION, DIRECTION, RANGE, IGNORE)
end
local function CreateSound(ID, PARENT, VOLUME, PITCH, DOESLOOP)
	return C.sound(ID, VOLUME, PITCH, DOESLOOP == true)
end
local function WACKYEFFECT(Table)
	C.Effect(Table)
end
local function CreatePart(FORMFACTOR, PARENT, MATERIAL, REFLECTANCE, TRANSPARENCY, BRICKCOLOR, NAME, SIZE_, ANCHOR)
	local p = C.newPart({Name = NAME, Size = SIZE_, Material = MATERIAL, Reflectance = REFLECTANCE, Transparency = TRANSPARENCY, Parent = PARENT})
	p.Anchored = ANCHOR ~= false
	pcall(function()
		p.BrickColor = typeof(BRICKCOLOR) == "BrickColor" and BRICKCOLOR or BrickColor.new(tostring(BRICKCOLOR))
	end)
	return p
end
local function GetRoot(MODEL, ROOT)
	if ROOT == true then
		return MODEL:FindFirstChild("HumanoidRootPart") or MODEL:FindFirstChild("Torso") or MODEL:FindFirstChild("UpperTorso")
	else
		return MODEL:FindFirstChild("Torso") or MODEL:FindFirstChild("UpperTorso")
	end
end
local function isMine(model)
	return model == Character or (Character ~= nil and model:IsDescendantOf(Character))
end
local function CreateFlyingDebree(FLOOR, POSITION, AMOUNT, BLOCKSIZE, SWAIT, STRENGTH)
	if FLOOR ~= nil then
		for i = 1, AMOUNT do
			do
				local DEBREE = CreatePart(3, Effects, "Neon", FLOOR.Reflectance, FLOOR.Transparency, "Peal", "Debree", BLOCKSIZE, false)
				DEBREE.Material = FLOOR.Material
				DEBREE.Color = FLOOR.Color
				DEBREE.CFrame = POSITION * ANGLES(RAD(MRANDOM(-360, 360)), RAD(MRANDOM(-360, 360)), RAD(MRANDOM(-360, 360)))
				DEBREE.AssemblyLinearVelocity = VT(MRANDOM(-STRENGTH, STRENGTH), MRANDOM(-STRENGTH, STRENGTH), MRANDOM(-STRENGTH, STRENGTH))
				coroutine.resume(coroutine.create(function()
					Swait(15)
					DEBREE.Parent = workspace
					DEBREE.CanCollide = true
					Debris:AddItem(DEBREE, SWAIT)
				end))
			end
		end
	end
end

local FACE = {parts = {}, on = false}
local function FacialShadow()
	local SHADOWS = {}
	for i = 1, 16 do
		local p = C.newPart({Name = "FaceGradient", Size = VT(1.01, 0.65, 1.01), Color = C3(0, 0, 0), Material = Enum.Material.Fabric, Transparency = (i - 1) / 16.2})
		local m = Instance.new("SpecialMesh")
		m.MeshType = Enum.MeshType.Head
		m.Scale = VT(1.25, 1.25, 1.25)
		m.Parent = p
		SHADOWS[i] = p
	end
	FACE.parts = SHADOWS
	FACE.on = true
	return function()
		FACE.on = false
		for i = 1, #SHADOWS do
			SHADOWS[i]:Destroy()
		end
		FACE.parts = {}
	end
end

local ALIGNFILE = "InternalWarAlign.json"
local ALIGN = {{0, 0, 0, 0, 0, 0}, {0, 0, 0, 0, 0, 0}, {0, 0, 0, 0, 0, 0}, {0, 0, 0, 0, 0, 0}}
local TABNAME = {"Head", "Torso", "Arms", "Legs"}
local ALIGN2 = {{0, 0, 0, 0, 0, 0}, {0, 0, 0, 0, 0, 0}, {0, 0, 0, 0, 0, 0}, {0, 0, 0, 0, 0, 0}, {0, 0, 0, 0, 0, 0}}
local TABNAME2 = {"Torso", "R Arm", "L Arm", "R Leg", "L Leg"}
local KEYS2 = {"UTorso", "URArm", "ULArm", "URLeg", "ULLeg"}
local LEARN = {}
local function readNums(dst, a)
	if type(a) == "table" then
		for k = 1, 6 do
			local n = tonumber(a[k])
			if n and n == n and math.abs(n) < 1e5 then
				dst[k] = n
			end
		end
	end
end
local function loadAlign()
	pcall(function()
		if isfile and isfile(ALIGNFILE) then
			local t = HttpService:JSONDecode(readfile(ALIGNFILE))
			if type(t) == "table" then
				for i = 1, 4 do
					readNums(ALIGN[i], t[TABNAME[i]])
				end
				for i = 1, 5 do
					readNums(ALIGN2[i], t[KEYS2[i]])
				end
				if type(t.learned) == "table" then
					for k, v in pairs(t.learned) do
						if type(k) == "string" and type(v) == "string" and v:match("^%d+$") then
							LEARN[k] = v
						end
					end
				end
			end
		end
	end)
end
local function saveAlign()
	local t = {learned = LEARN}
	for i = 1, 4 do
		t[TABNAME[i]] = ALIGN[i]
	end
	for i = 1, 5 do
		t[KEYS2[i]] = ALIGN2[i]
	end
	local ok = pcall(function()
		writefile(ALIGNFILE, HttpService:JSONEncode(t))
	end)
	return ok
end
loadAlign()

local function idOf(s)
	if type(s) ~= "string" then
		return ""
	end
	local m = s:match("[?&]id=(%d+)") or s:match("rbxassetid://(%d+)") or s:match("/asset/(%d+)")
	if m then
		return m
	end
	local best = ""
	for d in s:gmatch("%d+") do
		if #d > #best then
			best = d
		end
	end
	return best
end
local function hasId(s, id)
	return type(s) == "string" and type(id) == "string" and id ~= "" and s:find(id, 1, true) ~= nil
end
local RIG = {
	{key = "head", mesh = "17375312569", pos = VT(0, 2.75, 0), rot = ANGLES(0, 3.15, 0), tab = 1, nextScan = 0},
	{key = "torso", mesh = "17269636541", pos = VT(0, 0, 0), rot = IDENT, tab = 2, alt = {"torso"}, tab2 = 1, nextScan = 0},
	{key = "rarm", mesh = "17269487439", pos = VT(0, 0, 0), rot = ANGLES(0, 0, 1.57), tab = 3, alt = {"rarm", "rightarm"}, tab2 = 2, nextScan = 0},
	{key = "larm", mesh = "17269487439", pos = VT(0, 0, 0), rot = ANGLES(0, 0, 1.57), tab = 3, left = true, alt = {"larm", "leftarm"}, tab2 = 3, nextScan = 0},
	{key = "rleg", mesh = "17269487439", pos = VT(0, 0, 0), rot = ANGLES(0, -1.57, -1.57), tab = 4, alt = {"rleg", "rightleg"}, tab2 = 4, nextScan = 0},
	{key = "lleg", mesh = "17269487439", pos = VT(0, 0, 0), rot = ANGLES(0, -1.57, -1.57), tab = 4, left = true, alt = {"lleg", "leftleg"}, tab2 = 5, nextScan = 0},
}
local function hatOk(h)
	return h.e ~= nil and h.j ~= nil and fd.cframes[h.e] ~= nil
end
local function restore(h)
	local j, home = h.j, h.home
	if j and home then
		pcall(function()
			j.Part1, j.C0, j.C1 = home[1], home[2], home[3]
		end)
	end
end
local function glue(h, part, rel)
	local j = h.j
	j.Part1 = part
	j.C0 = IDENT
	j.C1 = rel
end
local function accName(e)
	local ok, n = pcall(function()
		local par = rawget(e, "p").Parent
		if par and par:IsA("Accessory") then
			return par.Name
		end
	end)
	if ok and type(n) == "string" then
		return (string.lower(n):gsub("[^%w]", ""))
	end
	return nil
end
local function hubJob(slot, e)
	local A = ((typeof(getgenv) == "function" and getgenv()) or _G).AtsukoAlignment
	if type(A) ~= "table" or type(A.match) ~= "function" or type(e) ~= "table" then
		return nil
	end
	local ok, row = pcall(A.match, "InternalWar", slot, {mesh = idOf(rawget(e, "m")), tex = idOf(rawget(e, "t")), name = accName(e)})
	return ok and type(row) == "table" and row.src == "user" and row or nil
end
local UGCMETA = {}
local UGCIDS = {torso = "118799338103138", rarm = "132416515427938", larm = "101379144205559", rleg = "80628080423002", lleg = "121360936156823"}
local function uniqueMetaName(key)
	local m = UGCMETA[key]
	if not m or not m.name or m.name == "" or m.name == "accessory" then
		return nil
	end
	for k, o in pairs(UGCMETA) do
		if k ~= key and o.name == m.name then
			return nil
		end
	end
	return m.name
end
local function nameMatch(h, e)
	if not h.alt then
		return false
	end
	local n = accName(e)
	if not n or n == "" then
		return false
	end
	if n == uniqueMetaName(h.key) then
		return true
	end
	for _, a in ipairs(h.alt) do
		if n == a then
			return true
		end
		if #a >= 4 and h.key ~= "torso" and n:find(a, 1, true) then
			return true
		end
	end
	return false
end
local function sizeOf(e)
	local ok, s = pcall(function()
		return rawget(e, "p").Size
	end)
	if ok and s and s.X and s.X > 0 and s.Y > 0 and s.Z > 0 then
		return s
	end
	return nil
end
local function autoRot(h, s)
	if not s then
		return IDENT
	end
	local x, y, z = s.X, s.Y, s.Z
	if h.key == "torso" then
		if z <= math.min(x, y) * 1.1 then
			return IDENT
		end
		if x <= y then
			return ANGLES(0, RAD(-90), 0)
		end
		return ANGLES(RAD(90), 0, 0)
	end
	if y >= math.max(x, z) * 0.9 then
		return IDENT
	end
	if x >= z then
		return ANGLES(0, 0, RAD(90))
	end
	return ANGLES(RAD(-90), 0, 0)
end
local function claim(h, e, set)
	local j = fd.getPartJoint(e)
	if not j then
		return false
	end
	h.e, h.j, h.home, h.set = e, j, {j.Part1, j.C0, j.C1}, set
	h.auto = set == 2 and autoRot(h, sizeOf(e)) or IDENT
	if set == 2 then
		local m = idOf(rawget(e, "m"))
		if m ~= "" and LEARN[h.key] ~= m and not UGCMETA[h.key] then
			LEARN[h.key] = m
			saveAlign()
		end
	end
	return true
end
local function scanHats()
	local t = os.clock()
	local claimed = {}
	local need = {}
	for _, h in ipairs(RIG) do
		if hatOk(h) then
			claimed[h.e] = true
		end
	end
	for _, h in ipairs(RIG) do
		if not hatOk(h) and t >= h.nextScan then
			h.nextScan = t + 0.5
			if h.e then
				restore(h)
			end
			h.e, h.j, h.home, h.set, h.auto = nil, nil, nil, nil, nil
			need[#need + 1] = h
		end
	end
	if #need == 0 then
		return
	end
	for pass = 0, 3 do
		for _, h in ipairs(need) do
			if not h.e and (pass == 0 or pass == 3 or h.alt) then
				for e in pairs(fd.cframes) do
					if type(e) == "table" and rawget(e, "m") ~= nil and rawget(e, "p") and not claimed[e] then
						local rawm = rawget(e, "m")
						local hit
						if pass == 0 then
							hit = hubJob(h.key, e) ~= nil
						elseif pass == 1 then
							hit = LEARN[h.key] ~= nil and hasId(rawm, LEARN[h.key])
						elseif pass == 2 then
							hit = nameMatch(h, e)
						else
							hit = hasId(rawm, h.mesh)
						end
						if hit and claim(h, e, (pass == 3 or (pass == 0 and not h.tab2)) and 1 or 2) then
							claimed[e] = true
							break
						end
					end
				end
			end
		end
	end
end
C.onStop(function()
	for _, h in ipairs(RIG) do
		restore(h)
	end
end)
local function hatOffset(h)
	if h.set == 2 then
		local o = ALIGN2[h.tab2]
		return CF(o[1], o[2], o[3]) * (h.auto or IDENT) * ANGLES(RAD(o[4]), RAD(o[5]), RAD(o[6]))
	end
	local o = ALIGN[h.tab]
	local x = o[1]
	if h.left then
		x = -x
	end
	return CF(h.pos * TK + VT(x, o[2], o[3])) * h.rot * ANGLES(RAD(o[4]), RAD(o[5]), RAD(o[6]))
end
local function loadCatalog(id)
	local ok, objs = pcall(function()
		return game:GetObjects("rbxassetid://" .. id)
	end)
	if ok and type(objs) == "table" and objs[1] then
		return objs[1]
	end
	local ok2, m = pcall(function()
		return game:GetService("InsertService"):LoadAsset(tonumber(id))
	end)
	if ok2 and m then
		return m
	end
	return nil
end
local function readHandle(root)
	local acc = root
	if not root:IsA("Accessory") then
		acc = root:FindFirstChildWhichIsA("Accessory", true)
	end
	if not acc then
		return nil
	end
	local handle = acc:FindFirstChild("Handle")
	if not handle then
		return nil
	end
	local mesh, tex
	if handle:IsA("MeshPart") then
		mesh, tex = handle.MeshId, handle.TextureID
	else
		local sm = handle:FindFirstChildOfClass("SpecialMesh")
		if sm then
			mesh, tex = sm.MeshId, sm.TextureId
		end
	end
	return {name = (string.lower(acc.Name):gsub("[^%w]", "")), mesh = idOf(mesh), tex = idOf(tex), size = handle.Size}
end
for key, id in pairs(UGCIDS) do
	task.spawn(function()
		local ok, root = pcall(loadCatalog, id)
		if ok and root then
			local ok2, meta = pcall(readHandle, root)
			if ok2 and meta and meta.mesh ~= "" then
				UGCMETA[key] = meta
				if LEARN[key] ~= meta.mesh then
					LEARN[key] = meta.mesh
					saveAlign()
				end
				for _, h in ipairs(RIG) do
					h.nextScan = 0
				end
			end
			pcall(function()
				root:Destroy()
			end)
		end
	end)
end
local function unplacedHats()
	local used = {}
	for _, h in ipairs(RIG) do
		if h.e then
			used[h.e] = true
		end
	end
	local names = {}
	for e in pairs(fd.cframes) do
		if type(e) == "table" and rawget(e, "m") ~= nil and rawget(e, "p") and not used[e] then
			names[#names + 1] = accName(e) or ("mesh " .. idOf(rawget(e, "m")))
		end
	end
	return names
end
local function hatCount()
	local n, u = 0, 0
	for _, h in ipairs(RIG) do
		if hatOk(h) then
			n += 1
			if h.set == 2 then
				u += 1
			end
		end
	end
	return n, u
end
local function hatReport()
	local lines = {}
	for _, h in ipairs(RIG) do
		if hatOk(h) then
			local e = h.e
			local s = sizeOf(e)
			lines[#lines + 1] = string.format("%s: %s | acc %s | mesh %s | tex %s | size %s", h.key, h.set == 2 and "UGC" or "Void", tostring(accName(e)), idOf(rawget(e, "m")), idOf(rawget(e, "t")), s and string.format("%.2f,%.2f,%.2f", s.X, s.Y, s.Z) or "?")
		else
			lines[#lines + 1] = h.key .. ": not found"
		end
	end
	local used = {}
	for _, h in ipairs(RIG) do
		if h.e then
			used[h.e] = true
		end
	end
	for e in pairs(fd.cframes) do
		if type(e) == "table" and rawget(e, "m") ~= nil and rawget(e, "p") and not used[e] then
			local s = sizeOf(e)
			lines[#lines + 1] = string.format("other hat: acc %s | mesh %s | tex %s | size %s", tostring(accName(e)), idOf(rawget(e, "m")), idOf(rawget(e, "t")), s and string.format("%.2f,%.2f,%.2f", s.X, s.Y, s.Z) or "?")
		end
	end
	return table.concat(lines, "\n")
end

local GHOST = {}
do
	local defs = {
		{"head", 1, 1, 1, true}, {"torso", 2, 2, 1}, {"rarm", 1, 2, 1}, {"larm", 1, 2, 1}, {"rleg", 1, 2, 1}, {"lleg", 1, 2, 1},
	}
	for _, d in ipairs(defs) do
		local p = C.newPart({Name = d[1], Size = VT(d[2], d[3], d[4]) * SIZE * TK, Color = C3(1, 1, 1), Material = Enum.Material.Neon, Transparency = 1})
		if d[5] then
			local m = Instance.new("SpecialMesh")
			m.MeshType = Enum.MeshType.Head
			m.Scale = VT(1.25, 1.25, 1.25)
			m.Parent = p
		end
		GHOST[#GHOST + 1] = {key = d[1], p = p, base = VT(d[2], d[3], d[4])}
	end
end

local function applyTitanSize()
	TK = TS.k
	for _, g in ipairs(GHOST) do
		g.p.Size = g.base * SIZE * TK
	end
end
applyTitanSize()
local function wantedSet()
	local n, u = hatCount()
	if u > 0 then
		return "ugc"
	elseif n > 0 then
		return "void"
	end
	return TS.set
end
do
	pcall(scanHats)
	TS.set = wantedSet()
	TS.goal = SET[TS.set]
	TS.k = TS.goal
	applyTitanSize()
	T.R2 = C.rootCF() * CF(0, -20 * TK, 5 * TK)
	T.pR2 = T.R2
end
for _, j in ipairs(JL) do
	j.pC0, j.pC1 = j.C0, j.C1
end

local function ApplyDamage(Humanoid, Damage)
end


;(function()
local function ApplyAoE(POSITION, RANGE, MINDMG, MAXDMG, FLING, INSTAKILL)
	for index, CHILD in pairs(workspace:GetDescendants()) do
		if CHILD.ClassName == "Model" and not isMine(CHILD) then
			local HUM = CHILD:FindFirstChildOfClass("Humanoid")
			if HUM then
				local TORSO = CHILD:FindFirstChild("Torso") or CHILD:FindFirstChild("UpperTorso")
				if TORSO and RANGE >= (TORSO.Position - POSITION).Magnitude then
					if INSTAKILL == true then
						CHILD:BreakJoints()
					else
						local DMG = MRANDOM(MINDMG, MAXDMG)
						ApplyDamage(HUM, DMG)
					end
					if FLING > 0 then
						for _, c in pairs(CHILD:GetChildren()) do
							if c:IsA("BasePart") then
								local bv = Instance.new("BodyVelocity")
								bv.MaxForce = Vector3.new(1000000000, 1000000000, 1000000000)
								bv.Velocity = CF(POSITION, TORSO.Position).LookVector * FLING
								bv.Parent = c
								Debris:AddItem(bv, 0.05)
							end
						end
					end
				end
			end
		end
	end
end
local function Intro()
	EQUIPPED = true
	ATTACK = true
	Rooted = true
	if Rooted == false then
		Disable_Jump = false
		Humanoid.WalkSpeed = Speed
	elseif Rooted == true then
		Disable_Jump = true
		Humanoid.WalkSpeed = 0
	end
	coroutine.resume(coroutine.create(function()
		repeat
			Swait()
			RootPart2.Anchored = true
			for _, c in pairs(SHADOW:GetChildren()) do
				if c:IsA("Part") then
					c.Color = C3(1, 1, 1)
					if c ~= RootPart2 then
						c.Transparency = E + 0.15 * SIN(SINE / 12)
					end
					if c:FindFirstChildOfClass("Decal") then
						c:ClearAllChildren()
					end
					c.CanCollide = false
					c.Material = "Neon"
				else
					c:Destroy()
				end
			end
			RootJoint.C0 = Clerp(RootJoint.C0, ROOTC0 * CF(0, 0, 0) * ANGLES(RAD(-5), RAD(0), RAD(-35)), 1 / Animation_Speed)
			Neck.C0 = Clerp(Neck.C0, NECKC0 * CF(0, 0, 0) * ANGLES(RAD(0), RAD(0), RAD(35)), 1 / Animation_Speed)
			RightShoulder.C0 = Clerp(RightShoulder.C0, CF(1.5, 0.5, 0) * ANGLES(RAD(-1), RAD(0), RAD(3)) * RIGHTSHOULDERC0, 1 / Animation_Speed)
			LeftShoulder.C0 = Clerp(LeftShoulder.C0, CF(-1.5, 0.5, 0) * ANGLES(RAD(-1), RAD(0), RAD(-3)) * LEFTSHOULDERC0, 1 / Animation_Speed)
			RightHip.C0 = Clerp(RightHip.C0, CF(1, -1, -0.01) * ANGLES(RAD(-12), RAD(80), RAD(0)) * ANGLES(RAD(-2), RAD(0), RAD(0)), 1 / Animation_Speed)
			LeftHip.C0 = Clerp(LeftHip.C0, CF(-1, -1, -0.01) * ANGLES(RAD(0), RAD(-60), RAD(0)) * ANGLES(RAD(-2), RAD(0), RAD(0)), 1 / Animation_Speed)
		until ATTACK == false
	end))
	Swait(60)
	SHADOW.Parent = Character
	SHADOW:SetPrimaryPartCFrame(TF(0, -20, 5))
	local HIT, POS = Raycast(TF(0, 0, 5).Position, CF(RootPart.Position, RootPart.Position + VT(0, -1, 0)).LookVector, 4, Character)
	for i = 1, 250 do
		Swait()
		E = E - 0.0032
		local AREA = CF(POS) * ANGLES(RAD(0), RAD(MRANDOM(0, 360)), RAD(0)) * CF(0, 0, MRANDOM(2, 18))
		local TIMER = MRANDOM(20, 80)
		WACKYEFFECT({
			Time = TIMER,
			EffectType = "Sphere",
			Size = VT(1, 1, 1),
			Size2 = VT(0, 45, 0),
			Transparency = 0,
			Transparency2 = 0,
			CFrame = AREA,
			MoveToPos = AREA.Position + VT(0, MRANDOM(35, 160), 0),
			RotationX = 0,
			RotationY = 0,
			RotationZ = 0,
			Material = "Neon",
			Color = C3(1, 1, 1),
			SoundID = nil,
			SoundPitch = 0.8,
			SoundVolume = 5
		})
		RootPart2.CFrame = Clerp(RootPart2.CFrame, TF(0, 6, 5), 0.01)
		RootJoint2.C0 = Clerp(RootJoint2.C0, ROOTC0 * CF(0, 0, 0) * ANGLES(RAD(-5), RAD(0), RAD(0)), 1 / Animation_Speed)
		Neck2.C0 = Clerp(Neck2.C0, NECKC0 * CF(0, 0, 0 + (1 * SIZE - 1)) * ANGLES(RAD(-25), RAD(0), RAD(0)), 1 / Animation_Speed)
		RightShoulder2.C0 = Clerp(RightShoulder2.C0, CF(1.5 * SIZE, 0.5 * SIZE, 0) * ANGLES(RAD(-15), RAD(0), RAD(45)) * RIGHTSHOULDERC0, 1 / Animation_Speed)
		LeftShoulder2.C0 = Clerp(LeftShoulder2.C0, CF(-1.5 * SIZE, 0.5 * SIZE, 0) * ANGLES(RAD(-15), RAD(0), RAD(-45)) * LEFTSHOULDERC0, 1 / Animation_Speed)
		RightHip2.C0 = Clerp(RightHip2.C0, CF(1 * SIZE, -0.7 * SIZE, -0.5 * SIZE) * ANGLES(RAD(-25), RAD(80), RAD(0)) * ANGLES(RAD(-1 * SIN(SINE / 6)), RAD(0), RAD(0)), 1 / Animation_Speed)
		LeftHip2.C0 = Clerp(LeftHip2.C0, CF(-1 * SIZE, -0.7 * SIZE, -0.5 * SIZE) * ANGLES(RAD(-25), RAD(-80), RAD(0)) * ANGLES(RAD(-1 * SIN(SINE / 6)), RAD(0), RAD(0)), 1 / Animation_Speed)
	end
	for i = 0, 0.6, 0.1 / Animation_Speed do
		Swait()
		RootPart2.CFrame = Clerp(RootPart2.CFrame, TF(0, 6, 5), 0.1)
		RootJoint2.C0 = Clerp(RootJoint2.C0, ROOTC0 * CF(0, 0, 0) * ANGLES(RAD(-25), RAD(0), RAD(0)), 1 / Animation_Speed)
		Neck2.C0 = Clerp(Neck2.C0, NECKC0 * CF(0, 0, 0 + (1 * SIZE - 1)) * ANGLES(RAD(-25), RAD(0), RAD(0)), 1 / Animation_Speed)
		RightShoulder2.C0 = Clerp(RightShoulder2.C0, CF(1.5 * SIZE, 0.5 * SIZE, -0.5 * SIZE) * ANGLES(RAD(140), RAD(0), RAD(-25)) * RIGHTSHOULDERC0, 0.5 / Animation_Speed)
		LeftShoulder2.C0 = Clerp(LeftShoulder2.C0, CF(-1.5 * SIZE, 0.5 * SIZE, -0.5 * SIZE) * ANGLES(RAD(140), RAD(0), RAD(25)) * LEFTSHOULDERC0, 0.5 / Animation_Speed)
		RightHip2.C0 = Clerp(RightHip2.C0, CF(1 * SIZE, -0.7 * SIZE, -0.5 * SIZE) * ANGLES(RAD(25), RAD(80), RAD(0)) * ANGLES(RAD(-1 * SIN(SINE / 6)), RAD(0), RAD(0)), 1 / Animation_Speed)
		LeftHip2.C0 = Clerp(LeftHip2.C0, CF(-1 * SIZE, -0.7 * SIZE, -0.5 * SIZE) * ANGLES(RAD(25), RAD(-80), RAD(0)) * ANGLES(RAD(-1 * SIN(SINE / 6)), RAD(0), RAD(0)), 1 / Animation_Speed)
	end
	CreateSound(ROAR, Head2, 10, 1, false)
	for i = 0, 4, 0.1 / Animation_Speed do
		Swait()
		RootPart2.CFrame = Clerp(RootPart2.CFrame, TF(0, 6, 5), 0.1)
		RootJoint2.C0 = Clerp(RootJoint2.C0, ROOTC0 * CF(0, 0, 0) * ANGLES(RAD(35), RAD(0), RAD(0)), 1 / Animation_Speed)
		Neck2.C0 = Clerp(Neck2.C0, NECKC0 * CF(0, 0, 0 + (1 * SIZE - 1)) * ANGLES(RAD(-35), RAD(0), RAD(0)), 1 / Animation_Speed)
		RightShoulder2.C0 = Clerp(RightShoulder2.C0, CF(1.5 * SIZE, 0.5 * SIZE, 0) * ANGLES(RAD(-45), RAD(0), RAD(25)) * RIGHTSHOULDERC0, 1 / Animation_Speed)
		LeftShoulder2.C0 = Clerp(LeftShoulder2.C0, CF(-1.5 * SIZE, 0.5 * SIZE, 0) * ANGLES(RAD(-45), RAD(0), RAD(-25)) * LEFTSHOULDERC0, 1 / Animation_Speed)
		RightHip2.C0 = Clerp(RightHip2.C0, CF(1 * SIZE, -0.7 * SIZE, -0.5 * SIZE) * ANGLES(RAD(-25), RAD(80), RAD(0)) * ANGLES(RAD(-1 * SIN(SINE / 6)), RAD(0), RAD(0)), 1 / Animation_Speed)
		LeftHip2.C0 = Clerp(LeftHip2.C0, CF(-1 * SIZE, -0.7 * SIZE, -0.5 * SIZE) * ANGLES(RAD(-25), RAD(-80), RAD(0)) * ANGLES(RAD(-1 * SIN(SINE / 6)), RAD(0), RAD(0)), 1 / Animation_Speed)
	end
	ATTACK = false
	Rooted = false
end
local function Roar(TABLE)
	ATTACK = true
	Rooted = true
	local E = false
	coroutine.resume(coroutine.create(function()
		repeat
			Swait()
			RootPart2.CFrame = Clerp(RootPart2.CFrame, TF(0, 8, 0), 0.1)
			RootJoint.C0 = Clerp(RootJoint.C0, ROOTC0 * CF(0, 0, 0) * ANGLES(RAD(0), RAD(0), RAD(0)), 0.15 / Animation_Speed)
			Neck.C0 = Clerp(Neck.C0, NECKC0 * CF(0, 0, 0) * ANGLES(RAD(35), RAD(0), RAD(0)), 0.15 / Animation_Speed)
			RightShoulder.C0 = Clerp(RightShoulder.C0, CF(1.45, 0.65, 0) * ANGLES(RAD(170), RAD(0), RAD(-22)) * RIGHTSHOULDERC0, 1 / Animation_Speed)
			LeftShoulder.C0 = Clerp(LeftShoulder.C0, CF(-1.45, 0.65, 0) * ANGLES(RAD(170), RAD(0), RAD(22)) * LEFTSHOULDERC0, 1 / Animation_Speed)
			RightHip.C0 = Clerp(RightHip.C0, CF(1, -1, -0.01) * ANGLES(RAD(0), RAD(90), RAD(0)) * ANGLES(RAD(-8), RAD(0), RAD(0)), 0.15 / Animation_Speed)
			LeftHip.C0 = Clerp(LeftHip.C0, CF(-1, -1, -0.01) * ANGLES(RAD(0), RAD(-90), RAD(0)) * ANGLES(RAD(-8), RAD(0), RAD(0)), 0.15 / Animation_Speed)
		until E == true
	end))
	for i = 0, 1, 0.1 / Animation_Speed do
		Swait()
		RootJoint2.C0 = Clerp(RootJoint2.C0, ROOTC0 * CF(0, 0, 0) * ANGLES(RAD(-25), RAD(0), RAD(0)), 1 / Animation_Speed)
		Neck2.C0 = Clerp(Neck2.C0, NECKC0 * CF(0, 0, 0 + (1 * SIZE - 1)) * ANGLES(RAD(-25), RAD(0), RAD(0)), 1 / Animation_Speed)
		RightShoulder2.C0 = Clerp(RightShoulder2.C0, CF(1.15 * SIZE, 0.5 * SIZE, -0.5 * SIZE) * ANGLES(RAD(140), RAD(0), RAD(-45)) * RIGHTSHOULDERC0, 0.5 / Animation_Speed)
		LeftShoulder2.C0 = Clerp(LeftShoulder2.C0, CF(-1.15 * SIZE, 0.5 * SIZE, -0.5 * SIZE) * ANGLES(RAD(140), RAD(0), RAD(45)) * LEFTSHOULDERC0, 0.5 / Animation_Speed)
		RightHip2.C0 = Clerp(RightHip2.C0, CF(1 * SIZE, -0.7 * SIZE, -0.5 * SIZE) * ANGLES(RAD(25), RAD(80), RAD(0)) * ANGLES(RAD(-1 * SIN(SINE / 6)), RAD(0), RAD(0)), 1 / Animation_Speed)
		LeftHip2.C0 = Clerp(LeftHip2.C0, CF(-1 * SIZE, -0.7 * SIZE, -0.5 * SIZE) * ANGLES(RAD(25), RAD(-80), RAD(0)) * ANGLES(RAD(-1 * SIN(SINE / 6)), RAD(0), RAD(0)), 1 / Animation_Speed)
	end
	CreateSound(ROAR, Effects, 4, 1, false)
	if TABLE then
		for E = 1, #TABLE do
			if TABLE[E]:FindFirstChildOfClass("Humanoid") then
				local ROOT = GetRoot(TABLE[E], true)
				if ROOT then
					ApplyDamage(TABLE[E]:FindFirstChildOfClass("Humanoid"), MRANDOM(25, 50))
					local bv = Instance.new("BodyVelocity")
					bv.MaxForce = Vector3.new(1000000000, 1000000000, 1000000000)
					bv.Velocity = CF(RootPart.Position, ROOT.Position).LookVector * 150
					bv.Parent = ROOT
					Debris:AddItem(bv, 0.05)
				end
			end
		end
	end
	for i = 0, 6, 0.1 / Animation_Speed do
		Swait()
		local HITFLOOR, HITPOS = Raycast(RootPart2.Position, CF(RootPart.Position, RootPart.Position + VT(0, -1, 0)).LookVector, 25, Character)
		if HITFLOOR then
			CreateFlyingDebree(HITFLOOR, CF(HITPOS), 1, VT(1, 1, 1) * MRANDOM(7, 15) / 10, 5, 60)
		end
		WACKYEFFECT({
			EffectType = "Wave",
			Size = VT(20, 1, 20),
			Size2 = VT(25 + MRANDOM(0, 8), 7, 25 + MRANDOM(0, 8)),
			Transparency = 0.9,
			Transparency2 = 1,
			CFrame = CF(HITPOS) * ANGLES(RAD(0), RAD(MRANDOM(0, 360)), RAD(0)),
			MoveToPos = nil,
			RotationX = 0,
			RotationY = 5,
			RotationZ = 0,
			Material = "Neon",
			Color = C3(1, 1, 1),
			SoundID = nil,
			SoundPitch = nil,
			SoundVolume = nil
		})
		RootJoint2.C0 = Clerp(RootJoint2.C0, ROOTC0 * CF(0, 0, 0) * ANGLES(RAD(-35), RAD(0), RAD(0)), 1 / Animation_Speed)
		Neck2.C0 = Clerp(Neck2.C0, NECKC0 * CF(0, 0, 0 + (1 * SIZE - 1)) * ANGLES(RAD(-35), RAD(MRANDOM(-3, 3)), RAD(MRANDOM(-3, 3))), 1 / Animation_Speed)
		RightShoulder2.C0 = Clerp(RightShoulder2.C0, CF(1.5 * SIZE, 0.5 * SIZE, 0) * ANGLES(RAD(-45), RAD(0), RAD(25)) * RIGHTSHOULDERC0, 1 / Animation_Speed)
		LeftShoulder2.C0 = Clerp(LeftShoulder2.C0, CF(-1.5 * SIZE, 0.5 * SIZE, 0) * ANGLES(RAD(-45), RAD(0), RAD(-25)) * LEFTSHOULDERC0, 1 / Animation_Speed)
		RightHip2.C0 = Clerp(RightHip2.C0, CF(1 * SIZE, -0.7 * SIZE, -0.5 * SIZE) * ANGLES(RAD(-25), RAD(80), RAD(0)) * ANGLES(RAD(-1 * SIN(SINE / 6)), RAD(0), RAD(0)), 1 / Animation_Speed)
		LeftHip2.C0 = Clerp(LeftHip2.C0, CF(-1 * SIZE, -0.7 * SIZE, -0.5 * SIZE) * ANGLES(RAD(-25), RAD(-80), RAD(0)) * ANGLES(RAD(-1 * SIN(SINE / 6)), RAD(0), RAD(0)), 1 / Animation_Speed)
	end
	E = true
	if TABLE then
		CreateSound(1535995263, Head, 10, 1, false)
		for i = 0, 2.2, 0.1 / Animation_Speed do
			Swait()
			RootPart2.CFrame = Clerp(RootPart2.CFrame, TF(0, 6, 5), 0.1)
			RootJoint2.C0 = Clerp(RootJoint2.C0, ROOTC0 * CF(0, 0, 0.25 * COS(SINE / 12)) * ANGLES(RAD(-5 + 2 * SIN(SINE / 12)), RAD(15), RAD(35)), 0.5 / Animation_Speed)
			Neck2.C0 = Clerp(Neck2.C0, NECKC0 * CF(0, 0, 0 + (1 * SIZE - 1)) * ANGLES(RAD(25 - 2 * SIN(SINE / 12)), RAD(0), RAD(-35)), 0.5 / Animation_Speed)
			RightShoulder2.C0 = Clerp(RightShoulder2.C0, CF(1.5 * SIZE, 0.5 * SIZE, 0) * ANGLES(RAD(-35 + 15 * SIN(SINE / 12)), RAD(0), RAD(60)) * RIGHTSHOULDERC0, 0.5 / Animation_Speed)
			LeftShoulder2.C0 = Clerp(LeftShoulder2.C0, CF(-1.5 * SIZE, 0.5 * SIZE, 0) * ANGLES(RAD(-35 + 15 * SIN(SINE / 12)), RAD(0), RAD(-60)) * LEFTSHOULDERC0, 0.5 / Animation_Speed)
			RightHip2.C0 = Clerp(RightHip2.C0, CF(1 * SIZE, -1 * SIZE, 0) * ANGLES(RAD(0), RAD(80 - 1 * SIN(SINE / 6)), RAD(0)) * ANGLES(RAD(-3 * SIN(SINE / 12)), RAD(0), RAD(0)), 0.5 / Animation_Speed)
			LeftHip2.C0 = Clerp(LeftHip2.C0, CF(-1 * SIZE, -0.3 * SIZE, -0.6 * SIZE) * ANGLES(RAD(-25), RAD(-80 + 1 * SIN(SINE / 6)), RAD(0)) * ANGLES(RAD(-3 * SIN(SINE / 12)), RAD(0), RAD(0)), 0.5 / Animation_Speed)
			RootJoint.C0 = Clerp(RootJoint.C0, ROOTC0 * CF(0, 0, 0) * ANGLES(RAD(0), RAD(0), RAD(0)), 0.15 / Animation_Speed)
			Neck.C0 = Clerp(Neck.C0, NECKC0 * CF(0, 0, 0) * ANGLES(RAD(15), RAD(25), RAD(0)), 0.15 / Animation_Speed)
			RightShoulder.C0 = Clerp(RightShoulder.C0, CF(1.5, 0.5, 0) * ANGLES(RAD(170), RAD(0), RAD(5)) * RIGHTSHOULDERC0, 0.15 / Animation_Speed)
			LeftShoulder.C0 = Clerp(LeftShoulder.C0, CF(-1.5, 0.5, 0) * ANGLES(RAD(170), RAD(0), RAD(-5)) * LEFTSHOULDERC0, 0.15 / Animation_Speed)
			RightHip.C0 = Clerp(RightHip.C0, CF(1, -1, -0.01) * ANGLES(RAD(0), RAD(90), RAD(0)) * ANGLES(RAD(-8), RAD(0), RAD(0)), 0.15 / Animation_Speed)
			LeftHip.C0 = Clerp(LeftHip.C0, CF(-1, -1, -0.01) * ANGLES(RAD(0), RAD(-90), RAD(0)) * ANGLES(RAD(-8), RAD(0), RAD(0)), 0.15 / Animation_Speed)
		end
	end
	ATTACK = false
	Rooted = false
end
local function Punch()
	ATTACK = true
	Rooted = false
	local HITS = {}
	Speed = 12
	for i = 0, 1, 0.1 / Animation_Speed do
		Swait()
		RootPart2.CFrame = Clerp(RootPart2.CFrame, TF(0, 6, 5), 0.1)
		RootJoint2.C0 = Clerp(RootJoint2.C0, ROOTC0 * CF(0, 0, 0) * ANGLES(RAD(-5), RAD(0), RAD(-45)), 0.5 / Animation_Speed)
		Neck2.C0 = Clerp(Neck2.C0, NECKC0 * CF(0, 0, 0 + (1 * SIZE - 1)) * ANGLES(RAD(5), RAD(0), RAD(45)), 0.5 / Animation_Speed)
		RightShoulder2.C0 = Clerp(RightShoulder2.C0, CF(1.5 * SIZE, 0.5 * SIZE, -0.25 * SIZE) * ANGLES(RAD(90), RAD(0), RAD(-45)) * RIGHTSHOULDERC0, 0.5 / Animation_Speed)
		LeftShoulder2.C0 = Clerp(LeftShoulder2.C0, CF(-1.5 * SIZE, 0.5 * SIZE, 0) * ANGLES(RAD(0), RAD(0), RAD(-25)) * LEFTSHOULDERC0, 0.5 / Animation_Speed)
		RightHip2.C0 = Clerp(RightHip2.C0, CF(1 * SIZE, -1 * SIZE, 0) * ANGLES(RAD(0), RAD(50 - 1 * SIN(SINE / 6)), RAD(0)) * ANGLES(RAD(-1 * SIN(SINE / 6)), RAD(0), RAD(0)), 0.5 / Animation_Speed)
		LeftHip2.C0 = Clerp(LeftHip2.C0, CF(-1 * SIZE, -1 * SIZE, 0) * ANGLES(RAD(0), RAD(-80 + 1 * SIN(SINE / 6)), RAD(0)) * ANGLES(RAD(-1 * SIN(SINE / 6)), RAD(0), RAD(0)), 0.5 / Animation_Speed)
		RootJoint.C0 = Clerp(RootJoint.C0, ROOTC0 * CF(0, 0, 0) * ANGLES(RAD(0), RAD(0), RAD(-25)), 1 / Animation_Speed)
		Neck.C0 = Clerp(Neck.C0, NECKC0 * CF(0, 0, 0) * ANGLES(RAD(0 - 2.5 * SIN(SINE / 12)), RAD(0), RAD(25)), 1 / Animation_Speed)
		RightShoulder.C0 = Clerp(RightShoulder.C0, CF(1.5, 0.5, 0) * ANGLES(RAD(90), RAD(0), RAD(25)) * RIGHTSHOULDERC0, 1 / Animation_Speed)
		LeftShoulder.C0 = Clerp(LeftShoulder.C0, CF(-1.5, 0.5, 0) * ANGLES(RAD(0), RAD(0), RAD(-12)) * LEFTSHOULDERC0, 1 / Animation_Speed)
		RightHip.C0 = Clerp(RightHip.C0, CF(1, -1, -0.01) * ANGLES(RAD(0), RAD(60), RAD(0)) * ANGLES(RAD(-8), RAD(0), RAD(0)), 1 / Animation_Speed)
		LeftHip.C0 = Clerp(LeftHip.C0, CF(-1, -1, -0.01) * ANGLES(RAD(0), RAD(-90), RAD(0)) * ANGLES(RAD(-8), RAD(0), RAD(0)), 1 / Animation_Speed)
	end
	CreateSound(588693579, RightArm2, 6, MRANDOM(8, 12) / 10, false)
	for i = 0, 0.3, 0.1 / Animation_Speed do
		Swait()
		WACKYEFFECT({
			EffectType = "Box",
			Size = RightArm2.Size,
			Size2 = RightArm2.Size,
			Transparency = RightArm2.Transparency,
			Transparency2 = 1,
			CFrame = RightArm2.CFrame,
			MoveToPos = nil,
			RotationX = 0,
			RotationY = 0,
			RotationZ = 0,
			Material = "Neon",
			Color = C3(1, 1, 1),
			SoundID = nil,
			SoundPitch = nil,
			SoundVolume = nil
		})
		RootPart2.CFrame = Clerp(RootPart2.CFrame, TF(0, 3, -5), 0.4)
		RootJoint2.C0 = Clerp(RootJoint2.C0, ROOTC0 * CF(0, 0, 0) * ANGLES(RAD(45), RAD(0), RAD(45)), 0.5 / Animation_Speed)
		Neck2.C0 = Clerp(Neck2.C0, NECKC0 * CF(0, 0, 0 + (1 * SIZE - 1)) * ANGLES(RAD(5), RAD(0), RAD(-45)), 0.5 / Animation_Speed)
		RightShoulder2.C0 = Clerp(RightShoulder2.C0, CF(1.25 * SIZE, 0.5 * SIZE, -0.25 * SIZE) * ANGLES(RAD(135), RAD(0), RAD(45)) * RIGHTSHOULDERC0, 1 / Animation_Speed)
		LeftShoulder2.C0 = Clerp(LeftShoulder2.C0, CF(-1.5 * SIZE, 0.5 * SIZE, 0) * ANGLES(RAD(0), RAD(0), RAD(-25)) * LEFTSHOULDERC0, 0.5 / Animation_Speed)
		RightHip2.C0 = Clerp(RightHip2.C0, CF(1 * SIZE, -1 * SIZE, 0) * ANGLES(RAD(0), RAD(50 - 1 * SIN(SINE / 6)), RAD(0)) * ANGLES(RAD(-1 * SIN(SINE / 6)), RAD(0), RAD(0)), 0.5 / Animation_Speed)
		LeftHip2.C0 = Clerp(LeftHip2.C0, CF(-1 * SIZE, -1 * SIZE, 0) * ANGLES(RAD(0), RAD(-80 + 1 * SIN(SINE / 6)), RAD(0)) * ANGLES(RAD(-1 * SIN(SINE / 6)), RAD(0), RAD(0)), 0.5 / Animation_Speed)
		RootJoint.C0 = Clerp(RootJoint.C0, ROOTC0 * CF(0, 0, 0) * ANGLES(RAD(0), RAD(0), RAD(25)), 1 / Animation_Speed)
		Neck.C0 = Clerp(Neck.C0, NECKC0 * CF(0, 0, 0) * ANGLES(RAD(0 - 2.5 * SIN(SINE / 12)), RAD(0), RAD(-25)), 1 / Animation_Speed)
		RightShoulder.C0 = Clerp(RightShoulder.C0, CF(1.35, 0.5, 0) * ANGLES(RAD(90), RAD(0), RAD(-25)) * RIGHTSHOULDERC0, 1 / Animation_Speed)
		LeftShoulder.C0 = Clerp(LeftShoulder.C0, CF(-1.5, 0.5, 0) * ANGLES(RAD(0), RAD(0), RAD(-12)) * LEFTSHOULDERC0, 1 / Animation_Speed)
		RightHip.C0 = Clerp(RightHip.C0, CF(1, -1, -0.01) * ANGLES(RAD(0), RAD(90), RAD(0)) * ANGLES(RAD(-8), RAD(0), RAD(0)), 1 / Animation_Speed)
		LeftHip.C0 = Clerp(LeftHip.C0, CF(-1, -1, -0.01) * ANGLES(RAD(0), RAD(-60), RAD(0)) * ANGLES(RAD(-8), RAD(0), RAD(0)), 1 / Animation_Speed)
	end
	for index, CHILD in pairs(workspace:GetDescendants()) do
		if CHILD.ClassName == "Model" and not isMine(CHILD) then
			do
				local HUM = CHILD:FindFirstChildOfClass("Humanoid")
				if HUM then
					do
						local TORSO = CHILD:FindFirstChild("Torso") or CHILD:FindFirstChild("UpperTorso")
						if TORSO and (TORSO.Position - (RightArm2.CFrame * CF(0, -2 * TK, 0)).Position).Magnitude <= 15 * TK then
							table.insert(HITS, CHILD)
							coroutine.resume(coroutine.create(function()
								CreateSound(260430117, TORSO, 3, MRANDOM(8, 12) / 10, false)
								TORSO.Anchored = true
								local POS = TORSO.CFrame
								for i = 1, 35 do
									Swait()
									ApplyDamage(HUM, MRANDOM(1, 1))
									TORSO.CFrame = POS * CF(MRANDOM(-2, 2) / 10, MRANDOM(-2, 2) / 10, MRANDOM(-2, 2) / 10)
								end
								TORSO.Anchored = false
							end))
						end
					end
				end
			end
		end
	end
	for i = 0, 0.2, 0.1 / Animation_Speed do
		Swait()
		WACKYEFFECT({
			EffectType = "Box",
			Size = RightArm2.Size,
			Size2 = RightArm2.Size,
			Transparency = RightArm2.Transparency,
			Transparency2 = 1,
			CFrame = RightArm2.CFrame,
			MoveToPos = nil,
			RotationX = 0,
			RotationY = 0,
			RotationZ = 0,
			Material = "Neon",
			Color = C3(1, 1, 1),
			SoundID = nil,
			SoundPitch = nil,
			SoundVolume = nil
		})
		RootPart2.CFrame = Clerp(RootPart2.CFrame, TF(0, 3, -5), 0.5)
		RootJoint2.C0 = Clerp(RootJoint2.C0, ROOTC0 * CF(0, 0, 0) * ANGLES(RAD(45), RAD(0), RAD(45)), 0.5 / Animation_Speed)
		Neck2.C0 = Clerp(Neck2.C0, NECKC0 * CF(0, 0, 0 + (1 * SIZE - 1)) * ANGLES(RAD(5), RAD(0), RAD(-45)), 0.5 / Animation_Speed)
		RightShoulder2.C0 = Clerp(RightShoulder2.C0, CF(1.25 * SIZE, 0.5 * SIZE, -0.25 * SIZE) * ANGLES(RAD(135), RAD(0), RAD(-70)) * RIGHTSHOULDERC0, 1 / Animation_Speed)
		LeftShoulder2.C0 = Clerp(LeftShoulder2.C0, CF(-1.5 * SIZE, 0.5 * SIZE, 0) * ANGLES(RAD(0), RAD(0), RAD(-25)) * LEFTSHOULDERC0, 0.5 / Animation_Speed)
		RightHip2.C0 = Clerp(RightHip2.C0, CF(1 * SIZE, -1 * SIZE, 0) * ANGLES(RAD(0), RAD(50 - 1 * SIN(SINE / 6)), RAD(0)) * ANGLES(RAD(-1 * SIN(SINE / 6)), RAD(0), RAD(0)), 0.5 / Animation_Speed)
		LeftHip2.C0 = Clerp(LeftHip2.C0, CF(-1 * SIZE, -1 * SIZE, 0) * ANGLES(RAD(0), RAD(-80 + 1 * SIN(SINE / 6)), RAD(0)) * ANGLES(RAD(-1 * SIN(SINE / 6)), RAD(0), RAD(0)), 0.5 / Animation_Speed)
		RootJoint.C0 = Clerp(RootJoint.C0, ROOTC0 * CF(0, 0, 0) * ANGLES(RAD(0), RAD(0), RAD(25)), 1 / Animation_Speed)
		Neck.C0 = Clerp(Neck.C0, NECKC0 * CF(0, 0, 0) * ANGLES(RAD(0 - 2.5 * SIN(SINE / 12)), RAD(0), RAD(-25)), 1 / Animation_Speed)
		RightShoulder.C0 = Clerp(RightShoulder.C0, CF(1.35, 0.5, 0) * ANGLES(RAD(90), RAD(0), RAD(-25)) * RIGHTSHOULDERC0, 1 / Animation_Speed)
		LeftShoulder.C0 = Clerp(LeftShoulder.C0, CF(-1.5, 0.5, 0) * ANGLES(RAD(0), RAD(0), RAD(-12)) * LEFTSHOULDERC0, 1 / Animation_Speed)
		RightHip.C0 = Clerp(RightHip.C0, CF(1, -1, -0.01) * ANGLES(RAD(0), RAD(90), RAD(0)) * ANGLES(RAD(-8), RAD(0), RAD(0)), 1 / Animation_Speed)
		LeftHip.C0 = Clerp(LeftHip.C0, CF(-1, -1, -0.01) * ANGLES(RAD(0), RAD(-60), RAD(0)) * ANGLES(RAD(-8), RAD(0), RAD(0)), 1 / Animation_Speed)
	end
	if #HITS > 0 then
		for i = 0, 0.5, 0.1 / Animation_Speed do
			Swait()
			RootPart2.CFrame = Clerp(RootPart2.CFrame, TF(0, 3, -5), 0.5)
			RootJoint2.C0 = Clerp(RootJoint2.C0, ROOTC0 * CF(0, 0, 0) * ANGLES(RAD(45), RAD(0), RAD(45)), 0.5 / Animation_Speed)
			Neck2.C0 = Clerp(Neck2.C0, NECKC0 * CF(0, 0, 0 + (1 * SIZE - 1)) * ANGLES(RAD(5), RAD(0), RAD(-45)), 0.5 / Animation_Speed)
			RightShoulder2.C0 = Clerp(RightShoulder2.C0, CF(1.25 * SIZE, 0.5 * SIZE, -0.25 * SIZE) * ANGLES(RAD(135), RAD(0), RAD(-70)) * RIGHTSHOULDERC0, 1 / Animation_Speed)
			LeftShoulder2.C0 = Clerp(LeftShoulder2.C0, CF(-1.5 * SIZE, 0.5 * SIZE, 0) * ANGLES(RAD(0), RAD(0), RAD(-25)) * LEFTSHOULDERC0, 0.5 / Animation_Speed)
			RightHip2.C0 = Clerp(RightHip2.C0, CF(1 * SIZE, -1 * SIZE, 0) * ANGLES(RAD(0), RAD(50 - 1 * SIN(SINE / 6)), RAD(0)) * ANGLES(RAD(-1 * SIN(SINE / 6)), RAD(0), RAD(0)), 0.5 / Animation_Speed)
			LeftHip2.C0 = Clerp(LeftHip2.C0, CF(-1 * SIZE, -1 * SIZE, 0) * ANGLES(RAD(0), RAD(-80 + 1 * SIN(SINE / 6)), RAD(0)) * ANGLES(RAD(-1 * SIN(SINE / 6)), RAD(0), RAD(0)), 0.5 / Animation_Speed)
			RootJoint.C0 = Clerp(RootJoint.C0, ROOTC0 * CF(0, 0, 0) * ANGLES(RAD(0), RAD(0), RAD(25)), 1 / Animation_Speed)
			Neck.C0 = Clerp(Neck.C0, NECKC0 * CF(0, 0, 0) * ANGLES(RAD(0 - 2.5 * SIN(SINE / 12)), RAD(0), RAD(-25)), 1 / Animation_Speed)
			RightShoulder.C0 = Clerp(RightShoulder.C0, CF(1.35, 0.5, 0) * ANGLES(RAD(90), RAD(0), RAD(-25)) * RIGHTSHOULDERC0, 1 / Animation_Speed)
			LeftShoulder.C0 = Clerp(LeftShoulder.C0, CF(-1.5, 0.5, 0) * ANGLES(RAD(0), RAD(0), RAD(-12)) * LEFTSHOULDERC0, 1 / Animation_Speed)
			RightHip.C0 = Clerp(RightHip.C0, CF(1, -1, -0.01) * ANGLES(RAD(0), RAD(90), RAD(0)) * ANGLES(RAD(-8), RAD(0), RAD(0)), 1 / Animation_Speed)
			LeftHip.C0 = Clerp(LeftHip.C0, CF(-1, -1, -0.01) * ANGLES(RAD(0), RAD(-60), RAD(0)) * ANGLES(RAD(-8), RAD(0), RAD(0)), 1 / Animation_Speed)
		end
		Roar(HITS)
	end
	Speed = 16
	ATTACK = false
	Rooted = false
end
local function Throw()
	ATTACK = true
	Rooted = false
	local DEBREE = {}
	for i = 0, 1, 0.1 / Animation_Speed do
		Swait()
		RootPart2.CFrame = Clerp(RootPart2.CFrame, TF(0, 1, 2), 0.2)
		RootJoint2.C0 = Clerp(RootJoint2.C0, ROOTC0 * CF(0, 0, 0) * ANGLES(RAD(0), RAD(0), RAD(0)), 0.5 / Animation_Speed)
		Neck2.C0 = Clerp(Neck2.C0, NECKC0 * CF(0, 0, 0 + (1 * SIZE - 1)) * ANGLES(RAD(25), RAD(0), RAD(0)), 0.5 / Animation_Speed)
		RightShoulder2.C0 = Clerp(RightShoulder2.C0, CF(1.5 * SIZE, 0.5 * SIZE, 0) * ANGLES(RAD(90), RAD(0), RAD(-25)) * RIGHTSHOULDERC0, 0.5 / Animation_Speed)
		LeftShoulder2.C0 = Clerp(LeftShoulder2.C0, CF(-1.5 * SIZE, 0.5 * SIZE, 0) * ANGLES(RAD(90), RAD(0), RAD(25)) * LEFTSHOULDERC0, 0.5 / Animation_Speed)
		RightHip2.C0 = Clerp(RightHip2.C0, CF(1 * SIZE, -1 * SIZE, 0) * ANGLES(RAD(0), RAD(80 - 1 * SIN(SINE / 6)), RAD(0)) * ANGLES(RAD(-1 * SIN(SINE / 6)), RAD(0), RAD(0)), 0.5 / Animation_Speed)
		LeftHip2.C0 = Clerp(LeftHip2.C0, CF(-1 * SIZE, -1 * SIZE, 0) * ANGLES(RAD(0), RAD(-80 + 1 * SIN(SINE / 6)), RAD(0)) * ANGLES(RAD(-1 * SIN(SINE / 6)), RAD(0), RAD(0)), 0.5 / Animation_Speed)
		RootJoint.C0 = Clerp(RootJoint.C0, ROOTC0 * CF(0, 0, 0) * ANGLES(RAD(0), RAD(0), RAD(0)), 1 / Animation_Speed)
		Neck.C0 = Clerp(Neck.C0, NECKC0 * CF(0, 0, 0) * ANGLES(RAD(0 - 2.5 * SIN(SINE / 12)), RAD(0), RAD(0)), 1 / Animation_Speed)
		RightShoulder.C0 = Clerp(RightShoulder.C0, CF(1.5, 0.5, 0) * ANGLES(RAD(0), RAD(0), RAD(12)) * RIGHTSHOULDERC0, 1 / Animation_Speed)
		LeftShoulder.C0 = Clerp(LeftShoulder.C0, CF(-1.5, 0.5, 0) * ANGLES(RAD(0), RAD(0), RAD(-12)) * LEFTSHOULDERC0, 1 / Animation_Speed)
		RightHip.C0 = Clerp(RightHip.C0, CF(1, -1, -0.01) * ANGLES(RAD(0), RAD(90), RAD(0)) * ANGLES(RAD(0), RAD(0), RAD(0)), 1 / Animation_Speed)
		LeftHip.C0 = Clerp(LeftHip.C0, CF(-1, -1, -0.01) * ANGLES(RAD(0), RAD(-90), RAD(0)) * ANGLES(RAD(0), RAD(0), RAD(0)), 1 / Animation_Speed)
	end
	local CFRAME = RootPart2.CFrame * CF(0, 50, 0)
	Humanoid.PlatformStand = true
	UNANCHOR = false
	for i = 0, 1, 0.1 / Animation_Speed do
		Swait()
		RootPart2.CFrame = Clerp(RootPart2.CFrame, CF(CFRAME.Position, VT(Mouse.Hit.Position.X, RootPart2.Position.Y, Mouse.Hit.Position.Z)), 0.2)
		RootJoint2.C0 = Clerp(RootJoint2.C0, ROOTC0 * CF(0, 0, 0) * ANGLES(RAD(0), RAD(0), RAD(0)), 0.5 / Animation_Speed)
		Neck2.C0 = Clerp(Neck2.C0, NECKC0 * CF(0, 0, 0 + (1 * SIZE - 1)) * ANGLES(RAD(25), RAD(0), RAD(0)), 0.5 / Animation_Speed)
		RightShoulder2.C0 = Clerp(RightShoulder2.C0, CF(1.5 * SIZE, 0.5 * SIZE, 0) * ANGLES(RAD(90), RAD(0), RAD(-25)) * RIGHTSHOULDERC0, 0.5 / Animation_Speed)
		LeftShoulder2.C0 = Clerp(LeftShoulder2.C0, CF(-1.5 * SIZE, 0.5 * SIZE, 0) * ANGLES(RAD(90), RAD(0), RAD(25)) * LEFTSHOULDERC0, 0.5 / Animation_Speed)
		RightHip2.C0 = Clerp(RightHip2.C0, CF(1 * SIZE, -0.5 * SIZE, -0.5 * SIZE) * ANGLES(RAD(0), RAD(80 - 1 * SIN(SINE / 6)), RAD(0)) * ANGLES(RAD(-1 * SIN(SINE / 6)), RAD(0), RAD(0)), 0.5 / Animation_Speed)
		LeftHip2.C0 = Clerp(LeftHip2.C0, CF(-1 * SIZE, -1 * SIZE, 0) * ANGLES(RAD(0), RAD(-80 + 1 * SIN(SINE / 6)), RAD(0)) * ANGLES(RAD(-1 * SIN(SINE / 6)), RAD(0), RAD(0)), 0.5 / Animation_Speed)
		RootPart.CFrame = RootPart2.CFrame * CF(0, -1 * TK, -2 * TK)
		RootJoint.C0 = Clerp(RootJoint.C0, ROOTC0 * CF(0, 0, 0) * ANGLES(RAD(0), RAD(0), RAD(0)), 1 / Animation_Speed)
		Neck.C0 = Clerp(Neck.C0, NECKC0 * CF(0, 0, 0) * ANGLES(RAD(0 - 2.5 * SIN(SINE / 12)), RAD(0), RAD(0)), 1 / Animation_Speed)
		RightShoulder.C0 = Clerp(RightShoulder.C0, CF(1.5, 0.5, 0) * ANGLES(RAD(0), RAD(0), RAD(12)) * RIGHTSHOULDERC0, 1 / Animation_Speed)
		LeftShoulder.C0 = Clerp(LeftShoulder.C0, CF(-1.5, 0.5, 0) * ANGLES(RAD(0), RAD(0), RAD(-12)) * LEFTSHOULDERC0, 1 / Animation_Speed)
		RightHip.C0 = Clerp(RightHip.C0, CF(1, -1, -0.01) * ANGLES(RAD(0), RAD(90), RAD(0)) * ANGLES(RAD(0), RAD(0), RAD(0)), 1 / Animation_Speed)
		LeftHip.C0 = Clerp(LeftHip.C0, CF(-1, -1, -0.01) * ANGLES(RAD(0), RAD(-90), RAD(0)) * ANGLES(RAD(0), RAD(0), RAD(0)), 1 / Animation_Speed)
	end
	local HOLDING = true
	for i = 0, 0.4, 0.1 / Animation_Speed do
		Swait()
		RootPart2.CFrame = Clerp(RootPart2.CFrame, CF(CFRAME.Position, VT(Mouse.Hit.Position.X, RootPart2.Position.Y, Mouse.Hit.Position.Z)), 0.2)
		RootJoint2.C0 = Clerp(RootJoint2.C0, ROOTC0 * CF(0, 0, 0) * ANGLES(RAD(-25), RAD(0), RAD(0)), 0.5 / Animation_Speed)
		Neck2.C0 = Clerp(Neck2.C0, NECKC0 * CF(0, 0, 0 + (1 * SIZE - 1)) * ANGLES(RAD(25), RAD(0), RAD(0)), 0.5 / Animation_Speed)
		RightShoulder2.C0 = Clerp(RightShoulder2.C0, CF(1.5 * SIZE, 0.5 * SIZE, 0) * ANGLES(RAD(140), RAD(0), RAD(0)) * RIGHTSHOULDERC0, 0.5 / Animation_Speed)
		LeftShoulder2.C0 = Clerp(LeftShoulder2.C0, CF(-1.5 * SIZE, 0.5 * SIZE, 0) * ANGLES(RAD(0), RAD(0), RAD(0)) * LEFTSHOULDERC0, 0.5 / Animation_Speed)
		RightHip2.C0 = Clerp(RightHip2.C0, CF(1 * SIZE, -0.5 * SIZE, -0.5) * ANGLES(RAD(0), RAD(80 - 1 * SIN(SINE / 6)), RAD(0)) * ANGLES(RAD(-1 * SIN(SINE / 6)), RAD(0), RAD(0)), 0.5 / Animation_Speed)
		LeftHip2.C0 = Clerp(LeftHip2.C0, CF(-1 * SIZE, -1 * SIZE, 0) * ANGLES(RAD(0), RAD(-80 + 1 * SIN(SINE / 6)), RAD(0)) * ANGLES(RAD(-1 * SIN(SINE / 6)), RAD(0), RAD(0)), 0.5 / Animation_Speed)
		RootJoint.C0 = Clerp(RootJoint.C0, ROOTC0 * CF(0, 0, 0) * ANGLES(RAD(0), RAD(0), RAD(0)), 1 / Animation_Speed)
		Neck.C0 = Clerp(Neck.C0, NECKC0 * CF(0, 0, 0) * ANGLES(RAD(25), RAD(0), RAD(0)), 1 / Animation_Speed)
		RightShoulder.C0 = Clerp(RightShoulder.C0, CF(1.5, 0.5, -0.3) * ANGLES(RAD(90), RAD(0), RAD(-45)) * RIGHTSHOULDERC0, 1 / Animation_Speed)
		LeftShoulder.C0 = Clerp(LeftShoulder.C0, CF(-1.5, 0.35, -0.3) * ANGLES(RAD(80), RAD(0), RAD(45)) * LEFTSHOULDERC0, 1 / Animation_Speed)
		RightHip.C0 = Clerp(RightHip.C0, CF(1, -0.4, -0.5) * ANGLES(RAD(0), RAD(90), RAD(0)) * ANGLES(RAD(-1), RAD(0), RAD(0)), 1 / Animation_Speed)
		LeftHip.C0 = Clerp(LeftHip.C0, CF(-1, -0.4, -0.5) * ANGLES(RAD(0), RAD(-90), RAD(0)) * ANGLES(RAD(-1), RAD(0), RAD(0)), 1 / Animation_Speed)
		if HOLDING then
			RootPart.CFrame = (RightArm2.CFrame * CF(0, -2 * TK, 0) * ANGLES(RAD(-90), RAD(0), RAD(0))) * (RootJoint.C0 * RootJoint.C1:Inverse()):Inverse()
		end
	end
	local IMPACT = false
	HOLDING = false
	RootPart.CFrame = CF((RightArm2.CFrame * CF(0, -3 * TK, 0)).Position, Mouse.Hit.Position)
	CreateSound(588693579, RightArm2, 6, MRANDOM(8, 12) / 10, false)
	for i = 0, 0.4, 0.1 / Animation_Speed do
		Swait()
		WACKYEFFECT({
			EffectType = "Box",
			Size = RightArm2.Size,
			Size2 = RightArm2.Size,
			Transparency = RightArm2.Transparency,
			Transparency2 = 1,
			CFrame = RightArm2.CFrame,
			MoveToPos = nil,
			RotationX = 0,
			RotationY = 0,
			RotationZ = 0,
			Material = "Neon",
			Color = C3(1, 1, 1),
			SoundID = nil,
			SoundPitch = nil,
			SoundVolume = nil
		})
		RootPart2.CFrame = Clerp(RootPart2.CFrame, CF(CFRAME.Position, VT(Mouse.Hit.Position.X, RootPart2.Position.Y, Mouse.Hit.Position.Z)), 0.2)
		RootJoint2.C0 = Clerp(RootJoint2.C0, ROOTC0 * CF(0, 0, 0) * ANGLES(RAD(-25), RAD(0), RAD(0)), 0.5 / Animation_Speed)
		Neck2.C0 = Clerp(Neck2.C0, NECKC0 * CF(0, 0, 0 + (1 * SIZE - 1)) * ANGLES(RAD(25), RAD(0), RAD(0)), 0.5 / Animation_Speed)
		RightShoulder2.C0 = Clerp(RightShoulder2.C0, CF(1.5 * SIZE, 0.5 * SIZE, 0) * ANGLES(RAD(140), RAD(0), RAD(0)) * RIGHTSHOULDERC0, 0.5 / Animation_Speed)
		LeftShoulder2.C0 = Clerp(LeftShoulder2.C0, CF(-1.5 * SIZE, 0.5 * SIZE, 0) * ANGLES(RAD(0), RAD(0), RAD(0)) * LEFTSHOULDERC0, 0.5 / Animation_Speed)
		RightHip2.C0 = Clerp(RightHip2.C0, CF(1 * SIZE, -0.5 * SIZE, -0.5) * ANGLES(RAD(0), RAD(80 - 1 * SIN(SINE / 6)), RAD(0)) * ANGLES(RAD(-1 * SIN(SINE / 6)), RAD(0), RAD(0)), 0.5 / Animation_Speed)
		LeftHip2.C0 = Clerp(LeftHip2.C0, CF(-1 * SIZE, -1 * SIZE, 0) * ANGLES(RAD(0), RAD(-80 + 1 * SIN(SINE / 6)), RAD(0)) * ANGLES(RAD(-1 * SIN(SINE / 6)), RAD(0), RAD(0)), 0.5 / Animation_Speed)
		RootJoint.C0 = Clerp(RootJoint.C0, ROOTC0 * CF(0, 0, 0) * ANGLES(RAD(0), RAD(0), RAD(0)), 1 / Animation_Speed)
		Neck.C0 = Clerp(Neck.C0, NECKC0 * CF(0, 0, 0) * ANGLES(RAD(25), RAD(0), RAD(0)), 1 / Animation_Speed)
		RightShoulder.C0 = Clerp(RightShoulder.C0, CF(1.5, 0.5, -0.3) * ANGLES(RAD(90), RAD(0), RAD(-45)) * RIGHTSHOULDERC0, 1 / Animation_Speed)
		LeftShoulder.C0 = Clerp(LeftShoulder.C0, CF(-1.5, 0.35, -0.3) * ANGLES(RAD(80), RAD(0), RAD(45)) * LEFTSHOULDERC0, 1 / Animation_Speed)
		RightHip.C0 = Clerp(RightHip.C0, CF(1, -0.4, -0.5) * ANGLES(RAD(0), RAD(90), RAD(0)) * ANGLES(RAD(-1), RAD(0), RAD(0)), 1 / Animation_Speed)
		LeftHip.C0 = Clerp(LeftHip.C0, CF(-1, -0.4, -0.5) * ANGLES(RAD(0), RAD(-90), RAD(0)) * ANGLES(RAD(-1), RAD(0), RAD(0)), 1 / Animation_Speed)
	end
	coroutine.resume(coroutine.create(function()
		repeat
			Swait()
			RootJoint2.C0 = Clerp(RootJoint2.C0, ROOTC0 * CF(0, 0, 0) * ANGLES(RAD(-25), RAD(0), RAD(0)), 0.5 / Animation_Speed)
			Neck2.C0 = Clerp(Neck2.C0, NECKC0 * CF(0, 0, 0 + (1 * SIZE - 1)) * ANGLES(RAD(25), RAD(0), RAD(0)), 0.5 / Animation_Speed)
			RightShoulder2.C0 = Clerp(RightShoulder2.C0, CF(1.5 * SIZE, 0.5 * SIZE, 0) * ANGLES(RAD(140), RAD(0), RAD(0)) * RIGHTSHOULDERC0, 0.5 / Animation_Speed)
			LeftShoulder2.C0 = Clerp(LeftShoulder2.C0, CF(-1.5 * SIZE, 0.5 * SIZE, 0) * ANGLES(RAD(0), RAD(0), RAD(0)) * LEFTSHOULDERC0, 0.5 / Animation_Speed)
			RightHip2.C0 = Clerp(RightHip2.C0, CF(1 * SIZE, -0.5 * SIZE, -0.5) * ANGLES(RAD(0), RAD(80 - 1 * SIN(SINE / 6)), RAD(0)) * ANGLES(RAD(-1 * SIN(SINE / 6)), RAD(0), RAD(0)), 0.5 / Animation_Speed)
			LeftHip2.C0 = Clerp(LeftHip2.C0, CF(-1 * SIZE, -1 * SIZE, 0) * ANGLES(RAD(0), RAD(-80 + 1 * SIN(SINE / 6)), RAD(0)) * ANGLES(RAD(-1 * SIN(SINE / 6)), RAD(0), RAD(0)), 0.5 / Animation_Speed)
			RootJoint.C0 = Clerp(RootJoint.C0, ROOTC0 * CF(0, 0, 0) * ANGLES(RAD(-90), RAD(0), RAD(0)), 1 / Animation_Speed)
			Neck.C0 = Clerp(Neck.C0, NECKC0 * CF(0, 0, 0) * ANGLES(RAD(25), RAD(0), RAD(0)), 1 / Animation_Speed)
			RightShoulder.C0 = Clerp(RightShoulder.C0, CF(1.5, 0.5, -0.3) * ANGLES(RAD(90), RAD(0), RAD(-45)) * RIGHTSHOULDERC0, 1 / Animation_Speed)
			LeftShoulder.C0 = Clerp(LeftShoulder.C0, CF(-1.5, 0.35, -0.3) * ANGLES(RAD(80), RAD(0), RAD(45)) * LEFTSHOULDERC0, 1 / Animation_Speed)
			RightHip.C0 = Clerp(RightHip.C0, CF(1, -0.4, -0.5) * ANGLES(RAD(0), RAD(90), RAD(0)) * ANGLES(RAD(-1), RAD(0), RAD(0)), 1 / Animation_Speed)
			LeftHip.C0 = Clerp(LeftHip.C0, CF(-1, -0.4, -0.5) * ANGLES(RAD(0), RAD(-90), RAD(0)) * ANGLES(RAD(-1), RAD(0), RAD(0)), 1 / Animation_Speed)
		until IMPACT == true or ATTACK == false
	end))
	local FLOOR
	for i = 1, 80 do
		Swait()
		local HIT, POS = Raycast(RootPart.Position, RootPart.CFrame.LookVector, 6, Character)
		if HIT then
			FLOOR = HIT
			IMPACT = true
			local ORI = VT(0, RootPart.Orientation.Y, 0)
			RootPart.CFrame = CF(POS + VT(0, 3.5, 0))
			RootPart.Orientation = ORI
			RootJoint.Parent = RootPart
			break
		else
			RootPart.CFrame = RootPart.CFrame * CF(0, 0, -6)
		end
	end
	UNANCHOR = true
	if FLOOR then
		do
			local PLAYING = false
			Humanoid.PlatformStand = false
			local REPLAY = true
			local FLING = false
			coroutine.resume(coroutine.create(function()
				local ROCKS = MRANDOM(8, 13)
				for i = 1, ROCKS do
					local DEBREEPART = CreatePart(3, Effects, FLOOR.Material, 0, 0, FLOOR.BrickColor, "Debree", VT(1, 1, 1) * MRANDOM(2, 7), true)
					DEBREEPART.CFrame = CF(RootPart.Position - VT(0, 7, 0)) * ANGLES(RAD(0), RAD(360 / ROCKS * i), RAD(0)) * CF(0, 0, MRANDOM(20, 28)) * ANGLES(RAD(MRANDOM(0, 360)), RAD(MRANDOM(0, 360)), RAD(MRANDOM(0, 360)))
					table.insert(DEBREE, {
						DEBREEPART,
						DEBREEPART.Orientation,
						CF(DEBREEPART.Position + VT(0, MRANDOM(3, 7) + 8, 0))
					})
				end
				repeat
					Swait()
					for E = 1, #DEBREE do
						local ROCK = DEBREE[E][1]
						ROCK.CFrame = Clerp(ROCK.CFrame, DEBREE[E][3], 0.3)
						ROCK.Orientation = DEBREE[E][2]
					end
				until FLING == true or ATTACK == false
				if FLING == false then
					for E = 1, #DEBREE do
						local ROCK = DEBREE[E][1]
						ROCK.Anchored = false
						Debris:AddItem(ROCK, 4)
					end
				else
					for E = 1, #DEBREE do
						do
							local ROCK = DEBREE[E][1]
							ROCK.CFrame = CF(ROCK.Position, Mouse.Hit.Position)
							coroutine.resume(coroutine.create(function()
								for i = 1, 150 do
									Swait()
									local HIT, POS, NORMAL = Raycast(ROCK.Position, ROCK.CFrame.LookVector, 3, Character)
									if HIT then
										break
									else
										ROCK.CFrame = ROCK.CFrame * CF(0, 0, -3)
									end
								end
								ApplyAoE(ROCK.Position, 22, 10, 15, 70, false)
								WACKYEFFECT({
									EffectType = "Box",
									Size = ROCK.Size,
									Size2 = ROCK.Size * 1.2,
									Transparency = 0,
									Transparency2 = 1,
									CFrame = ROCK.CFrame,
									MoveToPos = nil,
									RotationX = 0,
									RotationY = 0,
									RotationZ = 0,
									Material = "Neon",
									Color = C3(1, 1, 1),
									SoundID = nil,
									SoundPitch = nil,
									SoundVolume = nil
								})
								WACKYEFFECT({
									Time = 15,
									EffectType = "Sphere",
									Size = ROCK.Size,
									Size2 = VT(35, 35, 35),
									Transparency = 0.8,
									Transparency2 = 1,
									CFrame = CF(ROCK.Position),
									MoveToPos = nil,
									RotationX = 0,
									RotationY = 0,
									RotationZ = 0,
									Material = "Neon",
									Color = C3(1, 1, 1),
									SoundID = 174580476,
									SoundPitch = 1,
									SoundVolume = 3
								})
								ROCK:Destroy()
							end))
							Swait(5)
						end
					end
				end
			end))
			local UNDO = FacialShadow()
			CreateSound(765590102, Torso, 2, MRANDOM(8, 12) / 10, false)
			KEY = Mouse.KeyDown:connect(function(NEWKEY)
				if NEWKEY == "e" then
					KEY:Disconnect()
					PLAYING = true
				end
			end)
			for i = 0, 2, 0.1 / Animation_Speed do
				Swait()
				if PLAYING == true then
					break
				end
				RootPart2.CFrame = Clerp(RootPart2.CFrame, TF(0, 6, 5), 0.1)
				RootJoint2.C0 = Clerp(RootJoint2.C0, ROOTC0 * CF(0, 0, 0.25 * COS(SINE / 12)) * ANGLES(RAD(-5 + 2 * SIN(SINE / 12)), RAD(15), RAD(35)), 0.5 / Animation_Speed)
				Neck2.C0 = Clerp(Neck2.C0, NECKC0 * CF(0, 0, 0 + (1 * SIZE - 1)) * ANGLES(RAD(25 - 2 * SIN(SINE / 12)), RAD(0), RAD(-35)), 0.5 / Animation_Speed)
				RightShoulder2.C0 = Clerp(RightShoulder2.C0, CF(1.5 * SIZE, 0.5 * SIZE, 0) * ANGLES(RAD(-35 + 15 * SIN(SINE / 12)), RAD(0), RAD(60)) * RIGHTSHOULDERC0, 0.5 / Animation_Speed)
				LeftShoulder2.C0 = Clerp(LeftShoulder2.C0, CF(-1.5 * SIZE, 0.5 * SIZE, 0) * ANGLES(RAD(-35 + 15 * SIN(SINE / 12)), RAD(0), RAD(-60)) * LEFTSHOULDERC0, 0.5 / Animation_Speed)
				RightHip2.C0 = Clerp(RightHip2.C0, CF(1 * SIZE, -1 * SIZE, 0) * ANGLES(RAD(0), RAD(80 - 1 * SIN(SINE / 6)), RAD(0)) * ANGLES(RAD(-3 * SIN(SINE / 12)), RAD(0), RAD(0)), 0.5 / Animation_Speed)
				LeftHip2.C0 = Clerp(LeftHip2.C0, CF(-1 * SIZE, -0.3 * SIZE, -0.6 * SIZE) * ANGLES(RAD(-25), RAD(-80 + 1 * SIN(SINE / 6)), RAD(0)) * ANGLES(RAD(-3 * SIN(SINE / 12)), RAD(0), RAD(0)), 0.5 / Animation_Speed)
				RootJoint.C0 = Clerp(RootJoint.C0, ROOTC0 * CF(0, 0.5, -0.5) * ANGLES(RAD(0), RAD(0), RAD(0)), 1 / Animation_Speed)
				Neck.C0 = Clerp(Neck.C0, NECKC0 * CF(0, 0, 0) * ANGLES(RAD(35), RAD(0), RAD(0)), 1 / Animation_Speed)
				RightShoulder.C0 = Clerp(RightShoulder.C0, CF(1.5, 0.5, 0) * ANGLES(RAD(0), RAD(0), RAD(12)) * RIGHTSHOULDERC0, 1 / Animation_Speed)
				LeftShoulder.C0 = Clerp(LeftShoulder.C0, CF(-1.5, 0.5, 0) * ANGLES(RAD(0), RAD(0), RAD(-12)) * LEFTSHOULDERC0, 1 / Animation_Speed)
				RightHip.C0 = Clerp(RightHip.C0, CF(1, -0.5, -0.5) * ANGLES(RAD(0), RAD(90), RAD(0)) * ANGLES(RAD(-8), RAD(0), RAD(0)), 1 / Animation_Speed)
				LeftHip.C0 = Clerp(LeftHip.C0, CF(-1, -0.5, -0.5) * ANGLES(RAD(0), RAD(-90), RAD(0)) * ANGLES(RAD(-8), RAD(0), RAD(0)), 1 / Animation_Speed)
			end
			if KEY then
				KEY:Disconnect()
			end
			if PLAYING == true then
				for i = 0, 0.3, 0.1 / Animation_Speed do
					Swait()
					RootPart2.CFrame = Clerp(RootPart2.CFrame, TF(0, 6, 5), 0.1)
					RootJoint2.C0 = Clerp(RootJoint2.C0, ROOTC0 * CF(0, 0, 0) * ANGLES(RAD(0), RAD(0), RAD(-25)), 0.5 / Animation_Speed)
					Neck2.C0 = Clerp(Neck2.C0, NECKC0 * CF(0, 0, 0 + (1 * SIZE - 1)) * ANGLES(RAD(0), RAD(0), RAD(25)), 0.5 / Animation_Speed)
					RightShoulder2.C0 = Clerp(RightShoulder2.C0, CF(1.25 * SIZE, 0.5 * SIZE, -0.5 * SIZE) * ANGLES(RAD(0), RAD(0), RAD(-90)) * RIGHTSHOULDERC0, 0.5 / Animation_Speed)
					LeftShoulder2.C0 = Clerp(LeftShoulder2.C0, CF(-1.5 * SIZE, 0.5 * SIZE, 0) * ANGLES(RAD(0), RAD(0), RAD(0)) * LEFTSHOULDERC0, 0.5 / Animation_Speed)
					RightHip2.C0 = Clerp(RightHip2.C0, CF(1 * SIZE, -1 * SIZE, 0) * ANGLES(RAD(0), RAD(80 - 1 * SIN(SINE / 6)), RAD(0)) * ANGLES(RAD(-1 * SIN(SINE / 6)), RAD(0), RAD(0)), 0.5 / Animation_Speed)
					LeftHip2.C0 = Clerp(LeftHip2.C0, CF(-1 * SIZE, -1 * SIZE, 0) * ANGLES(RAD(0), RAD(-80 + 1 * SIN(SINE / 6)), RAD(0)) * ANGLES(RAD(-1 * SIN(SINE / 6)), RAD(0), RAD(0)), 0.5 / Animation_Speed)
					RootJoint.C0 = Clerp(RootJoint.C0, ROOTC0 * CF(0, 0, 0) * ANGLES(RAD(0), RAD(0), RAD(0)), 1 / Animation_Speed)
					Neck.C0 = Clerp(Neck.C0, NECKC0 * CF(0, 0, 0) * ANGLES(RAD(0 - 2.5 * SIN(SINE / 12)), RAD(0), RAD(0)), 1 / Animation_Speed)
					RightShoulder.C0 = Clerp(RightShoulder.C0, CF(1.5, 0.5, 0) * ANGLES(RAD(0), RAD(0), RAD(3)) * RIGHTSHOULDERC0, 1 / Animation_Speed)
					LeftShoulder.C0 = Clerp(LeftShoulder.C0, CF(-1.5, 0.5, 0) * ANGLES(RAD(0), RAD(0), RAD(-3)) * LEFTSHOULDERC0, 1 / Animation_Speed)
					RightHip.C0 = Clerp(RightHip.C0, CF(1, -1, -0.01) * ANGLES(RAD(0), RAD(90), RAD(0)) * ANGLES(RAD(-2), RAD(0), RAD(0)), 1 / Animation_Speed)
					LeftHip.C0 = Clerp(LeftHip.C0, CF(-1, -1, -0.01) * ANGLES(RAD(0), RAD(-90), RAD(0)) * ANGLES(RAD(-2), RAD(0), RAD(0)), 1 / Animation_Speed)
				end
				FLING = true
				for i = 0, 1, 0.1 / Animation_Speed do
					Swait()
					RootPart2.CFrame = Clerp(RootPart2.CFrame, TF(0, 6, 5), 0.1)
					RootJoint2.C0 = Clerp(RootJoint2.C0, ROOTC0 * CF(0, 0, 0) * ANGLES(RAD(0), RAD(0), RAD(45)), 2 / Animation_Speed)
					Neck2.C0 = Clerp(Neck2.C0, NECKC0 * CF(0, 0, 0 + (1 * SIZE - 1)) * ANGLES(RAD(0), RAD(0), RAD(-35)), 2 / Animation_Speed)
					RightShoulder2.C0 = Clerp(RightShoulder2.C0, CF(1.5 * SIZE, 0.5 * SIZE, 0) * ANGLES(RAD(0), RAD(0), RAD(90)) * RIGHTSHOULDERC0, 2 / Animation_Speed)
					LeftShoulder2.C0 = Clerp(LeftShoulder2.C0, CF(-1.5 * SIZE, 0.5 * SIZE, 0) * ANGLES(RAD(0), RAD(0), RAD(0)) * LEFTSHOULDERC0, 0.5 / Animation_Speed)
					RightHip2.C0 = Clerp(RightHip2.C0, CF(1 * SIZE, -1 * SIZE, 0) * ANGLES(RAD(0), RAD(80 - 1 * SIN(SINE / 6)), RAD(0)) * ANGLES(RAD(-1 * SIN(SINE / 6)), RAD(0), RAD(0)), 0.5 / Animation_Speed)
					LeftHip2.C0 = Clerp(LeftHip2.C0, CF(-1 * SIZE, -1 * SIZE, 0) * ANGLES(RAD(0), RAD(-80 + 1 * SIN(SINE / 6)), RAD(0)) * ANGLES(RAD(-1 * SIN(SINE / 6)), RAD(0), RAD(0)), 0.5 / Animation_Speed)
					RootJoint.C0 = Clerp(RootJoint.C0, ROOTC0 * CF(0, 0, 0) * ANGLES(RAD(0), RAD(0), RAD(0)), 1 / Animation_Speed)
					Neck.C0 = Clerp(Neck.C0, NECKC0 * CF(0, 0, 0) * ANGLES(RAD(0 - 2.5 * SIN(SINE / 12)), RAD(0), RAD(0)), 1 / Animation_Speed)
					RightShoulder.C0 = Clerp(RightShoulder.C0, CF(1.5, 0.5, 0) * ANGLES(RAD(0), RAD(0), RAD(3)) * RIGHTSHOULDERC0, 1 / Animation_Speed)
					LeftShoulder.C0 = Clerp(LeftShoulder.C0, CF(-1.5, 0.5, 0) * ANGLES(RAD(0), RAD(0), RAD(-3)) * LEFTSHOULDERC0, 1 / Animation_Speed)
					RightHip.C0 = Clerp(RightHip.C0, CF(1, -1, -0.01) * ANGLES(RAD(0), RAD(90), RAD(0)) * ANGLES(RAD(-2), RAD(0), RAD(0)), 1 / Animation_Speed)
					LeftHip.C0 = Clerp(LeftHip.C0, CF(-1, -1, -0.01) * ANGLES(RAD(0), RAD(-90), RAD(0)) * ANGLES(RAD(-2), RAD(0), RAD(0)), 1 / Animation_Speed)
				end
			end
			UNDO()
		end
	end
	REPLAY = false
	ATTACK = false
	Rooted = false
end
local function Uppercut()
	ATTACK = true
	Rooted = false
	local HITS = {}
	Speed = 12
	for i = 0, 1, 0.1 / Animation_Speed do
		Swait()
		RootPart2.CFrame = Clerp(RootPart2.CFrame, TF(0, 6, 5), 0.1)
		RootJoint2.C0 = Clerp(RootJoint2.C0, ROOTC0 * CF(0, 0, 0) * ANGLES(RAD(-5), RAD(0), RAD(-45)), 0.5 / Animation_Speed)
		Neck2.C0 = Clerp(Neck2.C0, NECKC0 * CF(0, 0, 0 + (1 * SIZE - 1)) * ANGLES(RAD(5), RAD(0), RAD(45)), 0.5 / Animation_Speed)
		RightShoulder2.C0 = Clerp(RightShoulder2.C0, CF(1.5 * SIZE, 0.5 * SIZE, -0.25 * SIZE) * ANGLES(RAD(90), RAD(0), RAD(-45)) * RIGHTSHOULDERC0, 0.5 / Animation_Speed)
		LeftShoulder2.C0 = Clerp(LeftShoulder2.C0, CF(-1.5 * SIZE, 0.5 * SIZE, 0) * ANGLES(RAD(0), RAD(0), RAD(-25)) * LEFTSHOULDERC0, 0.5 / Animation_Speed)
		RightHip2.C0 = Clerp(RightHip2.C0, CF(1 * SIZE, -1 * SIZE, 0) * ANGLES(RAD(0), RAD(50 - 1 * SIN(SINE / 6)), RAD(0)) * ANGLES(RAD(-1 * SIN(SINE / 6)), RAD(0), RAD(0)), 0.5 / Animation_Speed)
		LeftHip2.C0 = Clerp(LeftHip2.C0, CF(-1 * SIZE, -1 * SIZE, 0) * ANGLES(RAD(0), RAD(-80 + 1 * SIN(SINE / 6)), RAD(0)) * ANGLES(RAD(-1 * SIN(SINE / 6)), RAD(0), RAD(0)), 0.5 / Animation_Speed)
		RootJoint.C0 = Clerp(RootJoint.C0, ROOTC0 * CF(0, 0, 0) * ANGLES(RAD(0), RAD(0), RAD(-25)), 1 / Animation_Speed)
		Neck.C0 = Clerp(Neck.C0, NECKC0 * CF(0, 0, 0) * ANGLES(RAD(0 - 2.5 * SIN(SINE / 12)), RAD(0), RAD(25)), 1 / Animation_Speed)
		RightShoulder.C0 = Clerp(RightShoulder.C0, CF(1.5, 0.5, 0) * ANGLES(RAD(90), RAD(0), RAD(25)) * RIGHTSHOULDERC0, 1 / Animation_Speed)
		LeftShoulder.C0 = Clerp(LeftShoulder.C0, CF(-1.5, 0.5, 0) * ANGLES(RAD(0), RAD(0), RAD(-12)) * LEFTSHOULDERC0, 1 / Animation_Speed)
		RightHip.C0 = Clerp(RightHip.C0, CF(1, -1, -0.01) * ANGLES(RAD(0), RAD(60), RAD(0)) * ANGLES(RAD(-8), RAD(0), RAD(0)), 1 / Animation_Speed)
		LeftHip.C0 = Clerp(LeftHip.C0, CF(-1, -1, -0.01) * ANGLES(RAD(0), RAD(-90), RAD(0)) * ANGLES(RAD(-8), RAD(0), RAD(0)), 1 / Animation_Speed)
	end
	CreateSound(588693579, RightArm2, 6, MRANDOM(8, 12) / 10, false)
	for i = 0, 0.3, 0.1 / Animation_Speed do
		Swait()
		WACKYEFFECT({
			EffectType = "Box",
			Size = RightArm2.Size,
			Size2 = RightArm2.Size,
			Transparency = RightArm2.Transparency,
			Transparency2 = 1,
			CFrame = RightArm2.CFrame,
			MoveToPos = nil,
			RotationX = 0,
			RotationY = 0,
			RotationZ = 0,
			Material = "Neon",
			Color = C3(1, 1, 1),
			SoundID = nil,
			SoundPitch = nil,
			SoundVolume = nil
		})
		RootPart2.CFrame = Clerp(RootPart2.CFrame, TF(0, 3, -5), 0.4)
		RootJoint2.C0 = Clerp(RootJoint2.C0, ROOTC0 * CF(0, 0, 0) * ANGLES(RAD(45), RAD(0), RAD(45)), 0.5 / Animation_Speed)
		Neck2.C0 = Clerp(Neck2.C0, NECKC0 * CF(0, 0, 0 + (1 * SIZE - 1)) * ANGLES(RAD(5), RAD(0), RAD(-45)), 0.5 / Animation_Speed)
		RightShoulder2.C0 = Clerp(RightShoulder2.C0, CF(1.25 * SIZE, 0.5 * SIZE, -0.25 * SIZE) * ANGLES(RAD(80), RAD(0), RAD(45)) * RIGHTSHOULDERC0, 1 / Animation_Speed)
		LeftShoulder2.C0 = Clerp(LeftShoulder2.C0, CF(-1.5 * SIZE, 0.5 * SIZE, 0) * ANGLES(RAD(0), RAD(0), RAD(-25)) * LEFTSHOULDERC0, 0.5 / Animation_Speed)
		RightHip2.C0 = Clerp(RightHip2.C0, CF(1 * SIZE, -1 * SIZE, 0) * ANGLES(RAD(0), RAD(50 - 1 * SIN(SINE / 6)), RAD(0)) * ANGLES(RAD(-1 * SIN(SINE / 6)), RAD(0), RAD(0)), 0.5 / Animation_Speed)
		LeftHip2.C0 = Clerp(LeftHip2.C0, CF(-1 * SIZE, -1 * SIZE, 0) * ANGLES(RAD(0), RAD(-80 + 1 * SIN(SINE / 6)), RAD(0)) * ANGLES(RAD(-1 * SIN(SINE / 6)), RAD(0), RAD(0)), 0.5 / Animation_Speed)
		RootJoint.C0 = Clerp(RootJoint.C0, ROOTC0 * CF(0, 0, 0) * ANGLES(RAD(0), RAD(0), RAD(25)), 1 / Animation_Speed)
		Neck.C0 = Clerp(Neck.C0, NECKC0 * CF(0, 0, 0) * ANGLES(RAD(0 - 2.5 * SIN(SINE / 12)), RAD(0), RAD(-25)), 1 / Animation_Speed)
		RightShoulder.C0 = Clerp(RightShoulder.C0, CF(1.35, 0.5, 0) * ANGLES(RAD(140), RAD(0), RAD(-25)) * RIGHTSHOULDERC0, 1 / Animation_Speed)
		LeftShoulder.C0 = Clerp(LeftShoulder.C0, CF(-1.5, 0.5, 0) * ANGLES(RAD(0), RAD(0), RAD(-12)) * LEFTSHOULDERC0, 1 / Animation_Speed)
		RightHip.C0 = Clerp(RightHip.C0, CF(1, -1, -0.01) * ANGLES(RAD(0), RAD(90), RAD(0)) * ANGLES(RAD(-8), RAD(0), RAD(0)), 1 / Animation_Speed)
		LeftHip.C0 = Clerp(LeftHip.C0, CF(-1, -1, -0.01) * ANGLES(RAD(0), RAD(-60), RAD(0)) * ANGLES(RAD(-8), RAD(0), RAD(0)), 1 / Animation_Speed)
	end
	for index, CHILD in pairs(workspace:GetDescendants()) do
		if CHILD.ClassName == "Model" and not isMine(CHILD) then
			do
				local HUM = CHILD:FindFirstChildOfClass("Humanoid")
				if HUM then
					do
						local TORSO = CHILD:FindFirstChild("Torso") or CHILD:FindFirstChild("UpperTorso")
						if TORSO and (TORSO.Position - (RightArm2.CFrame * CF(0, -2 * TK, 0)).Position).Magnitude <= 15 * TK then
							coroutine.resume(coroutine.create(function()
								CreateSound(260430117, TORSO, 3, MRANDOM(8, 12) / 10, false)
								local grav = Instance.new("BodyPosition", TORSO)
								grav.D = 1500
								grav.P = 20000
								grav.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
								grav.Position = TORSO.Position + VT(0, 25, 0)
								TORSO.AssemblyAngularVelocity = VT(MRANDOM(-25, 25), MRANDOM(-25, 25), MRANDOM(-25, 25))
								table.insert(HITS, {CHILD, grav})
								ApplyDamage(HUM, MRANDOM(12, 22))
							end))
						end
					end
				end
			end
		end
	end
	if #HITS > 0 then
		coroutine.resume(coroutine.create(function()
			repeat
				Swait()
			until ATTACK == false
			for E = 1, #HITS do
				HITS[E][2]:Destroy()
			end
		end))
	end
	REPLAY = true
	local PLAYING = false
	local WHACK = false
	local HITTING = 0
	local PAYDOWN = 200
	local UNDO = FacialShadow()
	for i = 0, 0.5, 0.1 / Animation_Speed do
		Swait()
		if PLAYING == true then
			break
		end
		WACKYEFFECT({
			EffectType = "Box",
			Size = RightArm2.Size,
			Size2 = RightArm2.Size,
			Transparency = RightArm2.Transparency,
			Transparency2 = 1,
			CFrame = RightArm2.CFrame,
			MoveToPos = nil,
			RotationX = 0,
			RotationY = 0,
			RotationZ = 0,
			Material = "Neon",
			Color = C3(1, 1, 1),
			SoundID = nil,
			SoundPitch = nil,
			SoundVolume = nil
		})
		RootPart2.CFrame = Clerp(RootPart2.CFrame, TF(0, 3, -5), 0.5)
		RootJoint2.C0 = Clerp(RootJoint2.C0, ROOTC0 * CF(0, 0, 0) * ANGLES(RAD(45), RAD(0), RAD(45)), 0.5 / Animation_Speed)
		Neck2.C0 = Clerp(Neck2.C0, NECKC0 * CF(0, 0, 0 + (1 * SIZE - 1)) * ANGLES(RAD(5), RAD(0), RAD(-45)), 0.5 / Animation_Speed)
		RightShoulder2.C0 = Clerp(RightShoulder2.C0, CF(1.25 * SIZE, 0.5 * SIZE, -0.25 * SIZE) * ANGLES(RAD(185), RAD(0), RAD(-45)) * RIGHTSHOULDERC0, 1 / Animation_Speed)
		LeftShoulder2.C0 = Clerp(LeftShoulder2.C0, CF(-1.5 * SIZE, 0.5 * SIZE, 0) * ANGLES(RAD(0), RAD(0), RAD(-25)) * LEFTSHOULDERC0, 0.5 / Animation_Speed)
		RightHip2.C0 = Clerp(RightHip2.C0, CF(1 * SIZE, -1 * SIZE, 0) * ANGLES(RAD(0), RAD(50 - 1 * SIN(SINE / 6)), RAD(0)) * ANGLES(RAD(-1 * SIN(SINE / 6)), RAD(0), RAD(0)), 0.5 / Animation_Speed)
		LeftHip2.C0 = Clerp(LeftHip2.C0, CF(-1 * SIZE, -1 * SIZE, 0) * ANGLES(RAD(0), RAD(-80 + 1 * SIN(SINE / 6)), RAD(0)) * ANGLES(RAD(-1 * SIN(SINE / 6)), RAD(0), RAD(0)), 0.5 / Animation_Speed)
		RootJoint.C0 = Clerp(RootJoint.C0, ROOTC0 * CF(0, 0, 0) * ANGLES(RAD(0), RAD(0), RAD(25)), 1 / Animation_Speed)
		Neck.C0 = Clerp(Neck.C0, NECKC0 * CF(0, 0, 0) * ANGLES(RAD(0 - 2.5 * SIN(SINE / 12)), RAD(0), RAD(-25)), 1 / Animation_Speed)
		RightShoulder.C0 = Clerp(RightShoulder.C0, CF(1.35, 0.5, 0) * ANGLES(RAD(140), RAD(0), RAD(-25)) * RIGHTSHOULDERC0, 1 / Animation_Speed)
		LeftShoulder.C0 = Clerp(LeftShoulder.C0, CF(-1.5, 0.5, 0) * ANGLES(RAD(0), RAD(0), RAD(-12)) * LEFTSHOULDERC0, 1 / Animation_Speed)
		RightHip.C0 = Clerp(RightHip.C0, CF(1, -1, -0.01) * ANGLES(RAD(0), RAD(90), RAD(0)) * ANGLES(RAD(-8), RAD(0), RAD(0)), 1 / Animation_Speed)
		LeftHip.C0 = Clerp(LeftHip.C0, CF(-1, -1, -0.01) * ANGLES(RAD(0), RAD(-60), RAD(0)) * ANGLES(RAD(-8), RAD(0), RAD(0)), 1 / Animation_Speed)
	end
	if #HITS > 0 then
		KEY = Mouse.KeyDown:connect(function(NEWKEY)
			if NEWKEY == "r" and WHACK == false then
				if PLAYING == false then
					PLAYING = true
				end
				WHACK = true
				PAYDOWN = 70
				HITTING = HITTING + 1
				for E = 1, #HITS do
					if HITS[E][1] then
						local ROOT = GetRoot(HITS[E][1], true)
						if ROOT then
							local HUM = HITS[E][1]:FindFirstChildOfClass("Humanoid")
							if HUM and HUM.Health > 0 then
								HUM.PlatformStand = true
								CreateSound(260430117, ROOT, 3, MRANDOM(8, 12) / 10, false)
								local HIT, POS = Raycast(ROOT.Position + VT(0, 5, 0), CF(RootPart.Position, RootPart.Position - VT(0, 5, 0)).LookVector, 60, HITS[E][1])
								ROOT.CFrame = CF(POS)
								ApplyDamage(HUM, MRANDOM(12, 18))
								ROOT.AssemblyAngularVelocity = VT(MRANDOM(-25, 25), MRANDOM(-25, 25), MRANDOM(-25, 25)) * 4
								if HIT then
									CreateFlyingDebree(HIT, CF(POS), 5, VT(1, 1, 1) * MRANDOM(7, 15) / 20, 5, 30)
								end
							end
						end
					end
				end
				CreateSound(217767125, RightArm, 10, 1, false)
				for i = 0, 0.25, 0.1 / Animation_Speed do
					Swait()
					RootPart2.CFrame = Clerp(RootPart2.CFrame, TF(0, 6, 5), 0.1)
					RootJoint2.C0 = Clerp(RootJoint2.C0, ROOTC0 * CF(0, 0, 0.2) * ANGLES(RAD(0), RAD(0), RAD(0)), 0.5 / Animation_Speed)
					Neck2.C0 = Clerp(Neck2.C0, NECKC0 * CF(0, 0, 0 + (1 * SIZE - 1)) * ANGLES(RAD(25), RAD(0), RAD(0)), 0.5 / Animation_Speed)
					RightShoulder2.C0 = Clerp(RightShoulder2.C0, CF(1.5 * SIZE, 0.5 * SIZE, 0) * ANGLES(RAD(90), RAD(0), RAD(90)) * RIGHTSHOULDERC0, 0.5 / Animation_Speed)
					LeftShoulder2.C0 = Clerp(LeftShoulder2.C0, CF(-1.5 * SIZE, 0.5 * SIZE, 0) * ANGLES(RAD(0), RAD(0), RAD(-15 - 1 * SIN(SINE / 6))) * LEFTSHOULDERC0, 0.5 / Animation_Speed)
					RightHip2.C0 = Clerp(RightHip2.C0, CF(1 * SIZE, -0.5 * SIZE, -0.5 * SIZE) * ANGLES(RAD(0), RAD(80 - 1 * SIN(SINE / 6)), RAD(0)) * ANGLES(RAD(-1 * SIN(SINE / 6)), RAD(0), RAD(0)), 0.5 / Animation_Speed)
					LeftHip2.C0 = Clerp(LeftHip2.C0, CF(-1 * SIZE, -1 * SIZE, 0) * ANGLES(RAD(0), RAD(-80 + 1 * SIN(SINE / 6)), RAD(0)) * ANGLES(RAD(-1 * SIN(SINE / 6)), RAD(0), RAD(0)), 0.5 / Animation_Speed)
					RootJoint.C0 = Clerp(RootJoint.C0, ROOTC0 * CF(0, 0, 0.1) * ANGLES(RAD(0), RAD(0), RAD(0)), 1 / Animation_Speed)
					Neck.C0 = Clerp(Neck.C0, NECKC0 * CF(0, 0, 0) * ANGLES(RAD(0 - 2.5 * SIN(SINE / 12)), RAD(0), RAD(0)), 1 / Animation_Speed)
					RightShoulder.C0 = Clerp(RightShoulder.C0, CF(1.5, 0.5, 0) * ANGLES(RAD(90), RAD(0), RAD(90)) * RIGHTSHOULDERC0, 1 / Animation_Speed)
					LeftShoulder.C0 = Clerp(LeftShoulder.C0, CF(-1.5, 0.5, 0.4) * ANGLES(RAD(-25), RAD(0), RAD(45)) * LEFTSHOULDERC0, 1 / Animation_Speed)
					RightHip.C0 = Clerp(RightHip.C0, CF(1, -1.1, -0.01) * ANGLES(RAD(0), RAD(90), RAD(0)) * ANGLES(RAD(-3), RAD(0), RAD(0)), 1 / Animation_Speed)
					LeftHip.C0 = Clerp(LeftHip.C0, CF(-1, -1.1, -0.01) * ANGLES(RAD(0), RAD(-90), RAD(0)) * ANGLES(RAD(-3), RAD(0), RAD(0)), 1 / Animation_Speed)
				end
				WHACK = false
			end
		end)
	end
	for i = 0, 1, 0.1 / Animation_Speed do
		Swait()
		if PLAYING == true then
			break
		end
		RootPart2.CFrame = Clerp(RootPart2.CFrame, TF(0, 3, -5), 0.5)
		RootJoint2.C0 = Clerp(RootJoint2.C0, ROOTC0 * CF(0, 0, 0) * ANGLES(RAD(45), RAD(0), RAD(45)), 0.5 / Animation_Speed)
		Neck2.C0 = Clerp(Neck2.C0, NECKC0 * CF(0, 0, 0 + (1 * SIZE - 1)) * ANGLES(RAD(5), RAD(0), RAD(-45)), 0.5 / Animation_Speed)
		RightShoulder2.C0 = Clerp(RightShoulder2.C0, CF(1.25 * SIZE, 0.5 * SIZE, -0.25 * SIZE) * ANGLES(RAD(185), RAD(0), RAD(-45)) * RIGHTSHOULDERC0, 1 / Animation_Speed)
		LeftShoulder2.C0 = Clerp(LeftShoulder2.C0, CF(-1.5 * SIZE, 0.5 * SIZE, 0) * ANGLES(RAD(0), RAD(0), RAD(-25)) * LEFTSHOULDERC0, 0.5 / Animation_Speed)
		RightHip2.C0 = Clerp(RightHip2.C0, CF(1 * SIZE, -1 * SIZE, 0) * ANGLES(RAD(0), RAD(50 - 1 * SIN(SINE / 6)), RAD(0)) * ANGLES(RAD(-1 * SIN(SINE / 6)), RAD(0), RAD(0)), 0.5 / Animation_Speed)
		LeftHip2.C0 = Clerp(LeftHip2.C0, CF(-1 * SIZE, -1 * SIZE, 0) * ANGLES(RAD(0), RAD(-80 + 1 * SIN(SINE / 6)), RAD(0)) * ANGLES(RAD(-1 * SIN(SINE / 6)), RAD(0), RAD(0)), 0.5 / Animation_Speed)
		RootJoint.C0 = Clerp(RootJoint.C0, ROOTC0 * CF(0, 0, 0) * ANGLES(RAD(0), RAD(0), RAD(25)), 1 / Animation_Speed)
		Neck.C0 = Clerp(Neck.C0, NECKC0 * CF(0, 0, 0) * ANGLES(RAD(0 - 2.5 * SIN(SINE / 12)), RAD(0), RAD(-25)), 1 / Animation_Speed)
		RightShoulder.C0 = Clerp(RightShoulder.C0, CF(1.35, 0.5, 0) * ANGLES(RAD(140), RAD(0), RAD(-25)) * RIGHTSHOULDERC0, 1 / Animation_Speed)
		LeftShoulder.C0 = Clerp(LeftShoulder.C0, CF(-1.5, 0.5, 0) * ANGLES(RAD(0), RAD(0), RAD(-12)) * LEFTSHOULDERC0, 1 / Animation_Speed)
		RightHip.C0 = Clerp(RightHip.C0, CF(1, -1, -0.01) * ANGLES(RAD(0), RAD(90), RAD(0)) * ANGLES(RAD(-8), RAD(0), RAD(0)), 1 / Animation_Speed)
		LeftHip.C0 = Clerp(LeftHip.C0, CF(-1, -1, -0.01) * ANGLES(RAD(0), RAD(-60), RAD(0)) * ANGLES(RAD(-8), RAD(0), RAD(0)), 1 / Animation_Speed)
	end
	if PLAYING == true then
		Rooted = true
		repeat
			Swait()
			if WHACK == false then
				PAYDOWN = PAYDOWN - 1
				if PAYDOWN <= 0 then
					PLAYING = false
				end
				RootPart2.CFrame = Clerp(RootPart2.CFrame, TF(0, 6, 5), 0.1)
				RootJoint2.C0 = Clerp(RootJoint2.C0, ROOTC0 * CF(0, 0, 0) * ANGLES(RAD(0), RAD(0), RAD(0)), 0.5 / Animation_Speed)
				Neck2.C0 = Clerp(Neck2.C0, NECKC0 * CF(0, 0, 0 + (1 * SIZE - 1)) * ANGLES(RAD(25), RAD(0), RAD(0)), 0.5 / Animation_Speed)
				RightShoulder2.C0 = Clerp(RightShoulder2.C0, CF(1.5 * SIZE, 0.5 * SIZE, 0) * ANGLES(RAD(0), RAD(0), RAD(120)) * ANGLES(RAD(0), RAD(-90), RAD(0)) * RIGHTSHOULDERC0, 0.5 / Animation_Speed)
				LeftShoulder2.C0 = Clerp(LeftShoulder2.C0, CF(-1.5 * SIZE, 0.5 * SIZE, 0) * ANGLES(RAD(0), RAD(0), RAD(-15 - 1 * SIN(SINE / 6))) * LEFTSHOULDERC0, 0.5 / Animation_Speed)
				RightHip2.C0 = Clerp(RightHip2.C0, CF(1 * SIZE, -0.5 * SIZE, -0.5 * SIZE) * ANGLES(RAD(0), RAD(80 - 1 * SIN(SINE / 6)), RAD(0)) * ANGLES(RAD(-1 * SIN(SINE / 6)), RAD(0), RAD(0)), 0.5 / Animation_Speed)
				LeftHip2.C0 = Clerp(LeftHip2.C0, CF(-1 * SIZE, -1 * SIZE, 0) * ANGLES(RAD(0), RAD(-80 + 1 * SIN(SINE / 6)), RAD(0)) * ANGLES(RAD(-1 * SIN(SINE / 6)), RAD(0), RAD(0)), 0.5 / Animation_Speed)
				RootJoint.C0 = Clerp(RootJoint.C0, ROOTC0 * CF(0, 0, 0) * ANGLES(RAD(0), RAD(0), RAD(0)), 1 / Animation_Speed)
				Neck.C0 = Clerp(Neck.C0, NECKC0 * CF(0, 0, 0) * ANGLES(RAD(0 - 2.5 * SIN(SINE / 12)), RAD(0), RAD(0)), 1 / Animation_Speed)
				RightShoulder.C0 = Clerp(RightShoulder.C0, CF(1.5, 0.5, 0) * ANGLES(RAD(0), RAD(0), RAD(120)) * ANGLES(RAD(0), RAD(-90), RAD(0)) * RIGHTSHOULDERC0, 1 / Animation_Speed)
				LeftShoulder.C0 = Clerp(LeftShoulder.C0, CF(-1.5, 0.5, 0.4) * ANGLES(RAD(-25), RAD(0), RAD(45)) * LEFTSHOULDERC0, 1 / Animation_Speed)
				RightHip.C0 = Clerp(RightHip.C0, CF(1, -1, -0.01) * ANGLES(RAD(0), RAD(90), RAD(0)) * ANGLES(RAD(-3), RAD(0), RAD(0)), 1 / Animation_Speed)
				LeftHip.C0 = Clerp(LeftHip.C0, CF(-1, -1, -0.01) * ANGLES(RAD(0), RAD(-90), RAD(0)) * ANGLES(RAD(-3), RAD(0), RAD(0)), 1 / Animation_Speed)
			end
		until PLAYING == false
	end
	if KEY then
		KEY:Disconnect()
	end
	if HITTING > 4 then
		CreateSound(1535994137, Head, 10, 1, false)
		for i = 0, 2.4, 0.1 / Animation_Speed do
			Swait()
			RootPart2.CFrame = Clerp(RootPart2.CFrame, TF(0, 6, 5), 0.1)
			RootJoint2.C0 = Clerp(RootJoint2.C0, ROOTC0 * CF(0, 0, 0.25 * COS(SINE / 12)) * ANGLES(RAD(-5 + 2 * SIN(SINE / 12)), RAD(15), RAD(35)), 0.5 / Animation_Speed)
			Neck2.C0 = Clerp(Neck2.C0, NECKC0 * CF(0, 0, 0 + (1 * SIZE - 1)) * ANGLES(RAD(25 - 2 * SIN(SINE / 12)), RAD(0), RAD(-35)), 0.5 / Animation_Speed)
			RightShoulder2.C0 = Clerp(RightShoulder2.C0, CF(1.5 * SIZE, 0.5 * SIZE, 0) * ANGLES(RAD(-35 + 15 * SIN(SINE / 12)), RAD(0), RAD(60)) * RIGHTSHOULDERC0, 0.5 / Animation_Speed)
			LeftShoulder2.C0 = Clerp(LeftShoulder2.C0, CF(-1.5 * SIZE, 0.5 * SIZE, 0) * ANGLES(RAD(-35 + 15 * SIN(SINE / 12)), RAD(0), RAD(-60)) * LEFTSHOULDERC0, 0.5 / Animation_Speed)
			RightHip2.C0 = Clerp(RightHip2.C0, CF(1 * SIZE, -1 * SIZE, 0) * ANGLES(RAD(0), RAD(80 - 1 * SIN(SINE / 6)), RAD(0)) * ANGLES(RAD(-3 * SIN(SINE / 12)), RAD(0), RAD(0)), 0.5 / Animation_Speed)
			LeftHip2.C0 = Clerp(LeftHip2.C0, CF(-1 * SIZE, -0.3 * SIZE, -0.6 * SIZE) * ANGLES(RAD(-25), RAD(-80 + 1 * SIN(SINE / 6)), RAD(0)) * ANGLES(RAD(-3 * SIN(SINE / 12)), RAD(0), RAD(0)), 0.5 / Animation_Speed)
			RootJoint.C0 = Clerp(RootJoint.C0, ROOTC0 * CF(0, 0, 0) * ANGLES(RAD(0), RAD(0), RAD(0)), 1 / Animation_Speed)
			Neck.C0 = Clerp(Neck.C0, NECKC0 * CF(0, 0, 0) * ANGLES(RAD(-25), RAD(15), RAD(15)), 1 / Animation_Speed)
			RightShoulder.C0 = Clerp(RightShoulder.C0, CF(1.5, 0.65, 0) * ANGLES(RAD(170), RAD(0), RAD(-13)) * RIGHTSHOULDERC0, 1 / Animation_Speed)
			LeftShoulder.C0 = Clerp(LeftShoulder.C0, CF(-1.5, 0.5, 0) * ANGLES(RAD(0), RAD(0), RAD(-3)) * LEFTSHOULDERC0, 1 / Animation_Speed)
			RightHip.C0 = Clerp(RightHip.C0, CF(1, -1, -0.01) * ANGLES(RAD(0), RAD(90), RAD(0)) * ANGLES(RAD(-2), RAD(0), RAD(0)), 1 / Animation_Speed)
			LeftHip.C0 = Clerp(LeftHip.C0, CF(-1, -1, -0.01) * ANGLES(RAD(0), RAD(-90), RAD(0)) * ANGLES(RAD(-2), RAD(0), RAD(0)), 1 / Animation_Speed)
		end
	end
	UNDO()
	Speed = 16
	REPLAY = false
	ATTACK = false
	Rooted = false
end
local function TakeOn()
	ATTACK = true
	Rooted = true
	coroutine.resume(coroutine.create(function()
		repeat
			Swait()
			RootJoint2.C0 = Clerp(RootJoint2.C0, ROOTC0 * CF(0, 0, 0.25 * COS(SINE / 12)) * ANGLES(RAD(-5 + 2 * SIN(SINE / 12)), RAD(15), RAD(35)), 0.5 / Animation_Speed)
			Neck2.C0 = Clerp(Neck2.C0, NECKC0 * CF(0, 0, 0 + (1 * SIZE - 1)) * ANGLES(RAD(25 - 2 * SIN(SINE / 12)), RAD(0), RAD(-35)), 0.5 / Animation_Speed)
			RightShoulder2.C0 = Clerp(RightShoulder2.C0, CF(1.5 * SIZE, 0.5 * SIZE, 0) * ANGLES(RAD(-35 + 15 * SIN(SINE / 12)), RAD(0), RAD(60)) * RIGHTSHOULDERC0, 0.5 / Animation_Speed)
			LeftShoulder2.C0 = Clerp(LeftShoulder2.C0, CF(-1.5 * SIZE, 0.5 * SIZE, 0) * ANGLES(RAD(-35 + 15 * SIN(SINE / 12)), RAD(0), RAD(-60)) * LEFTSHOULDERC0, 0.5 / Animation_Speed)
			RightHip2.C0 = Clerp(RightHip2.C0, CF(1 * SIZE, -1 * SIZE, 0) * ANGLES(RAD(0), RAD(80 - 1 * SIN(SINE / 6)), RAD(0)) * ANGLES(RAD(-3 * SIN(SINE / 12)), RAD(0), RAD(0)), 0.5 / Animation_Speed)
			LeftHip2.C0 = Clerp(LeftHip2.C0, CF(-1 * SIZE, -0.3 * SIZE, -0.6 * SIZE) * ANGLES(RAD(-25), RAD(-80 + 1 * SIN(SINE / 6)), RAD(0)) * ANGLES(RAD(-3 * SIN(SINE / 12)), RAD(0), RAD(0)), 0.5 / Animation_Speed)
		until ATTACK == false
	end))
	CreateSound(1535994669, Head, 10, 1, false)
	for i = 0, 1, 0.1 / Animation_Speed do
		Swait()
		RootJoint.C0 = Clerp(RootJoint.C0, ROOTC0 * CF(0, 0, 0) * ANGLES(RAD(0), RAD(0), RAD(0)), 1 / Animation_Speed)
		Neck.C0 = Clerp(Neck.C0, NECKC0 * CF(0, 0, 0) * ANGLES(RAD(35), RAD(0), RAD(0)), 1 / Animation_Speed)
		RightShoulder.C0 = Clerp(RightShoulder.C0, CF(1.5, 0.5, 0) * ANGLES(RAD(170), RAD(0), RAD(-25)) * RIGHTSHOULDERC0, 1 / Animation_Speed)
		LeftShoulder.C0 = Clerp(LeftShoulder.C0, CF(-1.35, 0.5, 0.2) * ANGLES(RAD(-25), RAD(0), RAD(45)) * LEFTSHOULDERC0, 1 / Animation_Speed)
		RightHip.C0 = Clerp(RightHip.C0, CF(1, -1, -0.01) * ANGLES(RAD(0), RAD(80), RAD(0)) * ANGLES(RAD(0), RAD(0), RAD(0)), 1 / Animation_Speed)
		LeftHip.C0 = Clerp(LeftHip.C0, CF(-1, -1, -0.01) * ANGLES(RAD(0), RAD(-80), RAD(0)) * ANGLES(RAD(0), RAD(0), RAD(0)), 1 / Animation_Speed)
	end
	for i = 0, 1, 0.1 / Animation_Speed do
		Swait()
		RootJoint.C0 = Clerp(RootJoint.C0, ROOTC0 * CF(0, 0, 0) * ANGLES(RAD(0), RAD(0), RAD(0)), 1 / Animation_Speed)
		Neck.C0 = Clerp(Neck.C0, NECKC0 * CF(0, 0, 0) * ANGLES(RAD(-10), RAD(0), RAD(35)), 1 / Animation_Speed)
		RightShoulder.C0 = Clerp(RightShoulder.C0, CF(1.5, 0.5, 0) * ANGLES(RAD(130), RAD(0), RAD(0)) * RIGHTSHOULDERC0, 1 / Animation_Speed)
		LeftShoulder.C0 = Clerp(LeftShoulder.C0, CF(-1.35, 0.5, 0.2) * ANGLES(RAD(-25), RAD(0), RAD(45)) * LEFTSHOULDERC0, 1 / Animation_Speed)
		RightHip.C0 = Clerp(RightHip.C0, CF(1, -1, -0.01) * ANGLES(RAD(0), RAD(80), RAD(0)) * ANGLES(RAD(0), RAD(0), RAD(0)), 1 / Animation_Speed)
		LeftHip.C0 = Clerp(LeftHip.C0, CF(-1, -1, -0.01) * ANGLES(RAD(0), RAD(-80), RAD(0)) * ANGLES(RAD(0), RAD(0), RAD(0)), 1 / Animation_Speed)
	end
	ATTACK = false
	Rooted = false
end

local function KeyDown(Key)
	if Key == "z" and ATTACK == false then
		Punch()
	end
	if Key == "e" and ATTACK == false and REPLAY == false then
		Throw()
	end
	if Key == "r" and ATTACK == false and REPLAY == false then
		Uppercut()
	end
	if Key == "t" and ATTACK == false then
		Roar()
	end
	if Key == "y" and ATTACK == false then
		TakeOn()
	end
end
local SKILLS = {
	{"z", "Z-Tremor Punch", "Punch"}, {"e", "E-Meteor Impact", "Throw"}, {"r", "R-Uppercut", "Uppercut"}, {"t", "T-Roar", "Roar"}, {"y", "Y-Take On", "Take On"},
}
local SKILLKEY = {z = true, e = true, r = true, t = true, y = true}

local function resetState()
	ATTACK = false
	Rooted = false
	UNANCHOR = true
	REPLAY = false
	Speed = IW.WalkSpeed
	if FACE.on then
		for i = 1, #FACE.parts do
			pcall(function()
				FACE.parts[i]:Destroy()
			end)
		end
		FACE.parts = {}
		FACE.on = false
	end
end

local WHITE = C3(1, 1, 1)
local gui = inst("ScreenGui", nil, {Name = "InternalWar", ResetOnSpawn = false, DisplayOrder = 55, ZIndexBehavior = Enum.ZIndexBehavior.Sibling})
gui.Parent = C.guiParent()
C.gui = gui
local COL = {bg = Color3.fromRGB(12, 12, 15), line = Color3.fromRGB(70, 70, 82), text = Color3.fromRGB(236, 238, 248), muted = Color3.fromRGB(150, 156, 184), accent = Color3.fromRGB(235, 235, 245), good = Color3.fromRGB(96, 214, 150), bad = Color3.fromRGB(255, 110, 120)}
local function round(o, r)
	inst("UICorner", o, {CornerRadius = UDim.new(0, r or 6)})
end
local function label(parent, props)
	local l = inst("TextLabel", parent, {BackgroundTransparency = 1, TextColor3 = COL.text, Font = Enum.Font.Code, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0})
	for k, v in pairs(props) do
		l[k] = v
	end
	return l
end
local function button(parent, props)
	local b = inst("TextButton", parent, {BackgroundColor3 = Color3.fromRGB(32, 32, 40), TextColor3 = COL.text, Font = Enum.Font.GothamMedium, TextSize = 13, AutoButtonColor = true, BorderSizePixel = 0})
	for k, v in pairs(props) do
		b[k] = v
	end
	round(b, 6)
	return b
end

local sizePanel = inst("Frame", gui, {
	Name = "TitanScale", Size = UDim2.fromOffset(280, 138), Position = UDim2.new(0.5, -140, 0.2, 0), BackgroundColor3 = COL.bg, BackgroundTransparency = 0.05,
	BorderSizePixel = 0, Visible = false, Active = true,
})
round(sizePanel, 8)
inst("UIStroke", sizePanel, {Color = COL.line, Thickness = 1})
label(sizePanel, {Position = UDim2.fromOffset(12, 8), Size = UDim2.new(1, -120, 0, 24), Text = "Titan Scale", TextSize = 18, Font = Enum.Font.GothamBold})
local sizeClose = button(sizePanel, {Position = UDim2.new(1, -36, 0, 8), Size = UDim2.fromOffset(26, 24), Text = "x"})
local sizeStop = button(sizePanel, {Position = UDim2.new(1, -96, 0, 8), Size = UDim2.fromOffset(54, 24), Text = "Stop", TextColor3 = COL.bad})
local sizeBox = inst("TextBox", sizePanel, {
	Position = UDim2.fromOffset(12, 40), Size = UDim2.fromOffset(86, 28), BackgroundColor3 = Color3.fromRGB(32, 32, 40), TextColor3 = COL.text, Font = Enum.Font.Code, TextSize = 16,
	ClearTextOnFocus = false, Text = "1", BorderSizePixel = 0, PlaceholderText = "1",
})
round(sizeBox, 6)
local sizeReset = button(sizePanel, {Position = UDim2.fromOffset(106, 40), Size = UDim2.fromOffset(70, 28), Text = "Reset"})
local setLabel = label(sizePanel, {Position = UDim2.fromOffset(184, 40), Size = UDim2.fromOffset(92, 28), Text = "", TextSize = 11, TextColor3 = COL.muted, TextWrapped = true})
local bar = inst("Frame", sizePanel, {Position = UDim2.fromOffset(16, 88), Size = UDim2.new(1, -32, 0, 6), BackgroundColor3 = Color3.fromRGB(200, 200, 210), BorderSizePixel = 0})
round(bar, 3)
local knob = inst("Frame", bar, {Size = UDim2.fromOffset(18, 18), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0.5, 0), BackgroundColor3 = WHITE, BorderSizePixel = 0})
round(knob, 9)
local barHit = inst("TextButton", sizePanel, {Position = UDim2.fromOffset(6, 74), Size = UDim2.new(1, -12, 0, 34), BackgroundTransparency = 1, Text = ""})
label(sizePanel, {Position = UDim2.fromOffset(12, 110), Size = UDim2.new(1, -24, 0, 22), Text = "slider 0.5 to 5 (0.1 steps), or type 0.001 to 20. Only the Titan changes", TextSize = 11, TextColor3 = COL.muted, TextWrapped = true})
local function setName()
	if TS.set == "ugc" then
		return string.format("UGC limbs, og %g", DEFSIZE.ugc)
	end
	return string.format("Void hats, og %g", DEFSIZE.void)
end
local function syncSizeUi()
	local v = SET[TS.set]
	sizeBox.Text = string.format("%g", v)
	setLabel.Text = setName()
	knob.Position = UDim2.new(CLAMP((v - 0.5) / 4.5, 0, 1), 0, 0.5, 0)
end
local function setTitanSize(n)
	if type(n) ~= "number" or n ~= n then
		return false
	end
	n = CLAMP(n, 0.001, 20)
	TS.goal = n
	SET[TS.set] = n
	saveSettings()
	syncSizeUi()
	return true
end
syncSizeUi()
sizeBox.FocusLost:Connect(function()
	if not setTitanSize(tonumber(sizeBox.Text)) then
		syncSizeUi()
	end
end)
sizeReset.MouseButton1Click:Connect(function()
	setTitanSize(DEFSIZE[TS.set])
end)
sizeClose.MouseButton1Click:Connect(function()
	sizePanel.Visible = false
end)
sizeStop.MouseButton1Click:Connect(function()
	task.spawn(C.stop)
end)
local draggingSize = false
local function sizeFromX(x)
	local rel = CLAMP((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
	setTitanSize(math.floor((0.5 + rel * 4.5) * 10 + 0.5) / 10)
end
barHit.InputBegan:Connect(function(io)
	if io.UserInputType == Enum.UserInputType.MouseButton1 or io.UserInputType == Enum.UserInputType.Touch then
		draggingSize = true
		sizeFromX(io.Position.X)
	end
end)
C.connect(UIS.InputChanged, function(io)
	if draggingSize and (io.UserInputType == Enum.UserInputType.MouseMovement or io.UserInputType == Enum.UserInputType.Touch) then
		sizeFromX(io.Position.X)
	end
end)
C.connect(UIS.InputEnded, function(io)
	if io.UserInputType == Enum.UserInputType.MouseButton1 or io.UserInputType == Enum.UserInputType.Touch then
		draggingSize = false
	end
end)
function C.toggleSize()
	sizePanel.Visible = not sizePanel.Visible
	if sizePanel.Visible then
		syncSizeUi()
	end
end

local ALTAB = {"Head", "Torso", "Arms", "Legs", "UGC Torso", "UGC R Arm", "UGC L Arm", "UGC R Leg", "UGC L Leg"}
local AL = {version = 1, title = "InternalWar", tabs = ALTAB, file = ALIGNFILE, dirty = false, open = false, key = string.upper(IW.AlignKey or "p"), hint = "Head to Legs line up the Void hats, the UGC tabs the UGC limb set. Tap Alignment on the Main Scripts bar to open it again."}
local alState = {cur = 1, watchers = {}, genv = (typeof(getgenv) == "function" and getgenv()) or _G}
local function alFire(what)
	for _, f in ipairs(table.clone(alState.watchers)) do
		pcall(f, what)
	end
end
local function alHub()
	local h = alState.genv.AtsukoHub
	return type(h) == "table" and h or nil
end
local function alSlot(s)
	if type(s) ~= "number" then
		return nil
	end
	if s >= 1 and s <= 4 then
		return ALIGN[s]
	end
	return ALIGN2[s - 4]
end
function AL.alive()
	return C.alive
end
function AL.focus(s)
	if alSlot(s) then
		alState.cur = s
	end
end
function AL.get(s)
	local v = alSlot(s)
	return v and table.clone(v) or nil
end
function AL.set(s, k, n)
	local v = alSlot(s)
	n = tonumber(n)
	if not v or not n or n ~= n or math.abs(n) >= 1e4 then
		return nil
	end
	if k > 3 then
		n = ((n + 180) % 360) - 180
		n = math.floor(n * 10 + 0.5) / 10
	else
		n = math.floor(n * 1000 + 0.5) / 1000
	end
	v[k] = n
	AL.dirty = true
	AL.later()
	return n
end
function AL.put(s, vals)
	local v = alSlot(s)
	if not v or type(vals) ~= "table" then
		return
	end
	for k = 1, 6 do
		v[k] = tonumber(vals[k]) or 0
	end
	AL.dirty = true
	AL.later()
end
function AL.reset(s)
	AL.put(s, {0, 0, 0, 0, 0, 0})
end
function AL.save()
	AL.tok = (AL.tok or 0) + 1
	local ok = saveAlign()
	if ok then
		AL.dirty = false
		return true
	end
	return false, "couldn't write " .. ALIGNFILE
end
function AL.later()
	AL.tok = (AL.tok or 0) + 1
	local my = AL.tok
	task.delay(1.5, function()
		if my == AL.tok and AL.dirty and C.alive and AL.save() then
			alFire("saved")
		end
	end)
end
function AL.load()
	loadAlign()
	AL.dirty = false
	alFire("load")
	return true
end
function AL.watch(f)
	local list = alState.watchers
	list[#list + 1] = f
	return function()
		local i = table.find(list, f)
		if i then
			table.remove(list, i)
		end
	end
end
function AL.found()
	local n, u = hatCount()
	return "Void hats: " .. (n - u) .. " of 6  ·  UGC limbs: " .. u .. " of 5"
end
AL.optList = {{"size", "Titan size", "button"}}
AL.optsSaved = false
function AL.opts()
	return {}
end
function AL.setOpt(name)
	if name == "size" and C.toggleSize then
		C.toggleSize()
	end
end
function C.toggleAlign()
	local h = alHub()
	if h and type(h.Align) == "function" then
		pcall(h.Align)
	else
		note("Open Atsuko Hub to line the Titan hats up, the alignment lives there now")
	end
end
alState.genv.AtsukoAlign = AL
do
	local h = alHub()
	if h and type(h.AlignReady) == "function" then
		pcall(h.AlignReady)
	end
end
C.onStop(function()
	if AL.dirty then
		pcall(saveAlign)
		AL.dirty = false
	end
	AL.open = false
	if alState.genv.AtsukoAlign == AL then
		alState.genv.AtsukoAlign = nil
	end
	alFire("stop")
	local h = alHub()
	if h and type(h.AlignReady) == "function" then
		pcall(h.AlignReady)
	end
end)
C.connect(UIS.InputBegan, function(io, gp)
	if io.UserInputType == Enum.UserInputType.Keyboard and not gp and not UIS:GetFocusedTextBox() then
		if string.lower(io.KeyCode.Name) == string.lower(IW.AlignKey or "p") and not (UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.RightShift)) then
			C.toggleAlign()
		end
	end
end)

local function sizeCmd(arg)
	local a = string.lower(arg or ""):gsub("x$", "")
	if a == "" then
		C.toggleSize()
		note(string.format("%s: Titan scale is %g. -size 2, -size 0.5, -size reset for the og", setName(), SET[TS.set]))
		return
	end
	local n = (a == "normal" or a == "reset" or a == "og") and DEFSIZE[TS.set] or tonumber(a)
	if not setTitanSize(n) then
		note("-size (number), like -size 2 or -size 0.5")
		return
	end
	note(string.format("Titan scale (%s): %g", TS.set == "ugc" and "UGC limbs" or "Void hats", SET[TS.set]))
end
local function musicCmd(arg)
	local a = string.lower(arg or "")
	if a == "off" or a == "stop" then
		C.music:Pause()
		note("music off")
	elseif a == "on" or a == "play" or a == "" then
		C.music:Play()
		note("music on")
	elseif tonumber(a) then
		C.music.Volume = CLAMP(tonumber(a), 0, 10)
		note("music volume " .. C.music.Volume)
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
	body = body:gsub("^/emote%s+", "")
	body = body:gsub("^/e%s+", "")
	body = body:gsub("^/e([%-;])", "%1")
	local name, rest = body:match("^[%-;](%a+)%s*(.*)$")
	local ok = name == "size" or name == "align" or name == "stop" or name == "music" or name == "hats"
	if not ok then
		return
	end
	local t = os.clock()
	if body == lastCmd and src ~= lastSrc and t - lastAt < 5 then
		return
	end
	lastCmd, lastAt, lastSrc = body, t, src
	if name == "size" then
		sizeCmd(rest)
	elseif name == "align" then
		C.toggleAlign()
	elseif name == "music" then
		musicCmd(rest)
	elseif name == "hats" then
		local report = hatReport()
		print("[Internal War] hats\n" .. report)
		local copied = false
		if setclipboard then
			copied = pcall(setclipboard, report)
		end
		local n, u = hatCount()
		note("Titan hats found: " .. n .. " (" .. u .. " UGC limbs). Full list in the console (F9)" .. (copied and ", copied to your clipboard" or ""))
	else
		note("Stopped")
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

local MV = {v = VT(0, 0, 0), last = nil}

local function mainStep()
	local vel = MV.v
	local TORSOVELOCITY = (vel * VT(1, 0, 1)).Magnitude
	local TORSOVERTICALVELOCITY = vel.Y
	local HITFLOOR = Raycast(RootPart.Position, VT(0, -1, 0), 4, Character)
	if HITFLOOR == nil then
		local okg, g = pcall(fd.isOnGround)
		if okg and g then
			HITFLOOR = true
		end
	end
	local st = C.state
	if st == "Walk" and TORSOVELOCITY < 1.5 then
		TORSOVELOCITY = 1.5
	elseif st == "Jump" then
		HITFLOOR = nil
		TORSOVERTICALVELOCITY = math.max(TORSOVERTICALVELOCITY, 2)
	elseif st == "Fall" then
		HITFLOOR = nil
		TORSOVERTICALVELOCITY = math.min(TORSOVERTICALVELOCITY, -2)
	end
	local WALKSPEEDVALUE = 4
	if ANIM == "Walk" and TORSOVELOCITY > 1 then
		RootJoint.C1 = Clerp(RootJoint.C1, ROOTC0 * CF(0, 0, -0.05 * COS(SINE / (WALKSPEEDVALUE / 2))) * ANGLES(RAD(0), RAD(0) - RootPart.RotVelocity.Y / 75, RAD(0)), 2 * (Humanoid.WalkSpeed / 16) / Animation_Speed)
		Neck.C1 = Clerp(Neck.C1, CF(0, -0.5, 0) * ANGLES(RAD(-90), RAD(0), RAD(180)) * ANGLES(RAD(2.5 * SIN(SINE / (WALKSPEEDVALUE / 2))), RAD(0), RAD(0) - Head.RotVelocity.Y / 30), 0.2 * (Humanoid.WalkSpeed / 16) / Animation_Speed)
		RightHip.C1 = Clerp(RightHip.C1, CF(0.5, 0.875 - 0.125 * SIN(SINE / WALKSPEEDVALUE) - 0.15 * COS(SINE / WALKSPEEDVALUE * 2), -0.125 * COS(SINE / WALKSPEEDVALUE) + 0.2 - 0.2 * COS(SINE / WALKSPEEDVALUE)) * ANGLES(RAD(0), RAD(90), RAD(0)) * ANGLES(RAD(0) - RightLeg.RotVelocity.Y / 75, RAD(0), RAD(76 * COS(SINE / WALKSPEEDVALUE))), 0.4 * (Humanoid.WalkSpeed / 16) / Animation_Speed)
		LeftHip.C1 = Clerp(LeftHip.C1, CF(-0.5, 0.875 + 0.125 * SIN(SINE / WALKSPEEDVALUE) - 0.15 * COS(SINE / WALKSPEEDVALUE * 2), 0.125 * COS(SINE / WALKSPEEDVALUE) + 0.2 + 0.2 * COS(SINE / WALKSPEEDVALUE)) * ANGLES(RAD(0), RAD(-90), RAD(0)) * ANGLES(RAD(0) + LeftLeg.RotVelocity.Y / 75, RAD(0), RAD(76 * COS(SINE / WALKSPEEDVALUE))), 0.4 * (Humanoid.WalkSpeed / 16) / Animation_Speed)
	elseif ANIM ~= "Walk" or TORSOVELOCITY < 1 then
		RootJoint.C1 = Clerp(RootJoint.C1, ROOTC0 * CF(0, 0, 0) * ANGLES(RAD(0), RAD(0), RAD(0)), 0.2 / Animation_Speed)
		Neck.C1 = Clerp(Neck.C1, CF(0, -0.5, 0) * ANGLES(RAD(-90), RAD(0), RAD(180)) * ANGLES(RAD(0), RAD(0), RAD(0)), 0.2 / Animation_Speed)
		RightHip.C1 = Clerp(RightHip.C1, CF(0.5, 1, 0) * ANGLES(RAD(0), RAD(90), RAD(0)) * ANGLES(RAD(0), RAD(0), RAD(0)), 0.2 / Animation_Speed)
		LeftHip.C1 = Clerp(LeftHip.C1, CF(-0.5, 1, 0) * ANGLES(RAD(0), RAD(-90), RAD(0)) * ANGLES(RAD(0), RAD(0), RAD(0)), 0.2 / Animation_Speed)
	end
	if TORSOVERTICALVELOCITY > 1 and HITFLOOR == nil then
		ANIM = "Jump"
		if ATTACK == false then
			RootJoint2.C0 = Clerp(RootJoint2.C0, ROOTC0 * CF(0, 0, 0) * ANGLES(RAD(-5), RAD(0), RAD(0)), 1 / Animation_Speed)
			Neck2.C0 = Clerp(Neck2.C0, NECKC0 * CF(0, 0, 0 + (1 * SIZE - 1)) * ANGLES(RAD(25), RAD(0), RAD(0)), 1 / Animation_Speed)
			RightShoulder2.C0 = Clerp(RightShoulder2.C0, CF(1.5 * SIZE, 0.5 * SIZE, 0) * ANGLES(RAD(0), RAD(0), RAD(15)) * RIGHTSHOULDERC0, 1 / Animation_Speed)
			LeftShoulder2.C0 = Clerp(LeftShoulder2.C0, CF(-1.5 * SIZE, 0.5 * SIZE, 0) * ANGLES(RAD(0), RAD(0), RAD(-15)) * LEFTSHOULDERC0, 1 / Animation_Speed)
			RightHip2.C0 = Clerp(RightHip2.C0, CF(1 * SIZE, -0.4 * SIZE, -0.5 * SIZE) * ANGLES(RAD(-25), RAD(80 - 1 * SIN(SINE / 6)), RAD(0)) * ANGLES(RAD(-1 * SIN(SINE / 6)), RAD(0), RAD(0)), 1 / Animation_Speed)
			LeftHip2.C0 = Clerp(LeftHip2.C0, CF(-1 * SIZE, -0.4 * SIZE, -0.5 * SIZE) * ANGLES(RAD(-25), RAD(-80 + 1 * SIN(SINE / 6)), RAD(0)) * ANGLES(RAD(-1 * SIN(SINE / 6)), RAD(0), RAD(0)), 1 / Animation_Speed)
			RootJoint.C0 = Clerp(RootJoint.C0, ROOTC0 * CF(0, 0, 0) * ANGLES(RAD(-5), RAD(0), RAD(0)), 1 / Animation_Speed)
			Neck.C0 = Clerp(Neck.C0, NECKC0 * CF(0, 0, 0) * ANGLES(RAD(-25), RAD(0), RAD(0)), 1 / Animation_Speed)
			RightShoulder.C0 = Clerp(RightShoulder.C0, CF(1.5, 0.5, 0) * ANGLES(RAD(-35), RAD(0), RAD(25 + 10 * COS(SINE / 12))) * RIGHTSHOULDERC0, 1 / Animation_Speed)
			LeftShoulder.C0 = Clerp(LeftShoulder.C0, CF(-1.5, 0.5, 0) * ANGLES(RAD(-35), RAD(0), RAD(-25 - 10 * COS(SINE / 12))) * LEFTSHOULDERC0, 1 / Animation_Speed)
			RightHip.C0 = Clerp(RightHip.C0, CF(1, -0.4, -0.6) * ANGLES(RAD(0), RAD(90), RAD(0)) * ANGLES(RAD(-1 * SIN(SINE / 6)), RAD(0), RAD(0)), 1 / Animation_Speed)
			LeftHip.C0 = Clerp(LeftHip.C0, CF(-1, -1, 0) * ANGLES(RAD(0), RAD(-85), RAD(0)) * ANGLES(RAD(-1 * SIN(SINE / 6)), RAD(0), RAD(0)), 1 / Animation_Speed)
		end
	elseif TORSOVERTICALVELOCITY < -1 and HITFLOOR == nil then
		ANIM = "Fall"
		if ATTACK == false then
			RootJoint2.C0 = Clerp(RootJoint2.C0, ROOTC0 * CF(0, 0, 0) * ANGLES(RAD(-5), RAD(0), RAD(0)), 1 / Animation_Speed)
			Neck2.C0 = Clerp(Neck2.C0, NECKC0 * CF(0, 0, 0 + (1 * SIZE - 1)) * ANGLES(RAD(25), RAD(0), RAD(0)), 1 / Animation_Speed)
			RightShoulder2.C0 = Clerp(RightShoulder2.C0, CF(1.5 * SIZE, 0.5 * SIZE, 0) * ANGLES(RAD(0), RAD(0), RAD(80)) * RIGHTSHOULDERC0, 1 / Animation_Speed)
			LeftShoulder2.C0 = Clerp(LeftShoulder2.C0, CF(-1.5 * SIZE, 0.5 * SIZE, 0) * ANGLES(RAD(0), RAD(0), RAD(-80)) * LEFTSHOULDERC0, 1 / Animation_Speed)
			RightHip2.C0 = Clerp(RightHip2.C0, CF(1 * SIZE, -0.4 * SIZE, -0.5 * SIZE) * ANGLES(RAD(-25), RAD(80 - 1 * SIN(SINE / 6)), RAD(0)) * ANGLES(RAD(-1 * SIN(SINE / 6)), RAD(0), RAD(0)), 1 / Animation_Speed)
			LeftHip2.C0 = Clerp(LeftHip2.C0, CF(-1 * SIZE, -0.4 * SIZE, -0.5 * SIZE) * ANGLES(RAD(-25), RAD(-80 + 1 * SIN(SINE / 6)), RAD(0)) * ANGLES(RAD(-1 * SIN(SINE / 6)), RAD(0), RAD(0)), 1 / Animation_Speed)
			RootJoint.C0 = Clerp(RootJoint.C0, ROOTC0 * CF(0, 0, 0) * ANGLES(RAD(15), RAD(0), RAD(0)), 1 / Animation_Speed)
			Neck.C0 = Clerp(Neck.C0, NECKC0 * CF(0, 0, 0) * ANGLES(RAD(15), RAD(0), RAD(0)), 1 / Animation_Speed)
			RightShoulder.C0 = Clerp(RightShoulder.C0, CF(1.5, 0.5, 0) * ANGLES(RAD(35 - 4 * COS(SINE / 6)), RAD(0), RAD(45 + 10 * COS(SINE / 12))) * RIGHTSHOULDERC0, 1 / Animation_Speed)
			LeftShoulder.C0 = Clerp(LeftShoulder.C0, CF(-1.5, 0.5, 0) * ANGLES(RAD(35 - 4 * COS(SINE / 6)), RAD(0), RAD(-45 - 10 * COS(SINE / 12))) * LEFTSHOULDERC0, 1 / Animation_Speed)
			RightHip.C0 = Clerp(RightHip.C0, CF(1, -0.3, -0.7) * ANGLES(RAD(-25 + 5 * SIN(SINE / 12)), RAD(90), RAD(0)) * ANGLES(RAD(-1 * SIN(SINE / 6)), RAD(0), RAD(0)), 1 / Animation_Speed)
			LeftHip.C0 = Clerp(LeftHip.C0, CF(-1, -0.8, -0.3) * ANGLES(RAD(-10), RAD(-80), RAD(0)) * ANGLES(RAD(-1 * SIN(SINE / 6)), RAD(0), RAD(0)), 1 / Animation_Speed)
		end
	elseif TORSOVELOCITY < 1 and HITFLOOR ~= nil then
		ANIM = "Idle"
		if ATTACK == false then
			RootJoint2.C0 = Clerp(RootJoint2.C0, ROOTC0 * CF(0, 0, 0.25 * COS(SINE / 12)) * ANGLES(RAD(-5 + 2 * SIN(SINE / 12)), RAD(15), RAD(35)), 0.5 / Animation_Speed)
			Neck2.C0 = Clerp(Neck2.C0, NECKC0 * CF(0, 0, 0 + (1 * SIZE - 1)) * ANGLES(RAD(25 - 2 * SIN(SINE / 12)), RAD(0), RAD(-35)), 0.5 / Animation_Speed)
			RightShoulder2.C0 = Clerp(RightShoulder2.C0, CF(1.5 * SIZE, 0.5 * SIZE, 0) * ANGLES(RAD(-35 + 15 * SIN(SINE / 12)), RAD(0), RAD(60)) * RIGHTSHOULDERC0, 0.5 / Animation_Speed)
			LeftShoulder2.C0 = Clerp(LeftShoulder2.C0, CF(-1.5 * SIZE, 0.5 * SIZE, 0) * ANGLES(RAD(-35 + 15 * SIN(SINE / 12)), RAD(0), RAD(-60)) * LEFTSHOULDERC0, 0.5 / Animation_Speed)
			RightHip2.C0 = Clerp(RightHip2.C0, CF(1 * SIZE, -1 * SIZE, 0) * ANGLES(RAD(0), RAD(80 - 1 * SIN(SINE / 6)), RAD(0)) * ANGLES(RAD(-3 * SIN(SINE / 12)), RAD(0), RAD(0)), 0.5 / Animation_Speed)
			LeftHip2.C0 = Clerp(LeftHip2.C0, CF(-1 * SIZE, -0.3 * SIZE, -0.6 * SIZE) * ANGLES(RAD(-25), RAD(-80 + 1 * SIN(SINE / 6)), RAD(0)) * ANGLES(RAD(-3 * SIN(SINE / 12)), RAD(0), RAD(0)), 0.5 / Animation_Speed)
			RootJoint.C0 = Clerp(RootJoint.C0, ROOTC0 * CF(0, 0, 0 + 0.05 * COS(SINE / 12)) * ANGLES(RAD(0), RAD(0), RAD(-15)), 1 / Animation_Speed)
			Neck.C0 = Clerp(Neck.C0, NECKC0 * CF(0, 0, 0) * ANGLES(RAD(0 - 2.5 * SIN(SINE / 12)), RAD(0), RAD(15)), 1 / Animation_Speed)
			RightShoulder.C0 = Clerp(RightShoulder.C0, CF(1.5, 0.5 + 0.05 * SIN(SINE / 12), 0) * ANGLES(RAD(0), RAD(0), RAD(3)) * RIGHTSHOULDERC0, 1 / Animation_Speed)
			LeftShoulder.C0 = Clerp(LeftShoulder.C0, CF(-1.35, 0.5, 0.2) * ANGLES(RAD(-25), RAD(0), RAD(45)) * LEFTSHOULDERC0, 1 / Animation_Speed)
			RightHip.C0 = Clerp(RightHip.C0, CF(1.1, -1 - 0.05 * COS(SINE / 12), -0.2) * ANGLES(RAD(0), RAD(100), RAD(0)) * ANGLES(RAD(0), RAD(0), RAD(0)), 1 / Animation_Speed)
			LeftHip.C0 = Clerp(LeftHip.C0, CF(-1, -1 - 0.05 * COS(SINE / 12), 0) * ANGLES(RAD(0), RAD(-70), RAD(0)) * ANGLES(RAD(0), RAD(-2), RAD(0)), 1 / Animation_Speed)
		end
	elseif TORSOVELOCITY > 1 and HITFLOOR ~= nil then
		ANIM = "Walk"
		if ATTACK == false then
			RootJoint2.C0 = Clerp(RootJoint2.C0, ROOTC0 * CF(0, 0, 0.25 * COS(SINE / 12)) * ANGLES(RAD(35 + 2 * SIN(SINE / 12)), RAD(0), RAD(35)), 0.5 / Animation_Speed)
			Neck2.C0 = Clerp(Neck2.C0, NECKC0 * CF(0, 0, 0 + (1 * SIZE - 1)) * ANGLES(RAD(-25 - 2 * SIN(SINE / 12)), RAD(0), RAD(-35)), 0.5 / Animation_Speed)
			RightShoulder2.C0 = Clerp(RightShoulder2.C0, CF(1.5 * SIZE, 0.5 * SIZE, 0) * ANGLES(RAD(-35 + 15 * SIN(SINE / 12)), RAD(0), RAD(60)) * RIGHTSHOULDERC0, 0.5 / Animation_Speed)
			LeftShoulder2.C0 = Clerp(LeftShoulder2.C0, CF(-1.5 * SIZE, 0.5 * SIZE, 0) * ANGLES(RAD(-35 + 15 * SIN(SINE / 12)), RAD(0), RAD(-60)) * LEFTSHOULDERC0, 0.5 / Animation_Speed)
			RightHip2.C0 = Clerp(RightHip2.C0, CF(1 * SIZE, -1 * SIZE, 0) * ANGLES(RAD(0), RAD(80 - 1 * SIN(SINE / 6)), RAD(0)) * ANGLES(RAD(-3 * SIN(SINE / 12)), RAD(0), RAD(0)), 0.5 / Animation_Speed)
			LeftHip2.C0 = Clerp(LeftHip2.C0, CF(-1 * SIZE, -0.5 * SIZE, -0.3 * SIZE) * ANGLES(RAD(-25), RAD(-80 + 1 * SIN(SINE / 6)), RAD(0)) * ANGLES(RAD(-3 * SIN(SINE / 12)), RAD(0), RAD(0)), 0.5 / Animation_Speed)
			RootJoint.C0 = Clerp(RootJoint.C0, ROOTC0 * CF(0, 0, -0.05) * ANGLES(RAD(5), RAD(0), RAD(0)), 1 / Animation_Speed)
			Neck.C0 = Clerp(Neck.C0, NECKC0 * CF(0, 0, 0) * ANGLES(RAD(5 - 1 * SIN(SINE / (WALKSPEEDVALUE / 2))), RAD(0), RAD(0)), 1 / Animation_Speed)
			RightShoulder.C0 = Clerp(RightShoulder.C0, CF(1.5, 0.5, 0) * ANGLES(RAD(30 * COS(SINE / WALKSPEEDVALUE)), RAD(0), RAD(5)) * RIGHTSHOULDERC0, 1 / Animation_Speed)
			LeftShoulder.C0 = Clerp(LeftShoulder.C0, CF(-1.5, 0.5, 0) * ANGLES(RAD(-30 * COS(SINE / WALKSPEEDVALUE)), RAD(0), RAD(-5)) * LEFTSHOULDERC0, 1 / Animation_Speed)
			RightHip.C0 = Clerp(RightHip.C0, CF(1, -1, 0) * ANGLES(RAD(0), RAD(90), RAD(0)) * ANGLES(RAD(0), RAD(0), RAD(-15)), 2 / Animation_Speed)
			LeftHip.C0 = Clerp(LeftHip.C0, CF(-1, -1, 0) * ANGLES(RAD(0), RAD(-90), RAD(0)) * ANGLES(RAD(0), RAD(0), RAD(15)), 2 / Animation_Speed)
		end
	end
	if ATTACK == false then
		RootPart2.CFrame = Clerp(RootPart2.CFrame, TF(0, 6, 5), 0.1)
	end
	if Rooted == false then
		Disable_Jump = false
		Humanoid.WalkSpeed = Speed
	elseif Rooted == true then
		Disable_Jump = true
		Humanoid.WalkSpeed = 0
	end
	if EQUIPPED == false then
		Intro()
	end
end
local function mainLoop()
	while C.alive do
		Swait()
		local ok, e = pcall(mainStep)
		if not ok then
			C.err(e)
			if EQUIPPED == false then
				EQUIPPED = true
			end
			resetState()
		end
	end
end

C.snapshot = function()
	for i = 1, #JL do
		local j = JL[i]
		j.pC0, j.pC1 = j.C0, j.C1
	end
	T.pR2 = T.R2
	if RP.has then
		RP.pcf = RP.cf
	end
	local root = fd.cframes[C.Root] or IDENT
	local rpos = root.Position
	if MV.last and not RP.has then
		local v = (rpos - MV.last) * 60
		if v.Magnitude > 300 then
			v = VT(0, 0, 0)
		end
		MV.v = MV.v + (v - MV.v) * 0.3
	else
		MV.v = MV.v * 0.5
	end
	MV.last = rpos
	if YAW.last then
		local _, ry = YAW.last:ToObjectSpace(root):ToEulerAnglesYXZ()
		YAW.rate += (CLAMP(ry * 60, -20, 20) - YAW.rate) * 0.3
	end
	YAW.last = root.Rotation
end
local last = {}
C.tick = function()
	SINE += CHANGE
	local want = wantedSet()
	if want ~= TS.set then
		TS.set = want
		TS.goal = SET[want]
		if os.clock() - T0 < 15 then
			TS.k = TS.goal
			applyTitanSize()
		end
		syncSizeUi()
	end
	if TS.k ~= TS.goal then
		TS.k += (TS.goal - TS.k) * 0.09
		if math.abs(TS.goal - TS.k) < 1e-3 * math.max(1, TS.goal) then
			TS.k = TS.goal
		end
		applyTitanSize()
	end
	local ws = HS.walk
	if ws ~= last.ws then
		last.ws = ws
		pcall(fd.setWalkSpeed, ws)
	end
	local jp = Disable_Jump and 0 or 50
	if jp ~= last.jp then
		last.jp = jp
		pcall(fd.setJumpPower, jp)
	end
	local g = UNANCHOR and 196.2 or 0
	if g ~= last.g then
		last.g = g
		pcall(fd.setGravity, g)
	end
end

C.keyDown = function(k)
	if k == "size" then
		C.toggleSize()
		return
	end
	if not SKILLKEY[k] then
		return
	end
	for _, c in ipairs(table.clone(Mouse.KeyDown.list)) do
		if not c.dead then
			task.spawn(c.fn, k)
		end
	end
	local ok, e = pcall(KeyDown, k)
	if not ok then
		C.err(e)
		resetState()
	end
end

local function glueHats(rootInv, P2)
	scanHats()
	for _, h in ipairs(RIG) do
		if hatOk(h) then
			glue(h, C.Root, rootInv * (P2[h.key] * hatOffset(h)))
		end
	end
end
local TPr = {}
local HIDECF = CF(0, -4000, 0)
local bulkP, bulkC = {}, {}
local ghostShown = false
local function onFrame(state, a)
	for i = 1, 6 do
		local s, f = simJ[i], fdJ[i]
		if s.pC0 == s.C0 then
			f.C0 = s.C0
		else
			f.C0 = s.pC0:Lerp(s.C0, a)
		end
		if s.pC1 == s.C1 then
			f.C1 = s.C1
		else
			f.C1 = s.pC1:Lerp(s.C1, a)
		end
	end
	if RP.has then
		local cf
		if UNANCHOR == false then
			cf = RP.pcf == RP.cf and RP.cf or RP.pcf:Lerp(RP.cf, a)
		else
			cf = RP.cf
			RP.has = false
		end
		setRootCF(cf)
	end
	local root = C.rootCF()
	local rootInv = root:Inverse()
	local R2 = T.pR2 == T.R2 and T.R2 or T.pR2:Lerp(T.R2, a)
	local P2 = titanPose(R2, a, TPr)
	local okH, eH = pcall(glueHats, rootInv, P2)
	if not okH then
		C.err(eH)
	end
	local n = 0
	table.clear(bulkP)
	table.clear(bulkC)
	if ghostOn then
		local tr = ghostTransparency()
		for _, g in ipairs(GHOST) do
			if g.tr ~= tr then
				g.tr = tr
				g.p.Transparency = tr
			end
			n += 1
			bulkP[n] = g.p
			bulkC[n] = P2[g.key]
		end
		ghostShown = true
	elseif ghostShown then
		ghostShown = false
		for _, g in ipairs(GHOST) do
			g.tr = 1
			g.p.Transparency = 1
		end
	end
	if FACE.on then
		local c0, c1 = jv(RootJoint, a)
		local torso = root * c0 * c1:Inverse()
		c0, c1 = jv(Neck, a)
		local head = torso * c0 * c1:Inverse()
		for i, p in ipairs(FACE.parts) do
			n += 1
			bulkP[n] = p
			bulkC[n] = head * CF(0, 0.45 - (i - 1) / 25, 0)
		end
	end
	if n > 0 and not pcall(workspace.BulkMoveTo, workspace, bulkP, bulkC, Enum.BulkMoveMode.FireCFrameChanged) then
		for k = 1, n do
			bulkP[k].CFrame = bulkC[k]
		end
	end
end

C.start(onFrame)
task.spawn(function()
	local ok, e = pcall(mainLoop)
	if not ok then
		C.err(e)
		resetState()
	end
end)
if IW.Music then
	C.music.SoundId = "rbxassetid://609005478"
	C.music.Looped = true
	C.music.Pitch = 1
	C.music.Volume = IW.MusicVolume or 1.5
	C.music:Play()
end
note("Internal War: Z Punch, E Throw, R Uppercut, T Roar, Y Take On. -size = Titan scale, -stop = stop. The Titan hats line up in the hub's Alignment window")
task.delay(4, function()
	if C.alive then
		local n, u = hatCount()
		if n == 0 then
			note("No Titan hats found. Wear the Void hats or the UGC limb set (LLeg, RArm, RLeg, LArm, Torso)")
		elseif n < 6 and not (u == 5 and n == 5) then
			local left = unplacedHats()
			note("Titan hats found: " .. n .. " of 6" .. (u > 0 and (" (" .. u .. " from the UGC limb set)") or "") .. ". Not placed: " .. (#left > 0 and table.concat(left, ", ", 1, math.min(#left, 6)) or "nothing left on you") .. ". -hats shows everything")
			print("[Internal War] hats\n" .. hatReport())
		end
	end
end)

end)()

end)
if not IW_OK then
	local msg = tostring(IW_ERR)
	warn("[Internal War] failed to load: " .. msg)
	pcall(function()
		if type(_G.IWFD_Stop) == "function" then
			_G.IWFD_Stop(true)
		end
	end)
	hubNotify("Internal War failed to load", string.sub(msg, 1, 220), "error", 40)
	pcall(function()
		if setclipboard then
			setclipboard("Internal War load error: " .. msg)
		end
	end)
end
