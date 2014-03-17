{View} = require 'atom'
CommandOutputView = require './command-output-view'

module.exports =
class CliStatusView extends View
  @content: ->
    @div class: 'cli-status inline-block', =>
      @span outlet: 'cliStatus', click: 'click', class: "cli-status icon icon-terminal"

  initialize: (serializeState) ->
    # atom.workspaceView.command "cli-status:toggle", => @toggle()
    console.log 'view init'
    @commandOutputView = new CommandOutputView
    @attach()

  attach: ->
    console.log 'attaching'
    atom.workspaceView.statusBar.appendLeft(this)
  # Returns an object that can be retrieved when package is activated
  # serialize: ->

  # Tear down any state and detach
  destroy: ->
    @detach()

  click: ->
    console.log 'click'
    @commandOutputView.toggle()

  toggle: ->
    console.log "CliStatusView was toggled!"
    if @hasParent()
      @detach()
    else
      atom.workspaceView.append(this)
