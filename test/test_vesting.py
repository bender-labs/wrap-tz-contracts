import unittest
from pathlib import Path

from pytezos import Key, MichelsonRuntimeError

from src.ligo import LigoContract
from unittest_data_provider import data_provider

reward_token = ("KT1VUNmGa1JYJuNxNS4XDzwpsc9N1gpcCBN2", 1)
stake_token = ("KT1LRboPna9yQY9BrjtQYDS1DVxhKESK4VVd", 0)
self_address = "KT1BEqzn5Wx8uJrZNvuS9DVHmLvG9td3fDLi"
reserve_contract = "KT1K7L5bQzqmVRYyrgLTHWNHQ6C5vFpYGQRk"
admin = Key.generate(export=False).public_key_hash()
burn_address = Key.generate(export=False).public_key_hash()
scale = 10 ** 16


class VestingContractTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        root_dir = Path(__file__).parent.parent / "ligo"
        cls.contract = LigoContract(
            root_dir / "vesting" / "vesting_main.mligo", "main"
        ).get_contract()


class DepositTest(VestingContractTest):

    def test_should_increase_balance_on_staking(self):
        user = a_user()
        storage = with_balance(user, 150, valid_storage(total_supply=10))

        res = self.contract.stake(100).interpret(storage=storage, sender=user, level=1000)

        delegator = delegator_entry(user, res.storage)
        self.assertEqual(250, delegator["balance"])
        self.assertEqual(110, total_supply(res.storage))
        self.assertEqual(2, delegator["counter"])
        self.assertEqual({"amount": 100, "level": 1000}, delegator["stakes"].get(1))

    def test_should_generate_transfer_on_staking(self):
        user = a_user()
        storage = with_balance(user, 150, valid_storage(total_supply=10))

        res = self.contract.stake(100).interpret(
            storage=storage, sender=user, self_address=self_address
        )

        self.assertEqual(1, len(res.operations))
        op = res.operations[0]
        self.assertEqual(stake_token[0], op["destination"])
        self.assertEqual("0", op["amount"])
        self.assertEqual("transfer", op["parameters"]["entrypoint"])
        self.assertEqual(
            [
                {
                    "prim": "Pair",
                    "args": [
                        {"string": user},
                        [
                            {
                                "prim": "Pair",
                                "args": [
                                    {"string": self_address},
                                    {"int": str(stake_token[1])},
                                    {"int": str(100)},
                                ],
                            }
                        ],
                    ],
                }
            ],
            op["parameters"]["value"],
        )

    def test_should_update_pool_and_reward_on_staking(self):
        user = a_user()
        storage = valid_storage(
            total_supply=10,
            last_block_update=90,
            period_end=110,
            accumulated_reward_per_token=1,
            reward_per_block=2 * scale,
        )

        res = self.contract.stake(10).interpret(
            storage=storage, sender=user, self_address=self_address, level=100
        )

        self.assertEqual(100, res.storage["reward"]["last_block_update"])
        self.assertEqual(
            3 * scale, res.storage["reward"]["accumulated_reward_per_token"]
        )
        self.assertEqual(
            3 *
            scale, res.storage["ledger"]["delegators"][user]["reward_per_token_paid"]
        )
        self.assertEqual(0, res.storage["ledger"]
        ["delegators"][user]["unpaid"])

    def test_should_update_pool_and_reward_on_staking_and_empty_pool(self):
        user = a_user()
        storage = valid_storage(
            total_supply=0,
            last_block_update=90,
            period_end=110,
            accumulated_reward_per_token=1,
            reward_per_block=2,
        )

        res = self.contract.stake(10).interpret(
            storage=storage, sender=user, self_address=self_address, level=100
        )

        self.assertEqual(100, res.storage["reward"]["last_block_update"])
        self.assertEqual(
            1 * scale, res.storage["reward"]["accumulated_reward_per_token"]
        )
        delegator = delegator_entry(user, res.storage)
        self.assertEqual(
            1 * scale, delegator["reward_per_token_paid"]
        )
        self.assertEqual(0, delegator["unpaid"])

    def test_should_accumulate_unpaid_amount(self):
        user = a_user()
        storage = valid_storage(
            total_supply=10,
            last_block_update=90,
            period_end=110,
            accumulated_reward_per_token=1,
            reward_per_block=2 * scale,
        )

        res = self.contract.stake(10).interpret(
            storage=storage, sender=user, self_address=self_address, level=100
        )
        res = self.contract.stake(10).interpret(
            storage=res.storage, sender=user, self_address=self_address, level=101
        )

        delegator = delegator_entry(user, res.storage)
        self.assertEqual(
            3.1 *
            scale, delegator["reward_per_token_paid"]
        )
        self.assertEqual(1 * scale, delegator["unpaid"])
        self.assertEqual(101, res.storage["reward"]["last_block_update"])
        self.assertEqual(
            3.1 * scale, res.storage["reward"]["accumulated_reward_per_token"]
        )

    def test_should_update_pool_according_to_period_end(self):
        user = a_user()
        storage = valid_storage(
            total_supply=10,
            last_block_update=90,
            period_end=110,
            accumulated_reward_per_token=1,
            reward_per_block=2 * scale,
        )

        res = self.contract.stake(10).interpret(
            storage=storage, sender=user, self_address=self_address, level=111
        )

        self.assertEqual(110, res.storage["reward"]["last_block_update"])
        self.assertEqual(
            5 * scale, res.storage["reward"]["accumulated_reward_per_token"]
        )
        delegator = delegator_entry(user, res.storage)
        self.assertEqual(
            5 * scale, delegator["reward_per_token_paid"]
        )
        self.assertEqual(0, delegator["unpaid"])


class WithdrawalTest(VestingContractTest):

    def test_should_decrease_balance_on_withdraw(self):
        user = a_user()
        storage = with_balance(user, 150, valid_storage(total_supply=10))

        res = self.contract.withdraw(0, 10).interpret(
            storage=storage, sender=user)

        self.assertEqual(140, balance_of(user, res.storage))
        self.assertEqual(0, total_supply(res.storage))

    def test_should_remove_stake_level_if_empty(self):
        user = a_user()
        storage = with_balance(user, 150, valid_storage(total_supply=150))

        res = self.contract.withdraw(0, 150).interpret(
            storage=storage, sender=user)

        delegator = delegator_entry(user, res.storage)
        self.assertFalse(0 in delegator["stakes"])

    def test_should_reject_withdraw_on_unknown_stake_level(self):
        user = a_user()
        with self.assertRaises(MichelsonRuntimeError) as context:
            storage = with_balance(user, 150, valid_storage(total_supply=10))
            self.contract.withdraw(1, 10).interpret(
                storage=storage, sender=user)

        self.assertEqual("'WRONG_STAKE_INDEX'", context.exception.args[-1])

    def test_should_generate_transfer_with_user_and_burn(self):
        user = a_user()
        storage = with_balance(user, 150, valid_storage(total_supply=150))

        res = self.contract.withdraw(0, 150).interpret(
            storage=storage, sender=user, self_address=self_address, level=1
        )

        self.assertEqual(1, len(res.operations))
        op = res.operations[0]
        self.assertEqual(stake_token[0], op["destination"])
        self.assertEqual("0", op["amount"])
        self.assertEqual("transfer", op["parameters"]["entrypoint"])
        transfer = extract_transfer(op["parameters"]["value"])
        self.assertEqual(
            {"from": self_address, "txs": [
                {"amount": "113", "to": user, "token_id": str(stake_token[1])},
                {"amount": "37", "to": burn_address, "token_id": str(stake_token[1])}
            ]}, transfer)

    def test_should_generate_transfer_with_fee_bracket_2(self):
        user = a_user()
        storage = with_balance(user, 150, valid_storage(total_supply=150))

        res = self.contract.withdraw(0, 150).interpret(
            storage=storage, sender=user, self_address=self_address, level=4096
        )

        self.assertEqual(1, len(res.operations))
        op = res.operations[0]
        self.assertEqual(stake_token[0], op["destination"])
        self.assertEqual("0", op["amount"])
        self.assertEqual("transfer", op["parameters"]["entrypoint"])
        transfer = extract_transfer(op["parameters"]["value"])
        self.assertEqual(
            {"from": self_address, "txs": [
                {"amount": "132", "to": user, "token_id": str(stake_token[1])},
                {"amount": "18", "to": burn_address, "token_id": str(stake_token[1])}
            ]}, transfer)

    def test_should_generate_transfer_with_next_fee_bracket_3(self):
        user = a_user()
        storage = with_balance(user, 150, valid_storage(total_supply=150))

        res = self.contract.withdraw(0, 150).interpret(
            storage=storage, sender=user, self_address=self_address, level=8192
        )

        self.assertEqual(1, len(res.operations))
        op = res.operations[0]
        self.assertEqual(stake_token[0], op["destination"])
        self.assertEqual("0", op["amount"])
        self.assertEqual("transfer", op["parameters"]["entrypoint"])
        transfer = extract_transfer(op["parameters"]["value"])
        self.assertEqual(
            {"from": self_address, "txs": [
                {"amount": "135", "to": user, "token_id": str(stake_token[1])},
                {"amount": "15", "to": burn_address, "token_id": str(stake_token[1])}
            ]}, transfer)

    def test_should_generate_transfer_with_default_bracket(self):
        user = a_user()
        storage = with_balance(user, 150, valid_storage(total_supply=150))

        res = self.contract.withdraw(0, 150).interpret(
            storage=storage, sender=user, self_address=self_address, level=12288
        )

        self.assertEqual(1, len(res.operations))
        op = res.operations[0]
        self.assertEqual(stake_token[0], op["destination"])
        self.assertEqual("0", op["amount"])
        self.assertEqual("transfer", op["parameters"]["entrypoint"])
        transfer = extract_transfer(op["parameters"]["value"])
        self.assertEqual(
            {"from": self_address, "txs": [
                {"amount": "144", "to": user, "token_id": str(stake_token[1])},
                {"amount": "6", "to": burn_address, "token_id": str(stake_token[1])}
            ]}, transfer)

    def test_should_generate_transfer_without_burn_if_0_fees(self):
        user = a_user()
        storage = with_balance(user, 150, valid_storage(total_supply=150))
        storage["fees"]["default_fees"] = 0

        res = self.contract.withdraw(0, 150).interpret(
            storage=storage, sender=user, self_address=self_address, level=12288
        )

        self.assertEqual(1, len(res.operations))
        op = res.operations[0]
        self.assertEqual(stake_token[0], op["destination"])
        self.assertEqual("0", op["amount"])
        self.assertEqual("transfer", op["parameters"]["entrypoint"])
        transfer = extract_transfer(op["parameters"]["value"])
        self.assertEqual(
            {"from": self_address, "txs": [
                {"amount": "150", "to": user, "token_id": str(stake_token[1])}
            ]}, transfer)

    def test_should_reject_withdrawal_with_amount_too_large(self):
        with self.assertRaises(MichelsonRuntimeError) as context:
            user = a_user()
            storage = with_balance(user, 5, valid_storage(total_supply=10))

            self.contract.withdraw(0, 10).interpret(storage=storage, sender=user)
        self.assertEqual("'NEGATIVE_BALANCE'", context.exception.args[-1])

    def test_should_reject_withdrawal_with_zero_amount(self):
        with self.assertRaises(MichelsonRuntimeError) as context:
            user = a_user()
            storage = with_balance(user, 5, valid_storage(total_supply=10))

            self.contract.withdraw(0, 0).interpret(storage=storage, sender=user)
        self.assertEqual("'BAD_AMOUNT'", context.exception.args[-1])

    def test_should_update_pool_and_reward_on_withdrawal(self):
        user = a_user()
        storage = valid_storage(
            total_supply=100,
            last_block_update=90,
            period_end=110,
            accumulated_reward_per_token=1,
            reward_per_block=2 * scale,
        )
        storage = with_balance(user, 100, storage)

        res = self.contract.withdraw(0, 100).interpret(
            storage=storage, sender=user, self_address=self_address, level=100
        )

        self.assertEqual(100, res.storage["reward"]["last_block_update"])
        self.assertEqual(
            1.2 * scale, res.storage["reward"]["accumulated_reward_per_token"]
        )
        delegator = delegator_entry(user, res.storage)
        self.assertEqual(
            1.2 *
            scale, delegator["reward_per_token_paid"]
        )
        self.assertEqual(120 * scale, delegator["unpaid"])


class ClaimTest(VestingContractTest):

    def test_claiming_should_update_reward_and_transfer(self):
        user = a_user()
        storage = valid_storage(
            total_supply=100,
            last_block_update=90,
            period_end=110,
            accumulated_reward_per_token=1,
            reward_per_block=2 * scale,
        )
        storage = with_balance(user, 100, storage)

        res = self.contract.claim().interpret(
            storage=storage, sender=user, self_address=self_address, level=100
        )

        delegator = delegator_entry(user, res.storage)
        self.assertEqual(0, delegator["unpaid"])
        self.assertEqual(1, len(res.operations))
        op = res.operations[0]
        self.assertEqual(reward_token[0], op["destination"])
        transfer = extract_transfer(op["parameters"]["value"])
        self.assertEqual({"from": reserve_contract, "txs": [
            {"to": user, "token_id": str(reward_token[1]), "amount": "120"}
        ]}, transfer)

    def test_no_transfer_should_be_generated_if_no_reward(self):
        user = a_user()
        storage = valid_storage(
            total_supply=100,
            last_block_update=90,
            period_end=110,
            accumulated_reward_per_token=1,
            reward_per_block=2,
        )

        res = self.contract.claim().interpret(
            storage=storage, sender=user, self_address=self_address, level=100
        )

        self.assertEqual(0, len(res.operations))

    def test_claiming_should_keep_remainder(self):
        user = a_user()
        storage = valid_storage(
            total_supply=100_000_000,
            last_block_update=90,
            period_end=110,
            accumulated_reward_per_token=1,
            reward_per_block=25 * scale,
        )
        storage = with_balance(user, 100, storage)

        res = self.contract.claim().interpret(
            storage=storage, sender=user, self_address=self_address, level=91
        )

        delegator = delegator_entry(user, res.storage)
        self.assertEqual(250000000000, delegator["unpaid"])
        self.assertEqual(1, len(res.operations))
        op = res.operations[0]
        self.assertEqual(reward_token[0], op["destination"])
        self.assertEqual("0", op["amount"])
        transfer = extract_transfer(op["parameters"]["value"])
        self.assertEqual({"from": reserve_contract, "txs": [
            {"to": user, "amount": "100", "token_id": str(reward_token[1])}
        ]}, transfer)


class PlanTests(VestingContractTest):

    def test_should_create_new_plan(self):
        res = self.contract.update_plan(100).interpret(
            storage=valid_storage(period_end=100, duration=20), level=100, sender=admin
        )

        self.assertEqual(res.storage["reward"]["period_end"], 120)
        self.assertEqual(res.storage["reward"]["last_block_update"], 100)
        self.assertEqual(res.storage["reward"]
                         ["reward_per_block"], 50000000000000000)
        self.assertEqual(res.storage["reward"]["reward_remainder"], 0)

    def test_should_save_R_for_next_distribution_period(self):
        res = self.contract.update_plan(50).interpret(
            storage=valid_storage(period_end=100, duration=20), level=101, sender=admin
        )

        self.assertEqual(res.storage["reward"]["period_end"], 121)
        self.assertEqual(res.storage["reward"]["last_block_update"], 101)
        self.assertEqual(res.storage["reward"]
                         ["reward_per_block"], 25000000000000000)
        self.assertEqual(res.storage["reward"]["reward_remainder"], 0)

    def test_should_use_R_and_undistributed_for_next_distribution_period(self):
        res = self.contract.update_plan(50).interpret(
            storage=valid_storage(period_end=100, duration=20), level=101, sender=admin
        )

        res = self.contract.update_plan(50).interpret(
            storage=res.storage, level=121, sender=admin
        )

        self.assertEqual(res.storage["reward"]["period_end"], 141)
        self.assertEqual(res.storage["reward"]["last_block_update"], 121)
        self.assertEqual(res.storage["reward"]["reward_per_block"], 5 * scale)
        self.assertEqual(res.storage["reward"]["reward_remainder"], 0)

    def test_should_use_left_over_from_previous_period(self):
        res = self.contract.update_plan(100).interpret(
            storage=valid_storage(period_end=100, total_supply=1, duration=20, reward_per_block=2 * scale), level=50,
            sender=admin
        )

        self.assertEqual(70, res.storage["reward"]["period_end"])
        self.assertEqual(50, res.storage["reward"]["last_block_update"])
        self.assertEqual(10 * scale, res.storage["reward"]
        ["reward_per_block"])
        self.assertEqual(0, res.storage["reward"]["reward_remainder"])

    def test_should_update_pool(self):
        storage = valid_storage(
            total_supply=10,
            last_block_update=90,
            period_end=110,
            accumulated_reward_per_token=1,
            reward_per_block=2 * scale,
        )

        res = self.contract.update_plan(100).interpret(
            storage=storage, self_address=self_address, level=111, sender=admin
        )

        self.assertEqual(111, res.storage["reward"]["last_block_update"])
        self.assertEqual(
            5 * scale, res.storage["reward"]["accumulated_reward_per_token"]
        )

    def test_should_reject_if_not_admin(self):
        with self.assertRaises(MichelsonRuntimeError) as context:
            self.contract.update_plan(100).interpret(
                storage=valid_storage(period_end=100, duration=20),
                level=100,
                sender=a_user(),
            )
        self.assertEqual("'NOT_AN_ADMIN'", context.exception.args[-1])

    def test_admin_should_change_plan_duration(self):
        res = self.contract.change_duration(500).interpret(
            storage=valid_storage(), sender=admin
        )

        self.assertEqual(500, res.storage["settings"]["duration"])

    def test_should_reject_change_duration_if_not_admin(self):
        with self.assertRaises(MichelsonRuntimeError) as context:
            self.contract.change_duration(500).interpret(
                storage=valid_storage(), sender=a_user()
            )
        self.assertEqual("'NOT_AN_ADMIN'", context.exception.args[-1])

    def test_should_reject_bad_duration_change(self):
        with self.assertRaises(MichelsonRuntimeError) as context:
            self.contract.change_duration(0).interpret(
                storage=valid_storage(), sender=admin
            )
        self.assertEqual("'BAD_DURATION'", context.exception.args[-1])


def balance_of(user, storage):
    return storage["ledger"]["delegators"].get(user, {"balance": 0})["balance"]


def delegator_entry(user, storage):
    return storage["ledger"]["delegators"].get(user)


def with_balance(user, amount, storage, stake_index=0, level=0):
    storage["ledger"]["delegators"][user] = {
        "unpaid": 0,
        "reward_per_token_paid": 0,
        "counter": 1,
        "balance": amount,
        "stakes": {stake_index: {"amount": amount, "level": level}}
    }
    return storage


def total_supply(storage):
    return storage["ledger"]["total_supply"]


def valid_storage(
        total_supply=0,
        last_block_update=0,
        period_end=10,
        accumulated_reward_per_token=0,
        reward_per_block=0,
        duration=10,
):
    return {
        "ledger": {"total_supply": total_supply, "delegators": {}},
        "fees": {
            "default_fees": 25,
            "fees_per_cycles": {
                1: 4,
                2: 8,
                3: 10
            }
        },
        "settings": {
            "duration": duration,
            "staked_token": stake_token,
            "reward_token": reward_token,
            "reserve_contract": reserve_contract,
            "blocks_per_cycle": 4096,
            "burn_address": burn_address
        },
        "reward": {
            "last_block_update": last_block_update,
            "period_end": period_end,
            "accumulated_reward_per_token": accumulated_reward_per_token * scale,
            "reward_per_block": reward_per_block,
            "reward_remainder": 0,
            "exponent": 8
        },
        "admin": {"address": admin, "pending_admin": None},
        "metadata": {},
    }


def extract_transfer(params):
    return {
        "from": params[0]["args"][0]["string"],
        "txs": list(map(lambda x: {"to": x["args"][0]["string"], "token_id": x["args"][1]["int"],
                                   "amount": x["args"][2]["int"]}, params[0]["args"][1]))
    }


def a_user():
    return Key.generate(export=False).public_key_hash()
