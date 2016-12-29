# Notes:
#   - gulp/tasks/browserify.js handles js recompiling with watchify
#   - gulp/tasks/browserSync.js watches and reloads compiled files
#
gulp = require 'gulp'
config = require '../config'

gulp.task 'watch', (->
  # Note: coffee is watched by watchify within browserify task
  gulp.watch config.jade.watch, ['jade']
  gulp.watch config.sass.src, ['sass']
  gulp.watch config.images.src, ['images']
  gulp.watch config.copyData.data + '/**', ['copyData']
  gulp.watch config.copyData.src + '/CNAME', ['copyCNAME']
  gulp.watch config.jadeScript.src, ['jadeScript']
  return)
