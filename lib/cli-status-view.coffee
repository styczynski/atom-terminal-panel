###
  Atom-terminal-panel
  Copyright by isis97
  MIT licensed

  The panel, which manages all the terminal instances.
###

require './cli-utils'

{View} = include 'atom-space-pen-views'
domify = include 'domify'
CommandOutputView = include './command-output-view'

module.exports =
class CliStatusView extends View
  @content: ->
    @div class: 'cli-status inline-block', =>
      @span outlet: 'termStatusContainer', =>
        @span click: 'newTermClick', class: "cli-status icon icon-plus"

  commandViews: []
  activeIndex: 0
  initialize: (serializeState) ->
    atom.commands.add 'atom-workspace',
      'atom-terminal-panel:new': => @newTermClick()
      'atom-terminal-panel:toggle': => @toggle()
      'atom-terminal-panel:next': => @activeNextCommandView()
      'atom-terminal-panel:prev': => @activePrevCommandView()
      'atom-terminal-panel:destroy': => @destroyActiveTerm()
      'atom-terminal-panel:compile': => @getForcedActiveCommandView().compile()

    @createCommandView()
    @attach()

  createCommandView: ->
    termStatus = domify '<span class="cli-status icon icon-terminal"></span>'
    commandOutputView = new CommandOutputView
    commandOutputView.statusIcon = termStatus
    commandOutputView.statusView = this
    @commandViews.push commandOutputView
    termStatus.addEventListener 'click', ->
      commandOutputView.toggle()
    @termStatusContainer.append termStatus
    commandOutputView.init()
    return commandOutputView

  activeNextCommandView: ->
    @activeCommandView @activeIndex + 1

  activePrevCommandView: ->
    @activeCommandView @activeIndex - 1

  activeCommandView: (index) ->
    if index >= @commandViews.length
      index = 0
    if index < 0
      index = @commandViews.length - 1
    @commandViews[index] and @commandViews[index].open()

  getActiveCommandView: () ->
    return @commandViews[@activeIndex]

  getForcedActiveCommandView: () ->
    if @getActiveCommandView() != null && @getActiveCommandView() != undefined
      return @getActiveCommandView()
    ret = @activeCommandView(0)
    @toggle()
    return ret

  setActiveCommandView: (commandView) ->
    @activeIndex = @commandViews.indexOf commandView

  removeCommandView: (commandView) ->
    index = @commandViews.indexOf commandView
    index >=0 and @commandViews.splice index, 1

  newTermClick: ->
    @createCommandView().toggle()

  attach: ->
    document.querySelector("status-bar").addLeftTile(item: this, priority: 100)

  destroyActiveTerm: ->
     @commandViews[@activeIndex]?.destroy()

  # Tear down any state and detach
  destroy: ->
    for index in [@commandViews.length .. 0]
      @removeCommandView @commandViews[index]
    @detach()

  toggle: ->
    @createCommandView() unless @commandViews[@activeIndex]?
    @commandViews[@activeIndex].toggle()
