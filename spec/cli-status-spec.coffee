CliStatus = require '../lib/cli-status'

# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

describe "CliStatus", ->
  activationPromise = null

  describe "when the terminal-panel:toggle event is triggered", ->
    it "attaches and then detaches the view", ->
      workspaceView = atom.views.getView(atom.workspace)
      expect(workspaceView.querySelector('.cli-status')).not.toExist()

      # This is an activation event, triggering it will cause the package to be
      # activated.

      waitsForPromise ->
        atom.packages.activatePackage('status-bar')
      waitsForPromise ->
        atom.packages.activatePackage('terminal-panel')

      runs ->
        expect(workspaceView.querySelector('.cli-status')).toExist()
        expect(workspaceView.querySelector('.cli-status')).not.toExist()

  describe "when cli-status is activated", ->
    it "should have configuration set up with defaults"

    waitsForPromise ->
        atom.packages.activatePackage('terminal-panel')

    runs ->
        expect(atom.config.get('terminal-panel.WindowHeight')).toBe(300)
