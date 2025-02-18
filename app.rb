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
    if session[:id].nil?
        redirect('/login')
    else
        db = SQLite3::Database.new("db/horoskop.db")
        db.results_as_hash = true
        result = db.execute("SELECT * FROM users")
        slim(:profile, locals:{users:result})
    end
end

get('/register') do
    if session[:id]
        redirect('/')
    else
        slim :register
    end
end

post('/users/new') do
    username = params[:username]
    password = params[:password]
    name = params[:name]
    password_confirm = params[:password_confirm]

    if password == password_confirm
        password_digest = BCrypt::Password.create(password)
        db = SQLite3::Database.new("db/horoskop.db")
        db.execute("INSERT INTO users (name,username,pwdigest) VALUES (?,?,?)",[name,username,password_digest])
        redirect('/')
    else
        "Lösenorden matchar inte"
    end
end

get('/login') do
    if session[:id]
        redirect('/profile')
    else
        slim :login
    end
end

post('/login') do
    username = params[:username]
    password = params[:password]
    db = SQLite3::Database.new('db/horoskop.db')
    db.results_as_hash = true
    result = db.execute("SELECT * FROM users WHERE username = ?",[username]).first
    
    if result.nil? 
        return "Fel användarnamn eller lösenord"
    end

    pwdigest = result["pwdigest"]
    id = result["id"]

    if BCrypt::Password.new(pwdigest).is_password?(password)
        session[:id] = id
        session[:username] = username
        redirect('/')
    else
        "Fel användarnamn eller lösenord"
    end
end

get('/logout') do
    session.clear
    redirect('/')
end