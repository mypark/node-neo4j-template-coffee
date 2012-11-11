
###
Module dependencies.
###
express = require("express")
routes = require("./routes")
users = require './routes/users'
http = require("http")
path = require("path")
app = express()

app.configure ->
  app.set "port", process.env.PORT or 3000
  app.set "views", __dirname + "/views"
  app.set "view engine", "jade"
  app.use express.favicon()
  app.use express.logger("dev")
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use app.router
  app.use express.static(path.join(__dirname, "public"))

app.configure "development", ->
  app.use express.errorHandler()

app.get "/", routes.index
app.get "/users", users.list

app.post "/users", users.create
app.get "/users/:id", users.show
app.post "/users/:id", users.edit
app.del "/users/:id", users.del
app.post "/users/:id/follow", users.follow
app.post "/users/:id/unfollow", users.unfollow


http.createServer(app).listen app.get("port"), ->
  console.log "Express server listening on port " + app.get("port")