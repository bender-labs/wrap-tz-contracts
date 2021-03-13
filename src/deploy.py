import json
from pathlib import Path
from typing import TypedDict

from pytezos import ContractInterface, PyTezosClient, OperationResult

from src.minter import Minter
from src.token import Token

_fa2_default_meta = "https://gist.githubusercontent.com/BodySplash/" \
                    "1a44558b64ce7c0edd77e1ba37d6d8bf/raw/multi_asset.json"

_nft_default_meta = "https://gist.githubusercontent.com/BodySplash/05db57db07be61afd6fb568e5b48299e/raw/nft.json"

_minter_default_meta = "https://gist.githubusercontent.com/BodySplash/1106a10160cc8cc9d00ce9df369b884a/raw/minter.json"

_quorum_default_meta = "https://gist.githubusercontent.com/BodySplash/2c10f6a73c7b0946dcc3ec2fc94bb6c6/raw/quorum.json"


def _print_contract(addr):
    print(
        f'Successfully originated {addr}\n'
        f'Check out the contract at https://better-call.dev/edo2net/{addr}')


class TokenType(TypedDict):
    eth_contract: str
    eth_symbol: str
    eth_name: str
    symbol: str
    name: str
    decimals: int


class NftType(TypedDict):
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

    def run(self, signers: dict[str, str], tokens: list[TokenType], nft: list[NftType], threshold=1):
        originations = [self._quorum_origination(signers, threshold), self._fa2_origination(tokens)]
        originations.extend([self._nft_origination(v) for k, v in enumerate(nft)])
        print("Deploying quorum and FA2s")
        opg = self.client.bulk(*originations).autofill().sign().inject(_async=False)
        originated_contracts = OperationResult.originated_contracts(opg)
        for o in originated_contracts:
            _print_contract(o)
        quorum = originated_contracts[0]
        fa2 = originated_contracts[1]
        nft_contracts = dict((v["eth_contract"][2:], originated_contracts[k + 2]) for k, v in enumerate(nft))
        minter = self._deploy_minter(quorum, tokens, fa2, nft_contracts)
        admin_calls = self._set_tokens_admin(minter, fa2, nft_contracts)
        admin_calls.append(self._confirm_admin(minter, fa2, nft_contracts))
        print("Setting and confirming FA2s administrator")
        self.client.bulk(*admin_calls).autofill().sign().inject(_async=False)
        print(f"Nfts contracts: {nft_contracts}\n")
        print(f"FA2 contract: {fa2}\nQuorum contract: {quorum}\nMinter contract: {minter}")

    def fa2(self, tokens: list[TokenType],
            meta_uri=_fa2_default_meta):
        print("Deploying fa2")
        origination = self._fa2_origination(tokens, meta_uri)
        return self._originate_single_contract(origination)

    def _token_info(self, v):
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

    def _fa2_origination(self, tokens, meta_uri=_fa2_default_meta):
        meta = _metadata_encode_uri(meta_uri)
        token_metadata = dict(
            [(k, {'token_id': k,
                  'token_info': self._token_info(v)}) for k, v in
             enumerate(tokens)])
        supply = dict([(k, 0) for k, v in enumerate(tokens)])
        initial_storage = {
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
        }
        origination = self.fa2_contract.originate(initial_storage=initial_storage)
        return origination

    def nft(self, token: NftType, metadata_uri=_nft_default_meta):
        print("Deploying NFT")
        origination = self._nft_origination(token, metadata_uri)
        return self._originate_single_contract(origination)

    def _nft_origination(self, token, metadata_uri=_nft_default_meta):
        meta = _metadata_encode_uri(metadata_uri)
        generic_metadata = {'decimals': str(0).encode().hex(),
                            'eth_contract': token['eth_contract'].encode().hex(),
                            'eth_symbol': token['eth_symbol'].encode().hex(),
                            'eth_name': token['eth_name'].encode().hex(),
                            'name': token['name'].encode().hex(),
                            'symbol': token['symbol'].encode().hex()
                            }
        initial_storage = {
            'admin': {
                'admin': self.client.key.public_key_hash(),
                'pending_admin': None,
                'paused': False
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

    def _set_tokens_admin(self, minter, fa2, nfts):
        token = Token(self.client)
        calls = [token.set_admin_call(fa2, minter)]
        calls.extend([token.set_admin_call(v, minter) for (i, v) in nfts.items()])
        return calls

    def _confirm_admin(self, minter, fa2_contract, nfts):
        minter_contract = Minter(self.client)
        return minter_contract.confirm_admin_call(minter, [v for (i, v) in nfts.items()] + [fa2_contract])

    def _deploy_minter(self, quorum_contract,
                       tokens: list[TokenType],
                       fa2_contract,
                       nft_contracts,
                       meta_uri=_minter_default_meta):
        print("Deploying minter contract")
        fungible_tokens = dict((v["eth_contract"][2:], [fa2_contract, k]) for k, v in enumerate(tokens))
        metadata = _metadata_encode_uri(meta_uri)
        initial_storage = {
            "admin": {
                "administrator": self.client.key.public_key_hash(),
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
                "erc20_wrapping_fees": 100,
                "erc20_unwrapping_fees": 100,
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

    def quorum(self, signers: dict[str, str],
               threshold,
               meta_uri=_quorum_default_meta):
        print("Deploying quorum contract")
        origination = self._quorum_origination(signers, threshold, meta_uri)
        return self._originate_single_contract(origination)

    def _quorum_origination(self, signers, threshold, meta_uri=_quorum_default_meta):
        metadata = _metadata_encode_uri(meta_uri)
        initial_storage = {
            "admin": self.client.key.public_key_hash(),
            "threshold": threshold,
            "signers": signers,
            "counters": {},
            "metadata": metadata
        }
        origination = self.quorum_contract.originate(initial_storage=initial_storage)
        return origination

    def _originate_single_contract(self, origination):
        opg = self.client.bulk(origination).autofill().sign().inject(_async=False)
        res = OperationResult.from_operation_group(opg)
        contract_id = res[0].originated_contracts[0]
        _print_contract(contract_id)
        return contract_id
