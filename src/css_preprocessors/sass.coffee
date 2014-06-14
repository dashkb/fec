moment = require 'moment'
{Promise} = require 'rsvp'
glob = require 'glob'
fs = require 'fs'
log = require '../log'
sass = require 'node-sass'
_ = require 'lodash'

module.exports = (ctx) ->
  startedAt = moment()
  new Promise (resolve, reject) ->
    files = glob.sync "#{ctx.args.srcDir}/**/*.+(sass|scss|css)"
    src = _.reduce files, (src, path) ->
      src + fs.readFileSync path
    , ''

    sass.render
      includePaths: [ctx.args.srcDir, ctx.args.bowerDir]
      imagePath: "#{ctx.args.buildDir}/images"
      data: src
      outputStyle: if ctx.args.compress then 'compressed' else 'nested'
      success: (css) ->
        fs.writeFile "#{ctx.args.buildDir}/css/all.css", css, (err) ->
          if err
            reject err
          else
            log.debug "Finished compiling styles in #{moment().diff startedAt}ms"
            resolve ctx
      error: (err) ->
        reject err

