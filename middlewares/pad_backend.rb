require 'faye/websocket'
require 'json'

unless ENV['RACK_ENV'] == 'production'
  Faye::WebSocket.load_adapter('thin')
end

module Padster
  class PadBackend
    KEEPALIVE_TIME = 15

    def initialize(app)
      @app = app
      @clients = []
      @usernames = {}
      @pad_text = ''
    end

    def rebuild_text_from_diff(start, length_replaced, length_added, diff)
      # rebuild stored string from diff sent back
      # by client message

      # to_s calls make sure nil's are treated as empty strings
      @pad_text[0...start].to_s + diff + @pad_text[start + length_replaced + 1..-1].to_s
    end

    def call(env)
      if Faye::WebSocket.websocket?(env)
        ws = Faye::WebSocket.new(env, nil, {ping: KEEPALIVE_TIME })

        ws.on :open do |event|
          p [:open, ws.object_id]
          @clients << ws
          @usernames[ws.object_id] = 'stranger danger'
          ws.send({
            usernames: @usernames.values(),
            text: @pad_text
          }.to_json)
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
            @pad_text = rebuild_text_from_diff(
              event_data['start'],
              event_data['lengthReplaced'],
              event_data['lengthAdded'],
              event_data['diff']
            )

            p [:pad_text, @pad_text]

            # for now we just force update connected
            # clients text, eventually we should let them
            # rebuild the file
            @clients.each do |client|
              unless client == ws
                client.send({
                  text: @pad_text
                }.to_json)
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
