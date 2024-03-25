local PLAYER, ENTITY = FindMetaTable("Player"), FindMetaTable("Entity")
local sub, lower, find, match, Trim
do
	local _obj_0 = string
	sub, lower, find, match, Trim = _obj_0.sub, _obj_0.lower, _obj_0.find, _obj_0.match, _obj_0.Trim
end
local LookupBone, GetBonePosition = ENTITY.LookupBone, ENTITY.GetBonePosition
local RunConsoleCommand = RunConsoleCommand
local tonumber = tonumber
local isnumber = isnumber
local isvector = isvector
local isangle = isangle
local istable = istable
local CurTime = CurTime
local CLIENT = CLIENT
local SERVER = SERVER
local Exists = file.Exists
local bor = bit.bor
if Exists("ulib/shared/hook.lua", "LUA") then
	include("ulib/shared/hook.lua")
end
local PRE_HOOK = PRE_HOOK or HOOK_MONITOR_HIGH
local addonName = "Unknown Taunts"
local lib = uTaunt
if not istable(lib) then
	lib = {
		Name = addonName
	}
	uTaunt = lib
end
local webSounds = list.GetForEdit("uTaunt - WebSounds", false)
local coopDances = list.GetForEdit("uTaunt - Coop", false)
timer.Simple(0.5, function()
	for sequenceName, value in pairs(coopDances) do
		if not isnumber(value) or value < 1 then
			goto _continue_0
		end
		local name, danceID = match(sequenceName, "^([%a_]+_?)(%d+)$")
		if name == nil or danceID == nil then
			goto _continue_0
		end
		danceID = tonumber(danceID)
		if danceID == nil then
			goto _continue_0
		end
		for index = 1, value do
			coopDances[name .. (danceID + index)] = 0
		end
		::_continue_0::
	end
end)
local IsValid, GetNW2Var, SetNW2Var, LookupSequence, SequenceDuration, GetSequenceList, IsDormant = ENTITY.IsValid, ENTITY.GetNW2Var, ENTITY.SetNW2Var, ENTITY.LookupSequence, ENTITY.SequenceDuration, ENTITY.GetSequenceList, ENTITY.IsDormant
local Add, Run
do
	local _obj_0 = hook
	Add, Run = _obj_0.Add, _obj_0.Run
end
local Alive = PLAYER.Alive
local ACT_GMOD_TAUNT_DANCE = ACT_GMOD_TAUNT_DANCE
local GESTURE_SLOT_CUSTOM = GESTURE_SLOT_CUSTOM
local isPlayingCTaunt = PLAYER.IsPlayingCTaunt
if isPlayingCTaunt == nil then
	isPlayingCTaunt = PLAYER.IsPlayingTaunt
	PLAYER.IsPlayingCTaunt = isPlayingCTaunt
end
lib.GetSequenceName = function(ply)
	return GetNW2Var(ply, "uTaunt-Name", "")
end
local getRenderAngles = nil
do
	local EyeAngles = ENTITY.EyeAngles
	getRenderAngles = function(ply)
		local angles = EyeAngles(ply)
		angles[1], angles[3] = 0, 0
		return GetNW2Var(ply, "uTaunt-Angles", angles)
	end
end
lib.GetRenderAngles = getRenderAngles
local isPlayingTaunt
isPlayingTaunt = function(ply)
	return GetNW2Var(ply, "uTaunt-Name") ~= nil
end
lib.IsPlayingTaunt = isPlayingTaunt
local getStartTime
getStartTime = function(ply)
	return GetNW2Var(ply, "uTaunt-Start") or CurTime()
end
lib.GetStartTime = getStartTime
lib.GetWebSound = function(sequenceName)
	return webSounds[sequenceName]
end
lib.HasWebSound = function(sequenceName)
	return webSounds[sequenceName] ~= nil
end
lib.HasWebSound = hasWebSound
local findSound = nil
do
	local sounds = list.GetForEdit("uTaunt - Sounds", false)
	local supportedExtensions = {
		"mp3",
		"wav",
		"ogg"
	}
	local GetTable = sound.GetTable
	local soundExists
	soundExists = function(sequenceName)
		if Exists("sound/unknown-taunts/" .. sequenceName, "GAME") then
			return true
		end
		return false
	end
	lib.SoundExists = soundExists
	findSound = function(sequenceName)
		if sounds[sequenceName] then
			return sounds[sequenceName]
		end
		for _index_0 = 1, #supportedExtensions do
			local extension = supportedExtensions[_index_0]
			if soundExists(sequenceName .. "." .. extension) then
				return "unknown-taunts/" .. sequenceName .. "." .. extension
			end
		end
		sequenceName = "uTaunt." .. sequenceName
		local _list_0 = GetTable()
		for _index_0 = 1, #_list_0 do
			local soundName = _list_0[_index_0]
			if soundName == sequenceName then
				return soundName
			end
		end
	end
	lib.FindSound = findSound
end
do
	local isPlayingAnyTaunt
	isPlayingAnyTaunt = function(ply)
		return ply.m_bIsPlayingTaunt
	end
	PLAYER.IsPlayingTaunt = isPlayingAnyTaunt
	lib.IsPlayingAnyTaunt = isPlayingAnyTaunt
end
local getCycle = nil
do
	local Clamp = math.Clamp
	getCycle = function(ply, sequenceID, startTime)
		return Clamp((CurTime() - (startTime or getStartTime(ply))) / SequenceDuration(ply, sequenceID), 0, 1)
	end
	lib.GetCycle = getCycle
end
do
	local length, id, duration = 0, 0, 0
	lib.FindSequences = function(entity, pattern)
		local sequences
		sequences, length = { }, 0
		local _list_0 = GetSequenceList(entity)
		for _index_0 = 1, #_list_0 do
			local name = _list_0[_index_0]
			if find(name, pattern, 1, false) == nil then
				goto _continue_0
			end
			id = LookupSequence(entity, name)
			if id < 1 then
				goto _continue_0
			end
			duration = SequenceDuration(entity, id)
			if duration <= 0 then
				goto _continue_0
			end
			length = length + 1
			sequences[length] = {
				id = id,
				name = name,
				duration = duration
			}
			::_continue_0::
		end
		return sequences, length
	end
end
local isValidTauntingPlayer
isValidTauntingPlayer = function(ply)
	return ply and IsValid(ply) and Alive(ply) and isPlayingTaunt(ply)
end
lib.IsValidTauntingPlayer = isValidTauntingPlayer
local utaunt_allow_weapons, utaunt_allow_movement, utaunt_allow_attack = nil, nil, nil
do
	local flags = bor(FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_NOTIFY)
	utaunt_allow_weapons = CreateConVar("utaunt_allow_weapons", "0", flags, "Allow players to hold weapons in their hands while taunting.", 0, 1)
	utaunt_allow_movement = CreateConVar("utaunt_allow_movement", "0", flags, "Allow players to move while taunting.", 0, 1)
	utaunt_allow_attack = CreateConVar("utaunt_allow_attack", "0", flags, "Allow players to attack while taunting.", 0, 1)
	local utaunt_sound_override = CreateConVar("utaunt_sound_override", "", flags, "Overrides the sound of all taunts to the specified one. Leave it blank so it won't be used.")
	Add("UnknownTauntSound", addonName .. "::SoundOverride", function()
		local value = utaunt_sound_override:GetString()
		if #value == 0 then
			return
		end
		if value == "0" then
			return false
		end
		return value
	end)
end
if SERVER then
	resource.AddWorkshop("3161527342")
	local GetInfo = PLAYER.GetInfo
	lib.SetSequenceName = function(ply, sequenceName)
		return SetNW2Var(ply, "uTaunt-Name", sequenceName)
	end
	lib.SetRenderAngles = function(ply, angles)
		return SetNW2Var(ply, "uTaunt-Angles", angles)
	end
	lib.SetCycle = function(ply, cycle, sequenceID)
		if not isnumber(cycle) then
			cycle = 0
		end
		if not isnumber(sequenceID) then
			local sequenceName = GetNW2Var(ply, "uTaunt-Name")
			if sequenceName == nil then
				return false
			end
			sequenceID = LookupSequence(ply, sequenceName)
		end
		if sequenceID < 1 then
			return false
		end
		SetNW2Var(ply, "uTaunt-Start", CurTime() - (cycle * SequenceDuration(ply, sequenceID)))
		return true
	end
	lib.IsAudioEnabled = function(ply)
		return GetInfo(ply, "utaunt_audio") == "1"
	end
	lib.IsCoopEnabled = function(ply)
		return GetInfo(ply, "utaunt_coop") == "1"
	end
	local utaunt_menu_key, utaunt_real_origin, utaunt_coop_distance, utaunt_collisions = nil, nil, nil, nil
	do
		local flags = bor(FCVAR_ARCHIVE, FCVAR_NOTIFY)
		utaunt_menu_key = CreateConVar("utaunt_menu_key", KEY_I, flags, "Default key to open menu of unknown taunts, uses keys from https://wiki.facepunch.com/gmod/Enums/KEY", 0, 512)
		utaunt_real_origin = CreateConVar("utaunt_real_origin", "0", flags, "Uses the player's real position instead of initial position at the end of taunt.", 0, 1)
		utaunt_coop_distance = CreateConVar("utaunt_coop_distance", "512", flags, "Minimum required distance to join in a co-op taunt.", 0, 16384)
		utaunt_collisions = CreateConVar("utaunt_collisions", "0", flags, "Allow players to collide with each other while taunting.", 0, 1)
	end
	local GetModel, SetCollisionGroup = ENTITY.GetModel, ENTITY.SetCollisionGroup
	Add("PlayerInitialSpawn", addonName .. "::CoopData", function(ply)
		ply.m_tUnknownTauntPlayers = { }
	end, PRE_HOOK)
	do
		local sequenceName, sequenceID, curTime, finishTime, timeRemaining = "", 0, 0, 0, 0
		local isbool = isbool
		lib.Finish = function(ply, force)
			sequenceName = GetNW2Var(ply, "uTaunt-Name")
			if sequenceName == nil then
				return false
			end
			curTime, timeRemaining = CurTime(), 0
			finishTime = curTime
			sequenceID = LookupSequence(ply, sequenceName)
			if sequenceID > 0 then
				finishTime = getStartTime(ply) + SequenceDuration(ply, sequenceID)
				timeRemaining = finishTime - curTime
				if timeRemaining < 0 then
					timeRemaining = 0
				end
			end
			if not force and Run("PlayerShouldFinishTaunt", ply, sequenceName, finishTime < curTime, timeRemaining, sequenceID, finishTime) == false then
				return false
			end
			local origin = ply.m_vUnknownTauntOrigin
			if utaunt_real_origin:GetBool() then
				local leftFoot, rightFoot = LookupBone(ply, "ValveBiped.Bip01_L_Foot"), LookupBone(ply, "ValveBiped.Bip01_R_Foot")
				if leftFoot > 0 and rightFoot > 0 then
					origin = (GetBonePosition(ply, leftFoot) + GetBonePosition(ply, rightFoot)) / 2
				else
					origin = GetBonePosition(ply, 0)
				end
			end
			if isvector(origin) then
				ply:SetPos(origin)
			end
			ply.m_vUnknownTauntOrigin = nil
			ply:AnimResetGestureSlot(GESTURE_SLOT_CUSTOM)
			SetNW2Var(ply, "uTaunt-Name", nil)
			ply:CrosshairEnable()
			local angles = GetNW2Var(ply, "uTaunt-Angles")
			if isangle(angles) then
				angles[1], angles[3] = 0, 0
				ply:SetEyeAngles(angles)
			end
			SetNW2Var(ply, "uTaunt-Angles", nil)
			local players = ply.m_tUnknownTauntPlayers
			for index = 1, #players do
				local otherPlayer = players[index]
				players[index] = nil
				if isValidTauntingPlayer(otherPlayer) then
					lib.Finish(otherPlayer, force)
				end
			end
			local collisionGroup = ply.m_iUnknownTauntCollisionGroup
			if isnumber(collisionGroup) then
				SetCollisionGroup(ply, collisionGroup)
			end
			ply.m_iUnknownTauntCollisionGroup = nil
			local avoidPlayers = ply.m_bUnknownTauntAvoidPlayers
			if isbool(avoidPlayers) then
				ply:SetAvoidPlayers(avoidPlayers)
			end
			ply.m_bUnknownTauntAvoidPlayers = nil
			local className = ply.m_sUnknownTauntWeapon
			if isstring(className) then
				ply:SelectWeapon(className)
			end
			ply.m_sUnknownTauntWeapon = nil
			local cSound = ply.m_csUnknownTauntSound
			if cSound and cSound:IsPlaying() then
				cSound:Stop()
			end
			ply.m_csUnknownTauntSound = nil
			Run("PlayerFinishedTaunt", ply, sequenceName, finishTime < curTime, timeRemaining, sequenceID, finishTime)
			return true
		end
	end
	local forcedFinish
	forcedFinish = function(ply)
		lib.Finish(ply, true)
		return
	end
	Add("PlayerDisconnected", addonName .. "::Finish", forcedFinish, PRE_HOOK)
	Add("PostPlayerDeath", addonName .. "::Finish", forcedFinish, PRE_HOOK)
	Add("PlayerSpawn", addonName .. "::Finish", forcedFinish, PRE_HOOK)
	Add("PlayerShouldTaunt", addonName .. "::DefaultTauntBlocking", function(ply, _, isUTaunt)
		if not isUTaunt and isPlayingTaunt(ply) then
			return false
		end
	end)
	lib.Start = function(ply, sequenceName, force, cycle, noSound, startOrigin, startAngles)
		if isPlayingCTaunt(ply) then
			if isPlayingTaunt(ply) then
				forcedFinish(ply)
			end
			return false
		end
		local sequenceID = LookupSequence(ply, sequenceName)
		if sequenceID < 1 then
			return false
		end
		if not force then
			if Run("PlayerShouldUnknownTaunt", ply, sequenceID) ~= true or Run("PlayerShouldTaunt", ply, ACT_GMOD_TAUNT_DANCE, true) == false then
				return false
			end
			if GetInfo(ply, "utaunt_coop") == "1" then
				local maxDistance = utaunt_coop_distance:GetInt()
				if maxDistance > 0 then
					local _list_0 = ents.FindInSphere(ply:GetPos(), maxDistance)
					for _index_0 = 1, #_list_0 do
						local otherPlayer = _list_0[_index_0]
						if not (otherPlayer:IsPlayer() and Alive(otherPlayer)) then
							goto _continue_0
						end
						if otherPlayer == ply or GetNW2Var(otherPlayer, "uTaunt-Name") ~= sequenceName or GetInfo(otherPlayer, "utaunt_coop") ~= "1" then
							goto _continue_0
						end
						if GetBonePosition(otherPlayer, 0):Distance(ply:EyePos()) > maxDistance then
							goto _continue_0
						end
						if Run("PlayerShouldCoopTaunt", ply, otherPlayer, sequenceName) == false then
							goto _continue_0
						end
						if lib.Join(ply, otherPlayer) then
							return true
						end
						::_continue_0::
					end
				end
			end
		end
		local duration = SequenceDuration(ply, sequenceID)
		if duration < 0.25 then
			return false
		end
		if isPlayingTaunt(ply) then
			forcedFinish(ply)
		end
		ply.m_sUnknownTauntModel = GetModel(ply)
		if isvector(startOrigin) then
			ply.m_vUnknownTauntOrigin = ply:GetPos()
			ply:SetPos(startOrigin)
		end
		if not isangle(startAngles) then
			startAngles = getRenderAngles(ply)
		end
		SetNW2Var(ply, "uTaunt-Angles", startAngles)
		if not utaunt_collisions:GetBool() then
			ply.m_iUnknownTauntCollisionGroup = ply:GetCollisionGroup()
			ply.m_bUnknownTauntAvoidPlayers = ply:GetAvoidPlayers()
			ply:SetAvoidPlayers(false)
		end
		if not utaunt_allow_weapons:GetBool() then
			local weapon = ply:GetActiveWeapon()
			if weapon and IsValid(weapon) then
				ply.m_sUnknownTauntWeapon = weapon:GetClass()
				ply:SetActiveWeapon()
			end
		end
		if not cycle then
			cycle = 0
		end
		SetNW2Var(ply, "uTaunt-Start", CurTime() - (cycle * duration))
		SetNW2Var(ply, "uTaunt-Name", sequenceName)
		ply:AddVCDSequenceToGestureSlot(GESTURE_SLOT_CUSTOM, sequenceID, 0, true)
		ply:CrosshairDisable()
		if noSound or not (GetInfo(ply, "utaunt_audio") == "1" or ply:IsBot()) then
			SetNW2Var(ply, "uTaunt-WebAudio", false)
		elseif webSounds[sequenceName] ~= nil then
			SetNW2Var(ply, "uTaunt-WebAudio", true)
		else
			local soundPath = Run("UnknownTauntSound", ply, sequenceName, cycle, duration, sequenceID)
			if soundPath == false then
				SetNW2Var(ply, "uTaunt-WebAudio", false)
			else
				if soundPath == nil or soundPath == true then
					soundPath = findSound(sequenceName)
				end
				if soundPath and find(soundPath, "^https?://.+$") == nil and not Exists(soundPath, "GAME") then
					SetNW2Var(ply, "uTaunt-WebAudio", false)
					local cSound = CreateSound(ply, soundPath)
					ply.m_csUnknownTauntSound = cSound
					cSound:ChangeVolume(0, 0)
					cSound:SetDSP(1)
					cSound:Play()
					cSound:ChangeVolume(1, 1)
				else
					SetNW2Var(ply, "uTaunt-WebAudio", true)
				end
			end
		end
		Run("PlayerStartTaunt", ply, ACT_GMOD_TAUNT_DANCE, duration)
		Run("PlayerStartedUnknownTaunt", ply, sequenceName, duration)
		return true
	end
	lib.Join = function(ply, otherPlayer)
		local sequenceName = GetNW2Var(otherPlayer, "uTaunt-Name")
		if sequenceName == nil then
			return false
		end
		local sequenceID = LookupSequence(ply, sequenceName)
		if sequenceID < 1 then
			return false
		end
		local players = otherPlayer.m_tUnknownTauntPlayers
		if not isnumber(coopDances[sequenceName]) or coopDances[sequenceName] < 1 then
			players[#players + 1] = ply
			return lib.Start(ply, sequenceName, true, getCycle(otherPlayer, sequenceID), true)
		end
		local danceName, danceID = match(sequenceName, "^([%a_]+_?)(%d+)$")
		if danceName == nil or danceID == nil then
			return false
		end
		danceID = tonumber(danceID)
		if danceID == nil then
			return false
		end
		for index = 1, coopDances[sequenceName] do
			if not isValidTauntingPlayer(players[index]) or players[index] == ply then
				players[index] = ply
				return lib.Start(ply, danceName .. (danceID + index), true, getCycle(otherPlayer, sequenceID), true, otherPlayer:GetPos(), getRenderAngles(otherPlayer))
			end
		end
		return false
	end
	do
		local COLLISION_GROUP_PASSABLE_DOOR = COLLISION_GROUP_PASSABLE_DOOR
		local GetCollisionGroup = ENTITY.GetCollisionGroup
		local Crouching = PLAYER.Crouching
		local sequenceID = 0
		Add("PlayerTauntThink", addonName .. "::Thinking", function(ply, isUTaunt)
			if not isUTaunt then
				return
			end
			if not Alive(ply) or Crouching(ply) then
				forcedFinish(ply)
				return
			end
			local sequenceName = GetNW2Var(ply, "uTaunt-Name")
			if sequenceName == nil then
				return
			end
			sequenceID = LookupSequence(ply, sequenceName)
			if sequenceID < 1 then
				forcedFinish(ply)
				return
			end
			if GetModel(ply) ~= ply.m_sUnknownTauntModel then
				forcedFinish(ply)
				return
			end
			local cycle = getCycle(ply, sequenceID)
			if Run("UnknownTauntThink", ply, sequenceName, cycle, sequenceID) == false or cycle == 1 then
				lib.Finish(ply, false)
				return
			end
			if utaunt_collisions:GetBool() then
				return
			end
			if GetCollisionGroup(ply) == COLLISION_GROUP_PASSABLE_DOOR then
				return
			end
			SetCollisionGroup(ply, COLLISION_GROUP_PASSABLE_DOOR)
			return
		end, PRE_HOOK)
	end
	concommand.Add("utaunt", function(ply, _, args)
		if not (ply and IsValid(ply) and Alive(ply)) or isPlayingCTaunt(ply) then
			return
		end
		if isstring(args[1]) then
			lib.Start(ply, args[1], false)
			return
		end
	end)
	concommand.Add("utaunt_stop", function(ply)
		if isPlayingTaunt(ply) then
			return lib.Finish(ply, false)
		end
	end)
	do
		local GetSequenceActivity = ENTITY.GetSequenceActivity
		local acts = {
			[ACT_GMOD_TAUNT_DANCE] = true,
			[ACT_GMOD_TAUNT_ROBOT] = true,
			[ACT_GMOD_TAUNT_CHEER] = true,
			[ACT_GMOD_TAUNT_LAUGH] = true,
			[ACT_GMOD_TAUNT_SALUTE] = true,
			[ACT_GMOD_TAUNT_MUSCLE] = true,
			[ACT_GMOD_TAUNT_PERSISTENCE] = true,
			[ACT_GMOD_GESTURE_BOW] = true,
			[ACT_GMOD_GESTURE_WAVE] = true,
			[ACT_GMOD_GESTURE_AGREE] = true,
			[ACT_GMOD_GESTURE_BECON] = true,
			[ACT_GMOD_GESTURE_DISAGREE] = true,
			[ACT_GMOD_GESTURE_RANGE_ZOMBIE] = true,
			[ACT_GMOD_GESTURE_TAUNT_ZOMBIE] = true,
			[ACT_GMOD_GESTURE_RANGE_ZOMBIE_SPECIAL] = true,
			[ACT_GMOD_GESTURE_ITEM_GIVE] = true,
			[ACT_GMOD_GESTURE_ITEM_DROP] = true,
			[ACT_GMOD_GESTURE_ITEM_PLACE] = true,
			[ACT_GMOD_GESTURE_ITEM_THROW] = true,
			[ACT_SIGNAL_FORWARD] = true,
			[ACT_SIGNAL_GROUP] = true,
			[ACT_SIGNAL_HALT] = true
		}
		Add("PlayerShouldUnknownTaunt", addonName .. "::DefaultSequences", function(ply, sequenceID)
			if acts[GetSequenceActivity(ply, sequenceID)] then
				return true
			end
		end)
	end
	Add("PlayerFinishedTaunt", addonName .. "::TauntLooping", function(ply, sequenceName, isFinished)
		if isFinished and GetInfo(ply, "utaunt_loop") == "1" then
			return lib.Start(ply, sequenceName, false)
		end
	end, PRE_HOOK)
	Add("PlayerButtonDown", addonName .. "::TauntMenu", function(ply, keyCode)
		if keyCode == utaunt_menu_key:GetInt() then
			ply:ConCommand("utaunts " .. keyCode)
			return
		end
	end, PRE_HOOK)
end
Add("PlayerSwitchWeapon", addonName .. "::WeaponSwitch", function(ply)
	if ply.m_bIsPlayingTaunt then
		if utaunt_allow_weapons:GetBool() then
			return
		end
		return true
	end
end)
do
	local Iterator = player.Iterator
	local curTime = 0
	Add("Think", addonName .. "::IsPlayingTaunt", function()
		curTime = CurTime()
		for _, ply in Iterator() do
			if not IsDormant(ply) then
				if isPlayingTaunt(ply) then
					ply.m_dLastPlayingTaunt = curTime
					Run("PlayerTauntThink", ply, true)
				elseif isPlayingCTaunt(ply) then
					ply.m_dLastPlayingTaunt = curTime
					Run("PlayerTauntThink", ply, false)
				end
			end
			if ply.m_dLastPlayingTaunt == nil then
				if ply.m_bIsPlayingTaunt == nil then
					ply.m_bIsPlayingTaunt = false
				end
				goto _continue_0
			end
			if (curTime - ply.m_dLastPlayingTaunt) > 0.1 then
				ply.m_dLastPlayingTaunt = nil
				ply.m_bIsPlayingTaunt = false
				goto _continue_0
			end
			ply.m_bIsPlayingTaunt = true
			do
				return
			end
			::_continue_0::
		end
	end, PRE_HOOK)
end
do
	local SetRenderAngles = PLAYER.SetRenderAngles
	Add("UpdateAnimation", addonName .. "::RenderAngles", function(ply)
		if isPlayingTaunt(ply) then
			SetRenderAngles(ply, getRenderAngles(ply))
			return
		end
	end, PRE_HOOK)
end
do
	local ClearMovement, SetButtons, SetImpulse, KeyDown, RemoveKey
	do
		local _obj_0 = FindMetaTable("CUserCmd")
		ClearMovement, SetButtons, SetImpulse, KeyDown, RemoveKey = _obj_0.ClearMovement, _obj_0.SetButtons, _obj_0.SetImpulse, _obj_0.KeyDown, _obj_0.RemoveKey
	end
	local IN_ATTACK, IN_ATTACK2, IN_DUCK, IN_JUMP = IN_ATTACK, IN_ATTACK2, IN_DUCK, IN_JUMP
	local band = bit.band
	local buttons = 0
	Add("StartCommand", addonName .. "::Movement", function(ply, cmd)
		if not ply.m_bIsPlayingTaunt then
			return
		end
		buttons = Run("TauntStartCommand", ply, cmd, GetNW2Var(ply, "uTaunt-Name", ""))
		if not isnumber(buttons) then
			buttons = 0
		end
		if KeyDown(cmd, IN_JUMP) then
			RemoveKey(cmd, IN_JUMP)
			if isPlayingTaunt(ply) and CLIENT and ply.m_bIsLocalPlayer then
				RunConsoleCommand("utaunt_stop")
			end
		end
		if KeyDown(cmd, IN_DUCK) then
			RemoveKey(cmd, IN_DUCK)
		end
		if not utaunt_allow_movement:GetBool() then
			ClearMovement(cmd)
		end
		if utaunt_allow_attack:GetBool() then
			if KeyDown(cmd, IN_ATTACK) and band(buttons, IN_ATTACK) == 0 then
				buttons = bor(buttons, IN_ATTACK)
			end
			if KeyDown(cmd, IN_ATTACK2) and band(buttons, IN_ATTACK2) == 0 then
				buttons = bor(buttons, IN_ATTACK2)
			end
		end
		SetButtons(cmd, buttons)
		SetImpulse(cmd, 0)
		return
	end, PRE_HOOK)
end
if not CLIENT then
	return
end
CreateClientConVar("utaunt_loop", "0", true, true, "Enables looping for all taunts.", 0, 1)
do
	local utaunt_audio = CreateClientConVar("utaunt_audio", "1", true, true, "Enables audio playback for taunts that support this feature.", 0, 1)
	lib.IsAudioEnabled = function()
		return utaunt_audio:GetBool()
	end
end
do
	local utaunt_coop = CreateClientConVar("utaunt_coop", "1", true, true, "If enabled player will automatically join/synchronize with dance of another player nearby.", 0, 1)
	lib.IsCoopEnabled = function()
		return utaunt_coop:GetBool()
	end
end
local GetPhrase = language.GetPhrase
local getPhrase
getPhrase = function(placeholder)
	local fulltext = GetPhrase(placeholder)
	if fulltext == placeholder and sub(placeholder, 1, 15) == "unknown_taunts." then
		return GetPhrase(sub(placeholder, 16))
	end
	return fulltext
end
lib.GetPhrase = getPhrase
do
	local ply = LocalPlayer()
	local isInTaunt = false
	IsInTaunt = function()
		return isInTaunt
	end
	Add("InitPostEntity", addonName .. "::Initialization", function()
		ply = LocalPlayer()
		ply.m_bIsLocalPlayer = true
		ply.m_bIsPlayingTaunt = false
	end, PRE_HOOK)
	Add("Think", addonName .. "::IsInTaunt", function()
		if ply and IsValid(ply) then
			isInTaunt = ply.m_bIsPlayingTaunt
		end
	end, PRE_HOOK)
	Add("HUDShouldDraw", addonName .. "::WeaponSelector", function(name)
		if isInTaunt and name == "CHudWeaponSelection" and not utaunt_allow_weapons:GetBool() then
			return false
		end
	end)
end
do
	local mins, maxs = Vector(-512, -512, 0), Vector(512, 512, 512)
	local Forward = FindMetaTable("Angle").Forward
	local stopAudio
	stopAudio = function(ply)
		local channel = ply.m_bcUnknownTauntAudio
		if channel and channel:IsValid() then
			channel:Stop()
		end
		ply.m_bcUnknownTauntAudio = nil
	end
	local playStates = {
		[GMOD_CHANNEL_PLAYING] = true,
		[GMOD_CHANNEL_STALLED] = true
	}
	local Remove = hook.Remove
	local boneID = 0
	Add("UnknownTauntSynced", addonName .. "::Sync", function(ply, sequenceName, cycle, sequenceID, webAudio)
		mins[3] = ply:GetModelRenderBounds()[3]
		ply:SetRenderBounds(mins, maxs)
		if not webAudio or IsDormant(ply) then
			stopAudio(ply)
			return
		end
		local filePath = Run("UnknownTauntSound", ply, sequenceName, cycle, SequenceDuration(ply, sequenceID) or 0, sequenceID) or webSounds[sequenceName]
		local channel = ply.m_bcUnknownTauntAudio
		if channel and channel:IsValid() then
			if not filePath then
				ply.m_sUnknownTauntAudioFilePath = nil
				ply.m_bcUnknownTauntAudio = nil
				channel:Stop()
				return
			end
			if filePath == ply.m_sUnknownTauntAudioFilePath then
				local length = channel:GetLength()
				if length > 0 then
					channel:SetTime(length * cycle)
				end
				if not playStates[channel:GetState()] then
					channel:Play()
				end
				return
			end
			ply.m_sUnknownTauntAudioFilePath = nil
			ply.m_bcUnknownTauntAudio = nil
			channel:Stop()
		end
		if not filePath then
			return
		end
		local isURL = find(filePath, "^https?://.+$") ~= nil
		if not (isURL or Exists(filePath, "GAME")) then
			return
		end
		sound[isURL and "PlayURL" or "PlayFile"](filePath, "3d noplay noblock", function(newChannel)
			if not (newChannel and newChannel:IsValid() and isValidTauntingPlayer(ply) and not IsDormant(ply)) then
				return
			end
			ply.m_sUnknownTauntAudioFilePath = filePath
			ply.m_bcUnknownTauntAudio = newChannel
			local length = newChannel:GetLength()
			if length > 0 then
				newChannel:SetTime(length * cycle)
			end
			newChannel:Play()
			Add("Think", newChannel, function()
				if not isValidTauntingPlayer(ply) or IsDormant(ply) then
					Remove("Think", newChannel)
					if IsValid(ply) then
						ply.m_sUnknownTauntAudioFilePath = nil
						ply.m_bcUnknownTauntAudio = nil
					end
					newChannel:Stop()
					return
				end
				boneID = LookupBone(ply, "ValveBiped.Bip01_Head1")
				if boneID and boneID >= 0 then
					newChannel:SetPos(GetBonePosition(ply, boneID), Forward(getRenderAngles(ply)))
					return
				end
				newChannel:SetPos(ply:WorldSpaceCenter(), Forward(getRenderAngles(ply)))
				return
			end)
			return
		end)
		return
	end, PRE_HOOK)
	Add("PlayerFinishedTaunt", addonName .. "::Cleanup", function(ply)
		ply:SetRenderBounds(ply:GetModelRenderBounds())
		stopAudio(ply)
		return
	end, PRE_HOOK)
end
do
	local cycle = 0
	Add("EntityNetworkedVarChanged", addonName .. "::Networking", function(ply, key, oldValue, value)
		if not (IsValid(ply) and ply:IsPlayer() and Alive(ply)) then
			return
		end
		if key == "uTaunt-Name" then
			if value == nil then
				if ply.m_bUsingUnknownTaunt then
					ply.m_bUsingUnknownTaunt = false
					ply:AnimResetGestureSlot(GESTURE_SLOT_CUSTOM)
					Run("PlayerFinishedTaunt", ply, oldValue)
				end
				return
			end
			local sequenceID = LookupSequence(ply, value)
			if sequenceID < 1 then
				return
			end
			ply.m_bUsingUnknownTaunt = true
			cycle = getCycle(ply, sequenceID)
			ply:AddVCDSequenceToGestureSlot(GESTURE_SLOT_CUSTOM, sequenceID, cycle, true)
			Run("UnknownTauntSynced", ply, value, cycle, sequenceID, GetNW2Var(ply, "uTaunt-WebAudio", false))
			return
		end
		if key == "uTaunt-Start" then
			local sequenceName = GetNW2Var(ply, "uTaunt-Name")
			if sequenceName == nil then
				if ply.m_bUsingUnknownTaunt then
					ply.m_bUsingUnknownTaunt = false
					ply:AnimResetGestureSlot(GESTURE_SLOT_CUSTOM)
					Run("PlayerFinishedTaunt", ply, sequenceName)
				end
				return
			end
			local sequenceID = LookupSequence(ply, sequenceName)
			if sequenceID < 1 then
				return
			end
			ply.m_bUsingUnknownTaunt = true
			cycle = getCycle(ply, sequenceID, value)
			ply:AddVCDSequenceToGestureSlot(GESTURE_SLOT_CUSTOM, sequenceID, cycle, true)
			Run("UnknownTauntSynced", ply, sequenceName, cycle, sequenceID, GetNW2Var(ply, "uTaunt-WebAudio", false))
			return
		end
		if key == "uTaunt-WebAudio" then
			local sequenceName = GetNW2Var(ply, "uTaunt-Name")
			if sequenceName == nil then
				if ply.m_bUsingUnknownTaunt then
					ply.m_bUsingUnknownTaunt = false
					ply:AnimResetGestureSlot(GESTURE_SLOT_CUSTOM)
					Run("PlayerFinishedTaunt", ply, sequenceName)
				end
				return
			end
			local sequenceID = LookupSequence(ply, sequenceName)
			if sequenceID < 1 then
				return
			end
			ply.m_bUsingUnknownTaunt = true
			cycle = getCycle(ply, sequenceID)
			ply:AddVCDSequenceToGestureSlot(GESTURE_SLOT_CUSTOM, sequenceID, cycle, true)
			Run("UnknownTauntSynced", ply, sequenceName, cycle, sequenceID, value == true)
			return
		end
	end, PRE_HOOK)
	Add("NotifyShouldTransmit", addonName .. "::PVS", function(ply, shouldtransmit)
		if not (shouldtransmit and IsValid(ply) and ply:IsPlayer() and Alive(ply)) then
			if ply.m_bUsingUnknownTaunt then
				ply.m_bUsingUnknownTaunt = false
				ply:AnimResetGestureSlot(GESTURE_SLOT_CUSTOM)
				Run("PlayerFinishedTaunt", ply, oldValue)
			end
			return
		end
		local sequenceName = GetNW2Var(ply, "uTaunt-Name")
		if sequenceName == nil then
			if ply.m_bUsingUnknownTaunt then
				ply.m_bUsingUnknownTaunt = false
				ply:AnimResetGestureSlot(GESTURE_SLOT_CUSTOM)
				Run("PlayerFinishedTaunt", ply, oldValue)
			end
			return
		end
		local sequenceID = LookupSequence(ply, sequenceName)
		if sequenceID < 1 then
			return
		end
		ply.m_bUsingUnknownTaunt = true
		cycle = getCycle(ply, sequenceID)
		ply:AddVCDSequenceToGestureSlot(GESTURE_SLOT_CUSTOM, sequenceID, cycle, true)
		Run("UnknownTauntSynced", ply, sequenceName, cycle, sequenceID)
		return
	end, PRE_HOOK)
end
local toggleMenu
toggleMenu = function(ply, keyCode)
	if isPlayingCTaunt(ply) then
		return false
	end
	if keyCode ~= nil then
		local bind = input.LookupKeyBinding(keyCode)
		if bind ~= nil and #bind > 0 then
			return false
		end
	end
	local panel = lib.Panel
	if panel and panel:IsValid() then
		panel:Remove()
		return true
	end
	if Run("AllowTauntMenu", ply) == false then
		return false
	end
	panel = vgui.Create("uTaunt::Menu")
	lib.Panel = panel
	panel:Setup(ply)
	return true
end
lib.ToggleMenu = toggleMenu
concommand.Add("utaunts", function(ply, _, args)
	if not ply:Alive() then
		return
	end
	local keyCode = args[1]
	if keyCode ~= nil and #keyCode > 0 then
		keyCode = tonumber(keyCode)
	end
	toggleMenu(ply, keyCode)
	return
end)
do
	local commmands = {
		"taunt",
		"dance",
		"utaunt",
		"udance"
	}
	local allowedChars = {
		["/"] = true,
		["!"] = true
	}
	Add("OnPlayerChat", addonName .. "::ChatCommands", function(ply, text, isTeam, isDead)
		if isDead or isTeam or not ply.m_bIsLocalPlayer then
			return
		end
		text = lower(Trim(text))
		if allowedChars[sub(text, 1, 1)] == nil then
			return
		end
		text = sub(text, 2)
		for _index_0 = 1, #commmands do
			local command = commmands[_index_0]
			if find(text, command, 1, false) ~= nil then
				toggleMenu(ply)
				return true
			end
		end
	end)
end
do
	local format = string.format
	local taunts = {
		"taunt_cheer",
		"taunt_dance",
		"taunt_laugh",
		"taunt_muscle",
		"taunt_robot",
		"taunt_persistence",
		"taunt_zombie"
	}
	local gestures = {
		"gesture_agree",
		"gesture_bow",
		"gesture_becon",
		"gesture_disagree",
		"gesture_salute",
		"gesture_wave",
		"gesture_item_drop",
		"gesture_item_give",
		"gesture_item_place",
		"gesture_item_throw",
		"gesture_signal_forward",
		"gesture_signal_halt",
		"gesture_signal_group"
	}
	local zombie = {
		"zombie_attack_01",
		"zombie_attack_02",
		"zombie_attack_03",
		"zombie_attack_04",
		"zombie_attack_05",
		"zombie_attack_06",
		"zombie_attack_07",
		"zombie_attack_special"
	}
	Add("UnknownTauntMenuSetup", addonName .. "::DefaultSequences", function(ply, add)
		local sequences, sequencesCount = { }, 0
		for _index_0 = 1, #taunts do
			local sequenceName = taunts[_index_0]
			if LookupSequence(ply, sequenceName) < 0 then
				goto _continue_0
			end
			sequencesCount = sequencesCount + 1
			sequences[sequencesCount] = sequenceName
			::_continue_0::
		end
		if sequencesCount > 0 then
			add(format(GetPhrase("unknown_taunts.menu.taunts"), "Garry's Mod"), sequences)
			for index = 1, sequencesCount do
				sequences[index] = nil
			end
			sequencesCount = 0
		end
		for _index_0 = 1, #gestures do
			local sequenceName = gestures[_index_0]
			if LookupSequence(ply, sequenceName) < 0 then
				goto _continue_1
			end
			sequencesCount = sequencesCount + 1
			sequences[sequencesCount] = sequenceName
			::_continue_1::
		end
		if sequencesCount > 0 then
			add(format(GetPhrase("unknown_taunts.menu.gestures"), "Garry's Mod"), sequences)
			for index = 1, sequencesCount do
				sequences[index] = nil
			end
			sequencesCount = 0
		end
		for _index_0 = 1, #zombie do
			local sequenceName = zombie[_index_0]
			if LookupSequence(ply, sequenceName) < 0 then
				goto _continue_2
			end
			sequencesCount = sequencesCount + 1
			sequences[sequencesCount] = sequenceName
			::_continue_2::
		end
		if sequencesCount > 0 then
			add(format(GetPhrase("unknown_taunts.menu.zombie"), "Garry's Mod"), sequences)
		end
		return
	end)
end
do
	local utaunt_menu_auto_close = CreateClientConVar("utaunt_menu_auto_close", "0", true, false, "Automatically close the taunt menu when a taunt is selected.", 0, 1)
	local DrawRect, SetDrawColor
	do
		local _obj_0 = surface
		DrawRect, SetDrawColor = _obj_0.DrawRect, _obj_0.SetDrawColor
	end
	local floor, Round
	do
		local _obj_0 = math
		floor, Round = _obj_0.floor, _obj_0.Round
	end
	local PANEL = { }
	PANEL.Init = function(self)
		self:SetTitle("#unknown_taunts.menu.title")
		self:SetSize(ScreenScale(128), 24)
		self:SetIcon("icon16/user.png")
		self:MakePopup()
		return self:Center()
	end
	PANEL.ClickSound = function()
		return surface.PlaySound("garrysmod/ui_click.wav")
	end
	PANEL.Setup = function(self, ply)
		local scrollPanel = self:Add("DScrollPanel")
		self.ScrollPanel = scrollPanel
		scrollPanel:Dock(FILL)
		scrollPanel.PerformLayout = function(_, width, height)
			local canvas = scrollPanel:GetCanvas()
			if canvas and canvas:IsValid() then
				local margin = ScreenScale(2)
				canvas:DockPadding(margin, 0, margin, margin)
			end
			return DScrollPanel.PerformLayout(scrollPanel, width, height)
		end
		local actions = scrollPanel:Add("EditablePanel")
		actions.Progress = 0
		actions:Dock(TOP)
		actions.PerformLayout = function()
			return actions:SetTall(32)
		end
		actions.Think = function()
			local sequenceName = GetNW2Var(ply, "uTaunt-Name")
			if sequenceName == nil then
				actions.Progress = 0
				return
			end
			local sequenceID = LookupSequence(ply, sequenceName)
			if sequenceID < 1 then
				actions.Progress = 0
				return
			end
			actions.Progress = getCycle(ply, sequenceID)
		end
		actions.Paint = function(_, width, height)
			SetDrawColor(150, 255, 50, 220)
			return DrawRect(0, height - 2, width * actions.Progress, 2)
		end
		do
			local button = actions:Add("DButton")
			button:SetText("")
			button:SetWide(32)
			button:Dock(RIGHT)
			button.Paint = function() end
			button.UpdateIcon = function(state)
				return button:SetImage(state and "icon16/group.png" or "icon16/user.png")
			end
			button.UpdateIcon(cvars.Bool("utaunt_coop"))
			button.DoClick = function()
				if cvars.Bool("utaunt_coop") then
					RunConsoleCommand("utaunt_coop", "0")
					button.UpdateIcon(false)
				else
					RunConsoleCommand("utaunt_coop", "1")
					button.UpdateIcon(true)
				end
				return self:ClickSound()
			end
		end
		do
			local button = actions:Add("DButton")
			button:SetText("")
			button:SetWide(32)
			button:Dock(RIGHT)
			button.Paint = function() end
			button.UpdateIcon = function(state)
				return button:SetImage(state and "icon16/sound.png" or "icon16/sound_mute.png")
			end
			button.UpdateIcon(cvars.Bool("utaunt_audio"))
			button.DoClick = function()
				if cvars.Bool("utaunt_audio") then
					RunConsoleCommand("utaunt_audio", "0")
					button.UpdateIcon(false)
				else
					RunConsoleCommand("utaunt_audio", "1")
					button.UpdateIcon(true)
				end
				return self:ClickSound()
			end
		end
		do
			local button = actions:Add("DButton")
			button:SetText("")
			button:SetWide(32)
			button:Dock(RIGHT)
			button.Paint = function() end
			button.UpdateIcon = function(state)
				return button:SetImage(state and "icon16/control_repeat_blue.png" or "icon16/control_repeat.png")
			end
			button.UpdateIcon(cvars.Bool("utaunt_loop"))
			button.DoClick = function()
				if cvars.Bool("utaunt_loop") then
					RunConsoleCommand("utaunt_loop", "0")
					button.UpdateIcon(false)
				else
					RunConsoleCommand("utaunt_loop", "1")
					button.UpdateIcon(true)
				end
				return self:ClickSound()
			end
		end
		do
			local button = actions:Add("DButton")
			button:SetText("")
			button:SetWide(32)
			button:Dock(RIGHT)
			button.Paint = function() end
			button.Think = function()
				local state = isPlayingTaunt(ply)
				if button.State ~= state then
					button.State = state
					if state then
						return button:SetImage("icon16/control_stop_blue.png")
					else
						return button:SetImage("icon16/control_stop.png")
					end
				end
			end
			button.DoClick = function()
				if isPlayingTaunt(ply) then
					RunConsoleCommand("utaunt_stop")
					return self:ClickSound()
				end
			end
		end
		do
			local label = actions:Add("DLabel")
			label.SequenceName = ""
			label:Dock(FILL)
			label.Think = function()
				if not isPlayingTaunt(ply) then
					if label.SequenceName ~= nil then
						label.SequenceName = nil
						label:SetText("#unknown_taunts.menu.none")
					end
					return
				end
				local sequenceName = GetNW2Var(ply, "uTaunt-Name")
				if sequenceName == nil then
					if label.SequenceName ~= nil then
						label.SequenceName = nil
						label:SetText("#unknown_taunts.menu.none")
					end
					return
				end
				local sequenceID = LookupSequence(ply, sequenceName)
				if sequenceID < 1 then
					if label.SequenceName ~= nil then
						label.SequenceName = nil
						label:SetText("#unknown_taunts.menu.none")
					end
					return
				end
				if label.SequenceName ~= sequenceName then
					label.SequenceName = sequenceName
					label.SequenceTitle = getPhrase("unknown_taunts." .. sequenceName)
				end
				local duration = SequenceDuration(ply, sequenceID)
				local timeRemaining = duration * getCycle(ply, sequenceID)
				if timeRemaining > 60 then
					timeRemaining = Round(timeRemaining / 60, 1) .. "m"
				else
					timeRemaining = floor(timeRemaining) .. "s"
				end
				if duration > 60 then
					duration = Round(duration / 60, 1) .. "m"
				else
					duration = floor(duration) .. "s"
				end
				local str = label.SequenceTitle .. " ( " .. timeRemaining .. " / " .. duration .. " )"
				if str ~= label:GetText() then
					return label:SetText(str)
				end
			end
		end
		return Run("UnknownTauntMenuSetup", ply, function(title, sequences)
			if not istable(sequences) then
				return
			end
			local length = #sequences
			if length == 0 then
				return
			end
			for index = 1, length do
				if Run("AllowUnknownTaunt", ply, sequences[index], title) == false then
					sequences[index] = false
				end
			end
			length = #sequences
			if length == 0 then
				return
			end
			local combo = self[title]
			if not (combo and combo:IsValid()) then
				local label = scrollPanel:Add("DLabel")
				label:SetText(title)
				label:Dock(TOP)
				combo = scrollPanel:Add("DComboBox")
				self[title] = combo
				combo:SetText("#unknown_taunts.menu.select")
				combo:Dock(TOP)
				combo.OnSelect = function(_, __, ___, name)
					RunConsoleCommand("utaunt", name)
					if utaunt_menu_auto_close:GetBool() then
						self:Close()
						return
					end
					return combo:SetText("#unknown_taunts.menu.select")
				end
			end
			for index = 1, length do
				if sequences[index] ~= false then
					combo:AddChoice(getPhrase("unknown_taunts." .. sequences[index]), sequences[index])
				end
			end
		end)
	end
	PANEL.PerformLayout = function(self, width, height)
		local scrollPanel = self.ScrollPanel
		if scrollPanel and scrollPanel:IsValid() then
			height = 0
			local _list_0 = scrollPanel:GetCanvas():GetChildren()
			for _index_0 = 1, #_list_0 do
				local pnl = _list_0[_index_0]
				height = height + pnl:GetTall()
			end
			if height == 0 then
				self:Remove()
				return
			end
			self:SetTall(math.min(height + 48, ScrH() * 0.5))
		end
		return DFrame.PerformLayout(self, width, height)
	end
	PANEL.Paint = function(self, width, height)
		SetDrawColor(50, 50, 50, 220)
		return DrawRect(0, 0, width, height)
	end
	vgui.Register("uTaunt::Menu", PANEL, "DFrame")
end
do
	local HSVToColor = HSVToColor
	local Round = math.Round
	local MsgC = MsgC
	concommand.Add("utaunt_list", function(ply, _, args)
		local modelSequences = GetSequenceList(ply)
		local allowAll = args[1] == "1"
		local sequences, count = { }, 0
		for index = 1, #modelSequences do
			local sequenceName = modelSequences[index]
			if not allowAll and Run("AllowUnknownTaunt", ply, sequenceName, "Sequences") == false then
				goto _continue_0
			end
			local placeholder = "unknown_taunts." .. sequenceName
			local fulltext = GetPhrase(placeholder)
			if not allowAll and fulltext == placeholder then
				goto _continue_0
			end
			count = count + 1
			local duration = SequenceDuration(ply, index)
			if duration > 60 then
				sequences[count] = sequenceName .. " (" .. Round(duration / 60, 1) .. " minutes) - " .. fulltext
				goto _continue_0
			end
			sequences[count] = sequenceName .. " (" .. Round(duration, 2) .. " seconds) - " .. fulltext
			::_continue_0::
		end
		if count == 0 then
			MsgC("No sequences found.\n")
			return
		end
		MsgC("Sequences:\n")
		for index = 1, count do
			MsgC(index .. ". ", HSVToColor((180 + index) % 360, 1, 1), sequences[index], "\n")
		end
	end)
end
return list.Set("DesktopWindows", "utaunt-menu", {
	title = "uTaunt",
	icon = "icon16/color_swatch.png",
	init = function(icon, window)
		if window and window:IsValid() then
			window:Remove()
		end
		icon.DoClick = function()
			return RunConsoleCommand("utaunts")
		end
		return RunConsoleCommand("utaunts")
	end
})
