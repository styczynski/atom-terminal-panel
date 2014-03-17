{View} = require 'atom'
CommandOutputView = require './command-output-view'

module.exports =
class CliStatusView extends View
  @content: ->
    @div class: 'cli-status inline-block', =>
      @span outlet: 'cliStatus', click: 'click', class: "cli-status icon icon-terminal"

  initialize: (serializeState) ->
    # atom.workspaceView.command "cli-status:toggle", => @toggle()
    @commandOutputView = new CommandOutputView
    @attach()

  attach: ->
    atom.workspaceView.statusBar.appendLeft(this)
  # Returns an object that can be retrieved when package is activated
  # serialize: ->

  # Tear down any state and detach
  destroy: ->
    @detach()

  click: ->
    @commandOutputView.toggle()

  toggle: ->
    if @hasParent()
      @detach()
    else
      atom.workspaceView.append(this)
