###
  == ATOM-TERMINAL-PANEL  FILE-MANIP PLUGIN ==

  Atom-terminal-panel builtin plugin v1.0.0
  -isis97

  Contains commands for file system manipulation.

  MIT License
  Feel free to do anything with this file.
###
module.exports =
  "@":
    "description": "Access native environment variables."
    "command": (state, args)->
      return state.parseTemplate "%(env."+args[0]+")"

  "cp":
    "params": "[file]... [destination]"
    "description": "Copies one/or more files to the specified directory (e.g cp ./test.js ./test/)"
    "command": (state, args)->
      srcs = args[..-2]
      tgt = args[-1..]
      try
        return (state.util.cp srcs, tgt) + ' files copied.'
      catch e
        state.consoleAlert 'Failed to copy the given entries '+e

  "mkdir":
    "params": "[name]..."
    "description": "Create one/or more directories."
    "params": "[FOLDER NAME]"
    "command": (state, args) ->
      try
        return state.util.mkdir args
      catch e
        state.consoleAlert 'Failed to create directory '+e

  "rmdir":
    "params": "[directory]..."
    "description": "Remove one/or more directories."
    "command": (state, args) ->
      try
        return state.util.rmdir args
      catch e
        state.consoleAlert 'Failed to remove directory '+e

  "rename":
    "params": "[name] [new name]"
    "description": "Rename the given file/directory."
    "command": (state, args) ->
      try
        return state.util.rename args[0], args[1]
      catch e
        state.consoleAlert 'Failed to rename file /or directory '+e
