require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'

get('/') do
    slim :home
end

get('/forum') do
    slim :forum
end

get('/profil') do
    db = SQLite3::Database.new("db/horoskop.db")
    db.results_as_hash = true
    @result = db.execute("SELECT * FROM users")
    slim(:users)
end
