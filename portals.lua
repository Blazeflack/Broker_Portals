if not LibStub then return end

local dewdrop = LibStub("Dewdrop-2.0", true)
local icon = LibStub("LibDBIcon-1.0")

local math_floor = math.floor

local GetContainerItemCooldown = GetContainerItemCooldown
local GetContainerItemInfo = GetContainerItemInfo
local GetContainerItemLink = GetContainerItemLink
local GetContainerNumSlots = GetContainerNumSlots
local GetBindLocation = GetBindLocation
local GetInventoryItemCooldown = GetInventoryItemCooldown
local GetInventoryItemLink = GetInventoryItemLink
local GetSpellInfo = GetSpellInfo
local GetSpellName = GetSpellName

local L = L

-- IDs of items usable for transportation
local items = {
  -- Dalaran rings
  40586, -- Band of the Kirin Tor
  48954, -- Etched Band of the Kirin Tor
  48955, -- Etched Loop of the Kirin Tor
  48956, -- Etched Ring of the Kirin Tor
  48957, -- Etched Signet of the Kirin Tor
  45688, -- Inscribed Band of the Kirin Tor
  45689, -- Inscribed Loop of the Kirin Tor
  45690, -- Inscribed Ring of the Kirin Tor
  45691, -- Inscribed Signet of the Kirin Tor
  44934, -- Loop of the Kirin Tor
  44935, -- Ring of the Kirin Tor
  40585, -- Signet of the Kirin Tor
  -- Engineering Gadgets
  30542, -- Dimensional Ripper - Area 52
  18984, -- Dimensional Ripper - Everlook
  18986, -- Ultrasafe Transporter: Gadgetzan
  30544, -- Ultrasafe Transporter: Toshley's Station
  48933, -- Wormhole Generator: Northrend
  -- Seasonal items
  37863, -- Direbrew's Remote
  21711, -- Lunar Festival Invitation
  -- Miscellaneous
  46874, -- Argent Crusader's Tabard
  32757, -- Blessed Medallion of Karabor
  35230  -- Darnarian's Scroll of Teleportation
}

-- IDs of items usable instead of hearthstone
local scrolls = {
  6948,  -- Hearthstone
  28585,  -- Ruby Slippers
  44315, -- Scroll of Recall III
  44314, -- Scroll of Recall II
  37118 -- Scroll of Recall
}

obj = LibStub:GetLibrary("LibDataBroker-1.1"):NewDataObject("Broker_Portals", {
	type = "data source",
	text = "Portals",
	icon = "Interface\\Icons\\INV_Misc_Rune_06",
})
local obj = obj
local methods	= {}
local portals	= nil
local frame = CreateFrame("frame")

frame:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end)
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("SKILL_LINES_CHANGED")


local function pairsByKeys(t)
	local a = {}
	for n in pairs(t) do
		table.insert(a, n)
	end
	table.sort(a)
	
	local i = 0
	local iter = function ()
		i = i + 1
		if a[i] == nil then
			return nil
		else
			return a[i], t[a[i]]
		end
	end
	return iter
end

local function findSpell(spellName)
	local i = 1
	while true do
		local s = GetSpellName(i, BOOKTYPE_SPELL)
		if not s then
			break
		end

		if s == spellName then
			return i
		end

		i = i + 1
	end
end

-- returns true, if player has item with given ID in inventory or bags and it's not on cooldown
local function hasItem(itemID)
  local item, found, id
  -- scan inventory
  for slotId = 1, 19 do
    item = GetInventoryItemLink("player", slotId)
    if item then
      found, _, id = item:find("^|c%x+|Hitem:(%d+):.+")
      if found and tonumber(id) == itemID then
        if GetInventoryItemCooldown("player", slotId) ~= 0 then
          return false
        else
          return true
        end
      end
    end
  end
  -- scan bags
	for bag = 0, 4 do
    for slot = 1, GetContainerNumSlots(bag) do
      item = GetContainerItemLink(bag, slot)
      if item then
        found, _, id = item:find("^|c%x+|Hitem:(%d+):.+")
        if found and tonumber(id) == itemID then
          if GetContainerItemCooldown(bag, slot) ~= 0 then
            return false
          else
            return true
          end
        end
      end
    end
  end

	return false
end

local function SetupSpells()
	local spells = {
		Alliance = {
			3561,  --TP:Stormwind
			3562,  --TP:Ironforge
			3565,  --TP:Darnassus
			32271, --TP:Exodar
			49359, --TP:Theramore
			33690, --TP:Shattrath
			53140, --TP:Dalaran
			10059, --P:Stormwind
			11416, --P:Ironforge
			11419, --P:Darnassus
			32266, --P:Exodar
			49360, --P:Theramore
			33691, --P:Shattrath
			53142  --P:Dalaran
		},
		Horde = {
			3563,  --TP:Undercity
			3566,  --TP:Thunder Bluff
			3567,  --TP:Orgrimmar
			32272, --TP:Silvermoon
			49358, --TP:Stonard
			35715, --TP:Shattrath
			53140, --TP:Dalaran
			11418, --P:Undercity
			11420, --P:Thunder Bluff
			11417, --P:Orgrimmar
			32267, --P:Silvermoon
			49361, --P:Stonard
			35717, --P:Shattrath
			53142  --P:Dalaran
		}
	}
	
	local _, class = UnitClass("player")
	if class == "MAGE" then
		portals = spells[UnitFactionGroup("player")]
	elseif class == "DEATHKNIGHT" then
		portals = {
			50977 --Death Gate
			}
	elseif class == "DRUID" then
		portals = {
			18960 --TP:Moonglade
			}
	elseif class == "SHAMAN" then
		portals = {
			556 --Astral Recall
			}
	end

	spells = nil
end

local function UpdateSpells()
	if not portals then
		SetupSpells()
	end
	
	if portals then
		for _,unTransSpell in ipairs(portals) do
			
			local spell, _, spellIcon = GetSpellInfo(unTransSpell)
			local spellid = findSpell(spell)
			
			if spellid then	
				methods[spell] = {
					spellid = spellid,
					text = spell,
					spellIcon = spellIcon,
					secure = {
						type = 'spell',
						spell = spell,
					}
				}
			end
		end
	end
end

local function UpdateIcon(icon)
	obj.icon = icon
end

local function GetHearthCooldown()
	local cooldown, startTime, duration

  for bag = 0, 4 do
    for slot = 1, GetContainerNumSlots(bag) do
      local item = GetContainerItemLink(bag, slot)
      if item then
        if item:find("^|c%x+|Hitem:6948:.+") then
          startTime, duration = GetContainerItemCooldown(bag, slot)
          cooldown = duration - (GetTime() - startTime)
          cooldown = cooldown / 60
          if cooldown <= 0 then
            return L["READY"]
          end
          cooldown = math_floor(cooldown)
          return cooldown.." "..L["MIN"]
        end
      end
    end
  end
  
  return L["N/A"]
end

local function ShowHearthstone()
	local text, secure, icon, name
  local bindLoc = GetBindLocation()

  for _, itemID in ipairs(scrolls) do
    if hasItem(itemID) then
      name, _, _, _, _, _, _, _, _, icon = GetItemInfo(itemID)
      text = L["INN"].." "..bindLoc
      secure = {
        type = 'item',
        item = name,
      }
      break
    end
  end

	if secure ~= nil then
		dewdrop:AddLine(
			'text', text,
			'secure', secure,
			'icon', icon,
			'func', function() UpdateIcon(icon) end,
			'closeWhenClicked', true
		)
		dewdrop:AddLine()
	end
end

local function ShowOtherItems()
  local secure, icon, name
  local i = 0

  for _, itemID in ipairs(items) do
    if hasItem(itemID) then
      name, _, _, _, _, _, _, _, _, icon = GetItemInfo(itemID)
      secure = {
        type = 'item',
        item = name,
      }

      dewdrop:AddLine(
        'text', name,
        'secure', secure,
        'icon', icon,
        'func', function() UpdateIcon(icon) end,
        'closeWhenClicked', true
      )
      i = i + 1
    end
  end
  if i > 0 then
    dewdrop:AddLine()
  end
end

local function ToggleMinimap()
	local hide = not PortalsDB.minimap.hide
	PortalsDB.minimap.hide = hide
	if hide then
		icon:Hide("Broker_Portals")
	else
		icon:Show("Broker_Portals")
	end
end

local function UpdateMenu()
	dewdrop:AddLine(
		'text', 	"Broker_Portals",
		'isTitle', 	true
	)
	dewdrop:AddLine()

	for k,v in pairsByKeys(methods) do
		if v.secure then
			dewdrop:AddLine(
				'text', v.text,
				'secure',	v.secure,
				'icon', v.spellIcon,
				'func', function() UpdateIcon(v.spellIcon) end,
				'closeWhenClicked', true
			)
		end
	end
	
	dewdrop:AddLine()
	
	ShowHearthstone()
  ShowOtherItems()
	
	dewdrop:AddLine(
		'text', L["ATT_MINIMAP"],
		'checked', not PortalsDB.minimap.hide,
		'func', function() ToggleMinimap() end,
		'closeWhenClicked', true
	)
	
	dewdrop:AddLine(
		'text', CLOSE,
		'tooltipTitle', CLOSE,
		'tooltipText', CLOSE_DESC,
		'closeWhenClicked', true
	)
end

function frame:PLAYER_LOGIN()
	-- PortalsDB.minimap is there for smooth upgrade of SVs from old version
	if (not PortalsDB) or (PortalsDB.version ~= 1) then
		PortalsDB = {}
		PortalsDB.minimap = {}
		PortalsDB.minimap.hide = false
		PortalsDB.version = 1
	end
	if icon then
		icon:Register("Broker_Portals", obj, PortalsDB.minimap)
	end

	self:UnregisterEvent("PLAYER_LOGIN")
end

function frame:SKILL_LINES_CHANGED()
	UpdateSpells()
end

local function getReagentCount(name)
	local count = 0
  for bag = 0, 4 do
    for slot = 1, GetContainerNumSlots(bag) do
      local item = GetContainerItemLink(bag, slot)
      if item then
        if item:find(name) then
          local _, itemCount = GetContainerItemInfo(bag, slot)
          count = count + itemCount
        end
      end
    end
  end
	
	return count
end

-- All credit for this func goes to Tekkub and his picoGuild!
local function GetTipAnchor(frame)
		local x,y = frame:GetCenter()
		if not x or not y then return "TOPLEFT", "BOTTOMLEFT" end
		local hhalf = (x > UIParent:GetWidth()*2/3) and "RIGHT" or (x < UIParent:GetWidth()/3) and "LEFT" or ""
		local vhalf = (y > UIParent:GetHeight()/2) and "TOP" or "BOTTOM"
		return vhalf..hhalf, frame, (vhalf == "TOP" and "BOTTOM" or "TOP")..hhalf
end

function obj.OnClick(self, button)
  GameTooltip:Hide() 
	if button == "RightButton" then
		dewdrop:Open(self, "children", function() UpdateMenu() end)
	end
end

function obj.OnLeave() 
	GameTooltip:Hide() 
end

function obj.OnEnter(self)
 	GameTooltip:SetOwner(self, "ANCHOR_NONE")
	GameTooltip:SetPoint(GetTipAnchor(self))
	GameTooltip:ClearLines()

	GameTooltip:AddLine("Broker Portals")
	GameTooltip:AddDoubleLine(L["RCLICK"], L["SEE_SPELLS"], 0.9, 0.6, 0.2, 0.2, 1, 0.2)
  GameTooltip:AddLine(" ")
  GameTooltip:AddDoubleLine(L["HEARTHSTONE"]..": "..GetBindLocation(), GetHearthCooldown(), 0.9, 0.6, 0.2, 0.2, 1, 0.2)
	GameTooltip:AddLine(" ")
	GameTooltip:AddDoubleLine(L["TP_P"], getReagentCount(L["TP_RUNE"]).."/"..getReagentCount(L["P_RUNE"]), 0.9, 0.6, 0.2, 0.2, 1, 0.2)

	GameTooltip:Show()
end

-- slashcommand definition
SlashCmdList["BROKER_PORTALS"] = function() ToggleMinimap() end
SLASH_BROKER_PORTALS1 =  "/portals"
