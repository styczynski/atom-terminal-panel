vm = require 'vm'

###
  == ATOM-TERMINAL-PANEL  UTILS PLUGIN ==

  Atom-terminal-panel builtin plugin v1.0.0
  -isis97

  Contains commands for easier console usage.

  MIT License
  Feel free to do anything with this file.
###
module.exports =
  "settings":
    "description": "Shows the ATOM settings."
    "command": (state, args)->
      state.exec 'application:show-settings', args, state
  "eval":
    "description": "Evaluates any javascript code."
    "params": "[CODE]"
    "command": (state, args)->
      (vm.runInThisContext args[0])
      return null
  "web":
    "description": "Shows any web page."
    "params": "[ADDRESS]"
    "command": (state, args)->
      address = args.join(' ')
      state.message "<iframe style='height:3000%;width:90%;' src='http://www.#{address}'></iframe>"
      return null
  "web-atom":
    "description": "Shows any web page."
    "params": "[ADDRESS]"
    "command": (state, args)->
      query = args.join(' ')
      state.message "<iframe style='height:3000%;width:90%;' src='https://atom.io/packages/search?q=#{query}'></iframe>"
      return null
