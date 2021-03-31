from pytezos import PyTezosClient
from pytezos.operation.result import OperationResult


class Minter(object):

    def __init__(self, client: PyTezosClient):
        self.client = client

    def unwrap_erc20(self, contract_id, erc_20, amount, fees, destination):
        contract = self._contract(contract_id)
        op = contract.unwrap_erc20(erc_20=erc_20, amount=int(amount), fees=int(fees), destination=destination) \
            .inject(_async=False)
        self._print(op)

    def unwrap_erc721(self, contract_id, erc_721, token_id, destination):
        contract = self._contract(contract_id)
        op = contract.unwrap_erc721(erc_721=erc_721, token_id=int(token_id), destination=destination) \
            .with_amount(500_000) \
            .inject(_async=False)
        self._print(op)

    def confirm_admin(self, contract_id, fa2_contracts):
        print(f"Confirming admin on {contract_id} for {fa2_contracts}")
        call = self.confirm_admin_call(contract_id, fa2_contracts)
        op = call.autofill().sign().inject(_async=False)
        self._print(op)

    def confirm_admin_call(self, contract_id, fa2_contracts):
        contract = self._contract(contract_id)
        call = contract \
            .confirm_tokens_administrator(fa2_contracts)
        return call

    def set_signer(self, contract_id, quorum_contract):
        contract = self._contract(contract_id)
        op = contract.set_signer(quorum_contract).inject(_async=False)
        self._print(op)

    def set_administrator(self, contract_id, administrator):
        contract = self._contract(contract_id)
        op = contract.set_administrator(administrator).inject(_async=False)
        self._print(op)

    def pause_contract(self, contract_id, token_id):
        contract = self._contract(contract_id)
        op = contract.pause_contract([[token_id, True]]).inject(_async=False)
        self._print(op)

    def unpause_contract(self, contract_id, token_id):
        contract = self._contract(contract_id)
        op = contract.pause_contract([[token_id, False]]).inject(_async=False)
        self._print(op)

    def withdraw_all_tokens(self, contract_id, fa2, tokens: [int]):
        contract = self._contract(contract_id)
        op = contract.withdraw_all_tokens(fa2, tokens).inject(_async=False)
        self._print(op)

    def _contract(self, contract_id):
        return self.client.contract(contract_id)

    def _print(self, opg):
        res = OperationResult.from_operation_group(opg)
        print(f"Done {res[0]['hash']}")
