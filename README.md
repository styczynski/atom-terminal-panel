atom-terminal-panel
==============

(a fork of super-awesome atom package - thedaniel/terminal-panel)

## Usage
Just press `shift-enter` or just `` ` `` (backtick) and enjoy your cool ATOM terminal :D

## Screenshot

Terminal with fancy file links and interative interface.

![A screenshot of atom-terminal-panel package](https://raw.githubusercontent.com/isis97/atom-terminal-panel/master/static/example.gif)

Fancy custom highlighting rules.

![A screenshot of atom-terminal-panel package](https://raw.githubusercontent.com/isis97/atom-terminal-panel/master/static/example3.gif)

Cutom highlighting and few commands:

![A screenshot of atom-terminal-panel package](https://raw.githubusercontent.com/isis97/atom-terminal-panel/master/static/example2.gif)

## Feature

* multiple terminal
* colorful status icon
* kill long live process
* fancy ls
* file and foler links (auto path detection)
* interactive content (tooltips and on-click-actions)
* highlighting rules (define your own highlight options - supports awesome stuff like regex matching, replacement and link creation)
* own commands support
* nice looking slide animation on terminal open

## Terminal-commands.json
The `terminal-commands.json` is the main config file for this package. If it's not present (or the JSON syntax is invalid) a new config file is created (in folder .atom).

The config file contains:

* custom commands definitions
* rules (defininig highlights, regex replacement for text etc.)

The sample config file can look like:

```json
{
  "commands": {
    "hello": [
      "echo Hello world :D",
      "echo This = %(*)",
      "echo is",
      "echo example usage",
      "echo of the console"
    ]
  },
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

The above config will create highlight rule for all lines containing "warning: " text (this lines will be colored yellow).

### Defining custom commands

Each command is defined the following way:

```json
"name": [ "command0", "command1", "command2"]
```
'command0', 'command1'... are the commands that will be invoked by the user entry.
Example involving `g++` usage:
```json
"build": [
  "echo Compiling %(file) using g++ Please wait...",
  "g++ \"%(file)\" -o \"%(file).runnable\"",
  "echo Compilation finished %(file)."
]
```
As you can see you are able to build the current C/C++ project using only a single command.
You may also try creating a build command accepting single file path (simple source file path) and
the auto_build command, which will execute build command with `%(file)` parameter.
E.g.
```json
"build": [
  "echo Compiling %(0) using g++ Please wait...",
  "g++ %(0) -o %(0).runnable",
  "echo Compilation finished %(0)."
],
"auto_build": [
  "build \"%(file)\""
]
```

### Defining custom rules

The highligh rules can be defined using two methods.
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

The REGEXP will be replaced with REPLACEMENT and all the line with matched token will be colored to red(matchLine=true).

### Special annotation

You can use special annotation (on commands/rules definitions or in settings - command prompt message/current file path replacement) which is really powerful:

* `%(path) or %(cwd)` - refers to the current working directory path
* `%(file)` - refers to the current file
* `%(line)` - refers to the input command number
* `%(link:FILEPATH)` - creates an interactive link for the given filepath
* `%(day)/%(month)/%(year)/%(hours)/%(minutes)/%(milis)` - refers to the current time
* `%(disc)` - refers to the current file disc location name
* `%(path:0)/%(path:1)/%(path:2)...` - refers to the current file path component (path:0 is a disc name)
* `%(path:-1)/%(path:-2)/%(path:-3)...` - refers to the current file component (numerated from the end) -     (path:-1 is the last path component)
* `%(tooltip:CASUAL TEXT:content:TOOLTIP CONTENT)` - generates new tooltip component (TEXT and TOOLTIP cannot contain any special characters like brackets)
* `%(label:TYPE:TEXT)` - creates new label (TYPE can be error, danger, warning, default, info, badge)
* `%(0), %(1), %(2)...` - refers to the passed arguments (ONLY USER COMMANDS)
* `%(*)` - refers to the all passed arguments (concatenated arguments list) (ONLY USER COMMANDS)
* `%(^)` - refers to the command string (command with all arguments) (ONLY USER COMMANDS)


## Internally defined commands

You can take advantage of commands like `memdump` which prints information about all plugin loaded commands.
Here the list of all commands:

* `ls`
* `new FILENAME` - creates new empty file in current working directory and opens it instantly in editor view
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

The ./config/functional-commands-external.coffee file contains the external functional commands (you can add your own commands).
E.g.
```coffeescript
"hello_world": (state, args)->
  return "Hello world"
```
The state is the terminal view object and the args - the array of all passesd parameters.
Your custom functional command can also create console links using ```state.consoleLink path```, labels using ```state.consoleLabel type, text``` or execute other commands:
E.g.
```coffeescript
"call_another": (state, args)->
  return state.exec "echo Hello world", state, args
```
But if you're using ```state.exec``` you must remember about passing not only command string but also state and args parameters.
As you can see all terminal messages are displayed automatically (just return the string message). but you can also print them manually:
``` coffeescript
"hello_world": (state, args)->
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
* `state.rawMessage 'MESSAGE'` - displays a message without parsing special sequences like `%(link:...)` or `%(cwd)` etc.
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

## Changelog

* v4.0.7 - Added slide terminal animation (use backtick key trigger for better experience :) )
