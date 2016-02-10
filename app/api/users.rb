class Users < Grape::API

  resource :users do

    desc 'Return all the users.'
    get do
      present User.all
    end

  end

end
