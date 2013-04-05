var Sparrow, statCurrent, statRange, Conf;
Sparrow = {};
Sparrow.shift = function(){
  return Session.get("shift_area");
};
statCurrent = function(){
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
statRange = function(){
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
Template.wrapper.rendered = function(){
  return Session.setDefault("rendered_wrapper", true);
};
Template.wrapper.events({
  "click .shift": function(event, tmpl){
    var dir, area, page, current, store_area, store_sub_area, sub_area;
    if (event.currentTarget.hasAttribute("disabled")) {
      return;
    }
    dir = event.currentTarget.getAttribute("data-shift-direction");
    area = event.currentTarget.getAttribute("data-shift-area");
    page = Meteor.Router.page();
    current = page.split("_")[0];
    store_area = Store.get("page_" + area) || area;
    store_sub_area = Store.get("page_" + store_area);
    sub_area = store_sub_area || store_area;
    Session.set("shift_direction", dir);
    Session.set("shift_area", area);
    Session.set("shift_sub_area", sub_area);
    return Session.set("shift_current", current);
  }
});
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
Conf = (function(){
  Conf.displayName = 'Conf';
  var prototype = Conf.prototype, constructor = Conf;
  function Conf(current){
    var ref$;
    this.sort = {};
    if ((ref$ = current.sort.verbose) != null && ref$.length) {
      this.sort[current.sort.specifier] = {};
      this.sort[current.sort.specifier][current.sort.selector] = current.sort.order;
    } else {
      this.sort_empty = true;
    }
    this.query = {};
    if ((ref$ = current.tagset) != null && ref$.length) {
      this.query.tagset = current.tagset.toString();
      if ((ref$ = current.tag) != null && ref$.length) {
        this.query.tags = {
          $in: current.tag
        };
      }
    }
  }
  return Conf;
}());
Template.home.helpers({
  get_offers: function(){
    var current, myLoc, conf, ranges, notes, result, r, n;
    this.coll == null && (this.coll = new Meteor.Collection(null));
    switch (false) {
    case !!this.offers:
      this.offers = Offer.loadAll(this.coll);
      break;
    case !(this.offers.length <= 0):
      this.offers = Offer.loadAll(this.coll);
      break;
    default:
      console.log("CACHE USED");
    }
    if (!this.offers) {
      return;
    }
    current = statCurrent().query;
    myLoc = Store.get("user_loc");
    conf = new Conf(current);
    ranges = {
      updatedAt: [],
      nearest: [],
      points: [],
      price: []
    };
    notes = {
      count: 0,
      votes: 0
    };
    result = this.coll.find(conf.query, conf.sort, {
      reactive: true
    }).map(function(d){
      var r;
      d.rand = _.random(0, 999);
      for (r in ranges) {
        ranges[r].push(d[r]);
      }
      notes.count += 1;
      notes.votes += d.points;
      if (conf.sort_empty && d.rand) {
        d.shuffle = current.sort.order * d.rand;
        d.shuffle = parseInt(d.shuffle.toString().slice(1, 4));
      }
      return d;
    });
    if (result && myLoc) {
      for (r in ranges) {
        amplify.store("max_" + r, _.max(ranges[r]));
        amplify.store("min_" + r, _.min(ranges[r]));
      }
      for (n in notes) {
        notes[n] = numberWithCommas(notes[n]);
      }
      Store.set("notes", notes);
      if (conf.sort_empty) {
        return result = _.sortBy(result, "shuffle");
      } else {
        return result;
      }
      result;
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