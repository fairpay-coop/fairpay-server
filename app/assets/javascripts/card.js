var lastBin = '';

function cardNumberKeypressed(event) {
  //alert('cardNumberKeypressed: ' + event);
  var card_number = $('#card_number').val();
  var amount = $('#amount').val();
  var embed_uuid = $('#embed_uuid').val();
  //alert('card number: ' + card_number);
  if (card_number.length >= 6) {
    var newBin = card_number.slice(0, 6);
    if (lastBin != newBin) {
      //alert('new bin: ' + newBin + ', last bin: ' + lastBin + ', amount: ' + amount);
      lastBin = newBin;
      data = {bin: newBin, amount: amount, embed_uuid: embed_uuid};
      FairPayApi.estimateFee(data, handleEstimateFeeResponse);
    }
  } else {
    if (lastBin != '') {
      //var default_fee_info = $('#default_fee_info').val();
      //$("#fee_info").html(default_fee_info);
      updateFeeInfo();
      lastBin = ''
    }
  }
}

function showDefaultFeeInfo() {
  var default_fee_info = $('#default_fee_info').val();
  $("#fee_info").html(default_fee_info);
}


function updateFeeInfo() {
  //var use_payment_source = params.use_payment_source;
  var card_number = $('#card_number').val();
  var amount = $('#amount').val();
  var embed_uuid = $('#embed_uuid').val();    var bin;
  if (card_number.length >= 6) {
    bin = card_number.slice(0, 6);
  } else {
    bin = null;
  }
  data = {bin: bin, amount: amount, embed_uuid: embed_uuid};
  //alert("data: " + JSON.stringify(data));
  FairPayApi.estimateFee(data, handleEstimateFeeResponse);
}

function handleEstimateFeeResponse(data) {
  //alert('estimate fee response: ' + JSON.stringify(data));
  if (data.result) {
    info = data.result;
    //var bindata = "<b>Information about your card</b>: <br>&nbsp; &nbsp;" + info.card_brand + ", " + info.card_type + ", " + info.card_category +
    //        ", " + info.issuing_org + ", " + (info.is_regulated ? "regulated bank" : "unregulated bank") + "";
    //bindata += "<br>Transaction fee for this card: <b>$" + info.estimated_fee + "</b>";
    //bindata += "<br>&nbsp; &nbsp;" + info.fee_tip;
    if (info.fee_str) {
      bindata = info.fee_str;
    } else {
      var bindata = "<b>$" + info.estimated_fee + "</b>";
      if (info.fee_tip) {
        bindata += "&nbsp; (" + info.fee_tip + ")";
      }
    }

    $("#fee_info").html(bindata);

  } else {
    console.log("info not found for bin: " + lastBin);
    $("#fee_info").html("<br><br>");
  }
}

//$("#card_form").submit(handleCard);

function handleCard() {
  console.log('handleCard');
  if ( ! validateAgreedToTerms() ) {
    return false;
  }
  // post the address form on this page if it exists
  //handleAddress();
  //console.log("after handleAddress()");

  // Copy fields from top form into submit data
  var name = $('#input_name').val();
  var email = $('#input_email').val();
  //var anonymous = $('#input_anonymous').val();
  var anonymous = $('input[type=checkbox][name=anonymous]').is(':checked');
  console.log("name: " + name + ", email: " + email + ", anon: " + anonymous);
  $('#hidden_name').val(name);
  $('#hidden_email').val(email);
  $('#hidden_anonymous').val(anonymous);

  var form = document.getElementById("card_form");
  var data = {};
  FairPayApi.copyFormValues(data, form, ['embed_uuid', 'transaction_uuid', 'payment_type', 'amount', 'card_number', 'card_mmyy', 'card_cvv', 'billing_zip', 'save_payment_info', 'use_payment_source', 'name', 'email', 'anonymous']);
  //alert('data: ' + JSON.stringify(data));
  if (validateCardFields(data)) {
    FairPayApi.submitPayment(data, handleCardResponse);
  }
  return false;
}

function validateAgreedToTerms() {
  console.log('agreedToTerms:' + agreedToTerms());
  if ( agreedToTerms() ) {
    return true;
  } else {
    el = $('p[id=termsAgree]');
    scrollToElement(el);
    showError('Please agree to terms before proceeding', el);
    console.log("validateAgreedToTerms - returning false");
    return false;
  }
}

//function newShowError(message, elt) {
//  if (elt) {
//    $(elt).notify(message, {className: "error", autoHideDelay: 2000, showDuration:100, position: "right"});
//  } else {
//    $.notify(message, {className: "error", autoHideDelay: 2000, showDuration:100 });
//  }
//}


function scrollToBottom() {
  $(window).scrollTop($(document).height());
}

function scrollToElement(el) {
    $(window).scrollTop($(el).offset().top);
}


function agreedToTerms() {
  var terms_field = $('input[type=checkbox][name=agree_to_terms]');
  if (terms_field == undefined) {
    console.log('agree_to_terms field missing');
    return false;
  }
  return terms_field.is(':checked');
}

function validateCardFields(data) {
  if (data['use_payment_source']) {
    return true;
  }
  if ( ! validatePresent(data['card_number'], 'Card Number') ) {
    return false;
  }
  if ( ! validatePresent(data['card_mmyy'], 'Card Expiration') ) {
    return false;
  }
  if ( ! validatePresent(data['card_cvv'], 'Card CVV') ) {
    return false;
  }
  if ( ! validatePresent(data['billing_zip'], 'Billing Zip') ) {
    return false;
  }
  return true;
}

//todo: factor this over to fairpayapi.js
function validatePresent(value, field_description) {
  if (value == undefined || value == null || value.length == 0) {
    alert("Please enter " + field_description);
    return false;
  } else {
    return true;
  }
}


function handleCardResponse(data) {
  console.log('step2 response: ' + JSON.stringify(data));
  if (data.result) {
    var status = data.result.status;
    //$('#paymentStatus').html(status);
    $('#errorMessage').html('');      //var linkUrl = data.result.statusLink;
    //var linkHtml = '<a href="' + linkUrl + '">' + linkUrl + '</a>';
    //$('#statusLink').html(linkHtml);
    if (data.result.redirect_url) {
      window.location = data.result.redirect_url;
    }
  } else if (data.error) {
    //alert('error resp: ' + JSON.stringify(data.error));
    //$('#paymentStatus').html('error');
    $('#errorMessage').html(data.error.message);
    //$('#errorStack').html('<pre>' + data.error.stack + '</pre>');
  }
}