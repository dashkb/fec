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
    log.debug "Starting build"
    mkdirp.sync ctx.cmd.buildDir
    _.each ['css', 'js', 'fonts', 'images'], (dir) ->
      mkdirp.sync "#{ctx.cmd.buildDir}/#{dir}"
    resolve ctx

buildScripts = (ctx) ->
  new Promise (resolve, reject) ->
    log.debug "Started scripts"

    scripts = _.map [
      'jquery/jquery.js',
      'bootstrap/dist/js/bootstrap.js',
    ], (script) ->
      "#{ctx.cmd.bowerDir}/#{script}"

    scripts.push ctx.cmd.mainScript || "#{ctx.cmd.srcDir}/site.coffee"

    bundle = browserify scripts
    bundle.transform require 'coffeeify'
    bundle.transform require 'uglifyify' if ctx.cmd.compress
    bundle.bundle (err, src) ->
      if err
        reject err
      else
        fs.writeFileSync "#{ctx.cmd.buildDir}/js/all.js", src
        log.debug "Finished scripts"
        resolve ctx

buildStyles = (ctx) ->
  new Promise (resolve, reject) ->
    log.debug "Started styles"
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
      log.debug "Finished styles"
      resolve ctx

copyFontAwesome = (ctx) ->
  new Promise (resolve, reject) ->
    log.debug "Started copying font-awesome"
    src = "#{ctx.cmd.bowerDir}/font-awesome/fonts/*"
    dst = "#{ctx.cmd.buildDir}/fonts/"
    exec "cp #{src} #{dst}", (err, out) ->
      if err
        reject err
      else
        log.debug "Finished copying font-awesome"
        resolve ctx

copyImages = (ctx) ->
  new Promise (resolve, reject) ->
    log.debug "Started copying images"
    images = glob.sync "#{ctx.cmd.srcDir}/**/*.+(jpg|png)"
    promises = _.map images, (file) ->
      new Promise (resolve, reject) ->
        relPath = path.relative ctx.cmd.srcDir, file
        dst = "#{ctx.cmd.buildDir}/images/#{path.dirname relPath}"
        exec "mkdir -p #{dst} && cp #{file} #{dst}", (err) ->
          if err then reject(err) else resolve()

    if promises.length > 0
      rsvp.all(promises).then ->
        log.debug "Finished copying images"
        resolve ctx
    else
      log.debug "No images found"
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
      steps.then null, reject
  .then (ctx) ->
    buildPages ctx
  .then (ctx) ->
    signalDone ctx
  .then null, (err) ->
    signalError err
