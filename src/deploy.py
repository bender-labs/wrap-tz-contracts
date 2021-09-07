import json
from pathlib import Path
from typing import TypedDict

from pytezos import ContractInterface, PyTezosClient
from pytezos.operation.result import OperationResult

_fa2_default_meta = "ipfs://QmT4qMBAK6qqXvr9sy3zVAWxY9Xh8siyLD8uw2w1UT74GY"

_nft_default_meta = "ipfs://QmWfncMgdmgtXEz5b8K2BGcyYT8FjVTT2fucFqYwyVBFtE"

_minter_default_meta = "ipfs://QmdY732YxFG3WjH18nFRWKmbkGjuY1SJQ7F81RHMmzq2bs"

_quorum_default_meta = "ipfs://QmPTL9zcLxvu1RrTkTcfEG9uTtDLNgUczWRBZHxCfidaEA"

_governance_default_meta = "ipfs://QmUgy4ETL2quUgTBKoLvWvFobHsZ5A1QdrcdVJEuWURyhX"


def _print_contract(addr):
    print(
        f'Successfully originated {addr}\n'
        f'Check out the contract at https://better-call.dev/edo2net/{addr}')


class TokenAndMetaType(TypedDict):
    eth_contract: str
    eth_symbol: str
    eth_name: str
    symbol: str
    name: str
    decimals: int


class FtTokenType(TypedDict):
    eth_contract: str
    fa2: str
    token_id: int


class FtTokenType(TypedDict):
    eth_contract: str
    fa2: str


class NftTokenAndMetaType(TypedDict):
    eth_contract: str
    eth_symbol: str
    eth_name: str
    symbol: str
    name: str


def _metadata_encode(content):
    meta_content = json.dumps(content, indent=2).encode().hex()
    meta_uri = str.encode("tezos-storage:content").hex()
    return {"": meta_uri, "content": meta_content}


def _metadata_encode_uri(uri):
    meta_uri = str.encode(uri).hex()
    return {"": meta_uri}


class Deploy(object):

    def __init__(self, client: PyTezosClient):
        self.client = client

        root_dir = Path(__file__).parent.parent / "michelson"
        self.minter_contract = ContractInterface.from_file(root_dir / "minter.tz")
        self.quorum_contract = ContractInterface.from_file(root_dir / "quorum.tz")
        self.fa2_contract = ContractInterface.from_file(root_dir / "multi_asset.tz")
        self.nft_contract = ContractInterface.from_file(root_dir / "nft.tz")
        self.governance_contract = ContractInterface.from_file(root_dir / "governance_token.tz")

    def all(self, signers: dict[str, str], governance_token, tokens: list[TokenAndMetaType], nft: list[NftTokenAndMetaType],
            threshold=1):
        originations = [self._fa2_origination(tokens), self._governance_token_origination(governance_token)]
        originations.extend([self._nft_origination(v) for k, v in enumerate(nft)])
        print("Deploying FA2s and nfts")
        opg = self.client.bulk(*originations).autofill().sign().inject(min_confirmations=1)
        originated_contracts = OperationResult.originated_contracts(opg)
        for o in originated_contracts:
            _print_contract(o)
        fa2 = originated_contracts[0]
        governance = originated_contracts[1]
        nft_contracts = dict((v["eth_contract"][2:], originated_contracts[k + 2]) for k, v in enumerate(nft))

        print("Deploying quorum contract")
        quorum = self._originate_single_contract(self._quorum_origination(signers, threshold))

        minter = self._deploy_minter(quorum, tokens, fa2,
                                     {'tezos': governance, 'eth': governance_token}, nft_contracts)
        admin_calls = self._set_tokens_minter(minter, fa2, governance, nft_contracts)
        print("Setting and confirming FA2s administrator")
        self.client.bulk(*admin_calls).autofill().sign().inject(min_confirmations=1)
        print(f"Nfts contracts: {nft_contracts}\n")
        print(
            f"FA2 contract: {fa2}\nGovernance token: {governance}\nQuorum contract: {quorum}\nMinter contract: {minter}")

    def governance_token(self, eth_address, admin=None, minter=None, oracle=None, meta_uri=_governance_default_meta):
        print("Deploying governance token")
        origination = self._governance_token_origination(eth_address, admin, minter, oracle, meta_uri)
        return self._originate_single_contract(origination)

    def _governance_token_origination(self, eth_address, admin=None, minter=None, oracle=None,
                                      meta_uri=_governance_default_meta):
        meta = _metadata_encode_uri(meta_uri)
        token_metadata = {
            0: {
                'token_id': 0,
                'token_info':
                    {
                        'decimals': '8'.encode().hex(),
                        'name': 'Wrap Governance Token'.encode().hex(),
                        'symbol': 'WRAP'.encode().hex(),
                        'thumbnailUri': 'ipfs://Qma2o69VRZe8aPsuCUN1VRUE5k67vw2mFDXb35uDkqn17o'.encode().hex(),
                        'eth_contract': eth_address.encode().hex(),
                        'eth_name': 'Wrap Governance Token'.encode().hex(),
                        'eth_symbol': 'WRAP'.encode().hex(),
                    }
            }
        }
        initial_storage = {
            'admin': {
                'admin': self.client.key.public_key_hash() if admin is None else admin,
                'paused': False,
                'pending_admin': None,
                'minter': self.client.key.public_key_hash() if minter is None else minter
            },
            'metadata': meta,
            'assets': {'ledger': {},
                       'operators': {},
                       'token_metadata': token_metadata,
                       'total_supply': 0,
                       },
            'oracle': {
                'role': {
                    'contract': self.client.key.public_key_hash() if oracle is None else oracle,
                    'pending_contract': None
                },
                'max_supply': 100_000_000 * 10 ** 8,
                'distributed': 0
            }
        }

        return self.governance_contract.originate(initial_storage=initial_storage)

    def fa2(self, tokens: list[TokenAndMetaType],
            meta_uri=_fa2_default_meta,
            admin=None,
            minter=None):
        print("Deploying fa2")
        origination = self._fa2_origination(tokens, admin, minter, meta_uri)
        return self._originate_single_contract(origination)

    def _fa2_origination(self, tokens, admin=None, minter=None, meta_uri=_fa2_default_meta):
        meta = _metadata_encode_uri(meta_uri)
        token_metadata = dict(
            [(k, {'token_id': k,
                  'token_info': self._token_info(v)}) for k, v in
             enumerate(tokens)])
        supply = dict([(k, 0) for k, v in enumerate(tokens)])
        initial_storage = {
            'admin': {
                'admin': self.client.key.public_key_hash() if admin is None else admin,
                'pending_admin': None,
                'paused': {},
                'minter': self.client.key.public_key_hash() if minter is None else minter
            },
            'assets': {
                'ledger': {},
                'operators': {},
                'token_metadata': token_metadata,
                'token_total_supply': supply
            },
            'metadata': meta
        }
        origination = self.fa2_contract.originate(initial_storage=initial_storage)
        return origination

    def _token_info(self, v):
        if v[''] is not None:
            return {'': str(v[''].encode().hex())}

        result = {'decimals': str(v['decimals']).encode().hex(),
                  'eth_contract': v['eth_contract'].encode().hex(),
                  'eth_name': v['eth_name'].encode().hex(),
                  'eth_symbol': v['eth_symbol'].encode().hex(),
                  'name': v['name'].encode().hex(),
                  'symbol': v['symbol'].encode().hex()
                  }
        if "thumbnailUri" in v:
            encoded = v['thumbnailUri'].encode().hex()
            result['thumbnailUri'] = encoded
        return result

    def nft(self, token: NftTokenAndMetaType, metadata_uri=_nft_default_meta, admin=None,
            minter=None):
        print("Deploying NFT")
        origination = self._nft_origination(token, admin, minter, metadata_uri)
        return self._originate_single_contract(origination)

    def _nft_origination(self, token, admin=None, minter=None, metadata_uri=_nft_default_meta):
        meta = _metadata_encode_uri(metadata_uri)
        generic_metadata = {'decimals': str(0).encode().hex(),
                            'eth_contract': token['eth_contract'].encode().hex(),
                            'eth_symbol': token['eth_symbol'].encode().hex(),
                            'eth_name': token['eth_name'].encode().hex(),
                            'name': token['name'].encode().hex(),
                            'symbol': token['symbol'].encode().hex(),
                            'isBooleanAmount': 'true'.encode().hex()
                            }
        initial_storage = {
            'admin': {
                'admin': self.client.key.public_key_hash() if admin is None else admin,
                'pending_admin': None,
                'paused': False,
                'minter': self.client.key.public_key_hash() if minter is None else minter
            },
            'assets': {
                'ledger': {},
                'operators': {},
                'token_info': generic_metadata
            },
            'metadata': meta
        }
        origination = self.nft_contract.originate(initial_storage=initial_storage)
        return origination

    def _set_tokens_minter(self, minter, fa2, governance, nfts):
        token = FtTokenType(self.client)
        calls = [token.set_minter_call(fa2, minter), token.set_minter_call(governance, minter)]
        calls.extend([token.set_minter_call(v, minter) for (i, v) in nfts.items()])
        return calls

    def _deploy_minter(self, quorum_contract,
                       tokens: list[TokenAndMetaType],
                       fa2_contract,
                       governance,
                       nft_contracts,
                       meta_uri=_minter_default_meta):
        print("Deploying minter contract")
        fungible_tokens = dict((v["eth_contract"][2:], [fa2_contract, k]) for k, v in enumerate(tokens))
        fungible_tokens[governance['eth']] = [governance['tezos'], 0]
        metadata = _metadata_encode_uri(meta_uri)
        initial_storage = {
            "admin": {
                "administrator": self.client.key.public_key_hash(),
                "pending_admin": None,
                "oracle": quorum_contract,
                "signer": quorum_contract,
                "paused": False
            },
            "assets": {
                "erc20_tokens": fungible_tokens,
                "erc721_tokens": nft_contracts,
                "mints": {}
            },
            "fees": {
                "signers": {},
                "tokens": {},
                "xtz": {}
            },
            "governance": {
                "contract": self.client.key.public_key_hash(),
                "staking": self.client.key.public_key_hash(),
                "dev_pool": self.client.key.public_key_hash(),
                "erc20_wrapping_fees": 15,
                "erc20_unwrapping_fees": 15,
                "erc721_wrapping_fees": 500_000,
                "erc721_unwrapping_fees": 500_000,
                "fees_share": {
                    "dev_pool": 10,
                    "signers": 50,
                    "staking": 40
                }
            },
            "metadata": metadata
        }
        origination = self.minter_contract.originate(initial_storage=initial_storage)
        return self._originate_single_contract(origination)

    def minter(self, quorum_contract,
               tokens: list[FtTokenType],
               admin=None,
               dev_pool=None,
               staking=None,
               nfts: list[NftTokenAndMetaType] = [],
               meta_uri=_minter_default_meta):
        print("Deploying minter")
        origination = self._minter_origination(quorum_contract, tokens, admin, dev_pool, staking, nfts, meta_uri)
        return self._originate_single_contract(origination)

    def _minter_origination(self, quorum_contract,
                            tokens: list[FtTokenType],
                            admin=None,
                            dev_pool=None,
                            staking=None,
                            nfts: list[NftTokenAndMetaType] = [],
                            meta_uri=_minter_default_meta):
        fungible_tokens = dict((v["eth_contract"][2:], [v['fa2'], v['token_id']]) for k, v in enumerate(tokens))
        non_fungible_tokens = dict((v["eth_contract"][2:], v['fa2']) for k, v in enumerate(nfts))

        metadata = _metadata_encode_uri(meta_uri)

        else_admin = self.client.key.public_key_hash() if admin is None else admin
        initial_storage = {
            "admin": {
                "administrator": else_admin,
                "pending_admin": None,
                "oracle": quorum_contract,
                "signer": quorum_contract,
                "paused": False
            },
            "assets": {
                "erc20_tokens": fungible_tokens,
                "erc721_tokens": non_fungible_tokens,
                "mints": {}
            },
            "fees": {
                "signers": {},
                "tokens": {},
                "xtz": {}
            },
            "governance": {
                "contract": else_admin,
                "staking": else_admin if staking is None else staking,
                "dev_pool": else_admin if dev_pool is None else dev_pool,
                "erc20_wrapping_fees": 15,
                "erc20_unwrapping_fees": 15,
                "erc721_wrapping_fees": 1_000_000,
                "erc721_unwrapping_fees": 1_000_000,
                "fees_share": {
                    "dev_pool": 10,
                    "signers": 50,
                    "staking": 40
                }
            },
            "metadata": metadata
        }
        return self.minter_contract.originate(initial_storage=initial_storage)

    def quorum(self, signers: dict[str, str],
               threshold,
               admin=None,
               meta_uri=_quorum_default_meta):
        print("Deploying quorum contract")
        origination = self._quorum_origination(signers, threshold, admin, meta_uri)
        return self._originate_single_contract(origination)

    def _quorum_origination(self, signers, threshold, admin=None, meta_uri=_quorum_default_meta):
        metadata = _metadata_encode_uri(meta_uri)
        initial_storage = {
            "admin": self.client.key.public_key_hash() if admin is None else admin,
            "pending_admin": None,
            "threshold": threshold,
            "signers": signers,
            "counters": {},
            "metadata": metadata
        }
        origination = self.quorum_contract.originate(initial_storage=initial_storage)
        return origination

    def _originate_single_contract(self, origination):
        opg = self.client.bulk(origination).autofill().sign().inject(min_confirmations=1)
        res = OperationResult.from_operation_group(opg)
        contract_id = res[0].originated_contracts[0]
        _print_contract(contract_id)
        return contract_id
