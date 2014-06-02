path  = require 'path'
_     = require 'lodash'
yargs = require 'yargs'
log   = require './log'
build = require './build'
dotfe = require('./dotfe').load()

devArgs = yargs
  .default('port', process.env.PORT || dotfe.PORT || dotfe.port || 8000)
  .default('serve', dotfe.serve || true)
  .argv

module.exports = run: (args) ->
  _.defaults args, devArgs
  args.renderDrafts = true

  building = false
  rebuild = (cb) ->
    unless building
      building = true
      build.run(args).then ->
        building = false
        cb?()
      .then null, (err) ->
        log "Error during build: #{err}"
        process.exit 1

  # Rebuild on return
  process.stdin.resume()
  process.stdin.on 'data', -> rebuild()

  # Build the site, then start a dev server
  # and watch for changes
  rebuild ->
    if args.serve
      connect = require 'connect'
      connect()
        .use(connect.static('./public'))
        .listen(args.port)

      log "Dev server listening on port #{args.port}"

    log "Press return to rebuild"
    (require 'gaze') "#{args.srcDir}/**", (err, watcher) ->
      @on 'all', -> rebuild()
