require "Window"
require "Apollo"

local LUI_BossMods = Apollo.GetAddon("LUI_BossMods")
local Mod = LUI_BossMods:EncounterPrototype("AileronHydroflux")

--Localize some of your Variables.
--These will be accessible from self.L, NOT within Mod:Setup(), but everywhere else.
Mod:Locales(
    {--[[enUS]] 
        -- Unit names
        ["unit.boss_air"] = "Aileron",
        ["unit.boss_water"] = "Hydroflux",
    },
    {--[[deDE]] 
		-- Unit names
        ["unit.boss_air"] = "Aileron",
        ["unit.boss_water"] = "Hydroflux",
	}, 
    {--[[frFR]] 
		-- Unit names
        ["unit.boss_air"] = "Ventemort",
        ["unit.boss_water"] = "Hydroflux",
	}
)

--Describe all General Options and things you want to use in this Encounter.
function Mod:Setup()
	--[[Sets the categories/names of this encounter within the Option Panel
		@param sInstance			- Name of the Instance e.g.: "Datascape"
		@param sName				- Name of the Encounter e.g.: "System Daemons"
		@param sGroup				- Name of the Group of this Encounter (Optional) e.g.: "Minibosses"]]
	name("Datascape", "Aileron & Hydroflux", "Elemental Pairs")
	
	--[[Disables this Encounter by Default]]
	disable()
	
	--[[Disables the Settings-Page of this Encounter]]
	disableSettings()
	
	--[[Sets the triggers for this Encounter. (In which situations this Encounter should be loaded)
		@param sType				- "ALL" or "ANY" - Does the Encounter need every unit from the localized unittable, or only one?
		@param enUnits				- Indexed table of the required units of this Encounter
		@param deUnits				- Localized for the different Client-Languages
		@param frUnits				- Examples: {"Hydroflux", "Pyrobane"} or {"Swabbie Ski'li"}
		@params ...					- All Zones, in which this Encounter could be loaded. Example: {continentId = 104, parentZoneId = 548, mapId = 549} ]]
	trigger("ALL", {"Boss1","Boss2"}, {"GermanBoss1","GermanBoss2"}, {"FrenchBoss1","FrenchBoss2"}, {continentId = 52, parentZoneId = 98, mapId = 118}, {continentId = 52, parentZoneId = 98, mapId = 119})
	
	--[[Adds the defaults for a unit.
		@param key					- The key for these options
		@param bEnable				- Show this unit in UnitFrame?
		@param nPriority			- Priority in UnitFrame and Option Panel (Top to Bottom)
		@param sColor				- Default for Health Bar Color (not given: uses Global Setting)
		@param sLabel				- Text in Option Panel (Text or Locale Key)]]
	unit("boss_air", true, 1, "af00ffff", "unit.boss_air")
	unit("boss_water", true, 2, "af1e90ff", "unit.boss_water")
	
	--[[Adds the defaults for a timer.
		@param key					- The key for these options
		@param bEnable				- Default for Enable/Disable timer
		@param sColor				- Default for Timer Bar Color (not given: uses Global Setting)
		@param sLabel				- Text in Option Panel (Text or Locale Key)]]
	timer("timer_midphase", true, nil, "label.midphase")
	timer("timer_tomb", true, "af1e90ff", "label.tomb")
	timer("timer_icestorm", true, nil, "label.icestorm")
	
	--[[Adds the defaults for a cast.
		@param key					- The key for these options
		@param bEnable				- Default for Enable/Disable cast
		@param sColor				- Default for Cast Bar Color (not given: uses Global Setting)
		@param sLabel				- Text in Option Panel (Text or Locale Key)]]
	cast("cast_icestorm", true, nil, "label.icestorm")
	
	--[[Adds the defaults for a alert.
		@param key					- The key for these options
		@param bEnable				- Default for Enable/Disable alert
		@param sColor				- Default for Alert Color (not given: uses Global Setting)
		@param nDuration			- Duration for this alert
		@param sLabel				- Text in Option Panel (Text or Locale Key)]]
	alert("alert_phase2", true, nil, nil, "label.phase2")
	alert("alert_icestorm", true, nil, nil, "label.icestorm")
	alert("alert_twirl", true, nil, nil, "alert.twirlyou")
	
	--[[Adds the defaults for a sound.
		@param key					- The key for these options
		@param bEnable				- Default for Enable/Disable sound
		@param sFile				- Default for sound-file (can be either string of filename or number of carbine sound)
		@param sLabel				- Text in Option Panel (Text or Locale Key)]]
	sound("sound_phase2", true, "alert", "label.phase2")
	sound("sound_icestorm", true, "run-away", "label.icestorm")
	sound("sound_twirl", true, "inferno", "alert.twirlyou")

	--[[Adds the defaults for a icon/sprite.
		@param key					- The key for these options
		@param bEnable				- Default for Enable/Disable icon/sprite
		@param sSprite				- Default Sprite for this icon/sprite
		@param nSize				- Default Size for this icon/sprite (not given: uses Global Setting)
		@param sColor				- Default for icon/sprite Color (not given: uses Global Setting)
		@param sLabel				- Text in Option Panel (Text or Locale Key)]]
	icon("icon_twirl", true, "target", 20, "ffff0000", "label.twirl")
	
	--[[Adds the defaults for a aura.
		@param key					- The key for these options
		@param bEnable				- Default for Enable/Disable aura
		@param sSprite				- Default Sprite for this aura
		@param sColor				- Default for aura Color (not given: uses Global Setting)
		@param sLabel				- Text in Option Panel (Text or Locale Key)]]
	aura("aura_twirlyou", true, "target2", "ff00ff00", "alert.twirlyou")
	
	--[[Adds the defaults for a line.
		@param key					- The key for these options
		@param bEnable				- Default for Enable/Disable line
		@param sColor				- Default for line Color
		@param nThickness			- Default for line Thickness
		@param sLabel				- Text in Option Panel (Text or Locale Key)]]
	line("line_twirltotomb", true, "ff0f0f0f", 7, "Twirl to Tomb")
	line("line_mycircle", true, "fff0f0f0", 7, "label.mycircle")
	line("line_bossbackline", true, "ff000000", 5, "Line out of Basses back")
end

--Filter the available Events to pass these to specific Methods.
function Mod:SetupEvents()
	-- THE ADDON WILL CREATE ERRORS, IF YOU PASS 'sMethod' IN WITHOUT IMPLEMENTING A METHOD COMING UP FOR THIS!

	--[[Calls the Method 'sMethod' whenever a matching event was recieved. Passes only events on, which match the parameters after sMethod.
		@param sMethod				- The key, to find the to-be-called method at. (e.g. "Cast123" would call Mod:Cast123(...))
		@param sName				- The units name													- Optional, nil = dont filter by this parameter
		@param bInCombat			- Is the unit in combat?											- Optional, nil = dont filter by this parameter]]
	onUnitCreated("BossCreated_Air", self.L["unit.boss_air"], true)
	onUnitCreated("BossCreated_Water", self.L["unit.boss_water"], true)
	
	--[[Calls the Method 'sMethod' whenever a matching event was recieved. Passes only events on, which match the parameters after sMethod.
		@param sMethod				- The key, to find the to-be-called method at. (e.g. "Cast123" would call Mod:Cast123(...))
		@param sName				- The units name													- Optional, nil = dont filter by this parameter]]
	onUnitDestroyed("BossDestroyed", self.L["unit.boss_air"]) 
	onUnitDestroyed("BossDestroyed", self.L["unit.boss_water"]) --if either of them get destroyed, :BossDestroyed(...) will be called.
	
	--[[Calls the Method 'sMethod' whenever a matching event was recieved. Passes only events on, which match the parameters after sMethod.
		@param sMethod				- The key, to find the to-be-called method at. (e.g. "Cast123" would call Mod:Cast123(...))
		@param uniqueID				- The uniqueID the unit was added with								- Optional, nil = dont filter by this parameter
		@param sName				- The units name													- Optional, nil = dont filter by this parameter]]
	onHealthChanged("Dummy_HealthChanged") --Every HealthChanged event will be passed to :Dummy_HealthChanged(...)
	onHealthChanged("Filtered_HealthChanged", "unit.boss_air") --if the Air-Bosses Health Changes, :Filtered_HealthChanged(...) will be called ASWELL
	
	--[[Calls the Method 'sMethod' whenever a matching event was recieved. Passes only events on, which match the parameters after sMethod.
		@param sMethod				- The key, to find the to-be-called method at. (e.g. "Cast123" would call Mod:Cast123(...))
		@param sMessage				- The said message													- Optional, nil = dont filter by this parameter
		@param sName				- The units name													- Optional, nil = dont filter by this parameter
		@param sEvent				- The Original Chat-Event OnNPCSay, OnNPCYell, OnNPCWhisper, OnDatachron - Optional, nil = dont filter by this parameter]]
	onDatachron("Yell_Msg", "The exact Message, which the unit may send.", "UnitsName?", "OnNPCYell")
	
	--[[Calls the Method 'sMethod' whenever a matching event was recieved. Passes only events on, which match the parameters after sMethod.
		@param sMethod				- The key, to find the to-be-called method at. (e.g. "Cast123" would call Mod:Cast123(...))
		@param uniqueID				- The uniqueID the unit was added with								- Optional, nil = dont filter by this parameter
		@param sUnitName			- The units name													- Optional, nil = dont filter by this parameter
		@param spellID				- The spells ID														- Optional, nil = dont filter by this parameter
		@param sSpellName			- The spells name													- Optional, nil = dont filter by this parameter	
		@param nStack				- The amount of stacks this buff was applied with 					- Optional, nil = dont filter by this parameter]]
	onBuffAdded("BuffAdd_Moo", nil, nil, BUFFID_MOO1)
	onBuffAdded("BuffAdd_Moo", nil, nil, BUFFID_MOO2)
	onBuffAdded("BuffAdd_Twirl", nil, nil, DEBUFFID_TWIRL)
	
	--[[Calls the Method 'sMethod' whenever a matching event was recieved. Passes only events on, which match the parameters after sMethod.
		@param sMethod				- The key, to find the to-be-called method at. (e.g. "Cast123" would call Mod:Cast123(...))
		@param uniqueID				- The uniqueID the unit was added with								- Optional, nil = dont filter by this parameter
		@param sUnitName			- The units name													- Optional, nil = dont filter by this parameter
		@param spellID				- The spells ID														- Optional, nil = dont filter by this parameter
		@param sSpellName			- The spells name													- Optional, nil = dont filter by this parameter	
		@param nStack				- The amount of stacks this buff now has		 					- Optional, nil = dont filter by this parameter]]
	onBuffUpdated("HighStack_BuffX", nil, nil, nil, "BuffX", 15) --will call everytime a unit got updated with a 15-Stacked Buff/Debuff called "BuffX"
	
	--[[Calls the Method 'sMethod' whenever a matching event was recieved. Passes only events on, which match the parameters after sMethod.
		@param sMethod				- The key, to find the to-be-called method at. (e.g. "Cast123" would call Mod:Cast123(...))
		@param uniqueID				- The uniqueID the unit was added with								- Optional, nil = dont filter by this parameter
		@param sUnitName			- The units name													- Optional, nil = dont filter by this parameter
		@param spellID				- The spells ID														- Optional, nil = dont filter by this parameter
		@param sSpellName			- The spells name													- Optional, nil = dont filter by this parameter]]
	onBuffRemoved("BuffRemove_Twirl", nil, nil, DEBUFFID_TWIRL)
	
	--[[Calls the Method 'sMethod' whenever a matching event was recieved. Passes only events on, which match the parameters after sMethod.
		@param sMethod				- The key, to find the to-be-called method at. (e.g. "Cast123" would call Mod:Cast123(...))
		@param uniqueID				- The uniqueID the unit was added with								- Optional, nil = dont filter by this parameter
		@param sUnitName			- The units name													- Optional, nil = dont filter by this parameter
		@param sSpellName			- The spells name													- Optional, nil = dont filter by this parameter]]
	onCastStart("CastStart_Tsunami", "unit.boss_water", nil, self.L["cast.tsunami"])
	onCastStart("CastStart_IceStorm", "unit.boss_water", nil, self.L["cast.icestorm"])
	
	--[[Calls the Method 'sMethod' whenever a matching event was recieved. Passes only events on, which match the parameters after sMethod.
		@param sMethod				- The key, to find the to-be-called method at. (e.g. "Cast123" would call Mod:Cast123(...))
		@param uniqueID				- The uniqueID the unit was added with								- Optional, nil = dont filter by this parameter
		@param sUnitName			- The units name													- Optional, nil = dont filter by this parameter
		@param sSpellName			- The spells name													- Optional, nil = dont filter by this parameter]]
	onCastEnd("CastEnd_Tsunami", "unit.boss_water", nil, self.L["cast.tsunami"])
end

function Mod:OnStart()
	--called whenever the Addon detects the trigger to be matching and the encounter not being active yet. 
	--From this point onward, Events can be fired. 
	nMOOCount = 0
    bIsPhase2 = false
	
	self:AddTimer("timer_midphase", 60)
	self:AddTimer("timer_tomb", 30)
end

function Mod:OnEnd()
	--Called on Wipe.
	--Clean Up Stuff?
end

-- Gets called for every unit that is created (Matching the Filters)
-- Gets also called when combat state of unit has changed (OnEnteredCombat)
-- @param nId               - Unique ID of the unit
-- @param tUnit             - Unit Object from carbine
-- @param sName             - Name of the Unit
-- @param bInCombat         - Boolean whether or not unit is combat
function Mod:BossCreated_Air(nId, tUnit, sName, bInCombat)
end

-- Gets called for every unit that is destroyed (Matching the Filters)
-- @param nId               - Unique ID of the unit
-- @param tUnit             - Unit Object from carbine
-- @param sName             - Name of the Unit
function Mod:BossDestroyed(nId, tUnit, sName)
end

-- Gets called everytime health amount has changed (tracked units only)(Matching the Filters)
-- @param nId               - Unique ID of the unit
-- @param nHealthPercent    - Health Percentage
-- @param sName             - Name of the Unit
-- @param tUnit             - Unit Object from carbine
function Mod:Dummy_HealthChanged(nId, nHealthPercent, sName, tUnit)
end

-- Chat Messages tracked in OnNPCSay, OnNPCYell, OnNPCWhisper, OnDatachron (Matching the Filters)
-- @param sMessage          - Message send
-- @param sSender           - Name of the Sender
-- @param sHandler          - Name of the Chat Event
function Mod:Yell_Msg(sMessage, sSender, sHandler)
end

-- Gets called for every new buff/debuff that is applied on a unit (tracked units only)(Matching the Filters)
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
function Mod:BuffAdd_Moo(nId, nSpellId, sName, tData, sUnitName, nStack, nDuration)
end

-- Gets called for every updated buff/debuff on a unit (tracked units only)(Matching the Filters)
-- @params same as OnBuffAdded
function Mod:HighStack_BuffX(nId, nSpellId, sName, tData, sUnitName, nStack, nDuration)
end

-- Gets called for every removed buff/debuff on a unit (tracked units only)(Matching the Filters)
-- @params same as OnBuffAdded
function Mod:BuffRemove_Twirl(nId, nSpellId, sName, tData, sUnitName)
end

-- Gets called everytime the unit starts casting (tracked units only)(Matching the Filters)
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
function Mod:CastStart_Tsunami(nId, sCastName, tCast, sName, nDuration)
end

-- Gets called everytime the unit ends casting (tracked units only)(Matching the Filters)
-- @params same as OnCastStart
function Mod:CastEnd_Tsunami(nId, sCastName, tCast, sName)
end

function Mod:RandomMethodName(...)
	--[[Adds a unit to the list of tracked units.
		@param key					- Config Key to retrieve Options from. - Optional, if not given all other Optionals must be provided.
		@param tUnit				- Unit Object from carbine
		@param bOnCast				- Track Casts of this unit (boolean)
		@param bOnBuff				- Track Buffs of this unit (boolean)
		@param bOnDebuff			- Track Debuffs of this unit (boolean)
		@param sMark				- Letter in Front of UnitFrame 											- Optional, nil for none
		@param uniqueID																						- Optional, Default: key
		@param sName				- Name of the unit 														- Optional, Default: self.config.units[key].label (or the referred self.L[...])
		@param sColor				- Health Bar Color (ARGB String) 										- Optional, Default: self.config.units[key].color
		@param nPriority			- Priority in UnitFrame and Option Panel (Top to Bottom) 				- Optional, Default: self.config.units[key].priority
		@param bShowUnit			- Boolean whether or not unit should be displayed (boss frames) 		- Optional, Default: self.config.units[key].enable]]
	self:AddUnit("boss_air", tUnit, true, false, false, "A")


	--[[Removes the unit completely.
		@param uniqueID				- The uniqueID the Unit was added with. (reminder: if it wasnt provided, its just the key)]]
	self:RemoveUnit("boss_air")


	--[[Creates a timer bar
		@param key					- Config Key to retrieve Options from.
		@param nDuration			- Duration in Seconds
		@param uniqueID																						- Optional, Default: key
		@param sText				- Bar Text 																- Optional, Default: self.config.timers[key].label (or the referred self.L[...])
		@param sColor				- Bar Color (ARGB String) 												- Optional, Default: self.config.timers[key].color
		@param fHandler				- Callback function 													- Optional
		@param tData				- Data to send on callback 												- Optional]]
	self:AddTimer("timer_midphase", 60)
	self:AddTimer("timer_midphase", 60, "specialUniqueID")

	
	--[[Hides the Timer
		@param uniqueID            	- The uniqueID the Timer was created with. (reminder: if it wasnt provided, its just the key)
		@param bCallback       		- Perform Callback (boolean) 											- Optional, Default: false]]
	self:RemoveTimer("time_midphase")
	self:RemoveTimer("specialUniqueID") --cant use "time_midphase" to remove the timer_midphase, which was created with a uniqueID.


	--[[Shows Castbar
		@param key					- Config Key to retrieve Options from.
		@param tCast            	- Cast Object (typically gained from Mod:OnCastStart())
		@param sName            	- Text shown on the Castbar 											- Optional, Default: self.config.casts[key].label (or the referred self.L[...])
		@param sColor           	- Cast Bar Color (ARGB String) 											- Optional, Default: self.config.casts[key].color ]]
	self:ShowCast("cast_icestorm", tCast)


	--[[Creates an Aura on your screen (like LUI Aura)
		@param key					- Config Key to retrieve Options from.
		@param nDuration       	 	- Duration in Seconds 													- Optional
		@param bShowDuration    	- Show Duration Text													- Optional, Default: true
		@param uniqueID																						- Optional, Default: key
		@param sSprite          	- Sprite of Aura 														- Optional, Default: self.config.auras[key].sprite
		@param sColor				- Sprite Color (ARGB String) 											- Optional, Default: self.config.auras[key].color
		@param fHandler         	- Callback function 													- Optional
		@param tData            	- Data to send on callback 												- Optional]]
	self:ShowAura("aura_twirlyou") --he gains basically all informations from the Options-Panel (aka the Defaults you set.)


	--[[Hides the Aura
		@param uniqueID            	- The uniqueID the Aura was created with. (reminder: if it wasnt provided, its just the key)
		@param bCallback       		- Perform Callback (boolean) 											- Optional, Default: false]]
	self:HideAura("aura_twirlyou")


	--[[Shows a Text Notification on your screen
		@param key					- Config Key to retrieve Options from.
		@param sText            	- Text displayed														- Optional, Default: self.config.alerts[key].label (or the referred self.L[...])
		@param nDuration       	 	- Duration in Seconds 													- Optional, Default: self.config.alerts[key].duration
		@param uniqueID																						- Optional, Default: key
		@param sColor				- Text Color (ARGB String) 												- Optional, Default: self.config.alerts[key].color
		@param sFont				- Text Font 															- Optional, Default: self.core.config.alerts.font]]
	self:ShowAlert("alert_phase2", "USE THIS TEXT INSTEAD OF LABEL!")
	

	--[[Plays a soundfile
		@param key					- Config Key to retrieve Options from.
		@param sound            	- Name of Soundfile (can be either string of filename or number of carbine sound) - Optional, Default:  self.config.sounds[key].file]]
	self:PlaySound("sound_icestorm")


	--[[Draw Icon on top of unit
		@param key					- Config Key to retrieve Options from.
		@param Origin           	- Unit Object
		@param nHeight          	- Height of Icon from bottom
		@param nDuration        	- Duration in seconds before getting removed 							- Optional
		@param bShowOverlay     	- Show Duration Overlay 												- Optional, Default: false
		@param uniqueID																						- Optional, Default: key
		@param sSprite          	- Sprite of Pixie 														- Optional, Default: self.config.icons[key].sprite
		@param nSpriteSize      	- Size of Pixie 														- Optional, Default: self.config.icons[key].size
		@param sColor           	- Text Color (ARGB String) 												- Optional, Default: self.config.icons[key].color
		@param fHandler         	- Callback function 													- Optional
		@param tData            	- Data to send on callback 												- Optional]]
	self:DrawIcon("icon_twirl", tUnit1, 20, 10, nil, "uniqueID"..tUnit1:GetSomethingUniqueFromThisUnit())
	self:DrawIcon("icon_twirl", tUnit1, 20, 10, nil, "uniqueID"..tUnit2:GetSomethingUniqueFromThisUnit()) --show these icons for 10sec


	--[[Removes Icon from Screen
		@param uniqueID            	- The uniqueID the Icon was created with. (reminder: if it wasnt provided, its just the key)
		@param bCallback       		- Perform Callback (boolean) 											- Optional, Default: false]]
	self:RemoveIcon("uniqueID"..tUnit2:GetSomethingUniqueFromThisUnit())


	--[[Draw Pixie on top of unit or coordinate (Basically a Icon with rotation and offset to the front of a unit.)
		@param key					- Config Key to retrieve Options from. (key inside self.config.icons)
		@param Origin           	- Unit Object / UnitId or Coordinates
		@param nHeight          	- Height of Icon from bottom
		@param nDistance			- Offset to the front of origin 
		@param nRotation			- Rotation in degrees
		@param nDuration        	- Duration in seconds before getting removed 							- Optional
		@param uniqueID																						- Optional, Default: key
		@param sSprite          	- Sprite of Pixie 														- Optional, Default: self.config.icons[key].sprite
		@param nSpriteSize      	- Size of Pixie 														- Optional, Default: self.config.icons[key].size
		@param sColor           	- Text Color (ARGB String) 												- Optional, Default: self.config.icons[key].color
		@param fHandler         	- Callback function 													- Optional
		@param tData            	- Data to send on callback 												- Optional]]
	self:DrawPixie("icon_twirl", tUnit1, 20, nil, nil, nil, nil, nil, nil, nil, "Unit1_PixieGotRemoved", {MY_AWESOME_PARAMETER}) --the callback will also be performed if the pixie would time out.


	--[[Removes Pixie from Screen
		@param uniqueID            	- The uniqueID the Pixie was created with. (reminder: if it wasnt provided, its just the key)
		@param bCallback       		- Perform Callback (boolean)											- Optional, Default: false]]
	self:RemovePixie("icon_twirl", true)


	--[[Draws a polyon on the ground at unit or position
		@param key					- Config Key to retrieve Options from. (key inside self.config.lines)
		@param Origin           	- Unit Object / UnitId or Coordinates
		@param nRadius          	- Radius of Polygon
		@param nSides           	- Amount of Sides of the Polygon
		@param nRotation			- Rotation of the Polygon in Degrees 									- Optional, Default: 0
		@param nDuration        	- Duration in seconds before getting removed 							- Optional
		@param uniqueID																						- Optional, Default: key
		@param nWidth           	- Thickness 															- Optional, Default: self.config.lines[key].thickness
		@param sColor           	- Text Color (ARGB String) 												- Optional, Default: self.config.lines[key].color
		@param fHandler         	- Callback function 													- Optional
		@param tData            	- Data to send on callback 												- Optional]]
	self:DrawPolygon("line_mycircle", GameLib.GetPlayerUnit(), 5, 8)


	--[[Removes Polygon from Screen
		@param uniqueID            	- The uniqueID the Polygon was created with. (reminder: if it wasnt provided, its just the key)
		@param bCallback       		- Perform Callback (boolean) 											- Optional, Default: false]]
	self:RemovePolygon("line_mycircle")


	--[[Draws a line from unit/coordinate into certain direction (unit facing/north + fixed rotation)
		@param key					- Config Key to retrieve Options from. (key inside self.config.lines)
		@param Origin           	- Unit Object / UnitId or Coordinates
		@param nLength				- Length of the Line
		@param nRotation			- Rotation in degrees 													- Optional, Default: 0
		@param nOffset				- Offset from Origin (in draw-direction) 								- Optional, Default: 0
		@param tVectorOffset		- Offset to Origin (table or vector3) (gets rotated aswell) 			- Optional
		@param nDuration			- Duration in seconds before getting removed 							- Optional
		@param nNumberOfDot			- Amount of dots 														- Optional, Default: 1 (Whole Line)
		@param uniqueID																						- Optional, Default: key
		@param nWidth				- Thickness 															- Optional, Default: self.config.lines[key].thickness
		@param sColor				- Text Color (ARGB String) 												- Optional, Default: self.config.lines[key].color
		@param fHandler				- Callback function 													- Optional
		@param tData				- Data to send on callback 												- Optional]]
	self:DrawLine("line_bossbackline", tBossUnit, 20, 180, 3)


	--[[Removes Lines from Screen
		@param uniqueID          	- The uniqueID the Line was created with. (reminder: if it wasnt provided, its just the key)
		@param bCallback        	- Perform Callback (boolean) 											- Optional, Default: false]]
	self:RemoveLine("line_bossbackline")


	--[[Draws a line in between two origins (unit/coordinate)
		@param key					- Config Key to retrieve Options from. (key inside self.config.lines)
		@param FromOrigin       	- Unit Object / UnitId or Coordinates
		@param ToOrigin         	- Unit Object / UnitId or Coordinates									- Optional, Default: PlayerUnit (nil)
		@param nDuration			- Duration in seconds before getting removed 							- Optional
		@param nNumberOfDot			- Amount of dots 														- Optional, Default: 1 (Whole Line)
		@param uniqueID																						- Optional, Default: key
		@param nWidth				- Thickness 															- Optional, Default: self.config.lines[key].thickness
		@param sColor				- Text Color (ARGB String) 												- Optional, Default: self.config.lines[key].color
		@param fHandler				- Callback function 													- Optional
		@param tData				- Data to send on callback 												- Optional]]
	self:DrawLineBetween("line_twirltotomb", tUnitTwirl, tUnitTomb1, 10, nil, "LineToTomb1")
	self:DrawLineBetween("line_twirltotomb", tUnitTwirl, tUnitTomb2, 10, nil, "LineToTomb2")


	--[[Removes Lines from Screen
		@param uniqueID             - The uniqueID the Line was created with. (reminder: if it wasnt provided, its just the key)
		@param bCallback        	- Perform Callback (boolean) 											- Optional, Default: false]]
	self:RemoveLineBetween("LineToTomb1")


	--[[Returns Icon/Pixie/Polygon/Line/LineBetween according to the uniqueID
		@param uniqueID             - The uniqueID the Line was created with. (reminder: if it wasnt provided, its just the key)]]
	local awesomeDrawing = self:GetDraw("line_mycircle")


	--[[Compute the distance between two origins.
		@param FromOrigin       	- Unit Object / UnitId or Coordinates
		@param ToOrigin         	- Unit Object / UnitId or Coordinates 									- Optional, Default: PlayerUnit (nil)
		@return 					- The distance in meter.]]
	self:GetDistance(GameLib.GetTargetUnit(), nil)
end

Mod:new() --THIS IS IMPORTANT DONT FORGET! (This should be one of the last lines in every encounter.)