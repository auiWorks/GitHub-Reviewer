module.exports = (grunt) ->
    grunt.initConfig
        pkg : grunt.file.readJSON 'package.json'

        compass :
            dist :
                options :
                    sassDir   : 'sass'
                    cssDir    : 'me/style'
                    imagesDir : 'me/image'
                    fontsDir  : 'me/font'

                    environment : 'production'
                    outputStyle : 'compressed'

        coffee :
            dist :
                expand  : true
                cwd     : 'coffee'
                src     : [ '**/*.coffee' ]
                dest    : 'me/script/'
                ext     : '.js'

        uglify :
            dist :
                expand  : true
                cwd     : 'me/script/'
                src     : [ '**/*.js' ]
                dest    : 'me/script/'
                ext     : '.js'

        watch :
            sass :
                files : [
                    'sass/**/*.sass'
                ]
                tasks : [
                    'compass'
                ]

            coffee :
                files : [
                    'coffee/**/*.coffee'
                ]
                tasks : [
                    'coffee'
                    'uglify'
                ]

    grunt.loadNpmTasks 'grunt-contrib-compass'
    grunt.loadNpmTasks 'grunt-contrib-coffee'
    grunt.loadNpmTasks 'grunt-contrib-uglify'
    grunt.loadNpmTasks 'grunt-contrib-watch'

    grunt.registerTask 'default', [
        'compass'
        'coffee'
        'uglify'
    ]
