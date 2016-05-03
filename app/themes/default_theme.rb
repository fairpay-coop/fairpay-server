# hook for logic which potentially needs to be customized on a per theme basis

class DefaultTheme

  attr_reader :transaction, :embed#, :data

  def initialize(embed=nil, transaction=nil)#, data=nil)
    @embed = embed  if embed
    if transaction
      @transaction = transaction
      @embed = transaction.embed
    end
    # @data = data  if data  # not yet sure if this will be useful
  end

  def email_from
    ENV['MAILER_DEFAULT_FROM']
  end

  def payee_receipt_subject
    "Payment Received - #{transaction.payor.name}"
  end

  def payor_receipt_subject
    "Payment Receipt - #{transaction.payee.name}"
  end

  def dwolla_info_subject
    "More about Dwolla"
  end

end