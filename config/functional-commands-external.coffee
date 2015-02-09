
module.exports =
  "compile":
    "description": "Compiles the C/C++ file using g++."
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
      return state.exec "#{COMPILER_NAME} #{COMPILER_FLAGS} \"#{SOURCE_FILE}\" -o \"#{TARGET_FILE}\" #{ADDITIONAL_FLAGS}", args, state

  "run":
    "description": "! Only for testing purposes. (meaningless)"
    "command": (state, args)->
      SOURCE_FILE = state.getCurrentFilePath()
      TARGET_FILE = "#{SOURCE_FILE}.exe"
      return state.exec "\"#{TARGET_FILE}\"", args, state

  "test":
    "description": "Tests the specified file with the input file."
    "command": (state, args)->
      test_file = args[0]
      app_name_matcher = /([^0-9])*/ig
      app_name_match = app_name_matcher.exec(test_file)
      app_file = app_name_match[0] + '.exe'
      state.execDelayedCommand '250', "#{app_file} < #{test_file}"
      return 'Probing application input ' + state.consoleLink(app_file) + ' < ' + state.consoleLink(test_file)

  "@":
    "description": "Access native environment variables."
    "command": (state, args)->
      return state.parseTemplate "%(env."+args[0]+")"

  "cp":
    "description": "Copies one/or more files to the specified directory (e.g cp ./test.js ./test/)"
    "command": (state, args)->
      srcs = args[..-2]
      tgt = args[-1..]
      return (state.util.cp srcs, tgt) + ' files copied.'

  "mkdir":
    "description": "Create one/or more directories."
    "command": (state, args) ->
      return state.util.mkdir args

  "rmdir":
    "description": "Remove one/or more directories."
    "command": (state, args) ->
      return state.util.rmdir args

  "rename":
    "description": "Rename the given file/directory."
    "command": (state, args) ->
      return state.util.rename args[0], args[1]
