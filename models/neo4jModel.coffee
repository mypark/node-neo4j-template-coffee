neo4j = require("neo4j")
db = new neo4j.GraphDatabase(process.env.NEO4J_URL or "http://localhost:7474")

###*
 * Neo4jModel class - base class for neo4j Models
 * 
 * 'Neo4jModel' constrcuted with an instance of a neo 4j node
 * and a property definition function that node data to be 
 * defined as properties
 * 
 * @constructor
 * @param {Object} _node - initial neo4j 'Node'
 ###

class Neo4jModel

	constructor : (@_node) ->
		@nodeType = @constructor.name

	validate : () ->
		check = require('validator').check
		check(@_node).notNull()

	save : (callback) ->
		try
			@validate()
			@_node.save (err) ->
				callback err
		catch e
			return callback e

	remove: (callback) ->
		@_node.del ((err) ->
			callback err
		), true

	# pass-through node properties:
	@property = (propertyName, isBuiltInNeo4jProperty) ->
		Object.defineProperty @::, propertyName,
			get: ->
				if isBuiltInNeo4jProperty
					@_node[propertyName]
				else
					@_node.data[propertyName]
					
			set: (value) ->
				if isBuiltInNeo4jProperty
					@_node[propertyName] = value
				else
					@_node.data[propertyName] = value
		
	@property "id", true
	@property "exists", true
	@property "nodeType"

	toJson : () ->

		result = @_node._data.data
		result.id = @id
		return result


	@deleteRelationship : (relId, callback) ->
		db.getRelationshipById relId, (getErr, rel) ->
			if getErr
				callback getErr
			else
				rel.del callback


	relationshipExists : (to, direction, type, cb) ->
		from = @id
	
		relationship = ""
		switch direction 
			when "outgoing"
				relationship = "-[r:#{type}]->"
			when "incoming"
				relationship = "<-[r:#{type}]-"
			else
				relationship = "-[r:#{type}]-"

		query = "START a=node({from}), b=node({to})
			MATCH (a) #{ relationship } (b)
			RETURN ID(r) as id"
		
		params = 
			from : from
			to: to

		db.query query, params, (err, results) ->

			if results and results.length is 0
				return cb err, false
			else if results
				return cb err, results[0].id
			else
				return cb err, null


	# only create relationship if it is not exists
	ensureRelationshipTo : (toId, direction, type, data, cb) ->

		unless typeof(toId) is "number"
			toId = parseInt toId

		db.getNodeById toId, (err, toNode) =>
			
			return cb(err)  if err and cb

			@relationshipExists toId, direction, type, (err2, rel) =>
				return cb(err2)  if err2 and cb
				
				if not rel
					
					if direction is "incoming"
						@_node.createRelationshipFrom toNode, type, data, cb
					else
						@_node.createRelationshipTo toNode, type, data, cb

				else if rel.data and not _.isEqual(data, rel.data)
					rel.data = data
					rel.save cb
				else
					cb(null)
				



module.exports = Neo4jModel