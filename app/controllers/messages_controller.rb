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
    add_prompt_to_chat
    stream_response
  end

  def add_prompt_to_chat
    data = turbo_stream.append(
      "#{dom_id(@chat)}_messages",
      partial: "message",
      locals: { message: @message, scroll_to: true
    })
    publish_to_redis(data)
  end

  def stream_response
  end

  def publish_to_redis(data)
    data.gsub!("\n", "")
    Redis.new.publish("user_#{@user.id}_streams", data)
  end

  def message_params
    params.require(:message).permit(:content)
  end
end
