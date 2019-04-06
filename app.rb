require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/cookies'
require "mysql2"
require "mysql2-cs-bind"
require "pry"

enable :sessions

$client = Mysql2::Client.new(
  :host => '127.0.0.1',
  :username => 'root',
  :password => 'root',
  :database => 'minstagram'
)

def isLoggedIn
  redirect '/login' unless session[:user_id]
end

def myinfo
  @myinfo = $client.xquery(
    'select * from users
     where id = ?', session[:user_id]
  ).to_a.first
end

get '/test' do
  erb :test
end

get '/' do
 if session[:user_id]
   redirect '/feed'
 else
   redirect '/login'
 end
end

get '/login' do
  erb :login, :layout => :shards
end

post '/login' do
  res = $client.xquery(
    'select * from users
     where name = ? && password = ?',
    params[:lname], params[:lpass]
  ).first

  if res
    session[:user_id] = res['id']
    session[:user_name] = res['name']
    redirect '/feed'
  else
    session[:user_id] = nil
    session[:user_name] = params[:lname]
    session[:error_msg] = 'ユーザ名またはパスワードが違います'
    redirect '/'
  end
end

get '/signup' do
  erb :signup, :layout => :shards
end

post '/signup' do
  cookies[:signup_name] = params[:signup_name]
  name = params[:signup_name]
  email = params[:signup_email]
  password = params[:signup_pass]

  @results = $client.xquery(
    'insert into users (name, email, password)
    values(?, ?, ?)', name, email, password
  )
  redirect '/'
end

get '/logout' do
  session[:user_id] = nil
  session[:error_msg] = nil
  redirect '/'
end

get '/feed' do
  isLoggedIn
  @posts = $client.xquery(
    'select distinct p.id, p.user_id, p.image_path, p.comment, u.name, p.created_at from posts p
    left outer join follows f
    on p.user_id = f.following_id
    left outer join users u
    on p.user_id = u.id
    where p.user_id in (
      select follower_id from follows where following_id = ?)
      order by created_at desc',
    session[:user_id])

  erb :feed
end

get '/all_posts' do
  isLoggedIn
  @posts = $client.xquery(
    'select p.id as post_id, p.user_id, p.image_path, p.comment, u.name from posts p
    left outer join users u
    on p.user_id = u.id'
  )

  erb :all_posts
end

get '/profile/:user_id?' do
  isLoggedIn

  @myinfo = myinfo
  # myinfoTemp = myinfo

  user = $client.xquery(
    'select * from users
     where id = ?', params[:user_id]
  ).to_a.first
  @user = user

  follows = $client.xquery(
    'select * from follows
     where following_id = ?', session[:user_id]
  )

  # フォローしているかの判定
  followFlg = false

  follows.each do  |follow|
    if follow['follower_id'] ==  user['id']
      followFlg = true
    end
  end
  @followFlg = followFlg

  @posts = $client.xquery(
    'select * from posts
    where user_id = ?', params[:user_id]
  )

  erb :profile
end

get '/edit_profile' do
  @myinfo = myinfo
  erb :edit_profile
end

post '/edit_profile' do
  isLoggedIn
  @myinfo = myinfo

  new_profile_img = ''
  new_profile = params[:new_profile]
  new_profile ||= ''

  if params[:new_profile_img]
    new_profile_img = params[:new_profile_img]
    FileUtils.mv(params[:new_profile_img][:tempfile], "./public/images/profile/#{params[:new_profile_img][:filename]}")
  end

  if params[:new_profile_img] && params[:new_profile] != ''
    $client.xquery(
      'update users
       set profile = ?, profile_photo = ?
       where id = ?',
       new_profile, params[:new_profile_img][:filename], session[:user_id]
    )
  elsif params[:new_profile_img] && params[:new_profile] == ''
    $client.xquery(
      'update users
      set profile_photo = ?
      where id = ?',
      new_profile_photo, session[:user_id]
    )
  else
    $client.xquery(
      'update users
      set profile = ?
      where id = ?',
      new_profile, session[:user_id]
    )
  end

  redirect "/profile/#{session[:user_id]}"
end

get '/post/create' do
  isLoggedIn
  erb :create
end

post '/post/insert' do
  FileUtils.mv(params[:image][:tempfile], "./public/images/#{params[:image][:filename]}")
  comment = params[:comment]
  image_path = params[:image][:filename]

  @results = $client.xquery(
    'insert into posts (user_id, image_path, comment)
    values (?, ?, ?)' , session[:user_id], image_path, comment)

  redirect '/all_posts'
end

get '/post/update/:id' do
  isLoggedIn
  @results = $client.xquery(
    'select * from posts
     where id = ?', params[:id].to_i).first
     # erb内の name="key" => params[:key]に入る
    erb :update
end

post '/post/update' do
  isLoggedIn
  comment = params[:comment]
  id = params[:id]

  @results = $client.xquery(
    'update posts
     set comment = ?
     where id = ?', comment, id)

   redirect "/profile/#{session[:user_id]}"
end

get '/post/delete/:id' do
  id = params['id']

  $client.xquery(
    'delete from posts
     where id = ?', id)

  redirect '/'
end

get '/follow/:user_id' do
  isLoggedIn
  $client.xquery(
    'insert into follows values(null, ?, ?)',
    session[:user_id], params[:user_id]
  )
  redirect "/profile/#{params[:user_id]}"
end

get '/unfollow/:user_id' do
  isLoggedIn
  $client.xquery(
    'delete from follows where following_id = ? && follower_id = ?',
    session[:user_id], params[:user_id]
  )
  redirect "/profile/#{params[:user_id]}"
end

get '/following_list' do
  isLoggedIn
  @res = $client.xquery(
    'select distinct f.follower_id, u.id, u.name, u.profile_photo, u.profile
    from follows f
    left outer join users u
    on f.follower_id = u.id
    where f.following_id = ?',
    session[:user_id]
  )

  erb :following_list
end

get '/follower_list' do
  isLoggedIn
  @res = $client.xquery(
    'select distinct f.following_id, u.id, u.name, u.profile_photo, u.profile
    from follows f
    left outer join users u
    on f.following_id = u.id
    where f.follower_id = ?',
    session[:user_id]
  )

  erb :follower_list
end


get '/like/:post_id' do
  isLoggedIn
  $client.xquery(
    'insert into likes values (null, ?, ?)',
     session[:user_id], params[:post_id]
  )

  redirect '/all_posts'
end

get '/dislike/:post_id' do
  $client.xquery(
    'delete from likes values(null, ?, ?)',
    session[:user_id], params[:post_id]
  )

  redirect 'all_posts'
end
