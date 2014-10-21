require 'faye/websocket'
require 'json'

module Padster
  class PadBackend
    KEEPALIVE_TIME = 15

    def initialize(app)
      @app = app
      @clients = []
      @usernames = {}
      @pad_text = ''
    end

    def call(env)
      if Faye::WebSocket.websocket?(env)
        ws = Faye::WebSocket.new(env, nil, {ping: KEEPALIVE_TIME })

        ws.on :open do |event|
          p [:open, ws.object_id]
          @clients << ws
          @usernames[ws.object_id] = 'stranger danger'
          ws.send(({
            usernames: @usernames.values(),
            text: @pad_text
          }.to_json))
        end

        ws.on :message do |event|
          p [:message, event.data]
          event_data = JSON.load(event.data)

          if event_data['action'] == 'name_change'
            # update usernames
            @usernames[ws.object_id] = event_data['username']
            @clients.each do |client|
              client.send({usernames: @usernames.values()}.to_json)
            end
          elsif event_data['action'] == 'text_change'
            @pad_text = event_data['text']
            # pass event to all clients
            @clients.each do |client|
              unless client == ws
                client.send(event.data)
              end
            end
          end
        end

        ws.on :close do |event|
          p [:close, ws.object_id, event.code, event.reason]
          @clients.delete(ws)
          @usernames.delete(ws.object_id)
          ws = nil
        end

        ws.rack_response
      else
        @app.call(env)
      end
    end
  end
end
