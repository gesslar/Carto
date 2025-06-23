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
---@field dependencies table
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
    mode = "quick",
    speedwalk_delay = 0.0,   -- Speedwalk delay
    speedwalk_delay_min = 0.0, -- Minimum speedwalk delay
    gmcp = {
      -- The event that triggers Carto
      event = "gmcp.Room.Info",
      -- Whether to expect coordinates from the GMCP event
      expect_coordinates = true,
      -- Whether to expect a hash or vnum from the GMCP event
      expect_hash = true,
      -- The property names we can expect from the GMCP event
      properties = {
        area = "area",
        coords = "coords",
        doors = "doors",
        environment = "environment",
        exits = "exits",
        hash = "hash",
        icon = "icon",
        name = "name",
        subtype = "subtype",
        symbol = "symbol",
        type = "type",
        vnum = "vnum",
      },
    },
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
    },
    -- Mapping of full exit names to abbreviations
    reverse = {
      north = "n",      northeast = "ne", northwest = "nw", east = "e",
      west = "w",       south = "s",      southeast = "se", southwest = "sw",
      up = "u",         down = "d",       ["in"] = "in",    out = "out",
    },
      -- Mapping of direction names to their numeric representations and vice versa
    stubs = {
      north = 1,        northeast = 2,      northwest = 3,      east = 4,
      west = 5,         south = 6,          southeast = 7,      southwest = 8,
      up = 9,           down = 10,          ["in"] = 11,        out = 12,
      [1] = "north",    [2] = "northeast",  [3] = "northwest",  [4] = "east",
      [5] = "west",     [6] = "south",      [7] = "southeast",  [8] = "southwest",
      [9] = "up",       [10] = "down",      [11] = "in",        [12] = "out",
    },
    -- Mapping of stubs in the reverse direction (n = s)
    stubs_reverse = {
       [1] =  6,         [2] =  8,          [3] =  7,           [4] =  5,
       [5] =  4,         [6] =  1,          [7] =  3,           [8] =  2,
       [9] = 10,        [10] =  9,         [11] = 12,          [12] = 11,
    },
    vectors = {
      name = {     --  x   y   z                   x   y   z
        north     = {  0,  1,  0 }, south     = {  0, -1,  0 },
        east      = {  1,  0,  0 }, west      = { -1,  0,  0 },
        northwest = { -1,  1,  0 }, northeast = {  1, -1,  0 },
        southwest = { -1, -1,  0 }, southeast = {  1, -1,  0 },
        up        = {  0,  0,  1 }, down      = {  0,  0, -1 },
        ["in"]    = {  0,  0,  0 }, out       = {  0,  0,  0 },
      },
      number = {
        [1] = { 0, 1, 0 },    [2] = { 1, 1, 0 },    [3] = { -1, 1, 0 },  [4] = { 1, 0, 0 },
        [5] = { -1, 0, 0 },   [6] = { 0, -1, 0 },   [7] = { 1, -1, 0 },  [8] = { -1, -1, 0 },
        [9] = { 0, 0, 1 },   [10] = { 0, 0, -1 },  [11] = { 0, 0, 0 },  [12] = { 0, 0, 0 },
      }
    }
  },
  tags = {
    carto = { "%s", table.deepcopy(color_table["orange_red"]), table.deepcopy(color_table["orange"]  ) },
    warning = { "%s", table.deepcopy(color_table["orange"]), table.deepcopy(color_table["orange_red"]) },
    error = { "%s", table.deepcopy(color_table["red"]), table.deepcopy(color_table["orange_red"]) },
    info = { "%s", table.deepcopy(color_table["chartreuse"]), table.deepcopy(color_table["olive_drab"]) },
  },
  door_changes = {},
  speedwalk_path = {},     -- Speedwalk path
  move_tracking = {},      -- Move tracking for room movements
  walk_timer = nil,        -- Walk timer
  walk_timer_name = nil,   -- Walk timer name
  walk_step = nil,         -- The next room id for the speedwalk
  dependencies = {
    { name = "Helper", url = "https://github.com/gesslar/Helper/releases/latest/download/Helper.mpackage" },
    { name = "mpkg", url = "https://mudlet.github.io/mudlet-package-repository/packages/mpkg.mpackage" },
  },
  debug = false,
}

-- For debugging
local function d(text)
  if _d and Carto.debug == true then
    _d(text, { colour = "maroon", skip = 1 })
  end
end

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
    ---@diagnostic disable-next-line: assign-type-mismatch
    self.prefs = prefs
  else
    self.prefs = defaults
  end

  -- Iterate through the prefs and set defaults for anything missing, clearing
  -- out anything that is no longer present.
  for key, value in pairs(self.default) do
    if key ~= "gmcp" then
      if not self.prefs[key] then
        self.prefs[key] = value
      end
    else
      if not self.prefs.gmcp then
        self.prefs.gmcp = self.default.gmcp
      else
        for k, v in pairs(value) do
          if k ~= "properties" then
          if not self.prefs.gmcp[k] then
              self.prefs.gmcp[k] = v
            end
          else
            if not self.prefs.gmcp.properties then
            self.prefs.gmcp.properties = self.default.gmcp.properties
            else
              for k, v in pairs(v) do
                if not self.prefs.gmcp.properties[k] then
                  self.prefs.gmcp.properties[k] = v
                end
              end
            end
          end
        end
      end
    end
  end

  -- Now for recalls
  if not self.prefs.recalls then
    self.prefs.recalls = {}
  end

  self:UpdateGMCPHandler()
end

function Carto:SavePreferences()
  local path = self.config.package_path .. self.config.preferences_file
  table.save(path, self.prefs)
  self:UpdateGMCPHandler()
end

function Carto:SetPreference(key, value)
  if not self.prefs then
    self.prefs = {}
  end

  if not self.default[key] then
    cecho(f"<orange_red>Unknown preference {key}.\n")
    return
  end

  if key == "speedwalk_delay" then
    value = tonumber(value)
  elseif key == "speedwalk_delay_min" then
    value = tonumber(value)
  else
    cecho(f"<orange_red>Unknown preference {key}.\n")
    return
  end

  self.prefs[key] = value
  self:SavePreferences()
  self:LoadPreferences()

  cecho(f"<chartreuse>Preference {key} set to {value}.\n")
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
--[[
  -- Check if we have dependencies that need installing. False means that
  -- we need to wait for the dependencies to be installed.
  -- We will be called again when the dependencies are installed.
  if not Dependent:run({
    name = self.config.package_name,
    dependencies = self.dependencies
  }) then return end
--]]
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
    registerNamedEventHandler(
      self.config.name,
      self.prefs.gmcp.event,
      self.prefs.gmcp.event,
      function(...) self:EventHandler(...) end
    )
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
    "carto.config",
    -- Dependent events
    "DependentCompleted",
    "DependentFailed",
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
  elseif event == "sysUninstall" then
    self:Uninstall(event, ...)
  elseif event == "sysLoadEvent" or event == "sysConnectionEvent" then
    self:Setup(event, ...)
  elseif event == "sysDisconnectionEvent" then
    self:Disconnect(event, ...) -- no args
  elseif event == "sysExitEvent" then
    self:Teardown(event, ...)   -- no args
  elseif self.prefs and self.prefs.gmcp and event == self.prefs.gmcp.event then
    self:Move(event, ...)       -- arg1 is the GMCP package name
  elseif event == "carto.AddOrUpdateRoomconfig" then
    self:Config(event, ...)
  elseif event == "DependentCompleted" or event == "DependentFailed" then
    self:Dependent(event, ...)
  elseif event == "carto.config" then
    self:Config(event, ...)
  end
end

-- sysInstall must be on its own, outside of the event_handlers
-- since it will be called during the install process.
registerNamedEventHandler(Carto.config.name, "Carto:Install", "sysInstall", function(...) Carto:EventHandler(...) end,
  true)
Carto:SetupEventHandlers()

function Carto:UpdateGMCPHandler()
  -- We need to add the gmcp one now based on the preferences
  if self.prefs.gmcp.event then
    deleteNamedEventHandler(self.config.name, self.prefs.gmcp.event)
    registerNamedEventHandler(
      self.config.name,
      self.prefs.gmcp.event,
      self.prefs.gmcp.event,
      function(...) self:EventHandler(...) end
    )
  end
end

-- ----------------------------------------------------------------------------
-- Dependent
-- ----------------------------------------------------------------------------

function Carto:Dependent(event, source_script, dependencies)
  if source_script ~= self.config.name then return end

  if event == "DependentCompleted" then
    self:Setup("sysInstall", self.config.package_name)
  elseif event == "DependentFailed" then
    cecho("\n")
    cecho(f"<orange_red>Could not install all dependencies, please install them manually.\n")
    for _, dependency in ipairs(dependencies.still_missing) do
      cecho(f"  <orange_red>Missing dependency: {dependency}\n")
    end
  end
end

-- ----------------------------------------------------------------------------
-- Config
-- ----------------------------------------------------------------------------

---@param event string
---@param setting string
---@param value string
function Carto:Config(event, setting, value)

  if not setting or setting == "" then
    helper.print({text=self.help.topics.carto_config, styles=self.help_styles})
    return
  elseif setting == "config" then
    self:DisplayGMCPConfig(event)
    return
  elseif setting == "event" then
    self.prefs.gmcp.event = value
  elseif setting == "expect_coordinates" then
    if value == "true" then
      self.prefs.gmcp.expect_coordinates = true
    elseif value == "false" then
      self.prefs.gmcp.expect_coordinates = false
    else
      cecho(f"<orange_red>Syntax: carto expect_coordinates <true|false>\n")
    end
  elseif setting == "expect_hash" then
    if value == "true" then
      self.prefs.gmcp.expect_hash = true
    elseif value == "false" then
      self.prefs.gmcp.expect_hash = false
    else
      cecho(f"<orange_red>Syntax: carto expect_hash <true|false>\n")
    end
  elseif setting == "mode" then
    if value ~= "quick" and value ~= "normal" then
      cecho(f"<orange_red>Unknown mode: {value}.\n")
      cecho(f"<orange_red>Valid modes are: quick, normal\n")
      return
    else
      self.prefs.mode = value
    end
  elseif setting == "properties" then
    if not value or value == "" then
      helper.print({text=self.help.topics.carto_properties, styles=self.help_styles})
      return
    else
      local parts = value:split(" ")
      ---@diagnostic disable-next-line: deprecated
      local p, v = unpack(parts)
      if p and p ~= "" and v and v ~= "" then
        if not self.default.gmcp.properties[p] then
          cecho(f"<orange_red>Unknown property {p}.\n")
          return
        end
        self.prefs.gmcp.properties[p] = v
        echo("Property " .. p .. " set to " .. v .. ".\n")
      else
        cecho(f"<orange_red>Syntax: carto properties <property> <value>\n")
        return
      end
    end
  else
    cecho(f"<orange_red>No such setting: {setting}.\n")
    return
  end

  cecho(f"<chartreuse>Setting {setting} to {value}.\n")

  self:SavePreferences()
end

function Carto:DisplayGMCPConfig(event)
  cecho("<hot_pink>Carto GMCP config:\n\n")
  -- Display base config
  for property, value in pairs(self.prefs.gmcp) do
    if property ~= "properties" then
      cecho(f"<hot_pink>{property}<reset> = {tostring(value)}\n")
    end
  end

  -- Display properties config
  if self.prefs.gmcp.properties then
    cecho("  <hot_pink>properties:\n")
    for property, value in pairs(self.prefs.gmcp.properties) do
      cecho(f"<hot_pink>  {property}<reset> = {tostring(value)}\n")
    end
  end
end

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
    tempTimer(0.05, function()
      cecho(f"<chartreuse>Uninstalling package: generic_mapper\n")
      uninstallPackage("generic_mapper")
      tempTimer(1, function()
        if(table.contains(getPackages(), "generic_mapper")) then
          cecho(f"<orange_red>Could not uninstall generic_mapper.\n")
          cecho(f"<orange_red>Please uninstall it manually and restart Mudlet.\n")
          return
        end
      end)
    end)
  end

  deleteNamedEventHandler(self.config.name, "Carto:Install")

  self:Setup(event, package)
end

---@param event string
---@param package string
function Carto:Uninstall(event, package)
  if package ~= self.config.package_name then
    return
  end

  if self.walking then
    cecho(f"<chartreuse>Resetting walking.\n")
  end
  self:ResetWalking(true, "Script has been uninstalled.")
  self:Teardown(event, package)

  Carto = nil
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
  d(f"Event = {event}, GMCP package = {gmcp_package}\n")

  local gmcp_table = self:TableFromPackage(gmcp_package) or {}

  self.info.previous = self.info.current

  d(f [[We expect {self.prefs.gmcp.expect_hash and "hash" or "vnum"}]])

  if self.prefs.gmcp.expect_hash then
    if not gmcp_table[self.prefs.gmcp.properties.hash] then return end
  else
    if not gmcp_table[self.prefs.gmcp.properties.vnum] then return end
  end

  d(f [[Received {self.prefs.gmcp.expect_hash and "hash" or "vnum"} {gmcp_table[self.prefs.gmcp.expect_hash and "hash" or "vnum"]}]])

  -- Record the room we've entered
  self.info.current = {
    hash = gmcp_table[self.prefs.gmcp.properties.hash],
    vnum = gmcp_table[self.prefs.gmcp.properties.vnum],
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

  local room_id = self:AddOrUpdateRoom(self.info.current)
  d(f"Room ID for {self.info.current.name} is {room_id}\n")
  if room_id == -1 then
    cecho(f"<orange_red>Failed to add room.\n")
    return
  end

  d(f"Recording room ID {room_id} for room {getRoomName(room_id)}\n")
  self.info.current.room_id = room_id

  self:UpdateCoordinates(room_id, gmcp_table)
  self:UpdateExits(room_id)
  self:UpdateDoors(room_id)

  centerview(room_id)

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

  d(f"Updating map.\n")
  updateMap()

  local current_room_id, previous_room_id
  if self.info.current and self.info.current.room_id then
    current_room_id = self.info.current.room_id
  end
  if self.info.previous and self.info.previous.room_id then
    previous_room_id = self.info.previous.room_id
  end

  raiseEvent("onMoveMap", current_room_id)

  if table.size(self.door_changes) > 0 then
    d(f"Updating doors.\n")
    for _, door in ipairs(self.door_changes) do
      d(f "Door {door.name} in room {door.room_id} changed to {door.status}.\n")
      raiseEvent("onDoorChange", door.room_id, door.command, door.door_status, door.old_status)
    end
  end

  d(f"Walking = {self.walking}\n")
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
  local door_status = {}

  if self.prefs.gmcp.expect_hash then
    room_id = getRoomIDbyHash(info.hash)
    d(f"The room we have entered doesn't exist yet.\n")
    if room_id == -1 then
      room_id = createRoomID()
      if not addRoom(room_id) then
        d(f"Failed to add room\n")
        return -1
      end
      setRoomIDbyHash(room_id, info.hash)
      d(f"Added room {room_id} with hash {info.hash}\n")
    else
      d(f"Room {room_id} already exists with hash {info.hash}\n")
    end
  else
    d(f"Expecting vnum\n")
    d(f"Vnum: {info.vnum}\n")
    local name = getRoomName(info.vnum)
    if not name then
      d(f"Adding room\n")
      local result = addRoom(info.vnum)
      d(f"Result: {result}\n")
      if not result then
        d(f"Failed to add room\n")
        return -1
      else
        d(f"Added room {name}\n")
      end
      room_id = info.vnum
      d(f"Setting room ID to {room_id}\n")
    else
      d(f"Room ID already exists as {name}\n")
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
-- UpdateCoordinates
--
-- This function updates the coordinates of a room based on the previous room
-- and the shift vectors. It returns the coordinates of the current room.
-- ----------------------------------------------------------------------------

---@param gmcp_table table
function Carto:UpdateCoordinates(room_id, gmcp_table)
  d(f"Updating coordinates for room {tostring(room_id)}\n")

  if self.info.previous and self.info.previous.room_id then
    if room_id == self.info.previous.room_id then
      d(f"We have not moved to a new room. Exiting.\n")
      return
    end
  end

  if self.prefs.gmcp.expect_coordinates then
    d(f"We are expecting coordinates.\n")
    assert(gmcp_table[self.prefs.gmcp.properties.coords], "Coordinates not found in GMCP table")
    self.info.current.coords = gmcp_table[self.prefs.gmcp.properties.coords]
    d(f"Coordinates received via GMCP: {table.concat(self.info.current.coords, ', ')}\n")
  else
    d(f "We are not expecting coordinates.\n")
    local prev_room_id = self.info.previous and self.info.previous.room_id or nil
    self.info.current.coords = self:CalculateCoordinates(room_id, prev_room_id)
    d(f "Calculated coordinates: {table.concat(self.info.current.coords, ', ')}\n")
  end

  if #self.info.current.coords == 3 then
    local x, y, z = unpack(self.info.current.coords)
    setRoomCoordinates(room_id, x, y, z)
  else
    d(f "Coordinates not set for room {room_id}\n")
  end
end

-- ----------------------------------------------------------------------------
-- CalculateCoordinates
--
-- This function calculates the coordinates of a room based on the previous
-- room and the shift vectors. It returns the coordinates of the current room.
-- ----------------------------------------------------------------------------

---@param curr_room_id number
---@param prev_room_id number|nil
function Carto:CalculateCoordinates(curr_room_id, prev_room_id)
  d(f"Calculating coordinates for room {tostring(curr_room_id)}\n")
  local default_coordinates = { 0, 0, 0 }

  if not prev_room_id then return default_coordinates end

  local x, y, z = getRoomCoordinates(prev_room_id)
  d(f"Previous room coordinates: {table.concat({x, y, z}, ', ')}\n")
  local coords
  if not x or not y or not z then
    coords = default_coordinates
  else
    coords = { x, y, z }
  end

  d(f"Previous room: {getRoomName(prev_room_id)} ({prev_room_id})\n")

  local shift = { 0, 0, 0 }
  local compare_field
  if self.prefs.gmcp.expect_hash then
    compare_field = "hash"
  else
    compare_field = "vnum"
  end

  d(f"Comparing current and previous {compare_field}\n")
  for dir, hash in pairs(self.info.previous.exits) do
    local current_hash = self.info.current[compare_field]
    d(f"  Checking {compare_field}: {dir} - {hash} against {current_hash}")
    if hash == current_hash and self.exits.vectors.name[dir] then
      if self.exits.vectors.name[dir] then
        shift = self.exits.vectors.name[dir]
        break
      else
        cecho(f"<orange_red>No shift vector found for {k}.\n")
      end
    end
  end

  d(f"Shift vector: {table.concat(shift, ', ')}\n")
  for n = 1, 3 do
    coords[n] = coords[n] + shift[n]
  end

  return coords
end

---@param room_id number
function Carto:UpdateExits(room_id)
  d(f"Updating exits for room {room_id} - {getRoomName(room_id)}\n")

  local prev = self.info.previous or {}
  local current = self.info.current or {}

  local current_exits = getRoomExits(room_id) or {}
  local current_stubs = getExitStubs1(room_id) or {}
  local prev_exits

  if prev.exits then
    prev_exits = prev.exits
  else
    prev_exits = {}
  end

  local compare_field
  if self.prefs.gmcp.expect_hash then
    compare_field = "hash"
  else
    compare_field = "vnum"
  end

  -- Iterate through the exits from the GMCP event in the room where we have
  -- arrived, adding new exit stubs for places we haven't seen before.
  -- If the exit leads to the room we just left, connect its exit stub
  -- to this room.
  for dir, id in pairs(current.exits) do
    local exit_room_id
    local done = false

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

    -- This exit leads to a room we haven't seen before
    if exit_room_id == -1 then
      d(f"We haven't seen the {dir} exit before. Creating an exit stub in that direction.\n")
      local stub_dir = self.exits.stubs[dir]
      d(f"Checking exit stub {dir} ({stub_dir})\n")
      if table.index_of(current_stubs, stub_dir) then
        d(f"  Exit stub {dir} ({stub_dir}) already exists. Skipping.\n")
      else
        d(f"  Exit stub {dir} ({stub_dir}) does not exist. Creating it.\n")
        setExitStub(room_id, stub_dir, true)
      end
    else
      -- We have seen the room this exit leads to.
      -- Check if it is the one we just left, so we can connect its exit stub.
      if self.info and self.info.previous and exit_room_id == self.info.previous.room_id then
        d(f"Exit {dir} leads to the room we've just left {getRoomName(exit_room_id)} ({exit_room_id}).\n")
        -- First determine if there is an exit in the previous room leading
        -- to this.
        local prev_exits = self.info.previous.exits or {}
        for prev_dir, prev_dest_hash in pairs(prev_exits) do
          -- Aha, we found an exit that leads here
          d(f"Comparing {prev_dir} - {prev_dest_hash} against {self.info.current[compare_field]}\n")
          if prev_dest_hash == self.info.current[compare_field] then
            d(f"We found a match in direction {prev_dir} to {room_id}\n")
            -- Now we need to see if there is an exit already built to
            -- this room.
            local exit_dir_exits = getRoomExits(exit_room_id) or {}
            for direction, dest_room_id in pairs(exit_dir_exits) do
              d(f"Comparing {dest_room_id} to {room_id}\n")
              if dest_room_id == room_id then
                d(f"All right, there is already an exit from {exit_room_id} ({direction}) to {room_id}\n")
                done = true
                break
              else
                d(f"No match found for {direction} - {dest_room_id}\n")
              end
            end
            if done == true then
              break
            end
            -- We didn't find any exit in the previous room leading to this,
            -- so, let's just build one and baaaaaail.
            d(f"Building an exit from {self.info.previous.room_id} to {room_id}\n")
            local result

            result = setExit(self.info.previous.room_id, room_id, prev_dir)
            d(f"Result: {tostring(result)}\n")

            assert(self.prefs.mode == "quick" or self.prefs.mode == "normal", "Unknown mode: " .. tostring(self.prefs.mode))
            if self.prefs.mode == "quick" then
              -- We're in quick mode, just build a reciprocal exit
              d(f"Building a reciprocal exit from {room_id} to {self.info.previous.room_id}\n")
              result = setExit(room_id, self.info.previous.room_id, self.exits.stubs_reverse[self.exits.stubs[prev_dir]])
              d(f"Result: {tostring(result)}\n")
            else
              -- In normal mode, we build a stub back, because we want to
              -- ensure that the room we're in has an exit stub back to the
              -- room we just left.
              setExitStub(room_id, dir, true)
            end
          end
        end
      else
        d(f"We have seen this room {getRoomName(exit_room_id)} ({exit_room_id}) before, but it is not the one we just left.\n")
        d(f"Current room: ({room_id}) {getRoomName(room_id)}\n")
        if self.info and self.info.previous then
          d(f"Previous room: {self.info.previous.room_id} ({getRoomName(self.info.previous.room_id)})\n")
        end
        local result
        if self.prefs.mode == "quick" then
          d("We're in quick mode, so we'll just build the exit!\n")
          d("But not if it already exists!\n")
          if not getRoomExits(room_id)[dir] then
            d(f"Building exit {dir} from {room_id} to {exit_room_id}\n")
            setExit(room_id, exit_room_id, dir)
            local reverse_dir = self.exits.stubs[self.exits.stubs_reverse[self.exits.stubs[dir]]]
            d(f"Building reciprocal exit {reverse_dir} from {exit_room_id} to {room_id}\n")
            setExit(exit_room_id, room_id, reverse_dir)
          else
            d("The exit already exists!\n")
          end
        end
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
-- UpdateDoors
--
-- This function updates the doors for a room.
-- ----------------------------------------------------------------------------

---@param room_id number
function Carto:UpdateDoors(room_id)
  local info = self.info.current

  self.door_changes = {}

  -- Update room doors if they have changed
  local doors = info.doors or {}
  local current_doors = getDoors(room_id) or {}

  for dir, door_info in pairs(doors) do
    local old_status = current_doors[dir]
    d(f"Door {dir} - {old_status} -> {door_info.status}\n")
    local command = self.exits.reverse[dir]
    local door_status = tonumber(door_info.status)

    local door_result, err = setDoor(room_id, command, door_status)
    d(f"Door {dir} - {old_status} -> {door_info.status} - {door_result}\n")
    current_doors[command] = door_status
    if door_result == true then
      if old_status ~= door_status then
        table.insert(self.door_changes, {
          room_id = room_id,
          command = command,
          door_status = door_status,
          old_status = old_status,
        })
      end
    end
  end

  for dir, _ in pairs(current_doors) do
    if not doors[self.exits.map[dir]] then
      d(f"Deleting door {dir} in room {room_id}\n")
      setDoor(room_id, dir, 0)
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

function Carto:ResetState()
  self.walking = false
  self.speedwalk_path = {}
  self.walk_timer = nil
  self.walk_step = nil
  self.move_tracking = {}
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

  local event
  if self.walking then
    if exception then
      event = "onSpeedwalkReset"
    else
      event = "sysSpeedwalkFinished"
    end
  end

  self:ResetState()
  raiseEvent(event, exception, reason)

end

-- ----------------------------------------------------------------------------
-- Speedwalk
--
-- This function is called from doSpeedWalk. It checks for necessary
-- conditions and initiates the walking process if all checks pass.
-- ----------------------------------------------------------------------------

function Carto:Speedwalk()
  if not self.info then
    cecho(f"{self.config.name} cannot determine your current room.\n")
    return
  end

  if not self.info.current then
    cecho(f"{self.config.name} cannot determine your current room.\n")
    return
  end

  if self.walking then
    cecho("<orange>You are already walking!\n")
    return
  end

  self.speedwalk_path = {}
  if not next(self.info.current.exits) then
    cecho("<orange>No speedwalk direction found.\n")
    self:ResetWalking(true, "No speedwalk direction found.")
    return
  end

  if not next(speedWalkPath) then
    cecho("<orange>No speedwalk path found.\n")
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
  d(f"self.info.current.room_id: {self.info.current.room_id}\n")
  local room_exits = getRoomExits(self.info.current.room_id) or {}
  if not next(room_exits) then
    cecho("<orange>No exits found.\n")
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


  self.walking = true
  local destination_id = self.speedwalk_path[#self.speedwalk_path][2]
  local destination_name = getRoomName(destination_id)
  d(f"Walking to {destination_name} ({destination_id}) from {self.info.current.name} ({self.info.current.room_id}).\n")

  registerNamedTimer(
    self.config.name,
    self.walk_timer_name,
    self.prefs.speedwalk_delay,
    function() self:Step() end,
    false
  )

  stopNamedTimer(self.config.name, "Carto:Step")

  self:Step()

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
  -- Stop the timer. It will be resumed when they moved to the next room.
  -- Or not, if they've arrived at their destination.
  stopNamedTimer(self.config.name, self.walk_timer_name)

  if not next(self.speedwalk_path) then
    cecho(f"<chartreuse>You have arrived at {self.info.current.name}.\n")
    self:ResetWalking(false, "Arrived at destination.")
    return
  end

  local current_room_id = self.info.current.room_id
  if not current_room_id then
    cecho("<orange>Unable to determine your current location.\n")
    self:ResetWalking(true, "Unable to determine your current location.")
    return
  end

  local current_step = self.speedwalk_path[1]

  -- Check if this is the starting room (which doesn't have a direction)
  if current_step[1] == "" then
    if current_room_id ~= current_step[2] then
      cecho("<orange>You are not in the expected starting room.\n")
      cecho(f"<orange>Expected you to be in room {current_step[2]} ({getRoomName(current_step[2])}).\n")
      cecho(f"<orange>Current room: {current_room_id} ({getRoomName(current_room_id)}).\n")
      self:ResetWalking(true, "You are not in the expected starting room.")
      return
    end

    table.remove(self.speedwalk_path, 1)
    if not next(self.speedwalk_path) then
      cecho(f"<chartreuse>You have arrived at {self.info.current.name}.\n")
      return
    end
    self.walk_step = current_room_id
    -- We have to force a step here to move to the actual next room, since
    -- the first step is the starting room.
    self:Step()
    return
  end

  d(f"Current room: {current_room_id} ({getRoomName(current_room_id)})\n")
  d(f"Walk step: {self.walk_step} ({getRoomName(self.walk_step)})\n")
  -- Check if we're in the expected room before moving
  if current_room_id ~= self.walk_step then
    if next(self.move_tracking) then
      local last_move = self.move_tracking[#self.move_tracking]
      if last_move then
        if current_room_id == last_move.prev_room_id then
          cecho("<orange>Something prevents you from continuing.\n")
        else
          cecho("<orange>1. You have veered off the expected path.\n")
        end
      else
        cecho("<orange>2. You have veered off the expected path.\n")
      end
    else
      cecho("<orange>3. You have veered off the expected path.\n")
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
    cecho("<orange>Invalid direction: " .. dir .. "\n")
    self:ResetWalking(true, "Invalid direction.")
    return
  end

  d(f"Moving {full_dir} to {next_room_id} ({getRoomName(next_room_id)})\n")
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
  cecho(f"<chartreuse>Walk speed set to {self.prefs.speedwalk_delay} {unit} per step.\n")
end

-- ----------------------------------------------------------------------------
-- RememberRoom
--
-- This function saves the current room as a recall point for the current
-- profile.
-- ----------------------------------------------------------------------------

---@param position number|nil
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
    cecho(f"<orange>Room {room_id} ({getRoomName(room_id)}) is already in recall position {index}.\n")
    return
  end

  if self.prefs.recalls[position] then
    local existing_room_id = self.prefs.recalls[position]
    local existing_room_name = getRoomName(existing_room_id)
    cecho(f"<orange>Replacing room {existing_room_id} ({existing_room_name}) in recall position {position} with room {room_id} ({getRoomName(room_id)}).\n")
    self.prefs.recalls[position] = room_id
  else
    table.insert(self.prefs.recalls, position, room_id)
    cecho(f"<chartreuse>Room {room_id} ({getRoomName(room_id)}) has been saved to recall position {position}.\n")
  end

  self:SavePreferences()
end

-- ----------------------------------------------------------------------------
-- ForgetRoom
--
-- This function removes a recall point from the list of recalls.
-- ----------------------------------------------------------------------------

---@param position number|nil
function Carto:ForgetRoom(position)
  if not self.prefs.recalls then
    cecho("<orange>No recall points have been set.\n")
    return
  end

  if position == nil then
    local room_id = getPlayerRoom()
    position = table.index_of(self.prefs.recalls, room_id)
    if not position then
      cecho("<orange>You are not in a recall point.\n")
      return
    end
  end

  if not self.prefs.recalls[position] then
    cecho("<orange>No recall point at position " .. position .. ".\n")
    return
  end

  cecho(f"<chartreuse>Forgetting room {self.prefs.recalls[position]} ({getRoomName(self.prefs.recalls[position])}) at position {position}.\n")
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
    cecho("<orange>No recall points have been set.\n")
    return
  end

  if not self.prefs.recalls[position] then
    cecho("<orange>No recall point at position " .. position .. ".\n")
    return
  end

  local room_id = self.prefs.recalls[position]
  local room_name = getRoomName(room_id)
  cecho(f"<chartreuse>Recalling to room {room_id} ({room_name}).\n")
  gotoRoom(room_id)
end

-- ----------------------------------------------------------------------------
-- DisplayRecalls
--
-- This function displays all the recall points for the current profile.
-- ----------------------------------------------------------------------------

function Carto:DisplayRecalls()
  if #self.prefs.recalls < 1 then
    cecho("<orange>No recall points have been set.\n")
    return
  end

  cecho("<chartreuse>Recall points:\n")
  for position, room_id in pairs(self.prefs.recalls) do
    local room_name = getRoomName(room_id)
    cecho("<chartreuse>" .. string.format("  %2d: %s\n", position, room_name))
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
  local keys = gmcp_package:split("%.")

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

Type <h1>carto</h1> to see your current GMCP settings.
]],
    carto_config = f [[
<h1><u>{Carto.config.name}</u></h1>

Syntax: <b>carto</b> [<b>setting</b>] [<b>value</b>]

  <b>carto</b> - See this help text.
  <b>carto config</b> - See the current GMCP config settings for {Carto.config.name}.
  <b>carto mode</b> <<b>quick</b>|<b>normal</b>> - Set the mode for building exits.
  <b>carto event</b> <<b>event</b>> - Set the GMCP event for processing room updates.
  <b>carto expect_coordinates</b> <<b>true</b>|<b>false</b>> - Set to <b>true</b> to enable coordinate processing.
  <b>carto expect_hash</b> <<b>true</b>|<b>false</b>> - Set to <b>true</b> to enable hash processing.
  <b>carto properties</b> <<b>property</b>> <<b>value</b>> - Set the GMCP property settings for {Carto.config.name}.

<h1>Properties</h1>

These properties are used by {Carto.config.name} to process incoming GMCP data.
Since not all GMCP implementations are the same, you may have different
properties arriving than what are the defaults. You can use this command to
set the properties you that {Carto.config.name} should expect.
]],
  },
}
