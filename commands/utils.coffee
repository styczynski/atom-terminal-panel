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
