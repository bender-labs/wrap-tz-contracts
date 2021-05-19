import unittest
from pathlib import Path

from pytezos import Key, MichelsonRuntimeError

from src.ligo import LigoContract
from unittest_data_provider import data_provider

reward_token = ("KT1VUNmGa1JYJuNxNS4XDzwpsc9N1gpcCBN2", 1)
stake_token = ("KT1LRboPna9yQY9BrjtQYDS1DVxhKESK4VVd", 0)
self_address = "KT1BEqzn5Wx8uJrZNvuS9DVHmLvG9td3fDLi"
reserve_contract = "KT1K7L5bQzqmVRYyrgLTHWNHQ6C5vFpYGQRk"
scale = 10 ** 6


class StakingContractTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        root_dir = Path(__file__).parent.parent / "ligo"
        cls.contract = LigoContract(
            root_dir / "staking" / "staking_main.mligo", "main"
        ).get_contract()


class DepositTest(StakingContractTest):
    def test_should_increase_balance_on_staking(self):
        user = a_user()
        storage = with_balance(user, 150, valid_storage(total_supply=10))

        res = self.contract.stake(100).interpret(storage=storage, sender=user)

        self.assertEqual(250, balance_of(user, res.storage))
        self.assertEqual(110, total_supply(res.storage))

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
            reward_per_block=2,
        )

        res = self.contract.stake(10).interpret(
            storage=storage, sender=user, self_address=self_address, level=100
        )

        self.assertEqual(100, res.storage["reward"]["last_block_update"])
        self.assertEqual(
            3 * scale, res.storage["reward"]["accumulated_reward_per_token"]
        )
        self.assertEqual(
            3 * scale, res.storage["delegators"][user]["reward_per_token_paid"]
        )
        self.assertEqual(0, res.storage["delegators"][user]["unpaid"])

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
        self.assertEqual(
            1 * scale, res.storage["delegators"][user]["reward_per_token_paid"]
        )
        self.assertEqual(0, res.storage["delegators"][user]["unpaid"])

    def test_should_accumulate_unpaid_amount(self):
        user = a_user()
        storage = valid_storage(
            total_supply=10,
            last_block_update=90,
            period_end=110,
            accumulated_reward_per_token=1,
            reward_per_block=2,
        )

        res = self.contract.stake(10).interpret(
            storage=storage, sender=user, self_address=self_address, level=100
        )
        res = self.contract.stake(10).interpret(
            storage=res.storage, sender=user, self_address=self_address, level=101
        )

        self.assertEqual(101, res.storage["reward"]["last_block_update"])
        self.assertEqual(
            3.1 * scale, res.storage["reward"]["accumulated_reward_per_token"]
        )
        self.assertEqual(
            3.1 * scale, res.storage["delegators"][user]["reward_per_token_paid"]
        )
        self.assertEqual(1, res.storage["delegators"][user]["unpaid"])

    def test_should_update_pool_according_to_period_end(self):
        user = a_user()
        storage = valid_storage(
            total_supply=10,
            last_block_update=90,
            period_end=110,
            accumulated_reward_per_token=1,
            reward_per_block=2,
        )

        res = self.contract.stake(10).interpret(
            storage=storage, sender=user, self_address=self_address, level=111
        )

        self.assertEqual(110, res.storage["reward"]["last_block_update"])
        self.assertEqual(
            5 * scale, res.storage["reward"]["accumulated_reward_per_token"]
        )
        self.assertEqual(
            5 * scale, res.storage["delegators"][user]["reward_per_token_paid"]
        )
        self.assertEqual(0, res.storage["delegators"][user]["unpaid"])


class WithdrawalTest(StakingContractTest):
    def test_should_decrease_balance_on_withdraw(self):
        user = a_user()
        storage = with_balance(user, 150, valid_storage(total_supply=10))

        res = self.contract.withdraw(10).interpret(storage=storage, sender=user)

        self.assertEqual(140, balance_of(user, res.storage))
        self.assertEqual(0, total_supply(res.storage))

    def test_should_generate_transfer_on_withdraw(self):
        user = a_user()
        storage = with_balance(user, 150, valid_storage(total_supply=10))

        res = self.contract.withdraw(10).interpret(
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
                        {"string": self_address},
                        [
                            {
                                "prim": "Pair",
                                "args": [
                                    {"string": user},
                                    {"int": str(stake_token[1])},
                                    {"int": str(10)},
                                ],
                            }
                        ],
                    ],
                }
            ],
            op["parameters"]["value"],
        )

    def test_should_reject_withdrawal_when_no_balance(self):
        with self.assertRaises(MichelsonRuntimeError) as context:
            user = a_user()
            storage = valid_storage(total_supply=10)

            self.contract.withdraw(10).interpret(storage=storage, sender=user)
        self.assertEqual("'NEGATIVE_BALANCE'", context.exception.args[-1])

    def test_should_reject_withdrawal_with_amount_too_large(self):
        with self.assertRaises(MichelsonRuntimeError) as context:
            user = a_user()
            storage = with_balance(user, 5, valid_storage(total_supply=10))

            self.contract.withdraw(10).interpret(storage=storage, sender=user)
        self.assertEqual("'NEGATIVE_BALANCE'", context.exception.args[-1])

    def test_should_reject_withdrawal_with_zero_amount(self):
        with self.assertRaises(MichelsonRuntimeError) as context:
            user = a_user()
            storage = with_balance(user, 5, valid_storage(total_supply=10))

            self.contract.withdraw(0).interpret(storage=storage, sender=user)
        self.assertEqual("'BAD_AMOUNT'", context.exception.args[-1])

    def test_should_update_pool_and_reward_on_withdrawal(self):
        user = a_user()
        storage = valid_storage(
            total_supply=100,
            last_block_update=90,
            period_end=110,
            accumulated_reward_per_token=1,
            reward_per_block=2,
        )
        storage = with_balance(user, 100, storage)

        res = self.contract.withdraw(100).interpret(
            storage=storage, sender=user, self_address=self_address, level=100
        )

        self.assertEqual(100, res.storage["reward"]["last_block_update"])
        self.assertEqual(
            1.2 * scale, res.storage["reward"]["accumulated_reward_per_token"]
        )
        self.assertEqual(
            1.2 * scale, res.storage["delegators"][user]["reward_per_token_paid"]
        )
        self.assertEqual(120, res.storage["delegators"][user]["unpaid"])


class ClaimTest(StakingContractTest):
    def test_claiming_should_update_reward(self):
        user = a_user()
        storage = valid_storage(
            total_supply=100,
            last_block_update=90,
            period_end=110,
            accumulated_reward_per_token=1,
            reward_per_block=2,
        )
        storage = with_balance(user, 100, storage)

        res = self.contract.claim().interpret(
            storage=storage, sender=user, self_address=self_address, level=100
        )

        self.assertEqual(0, res.storage["delegators"][user]["unpaid"])
        self.assertEqual(1, len(res.operations))
        op = res.operations[0]
        self.assertEqual(reward_token[0], op["destination"])
        self.assertEqual("0", op["amount"])
        self.assertEqual("transfer", op["parameters"]["entrypoint"])
        self.assertEqual(
            [
                {
                    "prim": "Pair",
                    "args": [
                        {"string": reserve_contract},
                        [
                            {
                                "prim": "Pair",
                                "args": [
                                    {"string": user},
                                    {"int": str(reward_token[1])},
                                    {"int": str(120)},
                                ],
                            }
                        ],
                    ],
                }
            ],
            op["parameters"]["value"],
        )


class PlanTests(StakingContractTest):
    def test_should_call_reserve_contract(self):
        res = self.contract.update_plan(100).interpret(storage=valid_storage(period_end=100), level=101)

        self.assertEqual(1, len(res.operations))
        op = res.operations[0]
        self.assertEqual(reserve_contract, op["destination"])
        self.assertEqual("0", op["amount"])
        self.assertEqual("claim_fees", op["parameters"]["entrypoint"])
        self.assertEqual(
            {
                "prim": "Pair",
                "args": [
                    {"string": reward_token[0]},
                    {"int": str(reward_token[1])},
                    {"int": "100"},
                ],
            },
            op["parameters"]["value"],
        )

    def test_should_create_new_plan(self):
       res = self.contract.update_plan(100).interpret(storage=valid_storage(period_end=100, duration=20), level=101)

       self.assertEqual(res.storage['reward']['period_end'], 121)
       self.assertEqual(res.storage['reward']['last_block_update'], 101)
       self.assertEqual(res.storage['reward']['reward_per_block'], 5)

    def test_should_uplate_pool(self):
        # TODO
        self.assertEqual(True, False)

    def test_should_reject_new_plan_if_period_is_not_finished(self):
        with self.assertRaises(MichelsonRuntimeError) as context:
            self.contract.update_plan(100).interpret(storage=valid_storage(period_end=100, duration=20), level=99)
        self.assertEqual("'DISTRIBUTION_RUNNING'", context.exception.args[-1])
       
    

class FunctionalTests(StakingContractTest):
    def setUp(self) -> None:
        super().setUp()
        self.storage = valid_storage(period_end=100, reward_per_block=2)

    @staticmethod
    def two_users_deposit():
        first_user = a_user()
        second_user = a_user()
        return [
            (
                [(first_user, "stake", 100, 0), (second_user, "stake", 200, 10)],
                [(first_user, 80), (second_user, 120)],
            )
        ]

    @staticmethod
    def two_users_deposit_and_then_withdraw():
        first_user = a_user()
        second_user = a_user()
        return [
            (
                [
                    (first_user, "stake", 100, 0),
                    (second_user, "stake", 200, 10),
                    (second_user, "withdraw", 100, 40),
                ],
                [(first_user, 100), (second_user, 100)],
            )
        ]

    @staticmethod
    def two_users_deposit_multiple_times():
        first_user = a_user()
        second_user = a_user()
        return [
            (
                [
                    (first_user, "stake", 100, 0),
                    (second_user, "stake", 200, 10),
                    (first_user, "stake", 100, 40),
                ],
                [(first_user, 100), (second_user, 100)],
            )
        ]

    @data_provider(two_users_deposit.__func__)
    def test_two_users_deposit(self, user_actions, results):
        self.run_case(user_actions, results)

    @data_provider(two_users_deposit_and_then_withdraw.__func__)
    def test_two_users_deposit_and_withdraw(self, user_actions, results):
        self.run_case(user_actions, results)

    @data_provider(two_users_deposit_multiple_times.__func__)
    def test_two_users_deposit_multiple_times(self, user_actions, results):
        self.run_case(user_actions, results)

    def run_case(self, user_actions, results):
        local_storage = self.storage
        for action in user_actions:
            (user, ep, amount, level) = action
            if ep == "stake":
                local_storage = (
                    self.contract.stake(amount)
                    .interpret(storage=local_storage, level=level, sender=user)
                    .storage
                )
            elif ep == "withdraw":
                local_storage = (
                    self.contract.withdraw(amount)
                    .interpret(storage=local_storage, level=level, sender=user)
                    .storage
                )
        for result in results:
            (user, amount) = result
            res = self.contract.claim().interpret(
                storage=local_storage, level=100, sender=user
            )

            self.check_reward_transfer(res, user, amount)
            local_storage = res.storage

    def check_reward_transfer(self, res, user, amount):
        self.assertEqual(1, len(res.operations))
        self.assertEqual(0, res.storage["delegators"][user]["unpaid"])
        op = res.operations[0]
        self.assertEqual(reward_token[0], op["destination"])
        self.assertEqual("0", op["amount"])
        self.assertEqual("transfer", op["parameters"]["entrypoint"])
        self.assertEqual(
            [
                {
                    "prim": "Pair",
                    "args": [
                        {"string": reserve_contract},
                        [
                            {
                                "prim": "Pair",
                                "args": [
                                    {"string": user},
                                    {"int": str(reward_token[1])},
                                    {"int": str(amount)},
                                ],
                            }
                        ],
                    ],
                }
            ],
            op["parameters"]["value"],
        )


def balance_of(user, storage):
    return storage["ledger"]["balances"].get(user, 0)


def with_balance(user, amount, storage):
    storage["ledger"]["balances"][user] = amount
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
        "ledger": {"total_supply": total_supply, "balances": {}},
        "delegators": {},
        "settings": {
            "duration": duration,
            "reward_token": reward_token,
            "staked_token": stake_token,
            "reserve_contract": reserve_contract,
        },
        "reward": {
            "last_block_update": last_block_update,
            "period_end": period_end,
            "accumulated_reward_per_token": accumulated_reward_per_token * scale,
            "reward_per_block": reward_per_block,
        },
    }


def a_user():
    return Key.generate(export=False).public_key_hash()
