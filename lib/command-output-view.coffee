{View, EditorView} = require 'atom'
{spawn} = require 'child_process'
ansihtml = require 'ansi-html-stream'
readline = require 'readline'
{addClass, removeClass} = require 'domutil'
{resolve} = require 'path'
fs = require 'fs'

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
    @cwd = atom.project.path
    atom.workspaceView.command "cli-status:toggle-output", =>
      @toggle()

    @on "core:confirm", =>
      inputCmd = @cmdEditor.getEditor().getText()
      @cliOutput.append "\n$>#{inputCmd}\n"
      args = []
      # support 'a b c' and "foo bar"
      inputCmd.replace /("[^"]*"|'[^']*'|[^\s'"]+)/g, (s) ->
        args.push s
      cmd = args.shift()
      if cmd == 'cd'
        return @cd args
      if cmd == 'ls'
        return @ls args
      @spawn cmd, args


  showCmd: ->
    @cmdEditor.show()
    @cmdEditor.getEditor().selectAll()
    @cmdEditor.focus()
    @scrollToBottom()

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
      _destroy()

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

  cd: (args)->
    dir = resolve @cwd, args[0]
    fs.stat dir, (err, stat) =>
      if err
        if err.code == 'ENOENT'
          return @message "cd: #{args[0]}: No such file or directory"
        return @message err.message
      if not stat.isDirectory()
        return @message "cd: not a directory: #{args[0]}"
      @cwd = dir
      @message "cwd: #{@cwd}"

  ls: (args)->
    files = fs.readdirSync @cwd
    filesBlocks = []
    files.forEach (filename) =>
      filesBlocks.push @_fileInfoHtml(filename, @cwd)
    @message filesBlocks.join('')

  _fileInfoHtml: (filename, parent)->
    classes = ['icon', 'file-info']
    filepath = parent + '/' + filename
    stat = fs.lstatSync filepath
    if stat.isFile()
      if stat.mode & 73 #0111
        classes.push 'stat-program'
      # TODO check extension
      classes.push 'icon-file-text'
    if stat.isDirectory()
      classes.push 'icon-file-directory'
    if stat.isSymbolicLink()
      classes.push 'icon-file-symlink-file'
      classes.push 'stat-link'
    if stat.isCharacterDevice()
      classes.push 'stat-char-dev'
    if stat.isFIFO()
      classes.push 'stat-fifo'
    if stat.isSocket()
      classes.push 'stat-sock'
    if filename[0] == '.'
      classes.push 'status-ignored'
    # if statusName = @getGitStatusName filepath
    #   classes.push statusName
    # other stat info
    "<span class=\"#{classes.join ' '}\">#{filename}</span>"

  getGitStatusName: (path, gitRoot, repo) ->
    status = (repo.getCachedPathStatus or repo.getPathStatus)(path)
    console.log 'path status', path, status
    if status
      if repo.isStatusModified status
        return 'modified'
      if repo.isStatusNew status
        return 'added'
    if repo.isPathIgnore path
      return 'ignored'

  message: (message) ->
      @cliOutput.append message
      @showCmd()

  spawn: (cmd, args) ->
    @cmdEditor.hide()
    htmlStream = ansihtml()
    htmlStream.on 'data', (data) =>
      @cliOutput.append data
      @scrollToBottom()
    try
      @program = spawn cmd, args, stdio: 'pipe', env: process.env, cwd: @cwd
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
        @showCmd()
      @program.on 'error', (err) =>
        @cliOutput.append err.message
        @showCmd()
        addClass @statusIcon, 'status-error'
      @program.stdout.on 'data', () =>
        @flashIconClass 'status-info'
        removeClass @statusIcon, 'status-error'
      @program.stderr.on 'data', () =>
        addClass @statusIcon, 'status-error'

    catch err
      @cliOutput.append err.message
      @showCmd()
