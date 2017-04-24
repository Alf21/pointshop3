if SERVER then AddCSLuaFile() include "pointshop3/sv_init.lua" end
if CLIENT then include "pointshop3/cl_init.lua" end

PS:Initialize()