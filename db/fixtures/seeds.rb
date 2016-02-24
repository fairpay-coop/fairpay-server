#
# to load the data:
#   rake db:seed_fu
#

AdminUser.seed(:email,
  { email: 'admin@example.com', password: 'password', password_confirmation: 'password' }
)

Profile.seed(:id,
  { id: 1, name: 'Test Merchant', email: 'test_merchant@fairpay.coop', phone: '+15551234567' },
  { id: 2, name: 'Test Customer', email: 'test_customer@fairpay.coop' }

)

Embed.seed(:id,
  { id: 1, uuid: 'RaF56o2r58hTKT7AYS9doj', profile_id: 1,  data: '{}' }
)

MerchantConfig.seed(:id,
  { id: 1, profile_id: 1, kind: 'authorizenet',
    data: '{"gateway":"sandbox","api_login_id":"9vkW3C6G", "api_transaction_key":"853xupQE6m5G8R5E"}' },
  { id: 2, profile_id: 1, kind: 'dwolla',
    data: '{"environment":"sandbox"}'},
  { id: 3, profile_id: 1, kind: 'paypal',
    data: '{"mode":"sandbox", "username":"payments-facilitator_api1.calaverasfoodhub.org", "password":"24CNAXDPM772V2L3", "signature":"AFcWxV21C7fd0v3bYYYRCpSSRl31ArbcW4ZfRN5LuHq6.1Zk8h8E9Rwm"}'}
)

WELLS_FARGO_NAME = 'WELLS FARGO BANK, N.A.'
BinbaseOrg.seed(:name,
  { name: WELLS_FARGO_NAME, country_iso: 'US', is_regulated: true }
)

Binbase.seed(:bin,
  { bin: '434443', card_brand: 'VISA', card_type: 'CREDIT', card_category: 'CLASSIC' },
  { bin: '429255', card_brand: 'VISA', card_type: 'DEBIT', card_category: 'CLASSIC' },
  { bin: '416724', card_brand: 'VISA', card_type: 'DEBIT', card_category: 'PREPAID',
    binbase_org: BinbaseOrg.find_by(name: WELLS_FARGO_NAME) }
)

# DwollaToken.seed(:id,
#   { id: 1, refresh_token: "cmla7H0wA028LNQvQxCcFDNdgwGsnw9zEDmhfdUO2WOnkFZ1dN", access_token: "cmla7H0wA028LNQvQxCcFDNdgwGsnw9zEDmhfdUO2WOnkFZ1dN",
#     account_id: 'd3c4fdc2-2b4d-47f7-84c3-35db069c6eb6', profile_id: 1 },
#   { id: 2, refresh_token: 'XclZpQlA6CJHNAKXgiesAprixM1Bc5ea4YLPFcRoP1J4JlUYg1', access_token: "u5whSEo9Pkb2vvowMto4KDNXPQKryQTiPCmhTUj2vHHRTMJ301",
#    account_id: '20699646-02ff-4f85-86a9-0668a0649eb4', profile_id: 2 },
# )


# TODO: shortlist of binbase data

