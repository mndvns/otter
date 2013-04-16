(function(){
  var Transitioner;
  Transitioner = (function(){
    Transitioner.displayName = 'Transitioner';
    var prototype = Transitioner.prototype, constructor = Transitioner;
    function Transitioner(){
      this._currentPage = null;
      this._currentPageListeners = new Deps.Dependency();
      this._nextPage = null;
      this._nextPageListeners = new Deps.Dependency();
      this._direction = null;
      this._options = {};
    }
    prototype._transitionEvents = "webkitTransitionEnd.transitioner oTransitionEnd.transitioner transitionEnd.transitioner msTransitionEnd.transitioner transitionend.transitioner";
    prototype._transitionClasses = function(){
      return "transitioning from_" + this._currentPage + " to_" + this._nextPage + " going_" + this._direction;
    };
    prototype.setOptions = function(it){
      return _.extend(this._options, it);
    };
    prototype.currentPage = function(){
      Deps.depend(this._currentPageListeners);
      return this._currentPage;
    };
    prototype._setCurrentPage = function(it){
      this._currentPage = it;
      return this._currentPageListeners.changed();
    };
    prototype.nextPage = function(){
      Deps.depend(this._nextPageListeners);
      return this._nextPage;
    };
    prototype._setNextPage = function(it){
      this._nextPage = it;
      return this._nextPageListeners.changed();
    };
    prototype.listen = function(){
      var this$ = this;
      return Deps.autorun(function(){
        return this$.transition(Session.get('shift_next_area'));
      });
    };
    prototype.transition = function(it){
      var this$ = this;
      switch (false) {
      case !!this._currentPage:
        return this._setCurrentPage(Session.get("shift_current_area"));
      case !this._nextPage:
        this.endTransition();
        break;
      case this._currentPage !== it:
        return;
      }
      this._setNextPage(it);
      return Deps.afterFlush(function(){
        var ref$;
        if (typeof (ref$ = this$._options).before === 'function') {
          ref$.before();
        }
        this$.transitionClasses = this$._transitionClasses();
        return $("body").addClass(this$.transitionClasses).on(this$._transitionEvents, function(it){
          if ($(it.target).is("body")) {
            return this$.endTransition();
          }
        });
      });
    };
    prototype.endTransition = function(){
      var this$ = this;
      if (!this._nextPage) {
        return;
      }
      this._setCurrentPage(this._nextPage);
      this._setNextPage(null);
      return Deps.afterFlush(function(){
        var ref$;
        $("body").off(".transitioner").removeClass(this$.transitionClasses);
        return typeof (ref$ = this$._options).after === 'function' ? ref$.after() : void 8;
      });
    };
    return Transitioner;
  }());
  Meteor.Transitioner = new Transitioner();
  return Meteor.startup(function(){
    return Meteor.Transitioner.listen();
  });
})();