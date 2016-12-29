browserify = require 'browserify'
watchify = require 'watchify'
bundleLogger = require '../util/bundleLogger'
gulp = require 'gulp'
gutil = require 'gulp-util'
handleErrors = require '../util/handleErrors'
source = require 'vinyl-source-stream2'
transform = require 'vinyl-transform'
rename = require 'gulp-rename'
buffer = require 'vinyl-buffer'

uglify = require 'gulp-uglifyjs'

config = require("../config").browserify

gulp.task "browserify", ((callback) ->
  bundleQueue = config.bundleConfigs.length
  browserifyThis = ((bundleConfig) ->

    bundler = browserify
      cache: {}
      packageCache: {}
      fullPaths: false
      entries: bundleConfig.entries
      extensions: config.extensions
      debug: config.debug

    bundle = (->
      bundleLogger.start bundleConfig.outputName

      res = bundler.bundle()
        .on('error', handleErrors)
        .pipe(source(bundleConfig.outputName))
        .pipe(buffer())

      if !gutil.env.dev
        res = res
          .pipe(rename(extname: '.min.js'))
          .pipe(uglify())

      res = res
        .pipe(gulp.dest(bundleConfig.dest))
        .on("end", reportFinished)

      return res)

    bundler = watchify(bundler)
    bundler.on "update", bundle

    reportFinished = (->
      bundleLogger.end bundleConfig.outputName
      if bundleQueue
        bundleQueue--
        callback()  if bundleQueue is 0
      return)

    bundle()

    return)

  config.bundleConfigs.forEach browserifyThis

  return false)
