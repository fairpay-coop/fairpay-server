'use strict';

var Widget = {

    channel: null,

    onAuthCompleteLoaded: function() {
        this.createChannel('popup');
        this.channel.call({method: "auth_complete",
            success: res => console.log(res)});
    },

    onCapturePaymentLoaded: function(fees, payment_type) {
        $("#card_number").change(() => this.updateCardInfo());

        $(".payments li").each((idx, el) => {
            console.log(el);
            $(el).click((evt) => {
                this.toggleTab($(el).data('type'));
            });
        });

        this.toggleTab(payment_type);
        this.updateFees(fees);

        $("#dwolla_auth_link").click((evt) => {
            evt.preventDefault();
            this.channel.call({method: "popup",
                params: $(evt.target).attr('href'),
                success: res => console.log(res)});
        });

        this.createChannel('widget');
    },

    createChannel: function(scope) {
        this.channel = Channel.build({window: window.parent,
            origin: "*",
            debugOutput: 1,
            scope: scope,
            onReady: function() {
                console.log("channel " + scope + " is ready!");
            }});
    },


    toggleTab: function(tab) {
        console.log("toggle to:" + tab);
        $(".payments li").each((idx, el) => {
            if ($(el).hasClass(tab) ) {
                $(el).addClass('is-active');
            } else {
                $(el).removeClass('is-active');
            }
        });
        $(".panels div").each((idx, el) => {
            $(el).toggle($(el).hasClass(tab));
        });

    },

    updateFees: function(fees) {
        for (let key in fees) {
            $("li." + key + " span.fee" ).text("Fees: " + fees[key]);
        }
    },

    capitalize: function(string) {
        return string.charAt(0).toUpperCase() + string.slice(1);
    },

    updateCardInfo: function() {
        //alert('updateCardInfo');
        var cardForm = document.getElementById("capture_payment");
        var card = cardForm.elements["card_number"].value;
        var amount = cardForm.elements["amount"].value;
        var embed_uuid = cardForm.elements["embed_uuid"].value;

        var bin = card.slice(0, 6);
        var url = "/api/v1/embed/" + embed_uuid + "/estimate_fee?payment_type=card&bin=" + bin + '&amount=' + amount;
        //alert("url: " + url);

        $.ajax({
            url: url,
            context: document.body,
            success: (info) => {
                if (info) {
                    console.log("info: " + JSON.stringify(info));

                    var bindata = "<b>Information about your card</b>: <br>&nbsp; &nbsp;" + info.card_brand + ", " + info.card_type + ", " + info.card_category +
                        ", " + info.issuing_org + ", " + (info.is_regulated ? "regulated bank" : "unregulated bank") + "";
                    bindata += "<br>Transaction fee for this card: <b>$" + info.estimated_fee + "</b>";
                    bindata += "<br>&nbsp; &nbsp;" + info.fee_tip;
                    var infoDiv = document.getElementById("card_info");
                    $("#card_info_body").html(bindata);

                    if (info.result.estimated_fee) {
                        this.updateFees({'card': info.result.estimated_fee});
                    }

                } else {
                    console.log("info not found for bin: " + card);
                }
            }
        });
    }

}

//module.exports = Card;
