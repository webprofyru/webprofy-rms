gulp = require 'gulp'
gutil = require 'gulp-util'
sass = require 'gulp-sass'
handleErrors = require '../util/handleErrors'
autoprefixer = require 'gulp-autoprefixer'
minifyCss = require 'gulp-minify-css'
rename = require 'gulp-rename'

config = require('../config').sass

gulp.task "sass", (->
  res = gulp.src(config.src)
    .pipe(sass(config.settings)).on("error", handleErrors)
    .pipe(autoprefixer(browsers: ["last 6 version"]))

  if !gutil.env.dev
    res = res
      .pipe(minifyCss())
      .pipe(rename(extname: '.min.css'))

  return res.pipe(gulp.dest(config.dest)))
