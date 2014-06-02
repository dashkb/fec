// Generated by CoffeeScript 1.7.1
(function() {
  var browserify, exportArgs, fs, log, path, yargs, _;

  _ = require('lodash');

  yargs = require('yargs');

  path = require('path');

  log = require('./log');

  fs = require('fs');

  browserify = require('browserify');

  exportArgs = yargs.demand(['sourceFile', 'outFile']).alias('s', 'sourceFile').alias('o', 'outFile').alias('r', 'requireAs').argv;

  module.exports = {
    run: function(args) {
      var bundle;
      _.extend(args, exportArgs);
      args.requireAs || (args.requireAs = args.sourceFile);
      bundle = browserify({
        extensions: ['.jst', '.coffee', '.js']
      });
      bundle.require(args.sourceFile);
      bundle.transform(require('coffeeify'));
      if (args.compress) {
        bundle.transform(require('uglifyify'));
      }
      bundle.transform(require('debowerify'));
      return bundle.bundle(function(err, src) {
        if (err) {
          return log("Error: " + err);
        } else {
          fs.writeFileSync(args.outFile, "module.exports = " + src + "(\"" + args.requireAs + "\");");
          return log.debug("Exported");
        }
      });
    }
  };

}).call(this);