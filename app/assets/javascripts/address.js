function handleAddress() {
  console.log('handleAddresss');
  var data = {};
  var form = document.getElementById("address_form");
  if (form == null) {
    console.log('no address_form found, skipping');
    return false;
  }
  FairPayApi.copyFormValues(data, form, ['embed_uuid', 'transaction_uuid', 'first_name', 'last_name', 'organization_name',
    'street_address', 'extended_address', 'locality', 'region', 'postal_code', 'country_code']);

  console.log("data: " + JSON.stringify(data));
  console.log("valid: " + validateAddressData(data));
  if (validateAddressData(data)) {
    FairPayApi.submitAddress(data, handleAddressResponse);
  }
  return false;
}

function handleAddressResponse(data) {
  console.log('address response: ' + JSON.stringify(data));
  if (data.result) {
    //var status = data.result.status;
    //$('#errorMessage').html('');      //var linkUrl = data.result.statusLink;
    // if (data.result.capture_address_on_payment_page) {
    //   console.log('assume already on payment page - what should be the visual trigger?');
    //   scrollToTag('#paymentBlock', -30);
    // } else if (data.result.next_step_url) {
    //   window.location = data.result.next_step_url;
    // }
  window.location = data.result.next_step_url;
  } else if (data.error) {
    showError(data.error.message);
  }
}

function scrollToTag(tag, adjust){
  $(window).scrollTop($(tag).offset().top + adjust);
}


//function showError(message) {
//  $('#errorMessage').show();
//  $('#errorMessage').html(message);
//  //$('#errorStack').html('<pre>' + data.error.stack + '</pre>');
//}

function hideError(message) {
  $('#errorMessage').hide();
  $('#errorMessage').html('');
}

function validateAddressData(data) {
  if (!validatePresent(data['first_name'], 'First Name')) {
    return false;
  }
  if (!validatePresent(data['last_name'], 'Last Name')) {
    return false;
  }
  if (!validatePresent(data['street_address'], 'Street Address')) {
    return false;
  }
  if (!validatePresent(data['locality'], 'City')) {
    return false;
  }
  if (!validatePresent(data['region'], 'State')) {
    return false;
  }
  if (!validatePresent(data['postal_code'], 'Zip Code')) {
    return false;
  }
  return true;
}

//todo: factor this over to fairpayapi.js
function validatePresent(value, field_description) {
  //console.log('validatePresent - value: ' + value + ', desc: ' + field_description);
  if (value == undefined || value == null || value.length == 0) {
    showError("Please enter " + field_description);
    return false;
  } else {
    return true;
  }
}

function field_val(name, default_value) {
  var field_spec = 'input[name="' + name + '"]';
  var raw = $(field_spec).val(); // confirm if this statement is always safe
  //alert(name + " raw val: " + raw);
  var val = raw ? raw : default_value;
  //alert(name + " val: " + val);
  return val;
}
