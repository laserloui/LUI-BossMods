require "Window"
require "Apollo"

local Mod = {}
local LUI_BossMods = Apollo.GetAddon("LUI_BossMods")
local Encounter = "ChiefWardenLockjaw"

local Locales = {
    ["enUS"] = {
        -- Units
        ["unit.boss"] = "Chief Warden Lockjaw",
        ["unit.circle_telegraph"] = "Hostile Invisible Unit for Fields (0 hit radius)",
        -- Casts
        ["cast.blaze_shackles"] = "Blaze Shackles",
        -- Labels
        ["label.circle_telegraph"] = "Circle Telegraphs",
    },
    ["deDE"] = {},
    ["frFR"] = {},
}

function Mod:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.instance = "Redmoon Terror"
    self.displayName = "Chief Warden Lockjaw"
    self.groupName = "Minibosses"
    self.tTrigger = {
        sType = "ANY",
        tZones = {
            [1] = {
                continentId = 104,
                parentZoneId = 548,
                mapId = 550,
            },
        },
        tNames = {
            ["enUS"] = {"Chief Warden Lockjaw"},
        },
    }
    self.run = false
    self.runtime = {}
    self.config = {
        enable = true,
        units = {
            boss = {
                enable = true,
                label = "unit.boss",
            },
        },
        lines = {
            circle_telegraph = {
                enable = true,
                thickness = 7,
                color = "ffff1493",
                label = "label.circle_telegraph",
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

function Mod:OnUnitCreated(nId, tUnit, sName, bInCombat)
    if not self.run == true then
        return
    end

    if sName == self.L["unit.boss"] and bInCombat == true then
        self.core:AddUnit(nId,sName,tUnit,self.config.units.boss.enable,false,false,false,nil,self.config.units.boss.color)
    elseif sName == self.L["unit.circle_telegraph"] then
        if self.config.lines.circle_telegraph.enable == true then
            self.core:DrawPolygon(nId, tUnit, 6.5, 0, self.config.lines.circle_telegraph.thickness, self.config.lines.circle_telegraph.color, 20)
        end
    end
end

function Mod:OnUnitDestroyed(nId, tUnit, sName)
    if sName == self.L["unit.circle_telegraph"] then
        self.core:RemovePolygon(nId)
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
end

function Mod:OnDisable()
    self.run = false
end

local ModInst = Mod:new()
LUI_BossMods.modules[Encounter] = ModInst
