#--- CHANGE FA2 MINTER

$(OUT)/minter_withdraw_all_tokens.mligo: target_address = $(DEFAULT_CONTRACT_TARGET)
$(OUT)/minter_withdraw_all_tokens.mligo: counter = 0
$(OUT)/minter_withdraw_all_tokens.mligo: $(OUT)/common_vars.mligo
	$(file >$@,let counter = $(counter)n)
	$(file >>$@,let contract_address = ("$(target_address)":address))
	$(file >>$@,let fa2_contract = ("":address))
	$(file >>$@,let tokens = ([]:nat list))
	$(file >>$@,let signatures: signature option list = [])

minter_withdraw_all_tokens_params: $(OUT)/minter_withdraw_all_tokens.mligo

$(OUT)/minter_withdraw_all_tokens.payload: minter/minter_withdraw_all_tokens.mligo $(OUT)/minter_withdraw_all_tokens.mligo
	$(eval PAYLOAD := $(shell $(COMPILE_EXPRESSION) $(notdir $(basename $@))_payload))
	$(file >$@,$(PAYLOAD))

minter_withdraw_all_tokens_payload: $(OUT)/minter_withdraw_all_tokens.payload

$(OUT)/minter_withdraw_all_tokens.tz: minter/minter_withdraw_all_tokens.mligo $(OUT)/minter_withdraw_all_tokens.mligo
	$(COMPILE_PARAMETER) '((counter, Operation withdraw_all_tokens), signatures)'

minter_withdraw_all_tokens_call: $(OUT)/minter_withdraw_all_tokens.tz