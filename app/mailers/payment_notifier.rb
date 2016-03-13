class PaymentNotifier < ApplicationMailer

  # send a signup email to the user, pass in the user object that   contains the user's email address
  def receipt(transaction)
    @transaction = transaction
    subject = "Payment Receipt - #{@transaction.payee.name}"
    mail( to: @transaction.payor.email, subject: subject )
  end

  def receipt_merchant(transaction)
    @transaction = transaction
    subject = "Payment Received - #{@transaction.payor.name}"
    mail( to: @transaction.payee.email, subject: subject )
  end


end
