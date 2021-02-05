from pytezos import PyTezosClient

from src.ligo import PtzUtils


class Quorum(object):
    def __init__(self, client: PtzUtils):
        self.utils = client

    def mint_erc20(self, contract_id, minter_contract, owner, amount, block_hash, log_index, erc_20, signer_id, signature):
        contract = self.utils.client.contract(contract_id)
        mint = {"amount": amount, "owner": owner,
                "erc_20": erc_20,
                "event_id": {
                    "block_hash": block_hash,
                    "log_index": log_index}}
        op = contract \
            .minter(signatures=[[signer_id, signature]],
                    action={"target": f"{minter_contract}%signer",
                            "entry_point": {"mint_erc20": mint}},
                    ) \
            .inject()
        res = self.utils.wait_for_ops(op)
        print(f"Done{res[0]['hash']}")

    def mint_erc721(self, contract_id, minter_contract, owner, token_id, block_hash, log_index, erc_721, signer_id, signature):
        contract = self.utils.client.contract(contract_id)
        mint = {"token_id": token_id, "owner": owner,
                "erc_721": erc_721,
                "event_id": {
                    "block_hash": block_hash,
                    "log_index": log_index}}
        op = contract \
            .minter(signatures=[[signer_id, signature]],
                    action={"target": f"{minter_contract}%signer",
                            "entry_point": {"mint_erc721": mint}},
                    ) \
            .with_amount(500_000) \
            .inject()
        res = self.utils.wait_for_ops(op)
        print(f"Done{res[0]['hash']}")