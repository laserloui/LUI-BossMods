require "Window"
require "Apollo"

local Mod = {}
local LUI_BossMods = Apollo.GetAddon("LUI_BossMods")
local Encounter = "PyrobaneHydroflux"

local Locales = {
    ["enUS"] = {
        -- Unit names
        ["unit.boss_fire"] = "Pyrobane",
        ["unit.boss_water"] = "Hydroflux",
		["unit.tomb"] = "Ice Tomb",
		
		["label.bomb"] = "Bombs",
		["label.tomb"] = "Ice Tomb",
		["label.otherBombFire"] = "Other Bombs: Fire",
		["label.otherBombWater"] = "Other Bombs: Water",
    },
    ["deDE"] = {
		["unit.boss_water"] = "Hydroflux",
		["unit.boss_fire"] = "Pyroman",
		["unit.tomb"] = "Eisgrab",
		
		["label.bomb"] = "Bomben",
		["label.tomb"] = "Eisgrab",
		["label.otherBombFire"] = "Andere Bomben: Feuer",
		["label.otherBombWater"] = "Andere Bomben: Wasser",
	},
    ["frFR"] = {
		["unit.boss_water"] = "Hydroflux",
		["unit.boss_fire"] = "Pyromagnus",
		["unit.tomb"] = "Tombeau de glace",
		
		["label.bomb"] = "Bombes",
		["label.tomb"] = "Tombeau de glace",
		["label.otherBombFire"] = "Other Bombs: Fire", --translate pls?
		["label.otherBombWater"] = "Other Bombs: Frost",
	},
}

function Mod:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.instance = "Datascape"
    self.displayName = "Pyrobane & Hydroflux"
    self.groupName = "Elemental Pairs"
    self.tTrigger = {
        sType = "ALL",
        tZones = {
            [1] = {
                continentId = 52,
                parentZoneId = 98,
                mapId = 118,
            },
        },
        tNames = {
            ["enUS"] = {"Pyrobane", "Hydroflux"},
			["deDE"] = {"Pyroman", "Hydroflux"},
			["frFR"] = {"Pyromagnus", "Hydroflux"},
        },
    }
    self.run = false
    self.runtime = {}
    self.config = {
        enable = true,
        units = {
            boss_fire = {
                enable = true,
                label = "unit.boss_fire",
                color = "afff2f2f",
            },
            boss_water = {
                enable = true,
                label = "unit.boss_water",
                color = "af1e90ff",
            },
        },
		timers = {
            bomb = {
                enable = true,          -- Enable/Disable timer
                color = "afff2f2f",     -- Color (Default: Global Setting)
                label = "label.bomb",      -- Text in Option Panel (Text or Locale Key)
            },
			tomb = {
                enable = true,          -- Enable/Disable timer
                color = "af1e90ff",     -- Color (Default: Global Setting)
                label = "label.tomb",      -- Text in Option Panel (Text or Locale Key)
            },
        },
		sounds = {
            bomb = { --bombs appeared
                enable = true,          -- Enable/Disable sound
                file = "alert",         -- Sound File
                label = "label.bomb"       -- Text in Option Panel (Text or Locale Key)
            },
			tomb = { --tombs appeared
				enable = true,          -- Enable/Disable sound
                file = "info",         -- Sound File
                label = "label.tomb"       -- Text in Option Panel (Text or Locale Key)
			},
        },
		lines = {
			otherBombFire = { --lines to bombs of other type
                enable = true,          -- Enable/Disable line
                color = "afff2f2f",     -- Color (Default: Global Setting)
                thickness = 7,         -- Thickness (Default: Global Setting)
                label = "label.otherBombFire"        -- Text in Option Panel (Text or Locale Key)
            },
			otherBombWater = { --lines to bombs of other type
                enable = true,          -- Enable/Disable line
                color = "af1e90ff",     -- Color (Default: Global Setting)
                thickness = 7,         -- Thickness (Default: Global Setting)
                label = "label.otherBombWater"        -- Text in Option Panel (Text or Locale Key)
            },
		},
    }
    return o
end

--Copied form RaidCore.
local DEBUFFID_ICE_TOMB = 74326
local DEBUFFID_FROSTBOMB = 75058
local DEBUFFID_FIREBOMB = 75059

local tFireBombs = {}
local tWaterBombs = {}
local strMyBomb = nil -- nil, "Frost" or "Fire" according to players bomb.


function Mod:Init(parent)
    Apollo.LinkAddon(parent, self)

    self.core = parent
    self.L = parent:GetLocale(Encounter,Locales)
end

function Mod:OnUnitCreated(nId, tUnit, sName, bInCombat)
	if not self.run == true then
        return
    end
	
    if sName == self.L["unit.boss_fire"] and bInCombat == true then
        self.core:AddUnit(nId,sName,tUnit,self.config.units.boss_fire.enable,false,false,false,nil,self.config.units.boss_fire.color)
    elseif sName == self.L["unit.boss_water"] and bInCombat == true then
        self.core:AddUnit(nId,sName,tUnit,self.config.units.boss_water.enable,false,false,false,nil,self.config.units.boss_water.color)
    end
end

function Mod:ApplyBombLines()
	self.bombTimer = nil
	
	if strMyBomb == "Fire" then
		for _, tUnit in ipairs(tWaterBombs) do
			self:ApplyBombLine(tUnit, "otherBombWater")
		end
	elseif strMyBomb == "Frost" then
		for _, tUnit in ipairs(tFireBombs) do
			self:ApplyBombLine(tUnit, "otherBombFire")
		end
	end
	
	tFireBombs = {}
	tWaterBombs = {}
	strMyBomb = nil
end

function Mod:ApplyBombLine(tUnit, key)
	self:DrawLineBetween(key, tUnit, nil--[[aka PlayerUnit]], "bomb"..tUnit:GetId(), 10 --[[Force removal after 10 sec]])
end

function Mod:RemoveBombLine(tUnit)
	self:RemoveLineBetween("bomb"..tUnit:GetId())
end

local lastTomb = 0
function Mod:OnBuffAdded(nId, nSpellId, sName, tData, sUnitName, nStack, nDuration)
	local tUnit = tData.tUnit
	
    if nSpellId == DEBUFFID_FIREBOMB then
		table.insert(tFireBombs, tUnit)
		if tUnit:IsThePlayer() then
			strMyBomb = "Fire"
		end
		if not self.bombTimer then
			--no matter to who the bomb was applied, we always want to at least clear the tFireBombs from its content. (even if we do not draw lines)
			self.bombTimer = ApolloTimer.Create(1, false, "ApplyBombLines", self)
			self:AddTimer("bomb", 30)
		end
    elseif nSpellId == DEBUFFID_FROSTBOMB then
        table.insert(tWaterBombs, tUnit)
		if tUnit:IsThePlayer() then
			strMyBomb = "Frost"
		end
		if not self.bombTimer then
			self.bombTimer = ApolloTimer.Create(1, false, "ApplyBombLines", self)
			self:AddTimer("bomb", 30)
		end
    elseif nSpellId == DEBUFFID_ICE_TOMB then
		local now = GameLib.GetGameTime()
		if now - lastTomb > 5 then
			self:AddTimer("tomb", 15)
			self:PlaySound("tomb")
		end
		lastTomb = now
    end
end

function Mod:OnBuffRemoved(nId, nSpellId, sName, tData, sUnitName)
    local tUnit = tData.tUnit

    if nSpellId == DEBUFFID_FIREBOMB then
		self:RemoveBombLine(tUnit)
    elseif nSpellId == DEBUFFID_FROSTBOMB then
		self:RemoveBombLine(tUnit)
    end
end

function Mod:IsRunning()
    return self.run
end

function Mod:IsEnabled()
    return self.config.enable
end

function Mod:OnEnable()
    self.run = true
	
	tFireBombs = {}
	tWaterBombs = {}
	strMyBomb = nil

	self:AddTimer("bomb", 30)
	self:AddTimer("tomb", 26)
end

function Mod:OnDisable()
    self.run = false
end


-------- ### HELPER METHODS ### ------
--Sorry, but i just dont like the default way of doing these - so much simpler this way. And the amount of typos i could have had...

function Mod:AddTimer(key, time)
	if self.config.timers[key] and self.config.timers[key].enable then --why actually do we compare with true?
		local txt = self.L[self.config.timers[key].label] or self.config.timers[key].label
		self.core:AddTimer(key, txt, time, self.config.timers[key].color)
	end
end

function Mod:PlaySound(key)
	if self.config.sounds[key] and self.config.sounds[key].enable then
		self.core:PlaySound(self.config.sounds[key].file)
	end
end

function Mod:DrawLineBetween(key, unit1, unit2, uniqueID, nDuration)
	if self.config.lines[key] and self.config.lines[key].enable then
		self.core:DrawLineBetween(uniqueID or key, unit1, unit2,  self.config.lines[key].thickness, self.config.lines[key].color, nDuration)
	end
end

function Mod:RemoveLineBetween(uniqueID)
	--dont need to check if enabled. (we do not even ask for the key.)
	self.core:RemoveLineBetween(uniqueID)
end
	
local ModInst = Mod:new()
LUI_BossMods.modules[Encounter] = ModInst
