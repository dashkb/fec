_         = require 'lodash'
path      = require 'path'
RSVP      = require 'rsvp'
{Promise} = RSVP
log       = require './log'
fs        = require 'fs'
{exec}    = require 'child_process'

examplesPath = "#{__dirname}/../example"

copyAndLogAndResolve = (ctx, src, dest, done, fail) ->
  exec "cp #{src} #{dest}", (err) ->
    if err
      fail err
    else
      log "wrote #{dest}"
      done ctx


createProjectDirectory = (ctx) ->
  new Promise (done, fail) ->
    fs.mkdir ctx.srcDir, (err) ->
      if err
        fail err
      else
        log "created project directory #{ctx.srcDir}"
        done ctx

writeMainTemplate = (ctx) ->
  new Promise (done, fail) ->
    src  = "#{examplesPath}/defaults/fe/fe.hamlc"
    dest = "#{ctx.srcDir}/#{ctx.mainTemplate}.hamlc"
    copyAndLogAndResolve ctx, src, dest, done, fail

writeMainStylesheet = (ctx) ->
  new Promise (done, fail) ->
    src  = "#{examplesPath}/defaults/fe/fe.less"
    dest = "#{ctx.srcDir}/#{ctx.mainStylesheet}.#{ctx.cssPreprocessor}"
    copyAndLogAndResolve ctx, src, dest, done, fail

writeMainScript = (ctx) ->
  new Promise (done, fail) ->
    src  = "#{examplesPath}/defaults/fe/fe.coffee"
    dest = "#{ctx.srcDir}/#{ctx.mainScript}"
    copyAndLogAndResolve ctx, src, dest, done, fail

writeIndexPage = (ctx) ->
  new Promise (done, fail) ->
    src  = "#{examplesPath}/defaults/fe/index.md"
    dest = "#{ctx.srcDir}/index.md"
    copyAndLogAndResolve ctx, src, dest, done, fail

module.exports = run: (args) ->
  createProjectDirectory(args).then (ctx) ->
    RSVP.all [
      writeMainTemplate(ctx),
      writeMainStylesheet(ctx),
      writeMainScript(ctx),
      writeIndexPage(ctx)
    ]

