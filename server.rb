require 'pry'
require 'sinatra'
require 'pg'

def db_connection
  begin
    connection = PG.connect(dbname: "movies")
    yield(connection)
  ensure
    connection.close
  end
end

class Actor
  attr_accessor :id, :name
  def initialize(id,name)
    @id = id
    @name = name
  end

  def self.all
    actors = nil
    db_connection do |conn|
      sql_query="SELECT*FROM actors ORDER BY name"
      actors = conn.exec(sql_query)
    end
    actors.map{ |actor| Actor.new(actor["id"], actor["name"]) }
  end

  def self.find(id)
    actor = nil
    db_connection do |conn|
      sql_query = "SELECT * FROM actors WHERE id = $1"
      data = [id]
      actor = conn.exec(sql_query, data).first
    end
    Actor.new(actor["id"], actor["name"])
  end

  def details
    details = nil
    db_connection do |conn|
      sql_query="SELECT cast_members.character, movies.title, movies.id
      FROM actors
      JOIN cast_members ON actors.id=cast_members.actor_id
      JOIN movies ON cast_members.movie_id=movies.id
      WHERE actors.id=$1"
      data = [id]
      details = conn.exec(sql_query, data)
    end
    details.map { |detail| ActorDetail.new(detail["character"], detail["title"], detail["id"])}
  end
end

class Movie
  attr_accessor :id, :title, :year, :rating, :genre, :studio
  def initialize(id,title,year,rating,genre,studio)
    @id = id
    @title = title
    @year = year
    @rating = rating
    @genre = genre
    @studio = studio
  end

  def self.all
    movies = nil
    db_connection do |conn|
      sql_query="SELECT movies.*, genres.name AS genre, studios.name AS studio
      FROM movies
      LEFT OUTER JOIN genres ON movies.genre_id=genres.id
      LEFT OUTER JOIN studios ON movies.studio_id=studios.id
      ORDER BY movies.title"
      movies = conn.exec(sql_query)
    end
    movies.map{ |movie| Movie.new(movie["id"], movie["title"], movie["year"], movie["rating"], movie["genre"], movie["studio"]) }
  end

  def self.find(id)
    movie = nil
    db_connection do |conn|
      sql_query = "SELECT movies.*, genres.name AS genre, studios.name AS studio
      FROM movies
      LEFT OUTER JOIN genres ON movies.genre_id=genres.id
      LEFT OUTER JOIN studios ON movies.studio_id=studios.id
      WHERE movies.id = $1"
      data = [id]
      movie = conn.exec(sql_query, data).first
    end
    Movie.new(movie["id"], movie["title"], movie["year"], movie["rating"], movie["genre"], movie["studio"])
  end

  def details
    details = nil
    db_connection do |conn|
      sql_query = "SELECT actors.name AS actor, actors.id AS actor_id, cast_members.character AS character
      FROM movies
      JOIN cast_members ON movies.id=cast_members.movie_id
      JOIN actors ON cast_members.actor_id=actors.id
      WHERE movies.id=$1"
      data = [id]
      details = conn.exec_params(sql_query, data)
    end
    details.map { |detail| MovieDetail.new(detail["actor"], detail["actor_id"], detail["character"])}
  end
end

class MovieDetail
  attr_accessor :actor, :actor_id, :character
  def initialize(actor, actor_id, character)
    @actor = actor
    @actor_id = actor_id
    @character = character
  end
end

class ActorDetail
  attr_accessor :character, :movie, :movie_id
  def initialize(character, movie, movie_id)
    @character = character
    @movie = movie
    @movie_id = movie_id
  end
end

get '/actors' do
  actors = Actor.all
  erb :'actors/index', locals: { actors: actors }
end
get '/actors/:id' do
  actor = Actor.find(params[:id])
  details = actor.details
  erb :'actors/show', locals: { actor: actor, details: details }
end
get '/movies' do
  movies = Movie.all
  erb :'movies/index', locals: { movies: movies }
end
get '/movies/:id' do
  movie = Movie.find(params[:id])
  details = movie.details
  erb :'movies/show', locals: { movie: movie, details: details }
end
