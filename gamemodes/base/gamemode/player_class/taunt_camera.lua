AddCSLuaFile()
local cl_taunt_headcam = CreateClientConVar("cl_taunt_headcam", "1", true, false, "Makes player's head the center of the screen.", 0, 1)
local LookupBone, GetBonePosition
do
	local _obj_0 = FindMetaTable("Entity")
	LookupBone, GetBonePosition = _obj_0.LookupBone, _obj_0.GetBonePosition
end
local Alive, GetViewEntity
do
	local _obj_0 = FindMetaTable("Player")
	Alive, GetViewEntity = _obj_0.Alive, _obj_0.GetViewEntity
end
local FrameTime = FrameTime
local viewAngles = nil
local eyeAngles = nil
local distance = nil
local CAM = { }
local traceResult = { }
local trace = {
	mins = Vector(-8, -8, -8),
	maxs = Vector(8, 8, 8),
	output = traceResult,
	mask = MASK_SHOT,
	filter = function(entity)
		return entity.m_bIsPlayingTaunt ~= true
	end
}
do
	local LerpVector = LerpVector
	local LerpAngle = LerpAngle
	local fraction = 0
	CAM.ShouldDrawLocalPlayer = function(self, ply, on)
		if not Alive(ply) or GetViewEntity(ply) ~= ply or on or fraction > 0 then
			return true
		end
	end
	CAM.CalcView = function(self, view, ply, on)
		if not ((on or fraction > 0) and Alive(ply) and GetViewEntity(ply) == ply) then
			if eyeAngles ~= nil then
				eyeAngles = nil
			end
			if viewAngles ~= nil then
				viewAngles = nil
			end
			if distance ~= nil then
				distance = nil
			end
			return
		end
		if not viewAngles then
			viewAngles = Angle(view.angles)
			viewAngles[1], viewAngles[3] = 0, 0
		end
		if not distance then
			distance = 128
		end
		if cl_taunt_headcam:GetBool() then
			local bone = LookupBone(ply, "ValveBiped.Bip01_Head1")
			if bone and bone >= 0 then
				view.origin = GetBonePosition(ply, bone)
			end
		end
		local targetOrigin = nil
		if traceResult.HitPos then
			targetOrigin = traceResult.HitPos + traceResult.HitNormal
		else
			targetOrigin = view.origin
		end
		if not eyeAngles then
			eyeAngles = Angle(viewAngles)
		end
		if on then
			if fraction < 1 then
				fraction = fraction + (FrameTime() * 4)
				view.origin = LerpVector(fraction, view.origin, targetOrigin)
				view.angles = LerpAngle(fraction, eyeAngles, viewAngles)
				return view
			end
		elseif fraction > 0 then
			fraction = fraction - (FrameTime() * 2)
			view.origin = LerpVector(fraction, view.origin, targetOrigin)
			view.angles = LerpAngle(fraction, eyeAngles, viewAngles)
			return view
		end
		view.origin = targetOrigin
		view.angles = viewAngles
		return view
	end
end
do
	local SetViewAngles, GetMouseX, GetMouseY, GetMouseWheel
	do
		local _obj_0 = FindMetaTable("CUserCmd")
		SetViewAngles, GetMouseX, GetMouseY, GetMouseWheel = _obj_0.SetViewAngles, _obj_0.GetMouseX, _obj_0.GetMouseY, _obj_0.GetMouseWheel
	end
	local Forward = FindMetaTable("Angle").Forward
	local TraceHull = util.TraceHull
	local Clamp = math.Clamp
	local frameTime = 0
	CAM.CreateMove = function(self, cmd, ply, on)
		if not (on and Alive(ply) and GetViewEntity(ply) == ply) then
			return
		end
		if viewAngles then
			frameTime = FrameTime()
			local _update_0 = 1
			viewAngles[_update_0] = viewAngles[_update_0] + (GetMouseY(cmd) * frameTime)
			local _update_1 = 2
			viewAngles[_update_1] = viewAngles[_update_1] - (GetMouseX(cmd) * frameTime)
		end
		if distance then
			distance = Clamp(distance - GetMouseWheel(cmd) * (distance * 0.1), 16, 1024)
		end
		if viewAngles and distance then
			if cl_taunt_headcam:GetBool() then
				local bone = LookupBone(ply, "ValveBiped.Bip01_Head1")
				if bone and bone >= 0 then
					trace.start = GetBonePosition(ply, bone)
				else
					trace.start = ply:EyePos()
				end
			else
				trace.start = ply:EyePos()
			end
			trace.endpos = trace.start - Forward(viewAngles) * distance
			TraceHull(trace)
		end
		if eyeAngles then
			SetViewAngles(cmd, eyeAngles)
			return
		end
	end
end
TauntCamera = function()
	return CAM
end
