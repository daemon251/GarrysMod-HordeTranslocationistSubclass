PERK.PrintName = "Translocationist Base"
PERK.Description = [[
COMPLEXITY: HIGH

Teleport to your teleport node if you have it with Shift+E. Create a new one upon teleporting to it. Teleporting deals {1} AOE shock damage.
Teleporting also gives you {2} evasion for {3} second. 
Max health is reduced to 85.
Has access to Sniper Rifles and (planned but not currently) Shotguns. 

{4} increased teleport recharge rate. ({5} base, {6} per level, up to {7}) ]]

--wanted to decrease teleport cd but Horde_SetPerkCooldown only accepts int, too lazy to work around.

-- These are used to fill out the {1}, {2}, {3}, {4} above.
-- Mainly useful for translation, it is optional.

PERK.Params = 
{
	[1] = {value = 250, percent = false},
	[2] = {value = 1, percent = true},
	[3] = {value = 1, percent = false},
	[4] = {percent = true, base = 0.00, level = 0.01, max = 0.25, classname = "Translocationist"},
    [5] = {value = 0.00, percent = true},
    [6] = {value = 0.01, percent = true},
    [7] = {value = 0.25, percent = true},
}

PERK.Hooks = {}

-- This is a required function if you are planning to use bonuses based on levels.
PERK.Hooks.Horde_PrecomputePerkLevelBonus = function (ply)
    if SERVER then
        ply:Horde_SetPerkLevelBonus("translocationist_base", math.min(0.25, 0.01 * ply:Horde_GetLevel("Translocationist")))
    end
end

HORDE:RegisterStatus("Translocationist_Evasion", "materials/status/evasion.png")

-- Apply the passive ability.

ability_radius = 190

PERK.Hooks.Horde_OnSetMaxHealth = function(ply, bonus)
    if (SERVER and ply:Horde_GetPerk("translocationist_base")) then
        bonus.increase = bonus.increase + -0.15
    end
end

local entmeta = FindMetaTable("Entity")
local plymeta = FindMetaTable("Player")

function entmeta:Horde_AddTeleportAura()
    self:Horde_RemoveTeleportAura() 
    local ent = ents.Create("horde_translocationist_aura") 
    ent:SetPos(self:GetPos())
    ent:SetParent(self)
	ent:Horde_SetAuraRadius(ability_radius - 25) --its not properly set in the entity, so. set this lower than the damage radius so that anything in this circle will absolutely be hit.
    ent:Spawn()
    self.Horde_TeleportAura = ent
end

function entmeta:Horde_RemoveTeleportAura()
    if not self:IsValid() then return end
    if self.Horde_TeleportAura and self.Horde_TeleportAura:IsValid() then
        self.Horde_TeleportAura:OnRemove()
        self.Horde_TeleportAura:Remove()
        self.Horde_TeleportAura = nil
    end
end

PERK.Hooks.Horde_OnPlayerDamageTaken = function(ply, dmginfo, bonus)
	if(inTeleport == 1 and ply:Horde_GetPerk("translocationist_base")) then
		bonus.evasion = bonus.evasion + 1.00
	else
		bonus.evasion = bonus.evasion + 0.00
	end
end

phantasmal_killer_active = 0
inTeleport = 0
afterimage_damage_active = 0
justTeleported = 0
rocket = nil

teleportPos = Vector(1000000,0,0) --janky but only you, yes you, you indeed, cares.

PERK.Hooks.Horde_UseActivePerk = function (ply)
    if not ply:Horde_GetPerk("translocationist_base") then return end
	
	if(teleportPos == Vector(1000000,0,0) or not teleportNodeEntity:IsValid()) then --if first time, no effect.
		sound.Play("ambient/energy/zap9.wav", ply:GetPos(), 60, 100) --placeholder
		ply:Horde_SetPerkCooldown(0)
		teleportPos = ply:GetPos()
		
		--teleport node
		
		teleportNodeEntity = ents.Create("horde_translocationist_teleportnode")
		local pos = ply:GetPos()
		local drop_pos = pos --+ dir * 100
		drop_pos.z = pos.z + 15
		teleportNodeEntity:SetPos(drop_pos)
		teleportNodeEntity:SetAngles(Angle(0, 180 + ply:GetAngles().y, 0))
		teleportNodeEntity:SetRenderMode(RENDERMODE_TRANSCOLOR)
		teleportNodeEntity:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
		teleportNodeEntity:Spawn()
		teleportNodeEntity:SetMoveType(MOVETYPE_NONE)
		--teleport node bubble
		local ent = ents.Create("horde_translocationist_aura") 
		ent:SetPos(teleportNodeEntity:GetPos())
		ent:SetParent(teleportNodeEntity)
		ent:Horde_SetAuraRadius(ability_radius - 25) 
		ent:Spawn()
		
		return
	end
	
	local enemyHitCount = 0
	
	tempPos = ply:GetPos()
	if(teleportPos ~= Vector(1000000,0,0)) then
		sound.Play("ambient/machines/teleport4.wav", ply:GetPos(), 150, 100) --init pos sound
		
		local pos = ply:GetPos()
		local drop_pos = pos --+ dir * 100
		drop_pos.z = pos.z + 15
		teleportNodeEntity:SetPos(drop_pos)
		teleportNodeEntity:SetAngles(Angle(0, 180 + ply:GetAngles().y, 0))
		
		--evasion
		local id = ply:SteamID()
		inTeleport = 1
		net.Start("Horde_SyncStatus")
			net.WriteUInt(HORDE.Status_Translocationist_Evasion, 8)
			net.WriteUInt(1, 8)
		net.Send(ply)
		timer.Create("Horde_Teleport_Effect" .. id, 1, 1, function() --time of 1s
		timer.Remove("Horde_Teleport_Effect" .. id)
			if ply:IsValid() then
				inTeleport = 0
				net.Start("Horde_SyncStatus")
					net.WriteUInt(HORDE.Status_Translocationist_Evasion, 8)
					net.WriteUInt(0, 8)
				net.Send(ply)
			end
		end)
		
		--phantas killer
		if(ply:Horde_GetPerk("translocationist_phantasmal_killer")) then
			local id = ply:SteamID()
			phantasmal_killer_active = 1
			net.Start("Horde_SyncStatus")
				net.WriteUInt(HORDE.Status_Phantasmal_Killer, 8)
				net.WriteUInt(1, 3)
			net.Send(ply)
			timer.Create("Horde_Phantasmal_Killer" .. id, 4, 1, function() --time of 4s
			timer.Remove("Horde_Phantasmal_Killer" .. id)
				if ply:IsValid() then
					phantasmal_killer_active = 0
					net.Start("Horde_SyncStatus")
						net.WriteUInt(HORDE.Status_Phantasmal_Killer, 8)
						net.WriteUInt(0, 8)
					net.Send(ply)
				end
			end)
		end
		
		--the meat
		
		local dmginfo = DamageInfo()
		dmginfo:SetAttacker(ply)
		dmginfo:SetInflictor(ply)
		dmginfo:SetDamage(250)
		if ply:Horde_GetPerk("translocationist_telefrag") then
			dmginfo:SetDamage(750) 
		end
		if ply:Horde_GetPerk("translocationist_cunning") then
			for debuff, buildup in pairs(ply.Horde_Debuff_Buildup) do
				ply:Horde_ReduceDebuffBuildup(debuff, buildup)
			end
			local healinfo = HealInfo:New({amount=30, healer=ply}) --copied from chakra code
			HORDE:OnPlayerHeal(ply, healinfo)
		end
		
		dmginfo:SetDamageType(DMG_SHOCK) 
		HORDE:ApplyDamageInRadius(ply:GetPos(), ability_radius, dmginfo, function (ent)
			enemyHitCount = enemyHitCount + 1
		end)
		--afterimage
		if(ply:Horde_GetPerk("translocationist_afterimage")) then --this is mostly specop flare code.
			if(rocket ~= nil) then
				if(rocket:IsValid()) then
					rocket:Remove() --done so only one exists at a time
				end
			end
			rocket = ents.Create("projectile_horde_translocationist_flare")
			local vel = 10
			local ang = ply:EyeAngles()

			local src = ply:GetPos() + Vector(0,0,50) + ply:GetEyeTrace().Normal * 5

			if !rocket:IsValid() then print("!!! INVALID ROUND " .. rocket) return end

			local rocketAng = Angle(ang.p, ang.y, ang.r)

			rocket:SetAngles(rocketAng)
			rocket:SetPos(src)

			rocket:SetOwner(ply)
			rocket.Owner = ply
			rocket.Inflictor = rocket

			local RealVelocity = ang:Forward() * vel / 0.0254
			rocket.CurVel = RealVelocity -- for non-physical projectiles that move themselves

			rocket:Spawn()
			rocket:Activate()
			if !rocket.NoPhys and rocket:GetPhysicsObject():IsValid() then
				rocket:SetCollisionGroup(rocket.CollisionGroup or COLLISION_GROUP_DEBRIS)
				rocket:GetPhysicsObject():SetVelocityInstantaneous(RealVelocity)
			end

			if rocket.Launch and rocket.SetState then
				rocket:SetState(1)
				rocket:Launch()
			end
			
			afterimage_damage_active = 1
			timer.Create("Horde_Afterimage_Damage" .. id, 5, 1, function() --time of 5s
			timer.Remove("Horde_Afterimage_Damage" .. id)
				if ply:IsValid() then
					afterimage_damage_active = 0
				end
			end)
		end
		
		--if(ply:Horde_GetPerk("translocationist_afterimage")) then --has timer on it, dont want
		--	local id = ply:SteamID()
		--	net.Start("Horde_SyncStatus")
		--		net.WriteUInt(HORDE.Status_Flare, 8)
		--		net.WriteUInt(1, 3)
		--	net.Send(ply)
		--	timer.Create("Horde_Afterimage_Status" .. id, 5, 1, function() --time of 5s
		--	timer.Remove("Horde_Afterimage_Status" .. id)
		--		if ply:IsValid() then
		--			net.Start("Horde_SyncStatus")
		--				net.WriteUInt(HORDE.Status_Flare, 8)
		--				net.WriteUInt(0, 8)
		--			net.Send(ply)
		--		end
		--	end)
		--end
		
		--now teleport
		
		ply:SetPos(teleportPos)
		
		HORDE:ApplyDamageInRadius(ply:GetPos(), ability_radius, dmginfo, function (ent) --we do damage at both the start and end point or else it would be lame.
			--HORDE:SelfHeal(ply, 0) --remove
			enemyHitCount = enemyHitCount + 1
		end)
		
		sound.Play("ambient/energy/zap9.wav", ply:GetPos(), 60, 100)--exit pos sound
		
		dmginfo:SetDamage(4000)
		HORDE:ApplyDamageInRadius(ply:GetPos(), 25, dmginfo, function (ent) --applies 4000 damage to enemies very close to the node, should prevent getting stuck on most enemies
				--print("a")
		end)
		
		--vPoint = teleportPos + Vector(0,0,30)
		--effectdata = EffectData()
		--vecNormal = Vector(0,0,1)
		--effectdata:SetOrigin( vPoint )
		--util.Effect("cball_explode", effectdata, true, true)
		--util.Effect("ElectricSpark", effectdata, true, true, vPoint, 1000, 10, vecNormal)
	end
	teleportPos = tempPos
	
	if(ply:Horde_GetPerk("translocationist_juggernaut")) then
		weapon1 = ply:GetActiveWeapon()
		if(weapon1:Clip1() < weapon1:GetMaxClip1()) then
			weapon1:SetClip1(0.20 * enemyHitCount * weapon1:GetMaxClip1() + weapon1:Clip1())
			if(weapon1:Clip1() > weapon1:GetMaxClip1()) then
				weapon1:SetClip1(weapon1:GetMaxClip1())
			end
		end
		if(weapon1:Clip2() < weapon1:GetMaxClip2()) then
			weapon1:SetClip2(0.20 * enemyHitCount * weapon1:GetMaxClip2() + weapon1:Clip2())
			if(weapon1:Clip2() > weapon1:GetMaxClip2()) then
				weapon1:SetClip2(weapon1:GetMaxClip2())
			end
		end
		
		ply:SetArmor(enemyHitCount * 4 + ply:Armor())
		if(ply:Armor() > ply:GetMaxArmor()) then
			ply:SetArmor(ply:GetMaxArmor())
		end
	end
	
	teleportCooldown = 10
	if(ply:Horde_GetPerk("translocationist_calculated")) then
		teleportCooldown = 8
	end
	if(ply:Horde_GetPerk("translocationist_chain_lightning")) then 
		teleportCooldown = teleportCooldown - 0.6 * enemyHitCount
		if(teleportCooldown < 2.5) then
			teleportCooldown = 2.5
		end
	end
	ply:Horde_SetPerkCooldown(math.ceil(teleportCooldown / (1.0 + ply:Horde_GetLevel("Translocationist") * 0.01))) --I dont think this does decimals properly. 
	ply:Horde_SetPerkInternalCooldown(0)
    net.Start("Horde_SyncActivePerk")
    net.WriteUInt(HORDE.Status_Displacer, 8)
    net.WriteUInt(1, 3)
    net.Send(ply)
	
	justTeleported = 1
	
	local times = 0
	local id = ply:SteamID()
	
	--cant update the text on the cooldown I think while its inactive or smth
	--[[timer.Create("Horde_Teleport_Cooldown" .. id, 1.0 / (1.0 + ply:Horde_GetLevel("Translocationist") * 0.01), teleportCooldown, function() --time of 1 / (1 + ply:Horde_GetLevel("Translocationist") * 0.01) teleportCooldown times.
		if(times < teleportCooldown) then
			times = times + 1
			--ply:Horde_SetPerkCooldown(teleportCooldown - times)
			--ply:Horde_SetPerkInternalCooldown(teleportCooldown - times)
			--net.Start("Horde_SyncActivePerk")
			--net.WriteUInt(HORDE.Status_Displacer, 8)
			--net.WriteUInt(1, 3)
			--net.Send(ply)
		end
		if(times >= teleportCooldown) then --umm not sure why an else here doesnt work... but it doesnt
			ply:Horde_SetPerkCooldown(0)
			ply:Horde_SetPerkInternalCooldown(0)
			net.Start("Horde_SyncActivePerk")
			net.WriteUInt(HORDE.Status_Displacer, 8)
			net.WriteUInt(1, 3)
			net.Send(ply)
			times = 0
			timer.Remove("Horde_Teleport_Cooldown" .. id)
		end
	end)--]]
	timer.Create("Horde_Teleport_Cooldown" .. id, teleportCooldown / (1.0 + ply:Horde_GetLevel("Translocationist") * 0.01), 1, function() --time of 1 / (1 + ply:Horde_GetLevel("Translocationist") * 0.01) teleportCooldown times.
		ply:Horde_SetPerkCooldown(0)
		ply:Horde_SetPerkInternalCooldown(0)
		net.Start("Horde_SyncActivePerk")
		net.WriteUInt(HORDE.Status_Displacer, 8)
		net.WriteUInt(1, 3)
		net.Send(ply)
		times = 0
		timer.Remove("Horde_Teleport_Cooldown" .. id)
	end)
end
	
PERK.Hooks.Horde_OnSetPerk = function(ply, perk)
    if SERVER and perk == "translocationist_base" then
        if(perk == "translocationist_calculated") then
			ply:Horde_SetPerkCooldown(8)
		else
			ply:Horde_SetPerkCooldown(10)
		end
        ply:Horde_SetPerkInternalCooldown(0)
        net.Start("Horde_SyncActivePerk")
        net.WriteUInt(HORDE.Status_Displacer, 8)
        net.WriteUInt(1, 3)
        net.Send(ply)
		
		ply:Horde_AddTeleportAura()
    end
end

PERK.Hooks.Horde_OnUnsetPerk = function(ply, perk)
    if SERVER and perk == "translocationist_base" then
        net.Start("Horde_SyncActivePerk")
            net.WriteUInt(HORDE.Status_Displacer, 8)
            net.WriteUInt(0, 3)
        net.Send(ply)
		
		ply:Horde_RemoveTeleportAura()
		if (teleportNodeEntity ~= nil) then 
			if (teleportNodeEntity:IsValid()) then 
				teleportNodeEntity:Remove() 
			end
		end
    end
end

PERK.Hooks.Horde_OnPlayerDamage = function (ply, npc, bonus, hitgroup, dmginfo)
	if(HORDE:IsLightningDamage(dmginfo) and justTeleported and ply:Horde_GetPerk("translocationist_base")) then 
		npc:Horde_AddDebuffBuildup(HORDE.Status_Shock, 1.4 * dmginfo:GetDamage(), ply, dmginfo:GetDamagePosition()) --equivalent to 12 AR2 balls on base damage
		return --so that afterimage and phant kill doesnt buff the damage
	end
	
	if ply:Horde_GetPerk("translocationist_like_water") then
		local id = ply:SteamID()
		if(weaponName ~= ply:GetActiveWeapon():GetPrintName() and HORDE:IsBallisticDamage(dmginfo)) then
			bonus.more = bonus.more * 1.50
		else 
			bonus.more = bonus.more 
		end
		weaponName = ply:GetActiveWeapon():GetPrintName()
	end

	if(teleportNodeEntity ~= nil) then -- idk if this works in mp... if teleportNodeEntity is defined for everyone, and it should, then this should work.
		if(teleportNodeEntity:IsValid()) then
			pos1 = dmginfo:GetDamagePosition()
			pos2 = teleportNodeEntity:GetPos()
			if (afterimage_damage_active == 1 and pos1:DistToSqr(pos2) < ability_radius * ability_radius) then
				bonus.more = bonus.more * 1.25
			end
		end
	end

	if not ply:Horde_GetPerk("translocationist_base") then return end
	
    if(ply:Horde_GetPerk("translocationist_phantasmal_killer") and phantasmal_killer_active == 1) 
	then bonus.more = bonus.more * 1.50 end
	
	--if(ply:Horde_GetPerk("translocationist_afterimage") and teleportNodeEntity ~= nil) then
	--	if(teleportNodeEntity:IsValid()) then
	--		pos1 = dmginfo:GetDamagePosition()
	--		pos2 = teleportNodeEntity:GetPos()
	--		if (afterimage_damage_active == 1 and pos1:DistToSqr(pos2) < ability_radius * ability_radius) then
	--			bonus.more = bonus.more * 1.25
	--		end
	--	end
	--end
end

