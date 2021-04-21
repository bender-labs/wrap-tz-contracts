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

include quorum/quorum.mk
include multisig/multisig.mk
include fa2/fa2.mk
include minter/minter.mk

$(OUT)/common_vars.mligo: contract_address = $(DEFAULT_MULTISIG_ADDRESS)
$(OUT)/common_vars.mligo:
	$(file >$@,let multisig_address = ("$(contract_address)":address))
	$(file >>$@,let chain = ("$(chain_id)":chain_id))


clean:
	rm -f build/*

.PHONY: clean
