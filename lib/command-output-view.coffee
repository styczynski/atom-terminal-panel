
{TextEditorView, View} = require 'atom-space-pen-views'
{spawn, exec} = require 'child_process'
ansihtml = require 'ansi-html-stream'
readline = require 'readline'
{addClass, removeClass} = require 'domutil'
{resolve, dirname, extname} = require 'path'
fs = require 'fs'
window.$ = require('atom').$
lastOpenedView = null

core = require './cli-core'

module.exports =
class CommandOutputView extends View
  cwd: null
  _cmdintdel: 50
  echoOn: true
  inputLine: 50
  helloMessageShown: false
  minHeight: 250

  @content: ->
    @div tabIndex: -1, class: 'panel cli-status panel-bottom', =>
      @div class: 'panel-heading', =>
        @div class: 'btn-group', =>
          @button outlet: 'killBtn', click: 'kill', class: 'btn hide', =>
            @span 'kill'
          @button click: 'moveToCurrentDirectory', class: 'btn', =>
            @span 'current directory'
          @button click: 'compile', class: 'btn', =>
            @span 'compile'
          @button click: 'run', class: 'btn', =>
              @span 'run'
          @button click: 'clear', class: 'btn', =>
            @span 'clear'
          @button click: 'destroy', class: 'btn', =>
            @span 'destroy'
          @button click: 'close', class: 'btn', =>
            @span class: "icon icon-x"
            @span 'close'
      @div class: 'cli-panel-body', =>
        # @progress outlet: 'cliProgressBar', max: '100', value: '0', style: 'width: 100%'
        # @div class: 'progress-bar progress-bar-striped active', role: 'progressbar', style: 'width: 45%', 'aria-valuenow':'45', 'aria-valuemin':'0', 'aria-valuemax':'100'
        @pre class: "terminal", outlet: "cliOutput"
        @subview 'cmdEditor', new TextEditorView(mini: true, placeholderText: 'input your command here')

  localCommands:
    "ls": (state, args)->
      state.commandLineNotCounted()
      if not state.ls args
        return 'The directory is inaccessible.'
      return null
    "clear": (state, args)->
      state.commandLineNotCounted()
      state.clear()
      return null
    "echo": (state, args)->
      if args?
        state.message args.join(' ') + '\n'
      state.message '\n'
      return null
    "print": (state, args)-> return JSON.stringify(args)
    "cd": (state, args)-> state.cd args
    "new": (state, args) ->
      if args == null || args == undefined
        atom.workspaceView.trigger 'application:new-file'
        return null
      file_name = args[0]
      if file_name == null || file_name == undefined
        atom.workspaceView.trigger 'application:new-file'
        return null
      else
        file_path = state.getCwd() + '/' + file_name
        state.rawMessage 'path := ' + file_path + '\n'
        fs.closeSync(fs.openSync(file_path, 'w'))
        state.delay () ->
          atom.workspaceView.open file_path
        return state.consoleLink file_path
    "rm": (state, args) ->
      filename = args[0]
      filepath = state.getCwd() + '/' + filename
      fs.unlinkSync(filepath)
      return state.consoleLink(filepath)
    "memdump": (state, args) ->
      return state.getLocalCommandsMemdump()
    "?": (state, args) ->
      return state.exec 'memdump', null, state
    "exit": (state, args) ->
      state.destroy()
    "update": (state, args) ->
      core.reload()
      return 'The console settings were reloaded.'
    "reload": (state, args) ->
      atom.reload()
    "edit": (state, args) ->
      file_name = args[0]
      state.delay () ->
        atom.workspaceView.open (state.getCwd() + '/' + file_name)
      return state.consoleLink(file_name)
    "link": (state, args) ->
      file_name = args[0]
      return state.consoleLink(file_name)
    "l": (state, args) ->
      return state.exec 'link', args, state

  init: () ->
    obj = require '../config/functional-commands-external'
    for key, value of obj
      @localCommands[key] = value
    return this

  commandLineNotCounted: () ->
    @inputLine--

  parseSpecialStringTemplate: (prompt, values) ->
    cmd = null
    file = @getCurrentFilePath()
    if values?
      if values.cmd?
        cmd = values.cmd
      if values.file?
        file = values.file

    if not atom.config.get('atom-terminal-panel.parseSpecialTemplateTokens')
      return prompt.replace /%\([^ ]*\)/ig, ''

    for key, value of values
      if key != 'cmd' and key != 'file'
        prompt = @replaceAll "%(#{key})", value, prompt

    prompt = @replaceAll '%(path)', @getCwd(), prompt
    prompt = @replaceAll '%(file)', file, prompt
    prompt = @replaceAll '%(cwd)', @getCwd(), prompt

    if cmd?
      prompt = @replaceAll '%(command)', cmd, prompt
    today = new Date()
    day = today.getDate()
    month = today.getMonth()+1
    year = today.getFullYear()
    minutes = today.getMinutes()
    hours = today.getHours()
    milis = today.getMilliseconds()
    if day < 10
      day = '0' + day
    if month < 10
      month = '0' + month
    if milis < 10
      milis = '000' + milis
    else if milis < 100
      milis = '00' + milis
    else if milis < 1000
      milis = '0' + milis
    if minutes < 10
      minutes = '0' + minutes
    if hours < 10
      hours = '0' + hours
    prompt = @replaceAll '%(day)', day, prompt
    prompt = @replaceAll '%(month)', month, prompt
    prompt = @replaceAll '%(year)', year, prompt
    prompt = @replaceAll '%(hours)', hours, prompt
    prompt = @replaceAll '%(minutes)', minutes, prompt
    prompt = @replaceAll '%(milis)', milis, prompt
    prompt = @replaceAll '%(line)', @inputLine+1, prompt

    pathBreadcrumbs = @getCwd().split /\\|\//ig
    pathBreadcrumbs[0] = pathBreadcrumbs[0].charAt(0).toUpperCase() + pathBreadcrumbs[0].slice(1)
    disc = @replaceAll ':', '', pathBreadcrumbs[0]
    prompt = @replaceAll '%(disc)', disc, prompt

    pathBreadcrumbsSize = pathBreadcrumbs.length - 1
    for i in [0..pathBreadcrumbsSize] by 1
      breadcrumbIdFwd = i-pathBreadcrumbsSize-1
      breadcrumbIdRwd = i
      prompt = @replaceAll "%(path:#{breadcrumbIdFwd})", pathBreadcrumbs[i], prompt
      prompt = @replaceAll "%(path:#{breadcrumbIdRwd})", pathBreadcrumbs[i], prompt

    prompt = prompt.replace /%\(tooltip:[^\n\t\[\]{}%\)\(]*\)/ig, (match, text, urlId) =>
      target = @replaceAll '%(tooltip:', '', match
      target = target.substring 0, target.length-1
      target_tokens = target.split ':content:'
      target = target_tokens[0]
      content = target_tokens[1]
      return "<font data-toggle=\"tooltip\" data-placement=\"top\" title=\"#{target}\">#{content}</font>"

    prompt = prompt.replace /%\(link:[^\n\t\[\]{}%\)\(]*\)/ig, (match, text, urlId) =>
      target = @replaceAll '%(link:', '', match
      target = target.substring 0, target.length-1
      # target = @replaceAll '..', ':', target
      # @replaceAll @getCwd(), '%(cwd-original)', @consoleLink target
      ret = @consoleLink target
      return ret

    if atom.config.get 'atom-terminal-panel.enableConsoleLabels'
      prompt = prompt.replace /%\(label:[^\n\t\[\]{}%\)\(]*\)/ig, (match, text, urlId) =>
        target = @replaceAll '%(label:', '', match
        target = target.substring 0, target.length-1
        target_tokens = target.split ':text:'
        target = target_tokens[0]
        content = target_tokens[1]
        return @consoleLabel target, content
    else
      prompt = prompt.replace /%\(label:[^\n\t\[\]{}%\)\(]*\)/ig, (match, text, urlId) =>
        target = @replaceAll '%(label:', '', match
        target = target.substring 0, target.length-1
        target_tokens = target.split ':text:'
        target = target_tokens[0]
        content = target_tokens[1]
        return content

    prompt = @replaceAll @getCurrentFilePath(), '%(file-original)', prompt
    prompt = @replaceAll @getCwd(), '%(cwd-original)', prompt
    prompt = @replaceAll @getCwd(), '%(cwd-original)', prompt

    return prompt

  getCommandPrompt: (cmd) ->
    return @parseSpecialStringTemplate atom.config.get('atom-terminal-panel.commandPrompt'), {cmd: cmd}

  delay: (callback, delay=100) ->
    setTimeout callback, delay

  execDelayedCommand: (delay, cmd, args, state) ->
    caller = this
    callback = ->
      caller.exec cmd, args, state
    setTimeout callback, delay

  moveToCurrentDirectory: ()->
    filepath = @getCurrentFileLocation()
    CURRENT_LOCATION = @getCurrentFileLocation()
    if CURRENT_LOCATION?
      @cd [CURRENT_LOCATION]
      @clear()
      @execDelayedCommand @_cmdintdel, 'ls', null, this

  getCurrentFileName: ()->
    current_file = @getCurrentFilePath()
    if current_file != null
      matcher = /(.*:)((.*)\\)*/ig
      return current_file.replace matcher, ""
    return null

  getCurrentFileLocation: ()->
    if @getCurrentFilePath() == null
      return null
    # return @getCurrentFilePath()
    return  @replaceAll(@getCurrentFileName(), "", @getCurrentFilePath())

  getCurrentFilePath: ()->
    editor = atom.workspace.getActivePaneItem()
    if editor == null || editor == undefined
      return null
    if editor?.buffer == undefined
      return null
    file = editor?.buffer.file
    if file == null || file == undefined
      return null
    return file?.path

  parseTemplate: (text, vars) ->
    ret = @parseSpecialStringTemplate text, vars
    ret = @replaceAll '%(file-original)', @getCurrentFilePath(), ret
    ret = @replaceAll '%(cwd-original)', @getCwd(), ret
    return ret

  parseExecToken__: (cmd, args, strArgs) ->
    cmd = @parseTemplate cmd, {file:@getCurrentFilePath()}
    if strArgs?
      cmd = @replaceAll "%(*)", strArgs, cmd
    cmd = @replaceAll "%(^)", (@replaceAll "%(^)", "", cmd), cmd
    if args?
      argsNum = args.length
      for i in [0..argsNum] by 1
        if args[i]?
          v = args[i].replace /\n/ig, ''
          cmd = @replaceAll "%(#{i})", args[i], cmd
      for i in [argsNum+1..100] by 1
        cmd = @replaceAll "%(#{i})", '', cmd
    return cmd


  exec: (cmdStr, ref_args, state) ->
    # @rawMessage "Call cmd={#{cmdStr}}; ref_args={#{ref_args}};\n"

    if cmdStr instanceof Array
      ret = ''
      for com in cmdStr
        # com = @parseExecToken__ com, ref_args, ref_args.join(' ')
        val = @exec com, ref_args, state
        if val?
          ret += val
      if not ret?
        return null
      return ret
    else
      ref_args_str = null
      if ref_args?
        ref_args_str = ref_args.join(' ')
      cmdStr = @parseExecToken__ cmdStr, ref_args, ref_args_str

      args = []
      cmd = cmdStr
      cmd.replace /("[^"]*"|'[^']*'|[^\s'"]+)/g, (s) =>
        if s[0] != '"' and s[0] != "'"
          s = s.replace /~/g, @userHome
        args.push s
      cmd = args.shift()
      command = core.findUserCommand(cmd)
      if command?
        if not state?
          ret = null
          throw 'The console functional (not native) command cannot be executed without caller information: \''+cmd+'\'.'
        if command?
          ret = command(state, args)
        if not ret?
          return null
        return ret
      else
        command = @getLocalCommand(cmd)
        if command?
          ret = command(state, args)
          if not ret?
            return null
          return ret
        else
          @spawn cmdStr, cmd, args
          if not cmd?
            return null
          return 'call '+cmd

  compile: () ->
    @clear()
    @exec('compile', null, this)

  run: () ->
    @exec('run', null, this)

  clear: () ->
    @inputLine = 0
    @cliOutput.empty()
    @message '\n'
    return @cmdEditor.setText ''

  isCommandEnabled: (name) ->
    disabledCommands = atom.config.get('atom-terminal-panel.disabledExtendedCommands')
    if name in disabledCommands
      return false
    return true

  getLocalCommand: (name) ->
    for cmd_name, cmd_body of @localCommands
      if cmd_name == name
        return cmd_body
    return null

  getLocalCommandsMemdump: () ->
    ret = []
    for cmd_name, cmd_body of @localCommands
      ret.push cmd_name
    for cmd_name, cmd_body of core.getUserCommands()
      ret.push cmd_name
    retString = '[\n\t'
    retSize = ret.length-1
    for i in [0..retSize] by 1
      if i != retSize
        retString += ret[i] + ', '
      else
        retString += ret[i]
    retString += '\n]'
    return retString

  commandProgress: (value) ->
    @rawMessage 'progress := '+value+'\n'
    #if value >= 100
    #  value = -1
    if value < 0
      # @cliProgressBar.fadeOut 500
      @cliProgressBar.hide()
      @cliProgressBar.attr('value', '0')
    else
      @cliProgressBar.show()
      # @cliProgressBar.fadeIn 500
      @cliProgressBar.attr('value', value/2)

  showInitMessage: () ->
    if @helloMessageShown
      return
    if atom.config.get 'atom-terminal-panel.enableConsoleStartupInfo'
      hello_message = @consolePanel 'ATOM Terminal', 'Please enter new commands to the box below.<br>The console supports special anotattion like: %(path), %(file), %(link:file.something).<br>It also supports special HTML elements like: %(tooltip:A:content:B) and so on.<br>Hope you\'ll enjoy the terminal.'
      @rawMessage hello_message
      @helloMessageShown = true
    return this

  initialize: ->

    @userHome = process.env.HOME or process.env.HOMEPATH or process.env.USERPROFILE
    cmd = 'test -e /etc/profile && source /etc/profile;test -e ~/.profile && source ~/.profile; node -pe "JSON.stringify(process.env)"'
    exec cmd, (code, stdout, stderr) ->
      try
        process.env = JSON.parse(stdout)
      catch e
    atom.commands.add 'atom-workspace',
      "cli-status:toggle-output": => @toggle()

    @on "core:confirm", =>
      @cmdEditor.addClass 'readonly'
      @inputLine++
      inputCmd = @cmdEditor.getModel().getText()
      inputCmd = @parseSpecialStringTemplate inputCmd

      if @echoOn
        @message ("\n"+@getCommandPrompt(inputCmd)+"\n")
      @scrollToBottom()

      ###
      args = []
      # support 'a b c' and "foo bar"
      inputCmd.replace /("[^"]*"|'[^']*'|[^\s'"]+)/g, (s) =>
        if s[0] != '"' and s[0] != "'"
          s = s.replace /~/g, @userHome
        args.push s
      cmd = args.shift()
      if atom.config.get('atom-terminal-panel.enableExtendedCommands')
        if @isCommandEnabled(cmd)
          action = null
          if core.findUserCommand(cmd) != null
            action = core.findUserCommand(cmd)
          else
            if @getLocalCommand(cmd) != null
              action = @getLocalCommand(cmd)
          if action?
            if @echoOn
              result = action(this, args)
              if result?
                @message result + '\n'
            @cmdEditor.removeClass 'readonly'
            return @cmdEditor.setText ''

        # @commandProgress -1
      # if cmd == 'cd'
      #  return @cd args
      # if cmd == 'ls' and atom.config.get('atom-terminal-panel.overrideLs')
      #  return @ls args
      # if cmd == 'clear'
      #  return @clear()
      ret = @spawn inputCmd, cmd, args
      @cmdEditor.removeClass 'readonly'
      return ret
      ###


      ret = @exec inputCmd, null, this
      @cmdEditor.setText ''
      @cmdEditor.removeClass 'readonly'
      if ret?
        @message ret + '\n'
      return null

  clear: ->
    @cliOutput.empty()
    @message '\n'
    return @cmdEditor.setText ''

  adjustWindowHeight: ->
    maxHeight = atom.config.get('atom-terminal-panel.WindowHeight')
    @cliOutput.css("max-height", "#{maxHeight}px")

  showCmd: ->
    @cmdEditor.show()
    @cmdEditor.getModel().selectAll()
    @cmdEditor.setText('') if atom.config.get('atom-terminal-panel.clearCommandInput')
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
    if disabledCommands = atom.config.get('atom-terminal-panel.moveToCurrentDirOnOpen')
      @moveToCurrentDirectory()
    @lastLocation = atom.workspace.getActivePane()
    atom.workspace.addBottomPanel(item: this) unless @hasParent()
    if lastOpenedView and lastOpenedView != this
      lastOpenedView.close()
    lastOpenedView = this
    @scrollToBottom()
    @statusView.setActiveCommandView this
    @cmdEditor.focus()
    @showInitMessage()

    if atom.config.get 'atom-terminal-panel.enableWindowAnimations'
      @WindowMinHeight = @cliOutput.height() + @cmdEditor.height() + 50
      @height 0
      @animate {
        height: @WindowMinHeight
      }, 250, =>
        @attr 'style', ''


  close: ->
    if atom.config.get 'atom-terminal-panel.enableWindowAnimations'
      @WindowMinHeight = @cliOutput.height() + @cmdEditor.height() + 50
      @height @WindowMinHeight
      @animate {
        height: 0
      }, 250, =>
        @attr 'style', ''
        @lastLocation.activate()
        @detach()
        lastOpenedView = null
    else
      @lastLocation.activate()
      @detach()
      lastOpenedView = null


  toggle: ->
    if @hasParent()
      @close()
    else
      @open()

  removeQuotes: (text)->
    if text instanceof Array
      ret = []
      for t in text
        ret.push (@removeQuotes t)
      return ret
    return text.replace(/['"]+/g, '')

  cd: (args)->
    args = [atom.project.path] if not args[0]
    args = @removeQuotes args
    dir = resolve @getCwd(), args[0]
    fs.stat dir, (err, stat) =>
      if err
        if err.code == 'ENOENT'
          return @errorMessage "cd: #{args[0]}: No such file or directory"
        return @errorMessage err.message
      if not stat.isDirectory()
        return @errorMessage "cd: not a directory: #{args[0]}"
      @cwd = dir
      # @message "cwd: #{@cwd}"

  ls: (args) ->
    try
      files = fs.readdirSync @getCwd()
    catch e
      return false
    filesBlocks = []
    files.forEach (filename) =>
      filesBlocks.push @_fileInfoHtml(filename, @getCwd())
    filesBlocks = filesBlocks.sort (a, b) ->
      aDir = false
      bDir = false
      if a[1]?
        aDir = a[1].isDirectory()
      if b[1]?
        bDir = b[1].isDirectory()
      if aDir and not bDir
        return -1
      if not aDir and bDir
        return 1
      a[2] > b[2] and 1 or -1
    filesBlocks.unshift @_fileInfoHtml('..', @getCwd())
    filesBlocks = filesBlocks.map (b) ->
      b[0]
    @message filesBlocks.join('') + '<div class="clear"/>'
    return true
    # @parseSpecialNodes()

  parseSpecialNodes: () ->
    caller = this

    if atom.config.get 'atom-terminal-panel.enableConsoleInteractiveHints'
      $('.cli-tooltip[data-toggle="tooltip"]').tooltip()

    if atom.config.get 'atom-terminal-panel.enableConsoleInteractiveLinks'
      @find('.console-link').each (
        () ->
          el = $(this)
          link_target = el.data('target')

          if link_target != null && link_target != undefined
            el.data('target', null)
            link_type = el.data('targettype')
            link_target_name = el.data('targetname')
            link_target_line = el.data('line')
            link_target_column = el.data('column')

            if not link_target_line?
              link_target_line = 0
            if not link_target_column?
              link_target_column = 0

            el.click () ->
              el.addClass('link-used')
              if link_type == 'file'
                atom.workspaceView.open link_target, {
                  initialLine: link_target_line
                  initialColumn: link_target_column
                }

              if link_type == 'directory'
                  moveToDir = (directory, messageDisp=false)->
                    caller.clear()
                    caller.cd([directory])
                    setTimeout () ->
                      if not caller.ls()
                        if not messageDisp
                          caller.errorMessage 'The directory is inaccesible.\n'
                          messageDisp = true
                          setTimeout () ->
                            moveToDir('..', messageDisp)
                          , 1500
                    , caller._cmdintdel
                  setTimeout () ->
                    moveToDir(link_target_name)
                  , caller._cmdintdel
      )
      # el.data('filenameLink', '')

  consoleAlert: (text) ->
    return '<div class="alert alert-danger alert-dismissible" role="alert"><button type="button" class="close" data-dismiss="alert" aria-label="Close"><span aria-hidden="true">&times;</span></button><strong>Warning!</strong> ' + text + '</div>'

  consolePanel: (title, content) ->
    return '<div class="panel panel-info"><div class="panel-heading">'+title+'</div><div class="panel-body">'+content+'</div></div><br><br>'

  consoleLabel: (type, text) ->
    if not atom.config.get 'atom-terminal-panel.enableConsoleLabels'
      return text

    if not text?
      text = type

    if type == 'badge'
      return '<span class="badge">'+text+'</span>'
    if type == 'default'
      return '<span class="label label-default">'+text+'</span>'
    if type == 'primary'
      return '<span class="label label-primary">'+text+'</span>'
    if type == 'success'
      return '<span class="label label-success">'+text+'</span>'
    if type == 'info'
      return '<span class="label label-info">'+text+'</span>'
    if type == 'warning'
      return '<span class="label label-warning">'+text+'</span>'
    if type == 'danger'
      return '<span class="label label-danger">'+text+'</span>'
    if type == 'error'
      return '<span class="label label-danger">'+text+'</span>'
    return '<span class="label label-default">'+text+'</span>'

  consoleLink: (name) ->
    return @_fileInfoHtml(name, @getCwd(), 'font', false)[0]

  _fileInfoHtml: (filename, parent, wrapper_class='span', use_file_info_class='true') ->
    str = filename
    name_tokens = filename
    filename = filename.replace /:[0-9]+:[0-9]/ig, ''
    name_tokens = @replaceAll filename, '', name_tokens
    name_tokens = name_tokens.split ':'
    fileline = name_tokens[0]
    filecolumn = name_tokens[1]
    # @rawMessage "str:=#{str}; file:=#{filename}; line:=#{fileline}; column:=#{filecolumn};\n"

    filename = @replaceAll '/', '\\', filename
    filename = @replaceAll parent, '', filename
    filename = @replaceAll (@replaceAll '/', '\\', parent), '', filename

    if filename[0] == '\\' or filename[0] == '/'
      filename = filename.substring(1)

    if filename == '..'
      if use_file_info_class
        return ["<font class=\"file-extension\"><#{wrapper_class} data-targetname=\"#{filename}\" data-targettype=\"directory\" data-target=\"#{filename}\" class=\"console-link icon-file-directory parent-folder\">#{filename}</#{wrapper_class}></font>", null, filename]
      else
          return ["<font class=\"file-extension\"><#{wrapper_class} data-targetname=\"#{filename}\" data-targettype=\"directory\" data-target=\"#{filename}\" class=\"console-link icon-file-directory file-info parent-folder\">#{filename}</#{wrapper_class}></font>", null, filename]

    file_exists = true

    classes = ['icon']
    if use_file_info_class
      classes.push 'file-info'
    filepath = parent + '/' + filename
    #try
    #  fs.open filepath, 'r+', (err, fd) ->
    #    file_exists = false
    #catch e
    #  file_exists = false

    stat = null
    if file_exists
      try
        stat = fs.lstatSync filepath
      catch e
        file_exists = false

    if file_exists
      if atom.config.get('atom-terminal-panel.enableConsoleInteractiveLinks')
        classes.push 'console-link'
      if stat.isSymbolicLink()
        # classes.push 'icon-file-symlink-file'
        classes.push 'stat-link'
        stat = fs.statSync filepath
        target_type = 'null'
      if stat.isFile()
        if stat.mode & 73 #0111
          classes.push 'stat-program'
        # TODO check extension
        matcher = /(.:)((.*)\\)*((.*\.)*)/ig
        extension = filepath.replace matcher, ""
        classes.push @replaceAll(' ', '', extension)
        classes.push 'icon-file-text'
        target_type = 'file'
      if stat.isDirectory()
        classes.push 'icon-file-directory'
        target_type = 'directory'
      if stat.isCharacterDevice()
        classes.push 'stat-char-dev'
        target_type = 'device'
      if stat.isFIFO()
        classes.push 'stat-fifo'
        target_type = 'fifo'
      if stat.isSocket()
        classes.push 'stat-sock'
        target_type = 'sock'
    else
      classes.push 'file-not-found'
      classes.push 'icon-file-text'
      target_type = 'file'
    if filename[0] == '.'
      classes.push 'status-ignored'
      target_type = 'ignored'
    # if statusName = @getGitStatusName filepath
    #   classes.push statusName
    # other stat info
    # onclick=\'openLink(\"#{filepath}\");\'

    href = 'file:///' + @replaceAll('\\', '/', filepath)

    classes.push 'cli-tooltip'

    exattrs = []
    if fileline?
      exattrs.push 'data-line="'+fileline+'"'
    if filecolumn?
      exattrs.push 'data-column="'+filecolumn+'"'

    ["<font class=\"file-extension\"><#{wrapper_class} #{exattrs.join ' '} tooltip=\"\" data-targetname=\"#{filename}\" data-targettype=\"#{target_type}\" data-target=\"#{filepath}\" class=\"#{classes.join ' '}\" data-toggle=\"tooltip\" data-placement=\"top\" title=\"#{filepath}\" >#{filename}</#{wrapper_class}></font>", stat, filename]

  getGitStatusName: (path, gitRoot, repo) ->
    status = (repo.getCachedPathStatus or repo.getPathStatus)(path)
    if status
      if repo.isStatusModified status
        return 'modified'
      if repo.isStatusNew status
        return 'added'
    if repo.isPathIgnore path
      return 'ignored'

  escapeRegExp: (string) ->
    if string == null
      return null
    return string.replace(/([.*+?^=!:${}()|\[\]\/\\])/g, "\\$1");

  replaceAll: (find, replace, str) ->
    if not str?
      return null
    if not replace?
      return str
    return str.replace(new RegExp(@escapeRegExp(find), 'g'), replace);

  preserveOriginalPaths: (text) ->
    text = @replaceAll @getCurrentFilePath(), '%(file-original)', text
    text = @replaceAll @getCwd(), '%(cwd-original)', text
    text = @replaceAll @getCwd(), '%(cwd-original)', text
    return text

  parseMessage: (message) ->
    if message == null
      return ''


    if atom.config.get('atom-terminal-panel.textReplacementFileAdress')?
      if atom.config.get('atom-terminal-panel.textReplacementFileAdress') != ''
        cwdN = @getCwd()
        cwdE = @replaceAll '/', '\\', @getCwd()
        regexString ='(' + (@escapeRegExp cwdN) + '|' + (@escapeRegExp cwdE) + ')\\\\[A-Za-z\\- ]+\\.?[A-Za-z\\-]*'
        # @rawMessage 'regex := '+regexString+'\n'
        # @rawMessage 'regex => '+regexString+'\n'
        regex = new RegExp(regexString, 'ig')
        message = message.replace regex, (match, text, urlId) =>
          # @rawMessage 'file = '+match+'\n'
          return @parseSpecialStringTemplate atom.config.get('atom-terminal-panel.textReplacementFileAdress'), {file:match}
    message = @preserveOriginalPaths message

    # message = @preserveOriginalPaths message

    if atom.config.get('atom-terminal-panel.textReplacementCurrentFile')?
      if atom.config.get('atom-terminal-panel.textReplacementCurrentFile') != ''
        repl = @parseSpecialStringTemplate atom.config.get('atom-terminal-panel.textReplacementCurrentFile')
        message = @replaceAll @getCurrentFilePath(), repl, message
    message = @preserveOriginalPaths message

    if atom.config.get('atom-terminal-panel.textReplacementCurrentPath')?
      if atom.config.get('atom-terminal-panel.textReplacementCurrentPath') != ''
        repl = @parseSpecialStringTemplate atom.config.get('atom-terminal-panel.textReplacementCurrentPath')
        message = @replaceAll @getCwd(), repl, message
    message = @preserveOriginalPaths message


    message = @replaceAll '%(file-original)', @getCurrentFilePath(), message
    message = @replaceAll '%(cwd-original)', @getCwd(), message

    rules = core.getConfig().rules
    for key, value of rules
      matchExp = key
      replExp = '%(content)'
      matchAllLine = false

      if value.match?
        if value.match.replace?
          replExp = value.match.replace
        if value.match.matchLine?
          matchAllLine = value.match.matchLine

      if matchAllLine
        matchExp = '.*' + matchExp

      regex = new RegExp(matchExp, 'ig')

      message = message.replace regex, (match, groups...) =>

        style = ''
        if value.css?
          style = core.jsonCssToInlineStyle value.css
        else if not value.match?
          style = core.jsonCssToInlineStyle value
        vars =
          content: match
          0: match

        groupsNumber = groups.length-1
        for i in [0..groupsNumber] by 1
          vars[i+1] = groups[i]

        repl = @parseSpecialStringTemplate replExp, vars
        return "<font style=\"#{style}\">#{repl}</font>"

    # message = @replaceAll @getCurrentFilePath(), ".", message
    message = @replaceAll '%(file-original)', @getCurrentFilePath(), message
    message = @replaceAll '%(cwd-original)', @getCwd(), message


    return message

  rawMessage: (message) ->
    @cliOutput.append message
    @showCmd()
    removeClass @statusIcon, 'status-error'
    addClass @statusIcon, 'status-success'
    # @parseSpecialNodes()

  message: (message) ->
    mes = @parseMessage(message)
    # mes = @replaceAll '<', '&lt;', mes
    # mes = @replaceAll '>', '&gt;', mes
    @cliOutput.append mes
    @showCmd()
    removeClass @statusIcon, 'status-error'
    addClass @statusIcon, 'status-success'
    @parseSpecialNodes()

  errorMessage: (message) ->
    @cliOutput.append @parseMessage(message)
    @showCmd()
    removeClass @statusIcon, 'status-success'
    addClass @statusIcon, 'status-error'
    @parseSpecialNodes()

  correctFilePath: (path) ->
    return @replaceAll '\\', '/', path

  getCwd: ->
    extFile = extname atom.project.path

    if extFile == ""
      if atom.project.path
        projectDir = atom.project.path
      else
        if process.env.HOME
          projectDir = process.env.HOME
        else if process.env.USERPROFILE
          projectDir = process.env.USERPROFILE
        else
          projectDir = '/'
    else
      projectDir = dirname atom.project.path

    cwd = @cwd or projectDir or @userHome
    return @correctFilePath cwd

  spawn: (inputCmd, cmd, args) ->
    @cmdEditor.hide()
    htmlStream = ansihtml()
    htmlStream.on 'data', (data) =>
      @message(data)
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
        console.log 'exit', code if atom.config.get('atom-terminal-panel.logConsole')
        @killBtn.addClass 'hide'
        removeClass @statusIcon, 'status-running'
        # removeClass @statusIcon, 'status-error'
        @program = null
        addClass @statusIcon, code == 0 and 'status-success' or 'status-error'
        @showCmd()
      @program.on 'error', (err) =>
        console.log 'error' if atom.config.get('atom-terminal-panel.logConsole')
        @message(err.message)
        @showCmd()
        addClass @statusIcon, 'status-error'
      @program.stdout.on 'data', =>
        @flashIconClass 'status-info'
        removeClass @statusIcon, 'status-error'
      @program.stderr.on 'data', =>
        console.log 'stderr' if atom.config.get('atom-terminal-panel.logConsole')
        @flashIconClass 'status-error', 300

    catch err
      @message (err.message)
      @showCmd()
