var GENERATE, MIX, link_href, link_active, link_activate, toString$ = {}.toString;
GENERATE = App.Utils.Generate;
MIX = App.Utils.Mix;
GENERATE([
  {
    klass: 'Tag',
    mix: ['Check', 'Limit', 'Clone']
  }, {
    coll: 'Tags',
    trans: function(it){
      return Tag['new'](it);
    },
    cache: [{
      coll: 'rated',
      trans: function(it){
        return Tag['new'](it);
      }
    }]
  }, {
    limit: 50,
    locks: {
      ownerId: function(){
        return My.userId();
      },
      offerId: function(){
        return My.offerId() || 'pending';
      },
      tagset: function(){
        return My.tagset();
      },
      collection: function(){
        return "tags";
      }
    },
    schema: {
      "name": {
        'default': "tag",
        required: true,
        max: 20,
        min: 2
      },
      "tagset": {
        'default': "eat",
        required: true,
        max: 10,
        min: 2
      }
    }
  }, 0, {
    proto: {
      rateIt: function(){
        return this.rate = this.constructor.where({
          name: this.name
        }).count();
      }
    },
    method: {
      cacheLoad: function(a, b){
        var list, out, i$, ref$, len$, n, lout, key, val, x$, o, y$, range, fout, this$ = this;
        a == null && (a = {});
        switch (toString$.call(a).slice(8, -1)) {
        case "Object":
          list = Tag.where(a).fetch();
          break;
        default:
          list = Tag.where({}).fetch();
        }
        if (!(list.length > 0)) {
          return;
        }
        out = {};
        for (i$ = 0, len$ = (ref$ = (fn$())).length; i$ < len$; ++i$) {
          n = ref$[i$];
          if (n == null) {
            continue;
          }
          out[n] == null && (out[n] = 0);
          out[n] += 1;
        }
        lout = [];
        for (key in out) {
          val = out[key];
          x$ = o = find(fn1$, list);
          x$.rate = val;
          x$.index = lout.length;
          lout.push(o);
        }
        y$ = range = d3.scale.linear();
        y$.domain(function(it){
          return [_.min(it), _.max(it)];
        }(map(function(it){
          return it.rate;
        }, lout)));
        y$.range([1, 4]);
        this.rated.remove({}, {
          multi: true
        });
        each(function(it){
          it.size = round(range(it.rate));
          return this$.rated.insert(this$['new'](it));
        })(
        lout);
        fout = this.rated.find({}, {
          reactive: false
        }).fetch();
        Session.set("tickets", fout);
        switch (false) {
        case toString$.call(a).slice(8, -1) !== "Function":
          a();
          break;
        case toString$.call(b).slice(8, -1) !== "Function":
          b();
        }
        return fout;
        function fn$(){
          var i$, x$, ref$, len$, results$ = [];
          for (i$ = 0, len$ = (ref$ = list).length; i$ < len$; ++i$) {
            x$ = ref$[i$];
            results$.push(x$.name);
          }
          return results$;
        }
        function fn1$(it){
          return it.name === key;
        }
      }
    }
  }
]);
if (typeof Session != 'undefined' && Session !== null) {
  Session.setDefault("shift_next_area", null);
}
GENERATE([
  {
    klass: 'Anchor',
    mix: ['Cite']
  }, {
    coll: 'Anchors',
    trans: function(it){
      return Anchor['new'](it);
    },
    stable: [
      {
        name: "about",
        display: "about",
        glyph: "harddrive",
        arrow: "left"
      }, {
        name: "home",
        display: "connectedkc",
        glyph: "camera",
        arrow: "up"
      }, {
        name: "account",
        display: "account",
        glyph: "cog",
        arrow: "right"
      }
    ]
  }, 0, {
    rendered: function(){
      var current;
      console.log("RENDERED ANCHOR");
      current = Session.get("shift_current_area").split('_')[0];
      if (current === this.data.name) {
        return $(this.find('li')).trigger('click');
      }
    },
    events: function(){
      return {
        'click li': function(event, tmp){
          var t, ref$, store_area, store_sub_area, sub_area;
          t = $(event.currentTarget);
          switch (false) {
          case !t.is('.active'):
            return;
          case tmp.data.name !== Session.get("shift_current_area").split('_')[0]:
            return;
          case tmp.data.name !== ((ref$ = Session.get("shift_next_area")) != null ? ref$.split('_')[0] : void 8):
            return;
          }
          t.siblings().attr('class', 'inactive');
          t.attr('class', 'active');
          t.parent().attr('data-active-anchor', this.name);
          if (t.index() === 1) {
            t.siblings().addClass('split');
          }
          store_area = Store.get("page_" + this.name) || this.name;
          store_sub_area = Store.get("page_" + store_area);
          sub_area = store_sub_area || store_area;
          Session.set('shift_sub_area', sub_area);
          return Session.set('shift_next_area', this.name);
        }
      };
    }()
  }
]);
GENERATE([
  {
    klass: 'Form',
    mix: []
  }, {
    coll: 'Forms',
    trans: function(it){
      return Form['new'](it);
    },
    stable: [
      {
        name: "signup",
        rows: [
          {
            attr: "data-focus=first",
            'class': "row-fluid",
            groups: [
              {
                label: "Full Name",
                tip: "this is a tip",
                'class': "span6",
                fields: [{
                  elem: "input",
                  attr: "name=name\nvalue = mikey\ndata-required  = true\ndata-trigger   = change\ndata-type      = alphanum\ndata-minlength = 3\ndata-maxlength = 20"
                }]
              }, {
                label: "Email (optional)",
                tip: "this is a tip",
                'class': "span6",
                fields: [{
                  elem: "input",
                  attr: "name=email\ndata-type     = email\ndata-trigger  = change"
                }]
              }
            ]
          }, {
            'class': "row-fluid",
            groups: [
              {
                label: "Password",
                tip: "this is a tip",
                'class': "span6",
                fields: [{
                  elem: "input",
                  attr: "name=password\ntype           = password\nvalue = 321321\ndata-required  = true\ndata-trigger   = change\ndata-minlength = 5\ndata-maxlength = 20"
                }]
              }, {
                label: "Username",
                tip: "this is a tip",
                'class': "span6",
                fields: [{
                  elem: "input",
                  attr: "name=username\nvalue = mikey\ndata-required  = true\ndata-trigger   = change\ndata-minlength = 5\ndata-maxlength = 20"
                }]
              }
            ]
          }, {
            'class': "",
            groups: [{
              'class': "row-fluid actions",
              fields: [
                {
                  elem: "p",
                  'class': "span10 conditions",
                  text: 'By checking this box and clicking <strong>Go</strong>, I acknowledge that I am awesome. Also, I have read and understand the <a href="#terms">Terms and Conditions</a>.'
                }, {
                  elem: "input",
                  'class': "span1",
                  style: "float: right",
                  attr: 'type           = checkbox\nname=terms\nchecked\ndata-required  = true\ndata-trigger   = change\ndata-error-container  = .error-container'
                }, {
                  elem: "div",
                  'class': "error-container"
                }, {
                  elem: "button",
                  'class': "btn row-fluid btn-primary",
                  style: "margin-bottom: 0",
                  text: "Go",
                  attr: "id=signup"
                }
              ]
            }]
          }
        ]
      }, {
        name: "services",
        rows: [{
          groups: [{
            'class': "services",
            fields: [
              {
                elem: "button",
                'class': "btn-facebook wide",
                attr: "data-service=facebook",
                text: "with Facebook",
                icon: "facebook"
              }, {
                elem: "button",
                'class': "btn-google wide",
                attr: "data-service=google",
                text: "with Google",
                icon: "google-plus"
              }, {
                elem: "button",
                'class': "btn-github wide",
                attr: "data-service=github",
                text: "with Github",
                icon: "github-alt"
              }
            ]
          }]
        }]
      }, {
        name: "login",
        rows: [
          {
            attr: "data-focus=first",
            'class': "row-fluid",
            groups: [
              {
                label: "Username",
                'class': "span6",
                fields: [{
                  elem: "input",
                  attr: "name=user\nvalue = mikey\ndata-required  = true\ndata-trigger   = change\ndata-type      = alphanum\ndata-minlength = 3\ndata-maxlength = 20"
                }]
              }, {
                label: "Password",
                'class': "span6",
                fields: [{
                  elem: "input",
                  attr: "name=password\ntype           = password\nvalue = 321321\ndata-required  = true\ndata-trigger   = change\ndata-minlength = 5\ndata-maxlength = 20"
                }]
              }
            ]
          }, {
            'class': "form-footer row-fluid",
            groups: [
              {
                'class': "span10 block",
                style: "display:inline-block; \ntext-align: left;",
                fields: [
                  {
                    elem: "p",
                    'class': "",
                    text: "Don't have an account?"
                  }, {
                    elem: "a",
                    'class': "",
                    text: "Wanna?",
                    attr: "href=/account/signup"
                  }
                ]
              }, {
                'class': "span2 block",
                style: "text-align: right;",
                fields: [{
                  elem: "button span2",
                  'class': "btn-primary",
                  text: "Login",
                  attr: "id=login"
                }]
              }
            ]
          }
        ]
      }
    ]
  }, 0, {
    rendered: function(){
      this.toolTip == null && (this.toolTip = $('.tip').tooltip());
      return this.data.center();
    },
    events: function(){
      return {
        'click [data-service]': function(e, t){
          e.preventDefault();
          return Meteor["loginWith" + e.currentTarget.getAttribute("data-service").toProperCase()]();
        },
        'click [data-link]': function(e, t){
          e.preventDefault();
          return Meteor.Router.to(e.currentTarget.getAttribute("data-link"));
        },
        'click button#login': function(e, t){
          e.preventDefault();
          return (function(){
            var this$ = this;
            return this.formValidate(function(it){
              return Meteor.loginWithPassword(it.user, it.password, function(it){
                var x$, y$;
                switch (false) {
                case !it:
                  x$ = this$;
                  x$.set("error", it.reason);
                  x$.save();
                  return x$;
                  break;
                default:
                  y$ = this$;
                  y$.set("error", null);
                  y$.save();
                  Meteor.Router.to('/account/profile');
                  return console.log("LOGGED IN USER");
                }
              });
            });
          }.call(t.data));
        },
        'click button#signup': function(e, t){
          e.preventDefault();
          return (function(){
            var this$ = this;
            return this.formValidate(function(res){
              return Accounts.createUser({
                username: res.username,
                email: res.email,
                password: res.password,
                profile: {
                  name: res.name
                }
              }, function(it){
                var x$, y$;
                switch (false) {
                case !it:
                  x$ = this$;
                  x$.set("error", it.reason);
                  x$.save();
                  return x$;
                  break;
                default:
                  y$ = this$;
                  y$.set("error", null);
                  y$.save();
                  return console.log("SAVED USER", res.username);
                }
              });
            });
          }.call(t.data));
        }
      };
    }()
  }, {
    proto: {
      formValidate: function(cb){
        var form;
        form = $("form#" + this.name);
        if (!form.parsley('validate')) {
          return;
        }
        return cb(Form.serialize(form));
      },
      center: function(){
        var ch, ref$, run, this$ = this;
        ch == null && (ch = null);
        if (((ref$ = this.style) != null ? ref$.length : void 8) != null) {
          return;
        }
        run = function(){
          var F, C, ch, cp, P, ph, OUT, x$;
          F = $('form');
          C = F.parents('.container-trim');
          ch = C.height();
          cp = parseInt(C.css("padding-top"));
          if (ch > 1) {
            P = C.parent();
            ph = P.height();
            OUT = function(){
              return (ph / 2 - ch / 2 - cp - 30).toString() + "px";
            }();
            x$ = this$;
            x$.set("style", "margin-top: " + OUT + ";\nvisibility: visible;");
            x$.save();
            return x$;
          }
        };
        if (ch < 1) {
          console.log("IT's LESS THAN 1");
          return _.delay(run, 50);
        }
      }
    }
  }
]);
link_href = function(it){
  return "active_menu_links_" + it.href.split('/')[1];
};
link_active = function(it){
  if (it.name === Session.get(link_href(it))) {
    return "active";
  }
};
link_activate = function(it){
  return Session.set(link_href(it), it.name);
};
GENERATE([
  {
    klass: 'Menu',
    mix: []
  }, {
    coll: 'Menus',
    trans: function(it){
      return Menu['new'](it);
    },
    stable: [
      {
        name: "home",
        pages: ['home'],
        rows: [{
          items: function(){
            var query;
            query = _.extend({}, Session.get('query'));
            Tag.cacheLoad();
            return Tag.rated.find(query).fetch();
          }
        }]
      }, {
        name: "account"
      }, {
        name: "account",
        pages: ['account_profile', 'account_profile_settings', 'account_offer'],
        rows: [{
          items: [
            {
              name: "offer",
              href: "/account/offer",
              'class': function(){
                return link_active(this);
              }
            }, {
              name: "settings",
              href: "/account/profile/settings",
              'class': function(){
                return link_active(this);
              }
            }
          ]
        }]
      }, {
        name: "about"
      }
    ]
  }, 0, {
    rendered: function(){
      return console.log("rendered menu", this.data.name);
    },
    events: function(){
      return {
        'click a': function(e, t){
          if (this.href) {
            return link_activate(this);
          }
        }
      };
    }()
  }
]);
GENERATE([
  {
    klass: 'Prompt',
    mix: []
  }, {
    coll: 'Prompts',
    scratch: true,
    trans: function(it){
      return Prompt['new'](it);
    }
  }, {
    locks: {
      ownerId: function(){
        return My.userId();
      },
      setAt: function(){
        return Time.now();
      }
    }
  }, 0, {
    method: {
      target: function(it){
        return this['new']({
          targetId: it
        });
      },
      test: function(it){
        return in$(it, map(function(it){
          return it.targetId;
        }, My.prompts()));
      }
    }
  }
]);
function in$(x, arr){
  var i = -1, l = arr.length >>> 0;
  while (++i < l) if (x === arr[i] && i in arr) return true;
  return false;
}