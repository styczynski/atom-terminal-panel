
module.exports =
  "compile": (state, args)->
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
    return state.exec("#{COMPILER_NAME} #{COMPILER_FLAGS} \"#{SOURCE_FILE}\" -o \"#{TARGET_FILE}\" #{ADDITIONAL_FLAGS}")

  "run": (state, args) ->
    SOURCE_FILE = state.getCurrentFilePath()
    TARGET_FILE = "#{SOURCE_FILE}.exe"
    return state.exec("\"#{TARGET_FILE}\"");

  "test": (state, args) ->
    test_file = args[0]
    app_name_matcher = /([^0-9])*/ig
    app_name_match = app_name_matcher.exec(test_file)
    app_file = app_name_match[0] + '.exe'
    state.execDelayedCommand '250', "#{app_file} < #{test_file}"
    return 'Probing application input ' + state.consoleLink(app_file) + ' < ' + state.consoleLink(test_file)
