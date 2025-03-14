AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")
ENT.CleanupPriority = 2

function ENT:Initialize()

    self:SetColor(Color(0, 0, 255))
    self:SetModel("models/props_combine/combine_light002a.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)

    self:SetSolid(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
    self:SetModelScale(1.5)
    self:SetTrigger(true)
    self:UseTriggerBounds(true, 4)

    self.Removing = false
    self:PhysWake()
	
	--timer.Simple(30, function ()
    --    if self:IsValid() then
    --        self:Remove()
    --    end
    --end)
end
