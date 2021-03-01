from pytezos import PyTezosClient, OperationResult


class Quorum(object):
    def __init__(self, client: PyTezosClient):
        self.client = client

    def mint_erc20(self, contract_id, minter_contract, owner, amount, block_hash, log_index, erc_20, signer_id,
                   signature):
        contract = self.client.contract(contract_id)
        mint = {"amount": amount, "owner": owner,
                "erc_20": erc_20,
                "event_id": {
                    "block_hash": block_hash,
                    "log_index": log_index}}
        op = contract \
            .minter(signatures=[[signer_id, signature]],
                    action={"target": f"{minter_contract}",
                            "entrypoint": {"mint_erc20": mint}},
                    ) \
            .inject(_async=False)
        self.print_opg(op)

    def mint_erc721(self, contract_id, minter_contract, owner, token_id, block_hash, log_index, erc_721, signer_id,
                    signature):
        contract = self.client.contract(contract_id)
        mint = {"token_id": token_id, "owner": owner,
                "erc_721": erc_721,
                "event_id": {
                    "block_hash": block_hash,
                    "log_index": log_index}}
        op = contract \
            .minter(signatures=[[signer_id, signature]],
                    action={"target": f"{minter_contract}",
                            "entrypoint": {"mint_erc721": mint}},
                    ) \
            .with_amount(500_000) \
            .inject(_async=False)
        self.print_opg(op)

    def change(self, contract_id, signers: dict[str, str], threshold=1):
        contract = self.client.contract(contract_id)
        opg = contract.change_quorum(threshold, signers).inject(_async=False)
        self.print_opg(opg)

    def distribute_xtz(self, contract_id, minter_contract):
        contract = self.client.contract(contract_id)
        opg = contract.distribute_xtz_with_quorum(minter_contract).inject(_async=False)
        self.print_opg(opg)

    def print_opg(self, opg):
        contents = OperationResult.get_contents(opg)
        print(f"Done {opg['hash']}")
        print(f"{OperationResult.get_result(contents[0])}")
        print(f"{OperationResult.consumed_gas(opg)}")
