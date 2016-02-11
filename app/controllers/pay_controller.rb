class PayController < ApplicationController
  def embed
    uuid = params[:uuid]
    @embed = Embed.by_uuid(uuid)
  end

  def step1
    embed_uuid = params[:uuid]
    @embed = Embed.by_uuid(embed_uuid)

  end

  def step1_post
    embed_uuid = params[:uuid]
    embed = Embed.by_uuid(embed_uuid)

    amount = params[:amount]   # todo: validate decimal conversion

    email = params[:email]
    payor = Profile.find_by(email: email)
    unless payor
      name = params[:name]
      payor = Profile.create!(email: email, name: name)
    end

    transaction = Transaction.create!(embed: embed, payee: embed.profile, payor: payor, base_amount: amount, status: :provisional)

    redirect_to "/pay/#{embed.uuid}/step2/#{transaction.uuid}"
  end


  def step2
    @embed = Embed.by_uuid(params[:uuid])
    @transaction = Transaction.by_uuid(params[:transaction_uuid])
  end

  def step2_post
    embed = Embed.by_uuid(params[:uuid])
    transaction_uuid = params[:transaction_uuid]
    transaction = Transaction.by_uuid(transaction_uuid)
    merchant_config = MerchantConfig.find(params[:merchant_config_id])

    #todo: actual payment processing
    estimated_fee = transaction.base_amount * 0.03 + 0.30
    paid_amount = transaction.base_amount

    data = params.slice(:card_number, :card_mmyy, :card_cvv)
    data[:amount] = paid_amount
    puts "data: #{data}"
    # todo: for the moment assuming only one config
    # payment_service = embed.profile.merchant_configs.first.payment_service
    payment_service = merchant_config.payment_service
    payment_service.charge(data)

    transaction.update!(status: 'completed', paid_amount: paid_amount, estimated_fee: estimated_fee)

    redirect_to "/pay/#{embed.uuid}/thanks/#{transaction.uuid}"

  end

  def thanks
    @embed = Embed.by_uuid(params[:uuid])
    @transaction = Transaction.by_uuid(params[:transaction_uuid])

  end



end
