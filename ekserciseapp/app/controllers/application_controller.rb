class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  def root
    render 'application/swagger.html'
  end
end
