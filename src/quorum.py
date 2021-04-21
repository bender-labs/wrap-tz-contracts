from pytezos import PyTezosClient
from pytezos.operation.result import OperationResult


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
        self._print_opg(op)

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
        self._print_opg(op)

    def change(self, contract_id, signers: dict[str, str], threshold=1):
        contract = self.client.contract(contract_id)
        opg = contract.change_quorum(threshold, signers).inject(_async=False)
        self._print_opg(opg)

    def distribute_xtz(self, contract_id, minter_contract):
        contract = self.client.contract(contract_id)
        opg = contract.distribute_xtz_with_quorum(minter_contract).inject(_async=False)
        self._print_opg(opg)

    def distribute_tokens(self, contract_id, minter_contract, tokens: [tuple[str, int]]):
        contract = self.client.contract(contract_id)
        self._inject(contract.distribute_tokens_with_quorum(minter_contract, tokens))

    def set_payment_address(self, contract_id, minter_contract, signer_id, signature):
        contract = self.client.contract(contract_id)
        payment_address = self.client.address
        print(f"Using {payment_address}")
        opg = contract.set_signer_payment_address(minter_contract=minter_contract, signature=signature,
                                                  signer_id=signer_id).inject(_async=False)
        self._print_opg(opg)

    def _inject(self, payload):
        opg = self.client.bulk(payload).autofill().sign().inject(min_confirmations=1)
        print(f"Done {opg['hash']}")