require "Window"
require "Apollo"

local Mod = {}
local LUI_BossMods = Apollo.GetAddon("LUI_BossMods")
local Encounter = "Test"

local Locales = {
    ["enUS"] = {
        ["unit.bossA"] = "Grimhowl Devourer",
        ["unit.bossB"] = "Grimhowl Limbripper",
    },
    ["deDE"] = {
        ["unit.bossA"] = "Grimmheul-Verschlinger",
        ["unit.bossB"] = "Grimhowl Limbripper",
    },
    ["frFR"] = {},
}

function Mod:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.instance = "Test"
    self.displayName = "Test"
    self.tTrigger = {
        tZones = {
            [1] = {
                continentId = 8,    -- Olyssia
                parentZoneId = 0,
                mapId = 0,
            },
            [2] = {
                continentId = 33,   -- Isigrol
                parentZoneId = 0,
                mapId = 0,
            },
            [3] = {
                continentId = 6,    -- Alizar
                parentZoneId = 0,
                mapId = 0,
            },
            [4] = {
                continentId = 92,   -- Arcterra
                parentZoneId = 0,
                mapId = 0,
            },
            [5] = {
                continentId = 61,   -- Crimson Badlands
                parentZoneId = 0,
                mapId = 0,
            },
            [6] = {
                continentId = 104,   -- Redmoon
                parentZoneId = 0,
                mapId = 0,
            },
            [7] = {
                continentId = 103,   -- Palaver Point
                parentZoneId = 0,
                mapId = 0,
            },
        },
    }
    self.run = false
    self.runtime = {}
    self.config = {
        enable = true,
        units = {
            boss = {
                enable = true,
                label = "Boss",
            },
            player = {
                enable = true,
                color = "FFFF0000",
                label = "Player",
            },
        },
        auras = {
            atomic_attraction = {
                enable = true,
                sprite = "LUIBM_meteor3",
                color = "ffff4500",
                label = "debuff.atomic_attraction",
            },
        },
    }
    return o
end

function Mod:Init(parent)
    Apollo.LinkAddon(parent, self)

    self.core = parent
    self.L = parent:GetLocale(Encounter,Locales)

    --self.wndDebug = Apollo.LoadForm(self.core.xmlDoc, "Debug", nil, self)
    --self.wndDebug:Show(true,true)

    --math.randomseed(os.time())
end

function Mod:OnAddDebug()
    local tTexts = {
        [1] = "AAAAAAAAAAAAAA",
        [2] = "BBBBBBBBBBBBBB",
        [3] = "CCCCCCCCCCCCCC",
        [4] = "DDDDDDDDDDDDCD",
        [5] = "EEEEEEEEEEEEEE",
        [6] = "FFFFFFFFFFFFFF",
        [7] = "GGGGGGGGGGGGGG",
        [8] = "HHHHHHHHHHHHHH",
        [9] = "IIIIIIIIIIIIII",
        [10] = "KKKKKKKKKKKKK",
    }
    local nId = math.random(10)
    self.core:ShowAlert("TEST"..tostring(nId), tTexts[nId], {enable=true})
end

function Mod:OnUnitCreated(nId, tUnit, sName, bInCombat)
    if not self.run then
        return
    end

    if (sName == self.L["unit.bossA"] or sName == self.L["unit.bossB"]) and bInCombat then
        self.core:AddUnit(nId, sName, tUnit, self.config.units.boss)
    end
end

function Mod:OnBuffAdded(nId, nSpellId, sName, tData, sUnitName, nStack, nDuration)
    if sName == "Angry Swarm" then
        self.core:ShowAura("atomic_attraction", self.config.auras.atomic_attraction, nDuration, "Kite the orb!")
    end
end

function Mod:OnBuffRemoved(nId, nSpellId, sName, tData, sUnitName)
    if sName == "Angry Swarm" then
        self.core:HideAura("atomic_attraction")
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
    self.unitPlayer = GameLib.GetPlayerUnit()

    self.core:AddUnit("Player", "Loui NaN", self.unitPlayer, self.config.units.player)
end

function Mod:OnDisable()
    self.run = false
end

local ModInst = Mod:new()
LUI_BossMods.modules[Encounter] = ModInst
