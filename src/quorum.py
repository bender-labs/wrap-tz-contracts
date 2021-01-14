from pytezos import PyTezosClient
from cid import cid


class Quorum(object):
    def __init__(self, client: PyTezosClient):
        self.client = client

    def mint(self, contract_id, minter_contract, owner, amount, tx_id, token_id, signer_id, signature):
        contract = self.client.contract(contract_id)
        id = cid.from_string(signer_id)
        mint = {"amount": amount, "owner": owner,
                "token_id": token_id,
                "tx_id": tx_id}
        print(contract.minter)
        op = contract \
            .minter(signatures=[[id.multihash, signature]],
                    action={"target": f"{minter_contract}%signer",
                            "entry_point": {"mint_token": mint}},
                    ) \
            .inject()
        print(op)
