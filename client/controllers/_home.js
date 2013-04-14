var validateArea, areas, getArea;
this.statCurrent = function(){
  var out;
  out = {
    query: {
      tagset: Store.get("current_tagsets"),
      tag: Store.get("current_tags"),
      sort: {
        verbose: Store.get("current_sorts"),
        specifier: Store.get("current_sorts_specifier"),
        selector: Store.get("current_sorts_selector"),
        order: Store.get("current_sorts_order")
      }
    },
    verbose: {
      tagset: Store.get("current_tagsets"),
      tag: Store.get("current_tags"),
      sort: Store.get("current_sorts"),
      sort_selector: Store.get("current_sorts_selector")
    }
  };
  return out;
};
this.statRange = function(){
  var out;
  out = {
    max: {
      updatedAt: amplify.store("max_updatedAt"),
      nearest: amplify.store("max_nearest"),
      points: amplify.store("max_points"),
      price: amplify.store("max_price")
    },
    min: {
      updatedAt: amplify.store("min_updatedAt"),
      nearest: amplify.store("min_nearest"),
      points: amplify.store("min_points"),
      price: amplify.store("min_price")
    }
  };
  return out;
};
Template.main.rendered = function(){
  return Session.setDefault("rendered_main", true);
};
Template.content.events({
  'click .accord header': function(event, tmpl){
    if (!$(event.target).hasClass("active")) {
      $(event.currentTarget).siblings().slideDown();
    } else {
      $(event.currentTarget).siblings().slideUp();
    }
    return $(event.target).toggleClass("active");
  }
});
validateArea = {
  account: [{
    exclude: ['account_join', 'account_signup', 'account_login'],
    test: function(){
      return My.user() == null;
    },
    onfail: function(){
      return 'account_join';
    }
  }]
};
areas = {
  account: {
    nav: function(){
      return Tags.find().fetch();
    }
  }
};
getArea = function(session_area, cb){
  var area, val, i$, len$, v;
  area = Session.get(session_area);
  if (!area) {
    return;
  }
  if (val = validateArea[area.split('_')[0]]) {
    for (i$ = 0, len$ = val.length; i$ < len$; ++i$) {
      v = val[i$];
      if (!in$(area, v.exclude)) {
        if (v.test()) {
          area = v.onfail();
          break;
        }
      }
    }
  }
  return cb(area);
};
Template.content.helpers({
  current_page: function(){
    return getArea("shift_current_area", function(area){
      return Template[area]();
    });
  },
  next_page: function(){
    return getArea("shift_sub_area", function(area){
      var parse_area, parse_sub_area;
      parse_area = area.split('_');
      parse_sub_area = parse_area.join('/');
      Meteor.Transitioner.setOptions({
        after: function(){
          Meteor.Router.to(parse_sub_area === "home"
            ? "/"
            : "/" + parse_sub_area);
          Session.set("shift_current_menu", area);
          Session.set("shift_current_area", area);
          Session.set("shift_sub_area", null);
          return Session.set("shift_next_menu", null);
        }
      });
      Session.set("shift_next_menu", area);
      return Template[area]();
    });
  }
});
Template.menus.helpers({
  current_menu: function(){
    var menu;
    if (menu = Menus.findOne({
      pages: Session.get("shift_current_menu")
    })) {
      return Template.menu(menu);
    }
  },
  next_menu: function(){
    var menu;
    if (menu = Menus.findOne({
      pages: Session.get("shift_next_menu")
    })) {
      Session.set("RANGO", Random.id());
      return Template.menu(menu);
    }
  }
});
Template.sidebar.events({
  'click .logout': function(){
    return Meteor.logout();
  }
});
Template.home.helpers({
  get_offers: function(){
    var ref$, ranges, result, r;
    this.coll == null && (this.coll = new Meteor.Collection(null));
    if (!((ref$ = this.offers) != null && ref$.length)) {
      this.offers = Offer.loadAll(this.coll);
    }
    if (!this.offers) {
      return;
    }
    ranges = {
      updatedAt: [],
      nearest: [],
      points: [],
      price: []
    };
    result = this.coll.find(Store.get("current_tagsets"), Store.get("current_sorts"), {
      reactive: true
    }).map(function(d){
      var r;
      for (r in ranges) {
        ranges[r].push(d[r]);
      }
      return d;
    });
    for (r in ranges) {
      amplify.store("max_" + r, _.max(ranges[r]));
      amplify.store("min_" + r, _.min(ranges[r]));
    }
    return result;
  },
  styleDate: function(date){
    return moment(date).fromNow();
  }
});
Template.intro.events({
  'click #getLocation': function(event, tmpl){
    var noLocation, foundLocation;
    Meteor.Alert.set({
      text: "One moment while we charge the lasers...",
      wait: true
    });
    noLocation = function(){
      return Meteor.Alert.set({
        text: "Uh oh... something went wrong"
      });
    };
    foundLocation = function(location){
      Meteor.Alert.set({
        text: "Booya! Lasers charged!"
      });
      return Store.set("user_loc", {
        lat: location.coords.latitude,
        long: location.coords.longitude
      });
    };
    return navigator.geolocation.getCurrentPosition(foundLocation, noLocation);
  },
  'click .geolocate': function(event, tmpl){
    var location, geo;
    location = tmpl.find("input").value;
    if (!location) {
      Meteor.Alert.set({
        text: "No location entered"
      });
      return;
    }
    Meteor.Alert.set({
      text: "One moment...",
      wait: true
    });
    geo = new google.maps.Geocoder();
    return geo.geocode({
      address: location
    }, function(results, status){
      var loc, userLoc, key;
      if (status !== "OK") {
        return Meteor.Alert.set({
          text: "We couldn't seem to find your location. Did you enter your address correctly?"
        });
      } else {
        Meteor.Alert.set({
          text: "Found ya!"
        });
        loc = results[0].geometry.location;
        userLoc = [];
        for (key in loc) {
          if (typeof loc[key] !== 'number') {
            break;
          }
          userLoc.push(loc[key]);
        }
        console.log("USERLOC", userLoc);
        return Store.set("user_loc", {
          lat: userLoc[0],
          long: userLoc[1]
        });
      }
    });
  }
});
Template.intro.rendered = function(){
  var window_height, intro, intro_height;
  window_height = $(".current").height() / 2;
  intro = $(this.find('#intro'));
  intro_height = intro.outerHeight() * 0.75;
  return intro.css({
    'margin-top': window_height - intro_height
  });
};
function in$(x, arr){
  var i = -1, l = arr.length >>> 0;
  while (++i < l) if (x === arr[i] && i in arr) return true;
  return false;
}