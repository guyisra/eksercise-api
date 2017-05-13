# frozen_string_literal: true

Rails.application.routes.draw do
  post 'candidates/', to: 'candidates#create'
  get 'candidates', to: 'candidates#index'
  post 'candidates/:id/evil', to: 'candidates#evil', as: 'candidate_evil'

  post '/people/search', to: 'people#search'
  get '/people', to: 'people#index'

  root 'application#root'
end
