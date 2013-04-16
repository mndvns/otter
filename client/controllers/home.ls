
@stat-current = ->
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

@stat-range = ->
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


Template.main.rendered = ->
  Session.setDefault "rendered_main", true


validate-area = 
  account :
    * exclude : <[
        account_join
        account_signup
        account_login
        ]>
      test    : -> not My.user()?
      onfail  : -> 'account_join'
    ...

  home :
    * exclude : <[
        home_launch
        ]>
      test    : -> not My.user()?
      onfail  : -> 'home_launch'
    ...

get-area = (session_area, cb) ->
  area = Session.get session_area
  unless area then return

  if val = validate-area[ area.split('_')[0] ]
    for v in val
      unless area in v.exclude
        if v.test!
          area = v.onfail!
          break

  cb area

get-menu = -> get-area it, (area) ->
  if menu = Menus.find-one pages: area
    Template.menu menu



Template.content.helpers {}=
  current_page  : -> get-area "shift_current_area", (area) ->
    Template[ area ]()

  next_page     : -> get-area "shift_sub_area", (area) ->
    parse_area      = area.split '_'
    parse_sub_area  = parse_area.join '/'

    Meteor.Transitioner.set-options after: ->
      Meteor.Router.to (if parse_sub_area is "home" then "/" else "/" + parse_sub_area)

    Template[ area ]()

Template.menus.helpers {}=
  current_menu: -> get-menu "shift_current_area"
  next_menu   : -> get-menu "shift_sub_area"






Template.home_intro.events {}=
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

Template.home_launch.rendered = ->
  # window_height = $('main').height() / 2
  # launch = $(@find('#launch'))
  # launch_height = (launch.outerHeight() * 0.75)
  # launch.css {}=
  #   'top': window_height - launch_height


Template.content.events {}=
  'click .accord header': (event, tmpl) ->
    if not $(event.target).hasClass "active"
      $(event.currentTarget).siblings().slideDown()
    else
      $(event.currentTarget).siblings().slideUp()
    $(event.target).toggleClass "active"




Template.anchors.rendered = ->
  current = Session.get("shift_current_area").split('_')[0]
  $ "li[data-shift-area=#{current}]" .trigger 'click'


Template.sidebar.events {}=
  'click .logout': ->
    # console.log "CURRENT", Session.get("shift_current_area")
    Meteor.logout!


Template.home.helpers {}=
  get_offers: ->

    @coll ?= new Meteor.Collection null

    if not @offers?.length => @offers = Offer.load-all @coll
    unless @offers => return

    ranges =
      updatedAt   : []
      nearest     : []
      points      : []
      price       : []

    result = @coll.find(
      Store.get("current_tagsets"),
      Store.get("current_sorts")
      reactive: true
    ).map (d)->

        for r of ranges
          ranges[r].push d[r]

        d

    for r of ranges
      amplify.store "max_#{r}", _.max(ranges[r])
      amplify.store "min_#{r}", _.min(ranges[r])

    result



  styleDate: (date) ->
    moment(date).fromNow()

