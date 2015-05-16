###
  Atom-terminal-panel
  Copyright by isis97
  MIT licensed

  'Command finder' view, which lists all available commands and variables.
###

{SelectListView, $$} = include 'atom-space-pen-views'

module.exports =
class ATPCommandFinderView extends SelectListView
  @thisPanel: null
  @thisCaller: null

  initialize: (@listOfItems) ->
    super
    @setItems @listOfItems


  viewForItem: (item) ->
    icon_style = ''
    descr_prefix = ''
    if item.source == 'external'
      icon_style = 'book'
      descr_prefix = 'External: '
    else if item.source == 'internal'
      icon_style = 'repo'
      descr_prefix = 'Builtin: '
    else if item.source == 'internal-atom'
      icon_style = 'repo'
      descr_prefix = 'Atom command: '
    else if item.source == 'external-functional'
      icon_style = 'plus'
      descr_prefix = 'Functional: '
    else if item.source == 'global-variable'
      icon_style = 'briefcase'
      descr_prefix = 'Global variable: '

    $$ ->
      @li class: 'two-lines selected', =>
        @div class: "status status-#{icon_style} icon icon-#{icon_style}"
        @div class: 'primary-line', =>
          @span item.name
        @div class: 'secondary-line', =>
          @span descr_prefix + item.description



  shown: (panel, caller) ->
    @thisPanel = panel
    @thisCaller = caller

  close: (item) ->

    if @thisPanel?
      try
        @thisPanel.destroy()
      catch e
    if item?
      @thisCaller.onCommand item.name

  cancel: ->
    @close null

  confirmed: (item) ->
    @close item

  getFilterKey: ->
    return "name"
