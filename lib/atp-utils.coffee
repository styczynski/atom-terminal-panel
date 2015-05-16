###
  Atom-terminal-panel
  Copyright by isis97
  MIT licensed

  This file contains basic, simple utilities used by coffeescript files.
###

if not global?
  throw "apt-utils: No global node.js namespace present."

global.include = (name) ->
  if not window.cliUtilsIncludeLog?
    window.cliUtilsIncludeLog = []
  if not name?
    setTimeout () =>
      atom.notifications.addError "atom-terminal-panel: Dependency error. Module with null-value name cannot be required."
    , 500
    return
  if (name.indexOf 'atp-') == 0
    name = './'+name

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
      , 500
    catch e2
    throw e
    throw "Dependency error. Module ["+name+"] cannot be required."
  return r


global.generateRandomID = () ->
  length = 32
  chars = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
  result = ''
  for i in [length...1] by -1
    result += chars[Math.round(Math.random() * (chars.length - 1))]
  return result
