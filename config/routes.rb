Rails.application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)
  devise_for :users

  # Landing page
  root 'welcome#index'

  get   '/api/v1/embed/:uuid' => 'embed#widget_data'
  get   '/api/v1/embed/:uuid/estimate_fee' => 'embed#estimate_fee'
  # need better names for these actions
  post  '/api/v1/embed/:uuid/step1' => 'embed#step1'
  post  '/api/v1/embed/:uuid/step2' => 'embed#step2'
  # temp get method matchers until cross-site iframe post supported
  get  '/api/v1/embed/:uuid/step1' => 'embed#step1'
  get  '/api/v1/embed/:uuid/step2' => 'embed#step2'

  get  '/dwolla/auth' => 'dwolla#auth'
  get  '/dwolla/oauth_complete' => 'dwolla#oauth_complete'
  get  '/dwolla/make_payment' => 'dwolla#make_payment'


  get  'embed/:uuid' => 'pay#embed'
  get  'pay/:uuid' => 'pay#step1'
  post 'pay/:uuid/step1' => 'pay#step1_post'
  get  'pay/:uuid/step2/:transaction_uuid' => 'pay#step2'
  post 'pay/:uuid/step2' => 'pay#step2_post'
  get  'pay/:uuid/pay_via_dwolla/:transaction_uuid' => 'pay#pay_via_dwolla'

  get  'pay/:uuid/thanks/:transaction_uuid' => 'pay#thanks'

  # API
  mount API => '/api'
  mount GrapeSwaggerRails::Engine => '/apidoc'

end
