#
# * GET home page.
# 
exports.index = (req, res) ->
	res.render "index",
		title: "Neo4j Coffee-Script Template"
