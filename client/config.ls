
do ->
  ms = Meteor.subscribe

  ms "all_locations", -> console.log "LOCATIONS READY"

  # ms "relations", My?.userLoc! , ->
  #   console.log "SUBSCRIBE READY"
  #   Session.set "subscribe_ready", true

  ms "my_offer"
  ms "my_tags"
  ms "my_pictures"
  ms "my_messages"
  ms "my_alerts"
  ms "my_prompts"

  ms "tagsets"
  ms "sorts"
  ms "points"

  ms "all_offers", -> Session.set 'offer_subscribe_ready', true
  ms "all_tags"
  ms "all_markets"

  ms "purchases"
  ms "customers"

  ms "user_data"

# window.__dirname = "http://localhost:3000/"











Stripe.set-publishable-key("pk_test_xB8tcSbkx4mwjHjxZtSMuZDf") 
Stripe.client_id = "ca_131FztgqheXRmq6vudxED4qdTPtZTjNt"

# Color = net.brehaut.Color

@Store = Meteor.Browser-store

Store.clear = ->
  keys = Object.keys(Store.keys)
  keeps = [
    "user_loc",
    "notes",
    "gray",
    "current_nouns",
    "current_sorts",
    "current_sorts_order",
    "current_sorts_selector",
    "current_tags",
    "current_tagsets"
  ]

  diffs = _.difference(keys, keeps)

  for diff in diffs
    console.log(diff)
    Store.set(diff, null)

Store.clear-all = ->
  keys = _.keys(Store.keys)
  for key in keys
    console.log(key)
    Store.set(key, null)

getLocation = ->
  Meteor.Alert.set {}=
    text: "One moment while we charge the lasers..."
    wait: true

  foundLocation = (location) ->
    Store.set "user_loc",
      lat: location.coords.latitude
      long: location.coords.longitude

    Meteor.Alert.set {}=
      text: "Booya! Lasers charged!"

  noLocation = ->
    Meteor.Alert.set {}=
      text: "Uh oh... something went wrong"

  navigator.geolocation.getCurrentPosition foundLocation, noLocation

validateEmail = (email) ->
  re = /^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/
  re.test email

Meteor.startup ->

  window.google ?= null
  window.initialize = initialize = ->
    console.log "GM INITIALIZED"

  $.get-script "https://maps.googleapis.com/maps/api/js?key=AIzaSyCcvzbUpSUtw1mK30ilGnHhGMPhIptp6Z4&sensor=false&callback=initialize"
  $.get-script "http://d-project.googlecode.com/svn/trunk/misc/qrcode/js/qrcode.js"

  do -> 
    config =
      kitId: "lnp0fti"
      scriptTimeout: 3000

    h = document.getElementsByTagName("html")[0]
    h.className += " wf-loading"
    t = setTimeout(->
      h.className = h.className.replace(/(\s|^)wf-loading(\s|$)/g, " ")
      h.className += " wf-inactive"
    , config.scriptTimeout)
    tk = document.createElement("script")
    d = false
    tk.src = "//use.typekit.net/" + config.kitId + ".js"
    tk.type = "text/javascript"
    tk.async = "true"
    tk.onload = tk.onreadystatechange = ->
      a = @readyState
      return  if d or a and a isnt "complete" and a isnt "loaded"
      d = true
      clearTimeout t
      try
        Typekit.load config

    s = document.getElementsByTagName("script")[0]
    s.parentNode.insertBefore tk, s

  new Stopwatch "watchOffer"



  unless Store.get("gray")
    Store.set "gray", "hero"




# Accounts.ui.config passwordSignupFields: "USERNAME_AND_OPTIONAL_EMAIL"

