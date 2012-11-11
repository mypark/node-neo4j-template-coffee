# users.js
# Routes to CRUD users.
User = require("../models/user")

# GET /users
exports.list = (req, res, next) ->
	User.getAll (err, users) ->
		return next(err)  if err
		res.render "users",
			users: users




# POST /users
exports.create = (req, res, next) ->
	User.create
		name: req.body["name"]
	, (err, user) ->
		return next(err)  if err
		res.redirect "/users/" + user.id



# GET /users/:id
exports.show = (req, res, next) ->
	User.get req.params.id, (err, user) ->
		return next(err) if err

		# TODO also fetch and show followers?
		user.getFollowingAndOthers (err, following, others) ->
			return next(err)  if err

			res.render "user",
				user: user
				following: following
				others: others

# POST /users/:id
exports.edit = (req, res, next) ->
	User.get req.params.id, (err, user) ->
		return next(err)  if err
		user.name = req.body["name"]
		user.save (err) ->
			return next(err)  if err
			res.redirect "/users/" + user.id




# DELETE /users/:id
exports.del = (req, res, next) ->
	User.get req.params.id, (err, user) ->
		return next(err)  if err
		user.del (err) ->
			return next(err)  if err
			res.redirect "/users"




# POST /users/:id/follow
exports.follow = (req, res, next) ->
	User.get req.params.id, (err, user) ->
		return next(err)  if err
		User.get req.body.user.id, (err, other) ->
			return next(err)  if err

			user.follow other.id, (err) ->
				return next(err)  if err
				res.redirect "/users/" + user.id





# POST /users/:id/unfollow
exports.unfollow = (req, res, next) ->
	User.get req.params.id, (err, user) ->
		return next(err)  if err
		User.get req.body.user.id, (err, other) ->
			return next(err)  if err
			user.unfollow req.body.relId, (err) ->
				return next(err)  if err
				res.redirect "/users/" + user.id
