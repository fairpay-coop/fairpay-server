
//FairPayApi.setEndpoint('http://localhost:3000');
//FairPayApi.setApiKey('abuntoo');
//FairPayApi.setEmbedUuid('VJ7iA5cQg');

function handleSignin() {
  var data = {};
  var form = document.getElementById("step1_form");
  FairPayApi.copyFormValues(data, form, ['email', 'password']);
  if (validateSigninData(data)) {
    FairPayApi.signin(data, handleSigninResponse);
  }
  return false;
}

function handleSigninResponse(data) {
  console.log('signin response: ' + JSON.stringify(data));
  if (data.result) {
    var token = data.result;
    //document.getElementById('auth_token');
    $("#auth_token").val(token);
    $("#password_block").hide();
    FairPayApi.profile(token, handleProfileResponse);
  } else if (data.error) {
    showError(data.error.message);
  }
}

function handleProfileResponse(data) {
  console.log('profile response: ' + JSON.stringify(data));
  if (data.result) {
    console.log('name: ' + data.result.name);
    $("#name").val(data.result.name);
  } else if (data.error) {
    showError(data.error.message);
  }
}

function handleStep1() {
  console.log("handleStep1");
  var data = {};
  var form = document.getElementById("step1_form");
  FairPayApi.copyFormValues(data, form, ['embed_uuid', 'name', 'email', 'recurrence', 'mailing_list', 'description', 'memo', 'return_url', 'correlation_id', 'auth_token']);
  data.amount = resolveAmount();
  data.offer_uuid = resolveOfferUuid();
  //alert('data: ' + JSON.stringify(data));

  if (validateStep1Data(data)) {
    console.log('beforfe submitStep1');
    FairPayApi.submitStep1(data, handleStep1Response);
  }
  return false;
}

function handleStep1Response(data) {
  console.log('step1 response: ' + JSON.stringify(data));
  if (data.result) {
    //var status = data.result.status;
    //$('#errorMessage').html('');      //var linkUrl = data.result.statusLink;
    var authenticated_email = $("#authenticated_email").val();
    console.log("authenticated email: " + authenticated_email);
    if (authenticated_email == '') {
      console.log("signin needed");
      window.signin();
    } else if (data.result.next_step_url) {
      window.location = data.result.next_step_url;
    }
  } else if (data.error) {
    showError(data.error.message);
  }
}

function showError(message, elt) {
  if (elt) {
    $(elt).notify(message, {className: "error", autoHideDelay: 2000, showDuration:100, position: "right"});
  } else {
    $.notify(message, {className: "error", autoHideDelay: 2000, showDuration:100 });
  }
}

function hideError(message) {
  $('#errorMessage').hide();
  $('#errorMessage').html('');
}

function resolveAmount() {
  var amount = $( "#donateSelectBox" ).val();
  console.log("select box amount: " + amount);
  if (amount && amount > 0) {
    return amount;
  }

  var assigned_amount = number_field_val('assigned_amount');
  var entered_amount = number_field_val('entered_amount');
  var amount_chosen_count = $("input[name=chosen_amount]:checked").length;
  var chosen_amount = $("input[name=chosen_amount]:checked").val();
  //if (amount_chosen_count > 0) {
  //  alert("chosen_amount: " + chosen_amount);
  //}
  if (assigned_amount > 0) {
    return assigned_amount;
  } else if (entered_amount > 0) {
    return entered_amount;
  } else if (amount_chosen_count > 0) {
    return chosen_amount;
  } else {
    return 0;
  }
}

function resolveOfferUuid() {
  var chosens = []
  $("input[name=chosen_offer_uuid]:checked").each( function(idx,elt){
    chosens.push($(elt).val())
  });

  if (chosens.length == 0) {
    var assignedUuid = field_val('assigned_offer_uuid', null);
    if (assignedUuid) {
      chosens.push();
    }
  }

  return chosens.join();
}

function validateStep1Data(data) {
  if (data['amount'] == 0) {
    showError("Please enter an amount", $('#donateSelectBox'));
    return false;
  }

  if (data['amount'] < minimumAmount()) {
    showError("Please enter at least the minimum donation.", $('#donateSelectBox'));
    return false;
  }

  if (data['offer_uuid'].length == 0 && !$('#chosen_offer_none')[0].checked) {
    showError("Please pick a gift or select 'no gift'.");
    return false;
  }

  //if (!validatePresent(data['email'], 'an Email')) {
  //  return false;
  //}
  return true;
}

function validateSigninData(data) {
  if (!validatePresent(data['email'], 'an Email')) {
    return false;
  }
  if (!validatePresent(data['password'], 'a Password')) {
    return false;
  }
  return true;
}
//todo: factor this over to fairpayapi.js
function validatePresent(value, field_description) {
  if (value == undefined || value == null || value.length == 0) {
    showError("Please enter " + field_description);
    return false;
  } else {
    return true;
  }
}

//function validateStep1Form() {
//  var assigned_amount = number_field_val('assigned_amount');
//  var entered_amount = number_field_val('entered_amount');
//  var amount_chosen_count = $("input[name=chosen_amount]:checked").length;
//  //var amount = $('#step1Amount').val();
//  //if (amount_chosen == 0 && (amount == null || amount == "")) {
//  //  alert("Please enter an amount");
//  //  return false;
//  //}
//  if (assigned_amount == 0 && entered_amount == 0 && amount_chosen_count == 0) {
//    alert("Please enter an amount");
//    return false;
//  }
//  var email = $('#email').val();
//  if (email == null || email == "") {
//    alert("Please enter an email");
//    return false;
//  }
//  return true;
//}

function number_field_val(name) {
  return Number(field_val(name, 0));
}

function field_val(name, default_value) {
  var field_spec = 'input[name="' + name + '"]';
  var raw = $(field_spec).val(); // confirm if this statement is always safe
  //alert(name + " raw val: " + raw);
  var val = raw ? raw : default_value;
  //alert(name + " val: " + val);
  return val;
}

function formatAmount(amount, decimals) {
  decimals = decimals || 2;
  return format("$%." + decimals + "f", amount);
}


function minimumAmount() {
  var no_gift_cb = $('#chosen_offer_none');
  var minimumAmount = 0;
  if ( !no_gift_cb[0].checked)  {
    $('.offer').each(function(idx, elt) {
      if (elt.checked) {
        minimumAmount += $(elt).data('min-contrib');
      }
    })
  }
  if (minimumAmount == 0 ) {
    minimumAmount = no_gift_cb.data('min-contrib');
  }

  return minimumAmount;
}

function updateContribution() {
  $('#minimumDonation').text(formatAmount(minimumAmount()));
//    var donateSelectBox = $('#donateSelectBox');
//    if (donateSelectBox.val() < minimumAmount) {
//      donateSelectBox.val(minimumAmount);
//    }
}

