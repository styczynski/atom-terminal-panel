CliStatusView = require './cli-status-view'

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

  deactivate: ->
    @cliStatusView.destroy()

  # serialize: ->
  #   cliStatusViewState: @cliStatusView.serialize()

  config:
    'WindowHeight':
      type: 'integer'
      default: 300
    'enableWindowAnimations':
      title: 'Enable window animations'
      type: 'boolean'
      default: true
    'clearCommandInput':
      type: 'boolean'
      default: true
    'logConsole':
      type: 'boolean'
      default: false
    'overrideLs':
      title: 'Override ls'
      type: 'boolean'
      default: true
    'enableExtendedCommands':
      title: 'Enable extended built-in commands'
      type: 'boolean'
      default: true
    'enableUserCommands':
      title: 'Enable user defined commands from terminal-commands.json file'
      type: 'boolean'
      default: true
    'enableConsoleInteractiveLinks':
      title: 'Enable console interactive links'
      type: 'boolean'
      default: true
    'enableConsoleInteractiveHints':
      title: 'Enable console interactive hints'
      type: 'boolean'
      default: true
    'enableConsoleLabels':
      title: 'Enable console labels (like %(label:info...), error, warning)'
      type: 'boolean'
      default: true
    'enableConsoleStartupInfo':
      title: 'Enable the console welcome message.'
      type: 'boolean'
      default: true
    'disabledExtendedCommands':
      title: 'Disabled commands:'
      type: 'array'
      default: []
      items:
        type: 'string'
    'moveToCurrentDirOnOpen':
      title: 'Always move to currently selected file\'s directory when the console is opened.'
      type: 'boolean'
      default: false
    'parseSpecialTemplateTokens':
      title: 'Enable the special tokens (like: %(path), %(day) etc.)'
      type: 'boolean'
      default: true
    'commandPrompt':
      title: 'The command prompt message.'
      type: 'string'
      default: '$> %command%'
    'textReplacementCurrentPath':
      title: 'Replacement for the current working directory path at the console output.'
      type: 'string'
      default: ''
    'textReplacementCurrentFile':
      title: 'Replacement for the currently edited file at the console output.'
      type: 'string'
      default: ''
    'textReplacementFileAdress':
      title: 'Replacement for any file adress at the console output.'
      type: 'string'
      default: ''
