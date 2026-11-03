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
---@field glu table -- Instance of Glu
Carto = Carto or {
  config = {
    name = script_name,                                     -- Name of the script
    package_name = "__PKGNAME__",                           -- Name of the package
    package_path = getMudletHomeDir() .. "/__PKGNAME__/",
    prefix = f [[{script_name}.]],                          -- Prefix for handlers
    preferences_file = f [[{script_name}.Preferences.lua]], -- Name of the preferences file
    speed_walk_fast = 0.5,                                  -- Speedwalk fast delay
    speed_walk_slow = 3.0,                                  -- Speedwalk slow delay
  },
  default = {
    mode = "quick",
    speedwalk_delay = 0.0,     -- Speedwalk delay
    speedwalk_delay_min = 0.0, -- Minimum speedwalk delay
    speedwalk_timeout = 5.0,   -- How long to wait for a step to land
    recalls = {},              -- Recall points for rooms
    -- The commands for getting through a door, which vary from game to game.
    -- {dir} is replaced with the full name of the direction.
    doors = {
      open = "open {dir}",
      unlock = "unlock {dir}",
    },
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
      n = "north",
      ne = "northeast",
      nw = "northwest",
      e = "east",
      w = "west",
      s = "south",
      se = "southeast",
      sw = "southwest",
      u = "up",
      d = "down",
      ["in"] = "in",
      out = "out",
    },
    -- Mapping of full exit names to abbreviations
    reverse = {
      north = "n",
      northeast = "ne",
      northwest = "nw",
      east = "e",
      west = "w",
      south = "s",
      southeast = "se",
      southwest = "sw",
      up = "u",
      down = "d",
      ["in"] = "in",
      out = "out",
    },
    -- Mapping of direction names to their numeric representations and vice versa
    stubs = {
      north = 1,
      northeast = 2,
      northwest = 3,
      east = 4,
      west = 5,
      south = 6,
      southeast = 7,
      southwest = 8,
      up = 9,
      down = 10,
      ["in"] = 11,
      out = 12,
      [1] = "north",
      [2] = "northeast",
      [3] = "northwest",
      [4] = "east",
      [5] = "west",
      [6] = "south",
      [7] = "southeast",
      [8] = "southwest",
      [9] = "up",
      [10] = "down",
      [11] = "in",
      [12] = "out",
    },
    -- Mapping of stubs in the reverse direction (n = s)
    stubs_reverse = {
      [1] = 6,
      [2] = 8,
      [3] = 7,
      [4] = 5,
      [5] = 4,
      [6] = 1,
      [7] = 3,
      [8] = 2,
      [9] = 10,
      [10] = 9,
      [11] = 12,
      [12] = 11,
    },
    vectors = {
      name = { --  x   y   z                   x   y   z
        north = { 0, 1, 0 },
        south = { 0, -1, 0 },
        east = { 1, 0, 0 },
        west = { -1, 0, 0 },
        northwest = { -1, 1, 0 },
        northeast = { 1, 1, 0 },
        southwest = { -1, -1, 0 },
        southeast = { 1, -1, 0 },
        up = { 0, 0, 1 },
        down = { 0, 0, -1 },
        ["in"] = { 0, 0, 0 },
        out = { 0, 0, 0 },
      },
      number = {
        [1] = { 0, 1, 0 },
        [2] = { 1, 1, 0 },
        [3] = { -1, 1, 0 },
        [4] = { 1, 0, 0 },
        [5] = { -1, 0, 0 },
        [6] = { 0, -1, 0 },
        [7] = { 1, -1, 0 },
        [8] = { -1, -1, 0 },
        [9] = { 0, 0, 1 },
        [10] = { 0, 0, -1 },
        [11] = { 0, 0, 0 },
        [12] = { 0, 0, 0 },
      }
    }
  },
  tags = {
    carto = { "%s", table.deepcopy(color_table["orange_red"]), table.deepcopy(color_table["orange"]) },
    warning = { "%s", table.deepcopy(color_table["orange"]), table.deepcopy(color_table["orange_red"]) },
    error = { "%s", table.deepcopy(color_table["red"]), table.deepcopy(color_table["orange_red"]) },
    info = { "%s", table.deepcopy(color_table["chartreuse"]), table.deepcopy(color_table["olive_drab"]) },
  },
  door_changes = {},
  speedwalk_path = {},   -- Speedwalk path
  walk_timer = nil,      -- Walk timer
  walk_timer_name = nil, -- Walk timer name
  step_timeout_name = script_name .. ".step_timeout", -- Can be cancelled before Setup
  walk_step = nil,       -- The next room id for the speedwalk
  dependencies = {
    { name = "Helper", url = "https://github.com/gesslar/Helper/releases/latest/download/Helper.mpackage" },
  },
  debug = false,
  glu = require("__PKGNAME__/vendor/Glu-single")("__PKGNAME__"),
}

-- For debugging. This takes the f template rather than its result, so that nothing
-- is evaluated with debugging off, and a template that can't be evaluated shows as
-- it was written instead of breaking the code it's reporting on. f finds the
-- caller's locals by walking up the stack, so they still resolve from in here.
local function d(template)
  if _d and Carto.debug == true then
    local ok, text = pcall(f, template)
    _d(ok and text or template, { colour = "maroon", skip = 1 })
  end
end

-- ----------------------------------------------------------------------------
-- Preferences
-- ----------------------------------------------------------------------------

function Carto:LoadPreferences()
  -- Glu handles file existence, load, and a recursive merge onto a copy of the
  -- defaults, so anything missing from the saved file is filled in at any depth.
  self.prefs = self.glu.preferences.load(
    nil, self.config.preferences_file, self.default
  )

  self:UpdateGMCPHandler()
end

function Carto:SavePreferences()
  self.glu.preferences.save(
    nil, self.config.preferences_file, self.prefs
  )
  self:UpdateGMCPHandler()
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
  self:LoadPreferences()

  -- Set custom environment colors for terrain types
  self:SetupEnvironment()

  self.walk_timer_name = self.config.prefix .. "walk_timer"

  for tag_name, tag_info in pairs(self.tags) do
    if tag_name == string.lower(self.config.name) then
      tag_info[1] = string.format(tag_info[1], string.lower(self.config.name))
    else
      tag_info[1] = string.lower(tag_name)
    end
  end

  gmod.enableModule(self.config.name, "Room")

  -- The same event the generic mapper raises, for scripts waiting on a mapper.
  if event == "sysLoadEvent" or event == "sysInstall" then
    raiseEvent("mapperScriptLoaded", self.config.package_name)
  end

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

-- Register the custom environment colors for each terrain type with the map.
-- These colors live inside the Mudlet map, so they are wiped whenever the map
-- is deleted/reset. We keep this separate from Setup so it can be re-applied on
-- demand (see AddOrUpdateRoom) instead of only on connection.
function Carto:SetupEnvironment()
  for _, data in pairs(self.terrain.types) do
    ---@diagnostic disable-next-line: deprecated
    local r, g, b = unpack(data.color)
    setCustomEnvColor(data.id, r, g, b, 255)
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
  }

  -- Register persistent event handlers. Registering a name again replaces it.
  for _, event in ipairs(self.event_handlers) do
    local handler = self.config.name .. "." .. event
    local result = registerNamedEventHandler(self.config.name, handler, event,
      function(...) self:EventHandler(...) end)
    if not result then
      cecho("<orange_red>Failed to register event handler for " .. event .. "\n")
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
  elseif event == "carto.config" then
    self:Config(event, ...)
  end
end

-- sysInstall must be on its own, outside of the event_handlers
-- since it will be called during the install process.
registerNamedEventHandler(
  Carto.config.name,
  "Carto:Install",
  "sysInstall",
  function(...) Carto:EventHandler(...) end,
  true
)
Carto:SetupEventHandlers()

function Carto:UpdateGMCPHandler()
  -- The handler is named after its event, so the one to replace goes by whichever
  -- event it was registered for, which may no longer be the one in the preferences.
  if self.gmcp_handler then
    deleteNamedEventHandler(self.config.name, self.gmcp_handler)
    self.gmcp_handler = nil
  end

  -- We need to add the gmcp one now based on the preferences
  if self.prefs.gmcp.event then
    registerNamedEventHandler(
      self.config.name,
      self.prefs.gmcp.event,
      self.prefs.gmcp.event,
      function(...) self:EventHandler(...) end
    )
    self.gmcp_handler = self.prefs.gmcp.event
  end
end

-- ----------------------------------------------------------------------------
-- Dependencies
--
-- Uses Glu's dependency_queue glass to install any missing required packages.
-- It filters out packages that are already installed, installs the rest in
-- sequence, and invokes the callback once finished. On success we proceed with
-- Setup; on failure we tell the user to install the dependencies manually.
-- ----------------------------------------------------------------------------

function Carto:InstallDependencies()
  local queue = self.glu.dependency_queue.new_dependency_queue(
    self.dependencies,
    function(success, message)
      if success then
        self:Setup("sysInstall", self.config.package_name)
      else
        local fb =
          "Could not install all dependencies, please install " ..
          "them manually."

        cecho("\n")
        cecho(f "<orange_red>{message or fb}\n")
      end
    end
  )

  -- new_dependency_queue returns nil when every dependency is already
  -- installed (the callback has already fired); only start a real queue.
  if queue then
    queue.start()
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
    helper.print({ text = self.help.topics.carto_config, styles = self.help_styles })
    return
  elseif setting == "config" then
    self:DisplayGMCPConfig(event)
    return
  elseif setting == "room" then
    if value and value ~= "" and not tonumber(value) then
      cecho("<orange_red>Syntax: carto room [room_id]\n")
      return
    end
    self:DisplayRoom(tonumber(value))
    return
  elseif setting == "doors" then
    self:ConfigDoors(value)
    return
  elseif setting == "event" then
    if not value or value == "" then
      cecho(f "<orange_red>Syntax: carto event <event>\n")
      return
    end
    self.prefs.gmcp.event = value
  elseif setting == "expect_coordinates" then
    if value == "true" then
      self.prefs.gmcp.expect_coordinates = true
    elseif value == "false" then
      self.prefs.gmcp.expect_coordinates = false
    else
      cecho(f "<orange_red>Syntax: carto expect_coordinates <true|false>\n")
      return
    end
  elseif setting == "expect_hash" then
    if value == "true" then
      self.prefs.gmcp.expect_hash = true
    elseif value == "false" then
      self.prefs.gmcp.expect_hash = false
    else
      cecho(f "<orange_red>Syntax: carto expect_hash <true|false>\n")
      return
    end
  elseif setting == "mode" then
    if value ~= "quick" and value ~= "normal" then
      cecho(f "<orange_red>Unknown mode: {value}.\n")
      cecho(f "<orange_red>Valid modes are: quick, normal\n")
      return
    else
      self.prefs.mode = value
    end
  elseif setting == "properties" then
    if not value or value == "" then
      self:DisplayGMCPProperties()
      return
    else
      local parts = value:split(" ")
      ---@diagnostic disable-next-line: deprecated
      local p, v = unpack(parts)
      if p and p ~= "" and v and v ~= "" then
        if not self.default.gmcp.properties[p] then
          cecho(f "<orange_red>Unknown property {p}.\n")
          return
        end
        self.prefs.gmcp.properties[p] = v
        echo("Property " .. p .. " set to " .. v .. ".\n")
      else
        cecho(f "<orange_red>Syntax: carto properties <property> <value>\n")
        return
      end
    end
  else
    cecho(f "<orange_red>No such setting: {setting}.\n")
    return
  end

  cecho(f "<chartreuse>Setting {setting} to {value}.\n")

  self:SavePreferences()
end

---Shows or sets the door commands. These come from the user and go to the game, so
---they're only ever filled in with the direction, never evaluated.
---@param value string|nil "<open|unlock> <command>", or nothing to show them
function Carto:ConfigDoors(value)
  local action, command = (value or ""):match("^(%S*)%s*(.*)$")

  if action == "" then
    cecho("<hot_pink>Carto door commands:\n")
    for _, name in ipairs({ "open", "unlock" }) do
      cecho(f "<hot_pink>  {name}<reset> = ")
      echo(self.prefs.doors[name] .. "\n")
    end
    return
  end

  if not self.default.doors[action] or command == "" then
    cecho("<orange_red>Syntax: carto doors <open|unlock> <command>\n")
    return
  end

  self.prefs.doors[action] = command
  self:SavePreferences()

  cecho(f "<chartreuse>Setting door command {action} to: ")
  echo(command .. "\n")
end

function Carto:DisplayGMCPConfig(event)
  cecho("<hot_pink>Carto GMCP config:\n\n")
  -- Display base config
  for property, value in pairs(self.prefs.gmcp) do
    if property ~= "properties" then
      cecho(f "<hot_pink>{property}<reset> = {tostring(value)}\n")
    end
  end

  -- Display properties config
  if self.prefs.gmcp.properties then
    self:DisplayGMCPProperties()
  end
end

function Carto:DisplayGMCPProperties()
  cecho("  <hot_pink>properties:\n")
  for property, value in pairs(self.prefs.gmcp.properties) do
    cecho(f "<hot_pink>  {property}<reset> = {tostring(value)}\n")
  end
end

-- ----------------------------------------------------------------------------
-- Utility Functions
-- ----------------------------------------------------------------------------

---@param event string
---@param ... any
function Carto:Disconnect(event, ...)
  self:ResetWalking(true, "Disconnected from the mud.")

  -- Wherever we turn up next, we won't have walked there from this room.
  self.info = {}
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
      cecho(f "<chartreuse>Uninstalling package: generic_mapper\n")
      uninstallPackage("generic_mapper")
      tempTimer(1, function()
        if (table.contains(getPackages(), "generic_mapper")) then
          cecho(f "<orange_red>Could not uninstall generic_mapper.\n")
          cecho(f "<orange_red>Please uninstall it manually and restart Mudlet.\n")
          return
        end
      end)
    end)
  end

  deleteNamedEventHandler(self.config.name, "Carto:Install")

  -- Install any missing dependencies first; Setup runs from the callback once
  -- they are all present (or immediately if nothing is missing).
  self:InstallDependencies()
end

---@param event string
---@param package string
function Carto:Uninstall(event, package)
  if package ~= self.config.package_name then
    return
  end

  if self.walking then
    cecho(f "<chartreuse>Resetting walking.\n")
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
  d("Event = {event}, GMCP package = {gmcp_package}\n")

  local gmcp_table = self:TableFromPackage(gmcp_package) or {}

  self.info.previous = self.info.current

  d([[We expect {self.prefs.gmcp.expect_hash and "hash" or "vnum"}]])

  if self.prefs.gmcp.expect_hash then
    if not gmcp_table[self.prefs.gmcp.properties.hash] then return end
  else
    if not gmcp_table[self.prefs.gmcp.properties.vnum] then return end
  end

  d([[Received {self.prefs.gmcp.expect_hash and "hash" or "vnum"} {gmcp_table[self.prefs.gmcp.expect_hash and "hash" or "vnum"]}]])

  -- Record the room we've entered
  self.info.current = {
    hash = gmcp_table[self.prefs.gmcp.properties.hash],
    vnum = gmcp_table[self.prefs.gmcp.properties.vnum],
    area = gmcp_table[self.prefs.gmcp.properties.area],
    name = gmcp_table[self.prefs.gmcp.properties.name],
    environment = gmcp_table[self.prefs.gmcp.properties.environment],
    symbol = gmcp_table[self.prefs.gmcp.properties.symbol],
    exits = self:NormaliseDirections(gmcp_table[self.prefs.gmcp.properties.exits]),
    doors = self:NormaliseDirections(gmcp_table[self.prefs.gmcp.properties.doors]),
    type = gmcp_table[self.prefs.gmcp.properties.type],
    subtype = gmcp_table[self.prefs.gmcp.properties.subtype],
    icon = gmcp_table[self.prefs.gmcp.properties.icon],
  }

  local room_id = self:AddOrUpdateRoom(self.info.current)
  d("Room ID for {self.info.current.name} is {room_id}\n")
  if room_id == -1 then
    cecho(f "<orange_red>Failed to add room.\n")
    return
  end

  d("Recording room ID {room_id} for room {getRoomName(room_id)}\n")
  self.info.current.room_id = room_id

  self:UpdateCoordinates(room_id, gmcp_table)
  self:UpdateExits(room_id)
  self:UpdateDoors(room_id)

  centerview(room_id)

  d("Updating map.\n")
  updateMap()

  raiseEvent("onMoveMap", room_id)

  if table.size(self.door_changes) > 0 then
    d("Updating doors.\n")
    for _, door in ipairs(self.door_changes) do
      d("Door {door.command} in room {door.room_id} changed to {door.door_status}.\n")
      raiseEvent("onDoorChange", door.room_id, door.command, door.door_status, door.old_status)
    end
  end

  d("Walking = {self.walking}\n")

  -- A room also updates without anyone having moved, as when anybody opens a door
  -- in it, and that says nothing about the step we're waiting on.
  local previous = self.info.previous
  if not previous or previous.room_id ~= room_id then
    self.step_in_flight = false
    self:CancelStepTimeout()

    -- Take the next step in the speedwalk, at the current speed, which may have
    -- changed since the last one.
    if self.walking and not self.paused then
      registerNamedTimer(
        self.config.name,
        self.walk_timer_name,
        self.prefs.speedwalk_delay,
        function() self:Step() end
      )
    end
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
    d("The room we have entered doesn't exist yet.\n")
    if room_id == -1 then
      room_id = createRoomID()
      if not addRoom(room_id) then
        d("Failed to add room\n")
        return -1
      end
      setRoomIDbyHash(room_id, info.hash)
      info.is_new = true
      d("Added room {room_id} with hash {info.hash}\n")
    else
      d("Room {room_id} already exists with hash {info.hash}\n")
    end
  else
    d("Expecting vnum\n")
    d("Vnum: {info.vnum}\n")
    local name = getRoomName(info.vnum)
    if not name then
      d("Adding room\n")
      local result = addRoom(info.vnum)
      d("Result: {result}\n")
      if not result then
        d("Failed to add room\n")
        return -1
      else
        d("Added room {name}\n")
      end
      info.is_new = true
      room_id = info.vnum
      d("Setting room ID to {room_id}\n")
    else
      d("Room ID already exists as {name}\n")
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

  -- Custom env colors are stored in the map and are wiped when the map is
  -- deleted/reset. Re-register them if they have gone missing so rooms paint
  -- correctly without needing to reconnect.
  if not next(getCustomEnvColorTable()) then
    self:SetupEnvironment()
  end

  local terrain = self.terrain.types[info.environment] or self.terrain.types["default"]
  local env_id = terrain.id

  -- Terrain rules only apply when the terrain changes, which includes a room's
  -- first visit, so that locks and weights set by hand survive walking through.
  if getRoomEnv(room_id) ~= env_id then
    setRoomEnv(room_id, env_id)

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
  end

  if info.icon and utf8.len(info.icon) > 0 then
    setRoomChar(room_id, info.icon)
  elseif type(info.symbol) == "string" and utf8.len(info.symbol) > 0 then
    setRoomChar(room_id, info.symbol)
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
---Normalises a GMCP coordinates value into a numeric {x, y, z} table.
---Servers may send coords as an array, or as a delimited string ("x,y,z" or
---"x y z"). table.concat / unpack downstream require an actual table of numbers.
---@param coords table|string The raw coordinates value from GMCP
---@return table coords A table of numbers
function Carto:NormaliseCoordinates(coords)
  if type(coords) == "table" then
    return coords
  end

  local result = {}

  if type(coords) == "string" then
    for part in coords:gmatch("[^%s,]+") do
      result[#result + 1] = tonumber(part) or part
    end
  end

  return result
end

---Normalises a GMCP table keyed by direction so that standard directions always
---use their full names, whichever form the server sends. Everything downstream,
---as well as getRoomExits, works in full names. Other keys are left as they are.
---@param by_direction any The raw exits or doors value from GMCP
---@return table|nil normalised A copy of the table, or nil if there wasn't one
function Carto:NormaliseDirections(by_direction)
  if type(by_direction) ~= "table" then
    return nil
  end

  local result = {}

  for dir, value in pairs(by_direction) do
    result[self.exits.map[dir] or dir] = table.deepcopy(value)
  end

  return result
end

function Carto:UpdateCoordinates(room_id, gmcp_table)
  d("Updating coordinates for room {tostring(room_id)}\n")

  if self.info.previous and self.info.previous.room_id then
    if room_id == self.info.previous.room_id then
      d("We have not moved to a new room. Exiting.\n")
      return
    end
  end

  local gmcp_coords

  if self.prefs.gmcp.expect_coordinates then
    d("We are expecting coordinates.\n")
    gmcp_coords = self:NormaliseCoordinates(gmcp_table[self.prefs.gmcp.properties.coords])
  end

  if gmcp_coords and #gmcp_coords == 3 then
    self.info.current.coords = gmcp_coords
    d("Coordinates received via GMCP: {table.concat(self.info.current.coords, ', ')}\n")
  else
    if self.prefs.gmcp.expect_coordinates then
      d("Expected GMCP coordinates but none were usable; calculating instead.\n")
    else
      d("We are not expecting coordinates.\n")
    end

    -- Calculating is only a best guess at where to put a room we've never seen.
    -- A room already on the map stays put, or logging in would send it to the
    -- origin and teleporting would stack it on top of the room we came from.
    if not self.info.current.is_new then
      d("Room {room_id} is already on the map. Keeping its coordinates.\n")
      self.info.current.coords = { getRoomCoordinates(room_id) }
      return
    end

    local prev_room_id = self.info.previous and self.info.previous.room_id or nil
    self.info.current.coords = self:CalculateCoordinates(room_id, prev_room_id)
    d("Calculated coordinates: {table.concat(self.info.current.coords, ', ')}\n")
  end

  if #self.info.current.coords == 3 then
    local x, y, z = unpack(self.info.current.coords)
    setRoomCoordinates(room_id, x, y, z)
  else
    d("Coordinates not set for room {room_id}\n")
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
  d("Calculating coordinates for room {tostring(curr_room_id)}\n")
  local default_coordinates = { 0, 0, 0 }

  if not prev_room_id then return default_coordinates end

  local x, y, z = getRoomCoordinates(prev_room_id)
  d("Previous room coordinates: {table.concat({x, y, z}, ', ')}\n")
  local coords
  if not x or not y or not z then
    coords = default_coordinates
  else
    coords = { x, y, z }
  end

  d("Previous room: {getRoomName(prev_room_id)} ({prev_room_id})\n")

  local shift = { 0, 0, 0 }
  local compare_field
  if self.prefs.gmcp.expect_hash then
    compare_field = "hash"
  else
    compare_field = "vnum"
  end

  d("Comparing current and previous {compare_field}\n")
  for dir, hash in pairs(self.info.previous.exits or {}) do
    local current_hash = self.info.current[compare_field]
    d("  Checking {compare_field}: {dir} - {hash} against {current_hash}")
    if hash == current_hash and self.exits.vectors.name[dir] then
      shift = self.exits.vectors.name[dir]
      break
    end
  end

  d("Shift vector: {table.concat(shift, ', ')}\n")
  for n = 1, 3 do
    coords[n] = coords[n] + shift[n]
  end

  return coords
end

---Finds the room an exit from the GMCP leads to.
---@param destination string|number The exit's hash or vnum
---@return number room_id The room's ID, or -1 if it isn't on the map yet
function Carto:ExitRoomId(destination)
  if self.prefs.gmcp.expect_hash then
    return getRoomIDbyHash(destination)
  end

  local vnum = tonumber(destination)

  return vnum and getRoomName(vnum) and vnum or -1
end

---Whether an entry in the GMCP exits is a special exit, which is any entry that
---isn't a standard direction: its key is the command to send, and its value is the
---hash or vnum it leads to, the same as any other exit.
---
---Speedwalking runs a special exit starting with "script:" as Lua, so one of those
---is only ever accepted from the user, and never from the server.
---@param command any The key from the GMCP exits
---@param destination any The value from the GMCP exits
---@return boolean
function Carto:IsSpecialExit(command, destination)
  return type(command) == "string"
    and not self.exits.reverse[command]
    and not command:lower():match("^%s*script:")
    and (type(destination) == "string" or type(destination) == "number")
end

---@param from_id number
---@param to_id number
---@param command string
function Carto:SetSpecialExit(from_id, to_id, command)
  if (getSpecialExitsSwap(from_id) or {})[command] ~= to_id then
    d("Building a special exit {command} from {from_id} to {to_id}\n")
    addSpecialExit(from_id, to_id, command)
  end
end

-- Connect the room we just left to this one, in every direction where it listed
-- an exit leading here. This doesn't depend on there being a way back, so one-way
-- exits get mapped too.
---@param room_id number
function Carto:LinkPreviousRoom(room_id)
  local previous = self.info.previous

  if not previous or not previous.room_id then
    return
  end

  local compare_field = self.prefs.gmcp.expect_hash and "hash" or "vnum"
  local destination = self.info.current[compare_field]
  local previous_exits = getRoomExits(previous.room_id) or {}

  for prev_dir, prev_dest in pairs(previous.exits or {}) do
    d("Comparing {prev_dir} - {prev_dest} against {destination}\n")
    if prev_dest == destination then
      if self.exits.reverse[prev_dir] then
        if previous_exits[prev_dir] ~= room_id then
          d("Building an exit {prev_dir} from {previous.room_id} to {room_id}\n")
          setExit(previous.room_id, room_id, prev_dir)
        end
      elseif self:IsSpecialExit(prev_dir, prev_dest) then
        self:SetSpecialExit(previous.room_id, room_id, prev_dir)
      end
    end
  end
end

---@param room_id number
function Carto:UpdateExits(room_id)
  d("Updating exits for room {room_id} - {getRoomName(room_id)}\n")

  local previous = self.info.previous
  local current = self.info.current

  -- A server that leaves the exits out of the GMCP hasn't told us anything about
  -- them, which isn't the same as telling us there are none.
  if not current.exits then
    d("No exits in the GMCP for room {room_id}. Leaving its exits alone.\n")
    return
  end

  self:LinkPreviousRoom(room_id)

  local current_exits = getRoomExits(room_id) or {}
  local current_stubs = getExitStubs1(room_id) or {}

  -- Iterate through the exits from the GMCP event in the room where we have
  -- arrived, adding new exit stubs for places we haven't seen before.
  for dir, id in pairs(current.exits) do
    if self.exits.reverse[dir] then
      local stub_dir = self.exits.stubs[dir]
      local exit_room_id = self:ExitRoomId(id)

      if exit_room_id == -1 then
        -- This exit leads to a room we haven't seen before
        d("We haven't seen the {dir} exit before. Creating an exit stub in that direction.\n")
        d("Checking exit stub {dir} ({stub_dir})\n")
        if table.index_of(current_stubs, stub_dir) then
          d("  Exit stub {dir} ({stub_dir}) already exists. Skipping.\n")
        else
          d("  Exit stub {dir} ({stub_dir}) does not exist. Creating it.\n")
          setExitStub(room_id, stub_dir, true)
        end
      elseif previous and exit_room_id == previous.room_id then
        -- This exit leads back to the room we just left.
        d("Exit {dir} leads to the room we've just left {getRoomName(exit_room_id)} ({exit_room_id}).\n")
        if self.prefs.mode == "quick" then
          -- We're in quick mode, just build the exit back. The way back isn't
          -- always the opposite of the way we came, so use the one we were given.
          if current_exits[dir] ~= exit_room_id then
            d("Building a reciprocal exit {dir} from {room_id} to {exit_room_id}\n")
            setExit(room_id, exit_room_id, dir)
          end
        elseif not current_exits[dir] then
          -- In normal mode, we build a stub back, because we want to ensure that
          -- the room we're in has an exit stub back to the room we just left.
          setExitStub(room_id, stub_dir, true)
        end
      else
        d("We have seen this room {getRoomName(exit_room_id)} ({exit_room_id}) before, but it is not the one we just left.\n")
        d("Current room: ({room_id}) {getRoomName(room_id)}\n")
        if previous and previous.room_id then
          d("Previous room: {previous.room_id} ({getRoomName(previous.room_id)})\n")
        end
        if self.prefs.mode == "quick" then
          d("We're in quick mode, so we'll just build the exit!\n")
          d("But not if it already exists!\n")
          if current_exits[dir] ~= exit_room_id then
            d("Building exit {dir} from {room_id} to {exit_room_id}\n")
            setExit(room_id, exit_room_id, dir)
            -- The reciprocal is only a guess, so it must not replace an exit
            -- that room already has in that direction.
            local reverse_dir = self.exits.stubs[self.exits.stubs_reverse[stub_dir]]
            if not (getRoomExits(exit_room_id) or {})[reverse_dir] then
              d("Building reciprocal exit {reverse_dir} from {exit_room_id} to {room_id}\n")
              setExit(exit_room_id, room_id, reverse_dir)
            end
          else
            d("The exit already exists!\n")
          end
        end
      end
    elseif self.prefs.mode == "quick" and self:IsSpecialExit(dir, id) then
      -- A special exit has no stub to stand in for it, so one to a room we haven't
      -- seen yet waits until we have, or until we walk through it.
      local exit_room_id = self:ExitRoomId(id)
      if exit_room_id ~= -1 then
        self:SetSpecialExit(room_id, exit_room_id, dir)
      end
    end
  end

  -- Special exits aren't removed along with the others below. They can be added by
  -- hand or come with an inherited map, and we can't tell those from the server's.

  -- Remove exits that no longer exist
  for dir, _ in pairs(current_exits) do
    if not current.exits[dir] then
      setExit(room_id, -1, dir)
    end
  end

  -- Likewise for exit stubs
  for _, stub_dir in ipairs(current_stubs) do
    if not current.exits[self.exits.stubs[stub_dir]] then
      setExitStub(room_id, stub_dir, false)
    end
  end
end

-- ----------------------------------------------------------------------------
-- UpdateDoors
--
-- This function updates the doors for a room.
-- ----------------------------------------------------------------------------

---The name a door goes by in the map. setDoor wants "up" and "down" in full, and all
---the others short. Anything that isn't a standard direction is a special exit,
---which goes by its name.
---@param dir string The full name of a direction, or a special exit
---@return string command
function Carto:DoorCommand(dir)
  return (dir == "up" or dir == "down") and dir or self.exits.reverse[dir] or dir
end

---@param room_id number
function Carto:UpdateDoors(room_id)
  local info = self.info.current

  self.door_changes = {}

  -- Update room doors if they have changed
  local doors = info.doors or {}
  local current_doors = getDoors(room_id) or {}

  for dir, door_info in pairs(doors) do
    local command = self:DoorCommand(dir)
    local old_status = current_doors[command]
    local door_status = type(door_info) == "table" and tonumber(door_info.status) or nil

    if door_status then
      d("Door {dir} - {old_status} -> {door_status}\n")
      local door_result, err = setDoor(room_id, command, door_status)
      d("Door {dir} - {old_status} -> {door_status} - {door_result}\n")
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
    else
      d("Door {dir} has no usable status. Skipping it.\n")
    end
  end

  for dir, old_status in pairs(current_doors) do
    if not doors[self.exits.map[dir] or dir] then
      d("Deleting door {dir} in room {room_id}\n")
      if setDoor(room_id, dir, 0) == true then
        table.insert(self.door_changes, {
          room_id = room_id,
          command = dir,
          door_status = 0,
          old_status = old_status,
        })
      end
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
  -- Uninstalling removes Carto, but Mudlet can still call this from the map.
  if Carto then
    Carto:Speedwalk()
  end
end

function Carto:ResetState()
  self.walking = false
  self.speedwalk_path = {}
  self.walk_timer = nil
  self.walk_step = nil
  self.walk_destination = nil
  self.paused = false
  self.step_in_flight = false
end

-- ----------------------------------------------------------------------------
-- ResetWalking
--
-- This function resets the walking state and raises events when the walking
-- process is interrupted or completed.
-- ----------------------------------------------------------------------------

---@param exception boolean
---@param reason string
---@param event string|nil The event to raise, if not the usual one for exception
function Carto:ResetWalking(exception, reason, event)
  if table.contains(getNamedTimers(self.config.name), self.walk_timer_name) then
    deleteNamedTimer(self.config.name, self.walk_timer_name)
  end

  self:CancelStepTimeout()

  local was_walking = self.walking

  self:ResetState()

  if was_walking then
    event = event or (exception and "onSpeedwalkReset" or "sysSpeedwalkFinished")
    raiseEvent(event, exception, reason)
  end
end

-- ----------------------------------------------------------------------------
-- PauseWalking / ResumeWalking
--
-- Pausing holds the walk where it is, and the character is free to go elsewhere
-- in the meantime. Resuming finds a new path to the destination if they did.
-- ----------------------------------------------------------------------------

function Carto:PauseWalking()
  if not self.walking then
    cecho("<orange>You are not walking.\n")
    return
  end

  if self.paused then
    cecho("<orange>Your walk is already paused.\n")
    return
  end

  self.paused = true
  deleteNamedTimer(self.config.name, self.walk_timer_name)
  self:CancelStepTimeout()
  raiseEvent("sysSpeedwalkPaused")
  cecho("<chartreuse>Speedwalk paused.\n")
end

function Carto:ResumeWalking()
  if not self.walking then
    cecho("<orange>You are not walking.\n")
    return
  end

  if not self.paused then
    cecho("<orange>Your walk is not paused.\n")
    return
  end

  self.paused = false
  raiseEvent("sysSpeedwalkResumed")
  cecho("<chartreuse>Speedwalk resumed.\n")

  -- The last step we sent hasn't landed yet, so Move will carry on when it does.
  if self.step_in_flight then
    self:ArmStepTimeout()
    return
  end

  local current_room_id = self.info.current.room_id
  if current_room_id ~= self.walk_step and not self:FindNewPath(current_room_id) then
    cecho("<orange>No path to your destination from here.\n")
    self:ResetWalking(true, "No path to the destination.")
    return
  end

  self:Step()
end

---Replaces what's left of the walk with a path from the given room.
---@param room_id number
---@return boolean found Whether there is a path to the destination
function Carto:FindNewPath(room_id)
  self.walk_step = room_id

  if room_id == self.walk_destination then
    self.speedwalk_path = {}
    return true
  end

  if not getPath(room_id, self.walk_destination) then
    return false
  end

  self.speedwalk_path = self:PathFromSpeedwalkGlobals()

  return true
end

---Reads the path that Mudlet leaves in speedWalkDir and speedWalkPath.
---@return table path A list of {direction, room_id} steps
function Carto:PathFromSpeedwalkGlobals()
  local path = {}

  ---@diagnostic disable-next-line: param-type-mismatch
  for i, dir in ipairs(speedWalkDir) do
    table.insert(path, { dir, tonumber(speedWalkPath[i]) })
  end

  return path
end

---Tells the user and any listening scripts that a walk they asked for won't happen.
---A walk already under way isn't affected, so this doesn't go through ResetWalking.
---@param reason string
function Carto:WalkNotStarted(reason)
  cecho("<orange>" .. reason .. "\n")
  raiseEvent("onSpeedwalkFailed", reason)
end

-- ----------------------------------------------------------------------------
-- Speedwalk
--
-- This function is called from doSpeedWalk. It checks for necessary
-- conditions and initiates the walking process if all checks pass.
-- ----------------------------------------------------------------------------

function Carto:Speedwalk()
  if not self.info or not self.info.current or not self.info.current.room_id then
    self:WalkNotStarted(f "{self.config.name} cannot determine your current room.")
    return
  end

  if self.walking then
    self:WalkNotStarted("You are already walking!")
    return
  end

  self.speedwalk_path = {}

  if not next(speedWalkPath) then
    self:WalkNotStarted("No speedwalk path found.")
    return
  end

  self.speedwalk_path = self:PathFromSpeedwalkGlobals()

  -- The path has to start from here. It may start through a special exit, which
  -- getRoomExits doesn't list.
  d("self.info.current.room_id: {self.info.current.room_id}\n")
  local current_room_id = self.info.current.room_id
  local first_room_id = self.speedwalk_path[1][2]
  if not table.contains(getRoomExits(current_room_id) or {}, first_room_id)
    and not table.contains(getSpecialExitsSwap(current_room_id) or {}, first_room_id) then
    self.speedwalk_path = {}
    self:WalkNotStarted("No exits found.")
    return
  end

  -- speedWalkDir does not include the current room, so add it as the starting
  -- step, which is the one step that has no direction.
  table.insert(self.speedwalk_path, 1, { "", current_room_id })

  self.walking = true
  local destination_id = self.speedwalk_path[#self.speedwalk_path][2]
  self.walk_destination = destination_id
  local destination_name = getRoomName(destination_id)
  d("Walking to {destination_name} ({destination_id}) from {self.info.current.name} ({self.info.current.room_id}).\n")

  raiseEvent("sysSpeedwalkStarted")

  self:Step()
end

-- ----------------------------------------------------------------------------
-- Step
--
-- This function performs a single step in the speedwalk process. It checks
-- the current room's ID against the expected room's ID, handles the starting
-- room, and sends the appropriate direction command to move to the next room.
--
-- It is called directly by Speedwalk to take the first step, and after that by
-- the timer that Move sets each time a step lands.
-- ----------------------------------------------------------------------------

function Carto:Step()
  if self.paused then
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
  if current_step and current_step[1] == "" then
    if current_room_id ~= current_step[2] then
      cecho("<orange>You are not in the expected starting room.\n")
      cecho(f "<orange>Expected you to be in room {current_step[2]} ({getRoomName(current_step[2])}).\n")
      cecho(f "<orange>Current room: {current_room_id} ({getRoomName(current_room_id)}).\n")
      self:ResetWalking(true, "You are not in the expected starting room.")
      return
    end

    table.remove(self.speedwalk_path, 1)
    self.walk_step = current_room_id
    -- We have to force a step here to move to the actual next room, since
    -- the first step is the starting room.
    self:Step()
    return
  end

  d("Current room: {current_room_id} ({getRoomName(current_room_id)})\n")
  d("Walk step: {self.walk_step} ({getRoomName(self.walk_step)})\n")
  -- Check if we're in the expected room before moving
  if current_room_id ~= self.walk_step then
    cecho("<orange>You have veered off the expected path.\n")
    self:ResetWalking(true, "You have veered off the expected path.")
    return
  end

  -- We're where we should be. If that's the end of the path, we've arrived.
  if not current_step then
    cecho(f "<chartreuse>You have arrived at {self.info.current.name}.\n")
    self:ResetWalking(false, "Arrived at destination.")
    return
  end

  -- Now we're dealing with a regular step
  ---@diagnostic disable-next-line: deprecated
  local dir, next_room_id = unpack(current_step)

  self.walk_step = next_room_id

  d("Moving {dir} to {next_room_id} ({getRoomName(next_room_id)})\n")

  self.step_in_flight = true
  self:OpenDoor(current_room_id, dir)

  -- Special exits are either a script to run or a command to send as it is.
  local script = dir:match("^script:(.*)$")
  if script then
    local ok, err = pcall(function() assert(loadstring(script))() end)
    if not ok then
      cecho(f "<orange>The special exit script failed: {err}\n")
      self:ResetWalking(true, "The special exit script failed.")
      return
    end
  else
    send(self.exits.map[dir] or self.exits.reverse[dir] or dir, true)
  end

  -- Remove the current step as we've just executed it
  table.remove(self.speedwalk_path, 1)

  self:ArmStepTimeout()
end

-- ----------------------------------------------------------------------------
-- Step timeout
--
-- A move that fails doesn't have to tell us anything, and the room may well update
-- for other reasons in the meantime, so the only sign that a step didn't work is
-- that we're still waiting for it after a while.
-- ----------------------------------------------------------------------------

function Carto:ArmStepTimeout()
  if self.prefs.speedwalk_timeout > 0 then
    registerNamedTimer(
      self.config.name,
      self.step_timeout_name,
      self.prefs.speedwalk_timeout,
      function()
        cecho("<orange>Something prevents you from continuing.\n")
        self:ResetWalking(true, "Something prevents you from continuing.")
      end
    )
  end
end

function Carto:CancelStepTimeout()
  deleteNamedTimer(self.config.name, self.step_timeout_name)
end

---@param timeout any Seconds to wait for a step, or 0 to wait for as long as it takes
function Carto:SetSpeedwalkTimeout(timeout)
  timeout = tonumber(timeout)
  if not timeout or timeout < 0 then
    cecho("<orange>Walk timeout must be a number of seconds, or 0 for none.\n")
    return
  end

  self.prefs.speedwalk_timeout = timeout
  self:SavePreferences()

  local unit = timeout == 1 and "second" or "seconds"
  cecho(f "<chartreuse>Walk timeout set to {timeout} {unit}.\n")
end

---Sends what it takes to get through any door the map has in this direction, going
---by the status the map has for it: 1 is open, 2 is closed, and 3 is locked. Doors
---on special exits are left alone, because the exit's command is all we know.
---@param room_id number
---@param dir string
function Carto:OpenDoor(room_id, dir)
  local direction = self.exits.map[dir] or dir

  if not self.exits.reverse[direction] then
    return
  end

  local status = (getDoors(room_id) or {})[self:DoorCommand(direction)]

  local function door_command(action)
    return (self.prefs.doors[action]:gsub("{dir}", direction))
  end

  if status == 3 then
    send(door_command("unlock"), true)
  end

  if status == 2 or status == 3 then
    send(door_command("open"), true)
  end
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
  delay = tonumber(delay)
  if not delay then
    cecho("<orange>Walk speed must be a number of seconds.\n")
    return
  end

  if delay < self.prefs.speedwalk_delay_min and not override then
    delay = self.prefs.speedwalk_delay_min
  end

  self.prefs.speedwalk_delay = delay
  self:SavePreferences()

  local unit = self.prefs.speedwalk_delay == 1 and "second" or "seconds"
  cecho(f "<chartreuse>Walk speed set to {self.prefs.speedwalk_delay} {unit} per step.\n")
end

-- ----------------------------------------------------------------------------
-- RememberRoom
--
-- This function saves the current room as a recall point for the current
-- profile.
-- ----------------------------------------------------------------------------

---The room the player is in. getPlayerRoom only answers while a map is open, but
---we know where they are from the GMCP whether it is or not.
---@return number|nil room_id
function Carto:CurrentRoomId()
  return self.info.current and self.info.current.room_id or getPlayerRoom()
end

---@param position number|nil
function Carto:RememberRoom(position)
  local room_id = self:CurrentRoomId()

  if not room_id then
    cecho("<orange>Unable to determine your current location.\n")
    return
  end

  if position == nil then
    position = #self.prefs.recalls + 1
  else
    if position < 1 or position ~= math.floor(position) then
      cecho("<orange>A recall position must be a whole number of at least 1.\n")
      return
    end

    if position > #self.prefs.recalls then
      position = #self.prefs.recalls + 1
    end
  end

  local index = table.index_of(self.prefs.recalls, room_id)
  if index then
    cecho(f "<orange>Room {room_id} ({getRoomName(room_id)}) is already in recall position {index}.\n")
    return
  end

  if self.prefs.recalls[position] then
    local existing_room_id = self.prefs.recalls[position]
    local existing_room_name = getRoomName(existing_room_id)
    cecho(f "<orange>Replacing room {existing_room_id} ({existing_room_name}) in recall position {position} with room {room_id} ({getRoomName(room_id)}).\n")
    self.prefs.recalls[position] = room_id
  else
    table.insert(self.prefs.recalls, position, room_id)
    cecho(f "<chartreuse>Room {room_id} ({getRoomName(room_id)}) has been saved to recall position {position}.\n")
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
    local room_id = self:CurrentRoomId()
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

  cecho(f "<chartreuse>Forgetting room {self.prefs.recalls[position]} ({getRoomName(self.prefs.recalls[position])}) at position {position}.\n")
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

  if not position or not self.prefs.recalls[position] then
    cecho("<orange>No recall point at position " .. tostring(position) .. ".\n")
    return
  end

  local room_id = self.prefs.recalls[position]
  local room_name = getRoomName(room_id) or "unknown room"
  cecho(f "<chartreuse>Recalling to room {room_id} ({room_name}).\n")

  local result, message = gotoRoom(room_id)
  if not result then
    cecho("<orange>Could not recall: " .. tostring(message) .. ".\n")
  end
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
  for position, room_id in ipairs(self.prefs.recalls) do
    -- The room may be gone, if the map has been reset since it was remembered.
    local room_name = getRoomName(room_id) or "unknown room"
    cecho("<chartreuse>" .. string.format("  %2d: %s\n", position, room_name))
  end
end

-- ----------------------------------------------------------------------------
-- DisplayRoom
--
-- This function shows what the map knows about a room.
-- ----------------------------------------------------------------------------

---@param room_id number|nil Defaults to the current room
function Carto:DisplayRoom(room_id)
  room_id = room_id or self:CurrentRoomId()

  if not room_id then
    cecho("<orange>Unable to determine your current location.\n")
    return
  end

  local name = getRoomName(room_id)
  if not name then
    cecho(f "<orange>Room {room_id} is not on the map.\n")
    return
  end

  local function show(label, value)
    cecho(f "<hot_pink>{label}<reset>: ")
    echo(tostring(value) .. "\n")
  end

  local function destination(to_id)
    return to_id .. " (" .. (getRoomName(to_id) or "unknown room") .. ")"
  end

  local door_names = { "open", "closed", "locked" }
  local doors = getDoors(room_id) or {}
  local function door(command)
    local status = door_names[doors[command]]
    return status and f " [{status} door]" or ""
  end

  local x, y, z = getRoomCoordinates(room_id)

  show("Room", destination(room_id))
  show("Area", getRoomAreaName(getRoomArea(room_id)))
  show("Coordinates", f "{x}, {y}, {z}")
  show("Environment", getRoomEnv(room_id))
  show("Weight", getRoomWeight(room_id))
  show("Locked", roomLocked(room_id))
  show("Hash", getRoomHashByID(room_id) or "none")

  local exits = getRoomExits(room_id) or {}
  local stubs = {}

  for _, stub_dir in ipairs(getExitStubs1(room_id) or {}) do
    stubs[self.exits.stubs[stub_dir]] = true
  end

  -- In the order of their numbers, so that they don't move around between looks.
  for n = 1, 12 do
    local dir = self.exits.stubs[n]
    local command = self:DoorCommand(dir)
    if exits[dir] then
      show(f "Exit {dir}", destination(exits[dir]) .. door(command))
    elseif stubs[dir] then
      show(f "Exit {dir}", "unexplored" .. door(command))
    end
  end

  local special_exits = getSpecialExitsSwap(room_id) or {}
  local commands = table.keys(special_exits)
  table.sort(commands)

  for _, command in ipairs(commands) do
    show(f "Special exit {command}", destination(special_exits[command]) .. door(command))
  end
end

-- ----------------------------------------------------------------------------
-- DisplayPath
--
-- This function shows the way from one room to another, without walking it.
-- ----------------------------------------------------------------------------

---@param from_id number|nil Defaults to the current room
---@param to_id number
function Carto:DisplayPath(from_id, to_id)
  from_id = from_id or self:CurrentRoomId()

  if not from_id then
    cecho("<orange>Unable to determine your current location.\n")
    return
  end

  for _, room_id in ipairs({ from_id, to_id }) do
    if not getRoomName(room_id) then
      cecho(f "<orange>Room {room_id} is not on the map.\n")
      return
    end
  end

  if from_id == to_id then
    cecho("<orange>Those are the same room.\n")
    return
  end

  if not getPath(from_id, to_id) then
    cecho(f "<orange>There is no path from {from_id} to {to_id}.\n")
    return
  end

  local steps = #speedWalkDir
  local unit = steps == 1 and "step" or "steps"

  cecho(f "<chartreuse>From {getRoomName(from_id)} to {getRoomName(to_id)}, {steps} {unit}:\n")
  echo(table.concat(speedWalkDir, ", ") .. "\n")
end

-- ----------------------------------------------------------------------------
-- GetSpeedwalkDelay / GetSpeedwalkTimeout
--
-- These functions return the values that SetSpeedwalkDelay and
-- SetSpeedwalkTimeout set.
-- ----------------------------------------------------------------------------

function Carto:GetSpeedwalkDelay()
  return self.prefs.speedwalk_delay
end

function Carto:GetSpeedwalkTimeout()
  return self.prefs.speedwalk_timeout
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
    current_table = current_table[keys[i]]

    if type(current_table) ~= "table" then
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
  <b>walk pause</b> - Pause walking.
  <b>walk resume</b> - Resume walking, from wherever you are now.
  <b>walk path</b> [<<b>from_id</b>>] <<b>to_id</b>> - See the way to a room, without walking it.
  <b>walk slow</b> - Set walk speed to {Carto.config.speed_walk_slow} seconds per step.
  <b>walk fast</b> - Set walk speed to {Carto.config.speed_walk_fast} seconds per step.
  <b>walk speed</b> - See your current walk speed.
  <b>walk speed</b> <<b>n</b>> - Set walk speed to <i>n</i> seconds per step.
  <b>walk timeout</b> - See how long to wait for a step before giving up.
  <b>walk timeout</b> <<b>n</b>> - Wait <i>n</i> seconds for a step, or 0 for as long as it takes.
  <b>walk to</b> <<b>room_id</b>> - Walk to room <i>room_id</i>.
  <b>walk remember</b> - Remember the current room.
  <b>walk remember</b> <<b>position</b>> - Remember the current room at <i>position</i>.
  <b>walk forget</b> - Forget the current room.
  <b>walk forget</b> <<b>position</b>> - Forget the room at <i>position</i>.
  <b>walk recall</b> - List all recall positions.
  <b>walk recall</b> <<b>position</b>> - Recall to the room at <i>position</i>.

Type <h1>carto config</h1> to see your current GMCP settings.
]],
    carto_config = f [[
<h1><u>{Carto.config.name}</u></h1>

Syntax: <b>carto</b> [<b>setting</b>] [<b>value</b>]

  <b>carto</b> - See this help text.
  <b>carto config</b> - See the current GMCP config settings for {Carto.config.name}.
  <b>carto room</b> [<<b>room_id</b>>] - See what the map knows about a room, or the current one.
  <b>carto doors</b> - See the commands used to get through doors while walking.
  <b>carto doors</b> <<b>open</b>|<b>unlock</b>> <<b>command</b>> - Set one, where <i>{"{dir}"}</i> is the direction.
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
