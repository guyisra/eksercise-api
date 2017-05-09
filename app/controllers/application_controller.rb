# frozen_string_literal: true

class ApplicationController < ActionController::Base
  protect_from_forgery with: :null_session

  after_action :cors_fix

  def root
    render 'application/swagger.html'
  end

  protected

  def cors_fix
    headers['Access-Control-Allow-Origin'] = '*'
  end

  def redis
    Redis.current
  end
end
