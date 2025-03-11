require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'

enable :sessions

get('/') do
    if session[:id]
        slim :logged_in
    else
        slim :home
    end
end

get('/forum') do
    slim :forum
end

post('/forum') do
    if session[:id].nil?
        redirect('/login')
    else
        
    end
end

get('/profile') do
    if session[:id].nil?
        redirect('/login')
    else        
        db = SQLite3::Database.new("db/horoskop.db")
        db.results_as_hash = true
        user = db.execute("SELECT * FROM users WHERE user_id = ?", [session[:id].to_i]).first
        db.close
        if user.nil?
            redirect('/login')
        else
            slim :profile, locals: {user: user}
        end
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
        db.close
        redirect('/')
    else
        "Lösenorden matchar inte"
    end
end

get('/login') do
    if session[:id]
        redirect('/')
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
    db.close
    
    if result.nil? 
        return "Fel användarnamn eller lösenord"
    end

    pwdigest = result["pwdigest"]
    id = result["id"]

    if BCrypt::Password.new(pwdigest).is_password?(password)
        session[:id] = id
        p session.inspect
        session[:username] = username
        redirect('/logged_in')
    else
        "Fel användarnamn eller lösenord"
    end
end

get('/logout') do
    session.clear
    redirect('/')
end

get('/logged_in') do
    slim :logged_in
end