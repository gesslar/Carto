local input = matches[2]:trim()
local command, value = input:match("^(%S+)%s*(.*)$")

if command == "slow" then
  command = "speed"
  value = Carto.config.speed_walk_slow
elseif command == "fast" then
  command = "speed"
  value = Carto.config.speed_walk_fast
end

local position = tonumber(value)

-- With no position these commands act on the current room or list every recall
-- point, so a position that doesn't parse must not fall back to that.
if (command == "remember" or command == "forget" or command == "recall")
  and value ~= "" and not position then
  echo("A recall position must be a number.\n")
  return
end

if command == "remember" then
  Carto:RememberRoom(position)
elseif command == "forget" then
  Carto:ForgetRoom(position)
elseif command == "recall" then
  if position then
    Carto:RecallRoom(position)
  else
    Carto:DisplayRecalls()
  end
elseif command == "stop" then
  -- Stop the speedwalk
  local walking = Carto.walking

  if not walking then
    echo("You are not walking.\n")
  else
    Carto:ResetWalking(false, "User stopped the walk", "sysSpeedwalkStopped")
    echo("Speedwalk stopped.\n")
  end
elseif command == "timeout" then
  if value ~= "" then
    Carto:SetSpeedwalkTimeout(value)
  else
    echo("Current walk timeout is " .. Carto.prefs.speedwalk_timeout .. " seconds.\n")
  end
elseif command == "pause" then
  Carto:PauseWalking()
elseif command == "resume" then
  Carto:ResumeWalking()
elseif command == "path" then
  local first, second = value:match("^(%d+)%s*(%d*)$")

  if not first then
    echo("Syntax: walk path [from_id] <to_id>\n")
  elseif second ~= "" then
    Carto:DisplayPath(tonumber(first), tonumber(second))
  else
    Carto:DisplayPath(nil, tonumber(first))
  end
elseif command == "speed" then
  if value ~= "" then
    -- Set new speed (delay)
    Carto:SetSpeedwalkDelay(value, false)
  else
    -- Check current speed (delay)
    if Carto.prefs.speedwalk_delay == 1 then
      echo("Current walk speed is " .. Carto.prefs.speedwalk_delay .. " second per step.\n")
    else
      echo("Current walk speed is " .. Carto.prefs.speedwalk_delay .. " seconds per step.\n")
    end
  end
elseif command == "to" and tonumber(value) then
  local roomNumber = tonumber(value)
  local currentRoom = getPlayerRoom()

  if currentRoom == roomNumber then
    echo("You are already there.\n")
    return
  end

  local result, message = gotoRoom(roomNumber)

  -- Walk to a specific room number
  if not result then
    echo("Room " .. message .. ".\n")
  end
else
  -- Print out the walk instructions
---@diagnostic disable-next-line: undefined-global
  helper.print({text = Carto.help.topics.usage, styles = Carto.help_styles})
end
