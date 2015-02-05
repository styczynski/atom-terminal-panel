CliStatusView = require './cli-status-view'

core = require './cli-core'
module.exports =
  cliStatusView: null

  activate: (state) ->
    # core.init()
    createStatusEntry = =>
      @cliStatusView = new CliStatusView(state.cliStatusViewState)

    if atom.views.getView(atom.workspace).statusBar
      createStatusEntry()
    else
      atom.packages.once 'activated', ->
        createStatusEntry()
    setTimeout ()->
      core.init()
    , 250

  deactivate: ->
    @cliStatusView.destroy()

  # serialize: ->
  #   cliStatusViewState: @cliStatusView.serialize()

  config:
    'WindowHeight':
      type: 'integer'
      description: 'Maximum height of a console window.'
      default: 300
    'enableWindowAnimations':
      title: 'Enable window animations'
      description: 'Enable window animations.'
      type: 'boolean'
      default: true
    'clearCommandInput':
      title: 'Clear command input'
      description: 'Always clear command input when opening terminal panel.'
      type: 'boolean'
      default: true
    'logConsole':
      title: 'Log console'
      description: 'Log console output.'
      type: 'boolean'
      default: false
    'overrideLs':
      title: 'Override ls'
      description: 'Override ls command (if this option is disabled the native version of ls is used)'
      type: 'boolean'
      default: true
    'enableExtendedCommands':
      title: 'Enable extended built-in commands'
      description: 'Enable extended built-in commands (like ls override, cd or echo).'
      type: 'boolean'
      default: true
    'enableUserCommands':
      title: 'Enable user commands'
      description: 'Enable user defined commands from terminal-commands.json file'
      type: 'boolean'
      default: true
    'enableConsoleInteractiveLinks':
      title: 'Enable console interactive links'
      description: 'If this option is disabled or terminal links are not clickable (the file extensions will be coloured only)'
      type: 'boolean'
      default: true
    'enableConsoleInteractiveHints':
      title: 'Enable console interactive hints'
      description: 'Enable terminal tooltips.'
      type: 'boolean'
      default: true
    'enableConsoleLabels':
      title: 'Enable console labels (like %(label:info...), error, warning)'
      description: 'If this option is disabled all labels are removed.'
      type: 'boolean'
      default: true
    'enableConsoleStartupInfo':
      title: 'Enable the console welcome message.'
      description: 'Always display welcome message when the terminal window is opened.'
      type: 'boolean'
      default: true
    'disabledExtendedCommands':
      title: 'Disabled commands:'
      description: 'You can disable any command (it will be used as native).'
      type: 'array'
      default: []
      items:
        type: 'string'
    'moveToCurrentDirOnOpen':
      title: 'Always move to current directory'
      description: 'Always move to currently selected file\'s directory when the console is opened (slows down terminal a little).'
      type: 'boolean'
      default: false
    'parseSpecialTemplateTokens':
      title: 'Enable the special tokens (like: %(path), %(day) etc.)'
      description: 'If this option is disabled all special tokens are removed.'
      type: 'boolean'
      default: true
    'commandPrompt':
      title: 'The command prompt message.'
      description: 'Set the command prompt message.'
      type: 'string'
      default: '%(label:badge:text:%(line)) %(hours):%(minutes) $.../%(path:-2)/%(path:-1)>'
    'textReplacementCurrentPath':
      title: 'Current working directory replacement'
      description: 'Replacement for the current working directory path at the console output.'
      type: 'string'
      default: '[CWD]'
    'textReplacementCurrentFile':
      title: 'Currently edited file replacement'
      description: 'Replacement for the currently edited file at the console output.'
      type: 'string'
      default: '%(link:%(file))'
    'textReplacementFileAdress':
      title: 'File adress replacement'
      description: 'Replacement for any file adress at the console output.'
      type: 'string'
      default: '%(link:%(file))'
