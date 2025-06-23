--[[
  Dependent is a script that handles dependencies for other scripts.
]]

-- Forward declarations
local is_array, is_associative_array
local reset = {
  source_script = nil,
  required = {},
  installed = {},
  missing = {},
  still_missing = {},
}

---@class Dependent
---@field config table
---@field timers table
---@field event_handlers table
---@field dependencies table
Dependent = Dependent or {
  config = {
    name = "Dependent",
    version = "1.0.0",
    description = "A script that handles dependencies for other scripts.",
    author = "Gesslar",
    url = "https://github.com/gesslar/Dependent",
    max_retries = 3,
  },
  handler_prefix = nil,
  timers = {},
  event_handlers = {},
  dependencies = {}, -- Table of dependencies
}

---@param opts table
---@param it number
function Dependent:run(opts, it)
  -- Ensure we have the required options
  assert(type(opts) == "table", "opts must be a table")

  -- Required options
  -- We need
  -- 1. The name of the package that is calling Dependent
  -- 2. A table of { name = "name", url = "url" } for each dependency
  assert(type(opts.name) == "string", "opts.name must be a string")
  assert(type(opts.dependencies) == "table", "opts.dependencies must be a table")
  assert(is_array(opts.dependencies), "opts.dependencies must be an array")
  for _, dependency in ipairs(opts.dependencies) do
    assert(type(dependency) == "table", "opts.dependencies must be an array of tables")
    assert(is_associative_array(dependency), "dependency must be an associative array")
    assert(type(dependency.name) == "string", "dependency.name must be a string")
    assert(type(dependency.url) == "string", "dependency.url must be a string")
  end

  -- Setup the handler prefix
  self.handler_prefix = "Dependent:" .. opts.name .. ":"
  -- Setup the other handler names
  self.event_handlers.sysInstall = self.handler_prefix .. "Install"
  self.timers.install = self.handler_prefix .. "Install"
  self.timers.check = self.handler_prefix .. "Check"
  self.timers.retry = self.handler_prefix .. "Retry"

  -- Ensure we're not already running. If we are, we'll try again in 2 seconds
  -- to a maximum of self.config.max_retries
  if self:Running() then
    it = it and it + 1 or 0

    if it > self.config.max_retries then return end
    self:EnableTimer("retry", function() self:run(opts, it) end)
    return
  end

  echo(f"We are not running.\n")
  -- Setup dependency information
  self.dependencies = reset
  self.dependencies.source_script = opts.name
  self.dependencies.required = opts.dependencies

  if self:CheckDependencies() then
    echo(f"All dependencies are installed.\n")
    self:FinishDependencyInstall()
    return true
  end

  -- Add all the dependencies to the missing table
  echo(f"Adding dependencies to the missing table.\n")
  for _, dependency in ipairs(self.dependencies.required) do
    if not table.contains(getPackages(), dependency.name) then
      table.insert(self.dependencies.missing, dependency)
    end
  end

  -- Start the install timer
  if table.size(self.dependencies.missing) > 0 then
    echo(f"Starting the install timer.\n")
    self:EnableTimer("install", function()
      echo(f"Installing missing dependencies.\n")
      self:InstallMissingDependencies()
    end)
    tempTimer(0.01, function()
      display(getNamedTimers(self.config.name))
    end)
    return false
  end

  return true
end

---@param timer string
---@param func function
function Dependent:EnableTimer(timer, func)
  display(self.timers)
  display(timer)
  local timer_label = self.timers[timer]

  echo(f"Enabling timer: {timer_label}\n")

  local ok, err
  if not timer_label then return end
  if not table.index_of(getNamedTimers(self.config.name), timer_label) then
    echo(f"Registering timer: {timer_label}\n")
    ok, err = registerNamedTimer(self.config.name, timer_label, 1, func, false)
  else
    echo(f"Resuming timer: {timer_label}\n")
    ok, err = resumeNamedTimer(self.config.name, timer_label)
  end

  display(ok, err)
  display(self.config.name)
  display(getNamedTimers(self.config.name))
  echo(f"Timer enabled: {table.index_of(getNamedTimers(self.config.name), timer_label)}\n")
  display(getNamedTimers(self.config.name))
end

function Dependent:EnableEventHandler(event, func)
  local event_label = self.event_handlers[event]
  if not table.index_of(getNamedEventHandlers(self.config.name), event_label) then
    registerNamedEventHandler(self.config.name, event_label, event, func, true)
  else
    resumeNamedEventHandler(self.config.name, event_label)
  end
end

-- This function checks if all the required dependencies are installed.
-- It returns true if all dependencies are installed, otherwise it returns
-- false.
---@return boolean
function Dependent:CheckDependencies()
  for _, dependency in ipairs(self.dependencies.required) do
    if not table.contains(getPackages(), dependency.name) then
      return false
    end
  end

  return true
end

-- This function is responsible for installing missing dependencies. It checks
-- if there are any missing dependencies, and if so, it installs the first one
-- in the list. It also starts or resumes a timer to check if the dependency
-- has been installed successfully, and an event handler to listen for the
-- installation event.
function Dependent:InstallMissingDependencies()
  echo(f"Installing missing dependencies: {table.size(self.dependencies.missing)}\n")
  if table.size(self.dependencies.missing) == 0 then
    self:FinishDependencyInstall()
    return
  end

  local dependency = self.dependencies.missing[1]
  cecho(f"<chartreuse>{self.config.name}: Installing dependency: {dependency.name}\n")

  -- Install the next dependency
  installPackage(dependency.url)

  -- Start or resume the check timer for the next dependency
  self:EnableTimer("check", function() self:CheckDependencyInstalled() end)

  -- Start or resume the event handler for the next dependency
  self:EnableEventHandler("sysInstall", function(...) self:DependencyInstalled(...) end)
end

-- This function checks if the first missing dependency has been installed
-- successfully. It stops the check timer and the event handler for
-- installation, then verifies if the package is now available. If installed,
-- it moves the package to the installed list; otherwise, it moves it to the
-- list of dependencies still missing.
-- Finally, it resumes the timer for installing the next dependency.
function Dependent:CheckDependencyInstalled()
  -- Stop the check timer
  stopNamedTimer(self.config.name, self.timers.check)
  -- Resume the event handler
  stopNamedEventHandler(self.config.name, self.event_handlers.sysInstall)

  local dependency = self.dependencies.missing[1]
  if not dependency then return end

  local package = dependency.name
  if table.contains(getPackages(), package) then
    cecho(f"<chartreuse>{self.config.name}: Installed dependency: {package}\n")
    table.remove(self.dependencies.missing, 1)
    table.insert(self.dependencies.installed, package)
  else
    cecho(f"<orange_red>{self.config.name}: Unable to install dependency: {package}\n")
    table.remove(self.dependencies.missing, 1)
    table.insert(self.dependencies.still_missing, package)
  end

  -- Resume the install timer
  resumeNamedTimer(self.config.name, self.timers.install)
end

-- This function is called when a dependency is installed. It checks if the
-- installed package matches the first missing dependency. If it does, it calls
-- the function to check if the dependency is now installed, which might
-- seem redundant, but it ensures that the dependency is installed and
-- cleans up the dependencies table, and continues the install process.
function Dependent:DependencyInstalled(event, package)
  local dependency = self.dependencies.missing[1]
  if not dependency or package ~= dependency.name then return end

  self:CheckDependencyInstalled()
end

function Dependent:DownloadPackage()
  local dependency = self.dependencies.missing[1]
  if not dependency then return end

  installPackage(dependency.url)
end

function Dependent:Running()
  local timers = getNamedTimers(self.config.name)
  local handlers = getNamedEventHandlers(self.config.name)

  local running = (#timers > 0 or #handlers > 0) and true or false

  display("Running: " .. tostring(running))
  return running
end

function Dependent:CleanUp()
  -- Stop the event handlers
  deleteAllNamedEventHandlers(self.config.name)
  -- Stop the timers
  deleteAllNamedTimers(self.config.name)

  -- Reset the dependencies table
  self.dependencies = reset

  self.handler_prefix = nil
  self.event_handlers = {}
  self.timers = {}
end

-- This function is responsible for finalizing the dependency installation
-- process. It stops all event handlers and timers related to the installation,
-- checks if all dependencies have been successfully installed, and raises an
-- event accordingly.
-- If all dependencies are installed, it raises a "DependentCompleted" event;
-- otherwise, it raises a "DependentFailed" event. Finally, it resets the
-- dependencies table.
function Dependent:FinishDependencyInstall()
  if self:CheckDependencies() then
    raiseEvent(
      "DependentCompleted",
      self.dependencies.source_script,
      table.deepcopy(self.dependencies)
    )
  else
    raiseEvent(
      "DependentFailed",
      self.dependencies.source_script,
      table.deepcopy(self.dependencies)
    )
  end

  self:CleanUp()
end

-- This function checks if a given table is an array, meaning it has only
-- integer keys starting from 1 and incrementing by 1 for each element.
---@param t table
---@return boolean
function is_array(t)
  -- Ensure it's a table
  if type(t) ~= "table" then
    return false
  end

  -- Check for only integer keys
  local i = 0
  for k, _ in pairs(t) do
    i = i + 1
    if type(k) ~= "number" or k ~= i then
      return false
    end
  end
  return true
end

-- This function checks if a given table is an associative array, meaning it
-- has at least one non-integer key.
---@param t table
---@return boolean
function is_associative_array(t)
  -- Ensure it's a table
  if type(t) ~= "table" then
    return false
  end

  -- Check for non-integer keys
  for k, _ in pairs(t) do
    if type(k) ~= "number" or math.floor(k) ~= k then
      return true
    end
  end
  return false
end

local system_name = Dependent.config.name .. ":System"
local handler_name

handler_name = "Dependent:Install"
registerNamedEventHandler(
  system_name,
  handler_name,
  "sysInstall",
  function(...) Dependent:CleanUp() end,
  true
)

handler_name = "Dependent:Load"
registerNamedEventHandler(
  system_name,
  handler_name,
  "sysLoadEvent",
  function(...) Dependent:CleanUp() end,
  false
)

handler_name = "Dependent:Uninstall"
registerNamedEventHandler(
  system_name,
  handler_name,
  "sysUninstall",
  function(...) Dependent:CleanUp() end,
  true
)
