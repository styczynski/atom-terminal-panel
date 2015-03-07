[![SHIELD](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](https://github.com/isis97/atom-terminal-panel)
[![SHIELD](http://img.shields.io/github/tag/isis97/atom-terminal-panel.svg?style=flat-square)](https://github.com/isis97/atom-terminal-panel)




atom-terminal-panel
==============

(a fork of super-awesome atom package - thedaniel/terminal-panel)
Plugin for ATOM Editor.

## Short note

This project uses `jquery-autocomplete-js` for autocompletion. [See git repo](https://github.com/isis97/autocomplete-js)

## Development

This project is in alpha stage.
Please contribute this project if you liked it.
All the help is welcome.
Feel free to propose new feautures, modify existing code, report issues.
Thank you.

## Usage
Just press `shift-enter` or just `` Ctrl + ` `` (control + backtick) and enjoy your cool ATOM terminal :D

## Screenshot

Terminal with fancy file links and interactive interface.

![A screenshot of atom-terminal-panel package](https://raw.githubusercontent.com/isis97/atom-terminal-panel/master/static/example.gif)

Fancy custom highlighting rules.

![A screenshot of atom-terminal-panel package](https://raw.githubusercontent.com/isis97/atom-terminal-panel/master/static/example3.gif)

Custom highlighting and few commands (old version):

![A screenshot of atom-terminal-panel package](https://raw.githubusercontent.com/isis97/atom-terminal-panel/master/static/example2.gif)

There's also nice looking easy-to-use command finder dialog (just to search your custom commands and terminal build-ins):

![A screenshot of atom-terminal-panel package](https://raw.githubusercontent.com/isis97/atom-terminal-panel/master/static/example_command_finder.png)


## Feature

* multiple terminal
* colorful status icon
* kill long live process
* fancy ls (with custom extension colouring!)
  * Do you wanna have a blue or a green executables? Do the yellow shell scripts look nice?
* file and directory links (auto path detection)
* interactive content (tooltips and on-click-actions)
* highlighting rules (define your own highlight options - supports awesome stuff like regex matching, replacement and link creation)
* nice looking slide animation on terminal open
* navigate command history using arrow keys
  * Just like in normal, native terminal.
* search your favourite commands and built-ins
  * Just type `?`, easy right?)
* many useful special variables (like path to the currenly edited file)
* customize your command prompt like never before using text formatting annotation and special variables!
  * Do you want a current time, computer name or a cwd in your command prompt? There's no problem.
* easily create custom commands!
  * You don't have to play with dirty shell script files!
* easily add new buttons to the terminal toolbar
  * Now you can quickly access your command just by pressing one button
* auto suggestions and commands descriptions for ease of use
* modular commands system
  * To add new commands just write your own /or download existing plugin!
  * And copy it to the ./commands directory! - Easy, right?

## Plugins

This ATOM plugin is modular. You can create your own commands or download existing from the other users.
The release contains also the built-in plugins (for file system management etc.).

## Terminal-commands.json
The `terminal-commands.json` is the main configuration file for this package. If it's not present (or the JSON syntax is invalid) a new config file is created (in folder .atom).

The config file contains:

* custom commands definitions
* rules (defininig highlights, regex replacement for text etc.)

The sample config file can look like:

```json
{
  "commands": {
    "hello": {
      "description": "Some description",
      "command": [
        "echo Hello world :D",
        "echo This = %(*)",
        "echo is",
        "echo example usage",
        "echo of the console"
      ]
    }
  },
  "toolbar": [],
  "rules": {
    "warning: (.*)" : {
      "match": {
        "matchLine": "true"
      },
      "css": {
        "color": "yellow"
      }
    }
  }
}
```

The above configuration file will create highlight rule for all lines containing "warning: " text (this lines will be colored yellow).

### Creating custom terminal shortcuts

You can create your own shortcuts buttons, which are placed on the terminal toolbar.
To do it just put a new entry in the `toolbar` property:
```json
toolbar: [
  ["SHORTCUT NAME", "COMMAND TO BE EXECUTED"]
]
```

E.g. creating a button, which displays all avaliable terminal bultin commands:
```json
toolbar: [
  [ "Display all commands", "memdump" ]
]
```

Another example. Now the button will move the terminal to the C: directory:
```json
toolbar: [
  ["C:", "cd C:\\"]
]
```

You can add also tooltips describing the button functions:
```json
toolbar: [
  ["C:", "cd C:\\", "Moves the terminal to the C:\\ directory."]
]
```

### Defining custom commands

Each command is defined in the `commands` entry the following way:

```json
"name": {
  "description": "Simple description shown in command view (activated by memdump or ?)",
  "command": ["command0", "command1", "command2"]
}
```
'command0', 'command1'... are the commands that will be invoked by the user entry.
Example involving `g++` usage:
```json
"build": {
  "description": "Build C/C++ application.",
  "command": [
    "echo Compiling %(file) using g++ Please wait...",
    "g++ \"%(file)\" -o \"%(file).runnable\"",
    "echo Compilation finished %(file)."
  ]
}
```
As you can see you are able to build the current C/C++ project using only a single command.
You may also try creating a build command accepting single file path (simple source file path) and
the auto_build command, which will execute build command with `%(file)` parameter.
E.g.
```json
"build": {
  "description": "Build C/C++ application.",
  "command": [
    "echo Compiling %(0) using g++ Please wait...",
    "g++ %(0) -o %(0).runnable",
    "echo Compilation finished %(0)."
  ]
},
"auto_build": {
  "description": "Automatically build C/C++ application.",
  "command": [
    "build \"%(file)\""
  ]
}
```

### Defining custom rules

The highlight rules that are placed in `rules` property can be defined using two methods.
The simple way looks like:
```json
  "regexp" : {
    "css-property1": "css-value1",
    "css-property2": "css-value2",
    "css-property3": "css-value3"
  }
```

Or more complex (and also more powerful) way:
```json
  "REGEXP" : {
    "match" : {
      "matchLine": "true",
      "replace": "REPLACEMENT"
    },
    "css": {
      "color": "red",
      "font-weight": "bold"
    }
  }
```

The REGEXP will be replaced with REPLACEMENT and all the line with matched token will be colored to red(matchLine:true).

### More about regex rules

You can use the following properties in regex matches:

* `matchLine` - bool value specifies if the regex should be applied to the whole line
* `matchNextLines` - integer value specifies how many lines after the line containing current match should be also matched
* `replace` - text that the match will be replaced with

### Special annotation

You can use special annotation (on commands/rules definitions or in settings - command prompt message/current file path replacement) which is really powerful:

* `%(username) or %(user)` - refers to the currently logged user
* `%(computer-name) or %(hostname)` - refers to the currently used computer name
* `%(home)` - refers to the current user home directory (experimental, may be broken sometimes)
* `%(path) or %(cwd)` - refers to the current working directory path
* `%(atom)` - refers to the atom directory
* `%(file)` - refers to the current file (its value depends on the usage context - you'll note :) )
* `%(editor.file)/%(editor.path)/%(editor.name)` - refers to the file currenly opened in the editor (full path/directory/file name)
* `%(line)` - refers to the input command number
* `%(env.PROPERTY)` - refers to the node.js environmental variable called PROPERTY (to get the list of all available properties type `%(env.*)` into the terminal)[See node.js process_env](http://nodejs.org/api/process.html#process_process_env)
* `%(command)` - refers to the lastly used command (experimental, may be broken)
* `%(link)FILEPATH%(endlink)` - creates an interactive link for the given filepath
* `%(day)/%(month)/%(year)/%(hours)/%(minutes)/%(seconds)/%(milis)` - refers to the current time
* `%(hours12)/%(ampm)/%(AMPM)` - special variables used for 12-hours time format
* `%(.day)/%(.month)/%(.year)/%(.hours)/%(.minutes)/%(.seconds)/%(.milis)/%(.hours12)` - refers to the current time (values without leading zeros)
* `%(^...)` - text formatting modifiers (see text formatting)
* `%(disc)` - refers to the current file disc location name
* `%(path:0)/%(path:1)/%(path:2)...` - refers to the current file path component (path:0 is a disc name)
* `%(path:-1)/%(path:-2)/%(path:-3)...` - refers to the current file component (numerated from the end) -     (path:-1 is the last path component)
* `%(tooltip:CASUAL TEXT:content:TOOLTIP CONTENT)` - generates new tooltip component (TEXT and TOOLTIP cannot contain any special characters like brackets)
* `%(label:TYPE:TEXT)` - creates new label (TYPE can be error, danger, warning, default, info, badge)
* `%(0), %(1), %(2)...` - refers to the passed arguments
* `%(0), %(1), %(2)...` - also refers to the capture groups in user defined colouring rules
* `%(*)` - refers to the all passed arguments (concatenated arguments list) (can be used only in user commands definitions)
* `%(*^)` - refers to the command string (command with all arguments) (can be used only in user commands definitions)


### Text formatting

Please use the `%(^...)` modifiers to format the text:

* `%(^)` - ends the text formatting
* `%(^#000000)` - colors the text with the hex color
* `%(^b) or %(^bold)` - creates bold text
* `%(^i) or %(^italic)` - creates text in italics
* `%(^u) or %(^underline)` - creates underlined text
* `%(^l) or %(^line-through)` - creates line trough the text

Example usage:
```
default %(^i)italics%(^) %(^u)underline%(^) %(^b)%(^i)bold italics%(^)%(^) %(^#DAA520)colored%(^)
```

## Internally defined commands

You can take advantage of commands like `memdump` which prints information about all loaded commands (internal, not native!).
Here the list of all commands:

* `ls`
* `new FILENAME` - creates new empty file in current working directory and opens it instantly in editor view
* `edit FILENAME` - opens a given file in editor
* `link FILENAME` - creates new file link (you can use it to open a file)
* `rm FILENAME` - removes file in current working directory
* `memdump` or `?` - prints information about all loaded commands
* `clear` - clears console output
* `cd` - moves to a given path
* `update` - reloads plugin config (terminal-commands.json)
* `reload` - reloads atom window

Included example commands:

* `compile` - compiles current file using g++
* `run` - runs the previously compiled file
* `test FILENAME` - runs the test on the compiled application FILENAME is a FILE0.in file and the compiled application name must be FILE.exe e.g. `test test5.in` means `test.exe < test5.in`

### Internal configuration

You can modify the extensions.less file and add your own extension colouring rules.
E.g:

```less
  .txt {
    color: hsl(185, 0.5, 0.5);
    font-weight: bold;
  }
  .js {
    color: red;
  }
```

Simple like making a cup of fresh coffee...
Just dot, extension name and CSS formatting.

The ./commands director contains the plugins (you can add your own commands).
Each plugin exports a list of all custom commands.
E.g.
```coffeescript
module.exports =
  "hello_world":
    "description": "Prints hello world message to the screen."
    "command": (state, args)->
      return "Hello world"
```
The state is the terminal view object and the args - the array of all passesd parameters.
Your custom functional command can also create console links using ```state.consoleLink path```, labels using ```state.consoleLabel type, text``` or execute other commands:
E.g.
```coffeescript
"call_another":
  "description": "This example shows how to call another command."
  "command": (state, args)->
    return state.exec "echo Hello world", state, args
```
But if you're using ```state.exec``` you must remember about passing not only command string but also state and args parameters (array of refernced parameters).
The array of the referenced parameters contans all parameters which will be referenced by a command string (element at zero index in array will be used for %(0) replacement). If the command string do not reference its parameters you can pass only a null value.
As you can see all terminal messages are displayed automatically (just return the string message). but you can also print them manually:
``` coffeescript
"hello_world":
  "description": "Hello world example with two messages."
  "command": (state, args)->
    state.message 'Hello world'
    return 'Second string hue hue :)'
```

You can specify the command description, example usage and if the plugin command is outdated - make it deprecated:
``` coffeescript
"hello_world":
  "deprecated": true
  "example": "hello_world"
  "params": "[NONE]"
  "description": "Hello world example with two messages."
  "command": (state, args)->
    state.message 'Hello world'
    return 'Second string hue hue :)'
```

The ./config/terminal-style.less contains the general terminal stylesheet:
E.g.
``` less
background-color: rgb(12, 12, 12);
color: red;
font-weight: bold;
```

## More about console

As you can see in previous examples we were calling `state.exec`.
This method accepts tree parametes:
`command`, `args_reference`, `state`
`command` is the string command to be executed e.g. `echo test` or `format C:`
`args_reference` is the array containing all reference arguments e.g. if you passes a ['arg0', 'arg1'] as parameter the `%(0)` sequence will be replaced with `arg0` text and `%(1)` with `arg1`. If this paramter is undefined or null the command is executed normally and the `%(0)` sequences are simply removed.
`state` - the console view object e.g. `state.exec 'echo test > test.txt', null, state`

You can also call other useful console methods:
* `state.message 'MESSAGE'` - displays a message (can contains css/html formatting)
* `state.rawMessage 'MESSAGE'` - displays a message without parsing special sequences like `%(link)...%(endlink)` or `%(cwd)` etc.
* `state.clear` - clears console output
* `state.consoleLink 'FILENAME'` - creates console link to a given file (returns text which will be replaced with interactive file link)
* `state.consoleLabel 'TYPE', 'TEXT'` - creates console label just like `%(label:TYPE:text:TEXT)`

## Hotkeys

* `shift-enter` toggle current terminal
* `command-shift-t` new terminal
* `command-shift-j` next terminal
* `command-shift-k` prev terminal
* `` ` `` - toggle terminal
* `escape` (in focused input box) - close terminal

## TODO

* Make a more cool terminal cursor.
* More interactive stuff
* Maybe a little bash parser written in javascript?
* Some about stdinput (which is really bad)

## Changelog

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


## Example configuration

Here it is, the example configuration (terminal-commands.json) - that you can see on the preview images.
To use it just copy it to your ./atom/terminal-commands.json file (if the file doesn't exist call `update` command and it should be created).

The regex rules preview can be easily checked by invoking `echo` command (e.g. `echo warn test warning messages.`).

Note that after each config update you must call `update` command otherwise changes will take no effects.

```json
{
  "_comment": "Package atom-terminal-panel: This terminal-commands.json file was automatically generated by atom-terminal-package. It contains all useful config data.",
  "commands": {
    "hello_world": {
      "description": "Prints the hello world message to the terminal output.",
      "command": [
        "echo Hello world :D",
        "echo This is",
        "echo example usage",
        "echo of the console"
      ]
    }
  },
  "toolbar": [
    [
      "clear",
      "clear",
      "Clears the console output."
    ],
    [
      "info",
      "info",
      "Prints the terminal welcome message."
    ],
    [
      "all available commands",
      "memdump",
      "Displays all available builtin commands. (all commands except native)"
    ]
  ],
  "rules": {
    "(error|err):? (.*)": {
      "match": {
        "matchLine": "true",
        "replace": "%(label:error:text:Error) %(0)"
      },
      "css": {
        "color": "red",
        "font-weight": "bold"
      }
    },
    "(warning|warn|alert):? (.*)": {
      "match": {
        "matchLine": "true",
        "replace": "%(label:warning:text:Warning) %(0)"
      },
      "css": {
        "color": "yellow"
      }
    },
    "(note|information):? (.*)": {
      "match": {
        "matchLine": "true",
        "replace": "%(label:info:text:Info) %(0)"
      },
      "css": {}
    },
    "(debug|dbg):? (.*)": {
      "match": {
        "matchLine": "true",
        "replace": "%(label:default:text:Debug) %(0)"
      },
      "css": {
        "color": "gray"
      }
    }
  }
}
```

## Experiments

This package is in alpha development phase. You can enable experimental features, which may be added to the software in incoming releases.
