var HeroList, heroTag;
Template.hero.events({
  "click .list li": function(event, tmpl){
    var story, current, active, output, nouns, loc;
    tmpl.handle.stop();
    story = d3.select(event.currentTarget).data()[0];
    current = Store.get("current_" + story.collection);
    active = $(event.currentTarget).is(".active");
    output = void 8;
    if (active) {
      output = _.without(current, story.name);
      if (story.collection === "tagsets") {
        nouns = Store.get("current_nouns");
        Store.set("current_nouns", _.without(nouns, story.noun));
      }
    } else {
      switch (story.collection) {
      case "tags":
        output = current.concat(story.name);
        break;
      case "tagsets":
        output = [story.name];
        Store.set("current_nouns", [story.noun]);
        Store.set("current_tags", []);
        break;
      case "sorts":
        output = [story.name];
        switch (story.selector) {
        case "random":
          output = [];
          story.order = _.random(1, 100);
          break;
        case "$near":
          loc = Store.get("user_loc");
          story.order = [loc.lat, loc.long];
        }
        Store.set("current_sorts_specifier", story.specifier);
        Store.set("current_sorts_selector", story.selector);
        Store.set("current_sorts_order", story.order);
      }
    }
    Session.set("current_changed", story.collection);
    return Store.set("current_" + story.collection, output);
  },
  "click .headline .tag span": function(event, tmpl){
    var selector, current, out;
    selector = event.target.textContent;
    current = Store.get("current_tags");
    out = _.without(current, selector);
    return Store.set("current_tags", out);
  }
});
HeroList = function(opt){
  var ref$, key$, list, item, active, inactive;
  (ref$ = opt.current)[key$ = opt.name] == null && (ref$[key$] = []);
  list = d3.select("ul." + opt.name + "-list");
  item = list.selectAll("li").data(opt.collection);
  item.enter().insert("li");
  item.datum(function(d, i){
    d.status = _.contains(opt.current[opt.name], d[opt.selector]) ? "active" : "inactive";
    return d;
  }).attr("class", function(it){
    return it.status;
  }).html(function(d){
    var child;
    child = "";
    if (opt.name === "tag") {
      child = "<span class='badge " + d.status + "'>" + d.rate + "</span>";
    }
    return d[opt.selector] + child;
  });
  item.exit().remove();
  active = list.selectAll("li.active").transition().style({
    'font-size': '18px'
  });
  inactive = list.selectAll("li.inactive").transition().style({
    'font-size': '13px'
  });
  return list;
};
heroTag = function(){
  var list, px, current, dd, rates, max, min, width, upper, lower, x$, scale, items;
  list = d3.select('ul.tag-list');
  px = function(it){
    return it + 'px';
  };
  current = Store.get('current_tags');
  dd = dummydata;
  rates = _.pluck(dd, 'rate');
  max = _.max(rates);
  min = _.min(rates);
  width = parseInt(list.style('width'));
  upper = (function(it){
    return it * 0.10;
  })(width);
  lower = (function(it){
    return it * 0.04;
  })(width);
  x$ = scale = d3.scale.linear();
  x$.domain([min, max]);
  x$.range([lower, upper]);
  items = list.selectAll('li').data(dd);
  items.enter().insert('li');
  items.datum(function(it){
    it.size = (function(it){
      return it * 10;
    })(round((function(it){
      return it / 10;
    })(scale(it.rate))));
    return it;
  }).attr('class', function(it){
    switch (false) {
    case !_.contains(current, it.name):
      return "active";
    default:
      return "inactive";
    }
  }).text(function(it){
    return it.name;
  });
  items.style({
    'padding': function(it){
      return '0 ' + px(it.size);
    }
  });
  return items.on('click', function(){
    return console.log(this.__data__);
  });
};
Template.hero.created = function(){
  Session.set("heroRendered", false);
  Session.set("current_changed", null);
  if (!this.handle) {
    this.handle = Deps.autorun(function(){
      var tagsets, sorts, tags, out;
      tagsets = Tagsets.find().fetch();
      sorts = Sorts.find().fetch();
      tags = Tag.rateAll();
      if (tags && tags.length) {
        if (!Store.get("current_tagsets")) {
          Store.set("current_tagsets", ["eat"]);
          Store.set("current_tags", []);
          Store.set("current_sorts", ["latest"]);
          Store.set("current_sorts_specifier", "sort");
          Store.set("current_sorts_selector", "updatedAt");
          Store.set("current_sorts_order", "-1");
        }
        out = {
          tagsets: tagsets,
          tags: tags,
          sorts: sorts
        };
        as("collection", out);
        return Session.set("heroDataReady", true);
      }
    });
  }
  Deps.autorun(function(){
    var current, Collection, collection, heroList;
    if (!Session.get("heroRendered")) {
      return false;
    }
    if (!Session.get("heroDataReady")) {
      return false;
    }
    current = statCurrent().verbose;
    Collection = as("collection");
    collection = {
      tagset: Collection.tagsets,
      tag: _.filter(Collection.tags, function(d){
        return _.contains(current.tagset, d.tagset);
      }),
      sort: Collection.sorts
    };
    return heroList = {
      tagset: new HeroList({
        name: "tagset",
        selector: "name",
        leader: true,
        current: current,
        collection: collection.tagset
      }),
      sort: new HeroList({
        name: "sort",
        selector: "name",
        leader: false,
        current: current,
        collection: collection.sort
      }),
      tag: heroTag()
    };
  });
  return Session.set("heroUpdated", true);
};
Template.hero.rendered = function(tmpl){
  if (!Session.get("heroRendered")) {
    Session.set("heroRendered", true);
  }
  if (Session.get("heroDataReady")) {
    return this.handle && this.handle.stop();
  }
};