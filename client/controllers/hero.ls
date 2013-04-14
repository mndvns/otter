

Template.hero.events {}=
  "click .list li": (event, tmpl) ->
    # watchOffer.click()

    tmpl.handle.stop!

    story = d3.select(event.currentTarget).data()[0]

    current  = Store.get("current_#{story.collection}")
    active   = $(event.currentTarget).is ".active"
    output   = void

    # console.log(story)

    if active
      output = _.without(current, story.name)
      if story.collection is "tagsets"
        nouns = Store.get("current_nouns")
        Store.set "current_nouns", _.without(nouns, story.noun)
    else
      switch story.collection
        when "tags"
          output = current.concat(story.name) 
          # console.log(output)
        when "tagsets"
          output = [story.name]
          Store.set "current_nouns", [story.noun]
          Store.set "current_tags", []
        when "sorts"

          output = [story.name]
          switch story.selector
            when "random"
              output = []
              story.order = _.random(1, 100)
            when "$near"
              loc = Store.get("user_loc")
              story.order = [loc.lat, loc.long]

          Store.set "current_sorts_specifier", story.specifier
          Store.set "current_sorts_selector", story.selector
          Store.set "current_sorts_order", story.order

    Session.set "current_changed", story.collection
    Store.set "current_#{story.collection}", output

  "click .headline .tag span": (event, tmpl) ->
    selector = event.target.textContent
    current = Store.get("current_tags")
    out = _.without(current, selector)
    Store.set "current_tags", out




HeroList = (opt) ->

  opt.current[opt.name] ?= []

  list = d3.select("ul." + opt.name + "-list")

  item = list.selectAll("li")
    .data(opt.collection)

  item
    .enter!
    .insert "li"

  item
    .datum (d, i) ->
      d.status  = if _.contains opt.current[opt.name], d[opt.selector]
                then "active"
                else "inactive"
      d

    .attr "class", (.status)
    .html (d) ->
      child = ""
      if opt.name is "tag"
        child = "<span class='badge #{d.status}'>#{d.rate}</span>"
      d[opt.selector] + child

  item
    .exit!
    .remove!

  active = list.selectAll("li.active")
    .transition!
    .style {}=
      'font-size': '18px'

  inactive = list.selectAll("li.inactive")
    .transition!
    .style {}=
      'font-size': '13px'


  list



hero-tag = ->
  # console.log "HERO TAG"

  list = d3.select 'ul.tag-list'

  px = -> it + 'px'

  current = Store.get 'current_tags'

  # dd    = as("collection").tags
  dd    = dummydata
  rates = _.pluck dd, 'rate'
  max   = _.max rates
  min   = _.min rates

  width = parse-int list.style 'width'
  upper = (* 0.10) width
  lower = (* 0.04) width

  scale = d3.scale.linear!
    ..domain [ min, max ]
    ..range [ lower, upper ]

  items = list.select-all 'li'
    .data dd

  # console.log \MAX, max
  # console.log \MIN, min

  items.enter!insert 'li'

  items
    .datum ->
      it.size = (* 10) round (/ 10) scale it.rate
      it
    .attr 'class', -> 
      | _.contains current, it.name => "active"
      | _                           => "inactive"
    .text -> it.name

  items.style {}=
    'padding'   : -> '0 ' + px it.size

  items.on 'click', -> console.log @__data__

Template.hero.created = ->
  Session.set "heroRendered", false
  Session.set "current_changed", null
  unless @handle
    @.handle = Deps.autorun ->

      tagsets = Tagsets.find!fetch!
      sorts   = Sorts.find!fetch!
      tags    = Tag.rateAll!

      if tags and tags.length

        unless Store.get "current_tagsets"
          Store.set "current_tagsets", ["eat"]
          Store.set "current_tags", []
          Store.set "current_sorts", ["latest"]
          Store.set "current_sorts_specifier", "sort"
          Store.set "current_sorts_selector", "updatedAt"
          Store.set "current_sorts_order", "-1"

        out = 
          tagsets: tagsets
          tags: tags
          sorts: sorts

        as "collection", out

        Session.set "heroDataReady", true



  Deps.autorun ->
    unless Session.get("heroRendered")
      # console.log "not rendered"
      return false
    unless Session.get("heroDataReady")
      # console.log "no data"
      return false

    current = statCurrent!verbose
    Collection = as("collection")

    collection =
      tagset: Collection.tagsets
      tag   : _.filter( Collection.tags , (d) ->
        _.contains current.tagset, d.tagset
      )
      sort  : Collection.sorts
      # noun  : Collection.tagsets

    heroList =
      tagset: new HeroList {}=
        name: "tagset"
        selector: "name"
        leader: true
        current: current
        collection: collection.tagset

      sort: new HeroList {}=
        name: "sort"
        selector: "name"
        leader: false
        current: current
        collection: collection.sort

      tag: hero-tag!

      # tag: new HeroList {}=
      #   name: "tag"
      #   selector: "name"
      #   leader: false
      #   current: current
      #   collection: collection.tag

  Session.set("heroUpdated", true)



Template.hero.rendered = (tmpl) ->
  Session.set "heroRendered", true  unless Session.get("heroRendered")
  if Session.get("heroDataReady") => @handle and @handle.stop!

