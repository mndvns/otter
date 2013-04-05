
# j = Location.new()
# console.log j


# Meteor.absoluteUrl
#   replaceHost: true
#   rootUrl: "http://localhost:3000"

# Meteor.absoluteUrl
#   replaceHost: true
#   rootUrl: "http://deffenbaugh.herokuapp.com"



String::toProperCase = ->
  @replace /\w\S*/g, (txt) ->
    txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase()

String::repeat = (num)->
  out = new Array( num + 1 ).join ""
  out

arrayRepeat = (value, len) ->
  len +=1
  out = []
  while len -=1
    out.push(value)
  out




numberWithCommas = (x)->
  x?.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",")

# Color = net?.brehaut.Color

Time =
  now: ->
    Date.now()
  addMinutes: (time, min) ->
    moment(time).add('minutes', min).unix() * 1000

class Stopwatch
  constructor: (name)->
    window[name] = this
    @countKeeper = 1
    @start = Time.now()

  click: ~>
    @start = Time.now()
    @clicked  = true

  stop: ~>
    switch @clicked
      when false
        console.log("    redundant...")
        @clicked = null
      when null
        return
      when true
        switch @countKeeper
          when @count
            stopValue = numberWithCommas( Time.now() - @start ) + " milliseconds"
            console.log(stopValue, " for ", @count, " items")
            @clicked = false
          else
            @countKeeper += 1

  setCount: (count) ~>
    @count = count
    @countKeeper = 1


# log "------------"
# log ""
# 
# json = --> JSON.stringify it, void, 2
# 
# class Z
#   ->
#     @arg ?= arguments
#     [x, ...xs] = @arg
# 
#     @run  ?= ->
#       log x.toUpperCase!
#       json-it = (json) >> (log)
#       each json-it, xs
#       log ""
# 
#     global[ &0 ] = @
# 
#     @run!
# 
# j = Offer?.new!
# j?.setDefaults!
# 
# new Z \K, j
# 
# log "------------"
