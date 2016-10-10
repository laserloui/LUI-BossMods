require "Window"
require "Apollo"

local LUI_BossMods = Apollo.GetAddon("LUI_BossMods")
local Mod = LUI_BossMods:EncounterPrototype("AileronHydroflux")

Mod:Locales(
    {--[[enUS]] 
        -- Unit names
        ["unit.boss_air"] = "Aileron",
        ["unit.boss_water"] = "Hydroflux",
		
		--casts
		["cast.tsunami"] = "Tsunami",
		["cast.icestorm"] = "Glacial Icestorm",
		
		--labels
		["label.midphase"] = "Midphase",
		["label.tomb"] = "Ice Tomb",
		["label.phase2"] = "Phase 2",
		["label.icestorm"] = "Icestorm",
		["label.twirl"] = "Twirl",
		
		--alerts
		["alert.twirlyou"] = "Twirl on YOU!",
    },
    {--[[deDE]] 
		-- Unit names
        ["unit.boss_air"] = "Aileron",
        ["unit.boss_water"] = "Hydroflux",
		
		--casts
		["cast.tsunami"] = "Tsunami",
		["cast.icestorm"] = "Frostiger Eissturm",
		
		--labels
		["label.midphase"] = "Midphase",
		["label.tomb"] = "Ice Tomb",
		["label.phase2"] = "Phase 2",
		["label.icestorm"] = "Icestorm",
		["label.twirl"] = "Twirl",
		
		--alerts
		["alert.twirlyou"] = "Twirl on YOU!",
	}, 
    {--[[frFR]] 
		-- Unit names
        ["unit.boss_air"] = "Ventemort",
        ["unit.boss_water"] = "Hydroflux",
		
		--casts
		["cast.tsunami"] = "Tsunami",
		["cast.icestorm"] = "Tempête de neige glaciale",
		
		--labels
		["label.midphase"] = "Midphase",
		["label.tomb"] = "Ice Tomb",
		["label.phase2"] = "Phase 2",
		["label.icestorm"] = "Icestorm",
		["label.twirl"] = "Twirl",
		
		--alerts
		["alert.twirlyou"] = "Twirl on YOU!",
	})
	
local nMOOCount = 0
local bIsPhase2 = false

local BUFFID_MOO1 = 69959
local BUFFID_MOO2 = 47075
local DEBUFFID_TWIRL = 70440

function Mod:Setup()
	name("Datascape", "Aileron & Hydroflux", "Elemental Pairs")
	trigger("ALL", {"Aileron","Hydroflux"}, {"Aileron","Hydroflux"}, {"Ventemort","Hydroflux"}, {continentId = 52, parentZoneId = 98, mapId = 118 })
	
	--units
	unit("boss_air", true, 1, "af00ffff", "unit.boss_air")
	unit("boss_water", true, 2, "af1e90ff", "unit.boss_water")
	
	--timers
	timer("timer_midphase", true, nil, "label.midphase")
	timer("timer_tomb", true, "af1e90ff", "label.tomb")
	timer("timer_icestorm", true, nil, "label.icestorm")
	
	--alerts
	alert("alert_phase2", true, nil, nil, "label.phase2")
	alert("alert_icestorm", true, nil, nil, "label.icestorm")
	alert("alert_twirl", true, nil, nil, "alert.twirlyou")
	
	--sounds
	sound("sound_phase2", true, "alert", "label.phase2")
	sound("sound_icestorm", true, "run-away", "label.icestorm")
	sound("sound_twirl", true, "inferno", "alert.twirlyou")

	--icons
	icon("icon_twirl", true, "target", 20, "ffff0000", "label.twirl")
end

function Mod:SetupEvents()
	onUnitCreated("BossCreated_Air", self.L["unit.boss_air"], true)
	onUnitCreated("BossCreated_Water", self.L["unit.boss_water"], true)
	
	onCastStart("CastStart_Tsunami", "unit.boss_water", nil, self.L["cast.tsunami"])
	onCastStart("CastStart_IceStorm", "unit.boss_water", nil, self.L["cast.icestorm"])
	
	onCastEnd("CastEnd_Tsunami", "unit.boss_water", nil, self.L["cast.tsunami"])
	
	onBuffAdded("BuffAdd_Moo", nil, nil, BUFFID_MOO1)
	onBuffAdded("BuffAdd_Moo", nil, nil, BUFFID_MOO2)
	onBuffAdded("BuffAdd_Twirl", nil, nil, DEBUFFID_TWIRL)
	
	onBuffRemoved("BuffRemove_Twirl", nil, nil, DEBUFFID_TWIRL)
end

function Mod:OnStart()
	nMOOCount = 0
    bIsPhase2 = false
	
	self:AddTimer("timer_midphase", 60)
	self:AddTimer("timer_tomb", 30)
end

function Mod:BossCreated_Air(nId, tUnit, sName, bInCombat)
	self:AddUnit("boss_air", tUnit, false, true, false) --bOnCast, bOnBuff, bOnDebuff
end

function Mod:BossCreated_Water(nId, tUnit, sName, bInCombat)
	self:AddUnit("boss_water", tUnit, true, true, false)
end

function Mod:CastStart_Tsunami(nId, sCastName, tCast, sName, nDuration)
	bIsPhase2 = true
	nMOOCount = nMOOCount + 1
	self:ShowAlert("alert_phase2")
	self:PlaySound("sound_phase2")
end

function Mod:CastStart_IceStorm(nId, sCastName, tCast, sName, nDuration)
	self:ShowAlert("alert_icestorm")
	self:PlaySound("sound_icestorm")
end

function Mod:CastEnd_Tsunami(nId, sCastName, tCast, sName)
	self:AddTimer("timer_midphase", 88)
	self:AddTimer("timer_tomb", 30)
end

function Mod:BuffAdd_Moo(nId, nSpellId, sName, tData, sUnitName, nStack, nDuration) 
	if bIsPhase2 then
		bIsPhase2 = false
		if nMOOCount == 2 then
            nMOOCount = 0
            mod:AddTimer("timer_icestorm", 15)
        end
	end
end

function Mod:BuffAdd_Twirl(nId, nSpellId, sName, tData, sUnitName, nStack, nDuration) 
	local tUnit = tData.tUnit
	if tUnit:IsThePlayer() then
		self:ShowAlert("alert_twirl")
		self:PlaySound("sound_twirl")
	else
		self:DrawIcon("icon_twirl", tUnit, 20, 20, nil, "twirl"..tUnit:GetId()) --show for max 20s
	end
end

function Mod:BuffRemove_Twirl(nId, nSpellId, sName, tData, sUnitName)
	if not tData.tUnit:IsThePlayer() then
		self:RemoveIcon("twirl"..tData.tUnit:GetId())
	end
end

Mod:new()