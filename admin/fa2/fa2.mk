#--- CHANGE FA2 MINTER

$(OUT)/fa2_set_minter.mligo: target_address = $(DEFAULT_CONTRACT_TARGET)
$(OUT)/fa2_set_minter.mligo: counter = 0
$(OUT)/fa2_set_minter.mligo: $(OUT)/common_vars.mligo
	$(file >$@,let counter = $(counter)n)
	$(file >>$@,let contract_address = ("$(target_address)":address))
	$(file >>$@,let new_minter = ("":address))
	$(file >>$@,let signatures: signature option list = [])

fa2_set_minter_params: $(OUT)/fa2_set_minter.mligo

$(OUT)/fa2_set_minter.payload: fa2/fa2_set_minter.mligo $(OUT)/fa2_set_minter.mligo
	$(eval PAYLOAD := $(shell $(COMPILE_EXPRESSION) $(notdir $(basename $@))_payload))
	$(file >$@,$(PAYLOAD))

fa2_set_minter_payload: $(OUT)/fa2_set_minter.payload

$(OUT)/fa2_set_minter.tz: fa2/fa2_set_minter.mligo $(OUT)/fa2_set_minter.mligo
	$(COMPILE_PARAMETER) '((counter, Operation set_minter), signatures)'

fa2_set_minter_call: $(OUT)/fa2_set_minter.tz