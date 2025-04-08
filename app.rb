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
    db = SQLite3::Database.new("db/horoskop.db")
    db.results_as_hash = true
    @posts = db.execute("SELECT * FROM posts")
    db.close
    slim :forum
end

get('/new') do
    if session[:id].nil?
        redirect('/login')
    else
        slim :new
    end
end

post('/posts/new') do
    if session[:id].nil?
        redirect('/login')
    else
        db = SQLite3::Database.new("db/horoskop.db")
        db.results_as_hash = true
        db.execute('INSERT INTO posts (creator, title, content) VALUES (?, ?, ?)', [params[:creator], params[:title], params[:content]])
        redirect ('/forum')
    end
end

get('/delete') do
    slim :delete
end

post('/posts/delete') do
    username = params[:username]
    password = params[:password]
    post_id = params[:post_id]

    db = SQLite3::Database.new('db/horoskop.db')
    db.results_as_hash = true

    result = db.execute("SELECT * FROM users WHERE username = ?",[username]).first

    if result.nil? 
        return "Vänligen fyll i alla uppgifter"
    end

    pwdigest = result["pwdigest"]

    if BCrypt::Password.new(pwdigest) == password
        post = db.execute("SELECT * FROM posts WHERE post_id = ?", [post_id]).first
        if post.nil?
            halt 404, "Inlägget finns inte"
        elsif post["creator"] != username
            halt 403, "Du har inte tillåtelse att radera detta inlägg"
        else
            db.execute("DELETE FROM posts WHERE post_id = ?", [post_id])
            redirect('/forum')
        end
    else
        halt 401, "Felaktigt lösenord"
    end
end

post('/forum') do
    if session[:id].nil?
        redirect('/login')
    else
        slim :forum
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
        return "Vänligen fyll i alla uppgifter"
    end

    pwdigest = result["pwdigest"]
    id = result["user_id"]

    if BCrypt::Password.new(pwdigest) == password
        session[:id] = id
        session[:username] = username
        session[:logged_in] = true
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