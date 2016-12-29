fs = require 'fs'
gulp = require 'gulp'
rimraf = require 'rimraf'

config = require("../config").cleanup

gulp.task "cleanup", ((cb) ->

  fs.readdir "#{config}/**/*", ((err, files) =>
    if err
      if err.message.startsWith 'ENOENT: no such file or directory'
        cb()
        return
      throw new Error err
    n = 0
    for file in files when !(file == '.git' || file == '.svn')
      do (file) =>
        n++
        rimraf "#{@_folder}/#{file}", (->
          cb() if --n == 0
          return)
    cb() if n == 0
    return)

  return false)
