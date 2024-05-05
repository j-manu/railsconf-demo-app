class ChatsController < ApplicationController
  before_action :authenticate_user!

  def index
    @chat = Current.user.chats.create!
    redirect_to @chat
  end

  def show
    @chat = Current.user.chats.find(params[:id])
    @messages = @chat.messages.latest_last
  end
end
