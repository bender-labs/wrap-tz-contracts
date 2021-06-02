import json
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

    def deploy_reserve(self, minter_contract, admin=None):
        admin = self.client.key.public_key_hash() if admin is None else admin
        storage = {
            "admin": {"pending_admin": None, "address": admin},
            "farms": {},
            "minter_contract": minter_contract,
        }
        origination = self.reserve_contract.originate(initial_storage=storage)
        self._originate_single_contract(origination)

    def _staking_storage(self, meta_uri, duration, wrap_token, reserve_contract, admin=None, token=None):
        meta = _metadata_encode_uri(meta_uri)
        admin = self.client.key.public_key_hash() if admin is None else admin
        if token is not None:
            meta["token"] = str.encode(token).hex()
        return {
            "ledger": {"total_supply": 0, "balances": {}},
            "delegators": {},
            "settings": {
                "duration": duration,
                "staked_token": wrap_token,
                "reserve_contract": reserve_contract,
            },
            "reward": {
                "last_block_update": 0,
                "period_end": 0,
                "accumulated_reward_per_token": 0,
                "reward_per_block": 0,
                "reward_remainder": 0
            },
            "admin": {"address": admin, "pending_admin": None},
            "metadata": meta
        }

    def deploy_staking(self, duration: int, wrap_token: (str, int), reserve_contract,
                       meta_uri=default_meta_uri):
        storage = self._staking_storage(meta_uri, duration, wrap_token, reserve_contract)
        origination = self.staking_contract.originate(initial_storage=storage)
        self._originate_single_contract(origination)

    def deploy_all_staking(self, file_path, meta_uri=default_meta_uri, admin=None):
        with open(file_path) as f:
            data = json.load(f)
            duration = data["duration"]
            wrap_token = data["wrap_token"]
            reserve_contract = data["reserve_contract"]
            storages = list(
                map(lambda x: self._staking_storage(meta_uri, duration, wrap_token, reserve_contract, token=x["name"],
                                                    admin=admin),
                    data["tokens"]))
            chunk = 5
            contracts = []
            for i in range(10, len(storages), chunk):
                print(f"deploy {i} to {i + chunk}")
                local = storages[i:i + chunk]
                ops = list(map(lambda s: self.staking_contract.originate(initial_storage=s), local))

                opg = self.client.bulk(*ops).autofill().sign().inject(min_confirmations=1)
                print(f"Injected {opg['hash']}")
                deployed = OperationResult.originated_contracts(opg)
                print(f"Deployed {deployed}")
                contracts += deployed
            result = [{"contract": contract, **(data["tokens"][index])} for index, contract in enumerate(contracts)]
            print(json.dumps({"reserve_contract": reserve_contract, "contracts": result}))

    def register_contract(self, reserve_contract, staking_contract, reward_token: (str, int)):
        contract = self.client.contract(reserve_contract)
        op = contract.register_contract(staking_contract, reward_token[0], reward_token[1])
        self._inject(op)

    def register_all_contracts(self, file_path):
        with open(file_path) as f:
            data = json.load(f)
            contract = self.client.contract(data["reserve_contract"])
            bulk = list(map(lambda x:
                            contract.register_contract(x["contract"], x["reward"][0], x["reward"][1])
                            , data["contracts"]))
            opg = self.client.bulk(*bulk).autofill().sign().inject(min_confirmations=1)
            print(f"Done {opg['hash']}")

    def _originate_single_contract(self, origination):
        opg = self.client.bulk(origination).autofill().sign().inject(min_confirmations=1)
        res = OperationResult.from_operation_group(opg)
        contract_id = res[0].originated_contracts[0]
        _print_contract(contract_id)
        return contract_id

    def _inject(self, payload):
        opg = self.client.bulk(payload).autofill().sign().inject(min_confirmations=1)
        print(f"Done {opg['hash']}")
