import json
from pathlib import Path
from typing import TypedDict

from pytezos import Contract, OperationGroup

from src.ligo import LigoContract, LigoView, PtzUtils
from src.token import Token
from src.minter import Minter


def _print_contract(addr):
    print(
        f'Successfully originated {addr}\n'
        f'Check out the contract at https://you.better-call.dev/delphinet/{addr}')


class TokenType(TypedDict):
    eth_contract: str
    eth_symbol: str
    symbol: str
    name: str
    decimals: int


class NftType(TypedDict):
    eth_contract: str
    eth_symbol: str
    symbol: str
    name: str


def _metadata_encode(content):
    meta_content = json.dumps(content, indent=2).encode().hex()
    meta_uri = str.encode("tezos-storage:content").hex()
    return {"": meta_uri, "content": meta_content}


class Deploy(object):

    def __init__(self, client: PtzUtils):
        self.utils = client
        root_dir = Path(__file__).parent.parent / "michelson"
        self.minter_contract = Contract.from_file(root_dir / "minter.tz")
        self.quorum_contract = Contract.from_file(root_dir / "quorum.tz")
        self.fa2_contract = Contract.from_file(root_dir / "multi_asset.tz")
        self.nft_contract = Contract.from_file(root_dir / "nft.tz")

    def run(self, signers: dict[str, str], tokens: list[TokenType], nft: list[NftType], threshold=1):
        fa2 = self.fa2(tokens)
        nft_contracts = dict((v["eth_contract"][2:], self.nft(v)) for k, v in enumerate(nft))
        quorum = self._deploy_quorum(signers, threshold)
        minter = self._deploy_minter(quorum, tokens, fa2, nft_contracts)
        self._set_tokens_admin(minter, fa2, nft_contracts)
        self._confirm_admin(minter, fa2, nft_contracts)
        print(f"FA2 contract: {fa2}\nQuorum contract: {quorum}\nMinter contract: {minter}")

    def fa2(self, tokens: list[TokenType]):
        print("Deploying fa2")
        views = LigoView("./ligo/fa2/multi_asset/views.mligo")
        get_balance = views.compile("get_balance", "nat", "get_balance as defined in tzip-12")
        total_supply = views.compile("total_supply", "nat", "get_total supply as defined in tzip-12")
        is_operator = views.compile("is_operator", "bool", "is_operator as defined in tzip-12")
        token_metadata = views.compile("token_metadata", "(pair nat (map string bytes))",
                                       "token_metadata as defined in tzip-12")
        meta = _metadata_encode({
            "interfaces": ["TZIP-12", "TZIP-16"],
            "name": "Wrap protocol FA2 tokens",
            "homepage": "https://github.com/bender-labs/wrap-tz-contracts",
            "license": {"name": "MIT"},
            "permissions": {
                "operator": "owner-or-operator-transfer",
                "receiver": "optional-owner-hook",
                "sender": "optional-owner-hook",
                "custom": {"tag": "PAUSABLE_TOKENS"},
            },
            "views": [
                get_balance,
                total_supply,
                is_operator,
                token_metadata
            ]
        })

        token_metadata = dict(
            [(k, {'token_id': k,
                  'token_info': {'decimals': str(v['decimals']).encode().hex(),
                                 'eth_contract': v['eth_contract'].encode().hex(),
                                 'eth_symbol': v['eth_symbol'].encode().hex(),
                                 'name': v['name'].encode().hex(),
                                 'symbol': v['symbol'].encode().hex()
                                 }}) for k, v in
             enumerate(tokens)])
        supply = dict([(k, 0) for k, v in enumerate(tokens)])
        initial_storage = self.fa2_contract.storage.encode({
            'admin': {
                'admin': self.utils.client.key.public_key_hash(),
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
        contract_id = self.utils.originate(self.fa2_contract.code, initial_storage)
        _print_contract(contract_id)
        return contract_id

    def nft(self, token: NftType):
        print("Deploying NFT")
        views = LigoView("./ligo/fa2/nft/views.mligo")
        get_balance = views.compile("get_balance", "nat", "get_balance as defined in tzip-12")
        total_supply = views.compile("total_supply", "nat", "get_total supply as defined in tzip-12")
        is_operator = views.compile("is_operator", "bool", "is_operator as defined in tzip-12")
        token_metadata = views.compile("token_metadata", "(pair nat (map string bytes))",
                                       "token_metadata as defined in tzip-12")

        meta = _metadata_encode({
            "interfaces": ["TZIP-12", "TZIP-16"],
            "name": "Wrap protocol NFT token",
            "homepage": "https://github.com/bender-labs/wrap-tz-contracts",
            "license": {"name": "MIT"},
            "permissions": {
                "operator": "owner-or-operator-transfer",
                "receiver": "owner-no-hook",
                "sender": "owner-no-hook",
                "custom": {"tag": "PAUSABLE_TOKENS"},
            },
            "views": [
                get_balance,
                is_operator,
                token_metadata
            ]
        })

        generic_metadata = {'decimals': str(1).encode().hex(),
                            'eth_contract': token['eth_contract'].encode().hex(),
                            'eth_symbol': token['eth_symbol'].encode().hex(),
                            'name': token['name'].encode().hex(),
                            'symbol': token['symbol'].encode().hex()
                            }

        initial_storage = self.nft_contract.storage.encode({
            'admin': {
                'admin': self.utils.client.key.public_key_hash(),
                'pending_admin': None,
                'paused': False
            },
            'assets': {
                'ledger': {},
                'operators': {},
                'token_info': generic_metadata
            },
            'metadata': meta
        })
        contract_id = self.utils.originate(self.nft_contract.code, initial_storage)
        _print_contract(contract_id)
        return contract_id

    def _set_tokens_admin(self, minter, fa2, nfts):
        token = Token(self.utils)
        token.set_admin(fa2, minter)
        [token.set_admin(v, minter) for (i, v) in nfts.items()]

    def _confirm_admin(self, minter, fa2_contract, nfts):
        minter_contract = Minter(self.utils)
        minter_contract.confirm_admin(minter, [v for (i, v) in nfts.items()] + [fa2_contract])

    def _deploy_minter(self, quorum_contract, tokens: list[TokenType], fa2_contract, nft_contracts):
        print("Deploying minter contract")
        fungible_tokens = dict((v["eth_contract"][2:], [fa2_contract, k]) for k, v in enumerate(tokens))
        metadata = _metadata_encode({
            "name": "Wrap protocol minter contract",
            "homepage": "https://github.com/bender-labs/wrap-tz-contracts",
            "license": {"name": "MIT"},
        })
        initial_storage = self.minter_contract.storage.encode({
            "admin": {
                "administrator": self.utils.client.key.public_key_hash(),
                "signer": quorum_contract,
                "paused": False
            },
            "assets": {
                "erc20_tokens": fungible_tokens,
                "erc721_tokens": nft_contracts,
                "mints": {}
            },
            "governance": {
                "contract": self.utils.client.key.public_key_hash(),
                "fees_contract": self.utils.client.key.public_key_hash(),
                "erc20_wrapping_fees": 100,
                "erc20_unwrapping_fees": 100,
                "erc721_wrapping_fees": 500_000,
                "erc721_unwrapping_fees": 500_000
            },
            "metadata": metadata
        })

        contract_id = self.utils.originate(self.minter_contract.code, initial_storage)
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
            "admin": self.utils.client.key.public_key_hash(),
            "threshold": threshold,
            "signers": signers,
            "metadata": metadata
        })
        contract_id = self.utils.originate(self.quorum_contract.code, initial_storage)
        _print_contract(contract_id)
        return contract_id
