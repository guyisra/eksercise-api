# frozen_string_literal: true

class PeopleController < ApplicationController
  def index
    page = params[:page] || 1

    people = User.page(page).per(50)

    render json: people
  end
end
