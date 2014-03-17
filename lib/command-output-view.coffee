{View, EditorView} = require 'atom'
{spawn} = require 'child_process'
ansihtml = require 'ansi-html-stream'

module.exports =
class CommandOutputView extends View

  @content: ->
    @div tabIndex: -1, class: 'cli-status tool-panel panel-bottom padded', =>
      @pre class: "terminal", outlet: "cliOutput",
        "Welcome to terminal status. http://github.com/guileen/terminal-status"
      @div class: 'editor-container', =>
        @subview 'cmdEditor', new EditorView(mini: true, placeholderText: 'input your command here')

  initialize: ->
    @cliOutput.css('font-size', "#{atom.config.getInt('editor.fontSize')}px")
    atom.workspaceView.command "cli-status:toggle-output", =>
      @toggle()

    @on "core:confirm", =>
      inputCmd = @cmdEditor.getEditor().getText()
      htmlStream = ansihtml()
      panel = @cliOutput.parent()
      @cmdEditor.hide()
      @cliOutput.append "\n$>#{inputCmd}\n"
      showCmd = =>
        @cmdEditor.show()
        @cmdEditor.getEditor().selectAll()
        @cmdEditor.focus()
        panel.scrollTop(10000000)

      htmlStream.on 'data', (data) =>
        # @cliOutput.innerHTML += data
        # el.innerHTML += data
        @cliOutput.append data
        panel.scrollTop(10000000)
      args = []
      # support 'a b c' and "foo bar"
      inputCmd.replace /("[^"]*"|'[^']*'|[^\s'"]+)/g, (s) ->
        args.push s
      cmd = args.shift()
      try
        program = spawn cmd, args, stdio: 'pipe', env: process.env, cwd: atom.project.path
        program.stdout.pipe htmlStream
        program.stderr.pipe htmlStream
        program.once 'exit', (code) =>
          showCmd()
        program.on 'error', (err) =>
          @cliOutput.append err.message
          showCmd()
      catch err
        @cliOutput.append err.message
        showCmd()

  toggle: ->
    if @hasParent()
      @detach()
    else
      atom.workspaceView.prependToBottom(this) unless @hasParent()
      @cliOutput.parent().scrollTop(10000000)
      @cmdEditor.focus()
