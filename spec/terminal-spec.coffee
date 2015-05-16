
describe "atom-terminal-panel Testing terminal functionality", ->

  atp = null
  [activationPromise, workspaceElement] = []

  tests =
    parseTemplateLabels:
      'echo test %(label:badge:text:error)': 'echo test <span class="badge">error</span>'
      'echo test %(label:default:text:error)': 'echo test <span class="inline-block highlight">error</span>'
      'echo test %(label:primary:text:error)': 'echo test <span class="label label-primary">error</span>'
      'echo test %(label:success:text:error)': 'echo test <span class="inline-block highlight-success">error</span>'
      'echo test %(label:warning:text:error)': 'echo test <span class="inline-block highlight-warning">error</span>'
      'echo test %(label:danger:text:error)': 'echo test <span class="inline-block highlight-error">error</span>'
      'echo test %(label:error:text:error)': 'echo test <span class="inline-block highlight-error">error</span>'
    parseTemplateUnusedVariables:
      '%(-9999999999)%(-100)%(-5)%(-4)%(-3)%(-2)%(-1)%(0)%(1)%(2)%(3)%(99999999)': ''
      '%(foo)%(bar)%(crap)%(0.009)%(nope)': ''
    util:
      dir: [
        [
          ["./a.txt", "b.txt"]
          "path"
          [ "path/a.txt", "b.txt" ]
        ]
        [
          ["./a.txt", "/non/relative/path/b.txt", "non/relative/path/c.txt"]
          "path"
          [ "path/a.txt", "C:/non/relative/path/b.txt", "non/relative/path/c.txt" ]
        ]
        [
          "./sample.sample.smpl"
          "E:/user/test/example/falsy/path"
          "E:/user/test/example/falsy/path/sample.sample.smpl"
        ]
      ]
      getFileName:
        'Z:/not/existing/strange/path/LOL/.././anything/test.lol.rar': 'test.lol.rar'
        'Z:/not/existing/path/to_the_file?/filename.b.c.d.extension': 'filename.b.c.d.extension'
        'C:/A/B/C/../../../D/EXAMPLE/PaTh/.file.txt': '.file.txt'
      getFilePath:
        'Z:/not/existing/strange/path/LOL/.././anything/test.lol.rar': 'Z:/not/existing/strange/path/LOL/.././anything/'
        'Z:/not/existing/path/to_the_file?/filename.b.c.d.extension': 'Z:/not/existing/path/to_the_file?/'
        'C:/A/B/C/../../../D/EXAMPLE/PaTh/.file.txt': 'C:/A/B/C/../../../D/EXAMPLE/PaTh/'
      mkdir: [
        ['__heeello', '__heeello/destiny']
        '__test'
        '__anything'
        '__.op'
      ]
      rename: [
        ['__.op', '__.ops']
        ['./__.ops', '__.op']
      ]
      rmdir: [
        '__anything'
        '__test'
        '__.op'
        ['__heeello/destiny', '__heeello']
      ]

  t = null
  initTerm = () =>
    workspaceElement = atom.views.getView(atom.workspace)
    activationPromise = atom.packages.activatePackage('atom-terminal-panel')
    atp = atom.packages.getLoadedPackage('atom-terminal-panel').mainModule
    t = atp.getPanel().createCommandView()

  executeCommand = (name, callback) ->
    atom.commands.dispatch(workspaceElement, 'atom-terminal-panel:'+name)
    waitsForPromise -> activationPromise
    runs(callback)

  beforeEach ->
    initTerm()

  it "tests basic modules presence", ->
    initTerm()

  it "tests the console initialization (in the specs mode)", ->
    expect(initTerm).not.toThrow()

  it "tests the terminal events dispatching", ->
    executeCommand 'toggle', ->
    executeCommand 'new', ->
    executeCommand 'next', ->
    executeCommand 'prev', ->
    executeCommand 'toggle-autocompletion', ->
    executeCommand 'destroy', ->
    executeCommand 'new', ->

  it "tests the console label parsing", ->
    for k, v in tests.parseTemplateLabels
      expect(t.parseTemplate k).toBe(v)

  it "tests the console ability to remove unused variables", ->
    for k, v in tests.parseTemplateUnusedVariables
      expect(t.parseTemplate k).toBe(v)

  it "test the \"echo test\" command", ->
    expect(()->t.exec "echo test").not.toThrow()

  it "test the terminal.util.dir calls", ->
    t.cd '/'
    expect(t.util.os).not.toThrow()
    for v in tests.util.dir
      expect(t.util.dir(v[0], v[1])).toEqual(v[2])
    for k, v in tests.util.getFileName
      expect(t.util.getFileName(k)).toEqual(v)
    for k, v in tests.util.getFilePath
      expect(t.util.getFilePath(k)).toEqual(v)


  it "test the terminal.util filesystem operations", ->
    t.cd '/'
    for k in tests.util.rmdir
      try
        t.util.rmdir(k)
      catch e

    for k in tests.util.mkdir
      expect(()->t.util.mkdir(k)).not.toThrow()
    for k in tests.util.rename
      expect(()->t.util.rename(k[0], k[1])).not.toThrow()
    for k in tests.util.rmdir
      expect(()->t.util.rmdir(k)).not.toThrow()

  it "tests the terminal choosen commands", ->
    expect(()->t.onCommand 'ls').not.toThrow()
    expect(()->t.onCommand 'info').not.toThrow()
    expect(()->t.onCommand 'memdump').not.toThrow()

  it "tests the terminal cwd (cp)", ->
    expect(()->t.cd '/').not.toThrow()
    cwd = t.getCwd()
    expect(cwd).toEqual(t.util.dir '/', '')
    try t.util.rmdir('/example_dir') catch e
    expect(()->t.util.mkdir('/example_dir')).not.toThrow()
    expect(()->t.cd ['/example_dir']).not.toThrow()
    expect(t.getCwd()).toEqual(t.util.dir './example_dir', cwd)

  it "tests terminal.removeQuotes()", ->
    expect(t.removeQuotes('\"Some examples3\'2\"1\'->?@#($)*@)#)\"\"\'asdsad\'')).toEqual('Some examples321->?@#($)*@)#)asdsad')


###
  t = core.init().createSpecsTerminal()
  tests =
    units:
      'tests the console label parsing':
        expect: [
          ['call', t.parseTemplate, 'toBe', 'echo test <span class="badge">error</span>']
        ]


  runTest = (tests) ->
    console.log 'called.runTest'
    if tests.init?
      tests.init.apply(v, [])
    for k, v of tests.units
      it k, ->
        console.log 'called.it'
        if v.init?
          v.init.apply(v, [])
        if v.beforeEach?
          beforeEach v.beforeEach
        if v.afterEach?
          afterEach v.afterEach
        for unit in v.expect
          expectation = unit
          value = null
          expectationStepsLength = expectation.length
          for i in [0..expectationStepsLength-1] by 1
            step = expectation[i]
            if step == 'call'
              if expectation[i+1] instanceof Array
                functname = expectation[i+1][0]
                expectation[i+1].shift()
                value = expect(functname.apply(null, expectation[i+1]))
              else
                value = expect((expectation[i+1])())
              ++i
              continue
            else if step == 'value'
              value = expect(expectation[i+1])
              ++i
              continue
            else if step == 'and'
              value = value.and
            else if step == 'throwError'
              value = value.throwError(expectation[i+1])
              ++i
              continue
            else if step == 'callThrough'
              value = value.callThrough()
            else if step == 'stub'
              value = value.stub()
            else if step == 'not'
              value = value.not
            else if step == 'toThrow'
              value = value.toThrow()
            else if step == 'toBe'
              value = value.toBe(expectation[i+1])
              ++i
              continue
            else if step == 'toBeNull'
              value = value.toBeNull()
            else if step == 'toEqual'
              value = value.toEqual(expectation[i+1])
              ++i
              continue
            else if step == 'toMatch'
              value = value.toMatch(expectation[i+1])
              ++i
              continue
            else if step == 'toThrowError'
              value = value.toThrowError(expectation[i+1])
              ++i
              continue
            else if step == 'toHaveBeenCalled'
              value = value.toHaveBeenCalled()
            else if step == 'toHaveBeenCalledWith'
              value = value.toHaveBeenCalledWith.apply(this, expectation[i+1])
              ++i
              continue
            else if step == 'toBeDefined'
              value = value.toBeDefined()
            else if step == 'toBeUndefined'
              value = value.toBeUndefined()

  runTest tests
###
