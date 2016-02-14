
// beware: copy of the old seedapi.js, not yet migrated, and will probably want to completely rework to use an iframe


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

        function submitStep1(data, successHandler) {
            var embedUuid = data.embed_uuid ? data.embed_uuid : getEmbedUuid();
            var uri = '/api/v1/embed/' + embedUuid + '/step1';
            invoke(uri, data, successHandler);
        }

        function submitStep2(data, successHandler) {
            var uri = '/api/v1/embed/' + data.embed_uuid + '/step2';
            invoke(uri, data, successHandler);
        }

        function estimateFee(data, successHandler) {
            var uri = '/api/v1/embed/' + data.embed_uuid + '/estimate_fee';
            invoke(uri, data, successHandler);
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


        function invoke(uri, data, successHandler) {
            var url = endpoint + uri;
            data.apiKey = apiKey;
            $.ajax({
                url: url
                , dataType: 'jsonp'
                , data: data
                , success: successHandler
                , error: function (xhr, status, error) {
                    alert(status)
                }
            });
        }

        function formValue(form, field) {
            return form.elements[field].value;
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
            submitStep1: submitStep1,
            submitStep2: submitStep2,
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


