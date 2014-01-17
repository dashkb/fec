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
{exec}      = require 'child_process'
moment      = require 'moment'
log         = require './log'
buildPages  = require './build_pages'

startBuild = (ctx) ->
  new Promise (resolve, reject) ->
    log "Starting build"
    rimraf.sync ctx.cmd.buildDir
    mkdirp.sync ctx.cmd.buildDir
    _.each ['css', 'js', 'fonts', 'images'], (dir) ->
      mkdirp.sync "#{ctx.cmd.buildDir}/#{dir}"
    resolve ctx

buildScripts = (ctx) ->
  new Promise (resolve, reject) ->
    bundle = browserify glob.sync "#{ctx.cmd.srcDir}/**/*.+(coffee|js)"
    bundle.transform require 'coffeeify'
    bundle.transform require 'uglifyify' if ctx.cmd.compress
    bundle.bundle (err, src) ->
      fs.writeFileSync "#{ctx.cmd.buildDir}/js/all.js", src
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
      fs.writeFileSync "#{ctx.cmd.buildDir}/css/all.css", css
      resolve ctx

copyFontAwesome = (ctx) ->
  new Promise (resolve, reject) ->
    src = "#{ctx.cmd.bowerDir}/font-awesome/fonts/*"
    dst = "#{ctx.cmd.buildDir}/fonts/"
    exec "cp #{src} #{dst}", (err, out) ->
      if err
        reject err
      else
        resolve ctx

copyImages = (ctx) ->
  new Promise (resolve, reject) ->
    images = glob.sync "#{ctx.cmd.srcDir}/**/*.+(jpg|png)"
    promises = _.map images, (file) ->
      new Promise (resolve, reject) ->
        relPath = path.relative ctx.cmd.srcDir, file
        dst = "#{ctx.cmd.buildDir}/images/#{path.dirname relPath}"
        exec "mkdir -p #{dst} && cp #{file} #{dst}", (err) ->
          if err then reject(err) else resolve()

    if promises.length > 0
      rsvp.all(promises).then -> resolve ctx
    else
      resolve ctx

signalDone = (ctx) ->
  new Promise (resolve, reject) ->
    resolve ctx
    log "Hooray"

signalError = (err) ->
  log "Error building", err, err.stack

module.exports = (cmd) ->
  startBuild(cmd: cmd).then (ctx) ->
    new Promise (resolve, reject) ->
      steps = rsvp.all _.map [
        buildScripts, buildStyles, copyFontAwesome, copyImages
      ], (fn) -> fn ctx
      steps.then -> resolve ctx
  .then (ctx) ->
    buildPages ctx
  .then (ctx) ->
    signalDone ctx
  .then null, (err) ->
    signalError err
