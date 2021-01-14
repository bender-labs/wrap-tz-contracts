from pytezos import PyTezosClient


class Minter(object):

    def __init__(self, client: PyTezosClient):
        self.client = client

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
