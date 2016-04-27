class PaymentNotifier < ApplicationMailer

  # send a signup email to the user, pass in the user object that   contains the user's email address
  def receipt(transaction)
    @transaction = transaction
    @data = hashify( transaction.step2_data )
    subject = "Payment Receipt - #{@transaction.payee.name}"
    mail( to: @transaction.payor.email, subject: subject )
  end

  def receipt_merchant(transaction)
    @transaction = transaction
    @data = hashify( transaction.step2_data )
    subject = "Payment Received - #{@transaction.payor.name}"
    mail( to: @transaction.payee.email, subject: subject )
  end

  def dwolla_info(transaction)
    @transaction = transaction
    @data = hashify( transaction.step2_data )
    subject = "More about Dwolla"
    mail( to: @transaction.payor.email, subject: subject )
  end



end
