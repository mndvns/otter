
GENERATE = App.Utils.Generate
MIX      = App.Utils.Mix

GENERATE {}=
  * klass : \Tag
    mix   : <[ Check Limit Clone ]>

  * coll  : \Tags
    trans : -> Tag.new it
    cache : []=
      * coll  : \rated
        trans : -> Tag.new it
      ...

  * limit  : 50
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
  * 0

  * proto  :
      rate-it : -> @rate = (@@@where name: @name .count!)

    method :
      cache-load : (a = {}, b) ->
        switch typeof! a
        | "Object"    => list = Tag.where a .fetch!
        | _           => list = Tag.where {} .fetch!

        unless list.length > 0 => return

        out = {}
        for n in [..name for list]
          unless n? => continue
          out[n] ?= 0
          out[n] += 1

        lout = []
        for key, val of out
          o = find (.name is key), list
            ..rate  = val
            ..index = lout.length
          lout.push o

        range = d3.scale.linear!
          ..domain (-> [(_.min it), (_.max it)]) map (.rate), lout
          ..range [ 1, 4 ]


        @rated.remove {}, multi: true
        lout |> each ~>
          it.size = round range it.rate
          @rated.insert @new it

        fout = @rated.find {}, {reactive: false} .fetch!
        Session.set "tickets", fout
        switch
        | typeof! a is "Function" => a!
        | typeof! b is "Function" => b!

        return fout


# GENERATE {}=
#   * klass   : \Reader
#   * coll    : \Readers
#     trans   : -> let r = Reader.new it
#       Reader.new _.extend {r._id}, {r.type}, {r.owner}, {items: (each (-> _.extend(it, r.uniform, {r.owner})), r.insert)}
# 
#     stable  : []=
# 
#       * owner   : 'about'
#         type    : 'links'
#         area    : 'top'
#         insert  :
#           * name: "synopsis"
#           * name: "faq"
#           * name: "blog"
#         uniform :
#           class : 'span4'
#           level   : 1
# 
#       * owner   : 'account'
#         type    : 'links'
#         area    : 'top'
#         insert  :
#           * name: "synopsis"
#           * name: "faq"
#           * name: "blog"
#         uniform :
#           class : 'span4'
#           level   : 1
# 
#       * owner   : 'home'
#         type    : 'collection'
#         area    : 'top'
#         insert  :
#           * name  : "eat"
#           * name  : "drink"
#           * name  : "shop"
#         uniform :
#           group : "tagsets"
#           class : 'span4'
#           level   : 1
# 
#       * owner   : 'home'
#         type    : 'collection'
#         area    : 'bottom'
#         insert  :
#           * name     : "best"
#             selector : "points"
#             order    : 1
#             specifier: "sort"
#           * name     : "nearest"
#             selector : "distance"
#             order    : -1
#             specifier: "sort"
#           * name     : "cheapest"
#             selector : "price"
#             order    : -1
#             specifier: "sort"
#           * name     : "latest"
#             selector : "updatedAt"
#             order    : 1
#             specifier: "sort"
#         uniform :
#           group : "sorts"
#           class : 'span3'
#           level : 3
# 
#   * 0
#   * created : ->
# 
#     rendered : ->
#       @handle ?= Deps.autorun ~>
#         | EJSON.equals Store.get("sel_#{@data.type}_#{@data.group}"), @data
#           $ @find "a" .add-class "active"
#         | _
#           $ @find "a" .remove-class "active"
# 
#     destroyed : ->
#       @handle.stop!
# 
#     events : do ->
#       'click a' : (event, tmp) ->
#         if @type is 'collection' => event.prevent-default!
# 
#         switch $ event.current-target .is '.active'
#         | true => Store.set "sel_#{@type}_#{@group}", null
#         | _    => Store.set "sel_#{@type}_#{@group}", Reader.new @
# 
#         if @type is 'collection'
#           event.stop-immediate-propagation!
#           out = void
#           switch @group
#           | 'sorts'   => out = {@specifier, @selector, @order}
#           | 'tagsets' => out = {tagset: @name}
#           | 'tags'    => out = {tagset: @name, $in: {tags: [@name]}}
#           Store.set "current_#{@group}", out
#           event.prevent-default!
#         else
#           console.log "GOT HERE", @
# 
#   * proto :
#       get-alias : ->
#         "sel_" + @type + '_' + @group
#       method:
#         derp: -> "ASDASD"

Session?.set-default "shift_next_area", null

GENERATE {}=
  * klass : \Anchor
    mix   : <[ Cite ]>

  * coll    : \Anchors
    trans   : -> Anchor.new it
    stable  : []=

      * name    : "about"
        display : "about"
        glyph   : "harddrive"
        arrow   : "left"

      * name    : "home"
        display : "connectedkc"
        glyph   : "camera"
        arrow   : "up"

      * name    : "account"
        display : "account"
        glyph   : "cog"
        arrow   : "right"

  * 0

  * rendered  : -> 
      console.log "RENDERED ANCHOR"
      # unless Session.get("rendered_main") => return false

      current = Session.get("shift_current_area").split('_')[0]

      # @past ?= Date.now!
      # present = Date.now!
      # passage = present - @past
      # @past = present

      # console.log "PASSAGE", passage
      # if passage < 0 => return

      if (current is @data.name)
        $ @find 'li' .trigger 'click'


    events    : do ->
      'click li' : (event, tmp)->
        t = $ event.current-target

        switch
        | t.is '.active' => return
        | tmp.data.name is Session.get "shift_current_area" .split('_')[0]  => return
        | tmp.data.name is Session.get "shift_next_area" ?.split('_')[0]    => return

        t.siblings!attr 'class', 'inactive'
        t.attr 'class', 'active'
        t.parent!.attr 'data-active-anchor', @name

        if t.index! is 1 => t.siblings!add-class 'split'

        store_area     = Store.get("page_" + @name ) or @name
        store_sub_area = Store.get("page_" + store_area )
        sub_area       = store_sub_area or store_area

        Session.set 'shift_sub_area', sub_area
        Session.set 'shift_next_area', @name


###
GENERATE {}=
  * klass : \Form
    mix   : <[ ]>

  * coll    : \Forms
    trans   : -> Form.new it
    stable  : []=

      * name    : "signup"
        rows    :

          * attr    : "data-focus=first"
            class   : "row-fluid"
            groups  :
              * label : "Full Name"
                tip   : "this is a tip"
                class : "span6"
                fields  :
                  * elem  : "input"
                    attr  : """
                      name=name
                      value = mikey
                      data-required  = true
                      data-trigger   = change
                      data-type      = alphanum
                      data-minlength = 3
                      data-maxlength = 20
                      """
                    ...

              * label : "Email (optional)"
                tip   : "this is a tip"
                class : "span6"
                fields  :
                  * elem  : "input"
                    attr  : """
                      name=email
                      data-type     = email
                      data-trigger  = change
                      """
                    ...

          * class   : "row-fluid"
            groups  :
              * label : "Password"
                tip   : "this is a tip"
                class : "span6"
                fields  :
                  * elem  : "input"
                    attr  : """
                      name=password
                      type           = password
                      value = 321321
                      data-required  = true
                      data-trigger   = change
                      data-minlength = 5
                      data-maxlength = 20
                      """
                    ...

              * label : "Username"
                tip   : "this is a tip"
                class : "span6"
                fields  :
                  * elem  : "input"
                    attr  : """
                      name=username
                      value = mikey
                      data-required  = true
                      data-trigger   = change
                      data-minlength = 5
                      data-maxlength = 20
                      """
                    ...

          * class   : ""
            groups  :
              * class : "row-fluid actions"
                fields  :
                  * elem  : "p"
                    class : "span10 conditions"
                    text  : '
                      By checking this box and clicking <strong>Go</strong>, I acknowledge that I am awesome. 
                      Also, I have read and understand the <a href="#terms">Terms and Conditions</a>.
                      '
                  * elem  : "input"
                    class : "span1"
                    style : "float: right"
                    attr  : '''
                      type           = checkbox
                      name=terms
                      checked
                      data-required  = true
                      data-trigger   = change
                      data-error-container  = .error-container
                      '''
                  * elem  : "div"
                    class : "error-container"

                  * elem  : "button"
                    class : "btn row-fluid btn-primary"
                    style : "margin-bottom: 0"
                    text  : "Go"
                    attr  : "id=signup"
                ...

      * name    : "services"
        rows    :

          * groups  :

              * class : "services"
                fields  :
                  * elem  : "button"
                    class : "btn-facebook wide"
                    attr  : "data-service=facebook"
                    text  : "with Facebook"
                    icon  : "facebook"
                  * elem  : "button"
                    class : "btn-google wide"
                    attr  : "data-service=google"
                    text  : "with Google"
                    icon  : "google-plus"
                  * elem  : "button"
                    class : "btn-github wide"
                    attr  : "data-service=github"
                    text  : "with Github"
                    icon  : "github-alt"
              ...
          ...

      * name    : "login"
        rows    :

          * attr    : "data-focus=first"
            class   : "row-fluid"
            groups  :

              * label : "Username"
                class : "span6"
                fields  :
                  * elem  : "input"
                    attr  : """
                      name=user
                      value = mikey
                      data-required  = true
                      data-trigger   = change
                      data-type      = alphanum
                      data-minlength = 3
                      data-maxlength = 20
                      """
                    ...

              * label : "Password"
                class : "span6"
                fields  :
                  * elem  : "input"
                    attr  : """
                      name=password
                      type           = password
                      value = 321321
                      data-required  = true
                      data-trigger   = change
                      data-minlength = 5
                      data-maxlength = 20
                      """
                    ...

          * class   : "form-footer row-fluid"
            groups  :

              * class   : "span10 block"
                style   : """
                  display:inline-block; 
                  text-align: left;
                  """
                fields  :

                  * elem  : "p"
                    class : ""
                    text  : "Don't have an account?"

                  * elem  : "a"
                    class : ""
                    text  : "Wanna?"
                    attr  : "href=/account/signup"

              * class   : "span2 block"
                style   : """
                  text-align: right;
                  """
                fields  :
                  * elem  : "button span2"
                    class : "btn-primary"
                    text  : "Login"
                    attr  : "id=login"
                    ...



  * 0

  * rendered  : ->
      @tool-tip ?= $ '.tip' .tooltip!

      @data.center!

    events    : do ->
      'click [data-service]'  : (e, t) ->
        e.prevent-default!
        Meteor[ "loginWith" + e.current-target.get-attribute("data-service").to-proper-case! ]!

      'click [data-link]'     : (e, t) ->
        e.prevent-default!
        Meteor.Router.to e.current-target.get-attribute "data-link"

      'click button#login'   : (e, t) ->
        e.prevent-default!
        let @ = t.data
          @form-validate ~>
            Meteor.login-with-password it.user, it.password, ~>
              | it => @ ..set "error", it.reason ..save!
              | _
                @ ..set "error", null ..save!
                Meteor.Router.to '/account/profile'

                console.log "LOGGED IN USER"

      'click button#signup'   : (e, t) ->
        e.prevent-default!
        let @ = t.data
          @form-validate (res) ~>
            Accounts.create-user {res.username, res.email, res.password, profile: {res.name}}, ~>
              | it => @ ..set "error", it.reason ..save!
              | _
                @ ..set "error", null ..save!

                console.log "SAVED USER", res.username


  * proto  :
      form-validate : ( cb ) ->
        form = $ "form##{@name}"
        unless form.parsley 'validate' => return
        cb Form.serialize form

      center : ->
        ch ?= null

        if @style?.length? => return

        run = ~>
          F  = $ 'form'
          C  = F.parents '.container-trim' 
          ch = C.height!
          cp = parse-int C.css("padding-top")

          if ch > 1
            P  = C.parent!
            ph = P.height!

            OUT = do -> ((ph / 2) - (ch / 2) - cp - 30).to-string! + "px"

            @ ..set "style", """
                margin-top: #{OUT};
                visibility: visible;
                """
              ..save!

        if ch < 1
          console.log "IT's LESS THAN 1"
          _.delay run, 50




link_href     = -> "active_menu_links_" + it.href.split('/')[1]
link_active   = -> if it.name is Session.get link_href it => "active"
link_activate = -> Session.set (link_href it), it.name



GENERATE {}=
  * klass : \Menu
    mix   : <[ ]>

  * coll    : \Menus
    trans   : -> Menu.new it
    stable  : []=


      * name  : "home"
        pages : <[ home ]>
        rows  :
          * items : ->
              query = _.extend {}, Session.get 'query'
              Tag.cache-load!
              Tag.rated.find query .fetch!
            ...

      * name  : "account"

      * name  : "account"
        pages : <[
          account_profile
          account_profile_settings
          account_offer
          ]>
        rows  :
          * items :
              * name : "offer"
                href : "/account/offer"
                class: -> link_active @
              * name : "settings"
                href : "/account/profile/settings"
                class: -> link_active @
            ...


      * name  : "about"

  * 0

  * rendered : ->
      console.log "rendered menu", @data.name

    events   : do ->
      'click a': (e, t) ->
        if @href
          link_activate @
        # else
        #   if not _.contains sg, @name
        #     ss sg ++ @name
        #   else
        #     ss _.without sg, @name



# Session.set 'loaded_stables', true



GENERATE {}=
  * klass : \Prompt
    mix   : <[]>

  * coll    : \Prompts
    scratch : true
    trans   : -> Prompt.new it

  * locks :
      owner-id  : -> My.user-id!
      set-at    : -> Time.now!

  * 0

  * method :
      target  : -> @new { target-id: it }
      test    : -> it in map (.target-id), My.prompts!

# Session.set 'loaded_scratches', true
