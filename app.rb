require "sinatra"
require "slim"
require "sqlite3"
require "bcrypt"

enable :sessions

get('/') do
    if session[:account] == nil
        session[:account] = {}
    end
    slim(:index)
end

post('/login') do
    db = SQLite3::Database.new('db/blogg.db')
    db.results_as_hash = true

    username = params["Username"]
    password = params["Password"]
   
    username_db = db.execute("SELECT Username from Users WHERE Username = (?)", username)
    password_db = db.execute("SELECT Password from Users WHERE Username = (?)", username)
    if username_db[0] != nil && password_db[0] != nil
        username_db = username_db[0][0]
        password_db = password_db[0][0]
    else
        session[:account]["logged_in"] = false
        redirect("/")
    end    
    if username_db == username
        if BCrypt::Password.new(password_db) == password
            session[:account]["logged_in"] = true
            session[:account]["Username"] = username
            session[:account]["User_Id"] = db.execute("Select User_Id from Users WHERE Username = ?", username)
            redirect("/granted")
        end
    end
    session[:account]["logged_in"] = false
    redirect("/")
end

get('/granted') do
    if session[:account]["logged_in"]
        slim(:granted)
    else
        redirect('/denied')
    end
end

get('/denied') do
    slim(:denied)
end

get('/register') do
    slim(:register)
end

post('/newuser') do
    db = SQLite3::Database.new('db/blogg.db')
    db.results_as_hash = true

    secret_password = BCrypt::Password.create(params["Password"])
    username = params["Username"]
    email = params["Email"]

    db.execute("INSERT INTO Users(Username, Password, Email) VALUES(?, ?, ?)", username, secret_password, email)

    redirect('/')
end

post('/log_out') do
    session[:account] = nil
    redirect('/')
end

get('/bloghome') do
    db = SQLite3::Database.new('db/blogg.db')
    db.results_as_hash = true

    info = db.execute("Select Blog_Id, Title from Blogs WHERE User_Id = ?", session[:account]["User_Id"])

    slim(:bloghome, locals:{blog:info})
end