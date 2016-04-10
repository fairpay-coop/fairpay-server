(function (global) {

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

    function $(selector) {
        const result = $$(selector);
        return result.length == 0 ? null : result[0];
    }

    function $$(selector) {
        return Array.from(document.querySelectorAll(selector));
    }

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
        let params = {};
        if (!query) return params; // return empty object
        var Pairs = query.split(/[;&]/);
        for (let i = 0; i < Pairs.length; i++) {
            const KeyVal = Pairs[i].split('=');
            if (!KeyVal || KeyVal.length != 2) continue;
            let key = unescape(KeyVal[0]);
            let val = unescape(KeyVal[1]);
            val = val.replace(/\+/g, ' ');
            params[key] = val;
        }
        return params;
    }

    function getParams(script) {
        const queryString = script.src.replace(/^[^\?]+\??/, '');
        let params = parseQuery(queryString);
        const re = /^(.*:)\/\/([A-Za-z0-9\-\.]+)(:[0-9]+)?(.*)$/;
        const matches = script.src.match(re);
        params['host'] = matches[1] + '//' + matches[2] + matches[3];
        return params;
    }

    function myself() {
        const scripts = document.getElementsByTagName('script');
        return scripts[scripts.length - 1];
    }

    function render(template, data) {
        return doT.template(template)(data);
    }

    //
    // Local Storage
    //

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

    class FairpayWidget {

        constructor(me, params) {
            this.panes = [];
            this.tabs = [];
            this.tabsStatus = {};
            this.store = {};
            this.templates = [];
            this.init(me, params);
        }


        loadTemplates(templateNames) {
            return loadFiles(templateNames.map(name => `${params['host']}/${name}.dot`))
                .then((result) => result.reduce((acc, val, idx, arr) => {
                    acc[templateNames[idx]] = val;
                    return acc;
                }, {}));
        }

        init(me, params) {

            let config = {};
            let localData = {};
            get(`${params['host']}/api/v1/embeds/${params['uuid']}/embed_data`)
                .then(data => {
                    console.log(data);
                    config = JSON.parse(data).result
                })
                .then(() => getLocalData())
                .then((data) => {
                    localData = data;
                    return this.loadTemplates(['fairpay', 'recap', 'dwolla', 'authorizenet']);
                })
                .then((result) => {
                    this.templates = result;
                    if (params.amount) {
                        config = Object.assign(config, {suggested_amounts: [params.amount]})
                    }
                    this.store = Object.assign({}, {config, params, localData});

                    // format the amounts
                    Object.assign(config, {
                        localizedAmounts: config.suggested_amounts.map((amount) => {
                            if (-1 == amount) {
                                return -1;
                            } else {
                                return this.localizeAmount(amount);
                            }
                        })
                    });


                    // render the template and insert it after the script tag
                    let html = render(this.templates['fairpay'], this.store.config);
                    me.insertAdjacentHTML('afterend', html);

                    // panes
                    this.panes = $$('.fpPane'); // get all the panes

                    // tabs
                    this.tabs = $$('.fpTab'); // get all the tabs
                    this.tabs.forEach((tab) => {
                        tab.addEventListener('click', (evt) => {
                            if (this.tabsStatus[tab.id] === 'enabled') {
                                this.togglePane(this.tabs, this.panes, tab.dataset.pane);
                            }
                        });
                        this.tabsStatus[tab.id] = 'disabled';
                    });
                    this.tabsStatus['fpTab_0'] = 'enabled';
                    this.togglePane(this.tabs, this.panes, 'fpAmountPane');
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

                    if (this.store.localData.email) {
                        emailInput.value = this.store.localData.email;
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
                        if (this.store.config.suggested_amounts.length == 1) {
                            amount = this.store.config.suggested_amounts[0];
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


                        const url = `${this.store.params['host']}/api/v1/embeds/${this.store.params['uuid']}/submit_step1`;
                        const data = {
                            email,
                            amount
                        };
                        post(url, data)
                            .then(data => {
                                console.log(data);
                                const state = JSON.parse(data).result;
                                this.store = Object.assign(this.store, {state});
                                this.tabsStatus['fpTab_2'] = 'enabled';
                                $('#fpAmount').textContent = `Total to pay: ${this.localizeAmount(this.store.state.transaction.base_amount)}`;
                                this.showCurrentPayment();
                                this.setupDwolla();
                                this.setupAuthorizenet();
                                this.updateFees();
                                this.togglePane(this.tabs, this.panes, 'fpPaymentPane');
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
                            this.showCurrentPayment();
                        })
                    });


                });
            // .catch(error => console.log(`Error in init:${error}`)); TODO: uncomment and handle better
        }

        togglePane(tabList, paneList, paneId) {
            paneList.forEach((pane, index) => {
                const tab = tabList[index];
                if (pane.id == paneId) {
                    show(pane);
                    addClass(tab, 'selected')
                } else {
                    hide(pane);
                    removeClass(tab, 'selected')
                }
            });
        }


        validateForm(inputs, button) {
            inputs.forEach(input => {
                if (input.checkValidity()) {
                    enable(button);
                } else {
                    disable(button);
                }
            })
        }


        setupAuthorizenet() {

            $("#fpPayment-pane-authorizenet").innerHTML = render(this.templates['authorizenet'], {widget: this});

            // form validation
            const authorizenetPayButton = $('#fpPayWithAuthorizenet');
            $$('input.fpAuthorizenet').forEach(input => {
                input.addEventListener('input', evt => {
                    this.validateForm([evt.target], authorizenetPayButton);

                    if (evt.target.id === "fpCardNumber") {
                        const bin = evt.target.value.slice(0, 6);
                        const amount = this.store.state.transaction.base_amount;

                        get(`${this.store.params['host']}/api/v1/embeds/${this.store.params['uuid']}/estimate_fee?bin=${bin}&amount=${amount}`)
                            .then((data) => {
                                const result = JSON.parse(data).result;
                                const paymentConfig = this.getPaymentConfig('authorizenet');
                                paymentConfig.card_fee_str = result.fee_str === "unknown" ? result.estimated_fee : result.fee_str;
                                this.updateFees();
                            });
                        // .catch((error) => console.log(`error:${error}`)); TODO: uncomment and handle better
                    }

                });
            });
            this.validateForm($$('input.fpAuthorizenet'), authorizenetPayButton);


            // pay button
            authorizenetPayButton.addEventListener('click', (evt) => {
                const url = `${this.store.params['host']}/api/v1/embeds/${this.store.params['uuid']}/submit_payment`;
                const data = {
                    transaction_uuid: this.store.state.transaction.uuid,
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
                        this.store = Object.assign(this.store, {paymentState});
                        this.disableTabs();
                        this.renderRecap();
                        this.togglePane(this.tabs, this.panes, 'fpRecapPane');
                    });
                // .catch((error) => console.log(`error:${error}`)); TODO: uncomment and handle better
            });


        }

        dwollaFundingSources() {
            const paymentConfig = this.getPaymentConfig('dwolla');
            return paymentConfig ? paymentConfig.funding_sources : [];
        }

        setupDwolla() {
            $("#fpPayment-pane-dwolla").innerHTML = render(this.templates['dwolla'], {widget: this});

            $('#fpDowlla-authorize').addEventListener('click', (evt) => {
                let url = `${this.store.params['host']}/dwolla/auth?t=${this.store.state.transaction.uuid}&o=widget`;
                let authorizeWindow = window.open(url, "_blank", "width=500, height=550");
                let interval = window.setInterval(() => {
                    if (authorizeWindow == null || authorizeWindow.closed) {
                        window.clearInterval(interval);
                        get(`${this.store.params['host']}/api/v1/embeds/${this.store.params['uuid']}/step2_data?transaction_uuid=${this.store.state.transaction.uuid}`)
                            .then((data) => {
                                console.log(data);
                                const state = JSON.parse(data).result;
                                this.store = Object.assign(this.store, {state});
                                this.setupDwolla();
                            });
                    }
                }, 1000);
            });

            $('#fpDowlla-pay').addEventListener('click', (evt) => {
                const url = `${this.store.params['host']}/api/v1/embeds/${this.store.params['uuid']}/send_dwolla_info`;
                const data = {
                    transaction_uuid: this.store.state.transaction.uuid,
                    funding_source_id: $('input[name=fpDwollaFundingSource]:checked').value
                };
                post(url, data)
                    .then(data => {
                        console.log(data);
                        const paymentState = JSON.parse(data).result;
                        this.store = Object.assign(this.store, {paymentState});
                        this.renderRecap();
                        this.disableTabs();
                        this.togglePane(this.tabs, this.panes, 'fpRecapPane');
                    });
                // .catch((error) => console.log(`error:${error}`)); TODO: uncomment and handle better


            });

            $$('.fpDwolla-pane').forEach(el => hide(el));
            if (this.getPaymentConfig('dwolla').has_dwolla_auth) {
                show($('#fpDowlla-pane-pay'))
            } else {
                show($('#fpDowlla-pane-authorize'))
            }

        }

        disableTabs() {
            this.tabs.forEach(tab => this.tabsStatus[tab.id] = 'disabled');
        }

        renderRecap() {
            $("#fpPaymentRecap").innerHTML = render(this.templates['recap'], this.store);
        }

        updateFees() {
            this.store.state.payment_configs.forEach(p => {
                $(`#fp_paymentFees_${p.kind}`).textContent = `Fees: ${p.card_fee_str}`;
            });
        }

        getPaymentConfig(paymentKind) {
            if (this.store.state) {
                return this.store.state.payment_configs
                    ? this.store.state.payment_configs.find(p => p.kind === paymentKind)
                    : null;
            }
        }

        showCurrentPayment() {
            let paymentType = $('input[name=fpPaymentType]:checked').value;
            $$(".fpPayment-pane").forEach(el => hide(el));
            show($(`#fpPayment-pane-${paymentType}`));
        }

        localizeAmount(amount) {
            return this.store.config.currency_format.replace('{0}', amount);
        }
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
        .then(() => {
            const widget = new FairpayWidget(me, params)
        });
    // .catch((error) => console.log(`error:${error}`)); TODO: uncomment and handle better

})(window);