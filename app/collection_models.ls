do ->
  AC  =  App.Collection = {}
  MC  =  Meteor.Collection

  ENV = My.env!
  CALL = Meteor.call

  switch
  | Meteor.is-server => IS-SERVER = true
  | Meteor.is-client => IS-CLIENT = true

  ENV.is-dev = true

  if ENV.is-dev is true => IS-DEV = true

  ENV.Users     = AC.Users    = new MC "userData"
  ENV.Sorts     = AC.Sorts    = new MC "sorts"
  ENV.Messages  = AC.Messages = new MC "messages"
  ENV.Alerts    = AC.Alerts   = new MC "alerts"

  MIX = {}=

    Check : {}=

      check-char : ->
        unless it? then return false
        switch it
        | "string"  => "characters"
        | "array"   => "items"
        | "number"  => "number"
        | "object"  => "values"
        | "boolean" => "true or false"

      check-field: ( f ) ->
        e = ~> @throw "#{@@@_type.model}'s #{f} property " + it

        a = @[f]
        s = @@@_schema[f]

        switch
        | not s? => e "does not exist"
        | not a? => e "has not been set"

        st = type s.default
        c = ~> @check-char it

        switch st
        | "boolean" => return
        | "number"  =>
          aval = a = parse-int a
          verb = "be"
          char = numberWithCommas s.max
        | otherwise =>
          aval = length a
          verb = "have"
          char = s.max + " " + c st

        at = type a

        switch
        | at isnt st                      => e "must have #{c st}, not #{c at}"
        | s.min is s.max isnt aval        => e "must #{verb} exactly #{char}"
        | s.max < aval or aval < s.min    => e "must #{verb} between #{s.min} and #{char}"

        return "#{f} checked"

      check-list  : -> for i in it then @check-field i
      check-set : ->
        n = if typeof! &0 is "Arguments"
            then &
            else &0
        switch typeof! n.0
        | "String"  => (@check-field n.0       ) and (@[n.0] = n.1                 ) and (out = {(n.0)  : n.1   })
        | "Array"   => (@check-field n.0.0     ) and (@[n.0.0] = n.0.1             ) and (out = {(n.0.0): n.0.1 })
        | "Object"  => (@check-list keys n.0.0 ) and (for k, v of n.0.0 => @[k] = v) and (out = n.0             )
        | _         => @throw "Must pass string, array, or object"

        &[&.length - 1]? out
        out
      check-save: ->
        | @is-persisted! => @check-set &, ~> @@@_collection.update @_id, $set: it
        | _              => @throw @@@_type.model + " must save before set-saving"

    Default : {}=
      default-set   : -> for k, v of @@@_schema => @[k] = v.default
      default-null  : -> for k of @@@_schema    => unless @[k]? => @[k] = null

    Limit  : {}=
      limit-guard : -> if (not @is-persisted!) and (@@@_limit - @@@mine!count! <= 0) => @throw "Collection at limit"

    Lock : {}=
      lock-set    : -> for k, v of @@@_locks  => @[k] = v!
      lock-check  : -> for l of @@@_locks     => unless @[l]?
        @throw "An error occured during the #{l} verification process"

    Store : {}=
      store-method  : -> Store?[&0] "instance_#{@@@_type.model.to-lower-case!}", &1
      store-load    : -> @store-method 'set', @
      store-set     : -> @set &0, &1 and @store-method "set", @
      store-clear   : -> @store-method "set", null
      # store-get     : -> @store-method "get", null

    Cite : {}=
      cite-set     : ({field, list, attr}, q, method, cb) ->
        col = ENV[list.to-proper-case!].find {([q.0]) : @[q.1]} .[method]!
        if field isnt list => col = map (.[field]), col
        if cb?             => col = cb col
        @[attr] = col

      cite-jam     : -> for p in @@@_cites => @cite-set p[0], p[1], p[2], p[3]

    Clone : {}=
      clone-new     : -> @@@new _.omit @, (keys @_locks ..push "_id")
      clone-kill    : -> @@@_collection.remove that._id if @clone-find it
      clone-find    : (f) -> find (~> it[f] is @[f]), My[@@@_collection._name]?!

    Is : {}=
      is-persisted  : -> @_id?
      is-structured : -> (@@@_schema   )?
      is-locked     : -> (@@@_locks    )?
      is-limited    : -> (@@@_limit    )?
      is-correct    : ->
        if @is-locked!     => @ ..lock-set! ..lock-check!
        if @is-limited!    => @ ..limit-guard!
        if @is-structured! => @ ..check-list keys filter (.required), @@@_schema



  class Model implements MIX.Lock, MIX.Is

    -> _.extend @, it

    throw : -> throw new Error it
    alert : ->
      | IS-DEV?    => console.log "ALERT", it
      | IS-SERVER? => new Alert text: it
      | IS-CLIENT? => Meteor.Alert.set text: it

    set       : -> @[&0] = &1
    update  : -> (for k, v of &0 => @[k] = v) and @save (&1)
    upsert  : ->
      | @is-persisted!  => @throw <- @@@_collection.update @_id, $set: _.omit @, "_id"
      | _               => @_id = @@@_collection.insert @

    save    : ->
      try @is-correct!
      catch
        @alert e?.message
        it? e.message
        return

      @upsert!
      @alert "Successfully saved #{@@@_type.model.to-lower-case!}"

      it? void, @


    destroy: ->
      if @is-persisted! => @@@_collection.remove @_id and @_id = null
      @store-clear?()

    @new    = ->  new @ &0

    @where  = -> @_collection.find it
    @mine   = -> @where owner-id: My.user-id!

    @destroy-mine = -> CALL "instance_destroy_mine", @_type.model + "s"

    @serialize    = -> @new <| list-to-obj <| map (->[it.name, it.value]), $(it).serialize-array!

    @store-get    = -> Store?.get "instance_#{@_type.model.to-lower-case!}"


  METHODS =
    shared : {}
    server : {}
    client : {}


  GENERATE = ([K, C, S, F, M]) ->

    object = ^^K.klass

    class object extends Model

    switch
    | C.scratch?  => Coll = null
    | _           => Coll = C.coll.to-lower-case!

    Klass             = ENV[K.klass] = object
    Klass._collection = ENV[C.coll]  = AC[C.coll] = new MC Coll, { id-generation: \STRING, transform: C.trans }
    Klass._type       = 
      model       : do -> K.klass.to-string!
      collection  : do -> _.pluralize K.klass.to-string!to-lower-case!

    if K.mix.length? => for m in K.mix => import-all$ Klass::, MIX[m]

    if S         => for s, v of S         => Klass["_" + s] = v
    if F?.proto  => for f, v of F.proto   => Klass::[f] = v
    if F?.method => for f, v of F.method  => Klass[f] = v


    if M => for m in M
      m-name = "#{K.klass.to-lower-case!}_#{m.name}".to-string!
      switch m.type
      | \proto  => Klass::[m.name] = -> CALL m-name, it
      | \method => Klass[m.name]   = -> CALL m-name, it
      METHODS[m.side][m-name] = m.func

    return Klass

  GENERATE {}=
    * klass : \Location
      mix   : <[ Check Limit ]>

    * coll    : \Locations
      trans   : -> Location.new it ..set "distance", ..geo-plot!

    * limit  : 20
      locks  :
        owner-id : -> My.user-id!
        offer-id : -> My.offer-id!
      schema :
        "geo":
          default  : [ 47, -122 ]
          required : true
          max      : 2
          min      : 2
        "city":
          default  : "Kansas City"
          required : true
          max      : 30
          min      : 5
        "street":
          default  : "200 Main Street"
          required : true
          max      : 30
          min      : 5
        "state":
          default  : "MO"
          required : true
          max      : 2
          min      : 2
        "zip":
          default  : "64105"
          required : true
          max      : 5
          min      : 5

    * proto  :
        geo-map : ->
          try
            @check-list <[ city street state zip ]>
          catch
            @alert e.message
            it? e.message
            return

          new google.maps.Geocoder?()
            .geocode address: "#{@street} #{@city} #{@state} #{@zip}",
            (results, status) ~>
              if status isnt "OK"
                message = "We couldn't seem to find your location. Did you enter your address correctly?"
                @alert message
                it? @throw message
              else
                format = (values results[0].geometry.location)[0,1]
                @geo = format
                @ ..alert format ..save!
                it? null, format

        geo-distance : (lat1, lon1, lat2, lon2, unit) ->
          radlat1 = Math.PI * lat1 / 180
          radlat2 = Math.PI * lat2 / 180
          radlon1 = Math.PI * lon1 / 180
          radlon2 = Math.PI * lon2 / 180
          theta = lon1 - lon2
          radtheta = Math.PI * theta / 180
          dist = Math.sin(radlat1) * Math.sin(radlat2) + Math.cos(radlat1) * Math.cos(radlat2) * Math.cos(radtheta)
          dist = Math.acos(dist)
          dist = dist * 180 / Math.PI
          dist = dist * 60 * 1.1515
          dist = dist * 1.609344  if unit is "K"
          dist = dist * 0.8684  if unit is "N"
          dist


        geo-plot: ->
          m = My.userLoc?! or {lat: 39, long: -94}
          g = @geo

          if g? => Math.round @geo-distance m.lat, m.long, g[0], g[1], "M" * 10 / 10

    * * name  : \rargo
        side  : \shared
        type  : \proto
        func  : -> console.log "RARGOOOOOOOOO"
      ...

  GENERATE {}=
    * klass : \Tagset
      mix   : <[ Check Limit ]>

    * coll  : \Tagsets
      trans : -> Tagset.new it

    * limit  : 5
      locks  :
        collection: -> "tagsets"
      schema :
        "name":
          default : "see"
        "noun":
          default : "event"

    * proto  :
        "count-tags" : -> Tag.where "tagset": @name .count!

  GENERATE {}=
    * klass : \Tag
      mix   : <[ Check Limit Clone ]>

    * coll  : \Tags
      trans : -> Tag.new it

    * limit  : 20
      locks  :
        owner-id    : -> My.user-id!
        offer-id    : -> My.offer-id! or 'pending'
        tagset      : -> My.tagset!
        collection  : -> "tags"
      schema :
        "name":
          default  : "tag"
          required : true
          max      : 20
          min      : 2
        "tagset":
          default  : "eat"
          required : true
          max      : 10
          min      : 2

    * proto  :
        rate-it : -> @rate = (@@@where name: @name .count!)
      method :
        rate-all : (it = {}) ->
          list = @where it .fetch!

          out = {}
          for n in [..name for list]
            unless n? => continue
            out[n] ?= 0
            out[n] += 1

          lout = []
          for key, val of out
            o = find (.name is key), list
              ..rate = val
            lout.push o

          lout




  GENERATE {}=
    * klass : \Prompt
      mix   : <[]>

    * coll    : \Prompts
      scratch : true
      trans   : -> Prompt.new it

    * locks :
        owner-id  : -> My.user-id!
        set-at    : -> Time.now!

    * method :
        target  : -> @new { target-id: it }
        test    : -> it in map (.target-id), My.prompts!



  GENERATE {}=
    * klass : \Offer
      mix   : <[ Check Limit Cite Store Default ]>

    * coll  : \Offers
      trans : -> Offer.new it ..cite-jam! ..set-nearest!
      # trans : -> Offer.new it

    * limit  : 1
      cites  :
        * * field : "name"
            list  : "tags"
            attr  : "tags"
          * 'ownerId'
            'ownerId'
          * 'fetch'
        * * field : "locations"
            list  : "locations"
            attr  : "locations"
          * 'ownerId'
            'ownerId'
          * 'fetch'
        * * field : "points"
            list  : "points"
            attr  : "points"
          * 'targetOffer'
            '_id'
          * 'count'
        * * field : "markets"
            list  : "markets"
            attr  : "market"
          * 'offerId'
            '_id'
          * 'fetch'
          * (.0 )

      locks  :
        owner-id   : -> My.userId!
        updated-at : -> Time.now!

      schema :
        "business":
          default  : "your business/vendor name"
          required : true
          max      : 30
          min      : 3
        "description":
          default  : "
            This is a description of the offer. Since the offer name 
            must be very brief, this is the place to put any details you 
            want to include."
          required : true
          max      : 140
          min      : 3
        "image":
          default  : "http       : //i.imgur.com/YhUFTyA.jpg"
        "locations":
          default  : []
        "name":
          default  : "Offer"
          required : true
          max      : 15
          min      : 3
        "price":
          default  : 10
          required : true
          min      : 3
          max      : 2000
        "published":
          default  : false

    * proto  :
        set-nearest : -> if @locations? => @nearest = minimum  [..distance for @locations]

      method :
        get-store  : -> 
          out = @new Store.get "instance_#{@_type.model.to-lower-case!}"

          mine = My.offer!

          if mine
            out._id       = mine._id
            out.owner-id  = mine.owner-id

          out

        load-store : ->
          Deps.autorun ~>
            unless Session.get("offer_subscribe_ready") is true => return

            switch
            | Is.mine @get-store! => (log 'LOAD!', 'IS MINE'     )
            | @mine!count! > 0    => (log 'LOAD!', 'LOADING MINE') and ( My.offer! ..store-load!            )
            | _                   => (log 'LOAD!', 'DEFAULT SET' ) and ( @new! ..default-set! ..store-load! )


        load-all   : (coll) -> each (-> coll.insert it), Offers.find!fetch!


  GENERATE {}=
    * klass : \Point
      mix   : <[]>

    * coll  : \Points
      trans : -> Point.new it

    * locks  :
        owner-id  : -> My.user-id!
        set-at    : -> Time.now!

    * method :
        cast : -> @new { target-offer: it._id, target-user: it.owner-id } ..save!




  MIX.Prompt  =
    prompt-target  : -> @set 'prompt', (Prompt.new { target-id: it })


  GENERATE {}=
    * klass : \Market
      mix   : <[ Limit Prompt ]>

    * coll  : \Markets
      trans : -> Market.new it

    * limit : 1
      locks  :
        owner-id  : -> My.user-id!
        offer-id  : -> My.offer-id!

    * proto:
        find-offer  : -> Offers.find-one _id: @offer-id

        create-token-customer: ( card )->

          CALL 'stripe_token_create', card, (err, res) ->
            console.log "GOT HERE"
            if err
              console.log "ERROR", err
            if res
              console.log \SUCCESS, 'create-token'
              console.log \ERR?, err
              console.log \RES?, res
              # token = res.id

              # CALL "customer_create", token, (err, res) ~>
              #   if err
              #     console.log "ERROR", err
              #   else
              #     console.log err, res, "customer_create"
              #     CALL "customer_save", res, (err, res) ~>
              #       if err => throw err
              #       if res => console.log err, res, "CUSTOMER SAVED!!!"

        create-purchase: ->


          offer         = @find-offer!
          access_token  = @access_token
          amount        = parseInt offer.price

          CALL 'purchase_create', access_token, amount, (err, res) ->
            if err => throw err
            else
              p = 
                charge    : res
                offer     : offer
                seller-id : offer.owner-id
                status    : "active"
              Purchase.new p ..save!
              console.log(err, res, \SUCCESS, "purchase_create")


    * * name  : \oauth
        side  : \server
        type  : \method
        func  : ->

          out = data:
            client_secret: stripe-client-secret
            code: it
            grant_type: "authorization_code"

          Meteor.http.call "POST", "https://connect.stripe.com/oauth/token", out, (err, res) ->
              if err
                console.log("ERROR", err)
              else
                console.log("SUCCESS", res)

                fields =
                  access_token           : res.data.access_token
                  refresh_token          : res.data.refresh_token
                  stripe_publishable_key : res.data.stripe_publishable_key
                  stripe_user_id         : res.data.stripe_user_id

                if My.market()? => My.market!.update fields
                else            => Market.new fields ..save!

        ...


  GENERATE {}=
    * klass : \Customer
      mix   : <[ Limit ]>

    * coll  : \Customers
      trans : -> Customer.new it

    * limit : 1
      locks  :
        owner-id  : -> My.user-id!

    * 0

    * * name  : \create
        side  : \server
        type  : \method
        func  : (token) ->
          console.log "GOT HERE IN CUST CREATE"

          out =
            card: do -> StripeAPI stripe-client-secret
            description: "A happy customer"

          f = new Future!
          stripe.customers.create out, (err, res)->
            if err
              console.log("ERR", err)
              f.return err
            else
              console.log("RES", res)
              f.return res
          f.wait!

      * name  : \save
        side  : \server
        type  : \method
        func  : (customer) ->

          f = new Future!
          my-cust = My.customer?!
          if my-cust
            console.log "CUSTOMER ALREADY"
            my-cust.update customer, (err, res) ->
              if err => throw err
              console.log "UPDATED CUSTOMER", res
              f.return err, res
          else
            console.log "NO CUSTOMER"
            Customer.new customer .save (err, res) ->
              if err => throw err
              console.log "CREATED NEW CUSTOMER", res
              f.return err, res

          f.wait!


  GENERATE {}=
    * klass : \Purchase
      mix   : <[]>

    * coll  : \Purchases
      trans : -> Purchase.new it

    * limit : 1000
      locks :
        owner-id  : -> My.user-id!

    * 0

    * * name  : \create
        side  : \server
        type  : \method
        func  : (access_token, amount) ->

          stripe = StripeAPI access_token

          out = {}
          out.amount          = do -> amount * 100
          out.application_fee = do -> amount * 5
          out.currency        = "USD"
          out.customer        = do -> My.customer-id!

          f = new Future!
          stripe.charges.create out, (err, res)->
            if err
              console.log("ERR", err)
              f.return err
            else
              console.log("RES", res)
              f.return res
          f.wait!

        ...

  GENERATE {}=
    * klass : \Picture
      mix   : <[ Check ]>

    * coll  : \Pictures
      trans : -> Picture.new it

    * locks  :
        owner-id  : -> My.user-id!
        offer-id  : -> My.offer-id!

      schema :
        "status":
          default : "active"
        "imgur":
          default : false
        "type":
          default : "jpg"
        "src":
          default : "http://i.imgur.com/YhUFTyA.jpg"

    * proto :
        activate: ->
          Pictures.update {}=
            owner-id: @owner-id
            _id: $nin: [@_id]
          , $set: status: "inactive"
          , multi: true

          Pictures.update @_id,
            $set: status: "active"

        deactivate: ->
          @status = "deactivated"
          @alert "Image successfully removed"

        on-upload : (err, res)->
          if err
            console.log("ERROR", err)
            @update status: "failed"
          else
            console.log("SUCCESS", res)
            @update {}=
              status: "active"
              src: res.data.link
              imgur: true
              deletehash: res.data.deletehash

        on-delete : (err, res)->
          | err => console.log("ERROR", err)
          | res => console.log("SUCCESS", res)
          @destroy!



  MM = Meteor.methods
  MM METHODS.shared
  switch
  | IS-CLIENT => MM METHODS.client
  | IS-SERVER => MM METHODS.server

  console.log 'MODELS LOADED'


