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

get('/profile') do
    db = SQLite3::Database.new("db/horoskop.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM users")
    slim(:profile, locals:{users:result})
end

get('/register') do
    slim :register
end

post('/users/new') do
    username = params[:username]
    password = params[:password]
    password_confirm = params[:password_confirm]

    if password == password_confirm
        password_digest = BCrypt::Password.create(password)
        db = SQLite3::Database.new("db/horoskop.db")
        db.execute("INSERT INTO users (username,pwdigest) VALUES (?,?)",[username,password_digest])
        redirect('/')
    else
        "Lösenorden matchar inte"
    end
end

get('/login') do
    slim(:login)
end

post('/login') do
    username = params[:username]
    password = params[:password]
    db = SQLite3::Database.new('db/horoskop.db')
    db.results_as_hash = true
    result = db.execute("SELECT * FROM users WHERE username = ?",[username]).first
    pwdigest = result["pwdigest"]
    id = result["id"]
    id = result["id"]
  if BCrypt::Password.new(pwdigest) == password
    session[:id] = id
    redirect('/')
  else
    "Fel lösenord"
  end
end