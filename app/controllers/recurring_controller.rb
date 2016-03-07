class RecurringController < ApplicationController

  def status
    uuid = params[:uuid]
    @recurring = RecurringPayment.by_uuid(uuid)
    raise "recurring payment not found for id: #{uuid}"  unless @recurring
  end

  def cancel
    uuid = params[:uuid]
    recurring = RecurringPayment.by_uuid(uuid)

    if recurring
      if recurring.active?
        recurring.cancel
      else
        puts "recurring payment not active - #{uuid}: #{recurring.status}"
      end
    else
      puts "recurring payment not found: #{uuid}"
    end

    redirect_to "/recurring/#{uuid}"
  end


  def perform_all_pending
    result = RecurringPayment.perform_all_pending
    render json: result
  end

end
