#--- CHANGE FA2 MINTER


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