require 'sinatra'
require 'data_mapper'
require 'haml'

DataMapper::setup(:default,"sqlite3://#{Dir.pwd}/score.db")

class Story
  include DataMapper::Resource
  property :id, Serial
  property :title, String
  property :url, Text
  property :score, Integer
  property :points, Integer, default: 0
  property :created_at, Time

  attr_accessor :score

  def epoch
    Time.local(2009, 11, 8, 7, 46, 43).to_time
  end

  def epoch_seconds(t)
    (t.to_i - epoch.to_i).to_f
  end

  def hot(points, date)
    displacement = Math.log( [points.abs, 1].max,  10 )

    sign = if points > 0
      1
    elsif points < 0
      -1
    else
      0
    end

    return (displacement * sign.to_f) + ( epoch_seconds(date) / 45000 )
  end

  def calculate_score
    self.score = hot(self.points, Time.now)
  end

  def self.all_sorted_desc
    self.all.each { |item| item.calculate_score }.sort { |a,b| a.score <=> b.score }.reverse
  end
end

DataMapper.finalize.auto_upgrade!

get '/' do
  @links = Story.all :order => :id.desc
  haml :index
end

get '/hot' do
  @links = Story.all_sorted_desc
  haml :index
end

post '/' do
  l = Story.new
  l.title = params[:title]
  l.url = params[:url]
  l.created_at = Time.now
  l.save
  redirect back
end

put '/:id/vote/:type' do
  l = Story.get params[:id]
  point = params[:type].to_i
  next if point > 1 || point < -1
  l.points += point
  l.save
  redirect back
end
