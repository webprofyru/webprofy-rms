gutil = require 'gulp-util'

fs = require 'fs'

dest = './build'
src = './src'
app = './src/app'
test = './test'
libs = './static/libs'
data = './data'

module.exports =

  cleanup: dest

  jadeScript:
    src: "#{app}/svc/emails/_emailTemplate.jade"
    dest: dest

  copyLibs:
    dest: dest
    libs: libs

  copyData:
    src: src
    dest: dest
    data: data

  browserSync:

#    reloadDelay: 2000

    server:

    # We're serving the src folder as well
    # for sass sourcemap linking
      baseDir: [dest, src]

    files: [
        "#{dest}/**"
      # Exclude Map files
        "!#{dest}/**.map"
    ]

    middleware: ((req, res, next) ->
      if req.headers.accept?.indexOf('text/html') >= 0
        url = String req.url
        if url.indexOf('browser-sync-client') < 0
#          console.log "url: #{url}"
          if url.charAt(url.length - 1) == '/'
            url = url.substr(0, url.length - 1)
          try
            stats = fs.statSync(filePath = dest + url)
            if stats.isDirectory()
              try
                stats = fs.statSync(filePath += '/index.html')
                req.url = newUrl = "#{url}/index.html"
              catch e # no index.html in this folder
                req.url = newUrl = '/index.html' # default
          catch e # file not found
            if url.substr(url.lastIndexOf(filePath, '/') + 1).indexOf('.') < 0 # path without extention, so let's try to add .html
              try
                stats = fs.statSync(filePath += '.html')
                req.url = newUrl = "#{url}.html"
              catch e # file not found, again
                req.url = newUrl = '/index.html' # default
            else
              req.url = newUrl = '/index.html' # default
#          if newUrl
#            console.log "new url: #{req.url}"
      next())

  jade:
    indexSrc: "#{app}/index.jade"
    watch: "#{app}/**/*.jade"
    src: ["#{app}/**/*.jade", "!#{app}/**/_*.jade"]
    dest: dest

  test:
    src: "#{test}/**/*.jade"
    dest: dest

  sass:
    src: "#{src}/sass/**/*.sass"
    dest: dest
    settings:
    # Required if you want to use SASS syntax
    # See https://github.com/dlmanning/gulp-sass/issues/81
      sass: './src/sass'
      css: './build'
      sourceComments: "map"
      imagePath: "/images" # Used by the image-url helper
      indentedSyntax: true

  images:
    src: "#{src}/images/**"
    dest: "#{dest}/images"

  browserify:

  # Enable source maps
    debug: false

  # Additional file extentions to make optional
    extensions: [".coffee", ".hbs"]

  # A separate bundle will be generated for each
  # bundle config in the list below
    bundleConfigs: (-> 
      res = [{
        entries: app + "/app.coffee"
        dest: dest
        outputName: "app.js"}]
      
      if gutil.env.test
        res.push
          entries: test + "/test.coffee"
          dest: dest
          outputName: "test.js"
          
      return res)()
