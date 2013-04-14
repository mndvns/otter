var setArea;
setArea = function(it){
  var j;
  Session.set("shift_current_area", it);
  j = $("li[data-shift-area=" + it.split('_')[0] + "]");
  return j.trigger('click');
};
Meteor.Router.add({
  "/": function(){
    setArea('home');
    return "home";
  },
  "/:area": function(area){
    var store_page;
    if (store_page = Store.get("page_" + area)) {
      return setArea(store_page);
    } else {
      return setArea(area);
    }
  },
  "/:area/:link": function(area, link){
    var store_page;
    if (store_page = Store.get("page_" + area + "_" + link)) {
      return setArea(store_page);
    } else {
      return setArea(area + "_" + link);
    }
  },
  "/:area/:link/:sublink": function(area, link, sublink){
    var sub_area;
    sub_area = area + "_" + link + "_" + sublink;
    if (link === "collections") {
      Store.set("nab", sublink.toProperCase());
      Store.set("nab_query", {});
      Store.set("nab_sort", {});
    }
    return setArea(sub_area);
  },
  "/offer/:id": function(id){
    Session.set("showThisOffer", Offers.findOne({
      business: id
    }));
    Session.set("header", null);
    return "thisOffer";
  },
  "/*": function(){
    setArea('home');
    return "404";
  }
});
Meteor.Router.filters({
  checkAdmin: function(page){
    var user;
    user = Meteor.user();
    if (user.type === "basic") {
      return page;
    } else {
      return "home";
    }
  }
});
Meteor.Router.filter("checkAdmin", {
  only: ["/admin/users"]
});