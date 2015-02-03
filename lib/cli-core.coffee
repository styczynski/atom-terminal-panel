
{resolve, dirname, extname} = require 'path'
fs = require 'fs'

class CliCore

  state:
    config: {}
    statePath: null
    opened: false
    customCommands: {}
    defaultCommands:
      "hello_world": [
        "echo Hello world :D",
        "echo %(*)",
        "echo is",
        "echo example usage",
        "echo of the console"
      ]

  createDefaultCommandsFile: () ->
    if atom.config.get('terminal-panel.enableUserCommands')
      try
        content = JSON.stringify {commands: @state.defaultCommands}
        fs.writeFileSync @state.statePath, content
      catch e
        console.log 'cli-core cannot create default terminal commands JSON file', e.message

  reload: () ->
    @state.opended = false
    @init()

  init: () ->
    if not @state.opended
      @state.opened = true
      @state.statePath = dirname(atom.config.getUserConfigPath()) + '/terminal-commands.json'
      try
        @state.config = JSON.parse fs.readFileSync @state.statePath
      catch e
        @state.opened = no
      if not @state.opened
        @createDefaultCommandsFile()
        @state.opened = true
        @state.customCommands = @state.defaultCommands
      else
        @state.customCommands = @state.config.commands
    return this

  jsonCssToInlineStyle: (obj) ->
    if obj instanceof String
      return obj
    ret = ''
    for key, value of obj
      if key? and value?
        ret += key + ':' + value + ';'
    return ret

  getConfig: () ->
    return @state.config

  getUserCommands: () ->
    if atom.config.get('terminal-panel.enableUserCommands')
      return @state.customCommands
    return null

  findUserCommandAction: (cmd) ->
    if not atom.config.get('terminal-panel.enableUserCommands')
      return null
    for name, code of @state.customCommands
      if name == cmd
        return code
    return null

  findUserCommand: (cmd) ->
    if not atom.config.get('terminal-panel.enableUserCommands')
      return null
    action = @findUserCommandAction(cmd)
    if not action?
      return null
    return (state, args) ->
      return state.execDelayedCommand 1, action, args, state

module.exports = new CliCore().init()
