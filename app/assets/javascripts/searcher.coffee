###
  Usage:

  Keys are case-sensitive.
  Must specify the chain down to the key you want to search on,
  i.e. "To:first_name" to search on first_name.

  Filter accepts params in either key/value or an object. You can chain 
  the filter method.

  Note: Filters are applied by logical AND.

  Top-level keys: ["To", "From", "Dates", "Subject", "Locations", "Summary"]
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
    else if params.length is 1
      # params is object
      console.log params
      for key, value of params[0]
        obj = {}
        obj[key] = value
        @filters.push obj
    else
      # Invalid params.
      throw new RangeError('Must supply a filter.')

    return @

  go: (cb) =>
    # Buildup URI
    if @filters.length is 0
      throw new RangeError('Must apply a filter.')
      return @

    url = ''
    for filter in @filters
      url += 'filters'
      for key, value of filter # only "loops" once.
        keys = key.split ':'
        for key in keys
          url += "[#{key}]"

        url += "=#{value}&"

    url = @base + url.slice(0, url.length - 1)
    $.getJSON url, (result) ->
      cb result

window.Searcher = Searcher