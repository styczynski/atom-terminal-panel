
{TextEditorView, View} = require 'atom-space-pen-views'
{spawn, exec} = require 'child_process'
ansihtml = require 'ansi-html-stream'
readline = require 'readline'
{addClass, removeClass} = require 'domutil'
{resolve, dirname, extname} = require 'path'
fs = require 'fs'
os = require 'os'
node_process = require 'process'
window.$ = window.jQuery = require('atom').$
lastOpenedView = null
CliCommandFinder = require './cli-command-finder'
core = require './cli-core'
stream = require 'stream'
iconv = require 'iconv-lite'
require '../ext/autocomplete.js'



module.exports =
class CommandOutputView extends View
  cwd: null
  streamsEncoding: 'iso-8859-3'
  _cmdintdel: 50
  echoOn: true
  inputLine: 50
  helloMessageShown: false
  minHeight: 250
  util: require './cli-terminal-util'
  currentInputBox: null
  currentInputBox: null
  currentInputBoxTmr: null
  keyCodes: {
    enter: 13
    arrowUp: 38
    arrowDown: 40
    arrowLeft: 37
    arrowRight: 39
  }
  @content: ->
    @div tabIndex: -1, class: 'panel cli-status panel-bottom', =>
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
      @div class: 'cli-panel-body', =>
        @pre class: "terminal", outlet: "cliOutput"

  localCommandAtomBindings: []
  localCommands:
    "encode":
      "description": "Change encoding."
      "command": (state, args)->
        encoding = args[0]
        state.streamsEncoding = encoding
        state.message 'Changed encoding to '+encoding
        return null
    "ls":
      "description": "Lists files in the current directory."
      "command": (state, args)->
        state.commandLineNotCounted()
        if not state.ls args
          return 'The directory is inaccessible.'
          return null
    "clear":
      "description": "Clears the console output."
      "command": (state, args)->
        state.commandLineNotCounted()
        state.clear()
        return null
    "echo":
      "description": "Prints the message to the output."
      "command": (state, args)->
        if args?
          state.message args.join(' ') + '\n'
          return null
        else
          state.message '\n'
          return null
    "print":
      "description": "Stringifies given parameters."
      "command": (state, args)-> return JSON.stringify(args)
    "cd":
      "description": "Moves to the specified directory."
      "command": (state, args)-> state.cd args
    "new":
      "description": "Creates a new file and opens it in the editor view."
      "command": (state, args)->
        if args == null || args == undefined
          atom.workspaceView.trigger 'application:new-file'
          return null
        file_name = state.replaceAll '\"', '', args[0]
        if file_name == null || file_name == undefined
          atom.workspaceView.trigger 'application:new-file'
          return null
        else
          file_path = state.resolvePath file_name
          fs.closeSync(fs.openSync(file_path, 'w'))
          state.delay () ->
            atom.workspaceView.open file_path
          return state.consoleLink file_path
    "rm":
      "description": "Removes the given file."
      "command": (state, args)->
        filepath = state.resolvePath args[0]
        fs.unlinkSync(filepath)
        return state.consoleLink filepath
    "memdump":
      "description": "Displays a list of all available internally stored commands."
      "command": (state, args)-> return state.getLocalCommandsMemdump()
    "?":
      "description": "Displays a list of all available internally stored commands."
      "command": (state, args)->
        return state.exec 'memdump', null, state
    "exit":
      "description": "Destroys the terminal session."
      "command": (state, args)->
        state.destroy()
    "update":
      "description": "Reloads the terminal configuration from terminal-commands.json"
      "command": (state, args)->
        core.reload()
        return (state.consoleLabel 'info', 'info') + (state.consoleText 'info', 'The console settings were reloaded')
    "reload":
      "description": "Reloads the atom window."
      "command": (state, args)->
        atom.reload()
    "edit":
      "description": "Opens the specified file in the editor view."
      "command": (state, args)->
        file_name = state.resolvePath args[0]
        state.delay () ->
          atom.workspaceView.open (file_name)
        return state.consoleLink file_name
    "link":
      "description": "Displays interactive link to the given file/directory."
      "command": (state, args)->
        file_name = state.resolvePath args[0]
        return state.consoleLink file_name
    "l":
      "description": "Displays interactive link to the given file/directory."
      "command": (state, args)->
        return state.exec 'link '+args[0], null, state
    "info":
      "description": "Prints the welcome message to the screen."
      "command": (state, args)->
        state.clear()
        state.showInitMessage true
        return null

  resolvePath: (path) ->
    path = @replaceAll '\"', '', path
    filepath = ''
    if path.match(/([A-Za-z]):/ig) != null
      filepath = path
    else
      filepath = @getCwd() + '/' + path
    filepath = @replaceAll '\\', '/', filepath
    return @replaceAll '\\', '/', (resolve filepath)

  reloadSettings: () ->
    @onCommand 'update'

  showSettings: () ->
    core.reload()
    setTimeout () =>
      panelPath = atom.packages.resolvePackagePath 'atom-terminal-panel'
      atomPath = resolve panelPath+'/../..'
      configPath = atomPath + '/terminal-commands.json'
      atom.workspaceView.open configPath
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

  putInputBox: () ->
    if @currentInputBoxTmr?
      clearInterval @currentInputBoxTmr
      @currentInputBoxTmr = null

    @cliOutput.find('.cli-dynamic-input-box').remove()
    prompt = @getCommandPrompt('')+" "
    @currentInputBox = $(
      '<div style="width: 100%; white-space:nowrap; overflow:hidden; display:inline-block;" class="cli-dynamic-input-box">' +
      prompt +
      '<div style="position:relative; top:5px; width: 100%; white-space:nowrap; overflow:hidden; display:inline-block;" class="terminal-input native-key-bindings"></div>' +
      '</div>'
    )

    @currentInputBox.keypress (e) =>
       code = e.keyCode or e.which
       if code == @keyCodes.enter
         @onCommand()

    @cliOutput.click () =>
      @focusInputBox()

    history = []
    if @currentInputBoxCmp?
      history = @currentInputBoxCmp.getInputHistory()
    inputComp = @currentInputBox.find '.terminal-input'

    @currentInputBoxCmp = inputComp.autocomplete {
      inputHistory: history
      inputWidth: '80%'
      showDropDown: atom.config.get 'atom-terminal-panel.enableConsoleSuggestionsDropdown'
    }
    options = @getCommandsNames()
    @currentInputBoxCmp.options = options
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

  init: () ->
    obj = require '../config/functional-commands-external'
    for key, value of obj
      @localCommands[key] = value
      @localCommands[key].source = 'external-functional'

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

    if core.getConfig()?
      toolbar = core.getConfig().toolbar
      if toolbar?
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

  parseSpecialStringTemplate: (prompt, values) ->
    cmd = null
    file = @getCurrentFilePath()
    if values?
      if values.cmd?
        cmd = values.cmd
      if values.file?
        file = values.file

    if not atom.config.get('atom-terminal-panel.parseSpecialTemplateTokens')
      return  @preserveOriginalPaths (prompt.replace /%\([^ ]*\)/ig, '')

    if prompt.indexOf('%') == -1
      return  @preserveOriginalPaths prompt

    for key, value of values
      if key != 'cmd' and key != 'file'
        prompt = @replaceAll "%(#{key})", value, prompt

    panelPath = atom.packages.resolvePackagePath 'atom-terminal-panel'
    atomPath = resolve panelPath+'/../..'

    prompt = @replaceAll '%(atom)', atomPath, prompt
    prompt = @replaceAll '%(path)', @getCwd(), prompt
    prompt = @replaceAll '%(file)', file, prompt
    prompt = @replaceAll '%(editor.path)', @getCurrentFileLocation(), prompt
    prompt = @replaceAll '%(editor.file)', @getCurrentFilePath(), prompt
    prompt = @replaceAll '%(editor.name)', @getCurrentFileName(), prompt
    prompt = @replaceAll '%(cwd)', @getCwd(), prompt
    prompt = @replaceAll '%(hostname)', os.hostname(), prompt
    prompt = @replaceAll '%(computer-name)', os.hostname(), prompt

    username = node_process.env.USERNAME or node_process.env.LOGNAME or node_process.env.USER
    prompt = @replaceAll '%(username)', username, prompt
    prompt = @replaceAll '%(user)', username, prompt

    homelocation = node_process.env.HOME or node_process.env.HOMEPATH or node_process.env.HOMEDIR
    prompt = @replaceAll '%(home)', homelocation, prompt

    osname = node_process.platform or node_process.env.OS
    prompt = @replaceAll '%(osname)', osname, prompt
    prompt = @replaceAll '%(os)', osname, prompt

    prompt = prompt.replace /%\(env\.[A-Za-z\*]*\)/ig, (match, text, urlId) =>
      nativeVarName = match
      nativeVarName = @replaceAll '%(env.', '', nativeVarName
      nativeVarName = nativeVarName.substring(0, nativeVarName.length-1)
      if nativeVarName == '*'
        ret = 'process.env {\n'
        for key, value of node_process.env
          ret += '\t' + key + '\n'
        ret += '}'
        return ret

      return node_process.env[nativeVarName]


    if cmd?
      prompt = @replaceAll '%(command)', cmd, prompt
    today = new Date()
    day = today.getDate()
    month = today.getMonth()+1
    year = today.getFullYear()
    minutes = today.getMinutes()
    hours = today.getHours()
    hours12 = today.getHours() % 12
    milis = today.getMilliseconds()
    seconds = today.getSeconds()
    ampm = 'am'
    ampmC = 'AM'

    if hours >= 12
      ampm = 'pm'
      ampmC = 'PM'

    prompt = @replaceAll '%(.day)', day, prompt
    prompt = @replaceAll '%(.month)', month, prompt
    prompt = @replaceAll '%(.year)', year, prompt
    prompt = @replaceAll '%(.hours)', hours, prompt
    prompt = @replaceAll '%(.hours12)', hours12, prompt
    prompt = @replaceAll '%(.minutes)', minutes, prompt
    prompt = @replaceAll '%(.seconds)', seconds, prompt
    prompt = @replaceAll '%(.milis)', milis, prompt

    if seconds < 10
      seconds = '0' + seconds
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
    if hours >= 12
      ampm = 'pm'
    if hours < 10
      hours = '0' + hours
    if hours12 < 10
      hours12 = '0' + hours12

    prompt = @replaceAll '%(day)', day, prompt
    prompt = @replaceAll '%(month)', month, prompt
    prompt = @replaceAll '%(year)', year, prompt
    prompt = @replaceAll '%(hours)', hours, prompt
    prompt = @replaceAll '%(hours12)', hours12, prompt
    prompt = @replaceAll '%(ampm)', ampm, prompt
    prompt = @replaceAll '%(AMPM)', ampmC, prompt
    prompt = @replaceAll '%(minutes)', minutes, prompt
    prompt = @replaceAll '%(seconds)', seconds, prompt
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

    # /%\(link:[^\n\t\[\]{}%\)\(]*\)/ig

    if prompt.indexOf('%(link:') != -1
      throw 'Error:\nUsage of %(link:) is deprecated.\nUse %(link)target%(endlink) notation\ninstead of %(link:target)!\nAt: ['+prompt+']'

    prompt = prompt.replace /%\(link\)[^%]*%\(endlink\)/ig, (match, text, urlId) =>
      target = match
      target = @replaceAll '%(link)', '', target
      target = @replaceAll '%(endlink)', '', target
      # target = target.substring 0, target.length-1
      ret = @consoleLink target, true
      return ret

    prompt = prompt.replace /%\(\^[^\s\(\)]*\)/ig, (match, text, urlId) =>
      target = @replaceAll '%(^', '', match
      target = target.substring 0, target.length-1

      if target == ''
        return '</font>'
      else if target.charAt(0) == '#'
        return "<font style=\"color:#{target};\">"
      else if target == 'b' or target == 'bold'
        return "<font style=\"font-weight:bold;\">"
      else if target == 'u' or target == 'underline'
        return "<font style=\"text-decoration:underline;\">"
      else if target == 'i' or target == 'italic'
        return "<font style=\"font-style:italic;\">"
      else if target == 'l' or target == 'line-through'
        return "<font style=\"text-decoration:line-through;\">"
      return ''

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

    return @preserveOriginalPaths prompt


  getCommandPrompt: (cmd) ->
    return @parseTemplate atom.config.get('atom-terminal-panel.commandPrompt'), {cmd: cmd}

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
    return  @replaceAll(@getCurrentFileName(), "", @getCurrentFilePath())

  getCurrentFilePath: ()->
    te = atom.workspace.getActiveTextEditor()
    if te?
      if te.getPath()?
        return te.getPath()

    return null
    ###editor = atom.workspace.getActivePaneItem()
    if editor == null || editor == undefined
      return null
    if editor?.buffer == undefined
      return null
    file = editor?.buffer.file
    if file == null || file == undefined
      return null
    return file?.path###

  parseTemplate: (text, vars) ->
    ret = @parseSpecialStringTemplate text, vars
    ret = @replaceAll '%(file-original)', @getCurrentFilePath(), ret
    ret = @replaceAll '%(cwd-original)', @getCwd(), ret
    ret = @replaceAll '&fs;', '/', ret
    ret = @replaceAll '&bs;', '\\', ret
    return ret

  parseExecToken__: (cmd, args, strArgs) ->
    cmd = @parseTemplate cmd, {file:@getCurrentFilePath()}
    if strArgs?
      cmd = @replaceAll "%(*)", strArgs, cmd
    cmd = @replaceAll "%(*^)", (@replaceAll "%(*^)", "", cmd), cmd
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
    if cmdStr instanceof Array
      ret = ''
      for com in cmdStr
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
      args = @util.dir args, @getCwd()
      cmd = args.shift()

      command = null
      if @isCommandEnabled(cmd)
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
        if atom.config.get('atom-terminal-panel.enableExtendedCommands')
          if @isCommandEnabled(cmd)
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
          return null

  compile: () ->
    @clear()
    @exec('compile', null, this)

  run: () ->
    @exec('run', null, this)

  isCommandEnabled: (name) ->
    disabledCommands = atom.config.get('atom-terminal-panel.disabledExtendedCommands')
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
    global_vars = {
      "%(atom)" : "atom directory."
      "%(path)" : "current working directory"
      "%(file)" : "currenly opened file in the editor"
      "%(editor.path)" : "path of the file currently opened in the editor"
      "%(editor.file)" : "full path of the file currently opened in the editor"
      "%(editor.name)" : "name of the file currently opened in the editor"
      "%(cwd)" : "current working directory"
      "%(hostname)" : "computer name"
      "%(computer-name)" : "computer name"
      "%(username)" : "currently logged in user"
      "%(user)" : "currently logged in user"
      "%(home)" : "home directory of the user"
      "%(osname)" : "name of the operating system"
      "%(os)" : "name of the operating system"
      "%(env.*)" : "list of all available native environment variables"
      "%(.day)" : "current date: day number (without leading zeros)"
      "%(.month)" : "current date: month number (without leading zeros)"
      "%(.year)" : "current date: year (without leading zeros)"
      "%(.hours)" : "current date: hour 24-format (without leading zeros)"
      "%(.hours12)" : "current date: hour 12-format (without leading zeros)"
      "%(.minutes)" : "current date: minutes (without leading zeros)"
      "%(.seconds)" : "current date: seconds (without leading zeros)"
      "%(.milis)" : "current date: miliseconds (without leading zeros)"
      "%(day)" : "current date: day number"
      "%(month)" : "current date: month number"
      "%(year)" : "current date: year"
      "%(hours)" : "current date: hour 24-format"
      "%(hours12)" : "current date: hour 12-format"
      "%(minutes)" : "current date: minutes"
      "%(seconds)" : "current date: seconds"
      "%(milis)" : "current date: miliseconds"
      "%(ampm)" : "displays am/pm (12-hour format)"
      "%(AMPM)" : "displays AM/PM (12-hour format)"
      "%(line)" : "input line number"
      "%(disc)" : "current working directory disc name"
      "%(label:TYPE:TEXT": "(styling-annotation) creates a label of the specified type"
      "%(tooltip:TEXT:content:CONTENT)": "(styling-annotation) creates a tooltip message"
      "%(link)": "(styling-annotation) starts the file link - see %(endlink)"
      "%(endlink)": "(styling-annotation) ends the file link - see %(link)"
      "%(^)": "(styling-annotation) ends text formatting"
      "%(^COLOR)": "(styling-annotation) creates coloured text"
      "%(^b)": "(styling-annotation) creates bolded text"
      "%(^bold)": "(styling-annotation) creates bolded text"
      "%(^i)": "(styling-annotation) creates italics text"
      "%(^italics)": "(styling-annotation) creates italics text"
      "%(^u)": "(styling-annotation) creates underline text"
      "%(^underline)": "(styling-annotation) creates underline text"
      "%(^l)": "(styling-annotation) creates a line through the text"
      "%(^line-trough)": "(styling-annotation) creates a line through the text"
      "%(path:INDEX)": "refers to the %(path) components"
      "%(*)": "(only user-defined commands) refers to the all passed parameters"
      "%(*^)": "(only user-defined commands) refers to the full command string"
      "%(NUMBER)": "(only user-defined commands) refers to the passed parameters"
    }

    for key, value of node_process.env
      global_vars['%(env.'+key+')'] = "access native environment variable: "+key

    cmd = []
    for cmd_name, cmd_body of @localCommands
      cmd.push {
        name: cmd_name
        description: cmd_body.description
        source: cmd_body.source or 'internal'
      }
    for cmd_name, cmd_body of core.getUserCommands()
      cmd.push {
        name: cmd_name
        description: cmd_body.description
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
    cmd_forbd = atom.config.get 'atom-terminal-panel.disabledExtendedCommands'
    for cmd_item in cmd
      if cmd_item.name in cmd_forbd
      else
        cmd_.push cmd_item

    return cmd_

  getCommandsNames: () ->
    cmds = @getCommandsRegistry()
    cmd_names = []
    for cmd in cmds
      cmd_names.push cmd.name
    return cmd_names

  getLocalCommandsMemdump: () ->
    cmd = @getCommandsRegistry()
    commandFinder = new CliCommandFinder cmd
    commandFinderPanel = atom.workspace.addModalPanel(item: commandFinder)
    commandFinder.shown commandFinderPanel, this

    return

    ###
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
    ###

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
    if atom.config.get 'atom-terminal-panel.enableConsoleStartupInfo' or forceShow
      hello_message = @consolePanel 'ATOM Terminal', 'Please enter new commands to the box below.<br>The console supports special anotattion like: %(path), %(file), %(link)file.something%(endlink).<br>It also supports special HTML elements like: %(tooltip:A:content:B) and so on.<br>Hope you\'ll enjoy the terminal.'
      @rawMessage hello_message
      @helloMessageShown = true
    return this

  onCommand: (inputCmd) ->
    if not inputCmd?
      inputCmd = @readInputBox()

    @inputLine++
    inputCmd = @parseSpecialStringTemplate inputCmd

    if @echoOn
      @message "\n"+@getCommandPrompt(inputCmd)+" "+inputCmd+"\n", false

    ret = @exec inputCmd, null, this
    if ret?
      @message ret + '\n'

    @scrollToBottom()
    @putInputBox()
    setTimeout () =>
      @putInputBox()
    , 250
    return null

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
      return @onCommand()

  clear: ->
    @cliOutput.empty()
    @message '\n'
    @putInputBox()

  adjustWindowHeight: ->
    maxHeight = atom.config.get('atom-terminal-panel.WindowHeight')
    @cliOutput.css("max-height", "#{maxHeight}px")

  showCmd: ->
    @focusInputBox()
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
    if atom.config.get('atom-terminal-panel.moveToCurrentDirOnOpen')
      @moveToCurrentDirectory()
    if atom.config.get('atom-terminal-panel.moveToCurrentDirOnOpenLS')
      @clear()
      @execDelayedCommand @_cmdintdel, 'ls', null, this

    @lastLocation = atom.workspace.getActivePane()
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
    fs.stat dir, (err, stat) =>
      if err
        if err.code == 'ENOENT'
          return @errorMessage "cd: #{args[0]}: No such file or directory"
        return @errorMessage err.message
      if not stat.isDirectory()
        return @errorMessage "cd: not a directory: #{args[0]}"
      @cwd = dir
      @putInputBox()


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
    if not atom.config.get 'atom-terminal-panel.enableConsoleLabels'
      return text

    if not text?
      text = type

    if type == 'badge'
      return '<span class="badge">'+text+'</span>'
    if type == 'default'
      return '<span class="inline-block highlight">'+text+'</span>'
    if type == 'primary'
      return '<span class="label label-primar">'+text+'</span>'
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
    name_tokens = @replaceAll filename, '', name_tokens
    name_tokens = name_tokens.split ':'
    fileline = name_tokens[0]
    filecolumn = name_tokens[1]

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

    filepath = @resolvePath filename

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

    href = 'file:///' + @replaceAll('\\', '/', filepath)

    classes.push 'cli-tooltip'

    exattrs = []
    if fileline?
      exattrs.push 'data-line="'+fileline+'"'
    if filecolumn?
      exattrs.push 'data-column="'+filecolumn+'"'

    filepath_tooltip = @replaceAll '\\', '/', filepath
    filepath = @replaceAll '\\', '/', filepath
    ["<font class=\"file-extension\"><#{wrapper_class} #{exattrs.join ' '} tooltip=\"\" data-targetname=\"#{filename}\" data-targettype=\"#{target_type}\" data-target=\"#{filepath}\" class=\"#{classes.join ' '}\" data-toggle=\"tooltip\" data-placement=\"top\" title=\"#{filepath_tooltip}\" >#{filename}</#{wrapper_class}></font>", stat, filename]

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
    text = @replaceAll '/', '&fs;', text
    text = @replaceAll '\\', '&bs;', text
    return text


  parseMessage: (message, matchSpec=true) ->
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
            cwdE = @replaceAll '/', '\\', @getCwd()
            regexString ='(' + (@escapeRegExp cwdN) + '|' + (@escapeRegExp cwdE) + ')\\\\([^\\s:#$%^&!:]| )+\\.?([^\\s:#$@%&\\*\\^!0-9:\\.+\\-,\\\\\\/\"]| )*'
            regex = new RegExp(regexString, 'ig')
            message = message.replace regex, (match, text, urlId) =>
              return @parseSpecialStringTemplate atom.config.get('atom-terminal-panel.textReplacementFileAdress'), {file:match}
      if atom.config.get('atom-terminal-panel.textReplacementCurrentFile')?
        if atom.config.get('atom-terminal-panel.textReplacementCurrentFile') != ''
          path = @getCurrentFilePath()
          regex = new RegExp @escapeRegExp(path), 'g'
          message = message.replace regex, (match, text, urlId) =>
            return @parseSpecialStringTemplate atom.config.get('atom-terminal-panel.textReplacementCurrentFile'), {file:match}
      message = @preserveOriginalPaths message
      if atom.config.get('atom-terminal-panel.textReplacementCurrentPath')?
        if atom.config.get('atom-terminal-panel.textReplacementCurrentPath') != ''
          path = @getCwd()
          regex = new RegExp @escapeRegExp(path), 'g'
          message = message.replace regex, (match, text, urlId) =>
            return @parseSpecialStringTemplate atom.config.get('atom-terminal-panel.textReplacementCurrentPath'), {file:match}


    message = @replaceAll '%(file-original)', @getCurrentFilePath(), message
    message = @replaceAll '%(cwd-original)', @getCwd(), message
    message = @replaceAll '&fs;', '/', message
    message = @replaceAll '&bs;', '\\', message

    rules = core.getConfig().rules
    for key, value of rules
      matchExp = key
      replExp = '%(content)'
      matchAllLine = false
      matchNextLines = 0

      if value.match?
        if value.match.replace?
          replExp = value.match.replace
        if value.match.matchLine?
          matchAllLine = value.match.matchLine
        if value.match.matchNextLines?
          matchNextLines = value.match.matchNextLines

      if matchAllLine
        matchExp = '.*' + matchExp

      for i in [0..matchNextLines] by 1
        matchExp = matchExp + '[\\r\\n].*';

      regex = new RegExp(matchExp, 'igm')

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

    message = @replaceAll '%(file-original)', @getCurrentFilePath(), message
    message = @replaceAll '%(cwd-original)', @getCwd(), message
    message = @replaceAll '&fs;', '/', message
    message = @replaceAll '&bs;', '\\', message

    return message

  rawMessage: (message) ->
    @cliOutput.append message
    @showCmd()
    removeClass @statusIcon, 'status-error'
    addClass @statusIcon, 'status-success'
    # @parseSpecialNodes()

  message: (message, matchSpec=true) ->
    mes = message.split '%(break)'
    if mes.length > 1
      for m in mes
        @message m
      return
    else
      mes = mes[0]

    mes = @parseMessage message, matchSpec
    # mes = @replaceAll '<', '&lt;', mes
    # mes = @replaceAll '>', '&gt;', mes
    @cliOutput.append mes
    @showCmd()
    removeClass @statusIcon, 'status-error'
    addClass @statusIcon, 'status-success'
    @parseSpecialNodes()
    @scrollToBottom()
    @putInputBox()

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
    # @cmdEditor.hide()
    # htmlStream = ansihtml()
    htmlStream = iconv.decodeStream @streamsEncoding
    htmlStream.on 'data', (data) =>
      @cliOutput.append data
      @scrollToBottom()
    try
      # @program = spawn cmd, args, stdio: 'pipe', env: process.env, cwd: @getCwd()
      @program = exec inputCmd, stdio: 'pipe', env: process.env, cwd: @getCwd()
      @program.stdin.pipe htmlStream
      @program.stdout.pipe htmlStream
      @program.stderr.pipe htmlStream
      # @program.stdout.setEncoding @streamsEncoding

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
