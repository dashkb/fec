util  = require 'util'
_     = require 'lodash'
yargs = require 'yargs'
dotfe = require('./dotfe').load()
log   = require './log'

module.exports = run: ->
  cwd = process.cwd()
  args = yargs
    .default('bowerDir', dotfe.bowerDir || "#{cwd}/bower_components")
    .default('srcDir', dotfe.srcDir || "#{cwd}/fe")
    .default('buildDir', dotfe.buildDir || "#{cwd}/public")
    .default('tmpDir', dotfe.tmpDir || "#{cwd}/tmp")
    .default('mainScript', dotfe.mainScript || "fe.coffee")
    .default('mainTemplate', dotfe.mainTemplate || "fe")
    .default('compress', dotfe.compress || false)
    .default('verbose', dotfe.verbose || false)
    .count('verbose')
    .alias
      srcDir: 's'
      buildDir: 'b'
      mainScript: 'm'
      verbose: 'v'
    .argv

  args._.push 'build' if args._.length == 0

  _.each args._, (command) ->
    if command == 'watch'
      command = 'dev'
      args.serve = false

    if args.verbose > 1
      log "Running `fetool #{command}` with opts", args

    require("./#{command}").run args
