import fire
import json

from src.ligo import LigoView


class Views(object):

    def multi_asset(self, destination):
        views = LigoView("./ligo/fa2/multi_asset/views.mligo")
        get_balance = views.compile("get_balance", "nat", "get_balance as defined in tzip-12")
        total_supply = views.compile("total_supply", "nat", "get_total supply as defined in tzip-12")
        is_operator = views.compile("is_operator", "bool", "is_operator as defined in tzip-12")
        token_metadata = views.compile("token_metadata", "(pair nat (map string bytes))",
                                       "token_metadata as defined in tzip-12")
        meta = {
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
        }
        with open(destination, 'w') as outfile:
            json.dump(meta, outfile, indent=4)

    def nft(self, destination):
        views = LigoView("./ligo/fa2/nft/views.mligo")
        get_balance = views.compile("get_balance", "nat", "get_balance as defined in tzip-12")
        total_supply = views.compile("total_supply", "nat", "get_total supply as defined in tzip-12")
        is_operator = views.compile("is_operator", "bool", "is_operator as defined in tzip-12")
        token_metadata = views.compile("token_metadata", "(pair nat (map string bytes))",
                                       "token_metadata as defined in tzip-12")
        meta = {
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
                token_metadata,
                total_supply
            ]
        }
        with open(destination, 'w') as outfile:
            json.dump(meta, outfile, indent=4)

    def quorum(self, destination):
        metadata = {
            "name": "Wrap protocol quorum contract",
            "homepage": "https://github.com/bender-labs/wrap-tz-contracts",
            "license": {"name": "MIT"},
        }
        with open(destination, 'w') as outfile:
            json.dump(metadata, outfile, indent=4)

    def minter(self, destination):
        metadata = {
            "name": "Wrap protocol minter contract",
            "homepage": "https://github.com/bender-labs/wrap-tz-contracts",
            "license": {"name": "MIT"},
        }
        with open(destination, 'w') as outfile:
            json.dump(metadata, outfile, indent=4)

if __name__ == '__main__':
    fire.Fire(Views)
