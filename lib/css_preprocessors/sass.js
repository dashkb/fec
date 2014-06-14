// Generated by CoffeeScript 1.7.1
(function() {
  var Promise, fs, glob, log, moment, sass, _;

  moment = require('moment');

  Promise = require('rsvp').Promise;

  glob = require('glob');

  fs = require('fs');

  log = require('../log');

  sass = require('node-sass');

  _ = require('lodash');

  module.exports = function(ctx) {
    var startedAt;
    startedAt = moment();
    return new Promise(function(resolve, reject) {
      var files, src;
      files = glob.sync("" + ctx.args.srcDir + "/**/*.+(sass|scss|css)");
      src = _.reduce(files, function(src, path) {
        return src + fs.readFileSync(path);
      }, '');
      return sass.render({
        includePaths: [ctx.args.srcDir, ctx.args.bowerDir],
        imagePath: "" + ctx.args.buildDir + "/images",
        data: src,
        outputStyle: ctx.args.compress ? 'compressed' : 'nested',
        success: function(css) {
          return fs.writeFile("" + ctx.args.buildDir + "/css/all.css", css, function(err) {
            if (err) {
              return reject(err);
            } else {
              log.debug("Finished compiling styles in " + (moment().diff(startedAt)) + "ms");
              return resolve(ctx);
            }
          });
        },
        error: function(err) {
          return reject(err);
        }
      });
    });
  };

}).call(this);