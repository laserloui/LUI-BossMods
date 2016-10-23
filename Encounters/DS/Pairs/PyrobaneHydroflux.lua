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
        ["unit.ice_tomb"] = "Ice Tomb",
        ["unit.flame_wave"] = "Flame Wave",
        -- Texts
        ["text.next_bombs"] = "Next bombs",
        ["text.next_ice_tomb"] = "Next ice tomb",
        -- Labels
        ["label.bombs"] = "Bombs",
        ["label.fireBombs"] = "Fire bombs",
        ["label.waterBombs"] = "Water bombs",
        ["label.ice_tomb"] = "Ice Tomb",
        ["label.flame_waves"] = "Flame Waves",
		--Messages
		["message.bombs"] = "Bombs!",
		["message.ice_tomb"] = "Ice Tombs!",
    },
    ["deDE"] = {
        -- Unit names
        ["unit.boss_fire"] = "Pyroman",
        ["unit.boss_water"] = "Hydroflux",
        ["unit.ice_tomb"] = "Eisgrab",
        ["unit.flame_wave"] = "Flammenwelle",
        -- Texts
        ["text.next_bombs"] = "Nächste Bomben",
        ["text.next_ice_tomb"] = "Nächstes Eisgrab",
        -- Labels
        ["label.bombs"] = "Bomben",
        ["label.fireBombs"] = "Feuer-Bomben",
        ["label.waterBombs"] = "Wasser-Bomben",
        ["label.ice_tomb"] = "Eisgrab",
        ["label.flame_waves"] = "Flammenwellen",
		--Messages
		["message.bombs"] = "Bomben!",
		["message.ice_tomb"] = "Eisgräber!",
	},
    ["frFR"] = {
		-- Unit names
        ["unit.boss_fire"] = "Pyromagnus",
        ["unit.boss_water"] = "Hydroflux",
        ["unit.ice_tomb"] = "Tombeau de glace",
        ["unit.flame_wave"] = "Vague de feu",
        -- Texts
        ["text.next_bombs"] = "Prochaine bombes",
        ["text.next_ice_tomb"] = "Prochain tombeau de glace",
        -- Labels
        ["label.bombs"] = "Bombes",
        ["label.fireBombs"] = "Fire bombs", --translate please.
        ["label.waterBombs"] = "Water bombs", --translate please.
        ["label.ice_tomb"] = "Tombeau de glace",
        ["label.flame_waves"] = "Vague de feu",
		--Messages
		["message.bombs"] = "Bombes!",
		["message.ice_tomb"] = "Tombeau de glace!",
	},
}

local nLastBombTime = 0
local nLastIceTombTime = 0
local tFrostBombs = {} --all fire-bombs; [unitId] = true
local tFireBombs = {} --all frost-bombs
local tBombLines = {} --map of all id's used for bomb-lines; [unitId] = "KeyUsedToCreateLine"

local DEBUFF_FROSTBOMB = 75058
local DEBUFF_FIREBOMB = 75059
local DEBUFF_ICE_TOMB = 74326

function Mod:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.instance = "Datascape"
    self.displayName = "Pyrobane & Hydroflux"
    self.groupName = "Elemental Pairs"
    self.tTrigger = {
        sType = "ALL",
        tNames = {"unit.boss_fire", "unit.boss_water"},
        tZones = {
            [1] = {
                continentId = 52,
                parentZoneId = 98,
                mapId = 118,
            },
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
        alerts = {
            bombs = {
                enable = true,
                duration = 3,
                label = "label.bombs",
            },
            ice_tomb = {
                enable = true,
                duration = 3,
                label = "label.ice_tomb",
            },
        },
        sounds = {
            bombs = {
                enable = true,
                file = "info",
                label = "label.bombs",
            },
            ice_tomb = {
                enable = true,
                file = "alert",
                label = "label.ice_tomb",
            },
        },
        timers = {
            bombs = {
                enable = true,
                color = "ade91dfb",
                text = "text.next_bombs",
                label = "label.bombs",
            },
            ice_tomb = {
                enable = true,
                color = "ade91dfb",
                text = "text.next_ice_tomb",
                label = "label.ice_tomb",
            },
        },
		icons = {
			fireBombs = {
                enable = true,
                sprite = "LUIBM_bomb",
                size = 40,
                color = "ffff2f2f",
                label = "label.fireBombs",
			},
			waterBombs = {
                enable = true,
                sprite = "LUIBM_bomb",
                size = 40,
                color = "ff1e1eff",
                label = "label.waterBombs",
			},
		},
        lines = {
            flame_wave = {
                enable = true,
                thickness = 10,
                color = "ffff0000",
                label = "label.flame_waves",
            },
			bombs = { --line to bombs of the other type (relative to your current bomb)
                enable = true,
                thickness = 7,
                label = "label.bombs",
			},
        },
    }
	
    return o
end

function Mod:Init(parent)
    Apollo.LinkAddon(parent, self)

    self.core = parent
    self.L = parent:GetLocale(Encounter,Locales)
end

function Mod:DrawBombLines()
	local player = GameLib.GetPlayerUnit()
	local nId = player:GetId()
	
	local otherBombs = tFireBombs[nId] and tFrostBombs or tFrostBombs[nId] and tFireBombs or {}
	
	for id in pairs(otherBombs) do
		local key = "bombLine"..id
		tBombLines[id] = key
		self.core:DrawLineBetween(key, player, id, self.config.lines.bombs)
	end
end

function Mod:OnUnitCreated(nId, tUnit, sName, bInCombat)
    if not self.run == true then
        return
    end

    if sName == self.L["unit.boss_fire"] then
        self.core:AddUnit(nId,sName,tUnit,self.config.units.boss_fire)
    elseif sName == self.L["unit.boss_water"] then
        self.core:AddUnit(nId,sName,tUnit,self.config.units.boss_water)
    elseif sName == self.L["unit.flame_wave"] then
        self.core:DrawLine(nId, tUnit, self.config.lines.flame_wave, 20)
    end
end

function Mod:OnUnitDestroyed(nId, tUnit, sName)
    if sName == self.L["unit.flame_wave"] then
        self.core:RemoveLine(nId)
    end
end

function Mod:OnBuffAdded(nId, nSpellId, sName, tData, sUnitName, nStack, nDuration)
    if nSpellId == DEBUFF_FIREBOMB or nSpellId == DEBUFF_FROSTBOMB then
        local nCurrentTime = GameLib.GetGameTime()
        if nCurrentTime - nLastBombTime > 10 then
            nLastBombTime = nCurrentTime
            self.core:AddTimer("BOMBS", self.L["message.bombs"], 30, self.config.timers.bombs)
			
			tFrostBombs = {}
			tFireBombs = {}
        end
		if tData.tUnit:IsThePlayer() then
			ApolloTimer.Create(1, false, "DrawBombLines", self)
		end
		if nSpellId == DEBUFF_FIREBOMB then
			self.core:DrawPixie(nId, tData.tUnit, self.config.icons.fireBombs, 0, 0, 2)
			tFireBombs[nId] = true
		else
			self.core:DrawPixie(nId, tData.tUnit, self.config.icons.waterBombs, 0, 0, 2)
			tFrostBombs[nId] = true
		end		
    elseif nSpellId == DEBUFF_ICE_TOMB then
        local nCurrentTime = GameLib.GetGameTime()
        if nCurrentTime - nLastIceTombTime > 5 then
            nLastIceTombTime = nCurrentTime
            self.core:AddTimer("ICE_TOMB", self.L["message.ice_tomb"], 15, self.config.timers.ice_tomb)
        end
    end
end

function Mod:OnBuffRemoved(nId, nSpellId, sName, tData, sUnitName)
    if nSpellId == DEBUFF_FIREBOMB or nSpellId == DEBUFF_FROSTBOMB then
		self.core:RemoveIcon(nId)
		if tData.tUnit:IsThePlayer() then
			for id, key in pairs(tBombLines) do
				self.core:RemoveLineBetween(key)
			end
			tBombLines = {}
		elseif tBombLines[nId] then
			self.core:RemoveLineBetween(tBombLines[nId])
			tBombLines[nId] = nil
		end
		tFrostBombs[nId] = nil
		tFireBombs[nId] = nil
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
    nLastIceTombTime = 0
    nLastBombTime = 0
	tFrostBombs = {}
	tFireBombs = {}
	tBombLines = {}

    self.core:AddTimer("BOMBS", self.L["message.bombs"], 30, self.config.timers.bombs)
    self.core:AddTimer("ICE_TOMB", self.L["message.ice_tomb"], 26, self.config.timers.ice_tomb)
end

function Mod:OnDisable()
    self.run = false
end

local ModInst = Mod:new()
LUI_BossMods.modules[Encounter] = ModInst
