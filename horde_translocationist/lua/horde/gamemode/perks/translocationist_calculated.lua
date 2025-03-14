PERK.PrintName = "Calculated"
PERK.Description = "Reduce weight to {1}. Gun damage increases stun buildup in enemies.\nDecreases maximum teleporter recharge time by {2}."
PERK.Icon = "materials/perks/translocationist/translocationist_calculated.png"
PERK.Params = 
{
    [1] = {value = 10, percent = false},
	[2] = {value = 0.20, percent = true}
}

PERK.Hooks = {}

--1 WORKS
--2 WORKS
--3 WORKS

PERK.Hooks.Horde_OnSetPerk = function(ply, perk)
    if SERVER and perk == "translocationist_calculated" then
        ply:Horde_SetMaxWeight(10)
    end
end

PERK.Hooks.Horde_OnUnsetPerk = function(ply, perk)
    if SERVER and perk == "translocationist_calculated" then
        ply:Horde_SetMaxWeight(HORDE.max_weight)
    end
end

PERK.Hooks.Horde_OnPlayerDamage = function (ply, npc, bonus, hitgroup, dmginfo)
    if not ply:Horde_GetPerk("translocationist_calculated") then return end
    local dmgtype = dmginfo:GetDamageType()
	npc:Horde_AddDebuffBuildup(HORDE.Status_Stun, dmginfo:GetDamage() / 3, ply, dmginfo:GetDamagePosition())
end