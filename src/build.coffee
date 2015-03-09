fs          = require 'fs'
mkdirp      = require 'mkdirp'
rimraf      = require 'rimraf'
rsvp        = require 'rsvp'
_           = require 'lodash'
browserify  = require 'browserify'
glob        = require 'glob'
path        = require 'path'
Promise     = rsvp.Promise
uglifyify   = require 'uglifyify'
{exec}      = require 'child_process'
moment      = require 'moment'
log         = require './log'
buildPages  = require './build_pages'


startBuild = (ctx) ->
  ctx.startedAt = moment()
  new Promise (resolve, reject) ->
    mkdirp.sync ctx.args.buildDir
    mkdirp.sync ctx.args.tmpDir
    _.each ['css', 'js', 'fonts', 'images'], (dir) ->
      mkdirp.sync "#{ctx.args.buildDir}/#{dir}"
    resolve ctx

compileTemplate = (template, ctx) ->
  log.debug "Recompiling template #{template}"
  CoffeeScript = require 'coffee-script'
  compiler = new (require '../node_modules/haml-coffee/src/haml-coffee')
    placement: 'standalone'
    uglify: ctx.args.compress

  compiler.parse fs.readFileSync template, encoding: 'utf8'

  CoffeeScript.compile compiler.precompile(),
    bare: true

compileTemplates = (ctx) ->
  startedAt = moment()
  log.debug "Started compiling templates"
  new Promise (resolve, reject) ->
    sources   = glob.sync "#{ctx.args.srcDir}/**/*.hamlc"
    cacheFile = "#{ctx.args.tmpDir}/templates.json"
    cache     = try
      JSON.parse fs.readFileSync cacheFile, encoding: 'utf8'
    catch
      log.warn "Could not load template cache; starting from scratch"
      {}

    _.each sources, (template) ->
      if fs.statSync(template).mtime > (cache[template]?.mtime || 0)
        cache[template] =
          mtime: +new Date()
          js: compileTemplate template, ctx
    fs.writeFileSync cacheFile, JSON.stringify(cache)

    jstSrc = _.reduce cache, (out, {js}, file) ->
      key = path.relative ctx.args.srcDir, file
      key = path.basename key, path.extname(key)
      out + "module.exports[\"#{key}\"] = function(ctx) {\n
        return (function() {\n
          #{js}\n
        }).call(ctx);
      };\n"
    , 'var _ = require("lodash");\nmodule.exports = {};\n'

    fs.writeFileSync "#{ctx.args.tmpDir}/templates.jst", jstSrc

    log.debug "Finished compiling templates in #{moment().diff startedAt}ms"

    if dest = ctx.args.withTemplates
      dest = "#{ctx.args.buildDir}/js/#{dest}"
      fs.writeFileSync dest, jstSrc
      log.debug "Wrote templates to #{dest}"

    ctx.JST = eval "(function(){ #{jstSrc}; return module.exports;}).call()"
    resolve ctx

buildScripts = (ctx) ->
  startedAt = moment()
  new Promise (resolve, reject) ->

    bundle = browserify
      entries: ["#{ctx.args.srcDir}/#{ctx.args.mainScript}"]
      extensions: ['.jst', '.coffee', '.js']
      ignoreMissing: true

    bundle.transform require 'coffeeify'
    bundle.transform require 'uglifyify' if ctx.args.compress
    bundle.transform require 'debowerify'
    bundle.bundle (err, src) ->
      if err
        reject err
      else
        fs.writeFileSync "#{ctx.args.buildDir}/js/all.js", src
        log.debug "Finished compiling scripts in #{moment().diff startedAt}ms"
        resolve ctx

buildStyles = (ctx) -> (require "./css_preprocessors/#{ctx.args.cssPreprocessor}") ctx

copyFontAwesome = (ctx) ->
  new Promise (resolve, reject) ->
    faDir = "#{ctx.args.bowerDir}/font-awesome"

    if fs.existsSync faDir
      src = "#{faDir}/fonts/*"
      dst = "#{ctx.args.buildDir}/fonts/"
      exec "cp #{src} #{dst}", (err, out) ->
        if err
          reject err
        else
          resolve ctx
    else
      resolve ctx

copyImages = (ctx) ->
  startedAt = moment()
  new Promise (resolve, reject) ->
    log.debug "Started copying images"
    images = glob.sync "#{ctx.args.srcDir}/**/*.+(jpg|png)"
    promises = _.map images, (file) ->
      new Promise (resolve, reject) ->
        relPath = path.relative ctx.args.srcDir, file
        dst = "#{ctx.args.buildDir}/images/#{path.dirname relPath}"
        exec "mkdir -p #{dst} && cp #{file} #{dst}", (err) ->
          if err then reject(err) else resolve()

    if promises.length > 0
      rsvp.all(promises).then ->
        log.debug "Finished copying images in #{moment().diff startedAt}ms"
        resolve ctx
    else
      log.debug "No images found"
      resolve ctx

signalDone = (ctx) ->
  new Promise (resolve, reject) ->
    log "Build finished in #{moment().diff ctx.startedAt}ms"
    resolve ctx

signalError = (err) ->
  log "Error building", err, err.stack

module.exports = run: (args) ->
  startBuild(args: args).then (ctx) ->
    compileTemplates ctx
  .then (ctx) ->
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
