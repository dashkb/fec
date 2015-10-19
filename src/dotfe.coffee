fs = require 'fs'
path = require 'path'
yaml = require 'js-yaml'
envfile = require 'envfile'
log = require './log'
cfg = undefined

readConfigFile = (dir) ->
  try
    src = fs.readFileSync("#{dir}/.fe").toString()
    log "Using .fe from #{dir}"
    src
  catch
    unless dir == '/'
      readConfigFile path.resolve dir, '../' unless dir == '/'
    else
      log "No .fe found.  Consider creating one."

loadConfig = ->
  src = readConfigFile process.cwd()
  if src
    if src.match /^{/
      parseFn = JSON.parse
    else if src.match /^---/ || src.match /^%YAML/
      parseFn = (str) -> yaml.load(str)[0]
    else
      parseFn = envfile.parseSync

    try
      parseFn src
    catch e
      throw "Error parsing .fe: #{e}."
  else
    {}

module.exports =
  load: ->
    cfg ||= loadConfig()
