require "sinatra"
require "slim"
require "sqlite3"
require "bcrypt"

enable :sessions

get('/') do
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
        redirect("/denied")
    end    
    if username_db == username
        if BCrypt::Password.new(password_db) == password
            session["logged_in"] = true
            redirect("/granted")
        end
    end
    redirect("/denied")
end

get('/granted') do
    if session["logged_in"] == true
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
    session.destroy
    redirect('/')
end