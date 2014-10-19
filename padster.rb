require 'sinatra'

module Padster
  class App < Sinatra::Base
    get '/' do
      erb :'index.html'
    end
  end
end
