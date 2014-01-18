_         = require 'lodash'
fs        = require 'fs'
path      = require 'path'
{exec}    = require 'child_process'
fm        = require 'front-matter'
glob      = require 'glob'
rsvp      = require 'rsvp'
hamlc     = require 'haml-coffee'
marked    = require 'marked'
highlight = require 'highlight.js'
moment    = require 'moment'
slugify   = require 'slug'
Promise   = rsvp.Promise
log       = require './log'

dateFormat = 'MMMM Do YYYY, h:mm:ss a'

extractFrontMatter = (ctx) ->
  new Promise (resolve, reject) ->
    log.debug "Started extracting front matter"
    files = glob.sync "#{ctx.cmd.srcDir}/**/*.md"
    ctx.pageMetadata = _.reduce files, (data, file) ->
      relativePath = path.relative ctx.cmd.srcDir, file
      {attributes, body} = fm fs.readFileSync file, encoding: 'utf8'

      fs.writeFileSync "#{ctx.cmd.buildDir}/#{relativePath}", body

      data[relativePath] = _.extend attributes,
        slug: slug = attributes.slug || slugify(attributes.title).toLowerCase()
        path: "#{path.dirname relativePath}/#{slug}.html"
      data
    , {}

    log.debug "Finished extracting front matter"
    resolve ctx

addGitMetadata = (ctx) ->
  new Promise (resolve, reject) ->
    log.debug "Started extracting git metadata"
    files = glob.sync "#{ctx.cmd.srcDir}/**/*.md"
    promises = _.map files, (file) ->
      relativePath = path.relative ctx.cmd.srcDir, file
      new Promise (resolve, reject) ->
        exec "git log --pretty=\"format:%h|%ai\" #{file}", (err, output) ->
          md = ctx.pageMetadata[relativePath]
          md.revisions = _.map (output.split "\n"), (line) ->
            [sha, date] = line.split '|'
            {sha: sha, date: date}
          resolve()

    rsvp.all(promises).then ->
      log.debug "Finished extracting git metadata"
      resolve ctx

renderPages = (ctx) ->
  log.debug "Started compiling templates"
  files = glob.sync "#{ctx.cmd.srcDir}/**/*.hamlc"
  templates = _.reduce files, (templates, file) ->
    relativePath = path.relative ctx.cmd.buildDir, file
    relativePath = path.basename relativePath, '.hamlc'
    templates[relativePath] = hamlc.compile String fs.readFileSync file
    templates
  , {}
  log.debug "Finished compiling templates"

  new Promise (resolve, reject) ->
    log.debug "Started rendering pages"
    files = glob.sync "#{ctx.cmd.buildDir}/**/*.md"
    _.each files, (file) ->
      relativePath = path.relative ctx.cmd.buildDir, file
      md = fs.readFileSync file
      html = marked String(md),
        gfm: true
        tables: true
        smartypants: true
        smartLists: true
        highlight: (code) -> highlight.highlightAuto(code).value

      pageData =
        site:
          pages: ctx.pageMetadata
        page: _.extend ctx.pageMetadata[relativePath], html: html
        JST: templates
        helpers:
          date: (date) -> moment(date).format(dateFormat)
          _: _

      dest = "#{ctx.cmd.buildDir}/#{pageData.page.path}"
      fs.writeFileSync dest, templates['site'](pageData)
      fs.unlinkSync file

    log.debug "Finished rendering pages"
    resolve ctx

module.exports = buildPages = (ctx) ->
  log.debug "Started building pages"
  new Promise (resolve, reject) ->
    extractFrontMatter(ctx).then (ctx) ->
      addGitMetadata ctx
    .then (ctx) ->
      renderPages ctx
    .then (ctx) ->
      log.debug "Finished building pages"
      resolve ctx
    .then null, (err) ->
      reject err
