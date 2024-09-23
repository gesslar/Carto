-- Letting Mudlet know that this is a mapper script
mudlet = mudlet or {};
mudlet.mapper_script = true

---@diagnostic disable-next-line: deprecated
table.unpack = unpack

---@class Mapper
-- Mapper setup
Mapper = {
  config = {
    speedwalk_path = {},          -- Speedwalk path
    speedwalk_delay = 0.0,        -- Speedwalk delay
    speedwalk_delay_min = 0.0,    -- Minimum speedwalk delay
    walk_timer = nil,             -- Walk timer
    walk_timer_name = nil,        -- Walk timer name
    walk_step = nil,              -- The next room id for the speedwalk
    package_name = "__PKGNAME__", -- Name of the package
    name = "gMap",              -- Name of the script
    prefix = "gMap.",           -- Prefix for handlers
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
      ["default"]       = { id = 500, color = { 220, 220, 220, 255 } }, -- Light Gray
      ["beach"]         = { id = 501, color = { 255, 223, 186, 255 } }, -- Light Sand
      ["desert"]        = { id = 502, color = { 244, 164, 96, 255 } }, -- Sandy Brown
      ["dirt road"]     = { id = 503, color = { 139, 69, 19, 255 } },  -- Saddle Brown
      ["forest"]        = { id = 504, color = { 34, 139, 34, 255 } },  -- Forest Green
      ["grass"]         = { id = 505, color = { 144, 238, 144, 255 } }, -- Light Green
      ["grassy"]        = { id = 505, color = { 144, 238, 144, 255 } }, -- Light Green
      ["indoor"]        = { id = 506, color = { 60, 42, 33, 255 } },   -- Rich Mocha
      ["mountain"]      = { id = 507, color = { 169, 169, 169, 255 } }, -- Dark Gray
      ["mud"]           = { id = 508, color = { 101, 67, 33, 255 } },  -- Dark Brown
      ["path"]          = { id = 509, color = { 210, 180, 140, 255 } }, -- Light Brown
      ["road"]          = { id = 510, color = { 160, 120, 90, 255 } }, -- Soft Brown
      ["sand"]          = { id = 511, color = { 238, 214, 175, 255 } }, -- Soft Sand
      ["snow"]          = { id = 512, color = { 255, 250, 250, 255 } }, -- Snow White
      ["swamp"]         = { id = 513, color = { 86, 125, 70, 255 } },  -- Dark Olive Green
      ["water"]         = { id = 514, color = { 35, 90, 186, 255 } },  -- Light Blue
      ["tunnels"]       = { id = 515, color = { 102, 85, 68, 255 } },  -- Greyish Brown
      ["sandy"]         = { id = 516, color = { 255, 223, 186, 255 } }, -- Light Sand
      ["rocky"]         = { id = 518, color = { 139, 137, 137, 255 } }, -- Dark Gray
      ["impassable"]    = { id = 519, color = { 0, 50, 0, 255 } },     -- Very dark green
      ["dusty"]         = { id = 520, color = { 102, 85, 68, 255 } },  -- Greyish Brown
      ["shallow water"] = { id = 521, color = { 40, 139, 184, 255 } }, -- Light Blue
      ["deep water"]    = { id = 522, color = { 24, 63, 130, 255 } },  -- Light Blue
    },
    -- Terrain types we will never path through. Using lockRoom() to prevent
    -- pathing through these terrain types.
    prevent_terrain_types = {
      522, -- Deep Water
    },
    -- Terrain types we will avoid when pathing. Using setRoomWeight() to avoid
    -- these terrain types, unless we have no other choice.
    avoid_terrain_types = {
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
  move_tracking = {}, -- Move tracking for room movements
}

Mapper.default_event_handlers = {
  -- System events that we want to handle
  "sysUninstall",
  "sysConnectionEvent",
  "sysExitEvent",
  -- GMCP events that we want to handle
  Mapper.config.gmcp.event
}

function Mapper:EventHandler(event, arg1, arg2)
  if event == "sysConnectionEvent" then
    self:Setup()               -- no args
  elseif event == "sysExitEvent" then
    self:Teardown()            -- no args
  elseif event == self.config.gmcp.event then
    self:Move(arg1)            -- arg1 is the GMCP package name
  end
end

function Mapper:Install(event, package)
  if package ~= self.config.package_name then
    return
  end

  if table.contains(getPackages(), "generic_mapper") then
    uninstallPackage("generic_mapper")
  end
end

function Mapper:Uninstall(event, package)
  if package ~= self.config.package_name then
    return
  end

  if self.walking then
    cecho("<orange_red>Resetting walking.\n")
  end
  self:ResetWalking(true, "Script has been uninstalled.")
  self:Teardown()
  Mapper = nil
end

function Mapper:Setup()
  -- Set custom environment colors for terrain types
  for _, data in pairs(self.terrain.types) do
    local r, g, b, a = table.unpack(data.color)
    setCustomEnvColor(data.id, r, g, b, a)
  end

  -- Register event handlers
  local handler

  -- Register persistent event handlers
  for _, event in ipairs(self.default_event_handlers) do
    handler = self.config.prefix .. event
    if registerNamedEventHandler(self.config.name, handler, event, function(...) self:EventHandler(...) end) then
      table.insert(self.event_handlers, handler)
    else
      cecho("<orange_red>Failed to register event handler for " .. event .. "\n")
    end
  end

  self.walk_timer_name = self.config.prefix .. "walk_timer"
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
    cecho("<orange_red>Failed to add room.\n")
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

  resumeNamedTimer(self.config.name, self.walk_timer_name)
end

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
      shift = self.vectors.name[k]
      break
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

-- doSpeedWalk remains a local function
function doSpeedWalk()
  Mapper:Speedwalk()
end

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

function Mapper:Speedwalk()
  if not next(self.info.current) then return end

  if self.walking then
    cecho("<orange_red>You are already walking!\n")
    return
  end

  self.speedwalk_path = {}
  if not next(self.info.current.exits) then
    cecho("<orange_red>No speedwalk direction found.\n")
    self:ResetWalking(true, "No speedwalk direction found.")
    return
  end

  if not next(speedWalkPath) then
    cecho("<orange_red>No speedwalk path found.\n")
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
    cecho("<orange_red>No exits found.\n")
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

  self.walk_timer = registerNamedTimer(
    self.config.name,
    self.walk_timer_name,
    self.config.speedwalk_delay + 0.01,
    function() self:Step() end,
    false
  )

  if not self.walk_timer then
    cecho("<orange_red>Failed to start walking.\n")
    self:ResetWalking(true, "Failed to start walking.")
    return
  end

  self.walking = true
  local destination_id = self.speedwalk_path[#self.speedwalk_path][2]
  local destination_name = getRoomName(destination_id)
  cecho("<aquamarine>Walking to " .. destination_name .. ".\n")

  raiseEvent("sysSpeedwalkStarted")
end

function Mapper:Step()
  if not next(self.speedwalk_path) then
    cecho("<aquamarine>You have arrived at " .. self.info.current.name .. ".\n")
    self:ResetWalking(false, "Arrived at destination.")
    return
  end

  local current_room_id = self.info.current.room_id
  if not current_room_id then
    cecho("<orange_red>Unable to determine your current location.\n")
    self:ResetWalking(true, "Unable to determine your current location.")
    return
  end

  local current_step = self.speedwalk_path[1]

  -- Check if this is the starting room (which doesn't have a direction)
  if current_step[1] == "" then
    if current_room_id ~= current_step[2] then
      cecho("<orange_red>You are not in the expected starting room.\n")
      cecho("<orange_red>Expected you to be in room " .. current_step[2] .. " (" .. getRoomName(current_step[2]) .. ").\n")
      cecho("<orange_red>Current room: " .. current_room_id .. " (" .. getRoomName(current_room_id) .. ").\n")
      self:ResetWalking(true, "You are not in the expected starting room.")
      return
    end

    table.remove(self.speedwalk_path, 1)
    if not next(self.speedwalk_path) then
      cecho("<aquamarine>You have arrived at " .. self.info.current.name .. ".\n")
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
          cecho("<orange_red>Something prevents you from continuing.\n")
        else
          cecho("<orange_red>You have veered off the expected path.\n")
        end
      else
        cecho("<orange_red>You have veered off the expected path.\n")
      end
    else
      cecho("<orange_red>You have veered off the expected path.\n")
    end
    self:ResetWalking(true, "You have veered off the expected path.")
    return
  end

  -- Now we're dealing with a regular step
  local dir, next_room_id = table.unpack(current_step)

  self.walk_step = next_room_id

  local full_dir = self.exits.map[dir] or self.exits.reverse[dir]
  if not full_dir then
    cecho("<orange_red>Invalid direction.\n")
    self:ResetWalking(true, "Invalid direction.")
    return
  end

  send(full_dir, true)

  -- Remove the current step as we've just executed it
  table.remove(self.speedwalk_path, 1)
end

function Mapper:SetSpeedwalkDelay(delay, override)
  delay = tonumber(delay) or 0
  if delay < self.config.speedwalk_delay_min and not override then
    delay = self.config.speedwalk_delay_min
  end

  self.config.speedwalk_delay = delay

  if self.config.speedwalk_delay == 0.075 then
    cecho("<aquamarine>Walk speed set to " .. self.config.speedwalk_delay .. " second per step.\n")
  else
    cecho("<aquamarine>Walk speed set to " .. self.config.speedwalk_delay .. " seconds per step.\n")
  end
end

function Mapper:GetSpeedwalkDelay()
  return self.config.speedwalk_delay
end

-- Basic event handlers
registerNamedEventHandler(Mapper.config.name, "Mapper:Install", "sysInstall", "Mapper:Install", true)
registerNamedEventHandler(Mapper.config.name, "Mapper:Uninstall", "sysUninstall", "Mapper:Uninstall", true)

-- Finally, let's just do the setup script
Mapper:Setup()
