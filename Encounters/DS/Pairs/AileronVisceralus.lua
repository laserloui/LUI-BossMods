require "Window"
require "Apollo"

local Mod = {}
local LUI_BossMods = Apollo.GetAddon("LUI_BossMods")
local Encounter = "AileronVisceralus"

local Locales = {
    ["enUS"] = {
        -- Unit names
        ["unit.boss_air"] = "Aileron",
        ["unit.boss_life"] = "Visceralus",
    },
    ["deDE"] = {},
    ["frFR"] = {},
}

function Mod:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.instance = "Datascape"
    self.displayName = "Aileron & Visceralus"
    self.tTrigger = {
        sType = "ANY",
        tZones = {
            [1] = {
                continentId = 52,
                parentZoneId = 98,
                mapId = 119,
            },
        },
        tNames = {
            ["enUS"] = {"Aileron","Visceralus"},
        },
    }
    self.run = false
    self.runtime = {}
    self.config = {
        enable = true,
    }
    return o
end

function Mod:Init(parent)
    Apollo.LinkAddon(parent, self)

    self.core = parent
    self.L = parent:GetLocale(Encounter,Locales)

    local strPrefix = Apollo.GetAssetFolder()
    local tToc = XmlDoc.CreateFromFile("toc.xml"):ToTable()
    for k,v in ipairs(tToc) do
        local strPath = string.match(v.Name, "(.*)[\\/]"..Encounter)
        if strPath ~= nil and strPath ~= "" then
            strPrefix = strPrefix .. "\\" .. strPath .. "\\"
            break
        end
    end

    self.xmlDoc = XmlDoc.CreateFromFile(strPrefix .. Encounter..".xml")
    self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

function Mod:OnDocLoaded()
    if self.xmlDoc == nil or not self.xmlDoc:IsLoaded() then
        return
    end
end

function Mod:OnUnitCreated(nId, tUnit, sName, bInCombat)
    if not self.run == true then
        return
    end

    if sName == self.L["unit.boss_air"] and bInCombat == true then
        self.core:AddUnit(nId,sName,tUnit,true,false,false,false,nil,self.config.healthColor)
    elseif sName == self.L["unit.boss_life"] and bInCombat == true then
        self.core:AddUnit(nId,sName,tUnit,true,false,false,false,nil,self.config.healthColor)
    end
end

function Mod:LoadSettings(wndParent)
    if not wndParent then
        return
    end

    local wnd = Apollo.LoadForm(self.xmlDoc, "Settings", wndParent, self)

    return wnd
end

function Mod:IsEnabled()
    return self.run
end

function Mod:OnEnable()
    self.run = true
end

function Mod:OnDisable()
    self.run = false
end

local ModInst = Mod:new()
LUI_BossMods.modules[Encounter] = ModInst
