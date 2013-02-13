class Searcher
  base: '/transcriptions/annotations/?'

  @baseUrl: ->
    return base

  constructor: ->
    @filters = []

  filter: (params...) =>
    if params.length is 2
      # params is key/value
      obj = {}
      obj[key] = value
      @filters.push obj
    else
      # params is object
      for key, value of params
        obj = {}
        obj[key] = value
        @filters.push obj

    return @

  go: (cb) =>
    # Buildup URI
    url = ''
    for filter in @filters
      for key, value of filter
        url = 'filter'
        keys = key.split ':'

        for key of keys
          url += "[#{key}]"

        url += "=#{value}&"

    url = @base + url.slice(0, url.length - 1)
    $.getJSON url, (result) ->
      cb result

window.Searcher = Searcher

s = new Searcher
s.filter('to:first_name','first');
s.filter
  city: 'chicago'
  provence: 'IL'

s.go (data) ->
  console.log data

