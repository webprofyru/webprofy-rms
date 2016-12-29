gulp = require 'gulp'
gulpsync = require("gulp-sync")(gulp)

gulp.task "default", gulpsync.sync [ # sync
  'cleanup'
  'build'
  # async
  ['watch', 'browserSync']]
