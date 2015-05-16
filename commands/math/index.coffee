vm = require 'vm'
require './jquery.jqplot.min.js'


###
  == ATOM-TERMINAL-PANEL  UTILS PLUGIN ==

  Atom-terminal-panel builtin plugin v1.0.0
  -isis97

  Contains commands for math graphs plotting etc.
  Supports math function plotting (using JQPlot).

  MIT License
  Feel free to do anything with this file.
###
math_parser_sandbox = {
  sin: Math.sin
  cos: Math.cos
  ceil: Math.ceil
  floor: Math.floor
  PI: Math.PI
  E: Math.E
  tan: Math.tan
  sqrt: Math.sqrt
  pow: Math.pow
  log: Math.log
  round: Math.round
}
vm.createContext math_parser_sandbox

module.exports =
  "plot":
    "description": "Plots math function using JQPlot."
    "params": "<[FROM] [TO]> [CODE]"
    "example": "plot 0 10 sin(x)"
    "command": (state, args)->
      points = []

      if args.length < 3
        args[2] = args[0]
        args[0] = -25
        args[1] = 25

      from = vm.runInThisContext args[0]
      to = vm.runInThisContext args[1]
      step = (to-from)/500.0
      for i in [from..to] by step
        math_parser_sandbox.x = i
        points.push([i, vm.runInContext(args[2], math_parser_sandbox)])
      math_parser_sandbox.x = undefined
      id = generateRandomID()
      state.message '<div style="height:300px; width:500px;padding-left:25px;" ><div id="chart-'+id+'"></div></div>'
      $.jqplot('chart-'+id, [points], {
        series:[{showMarker:false}]
        title:'Plotting f(x):='+args[2]
        axes:{
          xaxis:{
            label:'Angle (radians)'
            labelRenderer: $.jqplot.CanvasAxisLabelRenderer
            labelOptions: {
              fontFamily: 'Georgia, Serif'
              fontSize: '0pt'
            }
          }
          yaxis:{
            label:''
            labelRenderer: $.jqplot.CanvasAxisLabelRenderer
            labelOptions: {
              fontFamily: 'Georgia, Serif'
              fontSize: '0pt'
            }
          }
        }
      })
      return null
  "parse":
    "description": "Parses mathematical expression."
    "params": "[EXPRESSION]"
    "command": (state, args)->
      state.message "Result: "+(vm.runInContext args[0], math_parser_sandbox)
      return null
