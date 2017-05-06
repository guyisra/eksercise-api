# frozen_string_literal: true

class ApplicationController < ActionController::Base
  protect_from_forgery with: :null_session

  def root
    render 'application/swagger.html'
  end

  protected

  def redis
    Redis.current
  end
end
