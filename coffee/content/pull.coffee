setting =
    local : {}
    sync  : {}

chrome.storage.local.get 'setting', (items) ->
    setting.local = items['setting'] || {}

    chrome.storage.sync.get 'setting', (items) ->
        setting.sync = items['setting'] || {}

        C.fold.init()
        C.stick.init()
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

helper.isGitHubAccountSet = () ->
    setting.local['token']

helper.api = (options) ->
    return unless helper.isGitHubAccountSet()

    options.url     = "https://api.github.com#{options.url}"
    options.headers = { Authorization : "token #{setting.local['token']}" }
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

        patterns = if typeof setting.sync['autoFoldPatterns'] is 'undefined' then '' else setting.sync['autoFoldPatterns']
        patterns = patterns.split '\n'

        me.autoFoldPatterns = []
        for pattern in patterns
            me.autoFoldPatterns.push new RegExp(pattern) unless /^\s*$/.test pattern


C.stick = 
    $elements : [
        '.discussion-sidebar'
        '.repository-sidebar'
    ],

    init : () ->
        me = C.stick

        for i, selector of me.$elements
            $ele            = $(selector)
            $ele.offsetTop  = $ele.offset().top - 20
            me.$elements[i] = $ele

        $(window).on 'scroll', me.check

    check : () ->
        me = C.stick

        st = $(window).scrollTop()

        for $ele in me.$elements
            if st > $ele.offsetTop
                $ele.addClass 'github-reviewer--stick'
            else
                $ele.removeClass 'github-reviewer--stick'


C.labels =
    allLabels     : []
    activeLabels  : []
    hasPermission : true

    init : () ->
        me = C.labels

        return unless helper.isGitHubAccountSet()

        me.createBlockLabels()
        me.retriveAllLabels()
        me.retrivePullLabels()

        me.$blockLabels.on 'click', '> li', me.toggleLabel

    createBlockLabels : () ->
        me = C.labels

        me.$sidebar = $('.discussion-sidebar')
        me.$sidebar.append '<hr />'
        me.$sidebar.append '<strong>Labels</strong>'

        me.$blockLabels = $('<ul class="github-reviewer-blockLabels"></ul>')
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

        return unless me.hasPermission

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
            error    : (d) ->
                me.hasPermission = false
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
            error    : (d) ->
                me.hasPermission = false
                me.render()
