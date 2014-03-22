{View} = require 'atom'
domify = require 'domify'
CommandOutputView = require './command-output-view'

module.exports =
class CliStatusView extends View
  @content: ->
    @div class: 'cli-status inline-block', =>
      @span outlet: 'termStatusContainer', =>
      @span click: 'newTermClick', class: "cli-status icon icon-plus"

  initialize: (serializeState) ->
    @createTermStatus()
    @attach()

  createTermStatus: ()->
    termStatus = domify '<span class="cli-status icon icon-terminal"></span>'
    commandOutputView = new CommandOutputView
    commandOutputView.statusIcon = termStatus
    termStatus.addEventListener 'click', () =>
      commandOutputView.toggle()
    @termStatusContainer.append termStatus
    return commandOutputView

  newTermClick: ()->
    @createTermStatus().toggle()

  attach: ->
    atom.workspaceView.statusBar.appendLeft(this)
  # Returns an object that can be retrieved when package is activated
  # serialize: ->

  # Tear down any state and detach
  destroy: ->
    # FIXME kill all opened programs
    @detach()

  toggle: ->
    if @hasParent()
      @detach()
    else
      atom.workspaceView.append(this)
