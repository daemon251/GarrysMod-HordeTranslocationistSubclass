PERK.PrintName = "Like Water"
PERK.Description = "Increase weight to {1}. {2} increased swap speed.\nDealing damage increases damage dealt by the next shot of another weapon by {3}."
PERK.Icon = "materials/perks/translocationist/translocationist_like_water.png"
PERK.Params = 
{
    [1] = {value = 20, percent = false},
	[2] = {value = 0.50, percent = true},
	[3] = {value = 0.50, percent = true},
	[4] = {value = 5, percent = false}
	
}

PERK.Hooks = {}

--1 WORKS
--2 WORKS 
--3 WORKS

--icon needed

PERK.Hooks.Horde_OnSetPerk = function(ply, perk)
    if SERVER and perk == "translocationist_like_water" then
        ply:Horde_SetMaxWeight(20)
    end
end

PERK.Hooks.Horde_OnUnsetPerk = function(ply, perk)
    if SERVER and perk == "translocationist_like_water" then
        ply:Horde_SetMaxWeight(HORDE.max_weight)
		for _, wpn in pairs(ply:GetWeapons()) do --copied
            if wpn.ArcCW then
                wpn:RecalcAllBuffs()
            end
        end
    end
end

PERK.Hooks.M_Hook_Mult_DrawTime = function(wpn, data)
    local ply = wpn:GetOwner()
    if IsValid(ply) and ply:IsPlayer() and ply:Horde_GetPerk("translocationist_like_water") then
        data.mult = 1.0 / 1.5
    end
end

PERK.Hooks.M_Hook_Mult_HolsterTime = function(wpn, data)
    local ply = wpn:GetOwner()
    if IsValid(ply) and ply:IsPlayer() and ply:Horde_GetPerk("translocationist_like_water") then
        data.mult = 1.0 / 1.5
    end
end