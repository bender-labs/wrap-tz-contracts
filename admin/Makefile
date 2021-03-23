LIGO = ligo
RUN_FUNCTION = $(LIGO) run-function
COMPILE_EXPRESSION = $(LIGO) compile-expression --warn=false --init-file $< cameligo
COMPILE_PARAMETER = $(LIGO) compile-parameter --warn=false --output-file $@ $< multisig_main
OUT = build
_prepare := $(shell mkdir -p $(OUT))


chain_id = NetXSgo1ZT2DRUG

$(OUT)/common_vars.mligo: contract_address = KT1NEwCNbdz27XZpuhZhzECR97yBpxfo83Am
$(OUT)/common_vars.mligo:
	$(file >$@,let multisig_address = ("$(contract_address)":address))
	$(file >>$@,let chain = ("$(chain_id)":chain_id))

$(OUT)/quorum_change_threshold.mligo: target_address = KT1C5ftQmsS41bwS5wQKWRmEhUCyfk6kan2S
$(OUT)/quorum_change_threshold.mligo: threshold = 0
$(OUT)/quorum_change_threshold.mligo: counter = 0
$(OUT)/quorum_change_threshold.mligo: $(OUT)/common_vars.mligo
	$(file >$@,let threshold = $(threshold)n)
	$(file >>$@,let counter = $(counter)n)
	$(file >>$@,let contract_address = ("$(target_address)":address))
	$(file >>$@,let signatures: signature option list = [])

$(OUT)/quorum_change_threshold.payload: quorum_change_threshold.mligo $(OUT)/quorum_change_threshold.mligo
	$(eval PAYLOAD := $(shell $(COMPILE_EXPRESSION) $(notdir $(basename $@))_payload))
	$(file >$@,$(PAYLOAD))

 quorum_change_threshold: $(OUT)/quorum_change_threshold.payload

$(OUT)/quorum_change_threshold.tz: quorum_change_threshold.mligo $(OUT)/quorum_change_threshold.mligo
	$(COMPILE_PARAMETER) '((counter, Operation change_threshold), signatures)'

call_quorum_change_threshold: $(OUT)/quorum_change_threshold.tz


clean:
	rm -f build/*

.PHONY: clean
