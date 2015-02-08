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

    #atom.tooltips.add li,
    #title: 'Umpa umpa umpa.'
    # return li



  shown: (panel, caller) ->
    @thisPanel = panel
    @thisCaller = caller

  close: (item) ->
    if @thisPanel?
      try
        @thisPanel.destroy()
      catch e
        return
    if @thisCaller?
      if not @getFilterQuery()?
        if item?
          @thisCaller.onCommand item.name
      else
        if @getFilterQuery() != ''
          @thisCaller.onCommand @getFilterQuery()
        else if item?
          @thisCaller.onCommand item.name

  cancel: ->
    @close null

  confirmed: (item) ->
    @close item

  getFilterKey: ->
    return "name"
