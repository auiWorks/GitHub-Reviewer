window.addEventListener 'load', ->
    C.init()

C =
    init : ->
        chrome.storage.sync.get 'setting', (items) ->
            C.stack = items['setting'] || {}

            C.$fields = document.getElementsByTagName 'textarea';

            for $field in C.$fields
                C.recover.call $field
                $field.addEventListener 'input', C.change

    recover : ->
        $this = this

        key         = $this.getAttribute 'name'
        $this.value = C.stack[key] || ''

    change : ->
        $this = this

        clearTimeout $this.timer_input if $this.timer_input

        $this.timer_input = setTimeout ->
            key   = $this.getAttribute 'name'
            value = $this.value

            C.stack[key] = value
            C.save()
        , 500

    save : (callback) ->
        chrome.storage.sync.set
            setting : C.stack
        , callback
