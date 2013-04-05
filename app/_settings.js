var arrayRepeat, numberWithCommas, Time, Stopwatch;
String.prototype.toProperCase = function(){
  return this.replace(/\w\S*/g, function(txt){
    return txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase();
  });
};
String.prototype.repeat = function(num){
  var out;
  out = new Array(num + 1).join("");
  return out;
};
arrayRepeat = function(value, len){
  var out;
  len += 1;
  out = [];
  while (len -= 1) {
    out.push(value);
  }
  return out;
};
numberWithCommas = function(x){
  return x != null ? x.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",") : void 8;
};
Time = {
  now: function(){
    return Date.now();
  },
  addMinutes: function(time, min){
    return moment(time).add('minutes', min).unix() * 1000;
  }
};
Stopwatch = (function(){
  Stopwatch.displayName = 'Stopwatch';
  var prototype = Stopwatch.prototype, constructor = Stopwatch;
  prototype.constructor = function(name){
    window[name] = this;
    this.countKeeper = 1;
    return this.start = Time.now();
  };
  prototype.click = function(){
    this.start = Time.now();
    return this.clicked = true;
  };
  prototype.stop = function(){
    var stopValue;
    switch (this.clicked) {
    case false:
      console.log("    redundant...");
      return this.clicked = null;
    case null:
      break;
    case true:
      switch (this.countKeeper) {
      case this.count:
        stopValue = numberWithCommas(Time.now() - this.start) + " milliseconds";
        console.log(stopValue, " for ", this.count, " items");
        return this.clicked = false;
      default:
        return this.countKeeper += 1;
      }
    }
  };
  prototype.setCount = function(count){
    this.count = count;
    return this.countKeeper = 1;
  };
  function Stopwatch(){
    this.setCount = bind$(this, 'setCount', prototype);
    this.stop = bind$(this, 'stop', prototype);
    this.click = bind$(this, 'click', prototype);
  }
  return Stopwatch;
}());
function bind$(obj, key, target){
  return function(){ return (target || obj)[key].apply(obj, arguments) };
}