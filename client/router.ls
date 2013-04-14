

set-area = ->
  Session.set "shift_current_area", it
  j = $ "li[data-shift-area=#{it.split('_')[0]}]" 
  # console.log "JJJJJ", j
  j.trigger 'click'

Meteor.Router.add {}=
  "/": ->
    set-area 'home'
    "home"

  # "/access/*": ->
  #   console.log("YOOOOOOOOO")
  #   url-params = {}
  #   do ->
  #     compare = void
  #     pl = /\+/g
  #     search = /([^&=]+)=?([^&]*)/g
  #     decode = (s) ->
  #       decodeURIComponent s.replace(pl, " ")

  #     query = window.location.search.substring(1)
  #     console.log "QUERY" query
  #     while compare = search.exec(query)
  #       url-params[decode(compare[1])] = decode(compare[2]) 

  #   console.log \PARAMS, url-params

  #   Meteor.call 'market_oauth', url-params.code, -> window.close()
  #   "account_earnings_dashboard"

  "/:area": (area) ->
    if store_page = Store.get("page_" + area)
      set-area store_page
    else
      set-area area

  "/:area/:link": (area, link) ->

    if store_page = Store.get("page_" + area + "_" + link)
      set-area store_page
    else
      set-area area + "_" + link

  "/:area/:link/:sublink": (area, link, sublink) ->
    sub_area = area + "_" + link + "_" + sublink

    if link is "collections"
      Store.set("nab", sublink.toProperCase())
      Store.set("nab_query", {})
      Store.set("nab_sort", {})

    # Store.set "page_#{area}", sub_area
    set-area sub_area

  "/offer/:id": (id) ->
    Session.set "showThisOffer", Offers.findOne(business: id)
    Session.set "header", null
    "thisOffer"

  "/*": ->
    set-area 'home'
    "404"

Meteor.Router.filters {}=
  # checkLoggedIn: (page) ->
  #   if Meteor.user()
  #     page
  #   else
  #     "home"

  checkAdmin: (page) ->
    user = Meteor.user()
    if user.type is "basic"
      page
    else
      "home"

# Meteor.Router.filter "checkLoggedIn", only: ["account", "account_profile_settings"]

Meteor.Router.filter "checkAdmin",
  only: ["/admin/users"]
