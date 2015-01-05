module.exports = (grunt) ->
  process.on "uncaughtException", (e) ->
    grunt.log.error "Caught unhandled exception: #{e.toString()}"
    grunt.log.error e.stack

  grunt.initConfig
    clean: ['build', 'lib', 'demo/build']

    coffee:
      compile:
        cwd: 'src'
        src: '**/*.coffee'
        dest: 'lib'
        ext: '.js'
        expand: true
        options:
          sourceMap: true

    env:
      coverage:
        TEST_ROOT: __dirname + '/build/instrument/lib'

    instrument:
      files: 'lib/**/*.js'

    jasmine_node:
      options:
        coffee: true
      all: 'test/spec'

    makeReport:
      src: 'build/reports/coverage.json'

    coveralls:
      src: 'build/reports/lcov.info'

    open:
      coverage:
        path: 'build/reports/lcov-report/index.html'

    browserify:
        demo:
            files:
                'demo/build/demo.js': [
                    'src/**/*.coffee',
                    'demo/src/**/*.coffee',
                ]
            options:
                transform: ['coffeeify']
                browserifyOptions:
                    extensions: ['.coffee']

    uglify:
        demo:
            options:
                sourceMap: true
            files:
                'demo/build/demo.min.js': [
                    'demo/build/demo.js',
                ]

  grunt.loadNpmTasks 'grunt-browserify'
  grunt.loadNpmTasks 'grunt-contrib-clean'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-uglify'
  grunt.loadNpmTasks 'grunt-coveralls'
  grunt.loadNpmTasks 'grunt-env'
  grunt.loadNpmTasks 'grunt-istanbul'
  grunt.loadNpmTasks 'grunt-jasmine-node'
  grunt.loadNpmTasks 'grunt-newer'
  grunt.loadNpmTasks 'grunt-open'

  grunt.registerTask 'build', [
    'newer:coffee:compile',
    'newer:browserify:demo',
    'uglify:demo',
  ]

  grunt.registerTask 'test', ['build', 'jasmine_node']
  grunt.registerTask 't', 'test'

  grunt.registerTask 'pre-coverage', ['env:coverage', 'build', 'instrument']
  grunt.registerTask 'post-coverage', ['storeCoverage', 'makeReport']
  grunt.registerTask 'coverage', ['pre-coverage', 'test', 'post-coverage']
  grunt.registerTask 'open-coverage', ['coverage', 'open:coverage']
  grunt.registerTask 'c', 'coverage'

  grunt.registerTask 'travis', ['coverage', 'coveralls']

  grunt.registerTask 'default', 'test'
