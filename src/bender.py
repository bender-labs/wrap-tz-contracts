from io import TextIOWrapper
from subprocess import Popen, PIPE

from pytezos import Contract, PyTezosClient


def compile_contract():
    command = f"ligo compile-contract ./ligo/bender.religo main"
    compiled_michelson = _ligo_to_michelson(command)
    return Contract.from_michelson(compiled_michelson)


def _ligo_to_michelson(command):
    with Popen(command, stdout=PIPE, stderr=PIPE, shell=True) as p:
        with TextIOWrapper(p.stdout) as out, TextIOWrapper(p.stderr) as err:
            michelson = out.read()
            if not michelson:
                msg = err.read()
                raise Exception(msg)
            else:
                return michelson


class Bender(object):

    def __init__(self, client: PyTezosClient):
        self.client = client

    def originate(self):
        app = compile_contract()

        initial_storage = app.storage.encode({
            "admin": {
                "administrator": self.client.key.public_key_hash(),
                "governance": self.client.key.public_key_hash(),
                "signer": self.client.key.public_key_hash()
            },
            "assets": {
                "fees_contract": self.client.key.public_key_hash(),
                "fees_ratio": 10,
                "tokens": {},
                "mints": {}
            }

        })
        opg = self.client.origination(script={'code': app.code, 'storage': initial_storage}).autofill().sign()
        contract_id = opg.result()[0].originated_contracts[0]
        opg.inject()
        print(
            f'Successfully originated {contract_id}\n'
            f'Check out the contract at https://you.better-call.dev/delphinet/{contract_id}')

    def add_token(self, contract_id, token_id, token_contract_id):
        contract = self.client.contract(contract_id)
        op = contract.add_token(token_id, token_contract_id).inject()
        print(op)

    def mint(self, contract_id, token_id, tx_id, destination, amount):
        contract = self.client.contract(contract_id)
        print(contract.mint)
        op = contract.mint(token_id=token_id, tx_id=tx_id, owner=destination, amount=int(amount) * 10 ** 16) \
            .inject()
        print(op)
