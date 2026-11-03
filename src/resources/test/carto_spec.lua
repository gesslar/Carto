-- Runs inside real Mudlet with the built package installed, so the mapper API,
-- aliases, events and named timers are all the real ones. Only what would leave
-- the profile (send) is replaced, and the console functions are wrapped so that specs
-- can check what the user was told.
--
-- Busted runs specs in a sandboxed environment, so a global that Carto has to see
-- must be assigned through _G.
describe("Carto", function()
  local real = {}
  local watchers = {}
  local out, sent, events

  local WATCHED = {
    "sysSpeedwalkStarted", "sysSpeedwalkFinished", "sysSpeedwalkStopped",
    "sysSpeedwalkPaused", "sysSpeedwalkResumed",
    "onSpeedwalkReset", "onSpeedwalkFailed", "onDoorChange", "mapperScriptLoaded",
  }

  local function printed(text)
    for _, line in ipairs(out) do
      if line:find(text, 1, true) then
        return true
      end
    end
    return false
  end

  local function saw(event)
    for _, seen in ipairs(events) do
      if seen.name == event then
        return seen
      end
    end
    return nil
  end

  -- Let timers fire, which is how a walk gets from one step to the next.
  local function pump()
    pumpEvents(25)
  end

  local function room(info)
    _G.gmcp.Room = { Info = info }
    raiseEvent("gmcp.Room.Info", "gmcp.Room.Info")
    pump()
    return getRoomIDbyHash(info.hash)
  end

  local function has_stub(room_id, dir)
    return table.index_of(getExitStubs1(room_id) or {}, Carto.exits.stubs[dir]) ~= nil
  end

  local function walk(dirs, path)
    _G.speedWalkDir, _G.speedWalkPath = dirs, {}
    for i, room_id in ipairs(path) do
      _G.speedWalkPath[i] = tostring(room_id)
    end
    doSpeedWalk()
    pump()
  end

  local function alias(text)
    expandAlias(text, false)
  end

  setup(function()
    real.send, real.cecho, real.echo = _G.send, _G.cecho, _G.echo

    -- Mudlet only knows where the player is, and so can only find paths, with a map open.
    openMapWidget()

    for _, event in ipairs(WATCHED) do
      watchers[#watchers + 1] = registerAnonymousEventHandler(event, function(name, ...)
        events[#events + 1] = { name = name, args = { ... }, sent = #sent }
      end)
    end
  end)

  teardown(function()
    for _, id in ipairs(watchers) do
      killAnonymousEventHandler(id)
    end
    _G.send, _G.cecho, _G.echo = real.send, real.cecho, real.echo
  end)

  before_each(function()
    out, sent, events = {}, {}, {}

    _G.send = function(text) sent[#sent + 1] = text end
    -- These pass through because the test runner reports with them too.
    _G.cecho = function(text)
      out[#out + 1] = text
      return real.cecho(text)
    end
    _G.echo = function(text)
      out[#out + 1] = text
      return real.echo(text)
    end

    deleteMap()
    os.remove(getMudletHomeDir() .. "/" .. Carto.config.preferences_file)

    Carto.debug = false
    Carto:ResetWalking(true, "A new spec is starting.")
    Carto.info = {}
    Carto:LoadPreferences()
    Carto:Setup("sysLoadEvent")
    Carto.prefs.mode = "quick"

    _G.gmcp = _G.gmcp or {}
  end)

  describe("coordinates", function()
    it("should not move a known room when logging back in", function()
      Carto.prefs.gmcp.expect_coordinates = false
      local a = room({ hash = "a", name = "A", exits = {} })
      setRoomCoordinates(a, 10, 20, 0)
      Carto.info = {}
      room({ hash = "a", name = "A", exits = {} })
      assert.are.equal(10, (getRoomCoordinates(a)))
    end)

    it("should not stack a known room on the one you teleported from", function()
      Carto.prefs.gmcp.expect_coordinates = false
      local a = room({ hash = "a", name = "A", exits = {} })
      local b = room({ hash = "b", name = "B", exits = {} })
      setRoomCoordinates(a, 5, 5, 0)
      setRoomCoordinates(b, 50, 50, 0)
      room({ hash = "a", name = "A", exits = {} })
      assert.are.equal(5, (getRoomCoordinates(a)))
      room({ hash = "b", name = "B", exits = {} })
      assert.are.equal(50, (getRoomCoordinates(b)))
    end)

    it("should still place a brand new room from the one you left", function()
      Carto.prefs.gmcp.expect_coordinates = false
      room({ hash = "a", name = "A", exits = { north = "b" } })
      local b = room({ hash = "b", name = "B", exits = { south = "a" } })
      local _, y = getRoomCoordinates(b)
      assert.are.equal(1, y)
    end)
  end)

  describe("exits", function()
    it("should link short exit keys both ways", function()
      local a = room({ hash = "a", name = "A", exits = { n = "b" } })
      local b = room({ hash = "b", name = "B", exits = { s = "a" } })
      assert.are.equal(b, getRoomExits(a).north)
      assert.are.equal(a, getRoomExits(b).south)
    end)

    it("should keep short-key exits on a revisit", function()
      Carto.prefs.mode = "normal"
      local a = room({ hash = "a", name = "A", exits = { n = "b" } })
      local b = room({ hash = "b", name = "B", exits = { s = "a" } })
      room({ hash = "a", name = "A", exits = { n = "b" } })
      assert.are.equal(b, getRoomExits(a).north)
    end)

    it("should stub a short e exit", function()
      local a = room({ hash = "a", name = "A", exits = { e = "b" } })
      assert.is_true(has_stub(a, "east"))
    end)

    it("should cope with a non-standard exit on the room you left", function()
      room({ hash = "a", name = "A", exits = { portal = "b", north = "c" } })
      local b = room({ hash = "b", name = "B", exits = { south = "a" } })
      assert.are.equal(getRoomIDbyHash("a"), getRoomExits(b).south)
    end)

    it("should keep mapped exits when the GMCP has none", function()
      local a = room({ hash = "a", name = "A", exits = { north = "b" } })
      local b = room({ hash = "b", name = "B", exits = { south = "a" } })
      room({ hash = "a", name = "A" })
      assert.are.equal(b, getRoomExits(a).north)
    end)

    it("should cope with leaving a room whose GMCP had no exits", function()
      Carto.prefs.gmcp.expect_coordinates = false
      room({ hash = "a", name = "A" })
      assert.is_truthy(room({ hash = "b", name = "B", exits = {} }))
    end)

    it("should map a one-way exit by walking it", function()
      local a = room({ hash = "a", name = "A", exits = { north = "b" } })
      local b = room({ hash = "b", name = "B", exits = { east = "c" } })
      assert.are.equal(b, getRoomExits(a).north)
    end)

    it("should build forward and stub back in normal mode", function()
      Carto.prefs.mode = "normal"
      local a = room({ hash = "a", name = "A", exits = { north = "b" } })
      local b = room({ hash = "b", name = "B", exits = { south = "a" } })
      assert.are.equal(b, getRoomExits(a).north)
      assert.is_nil(getRoomExits(b).south)
      assert.is_true(has_stub(b, "south"))
      room({ hash = "a", name = "A", exits = { north = "b" } })
      assert.are.equal(a, getRoomExits(b).south)
    end)

    it("should build the reciprocal from the real exit in quick mode", function()
      local a = room({ hash = "a", name = "A", exits = { north = "b" } })
      local b = room({ hash = "b", name = "B", exits = { west = "a" } })
      assert.are.equal(a, getRoomExits(b).west)
      assert.is_nil(getRoomExits(b).south)
    end)

    it("should not overwrite the far room's exit with a guessed reciprocal", function()
      local d_room = room({ hash = "d", name = "D", exits = {} })
      local c = room({ hash = "c", name = "C", exits = { west = "d" } })
      Carto.info = {}
      room({ hash = "b", name = "B", exits = { east = "c" } })
      assert.are.equal(d_room, getRoomExits(c).west)
    end)

    it("should correct an exit whose destination is stale", function()
      local x = room({ hash = "x", name = "X", exits = {} })
      local c = room({ hash = "c", name = "C", exits = {} })
      Carto.info = {}
      local b = room({ hash = "b", name = "B", exits = {} })
      setExit(b, x, "east")
      Carto.info = {}
      room({ hash = "b", name = "B", exits = { east = "c" } })
      assert.are.equal(c, getRoomExits(b).east)
    end)

    it("should remove an exit stub the room no longer has", function()
      local a = room({ hash = "a", name = "A", exits = { north = "b", east = "c" } })
      assert.is_true(has_stub(a, "east"))
      room({ hash = "a", name = "A", exits = { north = "b" } })
      assert.is_false(has_stub(a, "east"))
      assert.is_true(has_stub(a, "north"))
    end)

    it("should link rooms by vnum", function()
      Carto.prefs.gmcp.expect_hash = false
      _G.gmcp.Room = { Info = { vnum = 1, name = "A", exits = { north = 2 } } }
      raiseEvent("gmcp.Room.Info", "gmcp.Room.Info")
      _G.gmcp.Room = { Info = { vnum = 2, name = "B", exits = { south = 1 } } }
      raiseEvent("gmcp.Room.Info", "gmcp.Room.Info")
      assert.are.equal(2, getRoomExits(1).north)
      assert.are.equal(1, getRoomExits(2).south)
    end)
  end)

  describe("doors", function()
    it("should set a door on a short key", function()
      local a = room({ hash = "a", name = "A", exits = { n = "b" }, doors = { n = { status = 2 } } })
      assert.are.equal(2, getDoors(a).n)
    end)

    it("should cope with a door on a special exit", function()
      assert.is_truthy(room({ hash = "a", name = "A", exits = {}, doors = { gate = { status = 2 } } }))
    end)

    it("should cope with an unusable door status", function()
      assert.is_truthy(room({
        hash = "a", name = "A", exits = { north = "b" }, doors = { north = { status = "closed" } },
      }))
    end)

    it("should keep up/down doors and raise the change only once", function()
      local exits = { up = "b", north = "c" }
      local doors = { up = { status = 2 }, north = { status = 1 } }
      local a = room({ hash = "a", name = "A", exits = exits, doors = doors })
      assert.are.equal(2, getDoors(a).up)
      assert.are.equal(1, getDoors(a).n)
      assert.is_truthy(saw("onDoorChange"))
      events = {}
      room({ hash = "a", name = "A", exits = exits, doors = doors })
      assert.is_nil(saw("onDoorChange"))
      assert.are.equal(2, getDoors(a).up)
    end)

    it("should remove a door that has gone and raise the change", function()
      local exits = { north = "b" }
      local a = room({ hash = "a", name = "A", exits = exits, doors = { north = { status = 2 } } })
      events = {}
      room({ hash = "a", name = "A", exits = exits, doors = {} })
      assert.is_nil(getDoors(a).n)
      local change = saw("onDoorChange")
      assert.is_truthy(change)
      assert.are.same({ a, "n", 0, 2 }, change.args)
    end)
  end)

  describe("speedwalk", function()
    it("should finish an ordinary walk through full and short directions", function()
      local a = room({ hash = "a", name = "A", exits = { north = "b" } })
      local b = room({ hash = "b", name = "B", exits = { south = "a", up = "c" } })
      local c = room({ hash = "c", name = "C", exits = { down = "b" } })
      room({ hash = "b", name = "B", exits = { south = "a", up = "c" } })
      room({ hash = "a", name = "A", exits = { north = "b" } })
      walk({ "n", "up" }, { b, c })
      assert.are.equal("north", sent[1])
      room({ hash = "b", name = "B", exits = { south = "a", up = "c" } })
      assert.are.equal("u", sent[2])
      room({ hash = "c", name = "C", exits = { down = "b" } })
      assert.is_false(Carto.walking)
      assert.is_truthy(saw("sysSpeedwalkFinished"))
      assert.is_nil(saw("onSpeedwalkReset"))
      assert.is_truthy(a)
    end)

    it("should walk a path from Mudlet's own pathfinding", function()
      room({ hash = "a", name = "A", exits = { north = "b" } })
      local b = room({ hash = "b", name = "B", exits = { south = "a" } })
      room({ hash = "a", name = "A", exits = { north = "b" } })
      assert.is_truthy(gotoRoom(b))
      pump()
      assert.are.equal("north", sent[1])
      room({ hash = "b", name = "B", exits = { south = "a" } })
      assert.is_false(Carto.walking)
      assert.is_true(printed("You have arrived"))
    end)

    it("should raise the started event before the first step", function()
      room({ hash = "a", name = "A", exits = { north = "b" } })
      local b = room({ hash = "b", name = "B", exits = { south = "a" } })
      room({ hash = "a", name = "A", exits = { north = "b" } })
      walk({ "n" }, { b })
      assert.are.equal(1, #sent)
      assert.are.equal(0, saw("sysSpeedwalkStarted").sent)
    end)

    it("should start through a special exit", function()
      local a = room({ hash = "a", name = "A", exits = {} })
      local b = room({ hash = "b", name = "B", exits = {} })
      room({ hash = "a", name = "A", exits = {} })
      addSpecialExit(a, b, "enter portal")
      walk({ "enter portal" }, { b })
      assert.are.equal("enter portal", sent[1])
      room({ hash = "b", name = "B", exits = {} })
      assert.is_false(Carto.walking)
      assert.is_true(printed("You have arrived"))
    end)

    it("should take a special exit mid-path", function()
      room({ hash = "a", name = "A", exits = { north = "b" } })
      local b = room({ hash = "b", name = "B", exits = { south = "a" } })
      local c = room({ hash = "c", name = "C", exits = {} })
      room({ hash = "b", name = "B", exits = { south = "a" } })
      room({ hash = "a", name = "A", exits = { north = "b" } })
      walk({ "n", "pull lever" }, { b, c })
      room({ hash = "b", name = "B", exits = { south = "a" } })
      assert.are.equal("pull lever", sent[2])
    end)

    it("should abort cleanly when the first step isn't reachable", function()
      local b = room({ hash = "b", name = "B", exits = {} })
      room({ hash = "a", name = "A", exits = {} })
      walk({ "n" }, { b })
      assert.is_false(Carto.walking)
      assert.are.equal(0, #sent)
    end)

    it("should run a script: special exit as Lua", function()
      local a = room({ hash = "a", name = "A", exits = {} })
      local b = room({ hash = "b", name = "B", exits = {} })
      room({ hash = "a", name = "A", exits = {} })
      addSpecialExit(a, b, "script: cartoSpecScriptRan = true")
      walk({ "script: cartoSpecScriptRan = true" }, { b })
      assert.is_true(_G.cartoSpecScriptRan)
      assert.are.equal(0, #sent)
      _G.cartoSpecScriptRan = nil
      room({ hash = "b", name = "B", exits = {} })
      assert.is_false(Carto.walking)
    end)

    it("should end the walk if a script: special exit fails", function()
      local a = room({ hash = "a", name = "A", exits = {} })
      local b = room({ hash = "b", name = "B", exits = {} })
      room({ hash = "a", name = "A", exits = {} })
      addSpecialExit(a, b, "script: error('nope')")
      walk({ "script: error('nope')" }, { b })
      assert.is_false(Carto.walking)
    end)

    it("should carry on through a room update that isn't a move", function()
      room({ hash = "a", name = "A", exits = { north = "b" } })
      local b = room({ hash = "b", name = "B", exits = { south = "a", north = "c" } })
      local c = room({ hash = "c", name = "C", exits = { south = "b" } })
      room({ hash = "b", name = "B", exits = { south = "a", north = "c" } })
      room({ hash = "a", name = "A", exits = { north = "b" } })
      walk({ "n", "n" }, { b, c })

      -- Before the first step lands, and again before the second.
      room({ hash = "a", name = "A", exits = { north = "b" } })
      assert.is_true(Carto.walking)
      assert.are.same({ "north" }, sent)
      room({ hash = "b", name = "B", exits = { south = "a", north = "c" } })
      assert.are.same({ "north", "north" }, sent)
      room({ hash = "b", name = "B", exits = { south = "a", north = "c" } })
      assert.is_true(Carto.walking)
      assert.are.same({ "north", "north" }, sent)

      room({ hash = "c", name = "C", exits = { south = "b" } })
      assert.is_false(Carto.walking)
      assert.is_true(printed("You have arrived"))
    end)

    it("should say veered off when a step lands somewhere else", function()
      room({ hash = "a", name = "A", exits = { north = "b" } })
      local b = room({ hash = "b", name = "B", exits = { south = "a" } })
      room({ hash = "a", name = "A", exits = { north = "b" } })
      walk({ "n" }, { b })
      room({ hash = "z", name = "Z", exits = {} })
      assert.is_false(Carto.walking)
      assert.is_true(printed("veered off"))
      assert.is_truthy(saw("onSpeedwalkReset"))
    end)

    describe("when a step doesn't land", function()
      local b

      before_each(function()
        room({ hash = "a", name = "A", exits = { north = "b" } })
        b = room({ hash = "b", name = "B", exits = { south = "a" } })
        room({ hash = "a", name = "A", exits = { north = "b" } })
        Carto.prefs.speedwalk_timeout = 0.2
      end)

      local function outlast_the_timeout()
        pumpEvents(400)
      end

      it("should give up if the game says nothing", function()
        walk({ "n" }, { b })
        assert.is_true(Carto.walking)
        outlast_the_timeout()
        assert.is_false(Carto.walking)
        assert.is_true(printed("Something prevents you"))
        assert.is_truthy(saw("onSpeedwalkReset"))
        assert.is_nil(saw("sysSpeedwalkFinished"))
      end)

      it("should give up if the game resends the same room", function()
        walk({ "n" }, { b })
        room({ hash = "a", name = "A", exits = { north = "b" } })
        assert.is_true(Carto.walking)
        assert.is_false(printed("Something prevents you"))
        outlast_the_timeout()
        assert.is_false(Carto.walking)
        assert.is_false(printed("You have arrived"))
        assert.is_true(printed("Something prevents you"))
      end)

      it("should not time out a step that landed", function()
        walk({ "n" }, { b })
        room({ hash = "b", name = "B", exits = { south = "a" } })
        assert.is_false(Carto.walking)
        events = {}
        outlast_the_timeout()
        assert.is_nil(saw("onSpeedwalkReset"))
        assert.is_false(printed("Something prevents you"))
      end)

      it("should wait for as long as it takes with no timeout", function()
        Carto.prefs.speedwalk_timeout = 0
        walk({ "n" }, { b })
        outlast_the_timeout()
        assert.is_true(Carto.walking)
      end)

      it("should not time out while paused, but should after resuming", function()
        walk({ "n" }, { b })
        alias("walk pause")
        outlast_the_timeout()
        assert.is_true(Carto.walking)
        alias("walk resume")
        outlast_the_timeout()
        assert.is_false(Carto.walking)
        assert.is_true(printed("Something prevents you"))
      end)

      it("should not fire after the walk has been stopped", function()
        walk({ "n" }, { b })
        alias("walk stop")
        out = {}
        outlast_the_timeout()
        assert.is_false(printed("Something prevents you"))
      end)
    end)

    describe("when a walk can't start", function()
      it("should say why if the first step isn't reachable", function()
        local b = room({ hash = "b", name = "B", exits = {} })
        room({ hash = "a", name = "A", exits = {} })
        walk({ "n" }, { b })
        assert.are.same({ "No exits found." }, saw("onSpeedwalkFailed").args)
        assert.is_nil(saw("sysSpeedwalkStarted"))
        assert.is_nil(saw("onSpeedwalkReset"))
        assert.is_false(Carto.walking)
        assert.are.same({}, Carto.speedwalk_path)
      end)

      it("should say why if there's no path", function()
        room({ hash = "a", name = "A", exits = {} })
        walk({}, {})
        assert.are.same({ "No speedwalk path found." }, saw("onSpeedwalkFailed").args)
      end)

      it("should say why if the current room isn't known", function()
        walk({ "n" }, { 1 })
        assert.is_truthy(saw("onSpeedwalkFailed"))
        assert.is_false(Carto.walking)
      end)

      it("should leave a walk that's already under way alone", function()
        room({ hash = "a", name = "A", exits = { north = "b" } })
        local b = room({ hash = "b", name = "B", exits = { south = "a" } })
        room({ hash = "a", name = "A", exits = { north = "b" } })
        walk({ "n" }, { b })
        walk({ "n" }, { b })
        assert.are.same({ "You are already walking!" }, saw("onSpeedwalkFailed").args)
        assert.is_true(Carto.walking)
        assert.are.same({ "north" }, sent)
        room({ hash = "b", name = "B", exits = { south = "a" } })
        assert.is_true(printed("You have arrived"))
      end)

      it("should not raise it for a walk that starts", function()
        room({ hash = "a", name = "A", exits = { north = "b" } })
        local b = room({ hash = "b", name = "B", exits = { south = "a" } })
        room({ hash = "a", name = "A", exits = { north = "b" } })
        walk({ "n" }, { b })
        assert.is_nil(saw("onSpeedwalkFailed"))
      end)

      it("should leave gotoRoom's own failure to its return value", function()
        local z = room({ hash = "z", name = "Z", exits = {} })
        room({ hash = "a", name = "A", exits = {} })
        assert.is_falsy(gotoRoom(z))
        assert.is_nil(saw("onSpeedwalkFailed"))
      end)
    end)

    it("should raise the stopped event for walk stop", function()
      room({ hash = "a", name = "A", exits = { north = "b" } })
      local b = room({ hash = "b", name = "B", exits = { south = "a", north = "c" } })
      local c = room({ hash = "c", name = "C", exits = { south = "b" } })
      room({ hash = "b", name = "B", exits = { south = "a", north = "c" } })
      room({ hash = "a", name = "A", exits = { north = "b" } })
      walk({ "n", "n" }, { b, c })
      alias("walk stop")
      assert.is_false(Carto.walking)
      assert.is_truthy(saw("sysSpeedwalkStopped"))
      assert.is_nil(saw("sysSpeedwalkFinished"))
    end)

    it("should reset quietly when not walking", function()
      assert.has_no.errors(function()
        Carto:ResetWalking(true, "Nothing to reset.")
      end)
      assert.is_nil(saw("onSpeedwalkReset"))
    end)

    it("should do nothing if the map asks to walk after an uninstall", function()
      local carto = Carto
      _G.Carto = nil
      local ok, err = pcall(doSpeedWalk)
      _G.Carto = carto
      assert.is_true(ok, err)
    end)
  end)

  describe("doors on a speedwalk", function()
    local function walk_through(status)
      local doors = { north = { status = status } }
      room({ hash = "a", name = "A", exits = { north = "b" }, doors = doors })
      local b = room({ hash = "b", name = "B", exits = { south = "a" } })
      room({ hash = "a", name = "A", exits = { north = "b" }, doors = doors })
      walk({ "n" }, { b })
    end

    it("should open a closed door", function()
      walk_through(2)
      assert.are.same({ "open north", "north" }, sent)
    end)

    it("should unlock and open a locked door", function()
      walk_through(3)
      assert.are.same({ "unlock north", "open north", "north" }, sent)
    end)

    it("should walk straight through an open door", function()
      walk_through(1)
      assert.are.same({ "north" }, sent)
    end)

    it("should find doors on up and down", function()
      local doors = { up = { status = 2 } }
      room({ hash = "a", name = "A", exits = { up = "b" }, doors = doors })
      local b = room({ hash = "b", name = "B", exits = { down = "a" } })
      room({ hash = "a", name = "A", exits = { up = "b" }, doors = doors })
      walk({ "up" }, { b })
      assert.are.equal("open up", sent[1])
    end)

    it("should only send the command for a door on a special exit", function()
      local doors = { portal = { status = 2 } }
      room({ hash = "a", name = "A", exits = { portal = "b" }, doors = doors })
      local b = room({ hash = "b", name = "B", exits = {} })
      room({ hash = "a", name = "A", exits = { portal = "b" }, doors = doors })
      walk({ "portal" }, { b })
      assert.are.same({ "portal" }, sent)
    end)

    it("should use the door commands from the settings", function()
      alias("carto doors open open {dir} door")
      alias("carto doors unlock pick {dir} lock")
      walk_through(3)
      assert.are.same({ "pick north lock", "open north door", "north" }, sent)
    end)

    it("should accept a door command with no direction in it", function()
      alias("carto doors open push door")
      walk_through(2)
      assert.are.same({ "push door", "north" }, sent)
    end)

    it("should save the door commands", function()
      alias("carto doors open open {dir} door")
      Carto:LoadPreferences()
      assert.are.equal("open {dir} door", Carto.prefs.doors.open)
      assert.are.equal("unlock {dir}", Carto.prefs.doors.unlock)
      assert.are.equal("open {dir}", Carto.default.doors.open)
    end)

    it("should show the door commands", function()
      alias("carto doors")
      assert.is_true(printed("open {dir}"))
      assert.is_true(printed("unlock {dir}"))
    end)

    it("should explain {dir} in the help", function()
      assert.is_truthy(Carto.help.topics.carto_config:find("<i>{dir}</i>", 1, true))
    end)

    it("should reject anything else", function()
      alias("carto doors smash {dir}")
      alias("carto doors open")
      assert.is_true(printed("Syntax: carto doors"))
      assert.are.equal("open {dir}", Carto.prefs.doors.open)
      assert.is_nil(Carto.prefs.doors.smash)
    end)

    it("should never evaluate a door command", function()
      alias("carto doors open {(function() _G.cartoSpecPwned = true end)()}")
      walk_through(2)
      assert.is_nil(_G.cartoSpecPwned)
      assert.are.equal("{(function() _G.cartoSpecPwned = true end)()}", sent[1])
    end)

    it("should keep walking when opening the door updates the room", function()
      walk_through(2)
      room({ hash = "a", name = "A", exits = { north = "b" }, doors = { north = { status = 1 } } })
      assert.is_true(Carto.walking)
      assert.is_false(printed("Something prevents you"))
      room({ hash = "b", name = "B", exits = { south = "a" } })
      assert.is_false(Carto.walking)
      assert.is_true(printed("You have arrived"))
    end)

    it("should still arrive after opening a door", function()
      walk_through(2)
      room({ hash = "b", name = "B", exits = { south = "a" } })
      assert.is_false(Carto.walking)
      assert.is_true(printed("You have arrived"))
    end)
  end)

  describe("pausing a speedwalk", function()
    local a, b, c, e

    -- A north to B north to C, with E off to the side of B, leading on to C.
    local exits = {
      a = { north = "b" },
      b = { south = "a", north = "c", east = "e" },
      c = { south = "b", east = "e" },
      e = { west = "b", north = "c" },
    }

    local function at(hash)
      return room({ hash = hash, name = hash:upper(), exits = exits[hash] })
    end

    before_each(function()
      a, b, c, e = at("a"), at("b"), at("c"), at("e")
      at("b")
      at("c")
      at("b")
      at("a")
    end)

    it("should hold the walk until it's resumed", function()
      walk({ "n", "n" }, { b, c })
      alias("walk pause")
      assert.is_true(Carto.walking)
      assert.is_truthy(saw("sysSpeedwalkPaused"))
      at("b")
      assert.are.same({ "north" }, sent)

      alias("walk resume")
      pump()
      assert.is_truthy(saw("sysSpeedwalkResumed"))
      assert.are.same({ "north", "north" }, sent)

      at("c")
      assert.is_false(Carto.walking)
      assert.is_truthy(saw("sysSpeedwalkFinished"))
    end)

    it("should wait for a step that hasn't landed when resumed", function()
      walk({ "n", "n" }, { b, c })
      alias("walk pause")
      alias("walk resume")
      pump()
      assert.is_true(Carto.walking)
      assert.are.same({ "north" }, sent)

      at("b")
      assert.are.same({ "north", "north" }, sent)
    end)

    it("should find a new path if they've wandered off", function()
      walk({ "n", "n" }, { b, c })
      alias("walk pause")
      at("b")
      at("e")

      alias("walk resume")
      pump()
      assert.are.equal("north", sent[#sent])
      assert.are.equal(2, #sent)

      at("c")
      assert.is_false(Carto.walking)
      assert.is_true(printed("You have arrived"))
    end)

    it("should arrive if they got there on their own", function()
      walk({ "n", "n" }, { b, c })
      alias("walk pause")
      at("b")
      at("c")

      alias("walk resume")
      pump()
      assert.is_false(Carto.walking)
      assert.is_true(printed("You have arrived"))
      assert.are.same({ "north" }, sent)
    end)

    it("should end the walk if there's no way from where they are now", function()
      walk({ "n", "n" }, { b, c })
      alias("walk pause")
      room({ hash = "z", name = "Z", exits = {} })

      alias("walk resume")
      pump()
      assert.is_false(Carto.walking)
      assert.is_truthy(saw("onSpeedwalkReset"))
    end)

    it("should stop a paused walk", function()
      walk({ "n", "n" }, { b, c })
      alias("walk pause")
      alias("walk stop")
      assert.is_false(Carto.walking)
      assert.is_false(Carto.paused)
      assert.is_truthy(saw("sysSpeedwalkStopped"))
    end)

    it("should say so when there's nothing to pause or resume", function()
      alias("walk pause")
      alias("walk resume")
      assert.is_nil(saw("sysSpeedwalkPaused"))
      assert.is_nil(saw("sysSpeedwalkResumed"))
      assert.is_true(printed("You are not walking"))

      walk({ "n", "n" }, { b, c })
      out = {}
      alias("walk resume")
      assert.is_true(printed("not paused"))
      alias("walk pause")
      out = {}
      alias("walk pause")
      assert.is_true(printed("already paused"))
    end)

    it("should build its fixtures", function()
      assert.is_truthy(a and e)
    end)
  end)

  describe("special exits from GMCP", function()
    it("should add one in quick mode when the room is known", function()
      local b = room({ hash = "b", name = "B", exits = {} })
      local a = room({ hash = "a", name = "A", exits = { ["enter portal"] = "b" } })
      assert.are.equal(b, getSpecialExitsSwap(a)["enter portal"])
    end)

    it("should wait for an unknown room, then add it on walking through", function()
      local a = room({ hash = "a", name = "A", exits = { ["enter portal"] = "b" } })
      assert.is_nil(getSpecialExitsSwap(a)["enter portal"])
      local b = room({ hash = "b", name = "B", exits = {} })
      assert.are.equal(b, getSpecialExitsSwap(a)["enter portal"])
    end)

    it("should only add one by walking through it in normal mode", function()
      Carto.prefs.mode = "normal"
      local c = room({ hash = "c", name = "C", exits = {} })
      local a = room({ hash = "a", name = "A", exits = { portal = "b", gate = "c" } })
      local b = room({ hash = "b", name = "B", exits = {} })
      assert.are.equal(b, getSpecialExitsSwap(a).portal)
      assert.is_nil(getSpecialExitsSwap(a).gate)
      assert.is_truthy(c)
    end)

    it("should add one by vnum", function()
      Carto.prefs.gmcp.expect_hash = false
      _G.gmcp.Room = { Info = { vnum = 2, name = "B", exits = {} } }
      raiseEvent("gmcp.Room.Info", "gmcp.Room.Info")
      _G.gmcp.Room = { Info = { vnum = 1, name = "A", exits = { portal = 2 } } }
      raiseEvent("gmcp.Room.Info", "gmcp.Room.Info")
      assert.are.equal(2, getSpecialExitsSwap(1).portal)
    end)

    it("should correct a destination that has changed", function()
      local x = room({ hash = "x", name = "X", exits = {} })
      local y = room({ hash = "y", name = "Y", exits = {} })
      local a = room({ hash = "a", name = "A", exits = { portal = "x" } })
      assert.are.equal(x, getSpecialExitsSwap(a).portal)
      room({ hash = "a", name = "A", exits = { portal = "y" } })
      assert.are.equal(y, getSpecialExitsSwap(a).portal)
    end)

    it("should keep a hand-added special exit the server doesn't list", function()
      local b = room({ hash = "b", name = "B", exits = {} })
      local a = room({ hash = "a", name = "A", exits = {} })
      addSpecialExit(a, b, "pull lever")
      room({ hash = "a", name = "A", exits = { north = "c" } })
      assert.are.equal(b, getSpecialExitsSwap(a)["pull lever"])
    end)

    it("should never accept a script: exit from the server", function()
      local b = room({ hash = "b", name = "B", exits = {} })
      local evil = "script: cartoSpecPwned = true"
      local exits = { [evil] = "b", [" SCRIPT: cartoSpecPwned = true"] = "b" }
      local a = room({ hash = "a", name = "A", exits = exits })
      assert.are.same({}, getSpecialExitsSwap(a))

      -- Nor by walking through it, which goes by a different route.
      room({ hash = "b", name = "B", exits = {} })
      assert.are.same({}, getSpecialExitsSwap(a))
    end)

    it("should walk one using the path Mudlet finds", function()
      room({ hash = "b", name = "B", exits = {} })
      local a = room({ hash = "a", name = "A", exits = { ["enter portal"] = "b" } })
      local b = getRoomIDbyHash("b")
      assert.is_truthy(gotoRoom(b))
      pump()
      assert.are.same({ "enter portal" }, sent)
      room({ hash = "b", name = "B", exits = {} })
      assert.is_false(Carto.walking)
      assert.is_truthy(a)
    end)
  end)

  describe("carto room", function()
    it("should show what the map knows about the current room", function()
      room({ hash = "c", name = "Cellar", exits = {} })
      room({ hash = "a", name = "Attic", area = "Manor", environment = "forest", exits = {
        north = "b", down = "c", ["enter portal"] = "c",
      }, doors = { down = { status = 2 } } })
      out = {}
      alias("carto room")
      assert.is_true(printed("Attic"))
      assert.is_true(printed("Manor"))
      assert.is_true(printed("504"))
      assert.is_true(printed("unexplored"))
      assert.is_true(printed("(Cellar) [closed door]"))
      assert.is_true(printed("Special exit enter portal"))
    end)

    it("should show a room by ID", function()
      local a = room({ hash = "a", name = "Attic", exits = {} })
      room({ hash = "b", name = "Barn", exits = {} })
      out = {}
      alias("carto room " .. a)
      assert.is_true(printed("Attic"))
      assert.is_false(printed("Barn"))
    end)

    it("should say so for a room that isn't on the map or a bad ID", function()
      alias("carto room 999")
      assert.is_true(printed("not on the map"))
      alias("carto room abc")
      assert.is_true(printed("Syntax: carto room"))
    end)
  end)

  describe("walk path", function()
    local a, b, c

    before_each(function()
      a = room({ hash = "a", name = "A", exits = { north = "b" } })
      b = room({ hash = "b", name = "B", exits = { south = "a", up = "c" } })
      c = room({ hash = "c", name = "C", exits = { down = "b" } })
      room({ hash = "b", name = "B", exits = { south = "a", up = "c" } })
      room({ hash = "a", name = "A", exits = { north = "b" } })
      out = {}
    end)

    it("should show the way from the current room without walking", function()
      alias("walk path " .. c)
      assert.is_true(printed("2 steps"))
      assert.is_true(printed("n, up"))
      assert.are.same({}, sent)
      assert.is_false(Carto.walking)
    end)

    it("should show the way between two given rooms", function()
      alias("walk path " .. b .. " " .. a)
      assert.is_true(printed("1 step:"))
      assert.is_true(printed("s"))
    end)

    it("should say so when it can't", function()
      local z = room({ hash = "z", name = "Z", exits = {} })
      room({ hash = "a", name = "A", exits = { north = "b" } })
      out = {}
      alias("walk path " .. z)
      assert.is_true(printed("no path"))
      alias("walk path 999")
      assert.is_true(printed("not on the map"))
      alias("walk path " .. a .. " " .. a)
      assert.is_true(printed("same room"))
      alias("walk path abc")
      assert.is_true(printed("Syntax: walk path"))
    end)
  end)

  describe("terrain and room details", function()
    it("should keep a manual lock and weight on a revisit", function()
      local a = room({ hash = "a", name = "A", exits = {}, environment = "forest" })
      lockRoom(a, true)
      setRoomWeight(a, 42)
      room({ hash = "a", name = "A", exits = {}, environment = "forest" })
      assert.is_true(roomLocked(a))
      assert.are.equal(42, getRoomWeight(a))
    end)

    it("should apply terrain rules to new rooms and terrain changes", function()
      local a = room({ hash = "a", name = "A", exits = {}, environment = "deep water" })
      assert.is_true(roomLocked(a))
      local b = room({ hash = "b", name = "B", exits = {}, environment = "water" })
      assert.are.equal(100, getRoomWeight(b))
      room({ hash = "b", name = "B", exits = {}, environment = "forest" })
      assert.are.equal(1, getRoomWeight(b))
    end)

    it("should honour a remapped environment property", function()
      Carto.prefs.gmcp.properties.environment = "terrain"
      local a = room({ hash = "a", name = "A", exits = {}, terrain = "forest" })
      assert.are.equal(504, getRoomEnv(a))
    end)

    it("should use the symbol as the room's character", function()
      local a = room({ hash = "a", name = "A", exits = {}, symbol = "@" })
      assert.are.equal("@", getRoomChar(a))
    end)

    it("should prefer the icon to the symbol", function()
      local a = room({ hash = "a", name = "A", exits = {}, symbol = "@", icon = "#" })
      assert.are.equal("#", getRoomChar(a))
    end)
  end)

  describe("recalls", function()
    it("should reject a position that isn't a whole number of at least 1", function()
      room({ hash = "a", name = "A", exits = {} })
      Carto.prefs.recalls = { 91, 92 }
      for _, position in ipairs({ "0", "-1", "1.5" }) do
        alias("walk remember " .. position)
      end
      assert.are.same({ 91, 92 }, Carto.prefs.recalls)
    end)

    it("should not fall back to the current room on junk positions", function()
      local a = room({ hash = "a", name = "A", exits = {} })
      Carto.prefs.recalls = { a }
      alias("walk forget abc")
      alias("walk remember abc")
      alias("walk recall abc")
      assert.are.same({ a }, Carto.prefs.recalls)
    end)

    it("should list recalls even if a room has been deleted", function()
      local a = room({ hash = "a", name = "A", exits = {} })
      Carto.prefs.recalls = { a, 999 }
      alias("walk recall")
      assert.is_true(printed("unknown room"))
    end)

    it("should report a recall to a deleted room", function()
      room({ hash = "a", name = "A", exits = {} })
      Carto.prefs.recalls = { 999 }
      alias("walk recall 1")
      assert.is_true(printed("Could not recall"))
    end)

    it("should remember, recall and forget", function()
      local a = room({ hash = "a", name = "A", exits = {} })
      alias("walk remember")
      assert.are.same({ a }, Carto.prefs.recalls)
      alias("walk recall 1")
      assert.is_true(printed("Recalling to room"))
      alias("walk forget 1")
      assert.are.same({}, Carto.prefs.recalls)
    end)
  end)

  describe("carto settings", function()
    it("should keep the current event when given none", function()
      alias("carto event")
      assert.are.equal("gmcp.Room.Info", Carto.prefs.gmcp.event)
    end)

    it("should not claim to have set an invalid boolean", function()
      alias("carto expect_hash maybe")
      alias("carto expect_coordinates maybe")
      assert.is_false(printed("Setting expect_"))
    end)

    it("should list the property names", function()
      alias("carto properties")
      assert.is_true(printed("environment"))
    end)

    it("should apply and save valid settings", function()
      alias("carto expect_hash false")
      assert.is_false(Carto.prefs.gmcp.expect_hash)
      alias("carto properties hash id")
      assert.are.equal("id", Carto.prefs.gmcp.properties.hash)
      alias("carto mode normal")
      assert.are.equal("normal", Carto.prefs.mode)
      Carto:LoadPreferences()
      assert.is_false(Carto.prefs.gmcp.expect_hash)
      assert.are.equal("id", Carto.prefs.gmcp.properties.hash)
    end)

    it("should stop listening to the old event when it changes", function()
      alias("carto event gmcp.Carto.Spec")
      local handlers = getNamedEventHandlers(Carto.config.name)
      assert.is_true(table.contains(handlers, "gmcp.Carto.Spec"))
      assert.is_false(table.contains(handlers, "gmcp.Room.Info"))

      _G.gmcp.Room = { Info = { hash = "old", name = "Old", exits = {} } }
      raiseEvent("gmcp.Room.Info", "gmcp.Room.Info")
      assert.are.equal(-1, getRoomIDbyHash("old"))

      _G.gmcp.Carto = { Spec = { hash = "new", name = "New", exits = {} } }
      raiseEvent("gmcp.Carto.Spec", "gmcp.Carto.Spec")
      assert.is_true(getRoomIDbyHash("new") > 0)
      _G.gmcp.Carto = nil
    end)

    it("should fill nested settings missing from a saved file", function()
      table.save(getMudletHomeDir() .. "/" .. Carto.config.preferences_file, {
        gmcp = { event = "gmcp.Room.Info", properties = { hash = "id" } },
      })
      Carto:LoadPreferences()
      assert.are.equal("id", Carto.prefs.gmcp.properties.hash)
      assert.are.equal("vnum", Carto.prefs.gmcp.properties.vnum)
      assert.is_true(Carto.prefs.gmcp.expect_hash)
      assert.are.equal("quick", Carto.prefs.mode)
      assert.are.same({}, Carto.prefs.recalls)
      assert.are.equal("hash", Carto.default.gmcp.properties.hash)
    end)
  end)

  describe("walk timeout", function()
    it("should set, save and show it", function()
      alias("walk timeout 2.5")
      assert.are.equal(2.5, Carto.prefs.speedwalk_timeout)
      Carto:LoadPreferences()
      assert.are.equal(2.5, Carto.prefs.speedwalk_timeout)
      out = {}
      alias("walk timeout")
      assert.is_true(printed("2.5 seconds"))
    end)

    it("should be readable by other scripts", function()
      Carto:SetSpeedwalkTimeout(2.5)
      assert.are.equal(2.5, Carto:GetSpeedwalkTimeout())
    end)

    it("should ignore anything that isn't zero or more seconds", function()
      alias("walk timeout abc")
      alias("walk timeout -1")
      assert.are.equal(5, Carto.prefs.speedwalk_timeout)
    end)
  end)

  describe("walk speed", function()
    it("should survive a reconnect", function()
      alias("walk speed 2")
      Carto:EventHandler("sysConnectionEvent")
      assert.are.equal(2, Carto.prefs.speedwalk_delay)
    end)

    it("should match the documented slow and fast delays", function()
      alias("walk slow")
      assert.are.equal(Carto.config.speed_walk_slow, Carto.prefs.speedwalk_delay)
      alias("walk fast")
      assert.are.equal(Carto.config.speed_walk_fast, Carto.prefs.speedwalk_delay)
    end)

    describe("during a walk", function()
      local b, c

      before_each(function()
        room({ hash = "a", name = "A", exits = { north = "b" } })
        b = room({ hash = "b", name = "B", exits = { south = "a", north = "c" } })
        c = room({ hash = "c", name = "C", exits = { south = "b" } })
        room({ hash = "b", name = "B", exits = { south = "a", north = "c" } })
        room({ hash = "a", name = "A", exits = { north = "b" } })
      end)

      it("should slow down from the next step", function()
        walk({ "n", "n" }, { b, c })
        alias("walk speed 0.3")
        room({ hash = "b", name = "B", exits = { south = "a", north = "c" } })
        assert.are.same({ "north" }, sent)
        pumpEvents(500)
        assert.are.same({ "north", "north" }, sent)
      end)

      it("should speed up from the next step", function()
        alias("walk speed 30")
        walk({ "n", "n" }, { b, c })
        alias("walk speed 0")
        room({ hash = "b", name = "B", exits = { south = "a", north = "c" } })
        assert.are.same({ "north", "north" }, sent)
      end)

      it("should wait out the delay before each step but the first", function()
        alias("walk speed 0.3")
        walk({ "n", "n" }, { b, c })
        assert.are.same({ "north" }, sent)
        room({ hash = "b", name = "B", exits = { south = "a", north = "c" } })
        assert.are.same({ "north" }, sent)
        pumpEvents(500)
        assert.are.same({ "north", "north" }, sent)
      end)

      it("should drop the pending step when paused, and take it on resuming", function()
        alias("walk speed 0.3")
        walk({ "n", "n" }, { b, c })
        room({ hash = "b", name = "B", exits = { south = "a", north = "c" } })
        alias("walk pause")
        pumpEvents(500)
        assert.are.same({ "north" }, sent)
        alias("walk resume")
        assert.are.same({ "north", "north" }, sent)
      end)
    end)

    it("should be readable by other scripts", function()
      Carto:SetSpeedwalkDelay(2)
      assert.are.equal(2, Carto:GetSpeedwalkDelay())
    end)

    it("should ignore a speed that isn't a number", function()
      alias("walk speed 2")
      alias("walk speed abc")
      assert.are.equal(2, Carto.prefs.speedwalk_delay)
    end)
  end)

  describe("aliases", function()
    it("should leave input that only starts with walk or carto alone", function()
      alias("walkspeed 7")
      assert.are.equal(0, Carto.prefs.speedwalk_delay)
      alias("cartomode normal")
      assert.are.equal("quick", Carto.prefs.mode)
    end)
  end)

  describe("connection", function()
    it("should announce itself as a mapper when loaded, not on every connect", function()
      events = {}
      Carto:EventHandler("sysConnectionEvent")
      assert.is_nil(saw("mapperScriptLoaded"))
      Carto:EventHandler("sysLoadEvent")
      assert.are.same({ "Carto" }, saw("mapperScriptLoaded").args)
    end)

    it("should forget the current room on disconnect", function()
      local a = room({ hash = "a", name = "A", exits = { north = "b" } })
      Carto:EventHandler("sysDisconnectionEvent")
      assert.is_nil(Carto.info.current)
      room({ hash = "b", name = "B", exits = {} })
      assert.is_nil(getRoomExits(a).north)
    end)
  end)

  describe("gmcp", function()
    it("should return nil for a package that isn't there", function()
      _G.gmcp.Room = {}
      assert.is_nil(Carto:TableFromPackage("gmcp.Room.Info"))
      assert.is_nil(Carto:TableFromPackage("gmcp.Nope.Info.Deeper"))
    end)

    it("should ignore an event for a package that isn't there", function()
      _G.gmcp.Room = {}
      assert.has_no.errors(function()
        Carto:Move("gmcp.Room.Info", "gmcp.Room.Info")
      end)
    end)
  end)

  describe("debug output", function()
    local real_d, messages

    before_each(function()
      real_d, messages = _G._d, {}
      _G._d = function(text) messages[#messages + 1] = text end
    end)

    after_each(function()
      _G._d = real_d
    end)

    local function logged(text)
      for _, line in ipairs(messages) do
        if line:find(text, 1, true) then
          return true
        end
      end
      return false
    end

    it("should stay quiet with debugging off", function()
      room({ hash = "a", name = "A", exits = {} })
      assert.are.same({}, messages)
    end)

    it("should fill in the caller's locals with debugging on", function()
      Carto.debug = true
      local a = room({ hash = "a", name = "A", exits = {} })
      assert.is_true(logged("Room ID for A is " .. a))
    end)

    it("should get through a walk with debugging on", function()
      Carto.debug = true
      room({ hash = "a", name = "A", exits = { north = "b" } })
      local b = room({ hash = "b", name = "B", exits = { south = "a" } })
      room({ hash = "a", name = "A", exits = { north = "b" } })
      walk({ "n" }, { b })
      room({ hash = "b", name = "B", exits = { south = "a" } })
      assert.is_false(Carto.walking)
      assert.is_true(printed("You have arrived"))
    end)
  end)
end)
