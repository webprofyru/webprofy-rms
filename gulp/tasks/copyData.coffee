gulp = require("gulp")
config = require("../config").copyData

gulp.task "copyData", [], (->
  return gulp.src("#{config.data}/**").pipe(gulp.dest(config.dest + '/data')))
