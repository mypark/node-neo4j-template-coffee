###
Module dependencies
###
neo4j = require 'neo4j'
db = new neo4j.GraphDatabase(process.env.NEO4J_URL or "http://localhost:7474")
async = require 'async'
Neo4jModel = require './neo4jModel'

INDEX_NAME = "User"
INDEX_KEY = "name"

class User extends Neo4jModel

	@property "name"

	constructor : (_node) ->
		super _node

	validate : () ->

		check = require('validator').check
		check(@name).notNull()

	@getByName = (name, callback) ->
		query = [
			"START user=node:User(name={name})", 
			"RETURN user"
		].join("\n")

		params = name: name.toLowerCase()

		db.query query, params, (err, results) ->

			callback err, null if err

			if results and results.length > 0
				callback null, new User(results[0].user)
			else
				callback err, null
	

	@get = (id, callback) ->
		
		if not typeof(id) is "number"
			id = parseInt(id)

		db.getNodeById id, (err, node) ->
			return callback(err)  if err
			callback null, new User(node)

	@getAll = (callback) =>
	
		query = "start user=node:#{INDEX_NAME}(\"#{INDEX_KEY}:*\") 
			RETURN user" #ID(users) as id, users.name as name"

		db.query query, null, (err, results) ->
			return callback(err)  if err

			users = results.map((result) ->
				new User(result.user)
			)

			callback err, users
			
			

		###
		db.getIndexedNodes 'User', INDEX_KEY, '', (err, nodes) ->
	
			# if (err) return callback(err);
			# XXX FIXME the index might not exist in the beginning, so special-case
			# this error detection. warning: this is super brittle!!
			return callback(err, [])  if err
			users = nodes.map((node) ->
			  new User(node)
			)
			callback null, users
	   	###




	@create = (data, callback) ->

		node = db.createNode(data)
		user = new User(node)

		async.series

			existingUser:(callback) ->
				
				User.getByName data.name, (err, results) ->
					if results
						callback new restify.ConflictError("User with that name already exists");
					else
						callback err
			
			createUser:(callback) ->
				node.save callback

			indexUser: (callback) ->
				node.index INDEX_NAME, INDEX_KEY, data.name.toLowerCase(), (err) ->
					callback err, user
		
		,(err, results) ->
			return callback err if err
			return callback new Error("Saving user did not return a user") if not results.createUser
			console.log 'user created ' + results.createUser
			return callback err, new User(results.createUser)


	follow: (otherId, callback) ->

		@ensureRelationshipTo otherId, 'outgoing', 'follow', {}, callback


	unfollow: (id, callback) ->

		db.getRelationshipById id, (getErr, rel) ->
			if getErr
				callback getErr
			else
				rel.del callback

	getFollowingAndOthers: (callback) ->
		# query all users and whether we follow each one or not:
		# COUNT(rel) is a hack for 1 or 0
		query = "START user=node({userId}), other=node:#{INDEX_NAME}(\"#{INDEX_KEY}:*\") MATCH (user) -[rel:follow]-> (other) RETURN ID(rel) as relId, other, COUNT(rel)"

		params = userId: @id


		db.query query, params, (err, results) =>
			return callback(err)  if err
			following = []
			others = []
			i = 0

			#while i < results.length
			for i in [0..results.length-1] by 1

				other = 
					user : new User(results[i]["other"])
					relId : results[i]["relId"]
				follows = results[i]["COUNT(rel)"]

				if @id is other.id
					continue
				else if follows
					following.push other
				else
					others.push other

			callback null, following, others



module.exports = User




