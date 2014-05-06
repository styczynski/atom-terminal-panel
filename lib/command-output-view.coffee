{View, EditorView} = require 'atom'
{spawn, exec} = require 'child_process'
ansihtml = require 'ansi-html-stream'
readline = require 'readline'
{addClass, removeClass} = require 'domutil'
{resolve} = require 'path'
fs = require 'fs'

lastOpenedView = null

module.exports =
class CommandOutputView extends View
  cwd: null
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
    @subscribe atom.config.observe 'terminal-status.WindowHeight', => @adjustWindowHeight()

    @userHome = process.env.HOME or process.env.HOMEPATH or process.env.USERPROFILE;
    cmd = 'test -e /etc/profile && source /etc/profile;test -e ~/.profile && source ~/.profile; node -pe "JSON.stringify(process.env)"'
    exec cmd, (code, stdout, stderr) ->
      process.env = JSON.parse(stdout)
    atom.workspaceView.command "cli-status:toggle-output", =>
      @toggle()

    @on "core:confirm", =>
      inputCmd = @cmdEditor.getEditor().getText()
      @cliOutput.append "\n$>#{inputCmd}\n"
      @scrollToBottom()
      args = []
      # support 'a b c' and "foo bar"
      inputCmd.replace /("[^"]*"|'[^']*'|[^\s'"]+)/g, (s) =>
        if s[0] != '"' and s[0] != "'"
          s = s.replace /~/g, @userHome
        args.push s
      cmd = args.shift()
      if cmd == 'cd'
        return @cd args
      if cmd == 'ls'
        return @ls args
      @spawn inputCmd, cmd, args


  adjustWindowHeight: ->
    maxHeight = atom.config.get('terminal-status.WindowHeight')
    @cliOutput.css("max-height", "#{maxHeight}px")

  showCmd: ->
    @cmdEditor.show()
    @cmdEditor.getEditor().selectAll()
    @cmdEditor.focus()
    @scrollToBottom()

  scrollToBottom: ->
    @cliOutput.scrollTop 10000000

  flashIconClass: (className, time=100)=>
    console.log 'addClass', className
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
    @lastLocation = atom.workspace.getActivePane()
    atom.workspaceView.prependToBottom(this) unless @hasParent()
    if lastOpenedView and lastOpenedView != this
      lastOpenedView.close()
    lastOpenedView = this
    @scrollToBottom()
    @statusView.setActiveCommandView this
    @cmdEditor.focus()

  close: ->
    @lastLocation.activate()
    @detach()
    lastOpenedView = null

  toggle: ->
    if @hasParent()
      @close()
    else
      @open()

  cd: (args)->
    dir = resolve @getCwd(), args[0]
    fs.stat dir, (err, stat) =>
      if err
        if err.code == 'ENOENT'
          return @errorMessage "cd: #{args[0]}: No such file or directory"
        return @errorMessage err.message
      if not stat.isDirectory()
        return @errorMessage "cd: not a directory: #{args[0]}"
      @cwd = dir
      @message "cwd: #{@cwd}"

  ls: (args)->
    files = fs.readdirSync @getCwd()
    filesBlocks = []
    files.forEach (filename) =>
      filesBlocks.push @_fileInfoHtml(filename, @getCwd())
    filesBlocks = filesBlocks.sort (a, b)->
      aDir = a[1].isDirectory()
      bDir = b[1].isDirectory()
      if aDir and not bDir
        return -1
      if not aDir and bDir
        return 1
      a[2] > b[2] and 1 or -1
    filesBlocks = filesBlocks.map (b) ->
      b[0]
    @message filesBlocks.join('') + '<div class="clear"/>'

  _fileInfoHtml: (filename, parent)->
    classes = ['icon', 'file-info']
    filepath = parent + '/' + filename
    stat = fs.lstatSync filepath
    if stat.isSymbolicLink()
      # classes.push 'icon-file-symlink-file'
      classes.push 'stat-link'
      stat = fs.statSync filepath
    if stat.isFile()
      if stat.mode & 73 #0111
        classes.push 'stat-program'
      # TODO check extension
      classes.push 'icon-file-text'
    if stat.isDirectory()
      classes.push 'icon-file-directory'
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
    ["<span class=\"#{classes.join ' '}\">#{filename}</span>", stat, filename]

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
    removeClass @statusIcon, 'status-error'
    addClass @statusIcon, 'status-success'

  errorMessage: (message) ->
    @cliOutput.append message
    @showCmd()
    removeClass @statusIcon, 'status-success'
    addClass @statusIcon, 'status-error'

  getCwd: ()->
    @cwd or atom.project.path or @userHome

  spawn: (inputCmd, cmd, args) ->
    @cmdEditor.hide()
    htmlStream = ansihtml()
    htmlStream.on 'data', (data) =>
      @cliOutput.append data
      @scrollToBottom()
    try
      # @program = spawn cmd, args, stdio: 'pipe', env: process.env, cwd: @getCwd()
      @program = exec inputCmd, stdio: 'pipe', env: process.env, cwd: @getCwd()
      @program.stdout.pipe htmlStream
      @program.stderr.pipe htmlStream
      removeClass @statusIcon, 'status-success'
      removeClass @statusIcon, 'status-error'
      addClass @statusIcon, 'status-running'
      @killBtn.removeClass 'hide'
      @program.once 'exit', (code) =>
        console.log 'exit', code
        @killBtn.addClass 'hide'
        removeClass @statusIcon, 'status-running'
        # removeClass @statusIcon, 'status-error'
        @program = null
        addClass @statusIcon, code == 0 and 'status-success' or 'status-error'
        @showCmd()
      @program.on 'error', (err) =>
        console.log 'error'
        @cliOutput.append err.message
        @showCmd()
        addClass @statusIcon, 'status-error'
      @program.stdout.on 'data', () =>
        @flashIconClass 'status-info'
        removeClass @statusIcon, 'status-error'
      @program.stderr.on 'data', () =>
        console.log 'stderr'
        @flashIconClass 'status-error', 300

    catch err
      @cliOutput.append err.message
      @showCmd()
