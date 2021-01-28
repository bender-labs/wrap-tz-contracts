.PHONY: test clean

venv/bin/activate: requirements.txt
	python3 -m venv venv
	./venv/bin/pip install -r requirements.txt

test: venv/bin/activate
	./venv/bin/python -m unittest discover -s test -t test

michelson/quorum.tz:
	ligo compile-contract --output-file=$@ ligo/quorum/multisig.religo main

michelson/minter.tz:
	ligo compile-contract --output-file=$@ ligo/minter/main.religo main

clean:
	rm -f michelson/quorum.tz
	rm -f michelson/minter.tz

compile: michelson/quorum.tz michelson/minter.tz