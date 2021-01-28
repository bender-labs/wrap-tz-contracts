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
