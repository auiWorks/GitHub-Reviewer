chrome.storage.sync.get 'setting', (items) ->
    setting  = items['setting'] || {}
    patterns = typeof setting['autoFoldPatterns'] !== 'undefined' ? setting['autoFoldPatterns'] : ''
    patterns = patterns.split '\n'
    
    autoFoldPatterns = []
    for pattern in patterns
        autoFoldPatterns.push new RegExp(pattern) unless /^\s*$/.test pattern

    $files = document.getElementsByClassName 'file'

    for $file in $files
        do ($file) ->
            $meta = ($file.getElementsByClassName 'meta')[0]
            path  = $meta.getAttribute 'data-path'

            $meta.addEventListener 'click', (e) ->
                $file.classList.toggle 'fold'
            , false

            for pattern in autoFoldPatterns
                if pattern.test path
                    $file.classList.add 'fold'
                    continue
