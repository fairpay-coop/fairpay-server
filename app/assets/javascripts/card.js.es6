//'use strict';
//
//var Card = {
//
//    registerHooks: function() {
//        //alert('registerHooks');
//        // using js6 fat arrow function declaration to bind to the correct this
//        $(".recalc").change(() => this.updateCardInfo());
//    },
//
//    updateCardInfo: function() {
//        //alert('updateCardInfo');
//        var cardForm = document.getElementById("step2_form");
//        var card = cardForm.elements["card_number"].value;
//        var amount = cardForm.elements["amount"].value;
//        var embed_uuid = cardForm.elements["embed_uuid"].value;
//
//        var bin = card.slice(0, 6);
//        var url = "/api/v1/embed/" + embed_uuid + "/estimate_fee?payment_type=card&bin=" + bin + '&amount=' + amount;
//        //alert("url: " + url);
//
//        $.ajax({
//            url: url,
//            context: document.body,
//            success: function(info) {
//                if (info) {
//                    //alert("info: " + JSON.stringify(info));
//
//                    var bindata = "<b>Information about your card</b>: <br>&nbsp; &nbsp;" + info.card_brand + ", " + info.card_type + ", " + info.card_category +
//                        ", " + info.issuing_org + ", " + (info.is_regulated ? "regulated bank" : "unregulated bank") + "";
//                    bindata += "<br>Transaction fee for this card: <b>$" + info.estimated_fee + "</b>";
//                    bindata += "<br>&nbsp; &nbsp;" + info.fee_tip;
//                    var infoDiv = document.getElementById("card_info");
//                    $("#card_info").html(bindata);
//                } else {
//                    console.log("info not found for bin: " + card);
//                    $("#card_info").html("<br><br>");
//                }
//            }
//        });
//    }
//
//}
//
////module.exports = Card;
