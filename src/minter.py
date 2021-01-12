from pytezos import PyTezosClient

from src.ligo import LigoContract


class Minter(object):

    def __init__(self, client: PyTezosClient):
        self.client = client
        self.contract = LigoContract("./ligo/minter/main.religo", "main")

    def originate(self, fa2_contract):
        app = self.contract.get_contract()

        initial_storage = app.storage.encode({
            "admin": {
                "administrator": self.client.key.public_key_hash(),
                "governance": self.client.key.public_key_hash(),
                "signer": self.client.key.public_key_hash()
            },
            "assets": {
                "fa2_contract": fa2_contract,
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

    def add_token(self, contract_id, token_id, eth_contract, eth_symbol, symbol, name, decimals):
        contract = self.client.contract(contract_id)

        op = contract.add_token(token_id=token_id, eth_contract=eth_contract, eth_symbol=eth_symbol, symbol=symbol,
                                name=name,
                                decimals=decimals).inject()
        print(op)

    def mint(self, contract_id, token_id, tx_id, destination, amount):
        contract = self.client.contract(contract_id)
        op = contract.mint(token_id=token_id, tx_id=tx_id, owner=destination, amount=int(amount) * 10 ** 16) \
            .inject()
        print(op)

    def burn(self, contract_id, token_id, amount, destination):
        contract = self.client.contract(contract_id)
        op = contract.burn(token_id=token_id, amount=int(amount) * 10 ** 16, destination=destination) \
            .inject()
        print(op)

    def confirm_admin(self, contract_id):
        contract = self.client.contract(contract_id)
        op = contract.confirm_tokens_administrator(None) \
            .inject()
        print(op)

    def set_signer(self, contract_id, minter_contract):
        contract = self.client.contract(contract_id)
        op = contract.set_signer(minter_contract).inject()
        print(op)
