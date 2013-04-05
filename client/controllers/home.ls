
Sparrow = {}
Sparrow.shift = ->
  Session.get "shift_area"

statCurrent = ->
  out =
    query:
      tagset : Store.get("current_tagsets")
      tag    : Store.get("current_tags")
      sort:
        verbose   : Store.get("current_sorts")
        specifier : Store.get("current_sorts_specifier")
        selector  : Store.get("current_sorts_selector")
        order     : Store.get("current_sorts_order")

    verbose:
      tagset        : Store.get("current_tagsets")
      tag           : Store.get("current_tags")
      sort          : Store.get("current_sorts")
      sort_selector : Store.get("current_sorts_selector")

  out

statRange = ->
  out =
    max:
      updatedAt   : amplify.store("max_updatedAt")
      nearest     : amplify.store("max_nearest")
      points      : amplify.store("max_points")
      price       : amplify.store("max_price")

    min:
      updatedAt   : amplify.store("min_updatedAt")
      nearest     : amplify.store("min_nearest")
      points      : amplify.store("min_points")
      price       : amplify.store("min_price")

  out


Template.wrapper.rendered = ->
  Session.setDefault "rendered_wrapper", true

Template.wrapper.events {}=

  "click .shift": (event, tmpl) ->

    if event.currentTarget.hasAttribute("disabled") then return

    dir     = event.currentTarget.getAttribute("data-shift-direction")
    area    = event.currentTarget.getAttribute("data-shift-area")
    page    = Meteor.Router.page()
    current = page.split("_")[0]

    store_area     = Store.get("page_" + area) or area
    store_sub_area = Store.get("page_" + store_area )

    sub_area       = store_sub_area or store_area

    # # console.log("DIR", dir)
    # console.log("AREA", area)
    # console.log("SUB AREA", sub_area)
    # # console.log("PAGE", page)
    # console.log("CURRENT", current)

    Session.set "shift_direction", dir
    Session.set "shift_area", area
    Session.set "shift_sub_area", sub_area
    Session.set "shift_current", current



Template.content.events {}=

  'click .accord header': (event, tmpl) ->
    if not $(event.target).hasClass "active"
      $(event.currentTarget).siblings().slideDown()
    else
      $(event.currentTarget).siblings().slideUp()
    $(event.target).toggleClass "active"



#////////////////////////////////////////////
#  $$ home

class Conf
  (current)->

    @sort = {}
    if current.sort.verbose?.length
      @sort[current.sort.specifier] = {}
      @sort[current.sort.specifier][current.sort.selector] = current.sort.order
    else
      @sort_empty = true

    @query = {}
    if current.tagset?.length
      @query.tagset = current.tagset.toString()
      if current.tag?.length
        @query.tags = $in: current.tag

Template.home.helpers {}=
  get_offers: ->

    @coll ?= new Meteor.Collection null

    switch 
    | not @offers          => @offers = Offer.load-all @coll
    | @offers.length <= 0  => @offers = Offer.load-all @coll
    | _                    => console.log "CACHE USED"

    unless @offers => return

    current = stat-current!query
    my-loc  = Store.get "user_loc"
    conf    = new Conf(current)

    ranges =
      updatedAt   : []
      nearest     : []
      points      : []
      price       : []

    notes =
      count: 0
      votes: 0

    result = @coll.find(
      conf.query,
      conf.sort,
      reactive: true
    ).map (d)->
        d.rand = _.random 0, 999

        for r of ranges
          ranges[r].push d[r]

        notes.count +=1
        notes.votes += d.points

        if conf.sort_empty and d.rand
          d.shuffle = current.sort.order * d.rand
          d.shuffle = parseInt( d.shuffle.to-string!.slice(1,4) )

        d

    if result and myLoc

      for r of ranges
        amplify.store "max_#{r}", _.max(ranges[r])
        amplify.store "min_#{r}", _.min(ranges[r])

      for n of notes
        notes[n] = numberWithCommas(notes[n])

      Store.set "notes", notes

      if conf.sort_empty
        return result = _.sort-by(result, "shuffle")
      else
        return result

      result

    result



  styleDate: (date) ->
    moment(date).fromNow()


#////////////////////////////////////////////
#  $$ intro

Template.intro.events {}=
  'click #getLocation': (event, tmpl) ->
    Meteor.Alert.set {}=
      text: "One moment while we charge the lasers..."
      wait: true

    noLocation = ->
      Meteor.Alert.set text: "Uh oh... something went wrong"

    foundLocation = (location) ->
      Meteor.Alert.set text: "Booya! Lasers charged!"

      Store.set "user_loc",
        lat: location.coords.latitude
        long: location.coords.longitude

    navigator.geolocation.getCurrentPosition foundLocation, noLocation

  'click .geolocate': (event, tmpl)->

    location = tmpl.find("input").value
    if not location
      Meteor.Alert.set text: "No location entered"
      return

    Meteor.Alert.set {}=
      text: "One moment..."
      wait: true

    geo = new google.maps.Geocoder()
    geo.geocode {}=
      address: location
    , (results, status) ->
      if status isnt "OK"
        Meteor.Alert.set text: "We couldn't seem to find your location. Did you enter your address correctly?"

      else
        Meteor.Alert.set text: "Found ya!"

        loc = results[0].geometry.location
        userLoc = []
        for key of loc
          if typeof loc[key] isnt 'number' then break
          userLoc.push loc[key]
        console.log("USERLOC", userLoc)

        Store.set "user_loc",
          lat: userLoc[0]
          long: userLoc[1]


Template.intro.rendered = ->
  window_height = $(".current").height() / 2
  intro = $(@find('#intro'))
  intro_height = (intro.outerHeight() * 0.75)
  intro.css {}=
    'margin-top': window_height - intro_height
