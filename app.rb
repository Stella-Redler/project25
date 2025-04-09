# Laddar in nödvändiga bibliotek
require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader' # Automatisk omladdning under utveckling
require 'bcrypt' # Kryptering av lösenord

# Aktiverar sessions för att hålla användare inloggade
enable :sessions

# Startsidan: visar antingen hem för utloggade eller hem för inloggade beroende på session
get('/') do
    if session[:id]
        slim :logged_in
    else
        slim :home
    end
end

# Visar alla foruminlägg
get('/forum') do
    db = SQLite3::Database.new("db/horoskop.db")
    db.results_as_hash = true
    @posts = db.execute("SELECT * FROM posts")
    db.close
    slim :forum
end

# Sida för att skapa nytt inlägg – endast för inloggade
get('/new') do
    if session[:id].nil?
        redirect('/login') # Om inte inloggad, skicka till login
    else
        slim :new
    end
end

# Tar emot och sparar ett nytt inlägg i databasen
post('/posts/new') do
    if session[:id].nil?
        redirect('/login')
    else
        db = SQLite3::Database.new("db/horoskop.db")
        db.results_as_hash = true
        db.execute('INSERT INTO posts (creator, title, content) VALUES (?, ?, ?)', [params[:creator], params[:title], params[:content]]) # Skapar ett nytt inlägg med data från formuläret
        redirect ('/forum')
    end
end

# Sida för att radera inlägg – bara för inloggade
get('/posts/delete/:id') do
    if session[:id].nil?
        redirect('/login')
    else
        @post_id=params[:id]
        slim :delete
    end
end

# Logik för att radera ett inlägg
post('/posts/delete') do
    username = params[:username]
    password = params[:password]
    post_id = params[:post_id]

    db = SQLite3::Database.new('db/horoskop.db')
    db.results_as_hash = true

    # Hämtar användarens lösenordshash från databasen
    result = db.execute("SELECT * FROM users WHERE username = ?",[username]).first

    if result.nil? 
        return "Vänligen fyll i alla uppgifter"
    end

    pwdigest = result["pwdigest"]

    # Jämför inskrivet lösenord med det hashade lösenordet
    if BCrypt::Password.new(pwdigest) == password
        # Hämtar inlägget som ska raderas
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

get('/posts/:id/edit') do
    if session[:id].nil?
        redirect('/login')
    else
        db = SQLite3::Database.new("db/horoskop.db")
        db.results_as_hash = true
        post = db.execute("SELECT * FROM posts WHERE post_id = ?", [params[:id]]).first
        db.close

        if post.nil?
            halt 404, "Inlägget hittades inte"
        elsif post["creator"] != session[:username]
            halt 403, "Du får inte redigera detta inlägg"
        else
            slim :edit, locals: { post: post }
        end
    end
end

post('/posts/:id/edit') do
    if session[:id].nil?
        redirect('/login')
    end
    
    title = params[:title]
    content = params[:content]
    post_id = params[:id]
    
    db = SQLite3::Database.new("db/horoskop.db")
    db.results_as_hash = true
    post = db.execute("SELECT * FROM posts WHERE post_id = ?", [post_id]).first
    
    if post.nil?
        halt 404, "Inlägget finns inte"
    elsif post["creator"] != session[:username]
        halt 403, "Du får inte redigera detta inlägg"
    else
        db.execute("UPDATE posts SET title = ?, content = ? WHERE post_id = ?", [title, content, post_id])
        db.close
        redirect('/forum')
    end
end

# Användarprofil – visar information om inloggad användare
get('/profile') do
    if session[:id].nil?
        redirect('/login')
    else        
        db = SQLite3::Database.new("db/horoskop.db")
        db.results_as_hash = true
        user = db.execute("SELECT * FROM users WHERE user_id = ?", [session[:id].to_i]).first # Hämtar användardata baserat på session[:id]
        db.close
        if user.nil?
            redirect('/login')
        else
            slim :profile, locals: {user: user}
        end
    end
end

# Visar registreringssidan (om inte redan inloggad)
get('/register') do
    if session[:id]
        redirect('/')
    else
        slim :register
    end
end

# Skapar en ny användare
post('/users/new') do
    username = params[:username]
    password = params[:password]
    name = params[:name]
    password_confirm = params[:password_confirm]

    # Kontrollerar att lösenorden matchar
    if password == password_confirm
        password_digest = BCrypt::Password.create(password) # Hashar lösenordet
        db = SQLite3::Database.new("db/horoskop.db")
        db.execute("INSERT INTO users (name,username,pwdigest) VALUES (?,?,?)",[name,username,password_digest]) # Lägger till ny användare
        db.close
        redirect('/')
    else
        "Lösenorden matchar inte"
    end
end

# Visar login-sidan (om inte redan inloggad)
get('/login') do
    if session[:id]
        redirect('/')
    else
        slim :login
    end
end

# Hanterar inloggning
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
    name = result["name"]

    # Jämför lösenordet med den hash som finns lagrad
    if BCrypt::Password.new(pwdigest) == password
        # Sparar information i session
        session[:id] = id
        session[:username] = username
        session[:name] = name
        session[:logged_in] = true
        redirect('/logged_in')
    else
        "Fel användarnamn eller lösenord"
    end
end

# Loggar ut användaren och tömmer sessionen
get('/logout') do
    session.clear
    redirect('/')
end

# Vy för inloggade användare
get('/logged_in') do
    slim :logged_in
end