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
      get :widget_data do
        embed = Embed.resolve(params[:embed_uuid])
        wrap_result( {
            uuid: embed.uuid,
            payee: embed.profile&.name,
            payment_types: embed.get_data_field(:payment_types)
        } )
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

      get :submit_step1 do
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
        end

        data = params.slice(:amount, :email, :name, :recurrence, :mailing_list, :description, :memo)

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



      get :submit_card do
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

