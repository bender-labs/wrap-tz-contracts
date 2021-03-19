from pytezos import PyTezosClient


class Governance(object):

    def __init__(self, client: PyTezosClient):
        self.client = client

    def distribute(self, contract_id, to, amount):
        print(f"Distributing {amount} to {to}")
        contract = self.client.contract(contract_id)
        call = self.client.bulk(contract.distribute([(to, amount * 10 ** 8)]))

        res = call.autofill().sign().inject(_async=False)
        print(f"Done {res[0]['hash']}")