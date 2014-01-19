# roots v2.1.0
roots = require 'roots'
fs = require 'fs'
Builder = require 'component-builder'

roots.compiler.on('finished', (err) ->
  builder = new Builder('./')
  builder.build((err, res) ->
    if err
      console.log(err)
    else
      fs.writeFile("./public/main.js", res.require + res.js, (err) ->
        if err
          console.log(err)
        else
          console.log('built public/main.js')
      )
  )
)

# Files in this list will not be compiled - minimatch supported
ignore_files: ['_*', 'readme*', '.gitignore', '.DS_Store', '*.log']
ignore_folders: ['.git', 'node_modules']

# Layout file config
# `default` applies to all views.
layouts:
  default: 'layout.jade'

locals:
  title: 'C.O.R.E. 2062'

stylus:
  plugins: [module.require('nib')]
