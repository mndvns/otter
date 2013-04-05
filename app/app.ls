type = ->
  unless it?
    return String it
  class-to-type = new Object
  for name in <[ Boolean Number String Function Array Date RegExp ]>
    class-to-type["[object #{name}]"] = name.to-lower-case!
  my-class = Object.prototype.to-string.call it
  if my-class of class-to-type
    return class-to-type[my-class]
  return "object"




@A = @App = Meteor.App = {}

@log = -> console.log &

# @EH = Event-horizon


String ::=

    to-proper-case : ->
      @replace /\w\S*/g , (txt) ->
        txt.char-at 0 .to-upper-case! + txt.substr 1 .to-lower-case!

    repeat : -> new Array( it + 1 ).join ""

array-repeat = (value, len) ->
  len +=1
  out = []
  while len -=1
    out.push(value)
  out

number-with-commas = (x)->
  x?.to-string!replace(/\B(?=(\d{3})+(?!\d))/g, ",")




self = @

@My =

  env       : ->
    | Meteor.isServer => return global
    | Meteor.isClient => return window

  user      : ->
    | Meteor.isServer => return Meteor.user!
    | Meteor.isClient => return Meteor.user!

  userId    : ->
    | Meteor.isServer => return self.userId
    | Meteor.isClient => return Meteor.userId!

  userLoc   : -> Store?.get "user_loc"

  customer  : -> Customers.findOne ownerId: @userId!
  customerId: -> @customer! ?.id

  offer     : -> Offers?.findOne ownerId: @userId!
  offer-id  : -> @offer! ?._id

  market    : -> Markets.findOne ownerId: @userId!

  tags      : -> Tags?.find ownerId: @userId! .fetch!
  tagset    : -> @offer! ?.tagset

  locations : -> Locations?.find ownerId: @userId! .fetch!
  pictures  : -> Pictures?.find ownerId: @userId! .fetch!

  alert     : -> Alerts?.find-one owner-id: @user-id! ?._id
  prompts   : -> Prompts?.find!.fetch!



  init      : (klass, obj = {}) -> @[klass]! or @env![klass.to-proper-case!].new obj
  map       : (field, list) --> map (-> it[field]), @[list]?!




@Is =

  mine  : -> My.user-id! is it?.owner-id




Meteor.methods {}=
  upvoteEvent: (offer) ->
    @unblock?!

    Offers.update offer._id,
      $push:
        votes_meta:
          user: @userId
          exp: Time.now!
      $inc:
        votes_count: 1

    Meteor.users.update offer.owner,
      $inc:
        karma: 1

  instance_destroy_mine: ->
    console.log 'GOT INSIDE'
    user-id = My.user-id!
    each (.destroy!), Offer.mine!fetch!
    # Offers.remove ownerId: user-id
