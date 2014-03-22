{View, EditorView} = require 'atom'
{spawn} = require 'child_process'
ansihtml = require 'ansi-html-stream'
readline = require 'readline'
{addClass, removeClass} = require 'domutil'

lastOpenedView = null

module.exports =
class CommandOutputView extends View

  @content: ->
    @div tabIndex: -1, class: 'panel cli-status panel-bottom', =>
      @div class: 'panel-heading', =>
        @div class: 'btn-group', =>
          @button outlet: 'killBtn', click: 'kill', class: 'btn hide', =>
            # @span class: "icon icon-x"
            @span 'kill'
          @button click: 'destroy', class: 'btn', =>
            # @span class: "icon icon-x"
            @span 'destroy'
          @button click: 'close', class: 'btn', =>
            @span class: "icon icon-x"
            @span 'close'
      @div class: 'cli-panel-body', =>
        @pre class: "terminal", outlet: "cliOutput",
          "Welcome to terminal status. http://github.com/guileen/terminal-status"
        @subview 'cmdEditor', new EditorView(mini: true, placeholderText: 'input your command here')

  initialize: ->
    atom.workspaceView.command "cli-status:toggle-output", =>
      @toggle()

    @on "core:confirm", =>
      inputCmd = @cmdEditor.getEditor().getText()
      htmlStream = ansihtml()
      @cmdEditor.hide()
      @cliOutput.append "\n$>#{inputCmd}\n"
      showCmd = =>
        @cmdEditor.show()
        @cmdEditor.getEditor().selectAll()
        @cmdEditor.focus()
        @scrollToBottom()

      htmlStream.on 'data', (data) =>
        @cliOutput.append data
        @scrollToBottom()
      args = []
      # support 'a b c' and "foo bar"
      inputCmd.replace /("[^"]*"|'[^']*'|[^\s'"]+)/g, (s) ->
        args.push s
      cmd = args.shift()
      try
        @program = spawn cmd, args, stdio: 'pipe', env: process.env, cwd: atom.project.path
        @program.stdout.pipe htmlStream
        @program.stderr.pipe htmlStream
        removeClass @statusIcon, 'status-success'
        removeClass @statusIcon, 'status-error'
        addClass @statusIcon, 'status-running'
        @killBtn.removeClass 'hide'
        @program.once 'exit', (code) =>
          @killBtn.addClass 'hide'
          removeClass @statusIcon, 'status-running'
          @program = null
          addClass @statusIcon, code == 0 and 'status-success' or 'status-error'
          showCmd()
        @program.on 'error', (err) =>
          @cliOutput.append err.message
          showCmd()
          addClass @statusIcon, 'status-error'
        @program.stdout.on 'data', () =>
          @flashIconClass 'status-info'
          removeClass @statusIcon, 'status-error'
        @program.stderr.on 'data', () =>
          addClass @statusIcon, 'status-error'

      catch err
        @cliOutput.append err.message
        showCmd()

  scrollToBottom: ->
    @cliOutput.scrollTop 10000000

  flashIconClass: (className, time=100)=>
    addClass @statusIcon, className
    @timer and clearTimeout(@timer)
    onStatusOut = =>
      removeClass @statusIcon, className
    @timer = setTimeout onStatusOut, time

  destroy: ->
    _destroy = =>
      if @hasParent()
        @close()
      if @statusIcon and @statusIcon.parentNode
        @statusIcon.parentNode.removeChild(@statusIcon)
      @statusView.removeCommandView this
    if @program
      @program.once 'exit', _destroy
      @program.kill()
    else
      _destory()

  kill: ->
    if @program
      @program.kill()

  open: ->
    atom.workspaceView.prependToBottom(this) unless @hasParent()
    if lastOpenedView and lastOpenedView != this
      lastOpenedView.close()
    lastOpenedView = this
    @scrollToBottom()
    @statusView.setActiveCommandView this
    @cmdEditor.focus()

  close: ->
    @detach()
    lastOpenedView = null

  toggle: ->
    if @hasParent()
      @close()
    else
      @open()
