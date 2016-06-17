# MerchantSamples::Engine.routes.draw do
#   # post  "merchant/ipn_notify" => "merchant#ipn_notify", :as => :ipn_notify
#   # match "merchant(/:action)",  :controller => "merchant", :as => :merchant, via: :all
#   #
#   # root :to => "merchant#index"
# end


Rails.application.routes.draw do

  get '/auth/auth0/callback', to: 'auth0#callback'
  get '/auth/failure', to: 'site#auth_failure'
  get '/auth/logout', to: 'auth0#logout', as: :logout

  # devise_for :admin_users, ActiveAdmin::Devise.config
  # ActiveAdmin.routes(self)

  devise_for :users, ActiveAdmin::Devise.config

  # todo: figure out if there is still a way to keep this handlers
  # devise_for :users, controllers: {
  #     sessions: 'users/sessions',
  #     registrations: 'users/registrations'
  # }

  ActiveAdmin.routes(self)


  # Landing page
  root 'site#index'
  # get  'index2' => 'site#index2'
  # todo: better factor these routes defs
  get 'terms', to: 'site#terms', as: :terms
  get 'faq', to: 'site#faq', as: :faq
  get 'privacy', to: 'site#privacy', as: :privacy
  get 'donate', to: 'site#donate', as: :donate
  get 'donate/:uuid', to: 'site#donate'
  get 'payment/:transaction_uuid', to: 'site#payment'
  get 'thanks/:transaction_uuid', to: 'site#thanks'
  get 'merchant_receipt/:transaction_uuid' => 'site#merchant_receipt'

  get  'site/:uuid' => 'site#index'
  get  'site/:uuid/address/:transaction_uuid' => 'site#address'
  get  'site/:uuid/payment/:transaction_uuid' => 'site#payment'
  get  'site/:uuid/thanks/:transaction_uuid' => 'site#thanks'
  get  'site/:uuid/merchant_receipt/:transaction_uuid' => 'site#merchant_receipt'

  #todo: move these to 'site' urls
  get  'recurring/:uuid/cancel' => 'recurring#cancel'
  get  'recurring/:uuid' => 'recurring#status'


  get '/welcome', to: 'welcome#index'
  get '/test', to: 'welcome#test'

  # todo: this this still used??
  get  'widget/:uuid', to: 'pay#widget'

  # get   '/api/v1/embed/:uuid', to: 'embed#widget_data'
  # get   '/api/v1/embed/:uuid/estimate_fee' => 'embed#estimate_fee'
  #
  # # need better names for these actions
  # post  '/api/v1/embed/:uuid/step1', to: 'embed#step1'
  # post  '/api/v1/embed/:uuid/step2', to: 'embed#step2'
  # # temp get method matchers until cross-site iframe post supported
  # get  '/api/v1/embed/:uuid/step1', to: 'embed#step1'
  # get  '/api/v1/embed/:uuid/step2', to: 'embed#step2'
  #
  # get  '/api/v1/embed/:uuid/update_fee_allocation', to: 'embed#update_fee_allocation'
  # get  '/api/v1/embed/:uuid/send_dwolla_info', to: 'embed#send_dwolla_info'


  get  '/dwolla/auth', to: 'dwolla#auth'
  get  '/dwolla/oauth_complete', to: 'dwolla#oauth_complete'
  get  '/dwolla/make_payment', to: 'dwolla#make_payment'

  # get  'pay/paypal' => 'pay#paypal'
  get  'paypal/checkout' => 'paypal#checkout', as: :paypal_checkout
  get  'paypal/complete_payment' => 'paypal#complete_payment', as: :paypal_complete_payment
  # get  'pay/:uuid/update_fee_allocation/:transaction_uuid' => 'pay#update_fee_allocation'
  # get  'pay/:uuid/send_dwolla_info/:transaction_uuid' => 'pay#send_dwolla_info'

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
