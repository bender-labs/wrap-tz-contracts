#--- CONFIRM BENDER ADDRESS MIGRATION

$(OUT)/governance_confirm_bender_migration.mligo: target_address = $(DEFAULT_CONTRACT_TARGET)
$(OUT)/governance_confirm_bender_migration.mligo: counter = 0
$(OUT)/governance_confirm_bender_migration.mligo: $(OUT)/common_vars.mligo
	$(file >$@,let counter = $(counter)n)
	$(file >>$@,let contract_address = ("$(target_address)":address))
	$(file >>$@,let signatures: signature option list = [])

governance_confirm_bender_migration_params: $(OUT)/governance_confirm_bender_migration.mligo

$(OUT)/governance_confirm_bender_migration.payload: governance/governance_confirm_bender_migration.mligo $(OUT)/governance_confirm_bender_migration.mligo
	$(eval PAYLOAD := $(shell $(COMPILE_EXPRESSION) $(notdir $(basename $@))_payload))
	$(file >$@,$(PAYLOAD))

governance_confirm_bender_migration_payload: $(OUT)/governance_confirm_bender_migration.payload


$(OUT)/governance_confirm_bender_migration.tz: governance/governance_confirm_bender_migration.mligo $(OUT)/governance_confirm_bender_migration.mligo
	$(COMPILE_PARAMETER) '((counter, Operation confirm_migration), signatures)'

governance_confirm_bender_migration_call: $(OUT)/governance_confirm_bender_migration.tz

#--- DISTRIBUTE GOVERNANCE TOKEN

$(OUT)/governance_distribute.mligo: target_address = $(DEFAULT_CONTRACT_TARGET)
$(OUT)/governance_distribute.mligo: counter = 0
$(OUT)/governance_distribute.mligo: $(OUT)/common_vars.mligo
	$(file >$@,let counter = $(counter)n)
	$(file >>$@,let contract_address = ("$(target_address)":address))
	$(file >>$@,let distribution:distribute_param = [])
	$(file >>$@,let signatures: signature option list = [])

governance_distribute_params: $(OUT)/governance_distribute.mligo

$(OUT)/governance_distribute.payload: governance/governance_distribute.mligo $(OUT)/governance_distribute.mligo
	$(eval PAYLOAD := $(shell $(COMPILE_EXPRESSION) $(notdir $(basename $@))_payload))
	$(file >$@,$(PAYLOAD))

governance_distribute_payload: $(OUT)/governance_distribute.payload


$(OUT)/governance_distribute.tz: governance/governance_distribute.mligo $(OUT)/governance_distribute.mligo
	$(COMPILE_PARAMETER) '((counter, Operation distribute), signatures)'

governance_distribute_call: $(OUT)/governance_distribute.tz