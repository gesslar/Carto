# Carto

## Description

This is a Mudlet package that allows you to map your adventures. It relies on
GMCP to get the room information, so it builds the map as you walk, with no
triggers or prompt patterns to set up.

Carto takes the place of Mudlet's generic mapper, and uninstalls it if it finds
it when installing.

## Usage

In Mudlet, type `walk` to see the help information for walking, and `carto` for
configuration.

Double-clicking a room on the map walks you there, the same as `walk to`.

### Walking

- `walk to <room_id>` - Walk to room `room_id`.
- `walk stop` - Stop walking.
- `walk pause` - Pause walking.
- `walk resume` - Resume walking, finding a new path if you've moved since
  pausing.
- `walk path [from_id] <to_id>` - See the way to a room, without walking it.
- `walk slow` - Set walk speed to 3 seconds per step.
- `walk fast` - Set walk speed to 0.5 seconds per step.
- `walk speed` - See your current walk speed.
- `walk speed <n>` - Set walk speed to `n` seconds per step (default: 0).
- `walk timeout` - See how long to wait for a step before giving up on the walk.
- `walk timeout <n>` - Wait `n` seconds for a step (default: 5), or 0 for as long
  as it takes.

A closed or locked door on the way is opened before stepping through it, using
the commands from `carto doors`. The walk ends if a step lands somewhere
unexpected, or hasn't landed by the end of the timeout.

### Recall points

Recall points are saved for each Mudlet profile.

- `walk remember` - Remember the current room.
- `walk remember <position>` - Remember the current room at `position`.
- `walk forget` - Forget the current room.
- `walk forget <position>` - Forget the room at `position`.
- `walk recall` - List all recall positions.
- `walk recall <position>` - Recall to the room at `position`.

### The map

- `carto room [room_id]` - See what the map knows about a room, or the current
  one.

## Configuration

- `carto` - See the help for these commands.
- `carto config` - See the current GMCP settings.
- `carto mode <quick|normal>` - Set how exits are built (default: `quick`).
  - `quick` builds an exit as soon as you see one leading to a room that's
    already on the map, along with a way back when there isn't one already.
  - `normal` builds an exit only when you walk through it.
- `carto doors` - See the commands used to get through doors while walking.
- `carto doors <open|unlock> <command>` - Set one of those commands, for games
  that word them differently. `{dir}` is replaced with the full name of the
  direction (defaults: `open {dir}` and `unlock {dir}`), for example
  `carto doors open open {dir} door`.
- `carto event <event>` - Set the event that triggers the mapper (default:
  `gmcp.Room.Info`).
- `carto expect_coordinates <true|false>` - Set whether to expect coordinates
  from the GMCP event (default: `true`).
- `carto expect_hash <true|false>` - Set whether rooms are identified by hash
  rather than vnum (default: `true`).
- `carto properties` - See the property names expected from the GMCP event.
- `carto properties <property> <name>` - Set the name a property goes by in your
  game's GMCP. Each one defaults to its own name:
  `hash`, `vnum`, `area`, `name`, `environment`, `symbol`, `exits`, `coords`,
  `doors`, `type`, `subtype` and `icon`.

## What Carto expects from GMCP

Each room update needs a `hash` or a `vnum`, depending on `expect_hash`. Anything
else that's missing is left out or given a default.

```json
{
  "hash": "abc123",
  "name": "The Town Square",
  "area": "Town",
  "environment": "road",
  "coords": [10, 20, 0],
  "exits": { "north": "def456", "enter portal": "ghi789" },
  "doors": { "north": { "status": 2 } }
}
```

- `exits` - Directions and the `hash` or `vnum` they lead to. Directions can be
  short (`n`) or in full (`north`). When `exits` is there, exits and exit stubs
  the room no longer lists are removed from the map. When it's left out, they
  are left alone.
- `doors` - The same keys as `exits`, each with a `status` of 1 (open), 2 (closed)
  or 3 (locked). A door the room no longer lists is removed from the map, which
  means all of them if `doors` is left out, unlike `exits`.
- `coords` - An `[x, y, z]` array, or a string such as `"10,20,0"`. Without usable
  coordinates, a new room is placed relative to the one you came from, and a room
  already on the map stays where it is.
- `environment` - The room's terrain, which sets its colour on the map. These are
  known, and anything else gets a default colour: `beach`, `desert`, `dirt road`,
  `dusty`, `forest`, `grass`, `grassy`, `impassable`, `indoor`, `mountain`, `mud`,
  `path`, `road`, `rocky`, `sand`, `sandy`, `shallow water`, `snow`, `swamp`,
  `tunnels`, `water` and `deep water`. When a room's terrain changes, `deep water`
  locks it against pathfinding and `water` makes it costly to path through. Locks
  and weights you've set yourself stay until then.
- `icon`, `symbol`, `subtype`, `type` - The first of these sets the room's
  character on the map. `icon` and `symbol` are used as they are, while `subtype`
  and `type` get a glyph if they're one of `bank`, `shop`, `food`, `drink`,
  `library`, `tavern`, `inn` or `storage`.

Your game can send a room update for reasons other than moving, such as a door
being opened. Carto applies those to the map, and they don't affect a walk.

### Special exits

Any entry in `exits` that isn't a standard direction is a special exit. Its key
is the command to send, and its value is the `hash` or `vnum` it leads to, the
same as any other exit.

- A special exit is added once the room it leads to is on the map. In `quick`
  mode that's as soon as you see the exit and know the room, and in `normal`
  mode it's when you walk through it.
- Doors on special exits go in `doors` under the same key, though walking doesn't
  open them.
- Special exits aren't removed when the server stops listing them, because the
  ones you add yourself look just the same.
- Keys starting with `script:` are ignored. Speedwalking runs those as Lua, so
  they can only be added to the map by you, not by the server.

## Events

These are raised for other scripts to use.

- `onMoveMap(room_id)` - A room update has been applied to the map. This happens
  on every update, including ones where you haven't moved.
- `onNewRoom()` - A room update is being applied to the map, and its name, area and
  terrain are done, but not yet its coordinates, exits or doors. Despite the name,
  this happens on every update, not just for new rooms.
- `onDoorChange(room_id, command, status, old_status)` - A door has been added,
  changed, or removed, in which case `status` is 0. `command` is the name the door
  goes by in the map, which is short for directions other than `up` and `down`.
- `sysSpeedwalkStarted()` - A walk has started, before its first step.
- `sysSpeedwalkPaused()` - A walk has been paused.
- `sysSpeedwalkResumed()` - A walk has been resumed.
- `sysSpeedwalkFinished(exception, reason)` - A walk has reached its destination.
- `sysSpeedwalkStopped(exception, reason)` - A walk was ended with `walk stop`.
- `onSpeedwalkReset(exception, reason)` - A walk was interrupted, such as by being
  blocked, landing somewhere unexpected, or disconnecting. `reason` says which.
- `onSpeedwalkFailed(reason)` - A walk couldn't start, raised during the call that
  asked for it. If a walk was already under way, it carries on. `gotoRoom` only
  gets as far as Carto once Mudlet has found a path, so check what `gotoRoom`
  returns as well.
- `mapperScriptLoaded(package_name)` - Carto has loaded, as the generic mapper
  also announces. `package_name` is `Carto`.

## Functions

These are for other scripts to use.

- `Carto:GetSpeedwalkDelay()` - The walk speed, in seconds per step.
- `Carto:SetSpeedwalkDelay(delay, override)` - Set and save the walk speed, which
  takes effect from the next step. `override` allows a delay below the minimum.
- `Carto:GetSpeedwalkTimeout()` - How many seconds to wait for a step, where 0
  means for as long as it takes.
- `Carto:SetSpeedwalkTimeout(timeout)` - Set and save that, which takes effect
  from the next step.

## Support

While there is no official support and this is a hobby project, you are welcome
to report issues on the [GitHub repo](https://github.com/gesslar/Carto).

## Dependencies

The following packages are required and will be automatically installed if they
are missing:

- [Helper](https://github.com/gesslar/Helper)

## Development

- `npm run build` - Build the package with
  [muddy](https://github.com/gesslar/muddy).
- `npm run watch` - Build whenever something changes.
- `npm test` - Run the specs in `src/resources/test`, inside real Mudlet, using
  the `gesslardev/mudlet-busted` Docker image.
- `npm run test:tree` - The same, with each spec listed.
- `npm run docker:update` - Get the latest version of that image.
- `npm run update-glu` - Get the latest version of the vendored Glu.

## Credits

[Compass icons created by Freepik - Flaticon](https://www.flaticon.com/free-icons/map)

## License

`carto` is released under the [0BSD](LICENSE.txt).
