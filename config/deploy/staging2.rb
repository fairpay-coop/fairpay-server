server 'staging2.fairpay.coop', user: 'deploy', roles: %w{app db web}

set :ssh_options, {
    forward_agent: true,
    auth_methods: %w(publickey),
    user: 'deploy',
}

set :rails_env, :production
set :conditionally_migrate, true

set :deploy_to, '/home/deploy/fairpay-server'

