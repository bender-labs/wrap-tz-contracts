import unittest
from pathlib import Path

from pytezos import Key, MichelsonRuntimeError

from src.ligo import LigoContract

reward_token = ("KT1VUNmGa1JYJuNxNS4XDzwpsc9N1gpcCBN2", 0)
self_address = "KT1BEqzn5Wx8uJrZNvuS9DVHmLvG9td3fDLi"


class StakingContractTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        root_dir = Path(__file__).parent.parent / "ligo"
        cls.contract = LigoContract(root_dir / "staking" / "main.mligo", "main").get_contract()


class WalletTest(StakingContractTest):

    def test_should_increase_balance_on_staking(self):
        user = a_user()
        storage = with_balance(user, 150, valid_storage(total_supply=10))

        res = self.contract.stake(100).interpret(storage=storage, sender=user)

        self.assertEqual(250, balance_of(user, res.storage))
        self.assertEqual(110, total_supply(res.storage))

    def test_should_generate_transfer_on_staking(self):
        user = a_user()
        storage = with_balance(user, 150, valid_storage(total_supply=10))

        res = self.contract.stake(100).interpret(storage=storage, sender=user, self_address=self_address)

        self.assertEqual(1, len(res.operations))
        op = res.operations[0]
        self.assertEqual(reward_token[0], op['destination'])
        self.assertEqual('0', op['amount'])
        self.assertEqual('transfer', op['parameters']['entrypoint'])
        self.assertEqual([{'prim': 'Pair', 'args': [{'string': user}, [
            {'prim': 'Pair',
             'args': [{'string': self_address}, {'int': str(reward_token[1])}, {'int': str(100)}]}]]}],
                         op['parameters']['value'])

    def test_should_decrease_balance_on_withdraw(self):
        user = a_user()
        storage = with_balance(user, 150, valid_storage(total_supply=10))

        res = self.contract.withdraw(10).interpret(storage=storage, sender=user)

        self.assertEqual(140, balance_of(user, res.storage))
        self.assertEqual(0, total_supply(res.storage))

    def test_should_generate_transfer_on_withdraw(self):
        user = a_user()
        storage = with_balance(user, 150, valid_storage(total_supply=10))

        res = self.contract.withdraw(10).interpret(storage=storage, sender=user, self_address=self_address)

        self.assertEqual(1, len(res.operations))
        op = res.operations[0]
        self.assertEqual(reward_token[0], op['destination'])
        self.assertEqual('0', op['amount'])
        self.assertEqual('transfer', op['parameters']['entrypoint'])
        self.assertEqual([{'prim': 'Pair', 'args': [{'string': self_address}, [
            {'prim': 'Pair',
             'args': [{'string': user}, {'int': str(reward_token[1])}, {'int': str(10)}]}]]}],
                         op['parameters']['value'])

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


def balance_of(user, storage):
    return storage["ledger"]["balances"].get(user, 0)


def with_balance(user, amount, storage):
    storage["ledger"]["balances"][user] = amount
    return storage


def total_supply(storage):
    return storage["ledger"]["total_supply"]


def valid_storage(total_supply=0):
    return {
        "ledger": {
            "total_supply": total_supply,
            "balances": {}
        },
        "settings": {
            "period": 10,
            "reward_token": reward_token
        }
    }


def a_user():
    return Key.generate(export=False).public_key_hash()
