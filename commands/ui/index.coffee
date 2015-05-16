vm = require 'vm'
os = require 'os'

###
  == ATOM-TERMINAL-PANEL  UI PLUGIN ==

  Atom-terminal-panel builtin plugin v1.0.0
  -isis97

  Contains commands for creating user interface components
  (e.g. bars etc.)

  MIT License
  Feel free to do anything with this file.
###
module.exports =
  "ui-clock":
    "description": "Displays the dynamic clock."
    "command": (state) ->
      state.exec "echo %(raw) %(dynamic) %(^#FF851B) %(hours12):%(minutes):%(seconds) %(ampm) %(^)", [], state
  "ui-mem":
    "description": "Displays the dynamic memory usage information"
    "command": (state) ->
      state.exec "echo %(raw) %(dynamic) %(^#FF851B) Free memory/available memory: %(os.freemem)B / %(os.totalmem)B %(^)", [], state
