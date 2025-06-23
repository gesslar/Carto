# Carto

## Description

This is a Mudlet package that allows you to map your adventures. It relies on
GMCP to get the room information.

## GMCP Configuration

To configure the package, type `carto` in Mudlet. You will be provided with a
list of commands to set various options in order to get the package to work
with your current mud.

- `carto event <event>` - Set the event that triggers the Mapper (default:
  `gmcp.Room.Info`).
- `carto expect_coordinates <boolean>` - Set whether to expect coordinates from
  the GMCP event (default: `true`).
- `carto expect_hash <boolean>` - Set whether to expect a hash or vnum from the
  GMCP event (default: `true`).
- `carto properties` - View the current property names we can expect from the
  GMCP event.
- `carto properties <properties>` - Set the property names we can expect from
  the GMCP event.

  Defaults:

  - `hash` - The hash value of the room (default: `hash`).
  - `vnum` - The vnum of the room (default: `vnum`).
  - `area` - The area of the room (default: `area`).
  - `name` - The name of the room (default: `name`).
  - `environment` - The environment of the room (default: `environment`).
  - `symbol` - The symbol of the room (default: `symbol`).
  - `exits` - The exits of the room (default: `exits`).
  - `coords` - The coordinates of the room (default: `coords`).
  - `doors` - The doors of the room (default: `doors`).
  - `type` - The type of the room (default: `type`).
  - `subtype` - The subtype of the room (default: `subtype`).
  - `icon` - The icon of the room (default: `icon`).

## Usage

In Mudlet, type `walk` to see the help information for this package.

- `walk stop` - Stop walking.
- `walk slow` - Set walk speed to 3 seconds per step.
- `walk fast` - Set walk speed to 0.5 seconds per step.
- `walk speed` - See your current walk speed.
- `walk speed <n>` - Set walk speed to `n` seconds per step.
- `walk to <room_id>` - Walk to room `room_id`.
- `walk remember` - Remember the current room.
- `walk remember <position>` - Remember the current room at `position`.
- `walk forget` - Forget the current room.
- `walk forget <position>` - Forget the room at `position`.
- `walk recall` - List all recall positions.
- `walk recall <position>` - Recall to the room at `position`.

## Support

While there is no official support and this is a hobby project, you are welcome
to report issues on the [GitHub repo](https://github.com/gesslar/Carto).

## Dependencies

The following packages are required and will be automatically installed if they
are missing:

* [Helper](https://github.com/gesslar/Helper)

## Credits

[Compass icons created by Freepik - Flaticon](https://www.flaticon.com/free-icons/map)
