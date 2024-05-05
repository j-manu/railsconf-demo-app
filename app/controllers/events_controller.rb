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
end
