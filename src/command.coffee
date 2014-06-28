util  = require 'util'
_     = require 'lodash'
yargs = require 'yargs'
dotfe = require('./dotfe').load()
log   = require './log'

module.exports = run: ->
  cwd = process.cwd()
  args = yargs
    .usage("$0 -s srcDir -b buildDir")
    .default('bowerDir', dotfe.bowerDir || "#{cwd}/bower_components")
    .default('srcDir', dotfe.srcDir || "#{cwd}/fe")
    .default('buildDir', dotfe.buildDir || "#{cwd}/public")
    .default('tmpDir', dotfe.tmpDir || "#{cwd}/tmp")
    .default('mainScript', dotfe.mainScript || "fe.coffee")
    .default('mainTemplate', dotfe.mainTemplate || "fe")
    .default('compress', dotfe.compress || false)
    .default('verbose', dotfe.verbose || false)
    .default('quiet', dotfe.quiet || false)
    .count('verbose')
    .alias
      srcDir: 's'
      buildDir: 'b'
      mainScript: 'm'
      verbose: 'v'
      quiet: 'q'

  showHelp = args.showHelp
  args = args.argv

  args._.push 'build' if args._.length == 0

  log.disable() if args.quiet

  _.each args._, (command) ->
    if command == 'help'
      showHelp()
      return

    if command == 'watch'
      command = 'dev'
      args.serve = false

    if args.verbose > 1
      log "Running `fec #{command}` with opts", args

    require("./#{command}").run args
