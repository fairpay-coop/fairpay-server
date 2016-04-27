//$("#dwolla_form").submit(handleDwollaPayment);

function handleDwollaPayment() {
  //alert('handleCard');
  var form = document.getElementById("dwolla_form");
  var data = {};
  FairPayApi.copyFormValues(data, form, ['embed_uuid', 'transaction_uuid', 'payment_type', 'amount', 'funding_source_id']);
  console.log('dwolla submit data: ' + JSON.stringify(data));
  //if (validateDwollaData(data)) {
  if (validateDwollaForm()) {
    FairPayApi.submitPayment(data, handleDwollaPaymentResponse);
  }
  return false;
}

function handleDwollaPaymentResponse(data) {
  console.log('dwolla payment response: ' + JSON.stringify(data));
  if (data.result) {
    var status = data.result.status;
    console.log('payment status: ' + status);
    //$('#paymentStatus').html(status);
    //$('#errorMessage').html('');      //var linkUrl = data.result.statusLink;
    //var linkHtml = '<a href="' + linkUrl + '">' + linkUrl + '</a>';
    //$('#statusLink').html(linkHtml);
    if (data.result.redirect_url) {
      window.location = data.result.redirect_url;
    }
  } else if (data.error) {
    alert('error resp: ' + JSON.stringify(data.error));
    //$('#paymentStatus').html('error');
    //$('#errorMessage').html(data.error.message);
    //$('#errorStack').html('<pre>' + data.error.stack + '</pre>');
  }
}

function updateDwollaChoices(dwolla_user) {
  //alert('handleCard');
  if (dwolla_user == 'true') {
    $("#dwolla_auth").show();
    $("#dwolla_send_more_info").hide();
  } else {
    $("#dwolla_auth").hide();
    $("#dwolla_send_more_info").show();
  }
}

function sendDwollaInfo() {
  var form = document.getElementById("dwolla_user_form");
  var data = {};
  FairPayApi.copyFormValues(data, form, ['embed_uuid', 'transaction_uuid']);
  //alert('data: ' + JSON.stringify(data));
  FairPayApi.sendDwollaInfo(data, handleSendDwollaInfoResponse);
  return false;
}

function handleSendDwollaInfoResponse(data) {
  //alert('handleSendDwollaInfoResponse: ' + JSON.stringify(data));
}

function validateDwollaForm() {
  var count = $("input[name=funding_source_id]:checked").length;
  //var funding_source_id = $("#dwolla_form input[type='radio']:checked").val();
  //var funding_source_id = $("#input[name=funding_source_id]:checked", '#dwolla_form').val();
  //alert("funding id: " + funding_source_id);

  if (count == 0) {
    alert("Please select a Funding Source");
    return false;
  } else {
    return true;
  }
}

function handleSigninDwolla() {
  var email = $("#email_dwolla").val();
  var password = $("#password_dwolla").val();
  var data = {email: email, password: password};
  console.log("handleSigninDwolla - data: " + JSON.stringify(data));
  FairPayApi.signin(data, handleSigninResponseDwolla);
  return false;
}

function handleSigninResponseDwolla(data) {
  console.log('signin response: ' + JSON.stringify(data));
  if (data.result) {
    var embed_uuid = $("#embed_uuid").val();
    var transaction_uuid = $("#transaction_uuid").val();
    var auth_token = data.result;
    var param_data = {embed_uuid: embed_uuid, transaction_uuid: transaction_uuid, auth_token: auth_token};
    console.log("update auth token params: " + JSON.stringify(param_data));
    //$("#password_block").hide();
    FairPayApi.updateAuthToken(param_data, handleUpdateAuthTokenDwollaResponse);
  } else if (data.error) {
    //showError(data.error.message);
    alert("error: " + data.error.message);
  }
}

function handleUpdateAuthTokenDwollaResponse(data) {
  console.log('handleUpdateAuthTokenDwollaResponse response: ' + JSON.stringify(data));
  if (data.result) {

    if (data.result.redirect_url) {
      console.log("next step url: " + data.result.redirect_url);
      window.location = data.result.redirect_url;
    }
  } else if (data.error) {
    //showError(data.error.message);
    alert("error: " + data.error.message);
  }
}