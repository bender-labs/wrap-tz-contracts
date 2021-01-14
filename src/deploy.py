import json
from pathlib import Path

from pytezos import PyTezosClient, Contract

from src.ligo import LigoContract
from cid import cid


def _print_contract(addr):
    print(
        f'Successfully originated {addr}\n'
        f'Check out the contract at https://you.better-call.dev/delphinet/{addr}')


def _meta_data(content):
    meta_content = json.dumps(content, indent=2).encode().hex()
    meta_uri = str.encode("tezos-storage:content").hex()
    return {"": meta_uri, "content": meta_content}


class Deploy(object):

    def __init__(self, client: PyTezosClient):
        self.client = client
        self.minter_contract = LigoContract("./ligo/minter/main.religo", "main").get_contract().contract
        self.quorum_contract = LigoContract("./ligo/quorum/multisig.religo", "main").get_contract().contract
        root_dir = Path(__file__).parent.parent / "michelson"
        self.fa2_contract = Contract.from_file(root_dir / "fa2.tz")

    def run(self, signers: dict[str, str], threshold=1, ):
        quorum = self._deploy_quorum(signers, threshold)
        fa2 = self._deploy_fa2()
        minter = self._deploy_minter(quorum, fa2)
        self._set_fa2_admin(minter, fa2)
        self._confirm_admin(minter)

    def _confirm_admin(self, minter):
        print("Confirming admin")
        contract = self.client.contract(minter)
        op = contract.confirm_tokens_administrator(None) \
            .inject(_async=False)
        print("Done")

    def _set_fa2_admin(self, minter, fa2):
        print("Setting fa2 admin")
        contract = self.client.contract(fa2)
        op = contract \
            .set_admin(minter) \
            .inject(_async=False)
        print("Done")

    def _deploy_fa2(self):
        print("Deploying fa2")
        initial_storage = self.fa2_contract.storage.encode({
            'admin': {
                'admin': self.client.key.public_key_hash(),
                'pending_admin': None,
                'paused': {}
            },
            'assets': {
                'ledger': {},
                'operators': {},
                'token_metadata': {},
                'token_total_supply': {}
            }
        })
        print(f"Initial storage {initial_storage}")
        opg = self.client.origination(
            script={'code': self.fa2_contract.code, 'storage': initial_storage}).autofill().sign()
        contract_id = opg.result()[0].originated_contracts[0]
        opg.inject(_async=False)
        _print_contract(contract_id)
        return contract_id

    def _deploy_minter(self, quorum_contract, fa2_contract):
        print("Deploying minter contract")
        metadata = _meta_data({
            "name": "Wrap protocol minter contract",
            "homepage": "https://github.com/bender-labs/wrap-tz-contracts",
            "license": {"name": "MIT"},
        })
        initial_storage = self.minter_contract.storage.encode({
            "admin": {
                "administrator": self.client.key.public_key_hash(),
                "signer": quorum_contract,
                "paused": False
            },
            "assets": {
                "fa2_contract": fa2_contract,
                "tokens": {},
                "mints": {}
            },
            "governance": {
                "contract": self.client.key.public_key_hash(),
                "fees_contract": self.client.key.public_key_hash(),
                "wrapping_fees": 100,
                "unwrapping_fees": 100,
            },
            "metadata": metadata
        })
        print(f"Initial storage {initial_storage}")
        opg = self.client.origination(
            script={'code': self.minter_contract.code, 'storage': initial_storage}).autofill().sign()
        contract_id = opg.result()[0].originated_contracts[0]
        opg.inject(_async=False)
        _print_contract(contract_id)
        return contract_id

    def _deploy_quorum(self, signers: dict[str, str], threshold):
        metadata = _meta_data({
            "name": "Wrap protocol quorum contract",
            "homepage": "https://github.com/bender-labs/wrap-tz-contracts",
            "license": {"name":"MIT"},
        })
        print("Deploying quorum contract")
        with_hash = {cid.from_string(k).multihash: v for (k, v) in signers.items()}
        initial_storage = self.quorum_contract.storage.encode({
            "admin": self.client.key.public_key_hash(),
            "threshold": threshold,
            "signers": with_hash,
            "metadata": metadata
        })
        print(f"Initial storage {initial_storage}")
        opg = self.client.origination(
            script={'code': self.quorum_contract.code, 'storage': initial_storage}).autofill().sign()
        contract_id = opg.result()[0].originated_contracts[0]
        opg.inject(_async=False)
        _print_contract(contract_id)
        return contract_id
