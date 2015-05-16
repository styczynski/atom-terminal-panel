vm = require 'vm'
os = require 'os'

###
  == ATOM-TERMINAL-PANEL  UTILS PLUGIN ==

  Atom-terminal-panel builtin plugin v1.0.0
  -isis97

  Contains commands for easier console usage.

  MIT License
  Feel free to do anything with this file.
###
module.exports =
  "tmpdir":
    "description": "Describes current machine."
    "variable": (state) -> os.tmpdir()
  "whoami":
    "description": "Describes the current machine."
    "variable": (state) -> os.hostname() + ' [' + os.platform() + ' ; ' + os.type() + ' ' + os.release() + ' (' + os.arch() + ' x' + os.cpus().length + ')' + '] ' + (process.env.USERNAME or process.env.LOGNAME or process.env.USER)
  "os.hostname":
    "description": "Returns the hostname of the operating system."
    "variable": (state) -> os.hostname()
  "os.type":
    "description": "Returns the operating system name."
    "variable": (state) -> os.type()
  "os.platform":
    "description": "Returns the operating system platform."
    "variable": (state) -> os.platform()
  "os.arch":
    "description": 'Returns the operating system CPU architecture. Possible values are "x64", "arm" and "ia32".'
    "variable": (state) -> os.arch()
  "os.release":
    "description": "Returns the operating system release."
    "variable": (state) -> os.release()
  "os.uptime":
    "description": "Returns the system uptime in seconds."
    "variable": (state) -> os.uptime()
  "os.totalmem":
    "description": "Returns the total amount of system memory in bytes."
    "variable": (state) -> os.totalmem()
  "os.freemem":
    "description": "Returns the amount of free system memory in bytes."
    "variable": (state) -> os.freemem()
  "os.cpus":
    "description": "Returns the node.js JSON-format information about CPUs characteristics."
    "variable": (state) -> JSON.stringify(os.cpus())
  "terminal":
    "description" : "Shows the native terminal in the current location."
    "command": (state, args)->
      o = state.util.os()
      if o.windows
        state.exec 'start cmd.exe', args, state
      else
        state.message '%(label:error:Error) The "terminal" command is currently not supported on platforms other than windows.'

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
