require './cli-utils'
luaparser = null

class CliRunner

  parser: null
  init: () =>
    @parser = luaparser
    return this

  run: (code) =>
    return @parser.parse(code)


module.exports = new CliRunner().init()
