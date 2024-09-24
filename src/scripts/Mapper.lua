-- Letting Mudlet know that this is a mapper script
mudlet = mudlet or {};
mudlet.mapper_script = true

---@diagnostic disable-next-line: deprecated
table.unpack = unpack

---@class Mapper
-- Mapper setup
Mapper = Mapper or {
  config = {
    speedwalk_path = {},          -- Speedwalk path
    speedwalk_delay = 0.0,        -- Speedwalk delay
    speedwalk_delay_min = 0.0,    -- Minimum speedwalk delay
    walk_timer = nil,             -- Walk timer
    walk_timer_name = nil,        -- Walk timer name
    walk_step = nil,              -- The next room id for the speedwalk
    package_name = "__PKGNAME__", -- Name of the package
    name = "Mapper",              -- Name of the script
    prefix = "Mapper.",           -- Prefix for handlers
    gmcp = {
      event = "gmcp.Room.Info",
      expect_coordinates = true,
      expect_hash = true,
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
    },
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
  },
  tags = {
    mapper = { "%s", table.deepcopy(color_table["orange_red"]), table.deepcopy(color_table["orange"]  ) },
    warning = { "%s", table.deepcopy(color_table["orange"]), table.deepcopy(color_table["orange_red"]) },
    error = { "%s", table.deepcopy(color_table["red"]), table.deepcopy(color_table["orange_red"]) },
    info = { "%s", table.deepcopy(color_table["chartreuse"]), table.deepcopy(color_table["olive_drab"]) },
  },
  move_tracking = {}, -- Move tracking for room movements
  recalls = {}, -- Recall points for rooms
}

-- ----------------------------------------------------------------------------
-- Event Handlers
-- ----------------------------------------------------------------------------

Mapper.default_event_handlers = Mapper.default_event_handlers or {
  -- System events that we want to handle
  "sysConnectionEvent",
  "sysExitEvent",
  "sysLoadEvent",
  -- GMCP events that we want to handle
  Mapper.config.gmcp.event
}

function Mapper:EventHandler(event, ...)
  if event == "sysLoadEvent" then
    self:Setup()               -- no args
  elseif event == "sysConnectionEvent" then
    self:Setup()               -- no args
  elseif event == "sysExitEvent" then
    self:Teardown()            -- no args
  elseif event == self.config.gmcp.event then
    self:Move(...)            -- arg1 is the GMCP package name
  end
end

-- Basic event handlers
registerNamedEventHandler(Mapper.config.name, "Mapper:Install", "sysInstall", "Mapper:Install", true)
registerNamedEventHandler(Mapper.config.name, "Mapper:Uninstall", "sysUninstall", "Mapper:Uninstall", true)

-- ----------------------------------------------------------------------------
-- Setup and Teardown
-- ----------------------------------------------------------------------------

function Mapper:Setup()
  -- Set custom environment colors for terrain types
  for _, data in pairs(self.terrain.types) do
    local r, g, b = table.unpack(data.color)
    setCustomEnvColor(data.id, r, g, b, 255)
  end

  -- Register event handlers
  local handler

  -- Register persistent event handlers
  for _, event in ipairs(self.default_event_handlers) do
    handler = self.config.prefix .. event
    if registerNamedEventHandler(self.config.name, handler, event, function(...) self:EventHandler(...) end) then
      table.insert(self.event_handlers, handler)
    else
      self:Echo("Failed to register event handler for " .. event, "error")
    end
  end

  self.walk_timer_name = self.config.prefix .. "walk_timer"

  for tag_name, tag_info in pairs(self.tags) do
    if tag_name == string.lower(self.config.name) then
      tag_info[1] = string.format(tag_info[1], string.lower(self.config.name))
    else
      tag_info[1] = string.lower(tag_name)
    end
  end

  gmod.enableModule(self.config.name, "Room")
end

function Mapper:Teardown()
  -- Kill event handlers
  deleteAllNamedEventHandlers(self.config.name)
  self.event_handlers = {}
  self:ResetWalking(false, "Script has been disabled.")
end

function Mapper:Explode(str, delimiter)
  local result = {}
  local pattern = "([^" .. delimiter .. "]+)" -- This pattern correctly matches non-delimiter characters

  for match in str:gmatch(pattern) do
    table.insert(result, match)
  end

  return result
end

-- ----------------------------------------------------------------------------
-- Install/Uninstall
-- ----------------------------------------------------------------------------

function Mapper:Install(event, package)
  if package ~= self.config.package_name then
    return
  end

  self:Setup()

  if table.contains(getPackages(), "generic_mapper") then
    self:Echo("Uninstalling package: generic_mapper")
    uninstallPackage("generic_mapper")
    if(table.contains(getPackages(), "generic_mapper")) then
      self:Echo("Could not uninstall generic_mapper.", "warning")
      self:Echo("Please uninstall it manually and restart Mudlet.", "warning")
      return
    end
  end

  deleteNamedEventHandler(self.config.name, "Mapper:Install")

  self:Echo(self.config.name .. " installed.")
  self:Setup()
end

function Mapper:Uninstall(event, package)
  if package ~= self.config.package_name then
    return
  end

  if self.walking then
    self:Echo("Resetting walking.")
  end
  self:ResetWalking(true, "Script has been uninstalled.")
  self:Teardown()

  self:Echo(self.config.name .. " uninstalled.")
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

function Mapper:Move(gmcp_package)
  local gmcp_table = self:TableFromPackage(gmcp_package) or {}

  self.info.previous = self.info.current

  if self.config.gmcp.expect_hash then
    if not gmcp_table[self.config.gmcp.properties.hash] then return end
  else
    if not gmcp_table[self.config.gmcp.properties.vnum] then return end
  end

  self.info.current = {
    hash = gmcp_table[self.config.gmcp.properties.hash],
    area = gmcp_table[self.config.gmcp.properties.area],
    name = gmcp_table[self.config.gmcp.properties.name],
    environment = gmcp_table[self.config.gmcp.properties.environment],
    symbol = gmcp_table[self.config.gmcp.properties.symbol],
    exits = table.deepcopy(gmcp_table[self.config.gmcp.properties.exits]),
    doors = table.deepcopy(gmcp_table[self.config.gmcp.properties.doors]),
    type = gmcp_table[self.config.gmcp.properties.type],
    subtype = gmcp_table[self.config.gmcp.properties.subtype],
    icon = gmcp_table[self.config.gmcp.properties.icon],
  }

  self.info.current.custom = gmcp_table[self.config.gmcp.properties.custom] or {}

  if self.config.gmcp.expect_coordinates then
    if gmcp_table[self.config.gmcp.properties.coords] then
      self.info.current.coords = gmcp_table[self.config.gmcp.properties.coords]
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
    self:Echo("Failed to add room.", "error")
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

function Mapper:AddOrUpdateRoom(info)
  local room_id

  if self.config.gmcp.expect_hash then
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
  if self.config.gmcp.expect_coordinates then
    if info.coords then
      coords = info.coords
    end
  else
    -- Calculate coordinates based on previous room
    coords = self:CalculateCoordinates(room_id)
  end

  if #coords == 3 then
    local x, y, z = table.unpack(coords)
    setRoomCoordinates(room_id, x, y, z)
  end

  local env_id
  if info[self.config.gmcp.properties.environment] then
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

function Mapper:CalculateCoordinates(roomID)
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
  if self.config.gmcp.expect_hash then
    compare_field = self.config.gmcp.properties.hash
  else
    compare_field = self.config.gmcp.properties.vnum
  end

  for k, v in pairs(self.info.current[self.config.gmcp.properties.exits]) do
    if v == self.info.previous[compare_field] and self.vectors.name[k] then
      if self.vectors.name[k] then
        shift = self.vectors.name[k]
        break
      else
        self:Echo("No shift vector found for " .. k .. ".", "warning")
      end
    end
  end

  for n = 1, 3 do
    coords[n] = coords[n] - shift[n]
  end

  return coords
end

function Mapper:UpdateExits(room_id)
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

    if self.config.gmcp.expect_hash then
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
      local stub_num = self.stubs[dir]
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
      if not table.contains(current_stubs, self.stubs[dir]) then
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
  Mapper:Speedwalk()
end

-- ----------------------------------------------------------------------------
-- ResetWalking
--
-- This function resets the walking state and raises events when the walking
-- process is interrupted or completed.
-- ----------------------------------------------------------------------------

function Mapper:ResetWalking(exception, reason)
  if table.contains(getNamedTimers(self.config.name), self.walk_timer_name) then
    deleteNamedTimer(self.config.name, self.walk_timer_name)
  end

  self.walking = false
  self.speedwalk_path = {}
  self.walk_timer = nil
  self.walk_step = nil
  self.move_tracking = {}

  if exception then
    raiseEvent("onSpeedwalkReset", exception, reason)
  else
    raiseEvent("sysSpeedwalkFinished")
  end
end

-- ----------------------------------------------------------------------------
-- Speedwalk
--
-- This function is called from doSpeedWalk. It checks for necessary
-- conditions and initiates the walking process if all checks pass.
-- ----------------------------------------------------------------------------

function Mapper:Speedwalk()
  if not self.info then
    self:Echo("You are not in a room.", "error")
    return
  end

  if not self.info.current then
    self:Echo("You are not in a room.", "error")
    return
  end

  if self.walking then
    self:Echo("You are already walking!", "error")
    return
  end

  self.speedwalk_path = {}
  if not next(self.info.current.exits) then
    self:Echo("No speedwalk direction found.", "error")
    self:ResetWalking(true, "No speedwalk direction found.")
    return
  end

  if not next(speedWalkPath) then
    self:Echo("No speedwalk path found.", "error")
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
    self:Echo("No exits found.", "error")
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
    self.config.speedwalk_delay + 0.01,
    function() self:Step() end,
    false
  )

  if not self.walk_timer then
    self:Echo("Failed to start walking.", "error")
    self:ResetWalking(true, "Failed to start walking.")
    return
  end

  self.walking = true
  local destination_id = self.speedwalk_path[#self.speedwalk_path][2]
  local destination_name = getRoomName(destination_id)
  self:Echo("Walking to " .. destination_name .. ".", "info")

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

function Mapper:Step()
  if not next(self.speedwalk_path) then
    self:Echo("You have arrived at " .. self.info.current.name .. ".", "info")
    self:ResetWalking(false, "Arrived at destination.")
    return
  end

  local current_room_id = self.info.current.room_id
  if not current_room_id then
    self:Echo("Unable to determine your current location.", "error")
    self:ResetWalking(true, "Unable to determine your current location.")
    return
  end

  local current_step = self.speedwalk_path[1]

  -- Check if this is the starting room (which doesn't have a direction)
  if current_step[1] == "" then
    if current_room_id ~= current_step[2] then
      self:Echo("You are not in the expected starting room.", "error")
      self:Echo("Expected you to be in room " .. current_step[2] .. " (" .. getRoomName(current_step[2]) .. ").\n", "error")
      self:Echo("Current room: " .. current_room_id .. " (" .. getRoomName(current_room_id) .. ").\n", "error")
      self:ResetWalking(true, "You are not in the expected starting room.")
      return
    end

    table.remove(self.speedwalk_path, 1)
    if not next(self.speedwalk_path) then
      self:Echo("You have arrived at " .. self.info.current.name .. ".", "info")
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
          self:Echo("Something prevents you from continuing.", "error")
        else
          self:Echo("You have veered off the expected path.", "error")
        end
      else
        self:Echo("You have veered off the expected path.", "error")
      end
    else
      self:Echo("You have veered off the expected path.", "error")
    end
    self:ResetWalking(true, "You have veered off the expected path.")
    return
  end

  -- Now we're dealing with a regular step
  local dir, next_room_id = table.unpack(current_step)

  self.walk_step = next_room_id

  local full_dir = self.exits.map[dir] or self.exits.reverse[dir]
  if not full_dir then
    self:Echo("Invalid direction: " .. dir, "error")
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

function Mapper:SetSpeedwalkDelay(delay, override)
  delay = tonumber(delay) or 0
  if delay < self.config.speedwalk_delay_min and not override then
    delay = self.config.speedwalk_delay_min
  end

  self.config.speedwalk_delay = delay

  local unit = self.config.speedwalk_delay == 1 and "second" or "seconds"
  self:Echo("Walk speed set to " .. self.config.speedwalk_delay .. " " .. unit .. " per step.", "info")
end

-- ----------------------------------------------------------------------------
-- RememberRoom
--
-- This function saves the current room as a recall point for the current
-- profile.
-- ----------------------------------------------------------------------------

function Mapper:RememberRoom(position)
  local room_id = getPlayerRoom()

  if position == nil then
    position = #self.recalls + 1
  else
    if position > #self.recalls then
      position = #self.recalls + 1
    end
  end

  local index = table.index_of(self.recalls, room_id)
  if index then
    self:Echo("Room " .. room_id .. " (" .. getRoomName(room_id) .. ") is already in recall position " .. index .. ".", "info")
    return
  end

  if self.recalls[position] then
    local existing_room_id = self.recalls[position]
    local existing_room_name = getRoomName(existing_room_id)
    self:Echo("Replacing room " .. existing_room_id .. " (" .. existing_room_name .. ") in recall position " .. position .. " with room " .. room_id .. " (" .. getRoomName(room_id) .. ").", "warning")
    self.recalls[position] = room_id
  else
    table.insert(self.recalls, position, room_id)
    self:Echo(
    "Room " .. room_id .. " (" .. getRoomName(room_id) .. ") has been saved to recall position " .. position .. ".",
      "info")
  end
end

-- ----------------------------------------------------------------------------
-- RecallRoom
--
-- This function recalls the character to a previously saved room based on the
-- provided position.
-- ----------------------------------------------------------------------------

function Mapper:RecallRoom(position)
  if not self.recalls then
    self:Echo("No recall points have been set.", "error")
    return
  end

  if not self.recalls[position] then
    self:Echo("No recall point at position " .. position .. ".", "error")
    return
  end

  local room_id = self.recalls[position]
  local room_name = getRoomName(room_id)
  self:Echo("Recalling to room " .. room_id .. " (" .. room_name .. ").", "info")
  gotoRoom(room_id)
end

-- ----------------------------------------------------------------------------
-- DisplayRecalls
--
-- This function displays all the recall points for the current profile.
-- ----------------------------------------------------------------------------

function Mapper:DisplayRecalls()
  if not self.recalls then
    self:Echo("No recall points have been set.", "error")
    return
  end

  self:Echo("Recall points:", "info")
  for position, room_id in pairs(self.recalls) do
    local room_name = getRoomName(room_id)
    self:Echo(string.format("  %2d: %s", position, room_name), "info")
  end
end

-- ----------------------------------------------------------------------------
-- GetSpeedwalkDelay
--
-- This function returns the current speedwalk delay value.
-- ----------------------------------------------------------------------------

function Mapper:GetSpeedwalkDelay()
  return self.config.speedwalk_delay
end

-- ----------------------------------------------------------------------------
-- Helper functions
-- ----------------------------------------------------------------------------

function Mapper:FormatMessage(tag)
  return string.format("<%s>(<%s>%s<%s>)<255,255,255> ",
    table.concat(self.tags[tag][2], ","),
    table.concat(self.tags[tag][3], ","),
    tag,
    table.concat(self.tags[tag][2], ",")
  )
end

function Mapper:Echo(message, tag)
  if tag then
    tag = string.lower(tag)
  end

  if message[#message] ~= "\n" then
    message = message .. "\n"
  end
  decho(self:FormatMessage(string.lower(self.config.name)))
  if tag then
    decho(self:FormatMessage(tag))
  end

  cecho(message)
end

function Mapper:TableFromPackage(gmcp_package)
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
