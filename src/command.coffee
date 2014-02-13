util  = require 'util'
_     = require 'lodash'
yargs = require 'yargs'

module.exports = run: ->
  cwd = process.cwd()
  args = yargs
    .default('bowerDir', "#{cwd}/bower_components")
    .default('srcDir', "#{cwd}/fe")
    .default('buildDir', "#{cwd}/public")
    .default('mainScript', "fe.coffee")
    .alias
      srcDir: 's'
      buildDir: 'b'
      mainScript: 'm'
    .argv

  _.each args._, (command) ->
    if command == 'watch'
      command = 'dev'
      args.serve = false

    require("./#{command}").run args
