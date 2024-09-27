local input = matches[2]:trim()
local command, value = input:match("^(%S+)%s*(.*)$")

if command == "slow" then
  command = "speed"
  value = 1.0
elseif command == "fast" then
  command = "speed"
  value = 0.5
end

if command == "remember" then
  Carto:RememberRoom(value and tonumber(value) or nil)
elseif command == "forget" then
  Carto:ForgetRoom(value and tonumber(value) or nil)
elseif command == "recall" then
  if value ~= "" then
    Carto:RecallRoom(tonumber(value))
  else
    Carto:DisplayRecalls()
  end
elseif command == "stop" then
  -- Stop the speedwalk
  local walking = Carto.walking

  if not walking then
    echo("You are not walking.\n")
  else
    Carto:ResetWalking()
    echo("Speedwalk stopped.\n")
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
  helper.print({text = Carto.help.topics.usage, styles = Carto.help_styles})
end
