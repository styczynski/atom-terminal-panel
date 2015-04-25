###
  == ATOM-TERMINAL-PANEL  HELPERS PLUGIN ==

  Atom-terminal-panel builtin plugin v1.0.0
  -isis97

  Contains helper commands (mainly for C/C++ compilation/testing).
  These commands are defined just for testing purposes.
  You can remove this file safely.

  MIT License
  Feel free to do anything with this file.
###
module.exports =
  "compile":
    "description": "Compiles the currently opened C/C++ file using g++."
    "command": (state, args)->
      SOURCE_FILE = state.getCurrentFilePath()
      COMPILER_NAME = 'g++'
      COMPILER_FLAGS = ' -lm -std=c++0x -O2 -m32 -Wl,--oformat,pei-i386 -Wall' +
       ' -W -Wextra -Wdouble-promotion -pedantic -Wmissing-include-dirs' +
       ' -Wunused -Wuninitialized -Wextra -Wstrict-overflow=3 -Wtrampolines' +
       ' -Wfloat-equal -Wconversion -Wmissing-field-initializers -Wno-multichar' +
       ' -Wpacked -Winline -Wshadow'
      TARGET_FILE = "#{SOURCE_FILE}.exe"
      TARGET_FILE = state.replaceAll '.cpp', '', TARGET_FILE
      TARGET_FILE = state.replaceAll '.c', '', TARGET_FILE
      ADDITIONAL_FLAGS = ""
      state.exec "#{COMPILER_NAME} #{COMPILER_FLAGS} \"#{SOURCE_FILE}\" -o \"#{TARGET_FILE}\" #{ADDITIONAL_FLAGS}", args, state
      return ""

  "run":
    "params": "[name]"
    "description": "! Only for testing purposes. (meaningless). Runs the [name].exe file."
    "command": (state, args)->
      SOURCE_FILE = state.getCurrentFilePath()
      TARGET_FILE = "#{SOURCE_FILE}.exe"
      return state.exec "\"#{TARGET_FILE}\"", args, state

  "test":
    "params": "[name]"
    "description": "Tests the specified file with the input file. (executes [name].exe < [name])"
    "command": (state, args)->
      test_file = args[0]
      app_name_matcher = /([^0-9])*/ig
      app_name_match = app_name_matcher.exec(test_file)
      app_file = app_name_match[0] + '.exe'
      state.execDelayedCommand '250', "#{app_file} < #{test_file}"
      return 'Probing application input ' + state.consoleLink(app_file) + ' < ' + state.consoleLink(test_file)
