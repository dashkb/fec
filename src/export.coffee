_         = require 'lodash'
yargs     = require 'yargs'
path      = require 'path'
log       = require './log'
fs = require 'fs'
browserify = require 'browserify'

exportArgs = yargs
  .demand(['sourceFile', 'outFile'])
  .alias('s', 'sourceFile')
  .alias('o', 'outFile')
  .alias('r', 'requireAs')
  .argv

module.exports = run: (args) ->
  _.extend args, exportArgs

  args.requireAs ||= args.sourceFile

  bundle = browserify
    extensions: ['.jst', '.coffee', '.js']

  bundle.require args.sourceFile

  bundle.transform require 'coffeeify'
  bundle.transform require 'uglifyify' if args.compress
  bundle.transform require 'debowerify'
  bundle.bundle (err, src) ->
    if err
      log "Error: #{err}"
    else
      fs.writeFileSync args.outFile, """
        module.exports = #{src}("#{args.requireAs}");
      """
      log.debug "Exported"

