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
scale = 10 ** 16


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
            reward_per_block=2 * scale,
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
            3.1 *
            scale, res.storage["delegators"][user]["reward_per_token_paid"]
        )
        self.assertEqual(1, res.storage["delegators"][user]["unpaid"])

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
        self.assertEqual(
            5 * scale, res.storage["delegators"][user]["reward_per_token_paid"]
        )
        self.assertEqual(0, res.storage["delegators"][user]["unpaid"])


class WithdrawalTest(StakingContractTest):
    def test_should_decrease_balance_on_withdraw(self):
        user = a_user()
        storage = with_balance(user, 150, valid_storage(total_supply=10))

        res = self.contract.withdraw(10).interpret(
            storage=storage, sender=user)

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
            reward_per_block=2*scale,
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
            1.2 *
            scale, res.storage["delegators"][user]["reward_per_token_paid"]
        )
        self.assertEqual(120 * scale, res.storage["delegators"][user]["unpaid"])


class ClaimTest(StakingContractTest):
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
        
        self.assertEqual(0, res.storage["delegators"][user]["unpaid"])
        self.assertEqual(1, len(res.operations))
        op = res.operations[0]
        self.assertEqual(reserve_contract, op["destination"])
        self.assertEqual("0", op["amount"])
        self.assertEqual("transfer_to_delegator",
                         op["parameters"]["entrypoint"])
        self.assertEqual(
            {
                "prim": "Pair",
                "args": [
                    {"string": user},
                    {"int": str(120)},
                ],
            },
            op["parameters"]["value"],
        )

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
        
        self.assertEqual(250000000000, res.storage["delegators"][user]["unpaid"])
        self.assertEqual(1, len(res.operations))
        op = res.operations[0]
        self.assertEqual(reserve_contract, op["destination"])
        self.assertEqual("0", op["amount"])
        self.assertEqual("transfer_to_delegator",
                         op["parameters"]["entrypoint"])
        self.assertEqual(
            {
                "prim": "Pair",
                "args": [
                    {"string": user},
                    {"int": str(100)},
                ],
            },
            op["parameters"]["value"],
        )

class PlanTests(StakingContractTest):
    def test_should_call_reserve_contract(self):
        res = self.contract.update_plan(100).interpret(
            storage=valid_storage(period_end=100), level=101, sender=admin
        )

        self.assertEqual(1, len(res.operations))
        op = res.operations[0]
        self.assertEqual(reserve_contract, op["destination"])
        self.assertEqual("0", op["amount"])
        self.assertEqual("claim_fees", op["parameters"]["entrypoint"])
        self.assertEqual(
            {"int": "100"},
            op["parameters"]["value"],
        )

    def test_should_create_new_plan(self):
        res = self.contract.update_plan(100).interpret(
            storage=valid_storage(period_end=100, duration=20), level=101, sender=admin
        )

        self.assertEqual(res.storage["reward"]["period_end"], 121)
        self.assertEqual(res.storage["reward"]["last_block_update"], 101)
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

    def test_should_use_R_and_left_over_for_next_distribution_period(self):
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

    def test_should_reject_new_plan_if_period_is_not_finished(self):
        with self.assertRaises(MichelsonRuntimeError) as context:
            self.contract.update_plan(100).interpret(
                storage=valid_storage(period_end=100, duration=20),
                level=99,
                sender=admin,
            )
        self.assertEqual("'DISTRIBUTION_RUNNING'", context.exception.args[-1])

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


class AdminTests(StakingContractTest):
    def test_should_change_admin(self):
        new_admin = a_user()

        res = self.contract.change_admin(new_admin).interpret(
            storage=valid_storage(), sender=admin
        )

        self.assertEqual(new_admin, res.storage["admin"]["pending_admin"])
        self.assertEqual(admin, res.storage["admin"]["address"])

    def test_should_reject_if_not_admin(self):
        with self.assertRaises(MichelsonRuntimeError) as context:
            self.contract.change_admin(admin).interpret(
                storage=valid_storage(), sender=a_user()
            )
        self.assertEqual("'NOT_AN_ADMIN'", context.exception.args[-1])

    def test_should_confirm_new_admin(self):
        new_admin = a_user()
        storage = (
            self.contract.change_admin(new_admin)
            .interpret(storage=valid_storage(), sender=admin)
            .storage
        )

        res = self.contract.confirm_new_admin().interpret(
            storage=storage, sender=new_admin
        )

        self.assertEqual(None, res.storage["admin"]["pending_admin"])
        self.assertEqual(new_admin, res.storage["admin"]["address"])

    def test_should_refect_if_no_pending_admin(self):
        with self.assertRaises(MichelsonRuntimeError) as context:
            self.contract.confirm_new_admin().interpret(
                storage=valid_storage(), sender=admin
            )
        self.assertEqual("'NO_PENDING_ADMIN'", context.exception.args[-1])

    def test_should_reject_if_not_pending_admin(self):
        with self.assertRaises(MichelsonRuntimeError) as context:
            new_admin = a_user()
            storage = (
                self.contract.change_admin(new_admin)
                .interpret(storage=valid_storage(), sender=admin)
                .storage
            )

            self.contract.confirm_new_admin().interpret(storage=storage, sender=admin)
        self.assertEqual("'NOT_PENDING_ADMIN'", context.exception.args[-1])


class FunctionalTests(StakingContractTest):
    def setUp(self) -> None:
        super().setUp()
        self.storage = valid_storage(
            period_end=100, reward_per_block=2 * scale)

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

    @data_provider(two_users_deposit.__func__)
    def test_two_users_deposit(self, user_actions, results):
        self.run_case(user_actions, results)

    @staticmethod
    def big_numbers():
        first_user = a_user()
        return [
            (
                [(first_user, "stake", 100_000_000 * 10 ** 8, 0)],
                [(first_user, 200)],
            )
        ]

    @data_provider(big_numbers.__func__)
    def test_big_numbers(self, user_actions, results):
        self.run_case(user_actions, results)

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

    @data_provider(two_users_deposit_and_then_withdraw.__func__)
    def test_two_users_deposit_and_withdraw(self, user_actions, results):
        self.run_case(user_actions, results)

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

    @data_provider(two_users_deposit_multiple_times.__func__)
    def test_two_users_deposit_multiple_times(self, user_actions, results):
        self.run_case(user_actions, results)

    @staticmethod
    def one_user_on_two_period():
        first_user = a_user()
        return [
            (
                [
                    (first_user, "stake", 100, 98),
                    (admin, "update_plan", 100, 100),
                    (first_user, "stake", 100, 100),
                ],
                [(first_user, 300)],
            )
        ]

    @data_provider(one_user_on_two_period.__func__)
    def test_one_user_on_two_periods(self, user_actions, results):
        self.run_case(user_actions, results)

    @staticmethod
    def one_user_on_next_period():
        first_user = a_user()
        return [
            (
                [
                    (admin, "update_plan", 100, 100),
                    (first_user, "stake", 100, 100),
                ],
                [(first_user, 300)],
            )
        ]

    @data_provider(one_user_on_next_period.__func__)
    def test_one_user_on_next_period(self, user_actions, results):
        self.run_case(user_actions, results)

    @staticmethod
    def one_user_unstake_in_the_middle():
        first_user = a_user()
        return [
            (
                [
                    (first_user, "stake", 100, 0),
                    (first_user, "withdraw", 100, 50),
                    (admin, "update_plan", 100, 100),
                    (first_user, "stake", 100, 100),
                ],
                [(first_user, 300)],
            )
        ]

    @data_provider(one_user_unstake_in_the_middle.__func__)
    def test_one_user_unstake_in_the_middle(self, user_actions, results):
        self.run_case(user_actions, results)

    @staticmethod
    def two_users_sandwiched_an_update():
        first_user = a_user()
        second_user = a_user()
        return [
            (
                [
                    (first_user, "stake", 100, 100),
                    (admin, "update_plan", 100, 100),
                    (second_user, "stake", 100, 100),
                ],
                [(first_user, 150), (second_user, 150)],
            )
        ]

    @data_provider(two_users_sandwiched_an_update.__func__)
    def test_two_users_sandwiched_an_update(self, user_actions, results):
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
            elif ep == "update_plan":
                local_storage = (
                    self.contract.update_plan(amount)
                    .interpret(storage=local_storage, level=level, sender=user)
                    .storage
                )
        for result in results:
            (user, amount) = result
            res = self.contract.claim().interpret(
                storage=local_storage,
                level=local_storage["reward"]["period_end"],
                sender=user,
            )

            self.check_reward_transfer(res, user, amount)
            local_storage = res.storage

    def check_reward_transfer(self, res, user, amount):
        self.assertEqual(1, len(res.operations))
        self.assertEqual(0, res.storage["delegators"][user]["unpaid"])
        op = res.operations[0]
        self.assertEqual(reserve_contract, op["destination"])
        self.assertEqual("0", op["amount"])
        self.assertEqual("transfer_to_delegator",
                         op["parameters"]["entrypoint"])
        self.assertEqual(
            {
                "prim": "Pair",
                "args": [
                    {"string": user},
                    {"int": str(amount)},
                ],
            },
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
            "staked_token": stake_token,
            "reserve_contract": reserve_contract
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


def a_user():
    return Key.generate(export=False).public_key_hash()
