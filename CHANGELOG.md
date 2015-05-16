## Changelog
* v4.4.4
  * Added ability to use Atom icons instead of the terminal defaults
    * Works well with UI themes changing file icons!
  * Rewritten some old code / developed better specs
  * Added dynamic suggestions for files and directories
  * Made the suggestion box less distracting (press the `ctrl` - `atom-terminal-panel:toggle-autocompletion` to show the suggestions drop down list; the live one-line suggestions are active all the time)
  * Added dynamic variables
    * Type `echo %(raw) %(dynamic) %(os.uptime)` and see what happens! :)
* v4.4.3
  * Repaired deprecated calls.
  * Rewritten some part of the code.
  * Removed some serious bugs.
  * Started to make working `specs`.
* v4.4.2
  * Added missing dependencies.
* v4.4.1
  * Added ability to bind the keys to the commands! :D
  * Made the terminal resizeable!
  * Added more variables and stuff.
  * Added `terminal` command (only Windows) - starts new cmd session in the cwd
  * Repaired old bugs with some buggy stuff...
  * Added ability to create plugins, which exports the custom variables
* v4.4.0
  * Repaired bugs with user-defined rules parsing
  * Added new variables: `%(project.root)`, `%(project.count)` and `%(project:INDEX)` to
  reference opened project directories
  * Developed better regexp parsing rules (now regexp does not break html code)
  * Still working on speeding up everything a little (highly unoptimised code)
* v4.3.1
  * Repaired bugs...
* v4.3.0
  * Repaired some bugs
  * Developed better plugin system
* v4.2.3
  * Moved changelog to the standalone file
  * Added another builtin plugin - math.coffee
    * This plugin plots simple mathematical functions using JQPlot
      * Try ``` plot sin(x) ```
      * Or ``` plot 0 10 x*x*sin(x)*cos(x) ```
* v4.2.2
  * Added moular plugin system
  * Changed the console trigger
    * From backtick to backtick+ctrl
  * Added description box next to the suggestions dropdown
* v4.2.1
  * Repaired broken requires.
  * Repaired `jquery-autocomplete-js` dependency
  * Developed a better errors handling
* v4.2.0
  * Added autocomplete functionality
  * Added new stuff to the command finder
  * Command finder now works as it should earlier
  * Now console correctly detects the project root directory
  * Repaired conflicting markers
    * Changed ` %(^) ` - full string command to ` %(*^) ` the formatting-end marker is the same - ` %(^) `
* v4.1.2
  * Added new built-in commands (like rmdir, mkdir, cp etc.)
* v4.1.1
  * Added icons to the command finder
  * Added global variables list to the command finder
* v4.1.0
  * Added support for arrow keys in terminal input (press up/down arrow key to access the input history)
  * Removed file highlighting bugs
  * Added more special variables
  * There's a new link annotation
  * Added experimental file highlight feature
  * Added commands view modal dialog
* v4.0.14
  * New better console "input box" - now it looks more like a serious console; made some repairs.
* v4.0.13
  * Repaired another mass of bugs, added config descriptions, repaired exec function mechanics.
* v4.0.11
  * Repaired a mass of bugs :/
* v4.0.7
  * Added slide terminal animation (use backtick key trigger for better experience :) )
