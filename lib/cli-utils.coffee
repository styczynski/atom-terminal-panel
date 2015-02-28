

window.include = (name) ->
  if not window.cliUtilsIncludeLog?
    window.cliUtilsIncludeLog = []
  r = null
  try
    r = require name
  catch e
    if name in window.cliUtilsIncludeLog
      return r
    else
      window.cliUtilsIncludeLog.push name
    try
      setTimeout () =>
        atom.notifications.addError "atom-terminal-panel: Dependency error. Module ["+name+"] cannot be required."
      , 1500
    catch e2
    throw e
    throw "Dependency error. Module ["+name+"] cannot be required."
  return r
