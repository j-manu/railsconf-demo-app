require "async/websocket/adapters/rails"

class EventsController < ApplicationController
  before_action :authenticate_user!

  EVENT_STREAM_HEADERS = {
    "content-type" => "text/event-stream",
    "cache-control" => "no-cache",
    "last-modified" => Time.now.httpdate
  }

  def sse
    client = Redis.new
    user_id = Current.user.id

    body = proc do |stream|
      client.subscribe("user_#{user_id}_streams") do |on|
        on.message do |_, message|
          stream.write("data: #{message}\n\n")
        end
      end
    ensure
      stream.close
    end

    self.response = Rack::Response[200, EVENT_STREAM_HEADERS.dup, body]
  end

  def websocket
    client = Redis.new
    user_id = Current.user.id

    self.response = Async::WebSocket::Adapters::Rails.open(request) do |connection|
      subscription_task = Async do
        client.subscribe("user_#{user_id}_streams") do |on|
          on.message do |_, message|
            connection.send_text(message)
            connection.flush
          end
        end
      end

      while (message = connection.read)
        Rails.logger.info "Message from client: #{message}"
      end
    rescue Errno::EPIPE, Errno::ECONNRESET, IOError, Protocol::WebSocket::ClosedError
    ensure
      subscription_task&.stop
    end
  end
end
