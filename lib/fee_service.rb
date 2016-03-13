
class FeeService
  include ApplicationHelper  # defines format_amount


  # fee_config example:
  #   interchange: true - add interchange rates per bin
  #   base: 0.15        - base fee to add per transaction
  #   percent: 0.10     - percentage fee of total payment amount
  def initialize(fee_config_param, payment_service)
    fee_config = fee_config_param  # is it safe in ruby to reassign function param?
    unless fee_config
      puts "ERROR: missing fee config - using dummy config"
      fee_config = {base: 0, percent: 0}
    end
    @payment_service = payment_service
    @config = fee_config.with_indifferent_access
    @interchange = @config[:interchange].to_s == 'true'
    @base = @config[:base].to_f
    @percent = @config[:percent].to_f
    puts "fee config - interchange: #{@interchange}, base: #{@base}, percent: #{@percent}"
  end



  def fee_update_enabled
    @interchange
  end


  #todo: need a better place to factor shared payment service logic too, probably a base class
  def card_fee_str(transaction, bin = nil)
    amount = transaction.amount
    if bin
      data = estimate_fee(amount, bin)
      data[:fee_str]
    else
      low, high = calculate_fee(transaction)
      result = "$#{format_amount(low)}"
      result += "-#{format_amount(high)} (depends on card type)"  if high
      result
    end
  end

  def fee_range_str(amount)
    low, high = fee_range(amount)
    result = "$#{format_amount(low)}"
    result += "-#{format_amount(high)} (depends on card type)"  if high
    result
  end



  # returns either fee range pair if no card prefix provided or a single value if provided
  def calculate_fee(transaction, params = {})
    amount = transaction.base_amount

    if @interchange
      use_payment_source = params[:use_payment_source].to_s == 'true'  #todo: better pattern here?
      if use_payment_source
        payment_source = transaction.payor.payment_source_for_type(@payment_service.payment_type)
        bin = payment_source&.get_data_field(:bin)
      else
        card = params[:card_number]
        bin = card ? card[0..5] : nil
      end

      if bin.present?
        data = estimate_fee(amount, bin)
        fee = data[:estimated_fee]
      else
        # returns a range when card prefix not provided
        fee_range(amount)  # note, returns an array with low/high range when params are missing
      end
    else
      apply_rate(amount)
    end
  end



  INTERCHANGE_LOW_DEBIT_BASE = 0.22
  INTERCHANGE_LOW_DEBIT_PERCENT = 0.05

  INTERCHANGE_LOW_CREDIT_BASE = 0.12
  INTERCHANGE_LOW_CREDIT_PERCENT = 1.80

  INTERCHAGNE_HIGH_BASE = 0.30
  INTERCHANGE_HIGH_PERCENT = 3.5

  # rates to use if bin not found
  INTERCHAGNE_DEFAULT_BASE = 0.22
  INTERCHANGE_DEFAULT_PERCENT = 2.5


  def fee_range(amount)
    [fee_range_low(amount), fee_range_high(amount)]
  end

  def fee_range_low(amount)
    amount = amount.to_f
    low_debit = apply_rate(amount, INTERCHANGE_LOW_DEBIT_BASE, INTERCHANGE_LOW_DEBIT_PERCENT)
    low_credit = apply_rate(amount, INTERCHANGE_LOW_CREDIT_BASE, INTERCHANGE_LOW_CREDIT_PERCENT)
    low = [low_debit,low_credit].min
  end

  def fee_range_high(amount)
    amount = amount.to_f
    high = apply_rate(amount, INTERCHAGNE_HIGH_BASE, INTERCHANGE_HIGH_PERCENT)
  end


  # right now, this is just the interchange fee calculation
  ## todo: add in merchant processor (i.e. dharma merchant services) fee
  #todo: perhaps rename this to 'fee_for_amount'. should never be used directly
  def estimate_fee(amount, bin = nil)
    unless bin && bin.length >= 6
      # fee_str = card_fee_str(amount)
      fee_str = fee_range_str(amount)
      #fee_range(amount)  # note, returns an array with low/high range when params are missing
      return {fee_str: fee_str}
    end

    bin = bin[0..5]  if bin.length > 6  # trim just in case we were given a full number

    binbase = Binbase.find_by(bin: bin)
    puts "binbase: #{binbase}"
    base = 0.30
    percent = 2.9
    message = nil

    amount = BigDecimal(amount)

    # return {error: 'BIN not found'} unless binbase
    unless binbase
      # placeholder default fee calculation
      # fee = apply_rate(amount, INTERCHAGNE_DEFAULT_BASE, INTERCHANGE_DEFAULT_PERCENT)

      # if unable to match bin, assume lowest fee. (don't want to overcharge)
      # todo: figure out best way to message this
      # todo: log non-matched bins for later investigation / stats
      fee = fee_range_low(amount)
      return {estimated_fee: fee, fee_str: "unknown"}
    end

    if binbase.card_brand == 'AMEX'
      base = 0.30
      percent = 3.5
      message = "Tip: AMEX has the highest fees!"
    end

    if binbase.card_brand == 'VISA' || binbase.card_brand == 'MASTERCARD'
      if binbase.card_type == 'DEBIT'
        base = 0.22
        if binbase.is_regulated
          percent = 0.05
          message = "Good choice, Debit Cards have the lowest fees!"
        else
          percent = 0.80
          message = "Good choice, Debit Cards have lower fees."
        end
      else
        base = 0.12
        message = "Tip: Debit Cards generally have lower fees than Credit Cards"
        if binbase.card_category == 'PLATINUM' || binbase.card_category == 'BUSINESS'
          percent = 2.9
          message += ", and Rewards Cards have the highest fees."
        elsif binbase.card_category == 'GOLD'
          percent = 2.2
          message += ", and Rewards Cards have higher fees."
        else
          percent = 1.8
        end
      end
    end
    if amount < 20
      message = ""
    end

    fee = apply_rate(amount, base, percent)

    fee_str = "$#{format_amount(fee)}"
    fee_str += " (#{message})"  if message.present?

    puts "calcfee - #{bin}, base: #{base}, %: #{percent} = #{fee} - tip: #{message}"
    {
        estimated_fee: fee,
        fee_tip: message,
        fee_str: fee_str, # combined and formatted string
        card_brand: binbase.card_brand,
        issuing_org: binbase.issuing_org,
        card_type: binbase.card_type,
        card_category: binbase.card_category,
        is_regulated: binbase.is_regulated,
    }
  end

  # calculates rate with configured mark-up
  def apply_rate(amount, interchange_base = 0.0, interchange_percent = 0.0)
    FeeService.apply_raw_rate(amount, @base + interchange_base, @percent + interchange_percent)
  end


  def self.apply_raw_rate(amount, base, percent)
    fee = base + amount * percent/100
    fee = (fee * 100).ceil / 100.0
  end

end