fs          = require 'fs'
mkdirp      = require 'mkdirp'
rimraf      = require 'rimraf'
rsvp        = require 'rsvp'
_           = require 'lodash'
browserify  = require 'browserify'
glob        = require 'glob'
path        = require 'path'
Promise     = rsvp.Promise
less        = require 'less'
uglifyify   = require 'uglifyify'

startBuild = (ctx) ->
  new Promise (resolve, reject) ->
    rimraf.sync ctx.cmd.buildDir
    mkdirp.sync ctx.cmd.buildDir
    resolve ctx

buildScripts = (ctx) ->
  new Promise (resolve, reject) ->
    bundle = browserify glob.sync "#{ctx.cmd.srcDir}/**/*.+(coffee|js)"
    bundle.transform require 'coffeeify'
    bundle.transform require 'uglifyify' if ctx.cmd.compress
    bundle.bundle (err, src) ->
      fs.writeFileSync "#{ctx.cmd.buildDir}/bundle.js", src
      resolve ctx

buildStyles = (ctx) ->
  new Promise (resolve, reject) ->
    files = glob.sync "#{ctx.cmd.srcDir}/**/*.+(less|css)"
    src = _.reduce files, (src, path) ->
      src + fs.readFileSync path
    , ''

    parser = new less.Parser
      paths: [ctx.cmd.srcDir, ctx.cmd.bowerDir]
      filename: 'bundle.less'

    parser.parse src, (err, tree) ->
      css = tree.toCSS compress: ctx.cmd.compress
      fs.writeFileSync "#{ctx.cmd.buildDir}/bundle.css", css
      resolve ctx

buildPages = (ctx) ->
  new Promise (resolve, reject) ->
    resolve ctx

signalDone = (ctx) ->
  new Promise (resolve, reject) ->
    resolve ctx
    console.log "Hooray"

signalError = (err) ->
  console.log "Error building", err, err.stack

module.exports = (cmd) ->
  startBuild(cmd: cmd).then (ctx) ->
    buildScripts ctx
  .then (ctx) ->
    buildStyles ctx
  .then (ctx) ->
    buildPages ctx
  .then (ctx) ->
    signalDone ctx
  .then null, (err) ->
    signalError err
