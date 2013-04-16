var validateEmail;
App.Templates = {};
(function(){
  var ms;
  ms = Meteor.subscribe;
  ms("all_locations", function(){
    return console.log("");
  });
  ms("my_offer");
  ms("my_tags");
  ms("my_pictures");
  ms("my_messages");
  ms("my_alerts");
  ms("my_prompts");
  ms("points");
  ms("all_offers", function(){
    return Session.set('offer_subscribe_ready', true);
  });
  ms("all_tags", function(){
    return Session.set('tags_subscribe_ready', true);
  });
  return ms("all_markets");
})();
(function(){
  var mt, out;
  mt = Mousetrap;
  out = [['left', 'about'], [['up', 'down'], "home"], ['right', 'account']];
  return _.each(out, function(o){
    return mt.bind(o[0], function(){
      return $("nav.anchors li[data-shift-area=" + o[1] + "]").trigger('click');
    });
  });
})();
this.Store = Meteor.BrowserStore;
Store.clear = function(){
  var keys, keeps, diffs, i$, len$, diff, results$ = [];
  keys = Object.keys(Store.keys);
  keeps = ["user_loc", "notes", "gray", "current_nouns", "current_sorts", "current_sorts_order", "current_sorts_selector", "current_tags", "current_tagsets"];
  diffs = _.difference(keys, keeps);
  for (i$ = 0, len$ = diffs.length; i$ < len$; ++i$) {
    diff = diffs[i$];
    console.log(diff);
    results$.push(Store.set(diff, null));
  }
  return results$;
};
Store.clearAll = function(){
  var keys, i$, len$, key, results$ = [];
  keys = _.keys(Store.keys);
  for (i$ = 0, len$ = keys.length; i$ < len$; ++i$) {
    key = keys[i$];
    console.log(key);
    results$.push(Store.set(key, null));
  }
  return results$;
};
this.getLocation = function(){
  var foundLocation, noLocation;
  Meteor.Alert.set({
    text: "One moment while we charge the lasers...",
    wait: true
  });
  foundLocation = function(location){
    Store.set("user_loc", {
      lat: location.coords.latitude,
      long: location.coords.longitude
    });
    return Meteor.Alert.set({
      text: "Booya! Lasers charged!"
    });
  };
  noLocation = function(){
    return Meteor.Alert.set({
      text: "Uh oh... something went wrong"
    });
  };
  return navigator.geolocation.getCurrentPosition(foundLocation, noLocation);
};
validateEmail = function(email){
  var re;
  re = /^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
  return re.test(email);
};
Meteor.startup(function(){
  var initialize;
  window.google == null && (window.google = null);
  window.initialize = initialize = function(){
    return console.log("GM INITIALIZED");
  };
  $.getScript("https://maps.googleapis.com/maps/api/js?key=AIzaSyCcvzbUpSUtw1mK30ilGnHhGMPhIptp6Z4&sensor=false&callback=initialize");
  $.getScript("http://d-project.googlecode.com/svn/trunk/misc/qrcode/js/qrcode.js");
  (function(){
    var config, h, t, tk, d, s;
    config = {
      kitId: "lnp0fti",
      scriptTimeout: 3000
    };
    h = document.getElementsByTagName("html")[0];
    h.className += " wf-loading";
    t = setTimeout(function(){
      h.className = h.className.replace(/(\s|^)wf-loading(\s|$)/g, " ");
      return h.className += " wf-inactive";
    }, config.scriptTimeout);
    tk = document.createElement("script");
    d = false;
    tk.src = "//use.typekit.net/" + config.kitId + ".js";
    tk.type = "text/javascript";
    tk.async = "true";
    tk.onload = tk.onreadystatechange = function(){
      var a, d;
      a = this.readyState;
      if (d || a && a !== "complete" && a !== "loaded") {
        return;
      }
      d = true;
      clearTimeout(t);
      try {
        return Typekit.load(config);
      } catch (e$) {}
    };
    s = document.getElementsByTagName("script")[0];
    return s.parentNode.insertBefore(tk, s);
  })();
  new Stopwatch("watchOffer");
  if (!Store.get("gray")) {
    return Store.set("gray", "hero");
  }
});