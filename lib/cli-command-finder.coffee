{SelectListView, $$} = require 'atom-space-pen-views'

module.exports =
class ExampleSelectListView extends SelectListView
  @thisPanel: null
  @thisCaller: null

  initialize: (@listOfItems) ->
    super
    @setItems @listOfItems

  viewForItem: (item) ->
    $$ ->
      @li class: 'two-lines selected', =>
        @div class: 'primary-line', =>
          @span item.name
        @div class: 'secondary-line', =>
          @span item.description

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
