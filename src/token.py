from src.ligo import PtzUtils


class Token(object):

    def __init__(self, client: PtzUtils):
        self.utils = client

    def set_admin(self, contract_id, new_admin):
        print(f"Setting fa2 admin on {contract_id} to {new_admin}")
        contract = self.utils.client.contract(contract_id)
        op = contract \
            .set_admin(new_admin) \
            .inject()
        res = self.utils.wait_for_ops(op)
        print(f"Done {res[0]['hash']}")
