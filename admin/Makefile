LIGO = ligo
RUN_FUNCTION = $(LIGO) run-function
COMPILE_EXPRESSION = $(LIGO) compile-expression --warn=false --init-file $< cameligo
COMPILE_PARAMETER = $(LIGO) compile-parameter --warn=false --output-file $@ $< multisig_main
OUT = build
_prepare := $(shell mkdir -p $(OUT))


target_address ?= KT1D8R2CecSKpC4X31EFezsPAU2usWmh4J6b
counter ?= 0

ifdef env
include $(env).mk
else
chain_id ?= NetXSgo1ZT2DRUG
contract_address ?= KT1NEwCNbdz27XZpuhZhzECR97yBpxfo83Am
endif

include quorum/quorum.mk
include multisig/multisig.mk
include fa2/fa2.mk
include minter/minter.mk
include transfer/transfer.mk


$(OUT)/common_vars.mligo:
	$(file >$@,let multisig_address = ("$(contract_address)":address))
	$(file >>$@,let chain = ("$(chain_id)":chain_id))


clean:
	rm -f build/*

info:
	@echo "env: $(env)"
	@echo "chain id: $(chain_id)"
	@echo "contract address: $(contract_address)"

.PHONY: clean info
