require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'

get ('/') do
    slim :home
end

get ('/forum') do
    slim :forum
end

get ('/profil') do
    slim :profile
    db = SQLite3::Database.new("db/horoskop.db")
    result = db.execute("SELECT * FROM users")
    slim(:users, locals:{users: result})
end
