# MerchantSamples::Engine.routes.draw do
#   # post  "merchant/ipn_notify" => "merchant#ipn_notify", :as => :ipn_notify
#   # match "merchant(/:action)",  :controller => "merchant", :as => :merchant, via: :all
#   #
#   # root :to => "merchant#index"
# end


Rails.application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)

  # devise_for :users

  devise_for :users, controllers: {
      sessions: 'users/sessions',
      registrations: 'users/registrations'
  }


  # Landing page
  root 'welcome#index'

  get  'widget/:uuid' => 'pay#widget'

  get   '/api/v1/embed/:uuid' => 'embed#widget_data'
  get   '/api/v1/embed/:uuid/estimate_fee' => 'embed#estimate_fee'

  # need better names for these actions
  post  '/api/v1/embed/:uuid/step1' => 'embed#step1'
  post  '/api/v1/embed/:uuid/step2' => 'embed#step2'
  # temp get method matchers until cross-site iframe post supported
  get  '/api/v1/embed/:uuid/step1' => 'embed#step1'
  get  '/api/v1/embed/:uuid/step2' => 'embed#step2'

  get  '/api/v1/embed/:uuid/update_fee_allocation' => 'embed#update_fee_allocation'
  get  '/api/v1/embed/:uuid/send_dwolla_info' => 'embed#send_dwolla_info'


  get  '/dwolla/auth' => 'dwolla#auth'
  get  '/dwolla/oauth_complete' => 'dwolla#oauth_complete'
  get  '/dwolla/make_payment' => 'dwolla#make_payment'


  get  'pay/paypal' => 'pay#paypal'
  # get  'paypal/:action', :controller => 'paypal'
  get  'paypal/checkout' => 'paypal#checkout', as: :paypal_checkout
  get  'paypal/complete_payment' => 'paypal#complete_payment', as: :paypal_complete_payment

  get  'pay/:uuid' => 'pay#step1'
  # post 'pay/:uuid/step1' => 'pay#step1_post'
  get  'pay/:uuid/address/:transaction_uuid' => 'pay#address'
  get  'pay/:uuid/step2/:transaction_uuid' => 'pay#step2'
  post 'pay/:uuid/step2' => 'pay#step2_post'  #still used by dwolla payment. todo: migrate to api call
  get  'pay/:uuid/pay_via_dwolla/:transaction_uuid' => 'pay#pay_via_dwolla'

  get  'pay/:uuid/update_fee_allocation/:transaction_uuid' => 'pay#update_fee_allocation'
  get  'pay/:uuid/send_dwolla_info/:transaction_uuid' => 'pay#send_dwolla_info'

  get  'pay/:uuid/thanks/:transaction_uuid' => 'pay#thanks'
  get  'pay/:uuid/merchant_receipt/:transaction_uuid' => 'pay#merchant_receipt'


  get  'recurring/:uuid/cancel' => 'recurring#cancel'
  get  'recurring/:uuid' => 'recurring#status'
  get  'system/perform_pending' => 'recurring#perform_all_pending'


  # Embedable widget
  get  '/widgetjs'                                        => 'widget#widget_js'
  get  '/widget/:uuid/captureId'                          => 'widget#capture_id'
  post '/widget/:uuid/updateId'                           => 'widget#update_id'
  get  '/widget/:uuid/capturePayment/:transaction_uuid'   => 'widget#capture_payment'
  post '/widget/:uuid/updatePayment/:transaction_uuid'    => 'widget#update_payment'
  get  '/widget/:uuid/paymentComplete/:transaction_uuid'  => 'widget#payment_complete'
  get  '/widget/:uuid/authComplete/:transaction_uuid'     => 'widget#auth_complete'
  get  '/iframe'                                          => 'widget#iframe'
  post '/ping'                                            => 'widget#ping'







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

  # mount MerchantSamples::Engine => "/samples"  #if Rails.env.development?

  # namespace :merchant_samples do
    post  "merchant/ipn_notify" => "merchant_samples/merchant#ipn_notify", :as => :ipn_notify
    match "merchant(/:action)",  :controller => "merchant_samples/merchant", :as => :merchant, via: :all

    # root :to => "merchant#index"
  # end


end
