{View} = require 'atom'
domify = require 'domify'
CommandOutputView = require './command-output-view'

module.exports =
class CliStatusView extends View
  @content: ->
    @div class: 'cli-status inline-block', =>
      @span outlet: 'termStatusContainer', =>
      @span click: 'newTermClick', class: "cli-status icon icon-plus"

  commandViews: []
  activeIndex: 0
  initialize: (serializeState) ->
    atom.workspaceView.command 'terminal-status:new', => @newTermClick()
    atom.workspaceView.command 'terminal-status:toggle', => @toggle()
    atom.workspaceView.command 'terminal-status:next', => @activeNextCommandView()
    atom.workspaceView.command 'terminal-status:prev', => @activePrevCommandView()
    @createCommandView()
    @attach()

  createCommandView: ()->
    termStatus = domify '<span class="cli-status icon icon-terminal"></span>'
    commandOutputView = new CommandOutputView
    commandOutputView.statusIcon = termStatus
    commandOutputView.statusView = this
    @commandViews.push commandOutputView
    termStatus.addEventListener 'click', () =>
      commandOutputView.toggle()
    @termStatusContainer.append termStatus
    return commandOutputView

  activeNextCommandView: ()->
    @activeCommandView @activeIndex + 1

  activePrevCommandView: ()->
    @activeCommandView @activeIndex - 1

  activeCommandView: (index) ->
    if index >= @commandViews.length
      index = 0
    if index < 0
      index = @commandViews.length - 1
    @commandViews[index] and @commandViews[index].open()

  setActiveCommandView: (commandView) ->
    @activeIndex = @commandViews.indexOf commandView

  removeCommandView: (commandView) ->
    index = @commandViews.indexOf commandView
    index >=0 and @commandViews.splice index, 1

  newTermClick: ()->
    @createCommandView().toggle()

  attach: ->
    atom.workspaceView.statusBar.appendLeft(this)
  # Returns an object that can be retrieved when package is activated
  # serialize: ->

  # Tear down any state and detach
  destroy: ->
    for index in [@commandViews.length .. 0]
      @removeCommandView @commandViews[index]
    @detach()

  toggle: ->
    @commandViews[@activeIndex] and @commandViews[@activeIndex].toggle()
