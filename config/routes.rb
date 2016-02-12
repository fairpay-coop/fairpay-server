Rails.application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)
  devise_for :users

  # Landing page
  root 'welcome#index'

  get  'embed/:uuid' => 'pay#embed'
  get  '/api/estimate_fee' => 'pay#estimate_fee'
  get  'pay/:uuid' => 'pay#step1'
  post 'pay/:uuid/step1' => 'pay#step1_post'
  get  'pay/:uuid/step2/:transaction_uuid' => 'pay#step2'
  post 'pay/:uuid/step2' => 'pay#step2_post'
  get  'pay/:uuid/thanks/:transaction_uuid' => 'pay#thanks'

  # API
  mount API => '/api'
  mount GrapeSwaggerRails::Engine => '/apidoc'

end
