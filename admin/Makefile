LIGO = ligo
RUN_FUNCTION = $(LIGO) run-function
COMPILE_EXPRESSION = $(LIGO) compile-expression --warn=false --init-file $< cameligo
COMPILE_PARAMETER = $(LIGO) compile-parameter --warn=false --output-file $@ $< multisig_main
OUT = build
_prepare := $(shell mkdir -p $(OUT))
DEFAULT_CONTRACT_TARGET := KT1D8R2CecSKpC4X31EFezsPAU2usWmh4J6b
#DEFAULT_CONTRACT_TARGET := KT1C5ftQmsS41bwS5wQKWRmEhUCyfk6kan2S
DEFAULT_MULTISIG_ADDRESS := KT1NEwCNbdz27XZpuhZhzECR97yBpxfo83Am
chain_id = NetXSgo1ZT2DRUG

#--- CHANGE QUORUM THRESHOLD

$(OUT)/common_vars.mligo: contract_address = $(DEFAULT_MULTISIG_ADDRESS)
$(OUT)/common_vars.mligo:
	$(file >$@,let multisig_address = ("$(contract_address)":address))
	$(file >>$@,let chain = ("$(chain_id)":chain_id))

$(OUT)/quorum_change_threshold.mligo: target_address = $(DEFAULT_CONTRACT_TARGET)
$(OUT)/quorum_change_threshold.mligo: counter = 0
$(OUT)/quorum_change_threshold.mligo: $(OUT)/common_vars.mligo
	$(file >$@,let counter = $(counter)n)
	$(file >>$@,let contract_address = ("$(target_address)":address))
	$(file >>$@,let threshold = 0n)
	$(file >>$@,let signatures: signature option list = [])

quorum_change_threshold_params: $(OUT)/quorum_change_threshold.mligo

$(OUT)/quorum_change_threshold.payload: quorum_change_threshold.mligo $(OUT)/quorum_change_threshold.mligo
	$(eval PAYLOAD := $(shell $(COMPILE_EXPRESSION) $(notdir $(basename $@))_payload))
	$(file >$@,$(PAYLOAD))

quorum_change_threshold_payload: $(OUT)/quorum_change_threshold.payload


$(OUT)/quorum_change_threshold.tz: quorum_change_threshold.mligo $(OUT)/quorum_change_threshold.mligo
	$(COMPILE_PARAMETER) '((counter, Operation change_threshold), signatures)'

quorum_change_threshold_call: $(OUT)/quorum_change_threshold.tz

#--- CHANGE QUORUM MEMBERS

$(OUT)/quorum_change_quorum.mligo: target_address = $(DEFAULT_CONTRACT_TARGET)
$(OUT)/quorum_change_quorum.mligo: counter = 0
$(OUT)/quorum_change_quorum.mligo: $(OUT)/common_vars.mligo
	$(file >$@,let counter = $(counter)n)
	$(file >>$@,let contract_address = ("$(target_address)":address))
	$(file >>$@,let threshold = 0n)
	$(file >>$@,let new_quorum : (string, key) map = Map.literal [])
	$(file >>$@,let signatures: signature option list = [])

quorum_change_quorum_params: $(OUT)/quorum_change_quorum.mligo

$(OUT)/quorum_change_quorum.payload: quorum_change_quorum.mligo $(OUT)/quorum_change_quorum.mligo
	$(eval PAYLOAD := $(shell $(COMPILE_EXPRESSION) $(notdir $(basename $@))_payload))
	$(file >$@,$(PAYLOAD))

quorum_change_quorum_payload: $(OUT)/quorum_change_quorum.payload

$(OUT)/quorum_change_quorum.tz: quorum_change_quorum.mligo $(OUT)/quorum_change_quorum.mligo
	$(COMPILE_PARAMETER) '((counter, Operation change_quorum), signatures)'

quorum_change_quorum_call: $(OUT)/quorum_change_quorum.tz

#--- CHANGE QUORUM ADMIN

$(OUT)/quorum_set_admin.mligo: target_address = $(DEFAULT_CONTRACT_TARGET)
$(OUT)/quorum_set_admin.mligo: counter = 0
$(OUT)/quorum_set_admin.mligo: $(OUT)/common_vars.mligo
	$(file >$@,let counter = $(counter)n)
	$(file >>$@,let contract_address = ("$(target_address)":address))
	$(file >>$@,let new_admin = ("":address))
	$(file >>$@,let signatures: signature option list = [])

quorum_set_admin_params: $(OUT)/quorum_set_admin.mligo

$(OUT)/quorum_set_admin.payload: quorum_set_admin.mligo $(OUT)/quorum_set_admin.mligo
	$(eval PAYLOAD := $(shell $(COMPILE_EXPRESSION) $(notdir $(basename $@))_payload))
	$(file >$@,$(PAYLOAD))

quorum_set_admin_payload: $(OUT)/quorum_set_admin.payload

$(OUT)/quorum_set_admin.tz: quorum_set_admin.mligo $(OUT)/quorum_set_admin.mligo
	$(COMPILE_PARAMETER) '((counter, Operation set_admin), signatures)'

quorum_set_admin_call: $(OUT)/quorum_set_admin.tz

#--- CHANGE MULTISIG MEMBERS

$(OUT)/multisig_change_keys.mligo: target_address = $(DEFAULT_CONTRACT_TARGET)
$(OUT)/multisig_change_keys.mligo: counter = 0
$(OUT)/multisig_change_keys.mligo: $(OUT)/common_vars.mligo
	$(file >$@,let counter = $(counter)n)
	$(file >>$@,let threshold = 1n)
	$(file >>$@,let keys: key list = [])
	$(file >>$@,let signatures: signature option list = [])

multisig_change_keys_params: $(OUT)/multisig_change_keys.mligo

$(OUT)/multisig_change_keys.payload: multisig_change_keys.mligo $(OUT)/multisig_change_keys.mligo
	$(eval PAYLOAD := $(shell $(COMPILE_EXPRESSION) $(notdir $(basename $@))_payload))
	$(file >$@,$(PAYLOAD))

multisig_change_keys_payload: $(OUT)/multisig_change_keys.payload

$(OUT)/multisig_change_keys.tz: multisig_change_keys.mligo $(OUT)/multisig_change_keys.mligo
	$(COMPILE_PARAMETER) '((counter, Change_keys {threshold=threshold;keys=keys}), signatures)'

multisig_change_keys_call: $(OUT)/multisig_change_keys.tz

clean:
	rm -f build/*

.PHONY: clean
