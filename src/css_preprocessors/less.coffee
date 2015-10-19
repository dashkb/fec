moment = require 'moment'
fs = require 'fs'
less = require 'less'
{Promise} = require 'rsvp'
glob = require 'glob'
_ = require 'lodash'
log = require '../log'

module.exports = (ctx) ->
  startedAt = moment()
  new Promise (resolve, reject) ->
    files = glob.sync "#{ctx.args.srcDir}/**/*.+(less|css)"
    src = _.reduce files, (src, path) ->
      src + fs.readFileSync path
    , ''

    # parser = new less.Parser
    #   paths: [ctx.args.srcDir, ctx.args.bowerDir]
    #   filename: 'bundle.less'

    rootFileInfo =
      currentDirectory: ctx.args.srcDir
      rootPath: ctx.args.srcDir
      relativeUrls: true

    paths = [ctx.args.bowerDir]

    less.render(src, rootFileInfo: rootFileInfo, paths: paths).then ({css, map}) ->
      fs.writeFileSync "#{ctx.args.buildDir}/css/all.css", css
      log.debug "Finished compiling styles in #{moment().diff startedAt}ms"
      resolve ctx
    .then null, (err) ->
      log.debug "Error compiling styles: #{err}"


    # parser.parse src, (err, tree) ->
    #   if err
    #     reject err
    #   else
    #     css = tree.toCSS compress: ctx.args.compress
    #     fs.writeFileSync "#{ctx.args.buildDir}/css/all.css", css
    #     log.debug "Finished compiling styles in #{moment().diff startedAt}ms"
    #     resolve ctx

