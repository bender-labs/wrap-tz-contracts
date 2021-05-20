from pathlib import Path

from pytezos import PyTezosClient, ContractInterface
from pytezos.operation.result import OperationResult

default_meta_uri = "https://gist.githubusercontent.com/BodySplash/2375d86cae6abf80eee06936331f88ac/raw/staking.json"


def _print_contract(addr):
    print(
        f'Successfully originated {addr}\n'
        f'Check out the contract at https://better-call.dev/florence/{addr}')


def _metadata_encode_uri(uri):
    meta_uri = str.encode(uri).hex()
    return {"": meta_uri}


class Staking(object):
    def __init__(self, client: PyTezosClient):
        self.client = client

        root_dir = Path(__file__).parent.parent / "michelson"
        self.staking_contract = ContractInterface.from_file(root_dir / "staking.tz")
        self.reserve_contract = ContractInterface.from_file(root_dir / "reserve.tz")

    def deploy_reserve(self, minter_contract):
        storage = {
            "admin": {"pending_admin": None, "address": self.client.key.public_key_hash()},
            "farms": {},
            "minter_contract": minter_contract,
        }
        origination = self.reserve_contract.originate(initial_storage=storage)
        self._originate_single_contract(origination)

    def deploy_staking(self, duration: int, reward_token: (str, int), wrap_token: (str, int), reserve_contract,
                       meta_uri=default_meta_uri):
        meta = _metadata_encode_uri(meta_uri)
        storage = {
            "ledger": {"total_supply": 0, "balances": {}},
            "delegators": {},
            "settings": {
                "duration": duration,
                "reward_token": reward_token,
                "staked_token": wrap_token,
                "reserve_contract": reserve_contract,
            },
            "reward": {
                "last_block_update": 0,
                "period_end": 0,
                "accumulated_reward_per_token": 0,
                "reward_per_block": 0,
            },
            "admin": {"address": self.client.key.public_key_hash(), "pending_admin": None},
            "metadata": meta
        }
        origination = self.staking_contract.originate(initial_storage=storage)
        self._originate_single_contract(origination)

    def register_contract(self, reserve_contract, staking_contract, reward_token:(str, int)):
        contract = self.client.contract(reserve_contract)
        op = contract.register_contract(staking_contract, reward_token[0], reward_token[1])
        self._inject(op)


    def _originate_single_contract(self, origination):
        opg = self.client.bulk(origination).autofill().sign().inject(min_confirmations=1)
        res = OperationResult.from_operation_group(opg)
        contract_id = res[0].originated_contracts[0]
        _print_contract(contract_id)
        return contract_id

    def _inject(self, payload):
        opg = self.client.bulk(payload).autofill().sign().inject(min_confirmations=1)
        print(f"Done {opg['hash']}")