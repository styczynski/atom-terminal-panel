


describe "atom-terminal-panel Testing utils functionality", ->

  it "tests the \"utils\" module", ->
    require '../lib/atp-utils'

  it "tests \"include\" function", ->
    expect(()->include '../lib/atp-core').not.toThrow()

  it "tests the utils functionality", ->
    expect(window.generateRandomID).toBeDefined()
    expect(window.generateRandomID).not.toThrow()
    expect(window.generateRandomID()).not.toBeNull()
    expect(window.generateRandomID()).toBeDefined()
