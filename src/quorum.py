from pytezos import PyTezosClient


class Quorum(object):
    def __init__(self, client: PyTezosClient):
        self.client = client

    def mint(self, contract_id, minter_contract, owner, amount, block_hash, log_index, token_id, signer_id, signature):
        contract = self.client.contract(contract_id)
        mint = {"amount": amount, "owner": owner,
                "token_id": token_id,
                "event_id": {
                    "block_hash": block_hash,
                    "log_index": log_index}}
        print(contract.minter)
        op = contract \
            .minter(signatures=[[signer_id, signature]],
                    action={"target": f"{minter_contract}%signer",
                            "entry_point": {"mint_token": mint}},
                    ) \
            .inject()
        print(op)
