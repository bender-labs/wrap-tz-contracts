LIGO = ligo
RUN_FUNCTION = $(LIGO) run-function
COMPILE_EXPRESSION = $(LIGO) compile-expression --init-file $< cameligo 
OUT = build


chain_id = NetXSgo1ZT2DRUG


$(OUT)/quorum_params.mligo: contract_address = KT1NEwCNbdz27XZpuhZhzECR97yBpxfo83Am
$(OUT)/quorum_params.mligo: target_address = KT1C5ftQmsS41bwS5wQKWRmEhUCyfk6kan2S
$(OUT)/quorum_params.mligo: counter = 0
$(OUT)/quorum_params.mligo: threshold = 0
$(OUT)/quorum_params.mligo: quorum_admin.mligo
	$(file >>$@,let threshold = $(threshold)n)
	$(file >>$@,let contract_address = ("$(target_address)":address))
	$(file >>$@,let multisig_address = ("$(contract_address)":address))
	$(file >>$@,let counter = $(counter)n)
	$(file >>$@,let chain = ("$(chain_id)":chain_id))
	$(file >>$@,let signatures : signature option list = [])

$(OUT)/change_threshold.payload: quorum_admin.mligo $(OUT)/quorum_params.mligo
	$(eval PAYLOAD := $(shell $(LIGO) compile-expression --init-file $< cameligo $(notdir $(basename $@))_payload))
	$(file >>$@, $(PAYLOAD))

prepare_change_threshold: $(OUT)/change_threshold.payload

$(OUT)/change_threshold.call: quorum_admin.mligo $(OUT)/quorum_params.mligo
	$(eval PARAMS := $(shell $(LIGO) compile-expression --format dev --init-file $< cameligo call))
	$(file >>$@,$(PARAMS))

call_change_threshold: $(OUT)/change_threshold.call

	
clean:
	rm -f build/*

.PHONY: clean 