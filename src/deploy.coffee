_         = require 'lodash'
yargs     = require 'yargs'
path      = require 'path'
{Promise} = require 'rsvp'
{exec}    = require 'child_process'
log       = require './log'

deployArgs = yargs
  .default('sourceBranch', 'source')
  .default('deployBranch', 'master')
  .default('deployRemote', 'origin')
  .argv

module.exports = run: (args) ->
  _.extend args, deployArgs

  new Promise (done, fail) ->
    exec "git status", (err, out) ->
      if out.match /working directory clean/
        done()
      else
        fail "You must have a clean working directory to deploy.  Check the output of `git status`."
  .then ->
    new Promise (done, fail) ->
      log.debug "Building site..."
      exec "fetool build -c", (err, out) ->
        if err
          fail err
        else
          done()
  .then ->
    new Promise (done, fail) ->
      exec "git co #{args.deployBranch} &&
        sleep 0.1s; cp -R #{args.buildDir}/* ./ &&
        git add . && sleep 0.1s;
        git commit -m 'Update' &&
        sleep 0.1s;
        git push #{args.deployRemote} #{args.deployBranch}
      ", (err, stdout) ->
        if err
          exec "git clean -df && git co #{args.sourceBranch}", ->
            if stdout.match /nothing to commit/
              fail "There were no changes since the last deploy"
            else
              fail [err, stdout].join '\n'
        else
          exec "git co #{args.sourceBranch}", ->
            log.debug stdout
            done()
  .then ->
    log "Success!"
  .then null, (err) ->
    log.error "Error during deploy: #{err}"
    log.error "Cleanup was attempted; you should make sure nothing is busted."
    log.error "Specifically consider `git branch -f #{args.deployBranch} #{args.deployBranch}~`"
    process.exit 1
