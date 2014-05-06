CliStatus = require '../lib/cli-status'

# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

describe "CliStatus", ->
  activationPromise = null

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    activationPromise = atom.packages.activatePackage('cliStatus')

  describe "when the cli-status:toggle event is triggered", ->
    it "attaches and then detaches the view", ->
      expect(atom.workspaceView.find('.cli-status')).not.toExist()

      # This is an activation event, triggering it will cause the package to be
      # activated.
      atom.workspaceView.trigger 'cli-status:toggle'

      waitsForPromise ->
        activationPromise

      runs ->
        expect(atom.workspaceView.find('.cli-status')).toExist()
        atom.workspaceView.trigger 'cli-status:toggle'
        expect(atom.workspaceView.find('.cli-status')).not.toExist()

  describe "when cli-status is activated", ->
    it "should have configuration set up with defaults"

    waitsForPromise ->
      activationPromise

    runs ->
        expect(atom.config.get('terminal-status.WindowHeight')).toBe(300)
