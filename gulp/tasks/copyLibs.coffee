gulp = require("gulp")
config = require("../config").copyLibs

gulp.task "copyLibs", [], (->
  return gulp.src("#{config.libs}/**").pipe(gulp.dest(config.dest + '/libs')))
