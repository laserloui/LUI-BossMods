require "Window"
require "Apollo"

local Mod = {}
local LUI_BossMods = Apollo.GetAddon("LUI_BossMods")
local Encounter = "ChiefWardenLockjaw"

local Locales = {
	["enUS"] = {
		-- Unit names
		["Chief Warden Lockjaw"] = "Chief Warden Lockjaw",
		-- Cast names
		["Blaze Shackles"] = "Blaze Shackles",
	},
	["deDE"] = {},
	["frFR"] = {},
}

function Mod:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 
    self.instance = "Redmoon Terror"
    self.displayName = "Mini: Chief Warden Lockjaw"
    self.zone = {
		continentId = 104,
		parentZoneId = 548,
		mapId = 550,
	}
	self.run = false
	self.runtime = {}
    self.config = {
    	enable = true,
    	PillarHealth = {
    		enable = true,
    		sound = true,
    	},
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

function Mod:LoadSettings(wndParent)
	if not wndParent then
		return 
	end 

	return Apollo.LoadForm(self.xmlDoc, "Settings", wndParent, self)
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