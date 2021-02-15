.PHONY: test clean

OUT = michelson

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

clean:
	rm -f $(OUT)/*.tz

compile: $(OUT)/multi_asset.tz $(OUT)/quorum.tz $(OUT)/minter.tz $(OUT)/nft.tz $(OUT)/fees.tz