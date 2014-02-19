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
  startedAt = moment()
  new Promise (resolve, reject) ->
    log.debug "Started extracting front matter"
    files = glob.sync "#{ctx.args.srcDir}/**/*.md"
    ctx.pageMetadata = _.reduce files, (data, file) ->
      relativePath = path.relative ctx.args.srcDir, file
      {attributes, body} = fm fs.readFileSync file, encoding: 'utf8'

      fs.writeFileSync "#{ctx.args.buildDir}/#{relativePath}", body

      slug = slugify(
        attributes.slug || attributes.title || path.basename(file, '.md')
      ).toLowerCase()
      dest = "#{path.dirname relativePath}/#{slug}.html"
      data[relativePath] = _.extend
        slug: slug
        path: dest
        template: 'article'
        index: true
      , attributes
      data
    , {}

    log.debug "Finished extracting front matter in #{moment().diff startedAt}ms"
    resolve ctx

addGitMetadata = (ctx) ->
  startedAt = moment()
  new Promise (resolve, reject) ->
    log.debug "Started extracting git metadata"
    files = glob.sync "#{ctx.args.srcDir}/**/*.md"
    promises = _.map files, (file) ->
      relativePath = path.relative ctx.args.srcDir, file
      new Promise (resolve, reject) ->
        exec "git log --follow --pretty=\"format:%h|%ai\" #{file}", (err, output) ->
          md = ctx.pageMetadata[relativePath]
          md.revisions = _.map (output.split "\n"), (line) ->
            [sha, date] = line.split '|'
            {sha: sha, date: date}
          resolve()

    rsvp.all(promises).then ->
      log.debug "Finished extracting git metadata in #{moment().diff startedAt}ms"
      resolve ctx

renderPages = (ctx) ->
  startedAt = moment()
  new Promise (resolve, reject) ->
    log.debug "Started rendering pages"

    files = glob.sync "#{ctx.args.buildDir}/**/*.md"
    _.each files, (file) ->
      relativePath = path.relative ctx.args.buildDir, file

      if ctx.args.renderDrafts || !ctx.pageMetadata[relativePath].draft
        md = fs.readFileSync file
        html = marked String(md),
          gfm: true
          tables: true
          smartypants: true
          smartLists: true
          highlight: (code, lang) -> highlight.highlight(lang, code).value
          langPrefix: ''

        pageData =
          site:
            pages: ctx.pageMetadata
          page: _.extend ctx.pageMetadata[relativePath], html: html
          JST: require "#{ctx.args.tmpDir}/templates.jst"
          helpers:
            date: (date) -> moment(date).format(dateFormat)
            _: _
            articles: _(ctx.pageMetadata).values().filter (page) ->
              # TODO this can't be here, too bloggy
              page.template == 'article' && page.index
            .sortBy (page) ->
              _.first(page.revisions).date
            .reverse().value()


        dest = "#{ctx.args.buildDir}/#{pageData.page.path}"
        fs.writeFileSync dest, pageData.JST[ctx.args.mainTemplate](pageData)
      fs.unlinkSync file

    log.debug "Finished rendering pages in #{moment().diff startedAt}ms"
    resolve ctx

module.exports = buildPages = (ctx) ->
  startedAt = moment()
  log.debug "Started building pages"
  new Promise (resolve, reject) ->
    extractFrontMatter(ctx).then (ctx) ->
      addGitMetadata ctx
    .then (ctx) ->
      renderPages ctx
    .then (ctx) ->
      log.debug "Finished building pages in #{moment().diff startedAt}ms"
      resolve ctx
    .then null, (err) ->
      reject err
