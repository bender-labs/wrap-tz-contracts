from pathlib import Path

from pytezos import Contract, PyTezosClient


class Token(object):

    def __init__(self, client: PyTezosClient):
        self.client = client

    def originate(self):
        root_dir = Path(__file__).parent.parent / "michelson"
        app = Contract.from_file(root_dir / "fa2.tz")
        initial_storage = app.storage.encode({
            'admin': {
                'admin': self.client.key.public_key_hash(),
                'pending_admin': None,
                'paused': False
            },
            'assets': {
                'ledger': {},
                'operators': {},
                'token_metadata': {},
                'token_total_supply': {}
            }
        })

        opg = self.client.origination(script={'code': app.code, 'storage': initial_storage}).autofill().sign()
        contract_id = opg.result()[0].originated_contracts[0]
        opg.inject()
        print(
            f'Successfully originated {contract_id}\n'
            f'Check out the contract at https://you.better-call.dev/delphinet/{contract_id}')

    def set_admin(self, contract_id, new_admin):
        contract = self.client.contract(contract_id)
        op = contract \
            .set_admin(new_admin) \
            .inject()
        print(op)

    def mint(self, contract_id, amount):
        contract = self.client.contract(contract_id)
        print(contract.mint_tokens)
        op = contract \
            .mint_tokens([{"owner": self.client.key.public_key_hash(), "amount": int(amount) * 10 ** 1016}]) \
            .inject()
        print(op)
