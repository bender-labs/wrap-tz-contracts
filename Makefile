.PHONY: test clean

LIGO = ligo
#LIGO = docker run --rm -v "${PWD}":"${PWD}" -w "${PWD}" ligolang/ligo:0.41.0
OUT = michelson
META_OUT = metadata
PYTHON = python3

venv/bin/activate: requirements.txt
	python3 -m venv venv
	./venv/bin/pip install -r requirements.txt

test:
	${PYTHON} -m unittest discover -s test -t test

$(OUT)/quorum.tz: ligo/quorum/multisig.mligo
	$(LIGO) compile contract --output-file $@ $^ -e main -p ithaca

$(OUT)/minter.tz: ligo/minter/main.mligo
	$(LIGO) compile contract --output-file $@ $^ -e main -p ithaca

$(OUT)/multi_asset.tz: ligo/fa2/multi_asset/fa2_multi_asset.mligo
	$(LIGO) compile contract --output-file $@ $^ -e main -p ithaca

$(OUT)/nft.tz:ligo/fa2/nft/fa2_nft_asset.mligo
	$(LIGO) compile contract --output-file $@ $^ -e main -p ithaca

$(OUT)/governance_token.tz:ligo/fa2/governance/main.mligo
	$(LIGO) compile contract --output-file $@ $^ -e main -p ithaca

$(OUT)/staking.tz:ligo/staking/staking_main.mligo
	$(LIGO) compile contract --output-file $@ $^ -e main -p ithaca

$(OUT)/reserve.tz:ligo/staking/reserve_main.mligo
	$(LIGO) compile contract --output-file $@ $^ -e main -p ithaca

$(OUT)/stacking.tz:ligo/stacking/stacking_main.mligo
	$(LIGO) compile contract --output-file $@ $^ -e main -p ithaca

$(META_OUT)/multi_asset.json:
	${PYTHON} -m metadata multi_asset $@

$(META_OUT)/nft.json:
	${PYTHON} -m metadata nft $@

$(META_OUT)/quorum.json:
	${PYTHON} -m metadata quorum $@

$(META_OUT)/minter.json:
	${PYTHON} -m metadata minter $@

$(META_OUT)/governance_token.json:
	${PYTHON} -m metadata governance_token $@

$(META_OUT)/staking.json:
	${PYTHON} -m metadata staking $@

$(META_OUT)/stacking.json:
	${PYTHON} -m metadata stacking $@

clean:
	rm -f $(OUT)/*.tz
	rm -f $(META_OUT)/*.json

compile: $(OUT)/multi_asset.tz $(OUT)/quorum.tz $(OUT)/minter.tz $(OUT)/nft.tz $(OUT)/governance_token.tz $(OUT)/staking.tz $(OUT)/reserve.tz $(OUT)/stacking.tz

metadata: $(META_OUT)/multi_asset.json $(META_OUT)/nft.json $(META_OUT)/quorum.json $(META_OUT)/minter.json $(META_OUT)/governance_token.json $(META_OUT)/staking.json $(META_OUT)/stacking.json

all: compile metadata