require 'rubygems'

ENV['RACK_ENV'] ||= ENV['RAILS_ENV'] ||= 'development'

require 'bundler/setup'
Bundler.require(:default)

Mongoid.load!(File.expand_path('../mongoid.yml', __FILE__))

class Park

  include Mongoid::Document

  field :Name, :type => String
  field :pos,  :type => Array

  index({ :pos => '2d' })

  def self.from_params(params)
    scope = where(:pos => {'$near' => [params['lon'], params['lat']]})
    scope = scope.where(:Name => {'$regex' => Regexp.new(params['name'], true)}) if params['name']
    scope.all
  end

end

Park.create_indexes

if Park.count == 0 && ! ENV['SPATIALAPP_DO_NOT_LOAD']

  Yajl::Parser.parse(File.read(File.expand_path('../parks.json', __FILE__))) do |park|
    Park.new(:Name => park['Name'], :pos => park['pos']).save
  end

end

class SpatialApp < Sinatra::Base

  helpers do

    def encode(data)
      Yajl::Encoder.encode(data)
    end

  end

  get '/' do
    'SpatialApplication'
  end

  get '/ws/parks' do
    encode(Park.all)
  end

  get '/ws/parks/park/:id' do
    encode(Park.where(:id => params['id']).first)
  end

  get '/ws/parks/near' do
    encode(Park.from_params(params))
  end

  get '/ws/parks/name/near/:name' do
    encode(Park.from_params(params))
  end

  get '/test' do
    "<strong>It actually worked</strong>"
  end

end

run SpatialApp
