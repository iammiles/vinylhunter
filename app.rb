require 'dotenv/load'
require 'sinatra'
require 'erb'
require 'sequel'
require 'spotify'

@accounts = Spotify::Accounts.new
@accounts.client_id = ENV['SPOTIFY_CLIENT_ID']
@accounts.client_secret = ENV['SPOTIFY_CLIENT_SECRET']
@accounts.redirect_uri = ENV['SPOTIFY_REDIRECT_URI']

enable :sessions
set :session_store, Rack::Session::Pool

DB = Sequel.connect('sqlite://db/app.db')
class Stream < Sequel::Model
  set_primary_key [:id]

  dataset_module do
    def all_artists_by_letter(letter)
      where(Sequel.like(:artist, "#{letter}%") | Sequel.like(:artist, "The #{letter}%")).
      where(is_owned: false).
      order(Sequel.desc(:listens)).
      all
    end
  end
end


get '/' do
  streams = Stream.where(is_owned: false).order(Sequel.desc(:listens))
  if session['letter'].nil?
    streams = streams.all_artists_by_letter(session['letter'])
  end
  erb :index, :locals => { streams: streams }
end

post '/toggle-owned/:id' do
  stream = Stream[params['id'].to_i]
  unless stream.nil?
    stream.update(is_owned: !stream[:is_owned])
    erb :stream, :locals => { stream: stream }
  end
end

post '/filter-by-letter/:letter' do
  if params['letter'] == 'All'
    session['letter'] = nil
  else session['letter'] = params['letter']
  end
  filtered_streams = Stream.all_artists_by_letter(session['letter'])
  erb :results, :locals => { streams: filtered_streams }
end

delete '/:id' do
  Stream[params['id'].to_i].delete
  redirect '/'
end

not_found do
  'Four oh four!'
end
