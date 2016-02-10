Rails.application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)
  devise_for :users

  # Landing page
  root 'welcome#index'

  # API
  mount API => '/api'
  mount GrapeSwaggerRails::Engine => '/apidoc'

end
