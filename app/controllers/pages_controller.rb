class PagesController < ApplicationController
  skip_before_action :authenticate_user!

  MIN_DOGS_FOR_STATS = 10

  def home
    dogs_count = Dog.count
    @stats = { dogs: dogs_count, matches: Chatroom.count, towns: Dog.distinct.count(:address) } if dogs_count >= MIN_DOGS_FOR_STATS
  end

  def offline
  end
end
