gulp = require("gulp")
changed = require("gulp-changed")
config = require("../config").images

gulp.task "images", (->
  return gulp.src(config.src)
#    .pipe(changed(config.dest))
    .pipe(gulp.dest(config.dest)))
