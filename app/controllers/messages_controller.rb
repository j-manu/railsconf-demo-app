class MessagesController < ApplicationController
  include ActionView::RecordIdentifier

  before_action :authenticate_user!

  def create
    @chat = Current.user.chats.find(params[:chat_id])
    @message = @chat.messages.create!(message_params.merge(role: "user"))
    @user = Current.user

    Async do |task|
      stream_to_chat
    end

    head :ok
  end

  private

  def stream_to_chat
    add_message_to_chat(@message)
    stream_response
  end

  def add_message_to_chat(message)
    data = turbo_stream.append(
      "#{dom_id(@chat)}_messages",
      partial: "message",
      locals: { message: message }
    )
    publish_to_redis(data)
  end

  def stream_response
    response_message = @chat.messages.create!(role: "system", content: "")
    add_message_to_chat(response_message)
    openai_client.chat(
      parameters: {
          model: "gpt-3.5-turbo",
          messages: [ { role: "user", content: @message.content } ],
          temperature: 0.7,
          stream: proc do |chunk, _bytesize|
              begin
                response_message.content += chunk.dig("choices", 0, "delta", "content")
                response_message.save!
              rescue
              end
              replace_message_in_chat(response_message)
          end
    })
  end

  def replace_message_in_chat(message)
    data = turbo_stream.update(
      dom_id(message),
      partial: "message",
      locals: { message: message }
    )
    publish_to_redis(data)
  end


  def publish_to_redis(data)
    data.gsub!("\n", "")
    Redis.new.publish("user_#{@user.id}_streams", data)
  end

  def message_params
    params.require(:message).permit(:content)
  end

  def openai_client
    OpenAI::Client.new(
      access_token: ENV.fetch("OPENAI_API_KEY"),
      log_errors: true
    )
  end
end
