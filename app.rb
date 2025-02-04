require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'

enable :sessions

get('/') do
    slim :home
end

get('/forum') do
    slim :forum
end

get('/users/profile') do
    db = SQLite3::Database.new("db/horoskop.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM users")
    p result
    slim(:users, locals:{users: result})
end