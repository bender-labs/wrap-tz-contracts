.PHONY: test clean

OUT = michelson

venv/bin/activate: requirements.txt
	python3 -m venv venv
	./venv/bin/pip install -r requirements.txt

test: venv/bin/activate
	./venv/bin/python -m unittest discover -s test -t test

$(OUT)/quorum.tz:
	ligo compile-contract --output-file=$@ ligo/quorum/multisig.mligo main

$(OUT)/minter.tz:
	ligo compile-contract --output-file=$@ ligo/minter/main.mligo main

$(OUT)/multi_asset.tz:
	ligo compile-contract --output-file=$@ ligo/fa2/multi_asset/fa2_multi_asset.mligo multi_asset_main

clean:
	rm -f $(OUT)/quorum.tz
	rm -f $(OUT)/minter.tz
	rm -f $(OUT)/multi_asset.tz

compile: $(OUT)/multi_asset.tz $(OUT)/quorum.tz $(OUT)/minter.tz