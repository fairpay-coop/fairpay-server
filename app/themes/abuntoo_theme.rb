# hook for logic which potentially needs to be customized on a per theme basis

class AbuntooTheme < DefaultTheme

  def email_from
    # "donations@abuntoo.com"
    "abuntoo@fairpay.coop"  #tmp for testing - should move more config stuff out to yaml files
  end

  def payee_receipt_subject
    "Abuntoo Donation Received - Please Thank Donor!"
  end

  def payor_receipt_subject
    "Abuntoo Donation Receipt - ##{transaction.reference_number}"
  end

end