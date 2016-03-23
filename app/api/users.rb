class Users < Grape::API

  resource :users do

    # shouldn't expose any of this level of data until we have a security model
    # desc 'Return all the users.'
    # get do
    #   present User.all
    # end

  end

end
