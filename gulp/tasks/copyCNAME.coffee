gulp = require("gulp")
config = require("../config").copyData

gulp.task "copyCNAME", [], ((cb) ->
  cnt = 2
  end = (->
    cb() if --cnt == 0
    return)
  gulp.src("#{config.src}/CNAME").pipe(gulp.dest(config.dest)).on('end', end)
  gulp.src("#{config.src}/.nojekyll").pipe(gulp.dest(config.dest)).on('end', end)
  return false)