.PHONY: test

venv/bin/activate: requirements.txt
	python3 -m venv venv
	./venv/bin/pip install -r requirements.txt

test: venv/bin/activate
	./venv/bin/python -m unittest discover -s test -t test