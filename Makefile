.PHONY: test clean

OUT = michelson
META_OUT = metadata
PYTHON = python3

venv/bin/activate: requirements.txt
	python3 -m venv venv
	./venv/bin/pip install -r requirements.txt

test:
	${PYTHON} -m unittest discover -s test -t test

$(OUT)/quorum.tz: ligo/quorum/multisig.mligo
	ligo compile-contract --output-file=$@ $^ main

$(OUT)/minter.tz: ligo/minter/main.mligo
	ligo compile-contract --output-file=$@ $^ main

$(OUT)/multi_asset.tz: ligo/fa2/multi_asset/fa2_multi_asset.mligo
	ligo compile-contract --output-file=$@ $^ main

$(OUT)/nft.tz:ligo/fa2/nft/fa2_nft_asset.mligo
	ligo compile-contract --output-file=$@ $^ main

$(OUT)/governance_token.tz:ligo/fa2/governance/main.mligo
	ligo compile-contract --output-file=$@ $^ main

$(OUT)/staking.tz:ligo/staking/staking_main.mligo
	ligo compile-contract --output-file=$@ $^ main

$(OUT)/reserve.tz:ligo/staking/reserve_main.mligo
	ligo compile-contract --output-file=$@ $^ main

$(OUT)/vesting.tz:ligo/vesting/vesting_main.mligo
	ligo compile-contract --output-file=$@ $^ main

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

$(META_OUT)/vesting.json:
	${PYTHON} -m metadata vesting $@

clean:
	rm -f $(OUT)/*.tz
	rm -f $(META_OUT)/*.json

compile: $(OUT)/multi_asset.tz $(OUT)/quorum.tz $(OUT)/minter.tz $(OUT)/nft.tz $(OUT)/governance_token.tz $(OUT)/staking.tz $(OUT)/reserve.tz $(OUT)/vesting.tz

metadata: $(META_OUT)/multi_asset.json $(META_OUT)/nft.json $(META_OUT)/quorum.json $(META_OUT)/minter.json $(META_OUT)/governance_token.json $(META_OUT)/staking.json $(META_OUT)/vesting.json

all: compile metadata