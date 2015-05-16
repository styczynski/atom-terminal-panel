###
  Atom-terminal-panel
  Copyright by isis97
  MIT licensed

  The main terminal view class, which does the most of all the work.
###

lastOpenedView = null

fs = include 'fs'
os = include 'os'
{$, TextEditorView, View} = include 'atom-space-pen-views'
{spawn, exec, execSync} = include 'child_process'
{resolve, dirname, extname, sep} = include 'path'

ansihtml = include 'ansi-html-stream'
stream = include 'stream'
iconv = include 'iconv-lite'

ATPCommandFinderView = include 'atp-command-finder'
ATPCore = include 'atp-core'
ATPCommandsBuiltins = include 'atp-builtins-commands'
ATPVariablesBuiltins = include 'atp-builtins-variables'

window.$ = window.jQuery = $
include 'jquery-autocomplete-js'


module.exports =
class ATPOutputView extends View
  cwd: null
  streamsEncoding: 'iso-8859-3'
  _cmdintdel: 50
  echoOn: true
  redirectOutput: ''
  specsMode: false
  inputLine: 0
  helloMessageShown: false
  minHeight: 250
  util: include 'atp-terminal-util'
  currentInputBox: null
  currentInputBox: null
  currentInputBoxTmr: null
  volatileSuggestions: []
  disposables:
    dispose: (field) =>
      if not this[field]?
        this[field] = []
      a = this[field]
      for i in [0..a.length-1] by 1
        a[i].dispose()
    add: (field, value) =>
      if not this[field]?
        this[field] = []
      this[field].push value
  keyCodes: {
    enter: 13
    arrowUp: 38
    arrowDown: 40
    arrowLeft: 37
    arrowRight: 39
  }
  localCommandAtomBindings: []
  localCommands: ATPCommandsBuiltins
  @content: ->
    @div tabIndex: -1, class: 'panel atp-panel panel-bottom', outlet: 'atpView', =>
      @div class: 'terminal panel-divider', style: 'cursor:n-resize;width:100%;height:8px;', outlet: 'panelDivider'
      @button outlet: 'maximizeIconBtn', class: 'atp-maximize-btn', click: 'maximize'
      @button outlet: 'closeIconBtn', class: 'atp-close-btn', click: 'close'
      @button outlet: 'destroyIconBtn', class: 'atp-destroy-btn', click: 'destroy'
      @div class: 'panel-heading btn-toolbar', outlet:'consoleToolbarHeading', =>
        @div class: 'btn-group', outlet:'consoleToolbar', =>
          @button outlet: 'killBtn', click: 'kill', class: 'btn hide', =>
            @span 'kill'
          @button outlet: 'exitBtn', click: 'destroy', class: 'btn', =>
            @span 'exit'
          @button outlet: 'closeBtn', click: 'close', class: 'btn', =>
            @span class: "icon icon-x"
            @span 'close'
        @button outlet: 'openConfigBtn', class: 'btn icon icon-gear inline-block-tight button-settings', click: 'showSettings', =>
          @span 'Open config'
        @button outlet: 'reloadConfigBtn', class: 'btn icon icon-gear inline-block-tight button-settings', click: 'reloadSettings', =>
          @span 'Reload config'
      @div class: 'atp-panel-body', =>
        @pre class: "terminal", outlet: "cliOutput"

  toggleAutoCompletion: () ->
    if @currentInputBoxCmp?
      @currentInputBoxCmp.enable()
      @currentInputBoxCmp.repaint()
      @currentInputBoxCmp.showDropDown()
      @currentInputBox.find('.terminal-input').height('100px');

  fsSpy: () ->
    @volatileSuggestions = []
    if @cwd?
      fs.readdir @cwd, (err, files) =>
        if files?
          for file in files
            @volatileSuggestions.push file

  turnSpecsMode: (state) ->
    @specsMode = state

  getRawOutput: () ->
    t = @getHtmlOutput().replace(/<[^>]*>/igm, "")
    t = @util.replaceAll "&gt;", ">", t
    t = @util.replaceAll "&lt;", "<", t
    t = @util.replaceAll "&quot;", "\"", t
    return t

  getHtmlOutput: () ->
    return @cliOutput.html()

  resolvePath: (path) ->
    path = @util.replaceAll '\"', '', path
    filepath = ''
    if path.match(/([A-Za-z]):/ig) != null
      filepath = path
    else
      filepath = @getCwd() + '/' + path
    filepath = @util.replaceAll '\\', '/', filepath
    return @util.replaceAll '\\', '/', (resolve filepath)

  reloadSettings: () ->
    @onCommand 'update'

  showSettings: () ->
    ATPCore.reload()
    setTimeout () =>
      panelPath = atom.packages.resolvePackagePath 'atom-terminal-panel'
      atomPath = resolve panelPath+'/../..'
      configPath = atomPath + '/terminal-commands.json'
      atom.workspace.open configPath
    , 50

  focusInputBox: () ->
    if @currentInputBoxCmp?
      @currentInputBoxCmp.input.focus()

  updateInputCursor: (textarea) ->
    @rawMessage 'test\n'
    val = textarea.val()
    textarea
      .blur()
      .focus()
      .val("")
      .val(val)

  removeInputBox: () ->
    @cliOutput.find('.atp-dynamic-input-box').remove()

  putInputBox: () ->
    if @currentInputBoxTmr?
      clearInterval @currentInputBoxTmr
      @currentInputBoxTmr = null

    @cliOutput.find('.atp-dynamic-input-box').remove()
    prompt = @getCommandPrompt('')
    @currentInputBox = $(
      '<div style="width: 100%; white-space:nowrap; overflow:hidden; display:inline-block;" class="atp-dynamic-input-box">' +
      '<div style="position:relative; top:5px; max-height:500px; width: 100%; bottom: -10px; height: 20px; white-space:nowrap; overflow:hidden; display:inline-block;" class="terminal-input native-key-bindings"></div>' +
      '</div>'
    )
    @currentInputBox.prepend '&nbsp;&nbsp;'
    @currentInputBox.prepend prompt

    #@cliOutput.mousedown (e) =>
    #  if e.which is 1
    #    @focusInputBox()

    history = []
    if @currentInputBoxCmp?
      history = @currentInputBoxCmp.getInputHistory()
    inputComp = @currentInputBox.find '.terminal-input'

    @currentInputBoxCmp = inputComp.autocomplete {
      animation: [
        ['opacity', 0, 0.8]
      ]
      isDisabled: true
      inputHistory: history
      inputWidth: '80%'
      dropDownWidth: '30%'
      dropDownDescriptionBoxWidth: '30%'
      dropDownPosition: 'top'
      showDropDown: atom.config.get 'atom-terminal-panel.enableConsoleSuggestionsDropdown'
    }
    @currentInputBoxCmp
    .confirmed(() =>
      @currentInputBoxCmp.disable().repaint()
      @onCommand()
    ).changed((inst, text) =>
      if inst.getText().length <= 0
        @currentInputBoxCmp.disable().repaint()
        @currentInputBox.find('.terminal-input').height('20px')
    )

    @currentInputBoxCmp.input.keydown((e) =>
      if (e.keyCode == 17) and (@currentInputBoxCmp.getText().length > 0)
        ###
        @currentInputBoxCmp.enable().repaint()
        @currentInputBoxCmp.showDropDown()
        @currentInputBox.find('.terminal-input').height('100px');
        ###
      else if (e.keyCode == 32) or (e.keyCode == 8)
        @currentInputBoxCmp.disable().repaint()
        @currentInputBox.find('.terminal-input').height('20px')
    )

    endsWith = (text, suffix) ->
      return text.indexOf(suffix, text.length - suffix.length) != -1

    @currentInputBoxCmp.options = (instance, text, lastToken) =>
      token = lastToken
      if not token?
        token = ''

      if not (endsWith(token, '/') or endsWith(token, '\\'))
        token = @util.replaceAll '\\', sep, token
        token = token.split sep
        token.pop()
        token = token.join(sep)
        if not endsWith(token, sep)
          token = token + sep

      o = @getCommandsNames().concat(@volatileSuggestions)
      fsStat = []
      if token?
        try
          fsStat = fs.readdirSync(token)
          for i in [0..fsStat.length-1] by 1
            fsStat[i] = token + fsStat[i]
        catch e
      ret = o.concat(fsStat)
      return ret

    @currentInputBoxCmp.hideDropDown()
    setTimeout () =>
   	 @currentInputBoxCmp.input.focus()
    , 0

    @currentInputBox.appendTo @cliOutput
    @focusInputBox()

  readInputBox: () ->
    ret = ''
    if @currentInputBoxCmp?
      # ret = @currentInputBox.find('.terminal-input').val()
      ret = @currentInputBoxCmp.getText()
    return ret

  requireCSS: (location) ->
    if not location?
      return
    location = resolve location
    console.log ("Require atom-terminal-panel plugin CSS file: "+location+"\n") if atom.config.get('atom-terminal-panel.logConsole') or @specsMode
    $('head').append "<link rel='stylesheet' type='text/css' href='#{location}'/>"

  resolvePluginDependencies: (path, plugin) ->
    config = plugin.dependencies
    if not config?
      return

    css_dependencies = config.css
    if not css_dependencies?
      css_dependencies = []
    for css_dependency in css_dependencies
      @requireCSS path+"/"+css_dependency

    delete plugin['dependencies']


  init: () ->


    ###
    TODO: test-autocomplete Remove this!
    el = $('<div style="z-index: 9999; position: absolute; left: 200px; top: 200px;" id="glotest"></div>')
    el.autocomplete({
      inputWidth: '80%'
    })
    $('body').append(el)
    ###


    lastY = -1
    mouseDown = false
    panelDraggingActive = false
    @panelDivider
    .mousedown () => panelDraggingActive = true
    .mouseup () => panelDraggingActive = false
    $(document)
    .mousedown () => mouseDown = true
    .mouseup () => mouseDown = false
    .mousemove (e) =>
      if mouseDown and panelDraggingActive
        if lastY != -1
          delta = e.pageY - lastY
          @cliOutput.height @cliOutput.height()-delta
        lastY = e.pageY
      else
        lastY = -1

    normalizedPath = require("path").join(__dirname, "../commands")
    console.log ("Loading atom-terminal-panel plugins from the directory: "+normalizedPath+"\n") if atom.config.get('atom-terminal-panel.logConsole') or @specsMode
    fs.readdirSync(normalizedPath).forEach( (folder) =>
      fullpath = resolve "../commands/" +folder
      console.log ("Require atom-terminal-panel plugin: "+folder+"\n") if atom.config.get('atom-terminal-panel.logConsole') or @specsMode
      obj = require ("../commands/" +folder+"/index.coffee")
      console.log "Plugin loaded." if atom.config.get('atom-terminal-panel.logConsole')
      @resolvePluginDependencies fullpath, obj
      for key, value of obj
        if value.command?
          @localCommands[key] = value
          @localCommands[key].source = 'external-functional'
          @localCommands[key].sourcefile = folder
        else if value.variable?
          value.name = key
          ATPVariablesBuiltins.putVariable value
    )
    console.log ("All plugins were loaded.") if atom.config.get('atom-terminal-panel.logConsole')

    if ATPCore.getConfig()?
      actions = ATPCore.getConfig().actions
      if actions?
        for action in actions
          if action.length > 1
            obj = {}
            obj['atom-terminal-panel:'+action[0]] = () =>
              @open()
              @onCommand action[1]
            atom.commands.add 'atom-workspace', obj

    if atom.workspace?
      eleqr = atom.workspace.getActivePaneItem() ? atom.workspace
      eleqr = atom.views.getView(eleqr)
      atomCommands = atom.commands.findCommands({target: eleqr})
      for command in atomCommands
        comName = command.name
        com = {}
        com.description = command.displayName
        com.command =
          ((comNameP) ->
            return (state, args) ->
              ele = atom.workspace.getActivePaneItem() ? atom.workspace
              ele = atom.views.getView(ele)
              atom.commands.dispatch ele, comNameP
              return (state.consoleLabel 'info', "info") + (state.consoleText 'info', 'Atom command executed: '+comNameP)
          )(comName)
        com.source = "internal-atom"
        @localCommands[comName] = com

    toolbar = ATPCore.getConfig().toolbar
    if toolbar?
      toolbar.reverse()
      for com in toolbar
        bt = $("<div class=\"btn\" data-action=\"#{com[1]}\" ><span>#{com[0]}</span></div>")
        if com[2]?
          atom.tooltips.add bt,
            title: com[2]
        @consoleToolbar.prepend bt
        caller = this
        bt.click () ->
          caller.onCommand $(this).data('action')

    return this

  commandLineNotCounted: () ->
    @inputLine--

  parseSpecialStringTemplate: (prompt, values, isDOM=false) =>
    if isDOM
      return ATPVariablesBuiltins.parseHtml(this, prompt, values)
    else
      return ATPVariablesBuiltins.parse(this, prompt, values)

  getCommandPrompt: (cmd) ->
    return @parseTemplate atom.config.get('atom-terminal-panel.commandPrompt'), {cmd: cmd}, true

  delay: (callback, delay=100) ->
    setTimeout callback, delay

  execDelayedCommand: (delay, cmd, args, state) ->
    caller = this
    callback = ->
      caller.exec cmd, args, state
    setTimeout callback, delay

  moveToCurrentDirectory: ()->
    CURRENT_LOCATION = @getCurrentFileLocation()
    if CURRENT_LOCATION?
      @cd [CURRENT_LOCATION]

  getCurrentFileName: ()->
    current_file = @getCurrentFilePath()
    if current_file != null
      matcher = /(.*:)((.*)\\)*/ig
      return current_file.replace matcher, ""
    return null

  getCurrentFileLocation: ()->
    if @getCurrentFilePath() == null
      return null
    return  @util.replaceAll(@getCurrentFileName(), "", @getCurrentFilePath())

  getCurrentFilePath: ()->
    if not atom.workspace?
      return null
    te = atom.workspace.getActiveTextEditor()
    if te?
      if te.getPath()?
        return te.getPath()
    return null


  parseTemplate: (text, vars, isDOM=false) ->
    if not vars?
      vars = {}
    ret = ''
    if isDOM
      ret = ATPVariablesBuiltins.parseHtml this, text, vars
    else
      ret = @parseSpecialStringTemplate text, vars
      ret = @util.replaceAll '%(file-original)', @getCurrentFilePath(), ret
      ret = @util.replaceAll '%(cwd-original)', @getCwd(), ret
      ret = @util.replaceAll '&fs;', '/', ret
      ret = @util.replaceAll '&bs;', '\\', ret
    return ret

  parseExecToken__: (cmd, args, strArgs) ->
    if strArgs?
      cmd = @util.replaceAll "%(*)", strArgs, cmd
    cmd = @util.replaceAll "%(*^)", (@util.replaceAll "%(*^)", "", cmd), cmd
    if args?
      argsNum = args.length
      for i in [0..argsNum] by 1
        if args[i]?
          v = args[i].replace /\n/ig, ''
          cmd = @util.replaceAll "%(#{i})", args[i], cmd
    cmd = @parseTemplate cmd, {file:@getCurrentFilePath()}
    return cmd

  execStackCounter: 0
  exec: (cmdStr, ref_args, state, callback) ->
    if not state?
      state = this
    if not ref_args?
      ref_args = {}
    if cmdStr.split?
      cmdStrC = cmdStr.split ';;'
      if cmdStrC.length > 1
        cmdStr = cmdStrC
    @execStackCounter = 0
    return @exec_ cmdStr, ref_args, state, callback

  exec_: (cmdStr, ref_args, state, callback) ->
    if not callback?
      callback = () -> return null
    ++@execStackCounter
    if cmdStr instanceof Array
      ret = ''
      for com in cmdStr
        val = @exec com, ref_args, state
        if val?
          ret += val
      --@execStackCounter
      if @execStackCounter==0
        callback()
      if not ret?
        return null
      return ret
    else
      cmdStr = @util.replaceAll "\\\"", '&hquot;', cmdStr
      cmdStr = @util.replaceAll "&bs;\"", '&hquot;', cmdStr
      cmdStr = @util.replaceAll "\\\'", '&lquot;', cmdStr
      cmdStr = @util.replaceAll "&bs;\'", '&lquot;', cmdStr

      ref_args_str = null
      if ref_args?
        if ref_args.join?
          ref_args_str = ref_args.join(' ')
      cmdStr = @parseExecToken__ cmdStr, ref_args, ref_args_str

      args = []
      cmd = cmdStr
      cmd.replace /("[^"]*"|'[^']*'|[^\s'"]+)/g, (s) =>
        if s[0] != '"' and s[0] != "'"
          s = s.replace /~/g, @userHome
        s = @util.replaceAll '&hquot;', '"', s
        s = @util.replaceAll '&lquot;', '\'', s
        args.push s
      args = @util.dir args, @getCwd()
      cmd = args.shift()

      command = null
      if @isCommandEnabled(cmd)
        command = ATPCore.findUserCommand(cmd)
      if command?
        if not state?
          ret = null
          throw 'The console functional (not native) command cannot be executed without caller information: \''+cmd+'\'.'
        if command?
          try
            ret = command(state, args)
          catch e
            throw new Error "Error at executing terminal command: '#{cmd}' ('#{cmdStr}'): #{e.message}"
        --@execStackCounter
        if @execStackCounter==0
          callback()
        if not ret?
          return null
        return ret
      else
        if atom.config.get('atom-terminal-panel.enableExtendedCommands') or @specsMode
          if @isCommandEnabled(cmd)
            command = @getLocalCommand(cmd)
        if command?
          ret = command(state, args)
          --@execStackCounter
          if @execStackCounter==0
            callback()
          if not ret?
            return null
          return ret
        else
          cmdStr = @util.replaceAll '&hquot;', '"', cmdStr
          cmd = @util.replaceAll '&hquot;', '"', cmd
          cmdStr = @util.replaceAll '&lquot;', '\'', cmdStr
          cmd = @util.replaceAll '&lquot;', '\'', cmd
          @spawn cmdStr, cmd, args
          --@execStackCounter
          if @execStackCounter==0
            callback()
          if not cmd?
            return null
          return null

  isCommandEnabled: (name) ->
    disabledCommands = atom.config.get('atom-terminal-panel.disabledExtendedCommands') or @specsMode
    if not disabledCommands?
      return true
    if name in disabledCommands
      return false
    return true

  getLocalCommand: (name) ->
    for cmd_name, cmd_body of @localCommands
      if cmd_name == name
        if cmd_body.command?
          return cmd_body.command
        else
          return cmd_body
    return null

  getCommandsRegistry: () ->
    global_vars = ATPVariablesBuiltins.list

    for key, value of process.env
      global_vars['%(env.'+key+')'] = "access native environment variable: "+key

    cmd = []
    for cmd_name, cmd_body of @localCommands
      cmd.push {
        name: cmd_name
        description: cmd_body.description
        example: cmd_body.example
        params: cmd_body.params
        deprecated: cmd_body.deprecated
        sourcefile: cmd_body.sourcefile
        source: cmd_body.source or 'internal'
      }
    for cmd_name, cmd_body of ATPCore.getUserCommands()
      cmd.push {
        name: cmd_name
        description: cmd_body.description
        example: cmd_body.example
        params: cmd_body.params
        deprecated: cmd_body.deprecated
        sourcefile: cmd_body.sourcefile
        source: 'external'
      }
    for var_name, descr of global_vars
      cmd.push {
        name: var_name
        description: descr
        source: 'global-variable'
      }

    cmd_ = []
    cmd_len = cmd.length
    cmd_forbd = (atom.config.get 'atom-terminal-panel.disabledExtendedCommands') or []
    for cmd_item in cmd
      if cmd_item.name in cmd_forbd
      else
        cmd_.push cmd_item

    return cmd_

  getCommandsNames: () ->
    cmds = @getCommandsRegistry()
    cmd_names = []
    for item in cmds
      descr = ""
      example = ""
      params = ""
      sourcefile = ""
      deprecated = false
      name = item.name
      if item.sourcefile?
        sourcefile = "<div style='float:bottom'><b style='float:right'>Plugin #{item.sourcefile}&nbsp;&nbsp;&nbsp;<b></div>"
      if item.example?
        example = "<br><b><u>Example:</u></b><br><code>"+item.example+"</code>"
      if item.params?
        params = item.params
      if item.deprecated
        deprecated = true
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
      if deprecated
        name = "<strike style='color:gray;font-weight:normal;'>"+name+"</strike>"
      descr = "<div style='float:left; padding-top:10px;' class='status status-#{icon_style} icon icon-#{icon_style}'></div><div style='padding-left: 10px;'><b>#{name} #{params}</b><br>#{item.description} #{example} #{sourcefile}</div>"
      cmd_names.push {
        name: item.name
        description: descr
        html: true
      }
    return cmd_names

  getLocalCommandsMemdump: () ->
    cmd = @getCommandsRegistry()
    commandFinder = new ATPCommandFinderView cmd
    commandFinderPanel = atom.workspace.addModalPanel(item: commandFinder)
    commandFinder.shown commandFinderPanel, this
    return

  commandProgress: (value) ->
    if value < 0
      @cliProgressBar.hide()
      @cliProgressBar.attr('value', '0')
    else
      @cliProgressBar.show()
      @cliProgressBar.attr('value', value/2)

  showInitMessage: (forceShow=false) ->
    if not forceShow
      if @helloMessageShown
        return
    if atom.config.get 'atom-terminal-panel.enableConsoleStartupInfo' or forceShow or (not @specsMode)
      changelog_path = require("path").join(__dirname, "../CHANGELOG.md");
      readme_path = require("path").join(__dirname, "../README.md");
      hello_message = @consolePanel 'ATOM Terminal', 'Please enter new commands to the box below. (ctrl-to show suggestions dropdown)<br>The console supports special anotattion like: %(path), %(file), %(link)file.something%(endlink).<br>It also supports special HTML elements like: %(tooltip:A:content:B) and so on.<br>Hope you\'ll enjoy the terminal.'+
      "<br><a class='changelog-link' href='#{changelog_path}'>See changelog</a>&nbsp;&nbsp;<a class='readme-link' href='#{readme_path}'>and the README! :)</a>"
      @rawMessage hello_message
      $('.changelog-link').css('font-weight','300%').click(() =>
          atom.workspace.open changelog_path
      )
      $('.readme-link').css('font-weight','300%').click(() =>
          atom.workspace.open readme_path
      )
      @helloMessageShown = true
    return this

  onCommand: (inputCmd) ->
    @fsSpy()

    if not inputCmd?
      inputCmd = @readInputBox()

    @disposables.dispose('statusIconTooltips')
    @disposables.add 'statusIconTooltips', atom.tooltips.add @statusIcon,
     title: 'Task: \"'+inputCmd+'\"'
     delay: 0
     animation: false

    @inputLine++
    inputCmd = @parseSpecialStringTemplate inputCmd

    if @echoOn
      console.log 'echo-on'
      #TODO: Repair!
      #@message "\n"+@getCommandPrompt(inputCmd)+" "+inputCmd+"\n", false

    ret = @exec inputCmd, null, this, () =>
      setTimeout () =>
        @putInputBox()
      , 750
    if ret?
      @message ret + '\n'

    @scrollToBottom()

    # TODO: Should be removed.
    @putInputBox()
    setTimeout () =>
      @putInputBox()
    , 750
    # TODO: Repair this above, making input box less buggy!

    return null

  initialize: ->
    @userHome = process.env.HOME or process.env.HOMEPATH or process.env.USERPROFILE
    cmd = 'test -e /etc/profile && source /etc/profile;test -e ~/.profile && source ~/.profile; node -pe "JSON.stringify(process.env)"'
    exec cmd, (code, stdout, stderr) ->
      try
        process.env = JSON.parse(stdout)
      catch e
    atom.commands.add 'atom-workspace',
      "atp-status:toggle-output": => @toggle()

  clear: ->
    @cliOutput.empty()
    @message '\n'
    @putInputBox()

  adjustWindowHeight: ->
    maxHeight = atom.config.get('atom-terminal-panel.WindowHeight')
    @cliOutput.css("max-height", "#{maxHeight}px")
    $('.terminal-input').css("max-height", "#{maxHeight}px")

  showCmd: ->
    @focusInputBox()
    @scrollToBottom()

  scrollToBottom: ->
    @cliOutput.scrollTop 10000000

  flashIconClass: (className, time=100)=>
    @statusIcon.addClass className
    @timer and clearTimeout(@timer)
    onStatusOut = =>
      @statusIcon.removeClass className
    @timer = setTimeout onStatusOut, time

  destroy: ->
    @statusIcon.remove()

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

  terminateProcessTree: () ->
    pid = @program.pid
    psTree = require 'ps-tree'
    killProcess = (pid, signal, callback) =>
        signal   = signal || 'SIGKILL'
        callback = callback || () -> {}
        killTree = true
        if killTree
            psTree(pid, (err, children) =>
                [pid].concat(
                    children.map((p) =>
                        return p.PID
                    )
                ).forEach((tpid) =>
                    try
                      process.kill tpid, signal
                    catch ex

                )
                callback()
            )
        else
          try
            process.kill pid, signal
          catch ex
          callback()
    killProcess pid, 'SIGINT'


  kill: ->
    if @program
      @terminateProcessTree @program.pid
      @program.stdin.pause()
      @program.kill('SIGINT')
      @program.kill()
      @message (@consoleLabel 'info', 'info')+(@consoleText 'info', 'Process has been stopped')

  maximize: ->
    @cliOutput.height (@cliOutput.height()+9999)

  open: ->
    if (atom.config.get('atom-terminal-panel.moveToCurrentDirOnOpen')) and (not @specsMode)
      @moveToCurrentDirectory()
    if (atom.config.get('atom-terminal-panel.moveToCurrentDirOnOpenLS')) and (not @specsMode)
      @clear()
      @execDelayedCommand @_cmdintdel, 'ls', null, this

    atom.workspace.addBottomPanel(item: this) unless @hasParent()
    if lastOpenedView and lastOpenedView != this
      lastOpenedView.close()
    lastOpenedView = this
    @scrollToBottom()
    @statusView.setActiveCommandView this
    @focusInputBox()
    @showInitMessage()
    @putInputBox()

    atom.tooltips.add @killBtn,
     title: 'Kill the long working process.'
    atom.tooltips.add @exitBtn,
     title: 'Destroy the terminal session.'
    atom.tooltips.add @closeBtn,
     title: 'Hide the terminal window.'
    atom.tooltips.add @openConfigBtn,
     title: 'Open the terminal config file.'
    atom.tooltips.add @reloadConfigBtn,
     title: 'Reload the terminal configuration.'

    if atom.config.get 'atom-terminal-panel.enableWindowAnimations'
      @WindowMinHeight = @cliOutput.height() + 50
      @height 0
      @consoleToolbarHeading.css {opacity: 0}
      @animate {
        height: @WindowMinHeight
      }, 250, =>
        @attr 'style', ''
        @consoleToolbarHeading.animate {
          opacity: 1
        }, 250, =>
          @consoleToolbarHeading.attr 'style', ''

  close: ->
    if atom.config.get 'atom-terminal-panel.enableWindowAnimations'
      @WindowMinHeight = @cliOutput.height() + 50
      @height @WindowMinHeight
      @animate {
        height: 0
      }, 250, =>
        @attr 'style', ''
        @consoleToolbar.attr 'style', ''
        @detach()
        lastOpenedView = null
    else
      @detach()
      lastOpenedView = null


  toggle: ->
    if @hasParent()
      @close()
    else
      @open()

  removeQuotes: (text)->
    if not text?
      return ''
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
    try
      stat = fs.statSync dir
      if not stat.isDirectory()
        return @errorMessage "cd: not a directory: #{args[0]}"
      @cwd = dir
      @putInputBox()
    catch e
      return @errorMessage "cd: #{args[0]}: No such file or directory"
    return null

  ls: (args) ->
    try
      files = fs.readdirSync @getCwd()
    catch e
      return false

    if atom.config.get('atom-terminal-panel.XExperimentEnableForceLinking')
      ret = ''
      files.forEach (filename) =>
        ret += @resolvePath filename + '\t%(break)'
      @message ret
      return true

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
    @message filesBlocks.join('%(break)') + '<div class="clear"/>'
    return true

  parseSpecialNodes: () ->
    caller = this

    if atom.config.get 'atom-terminal-panel.enableConsoleInteractiveHints'
      $('.atp-tooltip[data-toggle="tooltip"]').each(() ->
          title = $(this).attr('title')
          atom.tooltips.add $(this), {}
      )

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
                atom.workspace.open link_target, {
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
    return '<div class="panel panel-info welcome-panel"><div class="panel-heading">'+title+'</div><div class="panel-body">'+content+'</div></div><br><br>'

  consoleText: (type, text) ->
    if type == 'info'
      return '<span class="text-info" style="margin-left:10px;">'+text+'</span>'
    if type == 'error'
      return '<span class="text-error" style="margin-left:10px;">'+text+'</span>'
    if type == 'warning'
      return '<span class="text-warning" style="margin-left:10px;">'+text+'</span>'
    if type == 'success'
      return '<span class="text-success" style="margin-left:10px;">'+text+'</span>'
    return text

  consoleLabel: (type, text) ->
    if (not atom.config.get 'atom-terminal-panel.enableConsoleLabels') and (not @specsMode)
      return text

    if not text?
      text = type

    if type == 'badge'
      return '<span class="badge">'+text+'</span>'
    if type == 'default'
      return '<span class="inline-block highlight">'+text+'</span>'
    if type == 'primary'
      return '<span class="label label-primary">'+text+'</span>'
    if type == 'success'
      return '<span class="inline-block highlight-success">'+text+'</span>'
    if type == 'info'
      return '<span class="inline-block highlight-info">'+text+'</span>'
    if type == 'warning'
      return '<span class="inline-block highlight-warning">'+text+'</span>'
    if type == 'danger'
      return '<span class="inline-block highlight-error">'+text+'</span>'
    if type == 'error'
      return '<span class="inline-block highlight-error">'+text+'</span>'
    return '<span class="label label-default">'+text+'</span>'

  consoleLink: (name, forced=true) ->
    if (atom.config.get 'atom-terminal-panel.XExperimentEnableForceLinking') and (not forced)
      return name
    return @_fileInfoHtml(name, @getCwd(), 'font', false)[0]

  _fileInfoHtml: (filename, parent, wrapper_class='span', use_file_info_class='true') ->

    str = filename
    name_tokens = filename
    filename = filename.replace /:[0-9]+:[0-9]/ig, ''
    name_tokens = @util.replaceAll filename, '', name_tokens
    name_tokens = name_tokens.split ':'
    fileline = name_tokens[0]
    filecolumn = name_tokens[1]

    filename = @util.replaceAll '/', '\\', filename
    filename = @util.replaceAll parent, '', filename
    filename = @util.replaceAll (@util.replaceAll '/', '\\', parent), '', filename

    if filename[0] == '\\' or filename[0] == '/'
      filename = filename.substring(1)

    if filename == '..'
      if use_file_info_class
        return ["<font class=\"file-extension\"><#{wrapper_class} data-targetname=\"#{filename}\" data-targettype=\"directory\" data-target=\"#{filename}\" class=\"console-link icon-file-directory parent-folder\">#{filename}</#{wrapper_class}></font>", null, filename]
      else
          return ["<font class=\"file-extension\"><#{wrapper_class} data-targetname=\"#{filename}\" data-targettype=\"directory\" data-target=\"#{filename}\" class=\"console-link icon-file-directory file-info parent-folder\">#{filename}</#{wrapper_class}></font>", null, filename]

    file_exists = true

    filepath = @resolvePath filename
    classes = []
    dataname = ''

    if atom.config.get('atom-terminal-panel.useAtomIcons')
      classes.push 'name'
      classes.push 'icon'
      classes.push 'icon-file-text'
      dataname = filepath
    else
      classes.push 'name'

    if use_file_info_class
      classes.push 'file-info'

    stat = null
    if file_exists
      try
        stat = fs.lstatSync filepath
      catch e
        file_exists = false

    if file_exists
      if atom.config.get('atom-terminal-panel.enableConsoleInteractiveLinks') or @specsMode
        classes.push 'console-link'
      if stat.isSymbolicLink()
        classes.push 'stat-link'
        stat = fs.statSync filepath
        target_type = 'null'
      if stat.isFile()
        if stat.mode & 73 #0111
          classes.push 'stat-program'
        # TODO check extension
        matcher = /(.:)((.*)\\)*((.*\.)*)/ig
        extension = filepath.replace matcher, ""
        classes.push @util.replaceAll(' ', '', extension)
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

    href = 'file:///' + @util.replaceAll('\\', '/', filepath)

    classes.push 'atp-tooltip'

    exattrs = []
    if fileline?
      exattrs.push 'data-line="'+fileline+'"'
    if filecolumn?
      exattrs.push 'data-column="'+filecolumn+'"'

    filepath_tooltip = @util.replaceAll '\\', '/', filepath
    filepath = @util.replaceAll '\\', '/', filepath
    ["<font class=\"file-extension\"><#{wrapper_class} #{exattrs.join ' '} tooltip=\"\" data-targetname=\"#{filename}\" data-targettype=\"#{target_type}\" data-target=\"#{filepath}\" data-name=\"#{dataname}\" class=\"#{classes.join ' '}\" data-toggle=\"tooltip\" data-placement=\"top\" title=\"#{filepath_tooltip}\" >#{filename}</#{wrapper_class}></font>", stat, filename]

  getGitStatusName: (path, gitRoot, repo) ->
    status = (repo.getCachedPathStatus or repo.getPathStatus)(path)
    if status
      if repo.isStatusModified status
        return 'modified'
      if repo.isStatusNew status
        return 'added'
    if repo.isPathIgnore path
      return 'ignored'

  preserveOriginalPaths: (text) ->
    text = @util.replaceAll @getCurrentFilePath(), '%(file-original)', text
    text = @util.replaceAll @getCwd(), '%(cwd-original)', text
    text = @util.replaceAll @getCwd(), '%(cwd-original)', text
    text = @util.replaceAll '/', '&fs;', text
    text = @util.replaceAll '\\', '&bs;', text
    return text

  parseMessage: (message, matchSpec=true, parseCustomRules=true) ->
    instance = this
    message = '<div>'+(instance.parseMessage_ message, false, true, true)+'</div>'
    n = $(message)
    n.contents().filter(() ->
      return this.nodeType == 3
    ).each(() ->
      thiz = $(this)
      out = thiz.text()
      out = instance.parseMessage_ out, matchSpec, parseCustomRules
      thiz.replaceWith('<span>'+out+'</span>')
    )
    return n.html()

  parseMessage_: (message, matchSpec=true, parseCustomRules=true, isForcelyPreparsering=false) ->
    if message == null
      return ''
    if matchSpec
      if atom.config.get('atom-terminal-panel.XExperimentEnableForceLinking')
        if atom.config.get('atom-terminal-panel.textReplacementFileAdress')?
          if atom.config.get('atom-terminal-panel.textReplacementFileAdress') != ''
            # regex = /(([A-Za-z]:)(\\|\/))?([A-Za-z$\*\-+&#@!_\.]+(\\|\/))([A-Za-z $\*\-+&#@!_\.]+(\\|\/))*[A-Za-z\-_$\*\+&\^@#\. ]+\.[A-Za-z\-_$\*\+]*/ig
            # regex = /(([A-Za-z]:)(\\|\/))?(([^\s#@$%&!;<>\.\^:]| )+(\\|\/))((([^\s#@$%&!;<>\.\^:]| )+(\\|\/))*([^\s<>:#@$%\^;]| )+(\.([^\s#@$%&!;<>\.0-9:\^]| )*)*)?/ig
            regex = /(\.(\\|\/))?(([A-Za-z]:)(\\|\/))?(([^\s#@$%&!;<>\.\^:]| )+(\\|\/))((([^\s#@$%&!;<>\.\^:]| )+(\\|\/))*([^\s<>:#@$%\^;]| )+(\.([^\s#@$%&!;<>\.0-9:\^]| )*)*)?/ig
            regex2 = /(\.(\\|\/))((([^\s#@$%&!;<>\.\^:]| )+(\\|\/))*([^\s<>:#@$%\^;]| )+(\.([^\s#@$%&!;<>\.0-9:\^]| )*)*)?/ig
            message = message.replace regex, (match, text, urlId) =>
              return @parseSpecialStringTemplate atom.config.get('atom-terminal-panel.textReplacementFileAdress'), {file:match}
            message = message.replace regex2, (match, text, urlId) =>
              return @parseSpecialStringTemplate atom.config.get('atom-terminal-panel.textReplacementFileAdress'), {file:match}
      else
        if atom.config.get('atom-terminal-panel.textReplacementFileAdress')?
          if atom.config.get('atom-terminal-panel.textReplacementFileAdress') != ''
            #regex = /(([A-Za-z]:)(\\|\/))?([A-Za-z$\*\-+&#@!_\.]+(\\|\/))([A-Za-z $\*\-+&#@!_\.]+(\\|\/))*[A-Za-z\-_$\*\+&\^@#\. ]+\.[A-Za-z\-_$\*\+]*/ig
            cwdN = @getCwd()
            cwdE = @util.replaceAll '/', '\\', @getCwd()
            regexString ='(' + (@util.escapeRegExp cwdN) + '|' + (@util.escapeRegExp cwdE) + ')\\\\([^\\s:#$%^&!:]| )+\\.?([^\\s:#$@%&\\*\\^!0-9:\\.+\\-,\\\\\\/\"]| )*'
            regex = new RegExp(regexString, 'ig')
            message = message.replace regex, (match, text, urlId) =>
              return @parseSpecialStringTemplate atom.config.get('atom-terminal-panel.textReplacementFileAdress'), {file:match}
      if atom.config.get('atom-terminal-panel.textReplacementCurrentFile')?
        if atom.config.get('atom-terminal-panel.textReplacementCurrentFile') != ''
          path = @getCurrentFilePath()
          regex = new RegExp @util.escapeRegExp(path), 'g'
          message = message.replace regex, (match, text, urlId) =>
            return @parseSpecialStringTemplate atom.config.get('atom-terminal-panel.textReplacementCurrentFile'), {file:match}
      message = @preserveOriginalPaths message
      if atom.config.get('atom-terminal-panel.textReplacementCurrentPath')?
        if atom.config.get('atom-terminal-panel.textReplacementCurrentPath') != ''
          path = @getCwd()
          regex = new RegExp @util.escapeRegExp(path), 'g'
          message = message.replace regex, (match, text, urlId) =>
            return @parseSpecialStringTemplate atom.config.get('atom-terminal-panel.textReplacementCurrentPath'), {file:match}


    message = @util.replaceAll '%(file-original)', @getCurrentFilePath(), message
    message = @util.replaceAll '%(cwd-original)', @getCwd(), message
    message = @util.replaceAll '&fs;', '/', message
    message = @util.replaceAll '&bs;', '\\', message

    rules = ATPCore.getConfig().rules
    for key, value of rules
      matchExp = key
      replExp = '%(content)'
      matchAllLine = false
      matchNextLines = 0
      flags = 'gm'
      forceParse = false

      if value.match?
        if value.match.flags?
          flags = value.match.flags.join ''
        if value.match.replace?
          replExp = value.match.replace
        if value.match.matchLine?
          matchAllLine = value.match.matchLine
        if value.match.matchNextLines?
          matchNextLines = value.match.matchNextLines
        if value.match.forced?
          forceParse = value.match.forced

      if (forceParse or parseCustomRules) and ((isForcelyPreparsering and forceParse) or (not isForcelyPreparsering))
        if matchAllLine
          matchExp = '.*' + matchExp

        if matchNextLines > 0
          for i in [0..matchNextLines] by 1
            matchExp = matchExp + '[\\r\\n].*';

        regex = new RegExp(matchExp, flags)

        message = message.replace regex, (match, groups...) =>
          style = ''
          if value.css?
            style = ATPCore.jsonCssToInlineStyle value.css
          else if not value.match?
            style = ATPCore.jsonCssToInlineStyle value
          vars =
            content: match
            0: match

          groupsNumber = groups.length-1
          for i in [0..groupsNumber] by 1
            if groups[i]?
              vars[i+1] = groups[i]

          # console.log 'Active rule => '+matchExp
          repl = @parseSpecialStringTemplate replExp, vars
          return "<font style=\"#{style}\">#{repl}</font>"

    message = @util.replaceAll '%(file-original)', @getCurrentFilePath(), message
    message = @util.replaceAll '%(cwd-original)', @getCwd(), message
    message = @util.replaceAll '&fs;', '/', message
    message = @util.replaceAll '&bs;', '\\', message

    return message

  redirect: (streamName) ->
    @redirectOutput = streamName

  rawMessage: (message) ->
    if @redirectOutput == 'console'
      console.log message
      return

    @cliOutput.append message
    @showCmd()
    @statusIcon.removeClass 'status-error'
    @statusIcon.addClass 'status-success'
    # @parseSpecialNodes()

  message: (message, matchSpec=true) ->
    if @redirectOutput == 'console'
      console.log message
      return

    if typeof message is 'object'
      mes = message
    else
      if not message?
        return
      mes = message.split '%(break)'
      if mes.length > 1
        for m in mes
          @message m
        return
      else
        mes = mes[0]
      mes = @parseMessage message, matchSpec, matchSpec
      mes = @util.replaceAll '%(raw)', '', mes
      mes = @parseTemplate mes, [], true

    # mes = @util.replaceAll '<', '&lt;', mes
    # mes = @util.replaceAll '>', '&gt;', mes
    @cliOutput.append mes
    @showCmd()
    @statusIcon.removeClass 'status-error'
    @statusIcon.addClass 'status-success'
    @parseSpecialNodes()
    @scrollToBottom()
    # @putInputBox()

  errorMessage: (message) ->
    @cliOutput.append @parseMessage(message)
    @showCmd()
    @statusIcon.removeClass 'status-success'
    @statusIcon.addClass 'status-error'
    @parseSpecialNodes()

  correctFilePath: (path) ->
    return @util.replaceAll '\\', '/', path

  getCwd: ->
    if not atom.project?
      return null
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

  spawn: (inputCmd, cmd, args) =>
    ## @cmdEditor.hide()
    ## htmlStream = ansihtml()
    # htmlStream = iconv.decodeStream @streamsEncoding
    # htmlStream.on 'data', (data) =>
    ## @cliOutput.append data
    # @message data
    # @scrollToBottom()
    # try
    ## @program = spawn cmd, args, stdio: 'pipe', env: process.env, cwd: @getCwd()
    # @program = exec inputCmd, stdio: 'pipe', env: process.env, cwd: @getCwd()
    ## @program.stdin.pipe htmlStream
    # @program.stdout.pipe htmlStream
    # @program.stderr.pipe htmlStream
    ## @program.stdout.setEncoding @streamsEncoding
    @spawnProcessActive = true

    instance = this
    dataCallback = (data) ->
      instance.message(data)
      instance.scrollToBottom()

    htmlStream = ansihtml()
    htmlStream.on 'data', (data) =>
      setTimeout ()->
        dataCallback(data);
      , 100
    try
      @program = exec inputCmd, stdio: 'pipe', env: process.env, cwd: @getCwd()
      @program.stdout.pipe htmlStream
      @program.stderr.pipe htmlStream

      @statusIcon.removeClass 'status-success'
      @statusIcon.removeClass 'status-error'
      @statusIcon.addClass 'status-running'
      @killBtn.removeClass 'hide'
      @program.once 'exit', (code) =>
        console.log 'exit', code if atom.config.get('atom-terminal-panel.logConsole') or @specsMode
        @killBtn.addClass 'hide'
        @statusIcon.removeClass 'status-running'
        # removeClass @statusIcon, 'status-error'
        @program = null
        @statusIcon.addClass code == 0 and 'status-success' or 'status-error'
        @showCmd()
        @spawnProcessActive = false
      @program.on 'error', (err) =>
        console.log 'error' if atom.config.get('atom-terminal-panel.logConsole') or @specsMode
        @message(err.message)
        @showCmd()
        @statusIcon.addClass 'status-error'
      @program.stdout.on 'data', =>
        @flashIconClass 'status-info'
        @statusIcon.removeClass 'status-error'
      @program.stderr.on 'data', =>
        console.log 'stderr' if atom.config.get('atom-terminal-panel.logConsole') or @specsMode
        @flashIconClass 'status-error', 300

    catch err
      @message (err.message)
      @showCmd()
