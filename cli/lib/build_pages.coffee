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
Moment    = require 'moment'
Promise   = rsvp.Promise

extractFrontMatter = (ctx) ->
  new Promise (resolve, reject) ->
    files = glob.sync "#{ctx.cmd.srcDir}/**/*.md"
    ctx.pageMetadata = _.reduce files, (data, file) ->
      relativePath = path.relative ctx.cmd.srcDir, file
      {attributes, body} = fm fs.readFileSync file, encoding: 'utf8'

      fs.writeFileSync "#{ctx.cmd.buildDir}/#{relativePath}", body
      data[relativePath] = attributes
      data
    , {}

    resolve ctx

addGitMetadata = (ctx) ->
  new Promise (resolve, reject) ->
    files = glob.sync "#{ctx.cmd.srcDir}/**/*.md"
    promises = _.map files, (file) ->
      relativePath = path.relative ctx.cmd.srcDir, file
      new Promise (resolve, reject) ->
        exec "git log --pretty=\"format:%h|%ai\" #{file}", (err, output) ->
          md = ctx.pageMetadata[relativePath]
          md.revisions = _.map (output.split "\n"), (line) ->
            [sha, date] = line.split '|'
            {sha: sha, date: new Moment date}
          resolve()

      promises
    , {}

    rsvp.all(promises).then ->
      resolve ctx

renderPages = (ctx) ->
  layout = hamlc.compile String fs.readFileSync "#{ctx.cmd.srcDir}/layout.hamlc"
  nav    = hamlc.compile String fs.readFileSync "#{ctx.cmd.srcDir}/nav.haml"

  new Promise (resolve, reject) ->
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
        page: ctx.pageMetadata[relativePath]
        nav: nav
        content: html

      fs.writeFileSync file.replace('md', 'html'), layout(pageData)
      fs.unlinkSync file

    resolve ctx

module.exports = buildPages = (ctx) ->
  new Promise (resolve, reject) ->
    extractFrontMatter(ctx).then (ctx) ->
      addGitMetadata ctx
    .then (ctx) ->
      renderPages ctx
    .then (ctx) ->
      resolve ctx
