setting =
    local : {}
    sync  : {}

chrome.storage.local.get 'setting', (items) ->
    setting.local = items['setting'] || {}

    chrome.storage.sync.get 'setting', (items) ->
        setting.sync = items['setting'] || {}

        C.fold.init()


C = {}

C.fold =
    init : ->
        me = C.fold

        me.initAutoFoldPatterns()

        $('.file').each ->
            $this = $(this)
            $meta = $('.meta', $this)
            path  = $meta.attr 'data-path'

            $meta.on 'click', (e) ->
                $this.toggleClass 'fold'

            for pattern in me.autoFoldPatterns
                if pattern.test path
                    $this.addClass 'fold'
                    break

    initAutoFoldPatterns : ->
        me = C.fold

        patterns = if typeof setting.sync['autoFoldPatterns'] is 'undefined' then '' else setting.sync['autoFoldPatterns']
        patterns = patterns.split '\n'

        me.autoFoldPatterns = []
        for pattern in patterns
            me.autoFoldPatterns.push new RegExp(pattern) unless /^\s*$/.test pattern
