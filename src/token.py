from pytezos import PyTezosClient


class Token(object):

    def __init__(self, client: PyTezosClient):
        self.client = client

    def set_admin(self, contract_id, new_admin):
        print(f"Setting fa2 admin on {contract_id} to {new_admin}")
        call = self.set_admin_call(contract_id, new_admin)
        res = call.autofill().sign().inject(_async=False)
        print(f"Done {res[0]['hash']}")

    def set_admin_call(self, contract_id, new_admin):
        contract = self.client.contract(contract_id)
        op = contract \
            .set_admin(new_admin)
        return op

    def set_minter_call(self, contract_id, new_admin):
        contract = self.client.contract(contract_id)
        op = contract \
            .set_minter(new_admin)
        return op