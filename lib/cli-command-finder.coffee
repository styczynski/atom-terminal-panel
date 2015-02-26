{SelectListView, $$} = require 'atom-space-pen-views'

module.exports =
class ExampleSelectListView extends SelectListView
  @thisPanel: null
  @thisCaller: null

  initialize: (@listOfItems) ->
    super
    @setItems @listOfItems


  viewForItem: (item) ->
    icon_style = ''
    descr_prefix = ''
    if item.source == 'external'
      icon_style = 'added'
      descr_prefix = 'External: '
    else if item.source == 'internal'
      icon_style = 'modified'
      descr_prefix = 'Builtin: '
    else if item.source == 'internal-atom'
      icon_style = 'removed'
      descr_prefix = 'Atom command: '
    else if item.source == 'external-functional'
      icon_style = 'renamed'
      descr_prefix = 'Functional: '
    else if item.source == 'global-variable'
      icon_style = 'ignored'
      descr_prefix = 'Global variable: '

    $$ ->
      @li class: 'two-lines selected', =>
        @div class: "status status-#{icon_style} icon icon-diff-#{icon_style}"
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
