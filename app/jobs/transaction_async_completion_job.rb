class TransactionAsyncCompletionJob

  include SuckerPunch::Job

  def perform(transaction_id)
    puts "TransactionAsyncCompletionJob - #{transaction_id}"
    ActiveRecord::Base.connection_pool.with_connection do
      begin
        transaction = Transaction.find(transaction_id)
        transaction.async_completion
      rescue Gibbon::MailChimpError => mce
        SuckerPunch.logger.error("async completion failed: due to #{mce.message}")
        raise mce
      rescue Exception => e
        SuckerPunch.logger.error("async completion failed: due to #{e.message}")
        raise e
      end
    end
  end

end