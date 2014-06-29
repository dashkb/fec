{expect} = require 'chai'
{exec} = require 'child_process'
fs = require 'fs'

expectFile = (file, done) ->
  fs.open "#{process.cwd()}/fe/#{file}", 'r', (err) ->
    expect(err).to.be.null
    done()

describe 'fec new', ->
  before (done) ->
    process.chdir "#{__dirname}/new_project_test"
    exec 'fec new', (err, stdout) ->
      console.log stdout
      expect(err).to.be.null
      done()

  after (done) ->
    process.chdir "#{__dirname}/new_project_test"
    exec 'rm -rf fe tmp public', (err) ->
      expect(err).to.be.null
      done()

  it 'creates a directory', (done) ->
    fs.readdir "#{process.cwd()}/fe", (err, files) ->
      expect(err).to.be.null
      done()

  it 'creates the main template', (done) -> expectFile "fe.hamlc", done
  it 'creates the main stylesheet', (done) -> expectFile "fe.less", done
  it 'creates the main script', (done) -> expectFile "fe.coffee", done
  it 'creates an index.md', (done) -> expectFile "index.md", done

  #it 'creates a project which compiles', 
