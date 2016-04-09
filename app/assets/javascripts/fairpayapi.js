var FairPayApiSinglton = (function() {

    var instance;

    function init() {

        //note: assumes a block like this is included subsequent to this library being loaded
        //FairPayApi.setEndpoint('http://localhost:8000');
        //FairPayApi.setApiKey('w4l');
        //FairPayApi.setEmbedUuid('VJ7iA5cQg');

        // for the moment, assume same api and embed share same host
        var endpoint = '';
        var apiKey = 'dummy';
        var embedUuid;  // the default embed to use
        var base_uri = '/api/v1/embeds/';


        function launchPaymentFlow(amount, offer_uuid, return_url) {
            var embedUuid = data.embed_uuid ? data.embed_uuid : getEmbedUuid();
            var paymentUrl = '/pay/' + embedUuid + '?amount=' + amount + '&offer=' + offer_uuid + '&return_url=' + return_url;
            window.location = paymentUrl;
            //var uri = base_uri + embedUuid + '/campaign_status';
            //invoke(uri, data, successHandler);
        }

        function embedData(data, successHandler) {
            var embedUuid = data.embed_uuid ? data.embed_uuid : getEmbedUuid();
            var uri = base_uri + embedUuid + '/embed_data';
            invoke(uri, 'GET', data, successHandler);
        }

        function step2Data(data, successHandler) {
            var embedUuid = data.embed_uuid ? data.embed_uuid : getEmbedUuid();
            var uri = base_uri + embedUuid + '/step2_data';
            invoke(uri, 'GET', data, successHandler);
        }

        function campaignStatus(data, successHandler) {
            var embedUuid = data.embed_uuid ? data.embed_uuid : getEmbedUuid();
            var uri = base_uri + embedUuid + '/campaign_status';
            invoke(uri, 'GET', data, successHandler);
        }

        function submitStep1(data, successHandler) {
            var embedUuid = data.embed_uuid ? data.embed_uuid : getEmbedUuid();
            var uri = base_uri + embedUuid + '/submit_step1';
            invoke(uri, 'POST', data, successHandler);
        }

        function submitAddress(data, successHandler) {
            console.log('app/assets/javascripts/fairpayapi - submit addr data: ' + JSON.stringify(data));
            var uri = base_uri + data.embed_uuid + '/submit_address';
            invoke(uri, 'POST', data, successHandler);
        }

        function submitPayment(data, successHandler) {
            var uri = base_uri + data.embed_uuid + '/submit_payment';
            invoke(uri, 'POST', data, successHandler);
        }

        // todo: consider using a generate update_transaction
        function updateFeeAllocation(data, successHandler) {
            var uri = base_uri + data.embed_uuid + '/update_fee_allocation';
            invoke(uri, 'POST',  data, successHandler);
        }

        function sendDwollaInfo(data, successHandler) {
            var uri = base_uri + data.embed_uuid + '/send_dwolla_info';
            invoke(uri, 'POST', data, successHandler);
        }

        function estimateFee(data, successHandler) {
            var embedUuid = data.embed_uuid ? data.embed_uuid : getEmbedUuid();
            delete data.embed_uuid;
            var uri = base_uri + embedUuid + '/estimate_fee';
            invoke(uri, 'GET', data, successHandler);
        }

        //function joinMailingList(data, successHandler) {
        //    var campaignId = data.capaignId ? data.campaignId : getCampaignId();
        //    var uri = '/api/v1/campaign/' + campaignId + '/mailingList.join';
        //    invoke(uri, data, successHandler);
        //}
        //
        //function fetchContributionStatus(data, successHandler) {
        //    var uri = '/api/v1/contribution/' + data.contributionId + '/status';
        //    invoke(uri, data, successHandler);
        //}
        //
        //function endRecurringContribution(data, successHandler) {
        //    var uri = '/api/v1/contribution/' + data.contributionId + '/endRecurring';
        //    invoke(uri, data, successHandler);
        //}
        //
        //function fetchCampaignStatus(data, successHandler) {
        //    var campaignId = data.capaignId ? data.campaignId : getCampaignId();
        //    var uri = '/api/v1/campaign/' + campaignId + '/status';
        //    invoke(uri, data, successHandler);
        //}


        function invoke(uri, type, data, successHandler) {
            var url = endpoint + uri + ".jsonp";
            data.apiKey = apiKey;
            $.ajax({
                url: url
                , type: type
                , dataType: 'jsonp'
                , data: data
                , success: successHandler
                //, error: successHandler
                , error: function (xhr, status, error) {
                    alert(status)
                }
            });
        }

        function formValue(form, field) {
            field = form.elements[field];
            if (field) {
                if (field.type == 'checkbox') {
                    return field.checked;
                } else {
                    return field.value;
                }
            } else {
                return null
            }
        }

        function copyFormValues(data, form, fields) {
            for (i = 0; i < fields.length; i++) {
                data[fields[i]] = formValue(form, fields[i]);
            }
        }

        function getParameterByName(name) {
            var match = RegExp('[?&]' + name + '=([^&]*)').exec(window.location.search);
            return match && decodeURIComponent(match[1].replace(/\+/g, ' '));
        }


        function setEndpoint(s) {
            endpoint = s;
        }

        function setApiKey(s) {
            apiKey = s;
        }

        function setEmbedUuid(s) {
            embedUuid = s;
        }

        function getEmbedUuid() {
            return embedUuid;
        }

        return {
            launchPaymentFlow: launchPaymentFlow,
            embedData: embedData,
            step2Data: step2Data,
            campaignStatus: campaignStatus,
            submitStep1: submitStep1,
            submitAddress: submitAddress,
            submitPayment: submitPayment,
            updateFeeAllocation: updateFeeAllocation,
            sendDwollaInfo: sendDwollaInfo,
            estimateFee: estimateFee,
            //joinMailingList: joinMailingList,
            //fetchContributionStatus: fetchContributionStatus,
            //endRecurringContribution: endRecurringContribution,
            //fetchCampaignStatus: fetchCampaignStatus,
            invoke: invoke,
            copyFormValues: copyFormValues,
            formValue: formValue,
            getParameterByName: getParameterByName,
            setEndpoint: setEndpoint,
            setApiKey: setApiKey,
            setEmbedUuid: setEmbedUuid,
            getEmbedUuid: getEmbedUuid
        };
    }

    return {
        getInstance: function() {
            "use strict";
            if (!instance) {
                instance = init();
            }
            return instance;
        }
    };

})();

var FairPayApi = FairPayApiSinglton.getInstance();
window.FairPayApi = FairPayApi;


