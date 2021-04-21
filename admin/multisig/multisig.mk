#--- CHANGE MULTISIG MEMBERS

$(OUT)/multisig_change_keys.mligo: $(OUT)/common_vars.mligo
	$(file >$@,let counter = $(counter)n)
	$(file >>$@,let threshold = 1n)
	$(file >>$@,let keys: key list = [])
	$(file >>$@,let signatures: signature option list = [])

multisig_change_keys_params: $(OUT)/multisig_change_keys.mligo

$(OUT)/multisig_change_keys.payload: multisig/multisig_change_keys.mligo $(OUT)/multisig_change_keys.mligo
	$(eval PAYLOAD := $(shell $(COMPILE_EXPRESSION) $(notdir $(basename $@))_payload))
	$(file >$@,$(PAYLOAD))

multisig_change_keys_payload: $(OUT)/multisig_change_keys.payload

$(OUT)/multisig_change_keys.tz: multisig/multisig_change_keys.mligo $(OUT)/multisig_change_keys.mligo
	$(COMPILE_PARAMETER) '((counter, Change_keys {threshold=threshold;keys=keys}), signatures)'

multisig_change_keys_call: $(OUT)/multisig_change_keys.tz
