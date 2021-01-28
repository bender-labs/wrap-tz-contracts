from pytezos import PyTezosClient


class Minter(object):

    def __init__(self, client: PyTezosClient):
        self.client = client

    def burn(self, contract_id, token_id, amount, fees, destination):
        contract = self.client.contract(contract_id)
        op = contract.unwrap(token_id=token_id, amount=int(amount), fees=int(fees), destination=destination) \
            .inject()
        print(op)

    def confirm_admin(self, contract_id):
        contract = self.client.contract(contract_id)
        op = contract.confirm_tokens_administrator(None) \
            .inject()
        print(op)

    def set_signer(self, contract_id, quorum_contract):
        contract = self.client.contract(contract_id)
        op = contract.set_signer(quorum_contract).inject()
        print(op)

    def set_administrator(self, contract_id, administrator):
        contract = self.client.contract(contract_id)
        op = contract.set_administrator(administrator).inject()
        print(op)

    def pause_contract(self, contract_id):
        contract = self.client.contract(contract_id)
        op = contract.pause_contract(True).inject()
        print(op)

    def unpause_contract(self, contract_id):
        contract = self.client.contract(contract_id)
        op = contract.pause_contract(False).inject()
        print(op)