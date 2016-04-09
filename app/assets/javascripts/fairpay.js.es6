(function (global) {


    var panes = [];
    var tabs = [];
    var store;
    var templates;


    //
    // Extensions
    //

    Array.prototype.last = function () {
        return this[this.length - 1];
    };

    Array.prototype.first = function () {
        return this[0];
    };

    //
    // Resource loading helpers
    //

    function loadScripts(srcs) {
        return Promise.all(srcs.map(src => loadScript(src)));
    }

    function loadScript(src) {
        return new Promise((resolve, reject) => {
            var script_tag = document.createElement('script');
            script_tag.setAttribute("type", "text/javascript");
            script_tag.setAttribute("src", src);

            if (script_tag.readyState) {
                script_tag.onreadystatechange = () => {
                    if (this.readyState == 'complete' || this.readyState == 'loaded') {
                        console.log(src + " Loaded");
                        resolve(src);
                    } else {
                        reject(this.readyState);
                    }
                };
            } else {
                script_tag.onload = () => {
                    console.log(src + " Loaded");
                    resolve(src)
                };
            }
            (document.getElementsByTagName("head")[0] || document.documentElement).appendChild(script_tag);
        });
    }

    function loadCss(href) {
        return new Promise((resolve, reject) => {
            var link_tag = document.createElement('link');
            link_tag.setAttribute("type", "text/css");
            link_tag.setAttribute("rel", "stylesheet");
            link_tag.setAttribute("href", href);
            (document.getElementsByTagName("head")[0] || document.documentElement).appendChild(link_tag);
            resolve();
        });
    }


    function loadFiles(urls) {
        return Promise.all(urls.map(url => get(url)));
    }

    //
    // Network op helpers
    //

    function get(url) {
        return new Promise((resolve, reject) => {
            var request = new XMLHttpRequest();
            url = url + (-1 === url.indexOf('?') ? '?' : '&') + "_=" + Number(new Date());
            request.open('GET', url, true);

            request.onload = (evt) => {
                let res = evt.target;
                if (res.status >= 200 && res.status < 400) {
                    // Success!
                    resolve(res.response);
                } else {
                    reject(res.status);
                }
            };

            request.onerror = (evt) => {
                reject(evt.target.status);
            };

            request.send();
        });
    }

    function post(url, data) {
        return new Promise((resolve, reject) => {
            var request = new XMLHttpRequest();
            request.open('POST', url, true);

            request.onload = (evt) => {
                let res = evt.target;
                if (res.status >= 200 && res.status < 400) {
                    // Success!
                    resolve(res.response);
                } else {
                    reject(res.status);
                }
            };

            request.onerror = (evt) => {
                reject(evt.target.status);
            };

            request.setRequestHeader('Content-Type', 'application/json; charset=UTF-8');
            request.send(JSON.stringify(data));
        });
    }

    //
    // DOM helpers
    //

    function hide(el) {
        if (el) el.style.display = 'none';
    }

    function show(el) {
        if (el) el.style.display = '';
    }

    function addClass(el, className) {
        if (el) el.classList.add(className);
    }

    function removeClass(el, className) {
        if (el) el.classList.remove(className);
    }

    function enable(el) {
        if (el) el.disabled = false;
    }

    function disable(el) {
        if (el) el.disabled = true;
    }

    //
    // Misc helpers
    //

    function parseQuery(query) {
        var params = {};
        if (!query) return params; // return empty object
        var Pairs = query.split(/[;&]/);
        for (var i = 0; i < Pairs.length; i++) {
            var KeyVal = Pairs[i].split('=');
            if (!KeyVal || KeyVal.length != 2) continue;
            var key = unescape(KeyVal[0]);
            var val = unescape(KeyVal[1]);
            val = val.replace(/\+/g, ' ');
            params[key] = val;
        }
        return params;
    }


    function getParams(script) {
        var queryString = script.src.replace(/^[^\?]+\??/, '');

        var params = parseQuery(queryString);

        var re = /^(.*:)\/\/([A-Za-z0-9\-\.]+)(:[0-9]+)?(.*)$/;
        var matches = script.src.match(re);
        params['host'] = matches[1] + '//' + matches[2] + matches[3];
        return params;
    }

    function myself() {
        var scripts = document.getElementsByTagName('script');
        return scripts[scripts.length - 1];
    }


    function render(template, data) {
        return doT.template(template)(data);
    }


    function togglePane(tabList, paneList, paneIdx) {
        console.log(`toggling pane:${paneIdx} of ${paneList}`)
        paneList.forEach((pane, index) => {
            if (index == paneIdx) {
                show(paneList[index]);
                addClass(tabList[index], 'selected')
            } else {
                hide(paneList[index]);
                removeClass(tabList[index], 'selected')
            }
        });
    }

    function $(selector) {
        let result = Array.from(document.querySelectorAll(selector));
        //
        switch (result.length) {
            case 0:
                return null;
            default:
                return result[0];
        }
        //     case 1:
        //         return new Proxy(result[0], {
        //             apply: function(target, thisArg, argumentsList) {
        //             }
        //         });
        //     default:
        //         return result;
        // }
    }

    function $$(selector) {
        return Array.from(document.querySelectorAll(selector));
        //
        // switch (result.length) {
        //     case 0:
        //         return null;
        //     case 1:
        //         return new Proxy(result[0], {
        //             apply: function(target, thisArg, argumentsList) {
        //             }
        //         });
        //     default:
        //         return result;
        // }
    }

    function initLocalStorage(params) {
        return new Promise((resolve, reject) => {
            xdLocalStorage.init(
                {
                    iframeUrl: `${params['host']}/iframe`,
                    initCallback: () => {
                        console.log('Got iframe ready');
                        resolve();
                    }
                }
            );
        });
    }


    function getLocalData() {
        return new Promise((resolve, reject) => {
            xdLocalStorage.getItem('email', data => resolve({email: data.value}));
        });
    }


    function init(me, params) {

        let config = {};
        let localData = {};
        get(`${params['host']}/api/v1/embeds/${params['uuid']}/embed_data`)
            .then(data => config = JSON.parse(data).result)
            .then(() => getLocalData())
            .then((data) => {
                localData = data;
                return loadFiles([`${params['host']}/fairplay.dot`, `${params['host']}/recap.dot`]);
            })
            .then((result) => {
                
                templates = result;
                if (params.amount) {
                    config = Object.assign(config, {suggested_amounts: [params.amount]})
                }


                // format the amounts
                Object.assign(config, {
                    localizedAmounts: config.suggested_amounts.map((amount) => {
                        if (-1 == amount) {
                            return -1;
                        } else {
                            return config.currency_format.replace('{0}', amount);
                        }
                    })
                });

                store = Object.assign({}, {config, params, localData});

                // render the template and insert it after the script tag
                let html = render(templates[0], store.config);
                me.insertAdjacentHTML('afterend', html);

                // panes
                panes = $$('.fpPane'); // get all the panes

                // tabs
                let tabsStatus = {};
                tabs = $$('.fpTab'); // get all the tabs
                tabs.forEach((tab) => {
                    tab.addEventListener('click', (evt) => {
                        if (tabsStatus[tab.id] === 'enabled') {
                            togglePane(tabs, panes, tab.dataset.pane);
                        }
                    });
                    tabsStatus[tab.id] = 'disabled';
                });
                tabsStatus['fpTab_0'] = 'enabled';
                togglePane(tabs, panes, 0);
                // togglePane(tabs, panes, 2);

                // disable all the 'continue' buttons
                $$('.fpContinue').forEach(el => disable(el));


                //
                // Pane 1: amount + email
                //

                // hide custom amount
                let customAmountInput = $('.fpCustom-amount');
                hide(customAmountInput);


                // handle amount changes
                let amountButtons = $$('input[name=fpAmount]');
                if (amountButtons.length > 0) {
                    amountButtons[0].checked = true;
                    amountButtons.forEach((button) => {
                        button.addEventListener('click', (evt) => {
                            if (evt.target.id === 'fp_other') {
                                show(customAmountInput);
                            } else {
                                hide(customAmountInput);
                            }
                        })
                    });
                }

                let continueButton = $('#fpContinueAmountPane');

                // setup email
                let emailInput = $('#fpEmail');

                if (store.localData.email) {
                    emailInput.value = store.localData.email;
                    enable(continueButton);
                }
                emailInput.addEventListener('input', (evt) => {
                    if (evt.target.checkValidity()) {
                        enable(continueButton);
                    } else {
                        disable(continueButton);
                    }
                });

                // handle continue
                continueButton.addEventListener('click', (evt) => {
                    let amount = 0;
                    if (store.config.suggested_amounts.length == 1) {
                        amount = store.config.suggested_amounts[0];
                    } else {
                        amount = $('input[name=fpAmount]:checked').value;
                        if (amount === "other") {
                            amount = $('.fpCustom-amount').value
                        }
                    }

                    let email = $('#fpEmail').value;

                    // store email in local storage
                    xdLocalStorage.setItem('email', email, (data) => {
                        console.log('email saved')
                    });


                    post(`${store.params['host']}/api/v1/embeds/${store.params['uuid']}/submit_step1`, {email, amount})
                        .then((data) => {
                            console.log(data);
                            const state = JSON.parse(data).result;
                            store = Object.assign(store, {state});
                            tabsStatus['fpTab_2'] = 'enabled';
                            updateCurrentPayment(store);
                            updateFees();
                            updateDwolla();
                            togglePane(tabs, panes, 2);
                        });
                    // .catch((error) => console.log(`error:${error}`)); TODO: uncomment and handle better
                });


                // Pane 2: identity


                // Pane 3: Payment

                // handle payment type changes
                let paymentTypeButtons = $$('input[name=fpPaymentType]');
                paymentTypeButtons[0].checked = true;
                paymentTypeButtons.forEach((button) => {
                    button.addEventListener('click', (evt) => {
                        updateCurrentPayment();
                    })
                });

                // Dwolla
                setupDwolla();

                // Paypal

                // Authorize.net
                setupAuthorizenet();

            });
        // .catch(error => console.log(`Error in init:${error}`)); TODO: uncomment and handle better
    }


    function validateForm(inputs, button) {
        inputs.forEach( input => {
            if (input.checkValidity()) {
                enable(button);
            } else {
                disable(button);
            }
        })
    }



    function setupAuthorizenet() {
        // form validation
        const authorizenetPayButton = $('#fpPayWithAuthorizenet');
        $$('input.fpAuthorizenet').forEach(input => {
            input.addEventListener('input', evt => {
                validateForm([evt.target], authorizenetPayButton);

                if (evt.target.id === "fpCardNumber") {
                    const bin = evt.target.value.slice(0, 6);
                    const amount = store.state.transaction.base_amount;

                    get(`${store.params['host']}/api/v1/embeds/${store.params['uuid']}/estimate_fee?bin=${bin}&amount=${amount}`)
                        .then((data) => {
                            const result = JSON.parse(data).result;
                            const paymentConfig = getPaymentConfig(store, 'authorizenet');
                            paymentConfig.card_fee_str = result.fee_str === "unknown" ? result.estimated_fee : result.fee_str;
                            updateFees();
                        });
                    // .catch((error) => console.log(`error:${error}`)); TODO: uncomment and handle better
                }

            });
        });
        validateForm($$('input.fpAuthorizenet'), authorizenetPayButton);


        // pay button
        authorizenetPayButton.addEventListener('click', (evt) => {
            const url = `${store.params['host']}/api/v1/embeds/${store.params['uuid']}/submit_payment`;
            const data = {
                transaction_uuid: store.state.transaction.uuid,
                payment_type: 'authorizenet',
                card_number: $('#fpCardNumber').value,
                card_mmyy: $('#fpCardExp').value,
                card_cvv: $('#fpCardCVV').value,
                billing_zip: $('#fpCardZip').value
            };
            post(url, data)
                .then(data => {
                    console.log(data);
                    const paymentState = JSON.parse(data).result;
                    store = Object.assign(store, {paymentState});
                    renderRecap();
                    togglePane(tabs, panes, 3);
                });
                // .catch((error) => console.log(`error:${error}`)); TODO: uncomment and handle better
        });



    }

    function setupDwolla() {
        $('#fpDowlla-authorize').addEventListener('click', (evt) => {
            let url = `${store.params['host']}/dwolla/auth?t=${store.state.transaction.uuid}&o=widget`;
            let authorizeWindow = window.open(url, "_blank", "width=500, height=550");
            let interval = window.setInterval(() => {
                if (authorizeWindow == null || authorizeWindow.closed) {
                    window.clearInterval(interval);
                    get(`${store.params['host']}/api/v1/embeds/${store.params['uuid']}/step2_data?transaction_uuid=${store.state.transaction.uuid}`)
                        .then((data) => {
                            console.log(data);
                            const state = JSON.parse(data).result;
                            store = Object.assign(store, {state});
                            updateDwolla();
                        });
                    
                }
            }, 1000);
        });


        $('#fpDowlla-pay').addEventListener('click', (evt) => {
            const url = `${store.params['host']}/api/v1/embeds/${store.params['uuid']}/send_dwolla_info`
            const data = {
                transaction_uuid: store.state.transaction.uuid,
            };
            post(url, data)
                .then(data => {
                    console.log(data);
                    const paymentState = JSON.parse(data).result;
                    store = Object.assign(store, {paymentState});
                    renderRecap();
                    togglePane(tabs, panes, 3);
                });
            // .catch((error) => console.log(`error:${error}`)); TODO: uncomment and handle better


        })
        
    }

    function renderRecap() {
        $("#fpRecapPane").innerHTML = render(templates[1], store);
    }
    
    
    function updateFees() {
        store.state.payment_configs.forEach(p => {
            $(`#fp_paymentFees_${p.kind}`).textContent = `Fees: ${p.card_fee_str}`;
        });
    }


    function updateDwolla() {
        $$('.fpDwolla-pane').forEach(el => hide(el));
        if (getPaymentConfig('dwolla').has_dwolla_auth) {
            show($('#fpDowlla-pane-pay'))
        } else {
            show($('#fpDowlla-pane-authorize'))
        }
    }

    function getPaymentConfig(paymentKind) {
        return store.state.payment_configs
            ? store.state.payment_configs.find(p => p.kind === paymentKind)
            : null;
    }

    function updateCurrentPayment() {
        let paymentType = $('input[name=fpPaymentType]:checked').value;
        $$(".fpPayment-pane").forEach(el => hide(el));
        show($(`#fpPayment-pane-${paymentType}`));
    }

    console.log("Widget loader loaded");

    var me = myself();
    var params = getParams(me);
    console.log(JSON.stringify(params));


    loadScripts([`${params['host']}/xdLocalStorage.js`,
        // `${params['host']}/picoModal.js`,
        // `${params['host']}/microlib-tabs.js`,
        `${params['host']}/doT.js`])
        .then(() => loadCss(`${params['host']}/fairway.css`))
        .then(() => initLocalStorage(params))
        .then(() => init(me, params));
        // .catch((error) => console.log(`error:${error}`)); TODO: uncomment and handle better

})(window);