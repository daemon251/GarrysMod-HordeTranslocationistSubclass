SUBCLASS.PrintName = "Translocationist" -- Required
SUBCLASS.UnlockCost = 100 -- How many skull tokens are required to unlock this class
SUBCLASS.ParentClass = HORDE.Class_Ghost -- Required for any new classes
SUBCLASS.Icon = "subclasses/translocationist.png" -- Required, Subclass Icon
SUBCLASS.Description = [[
Translocationist subclass.
Teleports and deals high burst damage.]] -- Required
SUBCLASS.BasePerk = "translocationist_base"
SUBCLASS.Perks = 
{
    [1] = {title = "Technology", choices = {"translocationist_cunning", "translocationist_telefrag"}},
    [2] = {title = "Tactics", choices = {"translocationist_afterimage", "translocationist_juggernaut"}},
    [3] = {title = "Focus", choices = {"translocationist_like_water", "translocationist_calculated"}},
    [4] = {title = "Efficency", choices = {"translocationist_phantasmal_killer", "translocationist_chain_lightning"}} --feedback loop instead?
} -- Required