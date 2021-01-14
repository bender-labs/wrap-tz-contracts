from pytezos import PyTezosClient


class Token(object):

    def __init__(self, client: PyTezosClient):
        self.client = client

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
