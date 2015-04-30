
terminal = require '../lib/command-output-view'
core = require '../lib/cli-core'
CliStatusView = require '../lib/cli-status-view'

describe "atom-terminal-panel Testing parsing functionality", ->

  it "tests the console label parsing", ->
    t = core.init().createSpecsTerminal()
    expect(t.parseTemplate 'echo test %(label:badge:text:error)').toBe('echo test <span class="badge">error</span>')
    expect(t.parseTemplate 'echo test %(label:default:text:error)').toBe('echo test <span class="inline-block highlight">error</span>')
    expect(t.parseTemplate 'echo test %(label:primary:text:error)').toBe('echo test <span class="label label-primary">error</span>')
    expect(t.parseTemplate 'echo test %(label:success:text:error)').toBe('echo test <span class="inline-block highlight-success">error</span>')
    expect(t.parseTemplate 'echo test %(label:warning:text:error)').toBe('echo test <span class="inline-block highlight-warning">error</span>')
    expect(t.parseTemplate 'echo test %(label:danger:text:error)').toBe('echo test <span class="inline-block highlight-error">error</span>')
    expect(t.parseTemplate 'echo test %(label:error:text:error)').toBe('echo test <span class="inline-block highlight-error">error</span>')

  it "tests the console ability to remove unused variables", ->
    t = core.init().createSpecsTerminal()
    expect(t.parseTemplate '%(-9999999999)%(-100)%(-5)%(-4)%(-3)%(-2)%(-1)%(0)%(1)%(2)%(3)%(99999999)').toBe('')
    expect(t.parseTemplate '%(foo)%(bar)%(crap)%(0.009)%(nope)').toBe('')

  it "test the \"echo test\" command", (done) ->
    t = core.init().createSpecsTerminal()
