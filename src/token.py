from pathlib import Path

from pytezos import Contract, PyTezosClient


class Token(object):

    def __init__(self, client: PyTezosClient):
        self.client = client

    def originate(self, bender_contract_id):
        root_dir = Path(__file__).parent.parent / "michelson"
        app = Contract.from_file(root_dir / "fa2.tz")
        initial_storage = app.storage.encode({
            'admin': {
                'admin': bender_contract_id,
                'pending_admin': None,
                'paused': False
            },
            'assets': {
                'ledger': {},
                'operators': {},
                'token_metadata': {
                    0: {
                        'token_id': 0,
                        'symbol': 'BOD',
                        'name': 'Body Token',
                        'decimals': 16,
                        'extras': {}
                    }
                },
                'total_supply': 0
            }
        })

        opg = self.client.origination(script={'code': app.code, 'storage': initial_storage}).autofill().sign()
        contract_id = opg.result()[0].originated_contracts[0]
        opg.inject()
        print(
            f'Successfully originated {contract_id}\n'
            f'Check out the contract at https://better-call.dev/delphinet/{contract_id}')
