# 
# unless Meteor.is-client => return
# 
# do ->
#   class Transitioner
#     ->
#       @_current-page = null
#       @_next-page = null
# 
#       @_current-page-listeners  = new Deps.Dependency!
#       @_next-page-listeners     = new Deps.Dependency!
# 
#       @_direction = null
#       @_options = {}
# 
#     _transition-events  : """
#       webkitTransitionEnd.transitioner
#       oTransitionEnd.transitioner
#       transitionEnd.transitioner
#       msTransitionEnd.transitioner
#       transitionend.transitioner
#       """
#     _transition-classes : ->
#       "transitioning from_" + @_current-page + " to_" + @_next-page + " going_" + @_direction
# 
#     set-options   : ->
#       _.extend @_options, it
# 
# 
#     current-page  : ->
#       Deps.depend @_current-page-listeners
#       @_current-page
# 
#     next-page     : ->
#       Deps.depend @_next-page-listeners
#       @_next-page
# 
#     _set-current-page : ->
#       @_current-page = it
#       @_current-page-listeners.changed!
# 
#     _set-next-page : ->
#       @_next-page = it
#       @_next-page-listeners.changed!
# 
# 
#     listen      : -> 
#       Deps.autorun ~> @transition Session.get('shift_next_area')
# 
#     transition  : ->
# 
#       switch
#       | not @_current-page   => return @_set-current-page Session.get "shift_current_area"
#       | @_next-page          => return @end-transition!
#       | @_current-page is it => return
# 
#       @_set-next-page it
# 
#       Deps.after-flush ~>
#         @_options.before?()
#         @transition-classes?()
# 
#       $("body").add-class(@transition-classes).on @_transition-events, ~>
#         if $ it.target .is "body"  => @end-transition!
# 
#     end-transition : ->
# 
#       unless @_next-page => return
# 
#       @_set-current-page @_next-page
#       @_set-next-page null
# 
#       <~ Deps.after-flush
#       $ "body" .off ".transitioner" .remove-class @transition-classes
#       @_options.after?()
# 
#   Meteor.Transitioner = new Transitioner!
# 
#   Meteor.startup ->
#     Meteor.Transitioner.listen!
# 
