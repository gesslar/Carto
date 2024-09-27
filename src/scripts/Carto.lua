-- Letting Mudlet know that this is a mapper script
mudlet = mudlet or {};
mudlet.mapper_script = true

-- This is the name of this script, which may be different to the package name
-- which is why we want to have a specific identifier for events that only
-- concern this script and not the package as a whole, if it is included
-- in other packages.
local script_name = "Carto"

---@class Carto
---@field config table
---@field default table
---@field prefs table
---@field walking boolean
---@field info table
---@field event_handlers table
---@field glyphs table
---@field terrain table
---@field exits table
---@field stubs table
---@field vectors table
Carto = Carto or {
  config = {
    name = script_name,              -- Name of the script
    package_name = "__PKGNAME__", -- Name of the package
    package_path = getMudletHomeDir() .. "/__PKGNAME__/",
    prefix = f[[{script_name}.]],           -- Prefix for handlers
    preferences_file = f[[{script_name}.Preferences.lua]], -- Name of the preferences file
    speed_walk_fast = 0.5, -- Speedwalk fast delay
    speed_walk_slow = 3.0, -- Speedwalk slow delay
  },
  default = {
    speedwalk_delay = 0.0,   -- Speedwalk delay
    speedwalk_delay_min = 0.0, -- Minimum speedwalk delay
    gmcp = {
      -- The event that triggers the Mapper
      event = "gmcp.Room.Info",
      -- Whether to expect coordinates from the GMCP event
      expect_coordinates = false,
      -- Whether to expect a hash or vnum from the GMCP event
      expect_hash = true,
      -- The property names we can expect from the GMCP event
      properties = {
        hash = "hash",
        vnum = "vnum",
        area = "area",
        name = "name",
        environment = "environment",
        symbol = "symbol",
        exits = "exits",
        coords = "coords",
        doors = "doors",
        type = "type",
        subtype = "subtype",
        icon = "icon",
      }
    }
  },
  prefs = {
    recalls = {}, -- Recall points for rooms
  },
  walking = false,
  info = {
    current = nil,
    previous = nil,
  },
  event_handlers = {}, -- Event handlers
  -- Glyphs for room environments
  glyphs = {
    bank    = utf8.escape("%x{1F3E6}"),
    shop    = utf8.escape("%x{1F4B0}"),
    food    = utf8.escape("%x{1F956}"),
    drink   = utf8.escape("%x{1F377}"),
    library = utf8.escape("%x{1F4D6}"),
    tavern  = utf8.escape("%x{1F378}"),
    inn     = utf8.escape("%x{1F3EB}"),
    storage = utf8.escape("%x{1F4E6}"),
  },
  terrain = {
    types = {
      ["default"]       = { id = 500, color = table.deepcopy(color_table["gainsboro"]) },
      ["beach"]         = { id = 501, color = table.deepcopy(color_table["navajo_white"]) },
      ["desert"]        = { id = 502, color = table.deepcopy(color_table["sandy_brown"]) },
      ["dirt road"]     = { id = 503, color = table.deepcopy(color_table["saddle_brown"]) },
      ["forest"]        = { id = 504, color = table.deepcopy(color_table["forest_green"]) },
      ["grass"]         = { id = 505, color = table.deepcopy(color_table["pale_green"]) },
      ["grassy"]        = { id = 505, color = table.deepcopy(color_table["pale_green"]) },
      ["indoor"]        = { id = 506, color = table.deepcopy(color_table["brown"]) },
      ["mountain"]      = { id = 507, color = table.deepcopy(color_table["gray"]) },
      ["mud"]           = { id = 508, color = table.deepcopy(color_table["brown"]) },
      ["path"]          = { id = 509, color = table.deepcopy(color_table["tan"]) },
      ["road"]          = { id = 510, color = table.deepcopy(color_table["sienna"]) },
      ["sand"]          = { id = 511, color = table.deepcopy(color_table["pale_goldenrod"]) },
      ["snow"]          = { id = 512, color = table.deepcopy(color_table["snow"]) },
      ["swamp"]         = { id = 513, color = table.deepcopy(color_table["dark_olive_green"]) },
      ["water"]         = { id = 514, color = table.deepcopy(color_table["steel_blue"]) },
      ["tunnels"]       = { id = 515, color = table.deepcopy(color_table["brown"]) },
      ["sandy"]         = { id = 516, color = table.deepcopy(color_table["navajo_white"]) },
      ["rocky"]         = { id = 518, color = table.deepcopy(color_table["gray"]) },
      ["impassable"]    = { id = 519, color = table.deepcopy(color_table["dark_green"]) },
      ["dusty"]         = { id = 520, color = table.deepcopy(color_table["brown"]) },
      ["shallow water"] = { id = 521, color = table.deepcopy(color_table["steel_blue"]) },
      ["deep water"]    = { id = 522, color = table.deepcopy(color_table["midnight_blue"]) },
    },
    -- Terrain types we will never path through. Using lockRoom() to prevent
    -- pathing through these terrain types.
    prevent = {
      522, -- Deep Water
    },
    -- Terrain types we will avoid when pathing. Using setRoomWeight() to avoid
    -- these terrain types, unless we have no other choice.
    avoid = {
      [514] = 100, -- Water
    },
  },
  exits = {
    -- Mapping of exit abbreviations to full names
    map = {
      n = "north",      ne = "northeast", nw = "northwest", e = "east",
      w = "west",       s = "south",      se = "southeast", sw = "southwest",
      u = "up",         d = "down",       ["in"] = "in",    out = "out",
      ed = "eastdown",  eu = "eastup",    nd = "northdown", nu = "northup",
      sd = "southdown", su = "southup",   wd = "westdown",  wu = "westup",
    },
    -- Mapping of full exit names to abbreviations
    reverse = {
      north = "n",      northeast = "ne", northwest = "nw", east = "e",
      west = "w",       south = "s",      southeast = "se", southwest = "sw",
      up = "u",         down = "d",       ["in"] = "in",    out = "out",
      eastdown = "ed",  eastup = "eu",    northdown = "nd", northup = "nu",
      southdown = "sd", southup = "su",   westdown = "wd",  westup = "wu",
    },
      -- Mapping of direction names to their numeric representations and vice versa
    stubs = {
      north = 1,        northeast = 2,      northwest = 3,      east = 4,
      west = 5,         south = 6,          southeast = 7,      southwest = 8,
      up = 9,           down = 10,          ["in"] = 11,        out = 12,
      northup = 13,     southdown = 14,     southup = 15,       northdown = 16,
      eastup = 17,      westdown = 18,      westup = 19,        eastdown = 20,
      [1] = "north",    [2] = "northeast",  [3] = "northwest",  [4] = "east",
      [5] = "west",     [6] = "south",      [7] = "southeast",  [8] = "southwest",
      [9] = "up",       [10] = "down",      [11] = "in",        [12] = "out",
      [13] = "northup", [14] = "southdown", [15] = "southup",   [16] = "northdown",
      [17] = "eastup",  [18] = "westdown",  [19] = "westup",    [20] = "eastdown",
    },
    vectors = {
      name = {
        north     = { 0, 1, 0 },   south     = { 0, -1, 0 },
        east      = { 1, 0, 0 },   west      = { -1, 0, 0 },
        northwest = { -1, 1, 0 },  northeast = { 1, 1, 0 },
        southwest = { -1, -1, 0 }, southeast = { 1, -1, 0 },
        up        = { 0, 0, 1 },   down      = { 0, 0, -1 },
        ["in"]    = { 0, 0, 0 },   out       = { 0, 0, 0 },
        northup   = { 0, 1, 1 },   southdown = { 0, -1, -1 },
        southup   = { 0, -1, 1 },  northdown = { 0, 1, -1 },
        eastup    = { 1, 0, 1 },   westdown  = { -1, 0, -1 },
        westup    = { -1, 0, 1 },  eastdown  = { 1, 0, -1 },
      },
      number = {
        [1] = { 0, 1, 0 },    [2] = { 1, 1, 0 },    [3] = { -1, 1, 0 },  [4] = { 1, 0, 0 },
        [5] = { -1, 0, 0 },   [6] = { 0, -1, 0 },   [7] = { 1, -1, 0 },  [8] = { -1, -1, 0 },
        [9] = { 0, 0, 1 },   [10] = { 0, 0, -1 },  [11] = { 0, 0, 0 },  [12] = { 0, 0, 0 },
        [13] = { 0, 1, 1 },   [14] = { 0, -1, -1 }, [15] = { 0, -1, 1 }, [16] = { 0, 1, -1 },
        [17] = { 1, 0, 1 },   [18] = { -1, 0, -1 }, [19] = { -1, 0, 1 }, [20] = { 1, 0, -1 },
      }
    }
  },
  tags = {
    mapper = { "%s", table.deepcopy(color_table["orange_red"]), table.deepcopy(color_table["orange"]  ) },
    warning = { "%s", table.deepcopy(color_table["orange"]), table.deepcopy(color_table["orange_red"]) },
    error = { "%s", table.deepcopy(color_table["red"]), table.deepcopy(color_table["orange_red"]) },
    info = { "%s", table.deepcopy(color_table["chartreuse"]), table.deepcopy(color_table["olive_drab"]) },
  },
  speedwalk_path = {},     -- Speedwalk path
  move_tracking = {},      -- Move tracking for room movements
  walk_timer = nil,        -- Walk timer
  walk_timer_name = nil,   -- Walk timer name
  walk_step = nil,         -- The next room id for the speedwalk
}

-- ----------------------------------------------------------------------------
-- Preferences
-- ----------------------------------------------------------------------------
function Carto:LoadPreferences()
  local path = self.config.package_path .. self.config.preferences_file
  local defaults = self.default

  if io.exists(path) then
    local prefs = {}
    table.load(path, prefs)
    prefs = table.update(defaults, prefs)
    self.prefs = prefs
  else
    self.prefs = defaults
  end
  if not self.prefs.speedwalk_delay then
    self.prefs.speedwalk_delay = self.default.speedwalk_delay
  end
  if not self.prefs.speedwalk_delay_min then
    self.prefs.speedwalk_delay_min = self.default.speedwalk_delay_min
  end
  if not self.prefs.gmcp then
    self.prefs.gmcp = self.default.gmcp
  end

  if not self.prefs.recalls then
    self.prefs.recalls = {}
  end
  self.prefs = self.default
  self.prefs.recalls = {}
end

function Carto:SavePreferences()
  local path = self.config.package_path .. self.config.preferences_file
  table.save(path, self.prefs)
end

function Carto:SetPreference(key, value)
  if not self.prefs then
    self.prefs = {}
  end

  if not self.default[key] then
    cecho("Unknown preference " .. key .. "\n")
    return
  end

  if key == "speedwalk_delay" then
    value = tonumber(value)
  elseif key == "speedwalk_delay_min" then
    value = tonumber(value)
  else
    cecho("Unknown preference " .. key .. "\n")
    return
  end

  self.prefs[key] = value
  self:SavePreferences()
  self:LoadPreferences()

  cecho("Preference " .. key .. " set to " .. value .. ".\n")
end


-- ----------------------------------------------------------------------------
-- Setup and Teardown
-- ----------------------------------------------------------------------------

---@param event string
---@param package string
function Carto:Setup(event, package)
  if package and package ~= self.config.package_name then
    return
  end

  if not table.index_of(getPackages(), "Helper") then
    cecho(f"<gold><b>{self.config.name} is installing dependent <b>Helper</b> package.\n")
    installPackage(
      "https://github.com/gesslar/Helper/releases/latest/download/Helper.mpackage"
    )
  end

  self:LoadPreferences()

  -- Set custom environment colors for terrain types
  for _, data in pairs(self.terrain.types) do
    ---@diagnostic disable-next-line: deprecated
    local r, g, b = unpack(data.color)
    setCustomEnvColor(data.id, r, g, b, 255)
  end

  -- Register event handlers
  local handler

  self.walk_timer_name = self.config.prefix .. "walk_timer"

  for tag_name, tag_info in pairs(self.tags) do
    if tag_name == string.lower(self.config.name) then
      tag_info[1] = string.format(tag_info[1], string.lower(self.config.name))
    else
      tag_info[1] = string.lower(tag_name)
    end
  end

  -- We need to add the gmcp one now based on the preferences
  if self.prefs.gmcp.event then
    registerNamedEventHandler(self.config.name, self.prefs.gmcp.event, self.prefs.gmcp.event, function(...) self:EventHandler(...) end)
  end

  gmod.enableModule(self.config.name, "Room")

  if event == "sysInstall" then
    tempTimer(1, function()
      echo("\n")
      cecho("<" .. self.help_styles.h1 .. ">Welcome to <b>" .. self.config.name .. "</b>!<reset>\n")
      echo("\n")
      helper.print({
        text = self.help.topics.usage,
        styles = self.help_styles
      })
    end)
  end
end

---@param event string
---@param ... any
function Carto:Teardown(event, ...)
  -- Kill event handlers
  deleteAllNamedEventHandlers(self.config.name)
  self:ResetWalking(false, "Script has been disabled.")
end

-- ----------------------------------------------------------------------------
-- Event Handlers
-- ----------------------------------------------------------------------------

function Carto:SetupEventHandlers()
  self.event_handlers = {
    -- System events that we want to handle
    "sysLoadEvent",
    "sysConnectionEvent",
    "sysUninstall",
    "sysDisconnectionEvent",
    "sysExitEvent",
  }

  local registered_handlers = getNamedEventHandlers(self.config.name) or {}
  -- Register persistent event handlers
  for _, event in ipairs(self.event_handlers) do
    local handler = self.config.name .. "." .. event
    if not registered_handlers[handler] then
      local result, err = registerNamedEventHandler(self.config.name, handler, event,
        function(...) self:EventHandler(...) end)
      if not result then
        cecho("<orange_red>Failed to register event handler for " .. event .. "\n")
      end
    end
  end
end

-- GMCP events that we want to handle
---@param event string
---@param ... any
function Carto:EventHandler(event, ...)
  if event == "sysInstall" then
    self:Install(event, ...)
  elseif event == "sysLoadEvent" or event == "sysConnectionEvent" then
    self:Setup(event, ...)
  elseif event == "sysDisconnectionEvent" then
    self:Disconnect(event, ...) -- no args
  elseif event == "sysExitEvent" then
    self:Teardown(event, ...)   -- no args
  elseif event == self.prefs.gmcp.event then
    self:Move(event, ...)       -- arg1 is the GMCP package name
  end
end


-- sysInstall must be on its own, outside of the event_handlers
-- since it will be called during the install process.
registerNamedEventHandler(Carto.config.name, "Mapper:Install", "sysInstall", function(...) Carto:EventHandler(...) end,
  true)
Carto:SetupEventHandlers()

-- ----------------------------------------------------------------------------
-- Utility Functions
-- ----------------------------------------------------------------------------

---@param str string
---@param delimiter string
---@return table
function Carto:Explode(str, delimiter)
  local result = {}
  local pattern = "([^" .. delimiter .. "]+)" -- This pattern correctly matches non-delimiter characters

  for match in str:gmatch(pattern) do
    table.insert(result, match)
  end

  return result
end

---@param event string
---@param ... any
function Carto:Disconnect(event, ...)
  self:ResetWalking(true, "Disconnected from the mud.")
end

-- ----------------------------------------------------------------------------
-- Install/Uninstall
-- ----------------------------------------------------------------------------

---@param event string
---@param package string
function Carto:Install(event, package)
  if package ~= self.config.package_name then
    return
  end

  if table.contains(getPackages(), "generic_mapper") then
    echo("Uninstalling package: generic_mapper\n")
    -- uninstallPackage("generic_mapper")
    if(table.contains(getPackages(), "generic_mapper")) then
      echo("Could not uninstall generic_mapper.\n")
      echo("Please uninstall it manually and restart Mudlet.\n")
      return
    end
  end

  deleteNamedEventHandler(self.config.name, "Mapper:Install")

  self:Setup(event, package)
end

---@param event string
---@param package string
function Carto:Uninstall(event, package)
  if package ~= self.config.package_name then
    return
  end

  if self.walking then
    echo("Resetting walking.\n")
  end
  self:ResetWalking(true, "Script has been uninstalled.")
  self:Teardown(event, package)

  echo(self.config.name .. " uninstalled.\n")
end

-- ----------------------------------------------------------------------------
-- Move
--
-- This function is called when the GMCP package is received. It updates the
-- current room information and adds or updates the room in the map.
--
-- It sets the previous room to the current room and updates the current room
-- with the new GMCP data. It then adds or updates the room in the map and
-- updates the exits.
-- ----------------------------------------------------------------------------

---@param gmcp_package string
function Carto:Move(event, gmcp_package)
  local gmcp_table = self:TableFromPackage(gmcp_package) or {}

  self.info.previous = self.info.current

  if self.prefs.gmcp.expect_hash then
    if not gmcp_table[self.prefs.gmcp.properties.hash] then return end
  else
    if not gmcp_table[self.prefs.gmcp.properties.vnum] then return end
  end

  self.info.current = {
    hash = gmcp_table[self.prefs.gmcp.properties.hash],
    area = gmcp_table[self.prefs.gmcp.properties.area],
    name = gmcp_table[self.prefs.gmcp.properties.name],
    environment = gmcp_table[self.prefs.gmcp.properties.environment],
    symbol = gmcp_table[self.prefs.gmcp.properties.symbol],
    exits = table.deepcopy(gmcp_table[self.prefs.gmcp.properties.exits]),
    doors = table.deepcopy(gmcp_table[self.prefs.gmcp.properties.doors]),
    type = gmcp_table[self.prefs.gmcp.properties.type],
    subtype = gmcp_table[self.prefs.gmcp.properties.subtype],
    icon = gmcp_table[self.prefs.gmcp.properties.icon],
  }

  self.info.current.custom = gmcp_table[self.prefs.gmcp.properties.custom] or {}

  if self.prefs.gmcp.expect_coordinates then
    if gmcp_table[self.prefs.gmcp.properties.coords] then
      self.info.current.coords = gmcp_table[self.prefs.gmcp.properties.coords]
    else
      if gmcp_table.x and gmcp_table.y and gmcp_table.z then
        self.info.current.coords = { gmcp_table.x, gmcp_table.y, gmcp_table.z }
      else
        self.info.current.coords = self:CalculateCoordinates()
      end
    end
  else
    self.info.current.coords = self:CalculateCoordinates()
  end

  local room_id = self:AddOrUpdateRoom(self.info.current)
  if room_id == -1 then
    echo("Failed to add room.\n")
    return
  end

  self:UpdateExits(room_id)

  centerview(room_id)

  self.info.current.room_id = room_id

  -- Keep track of the path we're walking so we can detect if we've veered
  -- off the path. Only record the move if we're actually walking.
  if self.walking then
    if next(self.speedwalk_path) then
      -- If the room we've entered is the room we're expected to be in,
      -- then record the move for later comparison.
      if self.walk_step == self.info.current.room_id then
        if not next(self.move_tracking) then
          self.move_tracking = {}
        end

        table.insert(self.move_tracking, {
          prev_room_id = self.info.previous.room_id,
          current_room_id = self.info.current.room_id,
        })
      end
    end
  end

  updateMap()

  local current_room_id, previous_room_id
  if self.info.current and self.info.current.room_id then
    current_room_id = self.info.current.room_id
  end
  if self.info.previous and self.info.previous.room_id then
    previous_room_id = self.info.previous.room_id
  end

  raiseEvent("onMoveMap", current_room_id)

  -- Take the next step in the speedwalk
  if self.walking then
    resumeNamedTimer(self.config.name, self.walk_timer_name)
  end
end

-- ----------------------------------------------------------------------------
-- AddOrUpdateRoom
--
-- This function adds or updates a room in the map based on the provided room
-- information. It handles both hash and vnum-based room identification.
-- ----------------------------------------------------------------------------

---@param info table
function Carto:AddOrUpdateRoom(info)
  local room_id

  if self.prefs.gmcp.expect_hash then
    room_id = getRoomIDbyHash(info.hash)
    if room_id == -1 then
      room_id = createRoomID()
      if not addRoom(room_id) then
        return -1
      end
      setRoomIDbyHash(room_id, info.hash)
    end
  else
    if not getRoomName(info.vnum) then
      if not addRoom(info.vnum) then
        return -1
      end
      room_id = info.vnum
    end
  end

  -- Update room name if it has changed
  if getRoomName(room_id) ~= info.name then
    setRoomName(room_id, info.name or "Unexplored Room")
  end

  -- Update room area if it has changed
  local area_name = info.area or "Undefined"
  local area_id = getAreaTable()[area_name]
  if not area_id then
    area_id = addAreaName(area_name)
  end
  if getRoomArea(room_id) ~= area_id then
    setRoomArea(room_id, area_id)
  end

  -- Update room doors if they have changed
  local doors = info.doors or {}
  local current_doors = getDoors(room_id) or {}
  for dir, door_info in pairs(doors) do
    local command = self.exits.reverse[dir]
    local door_status = tonumber(door_info.status)

    local door_result, err = setDoor(room_id, command, door_status)
    current_doors[command] = door_status
  end

  for dir, _ in pairs(current_doors) do
    if not doors[self.exits.map[dir]] then
      setDoor(room_id, dir, 0)
    end
  end

  -- Update room coordinates if they have changed, otherwise calculate them
  local coords = {}
  if self.prefs.gmcp.expect_coordinates then
    if info.coords then
      coords = info.coords
    end
  else
    -- Calculate coordinates based on previous room
    coords = self:CalculateCoordinates(room_id)
  end

  if #coords == 3 then
    ---@diagnostic disable-next-line: deprecated
    local x, y, z = unpack(coords)
    setRoomCoordinates(room_id, x, y, z)
  end

  local env_id
  if info[self.prefs.gmcp.properties.environment] then
    if self.terrain.types[info.environment] then
      env_id = self.terrain.types[info.environment].id
    else
      env_id = self.terrain.types["default"].id
    end
  else
    env_id = self.terrain.types["default"].id
  end

  if getRoomEnv(room_id) ~= env_id then
    setRoomEnv(room_id, env_id)
  end

  if table.contains(self.terrain.prevent, env_id) then
    lockRoom(room_id, true)
  else
    lockRoom(room_id, false)
    if table.contains(self.terrain.avoid, env_id) then
      setRoomWeight(room_id, self.terrain.avoid[env_id])
    else
      setRoomWeight(room_id, 1)
    end
  end

  if info.icon and utf8.len(info.icon) > 0 then
    setRoomChar(room_id, info.icon)
  elseif info.subtype and table.contains(self.glyphs, info.subtype) then
    setRoomChar(room_id, self.glyphs[info.subtype])
  elseif info.type and table.contains(self.glyphs, info.type) then
    setRoomChar(room_id, self.glyphs[info.type])
  else
    setRoomChar(room_id, "")
  end

  raiseEvent("onNewRoom")

  return room_id
end

-- ----------------------------------------------------------------------------
-- CalculateCoordinates
--
-- This function calculates the coordinates of a room based on the previous
-- room and the shift vectors. It returns the coordinates of the current room.
-- ----------------------------------------------------------------------------

function Carto:CalculateCoordinates()
  local default_coordinates = { 0, 0, 0 }

  if not self.info.previous or not self.info.previous.room_id then
    return default_coordinates
  end

  local prev_room_id = self.info.previous.room_id
  local x, y, z = getRoomCoordinates(prev_room_id)
  local coords
  if not x or not y or not z then
    coords = default_coordinates
  else
    coords = { x, y, z }
  end

  local shift = { 0, 0, 0 }
  local compare_field
  if self.prefs.gmcp.expect_hash then
    compare_field = self.prefs.gmcp.properties.hash
  else
    compare_field = self.prefs.gmcp.properties.vnum
  end

  for k, v in pairs(self.info.current[self.prefs.gmcp.properties.exits]) do
    if v == self.info.previous[compare_field] and self.exits.vectors.name[k] then
      if self.exits.vectors.name[k] then
        shift = self.exits.vectors.name[k]
        break
      else
        echo("No shift vector found for " .. k .. ".\n")
      end
    end
  end

  for n = 1, 3 do
    coords[n] = coords[n] - shift[n]
  end

  return coords
end

---@param room_id number
function Carto:UpdateExits(room_id)
  local prev = self.info.previous or {}
  local current = self.info.current or {}

  local current_exits = getRoomExits(room_id) or {}
  local current_stubs = getExitStubs(room_id) or {}
  local prev_exits

  if prev.exits then
    prev_exits = prev.exits
  else
    prev_exits = {}
  end

  -- Update or add new exits
  for dir, id in pairs(current.exits) do
    local exit_room_id

    if self.prefs.gmcp.expect_hash then
      exit_room_id = getRoomIDbyHash(id)
    else
      local tmp = getRoomName(id)
      if tmp then
        exit_room_id = id
      else
        exit_room_id = -1
      end
    end

    -- This exit leads to a room we've seen before
    if exit_room_id ~= -1 then
      -- Neither exit nor stub exists, set exit
      local stub_num = self.exits.stubs[dir]
      if stub_num then
        if not current_exits[dir] and not current_stubs[stub_num] then
          setExitStub(room_id, dir, true)
          connectExitStub(room_id, exit_room_id, dir)
          -- Else if a stub exists, but not an exit, connect the stub
        elseif current_stubs[stub_num] and not current_exits[dir] then
          connectExitStub(exit_room_id, room_id, dir)
        end
      end
    else
      -- This is an unexplored exit
      if not table.contains(current_stubs, self.exits.stubs[dir]) then
        setExitStub(room_id, dir, true)
      end
    end
  end

  -- Remove exits that no longer exist
  for dir, _ in pairs(current_exits) do
    if not current.exits[dir] then
      setExit(room_id, -1, dir)
    end
  end
end

-- ----------------------------------------------------------------------------
-- doSpeedWalk
--
-- This function starts the speedwalk process. It checks for necessary
-- conditions and initiates the walking process if all checks pass.
--
-- This function is called directly by Mudlet when the user initiates a
-- speedwalk by double-clicking on a room on the map, or through a script.
-- ----------------------------------------------------------------------------

function doSpeedWalk()
  Carto:Speedwalk()
end

-- ----------------------------------------------------------------------------
-- ResetWalking
--
-- This function resets the walking state and raises events when the walking
-- process is interrupted or completed.
-- ----------------------------------------------------------------------------

---@param exception boolean
---@param reason string
function Carto:ResetWalking(exception, reason)
  if table.contains(getNamedTimers(self.config.name), self.walk_timer_name) then
    deleteNamedTimer(self.config.name, self.walk_timer_name)
  end

  if self.walking then
    if exception then
      raiseEvent("onSpeedwalkReset", exception, reason)
    else
      raiseEvent("sysSpeedwalkFinished")
    end
  end

  self.walking = false
  self.speedwalk_path = {}
  self.walk_timer = nil
  self.walk_step = nil
  self.move_tracking = {}
end

-- ----------------------------------------------------------------------------
-- Speedwalk
--
-- This function is called from doSpeedWalk. It checks for necessary
-- conditions and initiates the walking process if all checks pass.
-- ----------------------------------------------------------------------------

function Carto:Speedwalk()
  if not self.info then
    echo(string.format("%s cannot determine your current room.\n", self.config.name))
    return
  end

  if not self.info.current then
    echo(string.format("%s cannot determine your current room.\n", self.config.name))
    return
  end

  if self.walking then
    echo("You are already walking!\n")
    return
  end

  self.speedwalk_path = {}
  if not next(self.info.current.exits) then
    echo("No speedwalk direction found.\n")
    self:ResetWalking(true, "No speedwalk direction found.")
    return
  end

  if not next(speedWalkPath) then
    echo("No speedwalk path found.\n")
    self:ResetWalking(true, "No speedwalk path found.")
    return
  end

  ---@diagnostic disable-next-line: param-type-mismatch
  for i, dir in ipairs(speedWalkDir) do
    local room_id = tonumber(speedWalkPath[i])
    table.insert(self.speedwalk_path, { dir, room_id })
  end

  -- Get the first exit, because speedWalkDir does not include the current room
  -- Inserts {nil, room_id} at the beginning of the path
  local room_exits = getRoomExits(self.info.current.room_id) or {}
  if not next(room_exits) then
    echo("No exits found.\n")
    self:ResetWalking(true, "No exits found.")
    return
  end

  for dir, room_id in pairs(room_exits) do
    if room_id == self.speedwalk_path[1][2] then
      local to_insert = { "", self.info.current.room_id }
      table.insert(self.speedwalk_path, 1, to_insert)
      break
    end
  end

  -- This is the timer that calls the Step function repeatedly, initiating
  -- the speedwalk's first step.
  self.walk_timer = registerNamedTimer(
    self.config.name,
    self.walk_timer_name,
    self.prefs.speedwalk_delay + 0.01,
    function() self:Step() end,
    false
  )

  if not self.walk_timer then
    echo("Failed to start walking.\n")
    self:ResetWalking(true, "Failed to start walking.")
    return
  end

  self.walking = true
  local destination_id = self.speedwalk_path[#self.speedwalk_path][2]
  local destination_name = getRoomName(destination_id)
  echo("Walking to " .. destination_name .. ".\n")

  raiseEvent("sysSpeedwalkStarted")
end

-- ----------------------------------------------------------------------------
-- Step
--
-- This function performs a single step in the speedwalk process. It checks
-- the current room's ID against the expected room's ID, handles the starting
-- room, and sends the appropriate direction command to move to the next room.
--
-- It is called by the initial timer set in Speedwalk and if there are
-- remaining steps to be taken, as determined by the Move function, then
-- it will be called again.
-- ----------------------------------------------------------------------------

function Carto:Step()
  if not next(self.speedwalk_path) then
    echo("You have arrived at " .. self.info.current.name .. ".\n")
    self:ResetWalking(false, "Arrived at destination.")
    return
  end

  local current_room_id = self.info.current.room_id
  if not current_room_id then
    echo("Unable to determine your current location.\n")
    self:ResetWalking(true, "Unable to determine your current location.")
    return
  end

  local current_step = self.speedwalk_path[1]

  -- Check if this is the starting room (which doesn't have a direction)
  if current_step[1] == "" then
    if current_room_id ~= current_step[2] then
      echo("You are not in the expected starting room.\n")
      echo("Expected you to be in room " .. current_step[2] .. " (" .. getRoomName(current_step[2]) .. ").\n")
      echo("Current room: " .. current_room_id .. " (" .. getRoomName(current_room_id) .. ").\n")
      self:ResetWalking(true, "You are not in the expected starting room.")
      return
    end

    table.remove(self.speedwalk_path, 1)
    if not next(self.speedwalk_path) then
      echo("You have arrived at " .. self.info.current.name .. ".\n")
      return
    end
    self.walk_step = current_room_id

    self:Step() -- Recursively call Step to move to the next actual step
    return
  end

  -- Check if we're in the expected room before moving
  if current_room_id ~= self.walk_step then
    if next(self.move_tracking) then
      local last_move = self.move_tracking[#self.move_tracking]
      if last_move then
        if current_room_id == last_move.prev_room_id then
          echo("Something prevents you from continuing.\n")
        else
          echo("You have veered off the expected path.\n")
        end
      else
        echo("You have veered off the expected path.\n")
      end
    else
      echo("You have veered off the expected path.\n")
    end
    self:ResetWalking(true, "You have veered off the expected path.")
    return
  end

  -- Now we're dealing with a regular step
  ---@diagnostic disable-next-line: deprecated
  local dir, next_room_id = unpack(current_step)

  self.walk_step = next_room_id

  local full_dir = self.exits.map[dir] or self.exits.reverse[dir]
  if not full_dir then
    echo("Invalid direction: " .. dir .. "\n")
    self:ResetWalking(true, "Invalid direction.")
    return
  end

  send(full_dir, true)

  -- Remove the current step as we've just executed it
  table.remove(self.speedwalk_path, 1)
end

-- ----------------------------------------------------------------------------
-- SetSpeedwalkDelay
--
-- This function sets the speedwalk delay based on the provided delay value.
-- It ensures the delay is within the minimum allowed value if not overridden.
-- ----------------------------------------------------------------------------

---@param delay number
---@param override boolean
function Carto:SetSpeedwalkDelay(delay, override)
  delay = tonumber(delay) or 0
  if delay < self.prefs.speedwalk_delay_min and not override then
    delay = self.prefs.speedwalk_delay_min
  end

  self.prefs.speedwalk_delay = delay

  local unit = self.prefs.speedwalk_delay == 1 and "second" or "seconds"
  echo("Walk speed set to " .. self.prefs.speedwalk_delay .. " " .. unit .. " per step.\n")
end

-- ----------------------------------------------------------------------------
-- RememberRoom
--
-- This function saves the current room as a recall point for the current
-- profile.
-- ----------------------------------------------------------------------------

---@param position number
function Carto:RememberRoom(position)
  local room_id = getPlayerRoom()

  if position == nil then
    position = #self.prefs.recalls + 1
  else
    if position > #self.prefs.recalls then
      position = #self.prefs.recalls + 1
    end
  end

  local index = table.index_of(self.prefs.recalls, room_id)
  if index then
    echo("Room " .. room_id .. " (" .. getRoomName(room_id) .. ") is already in recall position " .. index .. ".\n")
    return
  end

  if self.prefs.recalls[position] then
    local existing_room_id = self.prefs.recalls[position]
    local existing_room_name = getRoomName(existing_room_id)
    echo("Replacing room " .. existing_room_id .. " (" .. existing_room_name .. ") in recall position " .. position .. " with room " .. room_id .. " (" .. getRoomName(room_id) .. ").\n")
    self.prefs.recalls[position] = room_id
  else
    table.insert(self.prefs.recalls, position, room_id)
    echo("Room " .. room_id .. " (" .. getRoomName(room_id) .. ") has been saved to recall position " .. position .. ".\n")
  end

  self:SavePreferences()
end

-- ----------------------------------------------------------------------------
-- ForgetRoom
--
-- This function removes a recall point from the list of recalls.
-- ----------------------------------------------------------------------------

---@param position number
function Carto:ForgetRoom(position)
  if not self.prefs.recalls then
    echo("No recall points have been set.\n")
    return
  end

  if position == nil then
    local room_id = getPlayerRoom()
    position = table.index_of(self.prefs.recalls, room_id)
    if not position then
      echo("You are not in a recall point.\n")
      return
    end
  end

  if not self.prefs.recalls[position] then
    echo("No recall point at position " .. position .. ".\n")
    return
  end

  echo("Forgetting room " .. self.prefs.recalls[position] .. " (" .. getRoomName(self.prefs.recalls[position]) .. ") at position " .. position .. ".\n")
  table.remove(self.prefs.recalls, position)

  self:SavePreferences()
end

-- ----------------------------------------------------------------------------
-- RecallRoom
--
-- This function recalls the character to a previously saved room based on the
-- provided position.
-- ----------------------------------------------------------------------------

---@param position number
function Carto:RecallRoom(position)
  if #self.prefs.recalls < 1 then
    echo("No recall points have been set.\n")
    return
  end

  if not self.prefs.recalls[position] then
    echo("No recall point at position " .. position .. ".\n")
    return
  end

  local room_id = self.prefs.recalls[position]
  local room_name = getRoomName(room_id)
  echo("Recalling to room " .. room_id .. " (" .. room_name .. ").\n")
  gotoRoom(room_id)
end

-- ----------------------------------------------------------------------------
-- DisplayRecalls
--
-- This function displays all the recall points for the current profile.
-- ----------------------------------------------------------------------------

function Carto:DisplayRecalls()
  if #self.prefs.recalls < 1 then
    echo("No recall points have been set.\n")
    return
  end

  echo("Recall points:\n")
  for position, room_id in pairs(self.prefs.recalls) do
    local room_name = getRoomName(room_id)
    echo(string.format("  %2d: %s\n", position, room_name))
  end
end

-- ----------------------------------------------------------------------------
-- GetSpeedwalkDelay
--
-- This function returns the current speedwalk delay value.
-- ----------------------------------------------------------------------------

function Carto:GetSpeedwalkDelay()
  return self.prefs.speedwalk_delay
end

-- ----------------------------------------------------------------------------
-- Helper functions
-- ----------------------------------------------------------------------------

---@param gmcp_package string
function Carto:TableFromPackage(gmcp_package)
  -- Split the package string by the dots
  local keys = self:Explode(gmcp_package, ".")

  -- Start from the global gmcp table
  local current_table = gmcp

  -- Traverse through the keys to find the nested table
  for i = 2, #keys do
    local key = keys[i]
    if next(current_table) then
      current_table = current_table[key]
    else
      return nil -- Return nil if the key doesn't exist
    end
  end

  return current_table
end

-- ----------------------------------------------------------------------------
-- Help
-- ----------------------------------------------------------------------------

Carto.help_styles = {
  h1 = "hot_pink",
}

Carto.help = {
  name = Carto.config.name,
  topics = {
    usage = f [[
<h1><u>{Carto.config.name}</u></h1>

Syntax: <b>walk</b> [<b>command</b>]

  <b>walk</b> - See this help text.
  <b>walk stop</b> - Stop walking.
  <b>walk slow</b> - Set walk speed to {Carto.config.speed_walk_slow} seconds per step.
  <b>walk fast</b> - Set walk speed to {Carto.config.speed_walk_fast} seconds per step.
  <b>walk speed</b> - See your current walk speed.
  <b>walk speed</b> <<b>n</b>> - Set walk speed to <i>n</i> seconds per step.
  <b>walk to</b> <<b>room_id</b>> - Walk to room <i>room_id</i>.
  <b>walk remember</b> - Remember the current room.
  <b>walk remember</b> <<b>position</b>> - Remember the current room at <i>position</i>.
  <b>walk forget</b> - Forget the current room.
  <b>walk forget</b> <<b>position</b>> - Forget the room at <i>position</i>.
  <b>walk recall</b> - List all recall positions.
  <b>walk recall</b> <<b>position</b>> - Recall to the room at <i>position</i>.
]],
  }
}
