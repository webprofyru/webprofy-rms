gulp = require "gulp"
handleErrors = require "../util/handleErrors"
jade = require('gulp-jade')

config = require("../config").jadeScript

gulp.task "jadeScript", (->
  return gulp.src(config.src)
    .pipe(jade({client: true})).on("error", handleErrors)
    .pipe(gulp.dest(config.dest)))
