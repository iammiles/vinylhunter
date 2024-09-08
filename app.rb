require 'sinatra'
require 'erb'
require 'sequel'

class Settings
  attr_accessor :starts_with, :show_owned
end

DB = Sequel.connect('sqlite://db/app.db')
class Stream < Sequel::Model
  set_primary_key [:id]

  dataset_module do
    def all_artists_by_letter(letter)
      where(Sequel.like(:artist, "#{letter}%") | Sequel.like(:artist, "The #{letter}%")).
      where(is_owned: false).
      order(Sequel.desc(:artist)).
      all
    end
  end
end


before do
  puts "auth?"
end

get '/' do
  streams = Stream.where(is_owned: false)
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
  filtered_streams = Stream.all_artists_by_letter(params['letter'])
  erb :results, :locals => { streams: filtered_streams }
end

not_found do
  'Four oh four!'
end
