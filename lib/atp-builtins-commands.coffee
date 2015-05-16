###
  Atom-terminal-panel
  Copyright by isis97
  MIT licensed

  Class containing all builtin commands.
###

core = include 'atp-core'

module.exports =
  "encode":
    "params": "[encoding standard]"
    "deprecated": true
    "description": "Change encoding."
    "command": (state, args)->
      encoding = args[0]
      state.streamsEncoding = encoding
      state.message 'Changed encoding to '+encoding
      return null
  "ls":
    "description": "Lists files in the current directory."
    "command": (state, args)->
      state.commandLineNotCounted()
      if not state.ls args
        return 'The directory is inaccessible.'
        return null
  "clear":
    "description": "Clears the console output."
    "command": (state, args)->
      state.commandLineNotCounted()
      state.clear()
      return null
  "echo":
    "params": "[text]..."
    "description": "Prints the message to the output."
    "command": (state, args)->
      if args?
        state.message args.join(' ') + '\n'
        return null
      else
        state.message '\n'
        return null
  "print":
    "params": "[text]..."
    "description": "Stringifies given parameters."
    "command": (state, args)-> return JSON.stringify(args)
  "cd":
    "params": "[directory]"
    "description": "Moves to the specified directory."
    "command": (state, args)-> state.cd args
  "new":
    "description": "Creates a new file and opens it in the editor view."
    "command": (state, args)->
      if args == null || args == undefined
        atom.workspaceView.trigger 'application:new-file'
        return null
      file_name = state.util.replaceAll '\"', '', args[0]
      if file_name == null || file_name == undefined
        atom.workspaceView.trigger 'application:new-file'
        return null
      else
        file_path = state.resolvePath file_name
        fs.closeSync(fs.openSync(file_path, 'w'))
        state.delay () ->
          atom.workspaceView.open file_path
        return state.consoleLink file_path
  "rm":
    "params": "[file]"
    "description": "Removes the given file."
    "command": (state, args)->
      filepath = state.resolvePath args[0]
      fs.unlink filepath, (e) -> return
      return state.consoleLink filepath
  "memdump":
    "description": "Displays a list of all available internally stored commands."
    "command": (state, args)-> return state.getLocalCommandsMemdump()
  "?":
    "description": "Displays a list of all available internally stored commands."
    "command": (state, args)->
      return state.exec 'memdump', null, state
  "exit":
    "description": "Destroys the terminal session."
    "command": (state, args)->
      state.destroy()
  "update":
    "description": "Reloads the terminal configuration from terminal-commands.json"
    "command": (state, args)->
      core.reload()
      return (state.consoleLabel 'info', 'info') + (state.consoleText 'info', 'The console settings were reloaded')
  "reload":
    "description": "Reloads the atom window."
    "command": (state, args)->
      atom.reload()
  "edit":
    "params": "[file]"
    "description": "Opens the specified file in the editor view."
    "command": (state, args)->
      file_name = state.resolvePath args[0]
      state.delay () ->
        atom.workspaceView.open (file_name)
      return state.consoleLink file_name
  "link":
    "params": "[file/directory]"
    "description": "Displays interactive link to the given file/directory."
    "command": (state, args)->
      file_name = state.resolvePath args[0]
      return state.consoleLink file_name
  "l":
    "params": "[file/directory]"
    "description": "Displays interactive link to the given file/directory."
    "command": (state, args)->
      return state.exec 'link '+args[0], null, state
  "info":
    "description": "Prints the welcome message to the screen."
    "command": (state, args)->
      state.clear()
      state.showInitMessage true
      return null
