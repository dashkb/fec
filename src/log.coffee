_         = require 'lodash'
{inspect} = require 'util'
moment    = require 'moment'
opts      = 
  timeFormat: "HH:mm:ss"
  defaultLevel: 'info'
  threshold: 'debug'
  levels: ['trace', 'debug', 'info', 'warn', 'error']

n = (level) -> opts.levels.indexOf level

timestamp    = -> moment().format opts.timeFormat
createLogFns = ->
  _.reduce opts.levels, (fns, level) ->
    fns[level] = (msg...) ->
      msg = _.map msg, (item) -> if typeof(item) == 'string' then item else inspect item
      if n(level) >= n(opts.threshold)
        console.log "#{timestamp()} #{msg.join()}"
    fns
  , {}

log = (msg...) ->
  log[opts.defaultLevel] msg...

_.extend log, createLogFns(),
  setThreshold: (threshold) -> opts.threshold = threshold
  setLevels: (levels...) ->
    _.each opts.levels, (level) -> delete log[level]
    opts.levels = levels
    _.extend log, createLogFns()

log.timePromise = (p, msg, level = 'debug') ->
  start = moment()
  p.then ->
    log[level] "#{msg} #{moment().diff start}ms"
  .then null, ->
    log[level] "#{msg} failed #{moment().diff start}ms"

  p

module.exports = log
