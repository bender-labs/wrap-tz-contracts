#--- TRANSFER TEZ


$(OUT)/transfer_tez.mligo: $(OUT)/common_vars.mligo
	$(file >$@,let counter = $(counter)n)
	$(file >>$@,let contract_address = ("$(target_address)":address))
	$(file >>$@,let total = 0tez)
	$(file >>$@,let signatures: signature option list = [])

transfer_tez_params: $(OUT)/transfer_tez.mligo

$(OUT)/transfer_tez.payload: transfer/transfer_tez.mligo $(OUT)/transfer_tez.mligo
	$(eval PAYLOAD := $(shell $(COMPILE_EXPRESSION) $(notdir $(basename $@))_payload))
	$(file >$@,$(PAYLOAD))

transfer_tez_payload: $(OUT)/transfer_tez.payload

$(OUT)/transfer_tez.tz: transfer/transfer_tez.mligo $(OUT)/transfer_tez.mligo
	$(COMPILE_PARAMETER) '((counter, Operation transfer_tez), signatures)'

transfer_tez_call: $(OUT)/transfer_tez.tz



#--- TRANSFER FA2


$(OUT)/transfer_fa2.mligo: $(OUT)/common_vars.mligo
	$(file >$@,let counter = $(counter)n)
	$(file >>$@,let contract_address = ("$(target_address)":address))
	$(file >>$@,let token_amount = 0tez)
	$(file >>$@,let token_id = 0n)
	$(file >>$@,let destination = ("":address))
	$(file >>$@,let signatures: signature option list = [])

transfer_fa2_params: $(OUT)/transfer_fa2.mligo

$(OUT)/transfer_fa2.payload: transfer/transfer_fa2.mligo $(OUT)/transfer_fa2.mligo
	$(eval PAYLOAD := $(shell $(COMPILE_EXPRESSION) $(notdir $(basename $@))_payload))
	$(file >$@,$(PAYLOAD))

transfer_fa2_payload: $(OUT)/transfer_fa2.payload

$(OUT)/transfer_fa2.tz: transfer/transfer_fa2.mligo $(OUT)/transfer_fa2.mligo
	$(COMPILE_PARAMETER) '((counter, Operation transfer_fa2), signatures)'

transfer_fa2_call: $(OUT)/transfer_fa2.tz