import json
import sys
from pathlib import Path

from pytezos import PyTezosClient, Contract

from src.ligo import LigoContract
from cid import cid
from typing import TypedDict


def _print_contract(addr):
    print(
        f'Successfully originated {addr}\n'
        f'Check out the contract at https://you.better-call.dev/delphinet/{addr}')


class Token(TypedDict):
    eth_contract: str
    eth_symbol: str
    symbol: str
    name: str
    decimals: int


def _metadata_encode(content):
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

    def run(self, signers: dict[str, str], tokens: list[Token], threshold=1):
        fa2 = self._deploy_fa2(tokens)
        quorum = self._deploy_quorum(signers, threshold)
        minter = self._deploy_minter(quorum, tokens, fa2)
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

    def _deploy_fa2(self, tokens: list[Token]):
        print("Deploying fa2")
        meta = _metadata_encode({
            "interfaces": ["TZIP-12"],
            "name": "Wrap protocol FA2 tokens",
            "homepage": "https://github.com/bender-labs/wrap-tz-contracts",
            "license": {"name": "MIT"},
            "permissions": {
                "operator": "owner-or-operator-transfer",
                "receiver": "owner-no-hook",
                "sender": "owner-no-hook",
                "custom": {"tag": "PAUSABLE_TOKENS"},
            },
        })

        token_metadata = dict(
            [(k, {'token_id': k,
                  'extras': {'decimals': str(v['decimals']).encode().hex(),
                             'eth_contract': v['eth_contract'].encode().hex(),
                             'eth_symbol': v['eth_symbol'].encode().hex(),
                             'name': v['name'].encode().hex(),
                             'symbol': v['symbol'].encode().hex()
                             }}) for k, v in
             enumerate(tokens)])
        supply = dict([(k, 0) for k, v in enumerate(tokens)])
        initial_storage = self.fa2_contract.storage.encode({
            'admin': {
                'admin': self.client.key.public_key_hash(),
                'pending_admin': None,
                'paused': {}
            },
            'assets': {
                'ledger': {},
                'operators': {},
                'token_metadata': token_metadata,
                'token_total_supply': supply
            },
            'metadata': meta
        })
        print(f"Initial storage {initial_storage}")
        opg = self.client.origination(
            script={'code': self.fa2_contract.code, 'storage': initial_storage}).autofill().sign()
        contract_id = opg.result()[0].originated_contracts[0]
        opg.inject(_async=False)
        _print_contract(contract_id)
        return contract_id

    def _deploy_minter(self, quorum_contract, tokens: list[Token], fa2_contract):
        print("Deploying minter contract")
        token_metadata = dict((v["eth_contract"][2:], k) for k, v in enumerate(tokens))
        metadata = _metadata_encode({
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
                "tokens": token_metadata,
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
        metadata = _metadata_encode({
            "name": "Wrap protocol quorum contract",
            "homepage": "https://github.com/bender-labs/wrap-tz-contracts",
            "license": {"name": "MIT"},
        })
        print("Deploying quorum contract")
        initial_storage = self.quorum_contract.storage.encode({
            "admin": self.client.key.public_key_hash(),
            "threshold": threshold,
            "signers": signers,
            "metadata": metadata
        })
        print(f"Initial storage {initial_storage}")
        opg = self.client.origination(
            script={'code': self.quorum_contract.code, 'storage': initial_storage}).autofill().sign()
        contract_id = opg.result()[0].originated_contracts[0]
        opg.inject(_async=False)
        _print_contract(contract_id)
        return contract_id
