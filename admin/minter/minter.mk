#--- WITHDRAW TOKENS FOR ADDRESS


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

#--- CHANGE STAKING


$(OUT)/minter_set_staking.mligo: $(OUT)/common_vars.mligo
	$(file >$@,let counter = $(counter)n)
	$(file >>$@,let contract_address = ("$(target_address)":address))
	$(file >>$@,let new_staking_address = ("":address))
	$(file >>$@,let signatures: signature option list = [])

minter_set_staking_params: $(OUT)/minter_set_staking.mligo

$(OUT)/minter_set_staking.payload: minter/minter_set_staking.mligo $(OUT)/minter_set_staking.mligo
	$(eval PAYLOAD := $(shell $(COMPILE_EXPRESSION) $(notdir $(basename $@))_payload))
	$(file >$@,$(PAYLOAD))

minter_set_staking_payload: $(OUT)/minter_set_staking.payload

$(OUT)/minter_set_staking.tz: minter/minter_set_staking.mligo $(OUT)/minter_set_staking.mligo
	$(COMPILE_PARAMETER) '((counter, Operation set_staking), signatures)'

minter_set_staking_call: $(OUT)/minter_set_staking.tz


#--- SET FEES SHARE

$(OUT)/minter_set_fees_share.mligo: $(OUT)/common_vars.mligo
	$(file >$@,let counter = $(counter)n)
	$(file >>$@,let contract_address = ("$(target_address)":address))
	$(file >>$@,let dev_pool = 0n)
	$(file >>$@,let staking = 0n)
	$(file >>$@,let quorum = 0n)
	$(file >>$@,let signatures: signature option list = [])

minter_set_fees_share_params: $(OUT)/minter_set_fees_share.mligo

$(OUT)/minter_set_fees_share.payload: minter/minter_set_fees_share.mligo $(OUT)/minter_set_fees_share.mligo
	$(eval PAYLOAD := $(shell $(COMPILE_EXPRESSION) $(notdir $(basename $@))_payload))
	$(file >$@,$(PAYLOAD))

minter_set_fees_share_payload: $(OUT)/minter_set_fees_share.payload

$(OUT)/minter_set_fees_share.tz: minter/minter_set_fees_share.mligo $(OUT)/minter_set_fees_share.mligo
	$(COMPILE_PARAMETER) '((counter, Operation set_fees_share), signatures)'

minter_set_fees_share_call: $(OUT)/minter_set_fees_share.tz