
AdminUser.seed(:email,
 { email: 'admin@example.com', password: 'password', password_confirmation: 'password' }
)

Profile.seed(:id,
 { id: 1, name: 'john doe', email: 'jdoe@example.com', phone: '+15551234567' }
)

Embed.seed(:id,
  { id: 1, uuid: 'RaF56o2r58hTKT7AYS9doj', profile_id: 1, kind: 'authorizenet', data: '{}' }
)

MerchantConfig.seed(:id,
  { id: 1, profile_id: 1, kind: 'authorizenet', data: '{}' }
)


