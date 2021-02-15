.PHONY: test clean

OUT = michelson
META_OUT = metadata

venv/bin/activate: requirements.txt
	python3 -m venv venv
	./venv/bin/pip install -r requirements.txt

test: venv/bin/activate
	./venv/bin/python -m unittest discover -s test -t test

$(OUT)/quorum.tz: ligo/quorum/multisig.mligo
	ligo compile-contract --output-file=$@ $^ main

$(OUT)/minter.tz: ligo/minter/main.mligo
	ligo compile-contract --output-file=$@ $^ main

$(OUT)/multi_asset.tz: ligo/fa2/multi_asset/fa2_multi_asset.mligo
	ligo compile-contract --output-file=$@ $^ main

$(OUT)/nft.tz:ligo/fa2/nft/fa2_nft_asset.mligo
	ligo compile-contract --output-file=$@ $^ main

$(OUT)/fees.tz:ligo/fees/main.mligo
	ligo compile-contract --output-file=$@ $^ main

$(META_OUT)/multi_asset.json: venv/bin/activate
	./venv/bin/python -m metadata multi_asset $@

$(META_OUT)/nft.json: venv/bin/activate
	./venv/bin/python -m metadata nft $@

$(META_OUT)/quorum.json: venv/bin/activate
	./venv/bin/python -m metadata quorum $@

$(META_OUT)/minter.json: venv/bin/activate
	./venv/bin/python -m metadata minter $@

clean:
	rm -f $(OUT)/*.tz
	rm -f $(META_OUT)/*.json

compile: $(OUT)/multi_asset.tz $(OUT)/quorum.tz $(OUT)/minter.tz $(OUT)/nft.tz $(OUT)/fees.tz

metadata: $(META_OUT)/multi_asset.json $(META_OUT)/nft.json $(META_OUT)/quorum.json $(META_OUT)/minter.json

all: compile metadata