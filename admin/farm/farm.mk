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

$(OUT)/farm_update_plan.tz: farm/farm_update_plan.mligo $(OUT)/farm_update_plan.mligo
	$(COMPILE_PARAMETER) '((counter, Operation update_plan), signatures)'

farm_update_plan_call: $(OUT)/farm_update_plan.tz

#--- SET ADMIN

$(OUT)/farm_set_admin.mligo: target_address = $(DEFAULT_CONTRACT_TARGET)
$(OUT)/farm_set_admin.mligo: counter = 0
$(OUT)/farm_set_admin.mligo: $(OUT)/common_vars.mligo
	$(file >$@,let counter = $(counter)n)
	$(file >>$@,let contract_address = ("$(target_address)":address))
	$(file >>$@,let new_admin_address = ("":address))
	$(file >>$@,let signatures: signature option list = [])

farm_set_admin_params: $(OUT)/farm_set_admin.mligo

$(OUT)/farm_set_admin.payload: farm/farm_set_admin.mligo $(OUT)/farm_set_admin.mligo
	$(eval PAYLOAD := $(shell $(COMPILE_EXPRESSION) $(notdir $(basename $@))_payload))
	$(file >$@,$(PAYLOAD))

farm_set_admin_payload: $(OUT)/farm_set_admin.payload

$(OUT)/farm_set_admin.tz: farm/farm_set_admin.mligo $(OUT)/farm_set_admin.mligo
	$(COMPILE_PARAMETER) '((counter, Operation set_admin), signatures)'

farm_set_admin_call: $(OUT)/farm_set_admin.tz