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

    info = db.execute("Select Blog_Id, Title from Blogs WHERE User_Id = ?", session[:account]["User_Id"][0]["User_Id"])
    if info != []
        info = info[0]
        session[:account]["Blog_Id"] = info["Blog_Id"]
        data = db.execute("SELECT Title, Text, Post_Id FROM Posts Where Blog_Id == ?", session[:account]["Blog_Id"])
        info["Data"] = data
    end

    slim(:bloghome, locals:{info:info})
end

get('/blogmake') do
    slim(:blogmake)
end

post('/newblog') do
    db = SQLite3::Database.new('db/blogg.db')
    db.results_as_hash = true

    title = params["Title"]
    db.execute("INSERT INTO Blogs(Title, User_Id) VALUES(?, ?)", title, session[:account]["User_Id"][0]["User_Id"])

    redirect('/bloghome')
end

get('/makepost') do
    slim(:post)
end

post('/post') do
    db = SQLite3::Database.new('db/blogg.db')
    db.results_as_hash = true

    title = params["Title"]
    text = params["Text"]
    db.execute("INSERT INTO Posts(Title, Text, Blog_Id) VALUES(?, ?, ?)", title, text, session[:account]["Blog_Id"])

    redirect('/bloghome')
end

get('/editpost/:id') do
    id = params["id"]
    slim(:edit, locals:{post_id:id})
end

post('/edit') do
    db = SQLite3::Database.new('db/blogg.db')
    db.results_as_hash = true

    title = params["Title"]
    text = params["Text"]
    post_id = params["Post_Id"]

    db.execute("UPDATE Posts SET Title=?, Text=? WHERE Post_Id=?", title, text, post_id)

    redirect('/bloghome')
end

post('/delete') do
    db = SQLite3::Database.new('db/blogg.db')
    db.results_as_hash = true

    id = params["Post_Id"]

    db.execute("DELETE FROM Posts where Post_Id == ?", id)

    redirect('/bloghome')
end

get('/viewall') do
    db = SQLite3::Database.new('db/blogg.db')
    db.results_as_hash = true

    posts = db.execute("SELECT Posts.Title, Posts.Text, Blogs.Title FROM Posts INNER JOIN Blogs ON Blogs.Blog_Id = Posts.Blog_Id")

    slim(:viewall, locals:{posts:posts})
end