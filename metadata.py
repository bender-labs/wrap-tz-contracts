import fire
import json

from src.ligo import LigoView


class Views(object):
    def multi_asset(self, destination):
        views = LigoView("./ligo/fa2/multi_asset/views.mligo")
        get_balance = views.compile(
            "get_balance", "nat", "get_balance as defined in tzip-12"
        )
        total_supply = views.compile(
            "total_supply", "nat", "get_total supply as defined in tzip-12"
        )
        is_operator = views.compile(
            "is_operator", "bool", "is_operator as defined in tzip-12"
        )
        token_metadata = views.compile(
            "token_metadata",
            "(pair nat (map string bytes))",
            "token_metadata as defined in tzip-12",
        )
        meta = {
            "interfaces": ["TZIP-012", "TZIP-016", "TZIP-021"],
            "name": "Wrap protocol FA2 tokens",
            "homepage": "https://github.com/bender-labs/wrap-tz-contracts",
            "license": {"name": "MIT"},
            "permissions": {
                "operator": "owner-or-operator-transfer",
                "receiver": "owner-no-hook",
                "sender": "owner-no-hook",
                "custom": {"tag": "PAUSABLE_TOKENS"},
            },
            "views": [get_balance, total_supply, is_operator, token_metadata],
        }
        with open(destination, "w") as outfile:
            json.dump(meta, outfile, indent=4)

    def nft(self, destination):
        views = LigoView("./ligo/fa2/nft/views.mligo")
        get_balance = views.compile(
            "get_balance", "nat", "get_balance as defined in tzip-12"
        )
        total_supply = views.compile(
            "total_supply", "nat", "get_total supply as defined in tzip-12"
        )
        is_operator = views.compile(
            "is_operator", "bool", "is_operator as defined in tzip-12"
        )
        token_metadata = views.compile(
            "token_metadata",
            "(pair nat (map string bytes))",
            "token_metadata as defined in tzip-12",
        )
        meta = {
            "interfaces": ["TZIP-012", "TZIP-016"],
            "name": "Wrap protocol NFT token",
            "homepage": "https://github.com/bender-labs/wrap-tz-contracts",
            "license": {"name": "MIT"},
            "permissions": {
                "operator": "owner-or-operator-transfer",
                "receiver": "owner-no-hook",
                "sender": "owner-no-hook",
                "custom": {"tag": "PAUSABLE_TOKENS"},
            },
            "views": [get_balance, is_operator, token_metadata, total_supply],
        }
        with open(destination, "w") as outfile:
            json.dump(meta, outfile, indent=4)

    def quorum(self, destination):
        metadata = {
            "name": "Wrap protocol quorum contract",
            "homepage": "https://github.com/bender-labs/wrap-tz-contracts",
            "interfaces": ["TZIP-016"],
            "license": {"name": "MIT"},
        }
        with open(destination, "w") as outfile:
            json.dump(metadata, outfile, indent=4)

    def minter(self, destination):
        views = LigoView("./ligo/minter/views.mligo")
        get_token_reward = views.compile(
            "get_token_reward", "nat", "get pending tokens fees"
        )
        get_tez_reward = views.compile(
            "get_tez_reward", "mutez", "get pending tez fees"
        )
        metadata = {
            "name": "Wrap protocol minter contract",
            "interfaces": ["TZIP-016"],
            "homepage": "https://github.com/bender-labs/wrap-tz-contracts",
            "license": {"name": "MIT"},
            "views": [get_token_reward, get_tez_reward],
        }
        with open(destination, "w") as outfile:
            json.dump(metadata, outfile, indent=4)

    def governance_token(self, destination):
        views = LigoView("./ligo/fa2/governance/views.mligo")
        all_tokens = views.compile(
            "all_tokens", "list(nat)", "all_tokens as defined in tzip-12"
        )
        get_balance = views.compile(
            "get_balance", "nat", "get_balance as defined in tzip-12"
        )
        total_supply = views.compile(
            "total_supply", "nat", "get_total supply as defined in tzip-12"
        )
        is_operator = views.compile(
            "is_operator", "bool", "is_operator as defined in tzip-12"
        )
        token_metadata = views.compile(
            "token_metadata",
            "(pair nat (map string bytes))",
            "token_metadata as defined in tzip-12",
        )
        distributed = views.compile(
            "tokens_distributed",
            "How many governance tokens have already been distributed",
        )
        meta = {
            "interfaces": ["TZIP-012", "TZIP-016", "TZIP-021"],
            "name": "Wrap protocol governance token",
            "homepage": "https://github.com/bender-labs/wrap-tz-contracts",
            "license": {"name": "MIT"},
            "permissions": {
                "operator": "owner-or-operator-transfer",
                "receiver": "owner-no-hook",
                "sender": "owner-no-hook",
                "custom": {"tag": "PAUSABLE_TOKENS"},
            },
            "views": [
                all_tokens,
                get_balance,
                total_supply,
                is_operator,
                token_metadata,
                distributed,
            ],
        }
        with open(destination, "w") as outfile:
            json.dump(meta, outfile, indent=4)

    def staking(self, destination):
        views = LigoView("./ligo/staking/views.mligo")
        get_earned = views.compile(
            "get_earned",
            "nat",
            description="Get claimable reward for address",
            pure=False,
        )
        get_balance = views.compile(
            "get_balance", "nat", "Get staked balance for address"
        )
        total_supply = views.compile("total_supply", "nat", "Get total staked")
        meta = {
            "interfaces": ["TZIP-016"],
            "name": "Wrap staking contract",
            "homepage": "https://github.com/bender-labs/wrap-tz-contracts",
            "license": {"name": "MIT"},
            "views": [get_earned, get_balance, total_supply],
        }
        with open(destination, "w") as outfile:
            json.dump(meta, outfile, indent=4)

    def vesting(self, destination):
        views = LigoView("./ligo/vesting/views.mligo")
        get_earned = views.compile(
            "get_earned",
            description="Get claimable reward for address",
            pure=False,
        )
        get_balance = views.compile(
            "get_balance", description="Get staked balance for address"
        )
        total_supply = views.compile("total_supply", description="Get total staked")

        get_stakes = views.compile("get_stakes", description="Get stakes for user")
        meta = {
            "interfaces": ["TZIP-016"],
            "name": "Wrap vesting contract",
            "homepage": "https://github.com/bender-labs/wrap-tz-contracts",
            "license": {"name": "MIT"},
            "views": [get_earned, get_balance, total_supply, get_stakes],
        }
        with open(destination, "w") as outfile:
            json.dump(meta, outfile, indent=4)


if __name__ == "__main__":
    fire.Fire(Views)
