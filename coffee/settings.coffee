window.addEventListener 'load', ->
    C.init()

C =
    stack :
        local : {}
        sync  : {}

    init : ->
        chrome.storage.local.get 'setting', (items) ->
            C.stack.local = items['setting'] || {}

            chrome.storage.sync.get 'setting', (items) ->
                C.stack.sync = items['setting'] || {}

                C.$fields = []
                for tagName in [ 'textarea', 'input' ]
                    eles = document.getElementsByTagName tagName
                    C.$fields.push ele for ele in eles

                for $field in C.$fields
                    C.recover.call $field
                    $field.addEventListener 'input', C.change

    recover : ->
        $this = this

        type        = $this.getAttribute 'd-type'
        key         = $this.getAttribute 'name'
        $this.value = C.stack[type][key] || ''

    change : ->
        $this = this

        clearTimeout $this.timer_input if $this.timer_input

        $this.timer_input = setTimeout ->
            type  = $this.getAttribute 'd-type'
            key   = $this.getAttribute 'name'
            value = $this.value

            C.stack[type][key] = value
            C.save(type)
        , 500

    save : (type, callback) ->
        chrome.storage[type].set
            setting : C.stack[type]
        , callback
