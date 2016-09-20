require "Window"
require "Apollo"

--[[
    #########################################################################################################################################
    ####    USEFUL FUNCTIONS (LUI_BossMods // self.core)
    #########################################################################################################################################

    AddUnit(nId, sName, tUnit, bShowUnit, bOnCast, bOnBuff, bOnDebuff, sMark, sColor, nPriority)
        Adds a unit to the list of tracked units.
        @param nId              - Unique ID of unit
        @param sName            - Name of the unit
        @param tUnit            - Unit Object from carbine
        @param bShowUnit        - Boolean whether or not unit should be displayed (boss frames)
        @parem bOnCast          - Track Casts of this unit
        @param bOnBuff          - Track Buffs of this unit
        @param bOnDebuff        - Track Debuffs of this unit
        @param sMark            - Letter in Front of UnitFrame
        @param sColor           - Health Bar Color (ARGB String)
        @param nPriority        - Priority in UnitFrame and Option Panel (Top to Bottom)

    AddTimer(sName, sText, nDuration, sColor, fHandler, tData)
        Creates a timer bar
        @param sName            - Unique ID
        @param sText            - Text displayed on the timer bar
        @param nDuration        - Duration in Seconds
        @param sColor           - Bar Color (ARGB String)
        @param fHandler         - Callback function
        @param tData            - Data to send on callback

    RemoveTimer(sName, bCallback)
        Hides the Timer
        @param sName            - Name of the Timer
        @param bCallback        - Perform Callback (boolean)

    ShowCast(tCast, sName, sColor)
        Shows Castbar
        @param tCast            - Cast Object
        @param sName            - Text shown on the Castbar
        @param sColor           - Cast Bar Color (ARGB String)

    ShowAura(sName, sSprite, sColor, nDuration, bShowDuration, fHandler, tData)
        Creates an Aura on your screen (like LUI Aura)
        @param sName            - Unique ID
        @param sSprite          - Sprite of Aura (all sprites are located in LUI_BossMods/Sprites)
        @param sColor           - Sprite Color (ARGB String)
        @param nDuration        - Duration in Seconds (optional)
        @param bShowDuration    - Show Duration Text
        @param fHandler         - Callback function
        @param tData            - Data to send on callback

    HideAura(sName, bCallback)
        Hides the Aura
        @param sName            - Name of the Aura
        @param bCallback        - Perform Callback (boolean)

    ShowAlert(sName, sText, nDuration, sColor, sFont)
        Shows a Text Notification on your screen
        @param sName            - Unique ID
        @param sText            - Text displayed
        @param nDuration        - Duration in Seconds
        @param sColor           - Text Color (ARGB String)
        @param sFont            - Text Font

    PlaySound(sound)
        Plays a soundfile
        @param sound            - Name of Soundfile (can be either string of filename or number of carbine sound)

    DrawIcon(Key, Origin, sSprite, nSpriteSize, nHeight, sColor, nDuration, bShowOverlay, fHandler, tData)
        Draw Icon on top of unit
        @param Key              - Unique ID
        @param Origin           - Unit Object
        @param sSprite          - Sprite of Pixie (all sprites are located in LUI_BossMods/Sprites)
        @param nSpriteSize      - Size of Pixie
        @param nHeight          - Height of Icon from bottom
        @param sColor           - Text Color (ARGB String)
        @param nDuration        - Duration in seconds before getting removed (optional)
        @param bShowOverlay     - Show Duration Overlay (boolean)
        @param fHandler         - Callback function
        @param tData            - Data to send on callback

    RemoveIcon(Key, bCallback)
        Removes Icon from Screen
        @param Key              - Unique ID
        @param bCallback        - Perform Callback (boolean)

    DrawPixie(Key, Origin, sSprite, nSpriteSize, nRotation, nDistance, nHeight, sColor, nDuration, fHandler, tData)
        Draw Pixie on top of unit or coordinate
        @param Key              - Unique ID
        @param Origin           - Unit Object / UnitId or Coordinates
        @param sSprite          - Sprite of Pixie (all sprites are located in LUI_BossMods/Sprites)
        @param nSpriteSize      - Size of Pixie
        @param nRotation        - Rotation in degrees
        @param nDistance        - Offset to the front of origin
        @param nHeight          - Height of Pixie from bottom
        @param sColor           - Text Color (ARGB String)
        @param nDuration        - Duration in seconds before getting removed (optional)
        @param fHandler         - Callback function
        @param tData            - Data to send on callback

    RemovePixie(Key, bCallback)
        Removes Pixie from Screen
        @param Key              - Unique ID
        @param bCallback        - Perform Callback (boolean)

    DrawPolygon(Key, Origin, nRadius, nRotation, nWidth, sColor, nSide, nDuration, fHandler, tData)
        Draws a polyon on the ground at unit or position
        @param Key              - Unique ID
        @param Origin           - Unit Object / UnitId or Coordinates
        @param nRadius          - Radius of Polygon
        @param nWidth           - Thickness
        @param sColor           - Text Color (ARGB String)
        @param nSides           - Amount of Sides of the Polygon
        @param nDuration        - Duration in seconds before getting removed (optional)
        @param fHandler         - Callback function
        @param tData            - Data to send on callback

    RemovePolygon(Key, bCallback)
        Removes Polygon from Screen
        @param Key              - Unique ID
        @param bCallback        - Perform Callback (boolean)

    DrawLine(Key, Origin, sColor, nWidth, nLength, nRotation, nOffset, tVectorOffset, nDuration, nNumberOfDot, fHandler, tData)
        Draws a line from unit/coordinate into certain direction (unit facing/north by default)
        @param Key              - Unique ID
        @param Origin           - Unit Object / UnitId or Coordinates
        @param sColor           - Text Color (ARGB String)
        @param nWidth           - Thickness
        @param nLength          - Length
        @param nRotation        - Rotation in degrees
        @param nOffset          - Offset to Origin
        @param tVectorOffset    - Offset to Origin (table or vector3)
        @param nDuration        - Duration in seconds before getting removed (optional)
        @param nNumberOfDot     - Amount of dots (1 = default)
        @param fHandler         - Callback function
        @param tData            - Data to send on callback

    RemoveLine(Key, bCallback)
        Removes Lines from Screen
        @param Key              - Unique ID
        @param bCallback        - Perform Callback (boolean)

    DrawLineBetween(Key, FromOrigin, ToOrigin, nWidth, sColor, nDuration, nNumberOfDot, fHandler, tData)
        @param Key              - Unique ID
        @param FromOrigin       - Unit Object / UnitId or Coordinates
        @param ToOrigin         - Unit Object / UnitId or Coordinates (PlayerUnit if nil)
        @param nWidth           - Thickness
        @param sColor           - Text Color (ARGB String)
        @param nDuration        - Duration in seconds before getting removed (optional)
        @param nNumberOfDot     - Amount of dots (1 = default)
        @param fHandler         - Callback function
        @param tData            - Data to send on callback

    RemoveLineBetween(Key, bCallback)
        Removes Lines from Screen
        @param Key              - Unique ID
        @param bCallback        - Perform Callback (boolean)

    GetDistance(FromOrigin, ToOrigin)
        Compute the distance between two origins.
        @param FromOrigin       - Unit Object / UnitId or Coordinates
        @param ToOrigin         - Unit Object / UnitId or Coordinates (PlayerUnit if nil)
        @return The distance in meter.
]]

local Mod = {}
local LUI_BossMods = Apollo.GetAddon("LUI_BossMods")
local Encounter = "name_of_encounter"   -- Name of Encounter Module (XML file needs to be EncounterName.xml)

local Locales = {
    ["enUS"] = {    -- Table of english locales
        ["unit.boss"] = "Dreadphage Ohmna",
    },
    ["deDE"] = {    -- Table of german locales
        ["unit.boss"] = "Schreckensphage Ohmna",
    },
    ["frFR"] = {    -- Table of french locales
        ["unit.boss"] = "Ohmna la Terriphage",
    },
}

function Mod:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.instance = "Redmoon Terror"    -- Name of the Instance under which the module will show up in Option Panel
    self.displayName = "Shredder"       -- Name of the Encounter shown in the Option Panel
    self.groupName = nil                -- Name of the Group under which this Module will appear in Option Panel (e.g.: Minibosses)
    self.bHasSettings = true            -- Do Settings for the Option Panel exist?
    self.tTrigger = {
        sType = "ANY",
        tZones = {                      -- Zones in which module gets activated. Use GameLib.GetCurrentZoneMap() to retrieve current zone map.
            [1] = {                     -- When having multiple trigger zones, behavior is always "ANY".
                continentId = 104,      -- Continent Id
                parentZoneId = 548,     -- ParentZoneId
                mapId = 549,            -- MapId
            },
        },
        tNames = {                      -- Table of Units that have to exist and be in combat. Use sType to change between behavior "ANY" or "ALL".
            ["enUS"] = {"Swabbie Ski'Li"},
        },
    }
    self.run = false
    self.runtime = {}
    self.config = {                     -- Table of settings for this module
        enable = true,                  -- Enable/Disable Boss Module
        interval = 100,                 -- Update Interval for OnFrame Function
        units = {                       -- List of all units used in this module
            unitA = {
                enable = true,          -- Show this unit in UnitFrame?
                priority = 1,           -- Priority in UnitFrame and Option Panel (Top to Bottom)
                color = "96adff2f",     -- Health Bar Color (Default: Global Setting)
                label = "unit.a",       -- Text in Option Panel (Text or Locale Key)
            },
        },
        timers = {
            timerA = {
                enable = true,          -- Enable/Disable timer
                color = "ade91dfb",     -- Color (Default: Global Setting)
                label = "timer.a",      -- Text in Option Panel (Text or Locale Key)
            },
        },
        casts = {
            castA = {
                enable = true,          -- Enable/Disable cast
                color = "ffb22222",     -- Color (Default: Global Setting)
                label = "cast.a"        -- Text in Option Panel (Text or Locale Key)
            },
        },
        alerts = {
            alertA = {
                enable = true,          -- Enable/Disable alert
                color = "ffff4500",     -- Text Color (Default: Global Setting)
                duration = 5,           -- Duration (Default: Global Setting)
                label = "alert.a"       -- Text in Option Panel (Text or Locale Key)
            },
        },
        sounds = {
            soundA = {
                enable = true,          -- Enable/Disable sound
                file = "alert",         -- Sound File
                label = "sound.a"       -- Text in Option Panel (Text or Locale Key)
            },
        },
        icons = {
            iconA = {
                enable = true,          -- Enable/Disable icon
                sprite = "target2",     -- Icon Sprite
                size = 20,              -- Icon Size (Default: Global Setting)
                color = "ff40e0d0",     -- Icon Color (Default: Global Setting)
                label = "icon.a"        -- Text in Option Panel (Text or Locale Key)
            },
        },
        auras = {
            auraA = {
                enable = true,          -- Enable/Disable icon
                sprite = "bomb",        -- Icon Sprite
                color = "ff40e0d0",     -- Icon Color (Default: Global Setting)
                label = "aura.a"        -- Text in Option Panel (Text or Locale Key)
            },
        },
        lines = {
            lineA = {
                enable = true,          -- Enable/Disable line
                color = "ffff0000",     -- Color (Default: Global Setting)
                thickness = 10,         -- Thickness (Default: Global Setting)
                label = "line.a"        -- Text in Option Panel (Text or Locale Key)
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

-- OnFrame function you can use.
-- Uses update interval defined in config table
function Mod:OnFrame()
    if not self.run == true then
        return
    end

    self.tick = Apollo.GetTickCount()

    if not self.lastCheck then
        self.lastCheck = self.tick
    end

    if (self.tick - self.lastCheck) > self.config.interval then
        -- Put your stuff in here

        self.lastCheck = self.tick
    end
end

-- Gets called for every unit that is created
-- Gets also called when combat state of unit has changed (OnEnteredCombat)
-- @param nId               - Unique ID of the unit
-- @param tUnit             - Unit Object from carbine
-- @param sName             - Name of the Unit
-- @param bInCombat         - Boolean whether or not unit is combat
function Mod:OnUnitCreated(nId, tUnit, sName, bInCombat)
    if not self.run == true then
        return
    end
end

-- Gets called for every unit that is destroyed
-- @param nId               - Unique ID of the unit
-- @param tUnit             - Unit Object from carbine
-- @param sName             - Name of the Unit
function Mod:OnUnitDestroyed(nId, tUnit, sName)

end

-- Gets called everytime health amount has changed (tracked units only)
-- @param nId               - Unique ID of the unit
-- @param nHealthPercent    - Health Percentage
-- @param sName             - Name of the Unit
-- @param tUnit             - Unit Object from carbine
function Mod:OnHealthChanged(nId, nHealthPercent, sName, tUnit)

end

-- Chat Messages tracked in OnNPCSay, OnNPCYell, OnNPCWhisper, OnDatachron
-- @param sMessage          - Message send
-- @param sSender           - Name of the Sender
-- @param sHandler          - Name of the Chat Event
function Mod:OnDatachron(sMessage, sSender, sHandler)

end

-- Gets called for every new buff/debuff that is applied on a unit (tracked units only)
-- @param nId               - Unique ID of the unit
-- @param nSpellId          - Unique ID of the spell
-- @param sName             - Name of the spell
-- @param tData             - Table of contents about the spell and unit
    -- @param nId               - Unique ID of the spell
    -- @param sName             - Name of the spell
    -- @param nDuration         - Duration of the buff/debuff
    -- @param nTick             - TickCount
    -- @param nCount            - Stack Count
    -- @param nUnitId           - Unique ID of the unit
    -- @param sUnitName         - Name of the unit
    -- @param tUnit             - Unit Object from carbine
    -- @param tSpell            - Spell Object from carbine
-- @param sUnitName         - Name of the unit
-- @param nStack            - Stack Count
-- @param nDuration         - Duration of the buff/debuff
function Mod:OnBuffAdded(nId, nSpellId, sName, tData, sUnitName, nStack, nDuration)

end

-- Gets called for every updated buff/debuff on a unit (tracked units only)
-- @params same as OnBuffAdded
function Mod:OnBuffUpdated(nId, nSpellId, sName, tData, sUnitName, nStack, nDuration)

end

-- Gets called for every removed buff/debuff on a unit (tracked units only)
-- @params same as OnBuffAdded
function Mod:OnBuffRemoved(nId, nSpellId, sName, tData, sUnitName)

end

-- Gets called everytime the unit starts casting (tracked units only)
-- @param nId               - Unique ID of the unit
-- @param sCastName         - Name of the cast
-- @param tCast             - Table of contents about the spell and unit
    -- @param sName             - Name of the spell
    -- @param nDuration         - Duration of the cast
    -- @param nElapsed          - Elapsed duration of the cast
    -- @param nTick             - TickCount
    -- @param nUnitId           - Unique ID of the unit
    -- @param sUnitName         - Name of the unit
    -- @param tUnit             - Unit Object from carbine
-- @param sName             - Name of the unit
-- @param nDuration         - Cast Duration
--
-- Note: CastName "MOO" indicates, that this cast is the MOO Duration
function Mod:OnCastStart(nId, sCastName, tCast, sName, nDuration)

end

-- Gets called everytime the unit ends casting (tracked units only)
-- @params same as OnCastStart
function Mod:OnCastEnd(nId, sCastName, tCast, sName)

end

-- Register Event Handler for the module
function Mod:RegisterEvents()
    Apollo.RegisterEventHandler("VarChange_FrameCount", "OnFrame", self)
end

-- Unregister Event Handler for the module
function Mod:RemoveEvents()
    Apollo.RemoveEventHandler("VarChange_FrameCount", self)
end

function Mod:IsRunning()
    return self.run
end

function Mod:IsEnabled()
    return self.config.enable
end

-- Gets called when player enters combat while module trigger being successful.
function Mod:OnEnable()
    self.run = true
    self:RemoveEvents()
    self:RegisterEvents()
end

-- Gets called when group wipes on encounter
function Mod:OnDisable()
    self.run = false
    self:RemoveEvents()
end

local ModInst = Mod:new()
LUI_BossMods.modules[Encounter] = ModInst
