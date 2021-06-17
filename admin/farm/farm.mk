#--- UPDATE PLAN

$(OUT)/farm_update_plan.mligo: target_address = $(DEFAULT_CONTRACT_TARGET)
$(OUT)/farm_update_plan.mligo: counter = 0
$(OUT)/farm_update_plan.mligo: $(OUT)/common_vars.mligo
	$(file >$@,let counter = $(counter)n)
	$(file >>$@,let contract_address = ("$(target_address)":address))
	$(file >>$@,let total_blocks = 0n)
	$(file >>$@,let reward_per_block = 0n)
	$(file >>$@,let signatures: signature option list = [])

farm_update_plan_params: $(OUT)/farm_update_plan.mligo

$(OUT)/farm_update_plan.payload: farm/farm_update_plan.mligo $(OUT)/farm_update_plan.mligo
	$(eval PAYLOAD := $(shell $(COMPILE_EXPRESSION) $(notdir $(basename $@))_payload))
	$(file >$@,$(PAYLOAD))

farm_update_plan_payload: $(OUT)/farm_update_plan.payload

$(OUT)/farm_update_plan.tz: fa2/farm_update_plan.mligo $(OUT)/farm_update_plan.mligo
	$(COMPILE_PARAMETER) '((counter, Operation set_minter), signatures)'

farm_update_plan_call: $(OUT)/farm_update_plan.tz