MerchantSamples::Engine.routes.draw do
  post  "merchant/ipn_notify" => "merchant#ipn_notify", :as => :ipn_notify
  match "merchant(/:action)",  :controller => "merchant", :as => :merchant, via: :all

  root :to => "merchant#index"
end


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


  get  'pay/paypal' => 'pay#paypal'


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

  # paypal examples
  # mount MerchantSamples::Engine => "/paypalsamples" if Rails.env.development?

  # get "paypal_samples(/:action)",  :controller => "paypal_samples", :as => :paypal_samples
  # get "merchant(/:action)",  :controller => "merchant_samples/paypal_samples", :as => :merchant
  # post  "merchant/ipn_notify" => "merchant_samples/merchant#ipn_notify", :as => :ipn_notify
  # get "merchant(/:action)",  :controller => "merchant_samples/merchant", :as => :merchant

  # get ':controller(/:action(/:id))'

  mount MerchantSamples::Engine => "/samples"  #if Rails.env.development?

end
