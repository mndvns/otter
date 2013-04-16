var validateArea, getArea, getMenu;
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
validateArea = {
  account: [{
    exclude: ['account_join', 'account_signup', 'account_login'],
    test: function(){
      return My.user() == null;
    },
    onfail: function(){
      return 'account_join';
    }
  }],
  home: [{
    exclude: ['home_launch'],
    test: function(){
      return My.user() == null;
    },
    onfail: function(){
      return 'home_launch';
    }
  }]
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
getMenu = function(it){
  return getArea(it, function(area){
    var menu;
    if (menu = Menus.findOne({
      pages: area
    })) {
      return Template.menu(menu);
    }
  });
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
          return Meteor.Router.to(parse_sub_area === "home"
            ? "/"
            : "/" + parse_sub_area);
        }
      });
      return Template[area]();
    });
  }
});
Template.menus.helpers({
  current_menu: function(){
    return getMenu("shift_current_area");
  },
  next_menu: function(){
    return getMenu("shift_sub_area");
  }
});
Template.home_intro.events({
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
Template.home_launch.rendered = function(){};
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
Template.anchors.rendered = function(){
  var current;
  current = Session.get("shift_current_area").split('_')[0];
  return $("li[data-shift-area=" + current + "]").trigger('click');
};
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
function in$(x, arr){
  var i = -1, l = arr.length >>> 0;
  while (++i < l) if (x === arr[i] && i in arr) return true;
  return false;
}