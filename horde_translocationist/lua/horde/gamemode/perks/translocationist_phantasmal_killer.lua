PERK.PrintName = "Phantasmal Killer"
PERK.Description = "For {1} seconds after teleporting, gain a {2} damage buff."
PERK.Icon = "materials/perks/translocationist/translocationist_phantasmal_killer.png"
PERK.Params = 
{
    [1] = {value = 4, percent = false},
	[2] = {value = 0.50, percent = true}
}

PERK.Hooks = {}

--1 COMPLETED ? 

HORDE:RegisterStatus("Phantasmal_Killer", "materials/perks/translocationist/translocationist_phantasmal_killer.png")