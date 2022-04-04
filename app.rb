# frozen_string_literal: true

require 'sinatra'
require 'sinatra/cookies'
require 'rbnacl'
require 'sqlite3'
require 'pry'
require_relative 'models/users'
require_relative 'models/sessions'

DB = SQLite3::Database.new 'db/db.sqlite3'
UserStore = Users::Store.new(DB)
SessionStore = Sessions::Store.new(DB)

before do
  if !SessionStore.valid? cookies[:session]
    cookies.delete :session
  else
    user_id = SessionStore.user_id_for_session(cookies[:session])
    @user = UserStore.fetch_by_id(user_id)
  end
end

helpers do
  def login(user)
    session = SessionStore.create(user)
    cookies[:session] = session
  end
end

get '/' do
  erb :index
end

get '/join' do
  erb :join
end

post '/join' do
  username, password, verify = params.to_h.fetch_values('username', 'password', 'verify')
  email = params[:email]
  begin
    DB.transaction
    user = UserStore.create(username, email: email)
    UserStore.set_password!(user, password, verify)
    DB.commit
  rescue StandardError => e
    DB.rollback
    logger.error e
    error = if e.is_a? SQLite3::ConstraintException
              "\"#{username}\" already exists"
            else
              e.to_s
            end
    status 400
    erb(:join, locals: { error: error })
  else
    login(user)
    redirect to('/')
  end
end

get '/login/?' do
  erb :login
end

post '/login/?' do
  user = UserStore.fetch_by_name(params[:name])
  return erb(:login, locals: { error: "no such user #{params[:name]}" }) unless user

  unless UserStore.password_valid?(user, params[:password])
    return erb(:login, locals: {
                 error: 'wrong password',
                 name: params[:name]
               })
  end
  login(user)
  redirect to('/')
end

post '/logout/?' do
  session = cookies[:session]
  SessionStore.invalidate!(session)
  cookies.delete(:session)
  redirect to('/')
end
