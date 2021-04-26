#--- CHANGE QUORUM THRESHOLD

$(OUT)/quorum_change_threshold.mligo: $(OUT)/common_vars.mligo
	$(file >$@,let counter = $(counter)n)
	$(file >>$@,let contract_address = ("$(target_address)":address))
	$(file >>$@,let threshold = 0n)
	$(file >>$@,let signatures: signature option list = [])

quorum_change_threshold_params: $(OUT)/quorum_change_threshold.mligo

$(OUT)/quorum_change_threshold.payload: quorum/quorum_change_threshold.mligo $(OUT)/quorum_change_threshold.mligo
	$(eval PAYLOAD := $(shell $(COMPILE_EXPRESSION) $(notdir $(basename $@))_payload))
	$(file >$@,$(PAYLOAD))

quorum_change_threshold_payload: $(OUT)/quorum_change_threshold.payload


$(OUT)/quorum_change_threshold.tz: quorum/quorum_change_threshold.mligo $(OUT)/quorum_change_threshold.mligo
	$(COMPILE_PARAMETER) '((counter, Operation change_threshold), signatures)'

quorum_change_threshold_call: $(OUT)/quorum_change_threshold.tz

#--- CHANGE QUORUM MEMBERS

$(OUT)/quorum_change_quorum.mligo: $(OUT)/common_vars.mligo
	$(file >$@,let counter = $(counter)n)
	$(file >>$@,let contract_address = ("$(target_address)":address))
	$(file >>$@,let threshold = 0n)
	$(file >>$@,let new_quorum : (string, key) map = Map.literal [])
	$(file >>$@,let signatures: signature option list = [])

quorum_change_quorum_params: $(OUT)/quorum_change_quorum.mligo

$(OUT)/quorum_change_quorum.payload: quorum/quorum_change_quorum.mligo $(OUT)/quorum_change_quorum.mligo
	$(eval PAYLOAD := $(shell $(COMPILE_EXPRESSION) $(notdir $(basename $@))_payload))
	$(file >$@,$(PAYLOAD))

quorum_change_quorum_payload: $(OUT)/quorum_change_quorum.payload

$(OUT)/quorum_change_quorum.tz: quorum/quorum_change_quorum.mligo $(OUT)/quorum_change_quorum.mligo
	$(COMPILE_PARAMETER) '((counter, Operation change_quorum), signatures)'

quorum_change_quorum_call: $(OUT)/quorum_change_quorum.tz

#--- CHANGE QUORUM ADMIN

$(OUT)/quorum_set_admin.mligo: $(OUT)/common_vars.mligo
	$(file >$@,let counter = $(counter)n)
	$(file >>$@,let contract_address = ("$(target_address)":address))
	$(file >>$@,let new_admin = ("":address))
	$(file >>$@,let signatures: signature option list = [])

quorum_set_admin_params: $(OUT)/quorum_set_admin.mligo

$(OUT)/quorum_set_admin.payload: quorum/quorum_set_admin.mligo $(OUT)/quorum_set_admin.mligo
	$(eval PAYLOAD := $(shell $(COMPILE_EXPRESSION) $(notdir $(basename $@))_payload))
	$(file >$@,$(PAYLOAD))

quorum_set_admin_payload: $(OUT)/quorum_set_admin.payload

$(OUT)/quorum_set_admin.tz: quorum/quorum_set_admin.mligo $(OUT)/quorum_set_admin.mligo
	$(COMPILE_PARAMETER) '((counter, Operation set_admin), signatures)'

quorum_set_admin_call: $(OUT)/quorum_set_admin.tz

#--- SET PAYMENT_ADDRESS

$(OUT)/quorum_set_payment_address.mligo: $(OUT)/common_vars.mligo
	$(file >$@,let counter = $(counter)n)
	$(file >>$@,let contract_address = ("$(target_address)":address))
	$(file >>$@,let minter_contract = ("":address))
	$(file >>$@,let signer_sig = ("":signature))
	$(file >>$@,let signer_id = "")
	$(file >>$@,let signatures: signature option list = [])

quorum_set_payment_address_params: $(OUT)/quorum_set_payment_address.mligo

$(OUT)/quorum_set_payment_address.payload: quorum/quorum_set_payment_address.mligo $(OUT)/quorum_set_payment_address.mligo
	$(eval PAYLOAD := $(shell $(COMPILE_EXPRESSION) $(notdir $(basename $@))_payload))
	$(file >$@,$(PAYLOAD))

quorum_set_payment_address_payload: $(OUT)/quorum_set_payment_address.payload

$(OUT)/quorum_set_payment_address.tz: quorum/quorum_set_payment_address.mligo $(OUT)/quorum_set_payment_address.mligo
	$(COMPILE_PARAMETER) '((counter, Operation set_payment_address), signatures)'

quorum_set_payment_address_call: $(OUT)/quorum_set_payment_address.tz