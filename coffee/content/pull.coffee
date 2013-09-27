setting = {}
chrome.storage.sync.get 'setting', (items) ->
    setting = items['setting'] || {}

    C.fold.init()
    C.labels.init()


helper = {}

helper.params = (key) ->
    return arguments.callee.stack[key] if arguments.callee.stack

    matches = window.location.href.match /\/\/.+?\/(.+?)\/(.+?)\/pull\/(\d+)/
    arguments.callee.stack =
        owner  : matches[1]
        repo   : matches[2]
        number : matches[3]

    arguments.callee.stack[key]

helper.api = (options) ->
    return unless setting['username'] and setting['password']

    options.url     = 'https://api.github.com' + options.url
    options.headers = { Authorization : 'Basic ' + window.btoa "#{setting['username']}:#{setting['password']}" }
    $.ajax options


C = {}

C.fold =
    init : () ->
        me = C.fold

        me.initAutoFoldPatterns()

        $('.file').each () ->
            $this = $(this)
            $meta = $('.meta', $this)
            path  = $meta.attr 'data-path'

            $meta.on 'click', (e) ->
                $this.toggleClass 'fold'

            for pattern in me.autoFoldPatterns
                if pattern.test path
                    $this.addClass 'fold'
                    break

    initAutoFoldPatterns : () ->
        me = C.fold

        patterns = if typeof setting['autoFoldPatterns'] is 'undefined' then '' else setting['autoFoldPatterns']
        patterns = patterns.split '\n'

        me.autoFoldPatterns = []
        for pattern in patterns
            me.autoFoldPatterns.push new RegExp(pattern) unless /^\s*$/.test pattern


C.labels =
    allLabels    : []
    activeLabels : []

    init : () ->
        me = C.labels

        me.createBlockLabels()
        me.retriveAllLabels()
        me.retrivePullLabels()

        me.$blockLabels.on 'click', '> li', me.toggleLabel

    createBlockLabels : () ->
        me = C.labels

        me.$sidebar = $('.discussion-sidebar')
        me.$sidebar.append '<hr />'
        me.$sidebar.append '<strong>Labels</strong>'

        me.$blockLabels = $('<ul class="github-folder-blockLabels"></ul>')
        me.$sidebar.append me.$blockLabels

    retriveAllLabels : () ->
        me = C.labels

        helper.api
            url      : '/repos/' + helper.params('owner') + '/' + helper.params('repo') + '/labels'
            type     : 'GET'
            dataType : 'json'
            success  : (d) ->
                me.allLabels = d
                me.render()

    retrivePullLabels : () ->
        me = C.labels

        helper.api
            url      : '/repos/' + helper.params('owner') + '/' + helper.params('repo') + '/issues/' + helper.params('number') + '/labels'
            type     : 'GET'
            dataType : 'json'
            success  : (d) ->
                me.activeLabels = d
                me.render()

    render : () ->
        me = C.labels

        me.$blockLabels.empty()

        for label in me.allLabels
            $label = $("<li>#{label.name}</li>")
            $label.attr
                'name'  : label.name
                'title' : label.name
            $label.css
                'border-left-color' : "##{label.color}"

            for activeLabel in me.activeLabels
                if activeLabel.name is label.name
                    $label.addClass 'active'
                    break

            me.$blockLabels.append $label

    toggleLabel : () ->
        me    = C.labels
        $this = $(this)

        name = $this.attr 'name'

        $this.addClass 'loading'
        if $this.hasClass('active') then me.removeLabel(name) else me.addLabel(name)

    addLabel : (name) ->
        me = C.labels

        helper.api
            url      : '/repos/' + helper.params('owner') + '/' + helper.params('repo') + '/issues/' + helper.params('number') + '/labels'
            type     : 'POST'
            data     : JSON.stringify [ name ]
            dataType : 'json'
            success  : (d) ->
                me.activeLabels = d
                me.render()

    removeLabel : (name) ->
        me = C.labels

        name = encodeURIComponent name

        helper.api
            url      : '/repos/' + helper.params('owner') + '/' + helper.params('repo') + '/issues/' + helper.params('number') + '/labels/' + name
            type     : 'DELETE'
            dataType : 'json'
            success  : (d) ->
                me.activeLabels = d
                me.render()
