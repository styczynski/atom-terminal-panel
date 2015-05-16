###
  Atom-terminal-panel
  Copyright by isis97
  MIT licensed

  Class containing all builtin variables.
###

{$} = include 'atom-space-pen-views'
{resolve, dirname, extname} = include 'path'
os = include 'os'

$.event.special.destroyed = {
  remove: (o) ->
    if o.handler
      o.handler()
}

class BuiltinVariables
  list:
    "%(project.root)" : "first currently opened project directory"
    "%(project:INDEX)" : "n-th currently opened project directory"
    "%(project.count)" : "number of currently opened projects"
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
    "%(INDEX)": "(only user-defined commands) refers to the passed parameters"
    "%(raw)": "Makes the entire expression evaluated only when printing to output (delayed-evaluation)"
    "%(dynamic)": "Indicates that the expression should be dynamically updated."
  customVariables: []

  putVariable: (entry) ->
    @customVariables.push entry
    @list['%('+entry.name+')'] = entry.description or ""

  removeAnnotation: (consoleInstance, prompt) ->
    return prompt.replace /%\((?!cwd-original\))(?!file-original\))([^\(\)]*)\)/img, (match, text, urlId) =>
      return ''

  parseHtml: (consoleInstance, prompt, values, startRefreshTask=true) ->
    o = @parseFull(consoleInstance, prompt, values, startRefreshTask)
    if o.modif?
      o.modif (i) =>
        i = consoleInstance.util.replaceAll '%(file-original)', consoleInstance.getCurrentFilePath(), i
        i = consoleInstance.util.replaceAll '%(cwd-original)', consoleInstance.getCwd(), i
        i = consoleInstance.util.replaceAll '&fs;', '/', i
        i = consoleInstance.util.replaceAll '&bs;', '\\', i
        return i
    if o.getHtml?
      return o.getHtml()
    return o

  parse: (consoleInstance, prompt, values) ->
    o = @parseFull(consoleInstance, prompt, values)
    if o.getText?
      return o.getText()
    return o

  parseFull: (consoleInstance, prompt, values, startRefreshTask=true) ->

    orig = prompt
    text = ''
    isDynamicExpression = false
    dynamicExpressionUpdateDelay = 100

    if not consoleInstance?
      return ''
    if not prompt?
      return ''

    cmd = null
    file = consoleInstance.getCurrentFilePath()
    if values?
      if values.cmd?
        cmd = values.cmd
      if values.file?
        file = values.file

    if (not atom.config.get('atom-terminal-panel.parseSpecialTemplateTokens')) and (not consoleInstance.specsMode)
      consoleInstance.preserveOriginalPaths (prompt.replace /%\([^ ]*\)/ig, '')

    if prompt.indexOf('%') == -1
      consoleInstance.preserveOriginalPaths prompt

    prompt.replace /%\(dynamic:?([0-9]+)?\)/ig, (match, p1) =>
      if p1?
        dynamicExpressionUpdateDelay = parseInt(p1)
      isDynamicExpression = true
      return ''

    for key, value of values
      if key != 'cmd' and key != 'file'
        prompt = consoleInstance.util.replaceAll "%(#{key})", value, prompt

    if prompt.indexOf('%(raw)') == -1
      panelPath = atom.packages.resolvePackagePath 'atom-terminal-panel'
      atomPath = resolve panelPath+'/../..'

      prompt = consoleInstance.util.replaceAll '%(atom)', atomPath, prompt
      prompt = consoleInstance.util.replaceAll '%(path)', consoleInstance.getCwd(), prompt
      prompt = consoleInstance.util.replaceAll '%(file)', file, prompt
      prompt = consoleInstance.util.replaceAll '%(editor.path)', consoleInstance.getCurrentFileLocation(), prompt
      prompt = consoleInstance.util.replaceAll '%(editor.file)', consoleInstance.getCurrentFilePath(), prompt
      prompt = consoleInstance.util.replaceAll '%(editor.name)', consoleInstance.getCurrentFileName(), prompt
      prompt = consoleInstance.util.replaceAll '%(cwd)', consoleInstance.getCwd(), prompt
      prompt = consoleInstance.util.replaceAll '%(hostname)', os.hostname(), prompt
      prompt = consoleInstance.util.replaceAll '%(computer-name)', os.hostname(), prompt

      username = process.env.USERNAME or process.env.LOGNAME or process.env.USER
      prompt = consoleInstance.util.replaceAll '%(username)', username, prompt
      prompt = consoleInstance.util.replaceAll '%(user)', username, prompt

      homelocation = process.env.HOME or process.env.HOMEPATH or process.env.HOMEDIR
      prompt = consoleInstance.util.replaceAll '%(home)', homelocation, prompt

      osname = process.platform or process.env.OS
      prompt = consoleInstance.util.replaceAll '%(osname)', osname, prompt
      prompt = consoleInstance.util.replaceAll '%(os)', osname, prompt

      prompt = prompt.replace /%\(env\.[A-Za-z_\*]*\)/ig, (match, text, urlId) =>
        nativeVarName = match
        nativeVarName = consoleInstance.util.replaceAll '%(env.', '', nativeVarName
        nativeVarName = nativeVarName.substring(0, nativeVarName.length-1)
        if nativeVarName == '*'
          ret = 'process.env {\n'
          for key, value of process.env
            ret += '\t' + key + '\n'
          ret += '}'
          return ret

        return process.env[nativeVarName]


      if cmd?
        prompt = consoleInstance.util.replaceAll '%(command)', cmd, prompt
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

      prompt = consoleInstance.util.replaceAll '%(.day)', day, prompt
      prompt = consoleInstance.util.replaceAll '%(.month)', month, prompt
      prompt = consoleInstance.util.replaceAll '%(.year)', year, prompt
      prompt = consoleInstance.util.replaceAll '%(.hours)', hours, prompt
      prompt = consoleInstance.util.replaceAll '%(.hours12)', hours12, prompt
      prompt = consoleInstance.util.replaceAll '%(.minutes)', minutes, prompt
      prompt = consoleInstance.util.replaceAll '%(.seconds)', seconds, prompt
      prompt = consoleInstance.util.replaceAll '%(.milis)', milis, prompt

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

      prompt = consoleInstance.util.replaceAll '%(day)', day, prompt
      prompt = consoleInstance.util.replaceAll '%(month)', month, prompt
      prompt = consoleInstance.util.replaceAll '%(year)', year, prompt
      prompt = consoleInstance.util.replaceAll '%(hours)', hours, prompt
      prompt = consoleInstance.util.replaceAll '%(hours12)', hours12, prompt
      prompt = consoleInstance.util.replaceAll '%(ampm)', ampm, prompt
      prompt = consoleInstance.util.replaceAll '%(AMPM)', ampmC, prompt
      prompt = consoleInstance.util.replaceAll '%(minutes)', minutes, prompt
      prompt = consoleInstance.util.replaceAll '%(seconds)', seconds, prompt
      prompt = consoleInstance.util.replaceAll '%(milis)', milis, prompt
      prompt = consoleInstance.util.replaceAll '%(line)', consoleInstance.inputLine+1, prompt

      projectPaths = atom.project.getPaths()
      projectPathsCount = projectPaths.length - 1
      prompt = consoleInstance.util.replaceAll '%(project.root)', projectPaths[0], prompt
      prompt = consoleInstance.util.replaceAll '%(project.count)', projectPaths.length, prompt
      for i in [0..projectPathsCount] by 1
        breadcrumbIdFwd = i-projectPathsCount-1
        breadcrumbIdRwd = i
        prompt = consoleInstance.util.replaceAll "%(project:#{breadcrumbIdFwd})", projectPaths[i], prompt
        prompt = consoleInstance.util.replaceAll "%(project:#{breadcrumbIdRwd})", projectPaths[i], prompt

      pathBreadcrumbs = consoleInstance.getCwd().split /\\|\//ig
      pathBreadcrumbs[0] = pathBreadcrumbs[0].charAt(0).toUpperCase() + pathBreadcrumbs[0].slice(1)
      disc = consoleInstance.util.replaceAll ':', '', pathBreadcrumbs[0]
      prompt = consoleInstance.util.replaceAll '%(disc)', disc, prompt

      pathBreadcrumbsSize = pathBreadcrumbs.length - 1
      for i in [0..pathBreadcrumbsSize] by 1
        breadcrumbIdFwd = i-pathBreadcrumbsSize-1
        breadcrumbIdRwd = i
        prompt = consoleInstance.util.replaceAll "%(path:#{breadcrumbIdFwd})", pathBreadcrumbs[i], prompt
        prompt = consoleInstance.util.replaceAll "%(path:#{breadcrumbIdRwd})", pathBreadcrumbs[i], prompt

      prompt = prompt.replace /%\(tooltip:[^\n\t\[\]{}%\)\(]*\)/ig, (match, text, urlId) =>
        target = consoleInstance.util.replaceAll '%(tooltip:', '', match
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
        target = consoleInstance.util.replaceAll '%(link)', '', target
        target = consoleInstance.util.replaceAll '%(endlink)', '', target
        # target = target.substring 0, target.length-1
        ret = consoleInstance.consoleLink target, true
        return ret

      prompt = prompt.replace /%\(\^[^\s\(\)]*\)/ig, (match, text, urlId) =>
        target = consoleInstance.util.replaceAll '%(^', '', match
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

      if (atom.config.get 'atom-terminal-panel.enableConsoleLabels') or consoleInstance.specsMode
        prompt = prompt.replace /%\(label:[^\n\t\[\]{}%\)\(]*\)/ig, (match, text, urlId) =>
          target = consoleInstance.util.replaceAll '%(label:', '', match
          target = target.substring 0, target.length-1
          target_tokens = target.split ':text:'
          target = target_tokens[0]
          content = target_tokens[1]
          return consoleInstance.consoleLabel target, content
      else
        prompt = prompt.replace /%\(label:[^\n\t\[\]{}%\)\(]*\)/ig, (match, text, urlId) =>
          target = consoleInstance.util.replaceAll '%(label:', '', match
          target = target.substring 0, target.length-1
          target_tokens = target.split ':text:'
          target = target_tokens[0]
          content = target_tokens[1]
          return content

      for entry in @customVariables
        if prompt.indexOf('%('+entry.name+')') > -1
          repl = entry.variable(consoleInstance)
          if repl?
            prompt = consoleInstance.util.replaceAll '%('+entry.name+')', repl, prompt

      preservedPathsString = consoleInstance.preserveOriginalPaths prompt
      text = @removeAnnotation( consoleInstance, preservedPathsString )
    else
      text = prompt
      #text = consoleInstance.util.replaceAll '%(raw)', '', prompt

    o = {
      enclosedVarInstance: null
      text: text
      isDynamicExpression: isDynamicExpression
      dynamicExpressionUpdateDelay: dynamicExpressionUpdateDelay
      orig: orig
      textModifiers: []
      modif: (modifier) ->
        @textModifiers.push modifier
        return this
      runTextModifiers: (input) ->
        for i in [0..@textModifiers.length-1] by 1
          input = @textModifiers[i](input) or input
        return input
      getText: () ->
        return @runTextModifiers(@text)
      getHtml: () ->
        htmlObj = $('<span>'+@runTextModifiers(@text)+'</span>')
        taskRunning = false
        if not window.taskWorkingThreadsNumber?
          window.taskWorkingThreadsNumber = 0

        refresh = () =>
          t = @enclosedVarInstance.parseHtml(consoleInstance, @orig, values, false)
          htmlObj.html('')
          htmlObj.append(t)
        refreshTask = () =>
          if @dynamicExpressionUpdateDelay<=0 or not taskRunning
            --window.taskWorkingThreadsNumber
            #console.log 'Active threads: '+window.taskWorkingThreadsNumber
            return
          setTimeout () =>
            refresh()
            refreshTask()
          ,@dynamicExpressionUpdateDelay
        if startRefreshTask and @isDynamicExpression
          taskRunning = true
          htmlObj.bind 'destroyed', () ->
            taskRunning = false
          ++window.taskWorkingThreadsNumber
          #console.log 'Active threads: '+window.taskWorkingThreadsNumber
          refreshTask()
        return htmlObj
    }
    m = (i) ->
      i = consoleInstance.util.replaceAll '%(file-original)', consoleInstance.getCurrentFilePath(), i
      i = consoleInstance.util.replaceAll '%(cwd-original)', consoleInstance.getCwd(), i
      i = consoleInstance.util.replaceAll '&fs;', '/', i
      i = consoleInstance.util.replaceAll '&bs;', '\\', i
      return i
    o.modif m
    o.enclosedVarInstance = this
    return o

module.exports =
  new BuiltinVariables()
