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
  if value ~= "" then
    Mapper:RememberRoom(tonumber(value))
  else
    Mapper:Echo("Syntax: walk remember <recall number>", "info")
  end
elseif command == "recall" then
  if value ~= "" then
    Mapper:RecallRoom(tonumber(value))
  else
    Mapper:Echo("Syntax: walk recall <recall number>", "info")
  end
elseif command == "stop" then
  -- Stop the speedwalk
  local walking = Mapper.walking

  if not walking then
    Mapper:Echo("You are not walking.", "info")
  else
    Mapper:ResetWalking()
    Mapper:Echo("Speedwalk stopped.", "info")
  end
elseif command == "speed" then
  if value ~= "" then
    -- Set new speed (delay)
    Mapper:SetSpeedwalkDelay(value)
  else
    -- Check current speed (delay)
    if Mapper.config.speedwalk_delay == 1 then
      Mapper:Echo("Current walk speed is " .. Mapper.config.speedwalk_delay .. " second per step.", "info")
    else
      Mapper:Echo("Current walk speed is " .. Mapper.config.speedwalk_delay .. " seconds per step.", "info")
    end
  end
elseif command == "to" and tonumber(value) then
  local roomNumber = tonumber(value)
  local currentRoom = getPlayerRoom()

  if currentRoom == roomNumber then
    Mapper:Echo("You are already there.", "info")
    return
  end

  local result, message = gotoRoom(roomNumber)

  -- Walk to a specific room number
  if not result then
    Mapper:Echo("Room " .. message .. ".", "error")
  end
else
  -- Print out the walk instructions
  Mapper:Echo("Syntax: walk [stop|slow|fast|speed|speed <seconds>|to <room number>]", "info")
end
