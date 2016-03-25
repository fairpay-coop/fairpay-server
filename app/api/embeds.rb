class Embeds < Grape::API

  namespace :embeds do

    # desc 'Return all the embeds.'
    # get do
    #   present Embed.all
    # end
    #
    # desc 'data for a given embed'
    # get ':embed_uuid' do
    #
    # end
    #

    route_param :embed_uuid, type: String do

      get do
        embed = Embed.resolve(params[:embed_uuid])
      end

      #todo
      get :config do
        embed = Embed.resolve(params[:embed_uuid])
        wrap_result( {
            uuid: embed.uuid,
            payee: embed.profile&.name,
            payment_types: embed.get_data_field(:payment_types),
            payment_fees: embed.get_data_field(:payment_types).each_with_object({}) {|type, res| res[type] = "$0.%02d" % rand(25)},
            amounts: [5, 10, 50, -1],
            amount_format: '${0}'
        } )
      end

      get :campaign_status do
        puts "campaign_status - params: #{params.inspect}"
        embed = Embed.resolve(params[:embed_uuid])
        campaign = embed&.campaign
        raise "campaign now found for embed uuid: #{params[:embed_uuid]}"  unless campaign

        # result = present campaign
        result = Campaign::Entity.represent(campaign)
        wrap_result( result )
      end

      #todo: merge into renamed widget_data once branches unified
      get :embed_data do
        puts "embed_data - params: #{params.inspect}"
        embed = Embed.resolve(params[:embed_uuid])

        session_email = cookies[:email]

        # payment_types =

        payment_configs = embed.payment_configs.map do |merchant_config|
          merchant_config.widget_data(nil, nil)
        end

        result = {
            session_email: session_email,
            suggested_amounts: embed.suggested_amounts,
            payment_configs: payment_configs,
            description: embed.get_data_field(:description),
            campaign: Campaign::Entity.represent(embed.campaign),
            mailing_list_enabled: embed.mailing_list_enabled,
            capture_memo: embed.capture_memo,
            allocation_options: embed.fee_allocation_options(nil),
            consider_this: embed.get_data_field(:consider_this),
        }
        if embed.recurrence_enabled
          result[:recurrence_options] = embed.recurrence_options
              # option[:value], option[:label]
        end

          wrap_result( result )
      end

      get :step2_data do
        puts "embed_data - params: #{params.inspect}"
        session_data = params[:session_data] || {}
        #todo: session data security

        embed = Embed.resolve(params[:embed_uuid])
        transaction = Transaction.by_uuid(params[:transaction_uuid])

        raise "invalid transaction id: #{params[:transaction_uuid]}" unless transaction #todo confirm provisional status
        raise "missing transaction amount"  unless transaction.base_amount && transaction.base_amount > 0

        current_user = resolve_current_user(session_data)
        if current_user && current_user.email == transaction.payor.email
          puts "authenticated user session - stored payments available"
          # profile_authenticated = true
          authenticated_profile = current_user.profile
        else
          #todo: rip out once js session_data handling integrated
          authenticated_profile = transaction.payor
        end

        # used to resume after login
        # todo: think about this once devise auth integrated into widget
        # cookies[:current_url] = transaction.step2_url

        payment_configs = embed.payment_configs.map do |merchant_config|
          merchant_config.payment_service.widget_data(transaction, session_data)
        end

        result = {
            transaction: Transaction::Entity.represent(transaction),
            # dwolla_authenticated: dwolla_authenticated,
            authenticated_profile: Profile::Entity.represent(authenticated_profile),
            payment_configs: payment_configs
        }
        # if profile_authenticated
        #   result[:authenticated_profile] = current_user.profile
        # end
        wrap_result( result )
      end


      # # beware: not currently used
      # def step1
      #   render_json do
      #     embed_uuid = params[:uuid]
      #     embed = Embed.by_uuid(embed_uuid)
      #
      #     email = params[:email]
      #     name = params[:name]
      #     amount = params[:amount]   # todo: validate decimal conversion
      #
      #     transaction = embed.step1(params)  #email, name, amount)
      #
      #     result = {transaction_uuid: transaction.uuid}
      #   end
      # end

      post :submit_step1 do
        puts "step1 - params: #{params.inspect}"
        embed = Embed.resolve(params[:embed_uuid])

        params do
          required :amount, type: Float
          required :email, type: String
          optional :name, type: String
          optional :recurrence, type: String
          optional :mailing_list, type: Boolean
          optional :description, type: String
          optional :memo, type: String
          optional :offer_uuid, type: String
          optional :return_url, type: String
          optional :correlation_id, type: String
        end

        data = params.slice(:amount, :email, :name, :recurrence, :mailing_list, :description, :memo, :offer_uuid, :return_url, :correlation_id)

        cookies[:email] = data[:email]

        puts("data: #{data.inspect}")

        transaction = embed.step1(data)
        puts("tran: #{transaction.inspect}")

        wrap_result( {
            status: transaction.status,
            transaction_uuid: transaction.uuid,
            redirect_url: transaction.step2_url,
            transaction: transaction
        } )
      end



      get :submit_payment do
        puts "submit card - params: #{params.inspect}"
        embed = Embed.resolve(params[:embed_uuid])

        transaction = embed.step2(params)
        result = {
            status: transaction.status,
            paid_amount: transaction.paid_amount,
            estimated_fee: transaction.estimated_fee,
            redirect_url: transaction.finished_url
        }
        puts "step2 - result: #{result}"
        wrap_result result
      end


      get :estimate_fee do
        puts "estimate fee - params: #{params.inspect}"
        params do
          requires :bin, type: String
          requires :amount, type: Float
        end
        embed = Embed.resolve(params[:embed_uuid])
        bin = params[:bin]
        amount = params[:amount]
        wrap_result embed.card_payment_service.estimate_fee(amount, bin)
      end


      get :update_fee_allocation do
        puts "update fee allocation - params: #{params.inspect}"
        params do
          requires :transaction_uuid, type: String
          requires :fee_allocation, type: String
        end
        embed = Embed.resolve(params[:embed_uuid])
        # transaction = Transaction.by_uuid( params[:transaction_uuid] )
        # allocation = params[:fee_allocation]
        result = embed.update_fee_allocation(params)
        puts "update_fee_allocation - result: #{result}"
        wrap_result result
      end

      get :send_dwolla_info do
        puts "send_dwolla_info - params: #{params.inspect}"
        params do
          requires :transaction_uuid, type: String
        end
        embed = Embed.resolve(params[:embed_uuid])
        result = embed.send_dwolla_info(params)
        puts "send_dwolla_info - result: #{result}"
        wrap_result result
      end


    end


  end


end

