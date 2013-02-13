###
  Usage:

  Keys are case-sensitive.
  Must specify the chain down to the key you want to search on,
  i.e. "To:first_name" to search on first_name.

  Filter accepts params in either key/value or an object. You can chain 
  the filter method.
###

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
      obj[params[0]] = params[1]
      @filters.push obj
    else
      # params is object
      console.log params
      for key, value of params[0]
        obj = {}
        obj[key] = value
        @filters.push obj

      console.log @filters
    return @

  go: (cb) =>
    # Buildup URI
    url = 'filters'
    for filter in @filters
      for key, value of filter # only "loops" once.
        keys = key.split ':'
        for key in keys
          url += "[#{key}]"

        url += "=#{value}&"

    url = @base + url.slice(0, url.length - 1)
    $.getJSON url, (result) ->
      cb result

window.Searcher = Searcher

s = new Searcher
s.filter
  'Locations:city': 'chicago'
  'Locations:provence': 'IL'

s.go (data) ->
  console.log data

