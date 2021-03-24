from pathlib import Path
from unittest import TestCase

from pytezos import Key, MichelsonRuntimeError

from src.ligo import LigoContract

super_admin = Key.generate(export=False).public_key_hash()
user = Key.generate(export=False).public_key_hash()
oracle_address = Key.generate(export=False).public_key_hash()
contract_address = 'KT1RXpLtz22YgX24QQhxKVyKvtKZFaAVtTB9'
dao_address = 'KT1Hd1hiG1PhZ7xRi1HUVoAXM7i7Pzta8EHW'


class GovernanceTokenTest(TestCase):
    @classmethod
    def compile_contract(cls):
        root_dir = Path(__file__).parent.parent / "ligo"
        cls.contract = LigoContract(root_dir / "fa2" / "governance" / "main.mligo", "main").compile_contract()

    @classmethod
    def setUpClass(cls):
        cls.compile_contract()
        cls.maxDiff = None


class Fa2Test(GovernanceTokenTest):

    def test_should_transfer_unfrozen(self):
        storage1 = initial_storage()
        storage = with_token_balance(storage1, user, 100)
        destination = Key.generate(export=False).public_key_hash()

        result = self.contract.transfer([
            {
                "from_": user, "txs": [{"to_": destination, "token_id": 0, "amount": 10}]
            }]).interpret(storage=storage, sender=user)

        self.assertEqual(10, balance_of(result.storage, destination))
        self.assertEqual(90, balance_of(result.storage, user))

    def test_should_reject_other_transfers(self):
        with self.assertRaises(MichelsonRuntimeError) as context:
            storage = with_token_balance(initial_storage(), user, 100)
            destination = Key.generate(export=False).public_key_hash()

            self.contract.transfer([
                {
                    "from_": user, "txs": [{"to_": destination, "token_id": 2, "amount": 10}]
                }]).interpret(storage=storage, sender=user)
        self.assertEqual("'FA2_TOKEN_UNDEFINED'", context.exception.args[-1])

    def test_operator_should_transfer_tokens(self):
        storage = with_token_balance(initial_storage(), user, 100)
        destination = Key.generate(export=False).public_key_hash()
        storage['assets']['operators'][(user, super_admin)] = None

        result = self.contract.transfer([
            {
                "from_": user, "txs": [{"to_": destination, "token_id": 0, "amount": 10}]
            }]).interpret(storage=storage, sender=super_admin)

        self.assertEqual(10, balance_of(result.storage, destination))
        self.assertEqual(90, balance_of(result.storage, user))


class OracleTest(GovernanceTokenTest):

    def test_should_distribute_tokens(self):
        storage = initial_storage()

        res = self.contract.distribute([{"to_": user, "amount": 20}]).interpret(storage=storage, sender=oracle_address)

        self.assertEqual(20, balance_of(res.storage, user))
        self.assertEqual(20, total_supply(res.storage))
        self.assertEqual(20, res.storage['oracle']['distributed'])

    def test_should_not_distribute_more_tokens_than_reserve(self):
        with self.assertRaises(MichelsonRuntimeError) as context:
            storage = initial_storage()
            storage['oracle']['distributed'] = storage['oracle']['max_supply']

            self.contract.distribute([{"to_": user, "amount": 10001}]).interpret(storage=storage, sender=oracle_address)

        self.assertEqual("'RESERVE_DEPLETED'", context.exception.args[-1])

    def test_should_initiate_migration(self):
        res = self.contract.migrate_oracle(contract_address).interpret(storage=initial_storage(), sender=oracle_address)

        self.assertEqual(contract_address, res.storage['oracle']['role']['pending_contract'])

    def test_should_confirm_migration(self):
        storage = initial_storage()
        storage['oracle']['role']['pending_contract'] = contract_address

        res = self.contract.confirm_oracle_migration().interpret(storage=storage, sender=contract_address)

        self.assertEqual(contract_address, res.storage['oracle']['role']['contract'])
        self.assertEqual(None, res.storage['oracle']['role']['pending_contract'])


class TokenManagerTest(GovernanceTokenTest):

    def test_should_mint(self):
        storage = initial_storage()

        res = self.contract.mint_tokens([{'owner': user, 'token_id': 0, 'amount': 10}]).interpret(storage=storage,
                                                                                                  sender=super_admin)

        self.assertEqual(10, balance_of(res.storage, user))
        self.assertEqual(0, res.storage['assets']['total_supply'])

    def test_should_burn(self):
        storage1 = initial_storage()
        storage = with_token_balance(storage1, user, 20)

        res = self.contract.burn_tokens([{'owner': user, 'token_id': 0, 'amount': 10}]).interpret(storage=storage,
                                                                                                  sender=super_admin)

        self.assertEqual(10, balance_of(res.storage, user))
        self.assertEqual(20, res.storage['assets']['total_supply'])

    def test_should_not_mint_something_else_than_unfrozen_token(self):
        with self.assertRaises(MichelsonRuntimeError) as context:
            self.contract.mint_tokens([{'owner': user, 'token_id': 1, 'amount': 10}]).interpret(
                storage=initial_storage(),
                sender=super_admin)
        self.assertEqual("'BAD_MINT_BURN'", context.exception.args[-1])

    def test_should_not_burn_something_else_than_unfrozen_token(self):
        with self.assertRaises(MichelsonRuntimeError) as context:
            self.contract.burn_tokens([{'owner': user, 'token_id': 1, 'amount': 10}]).interpret(
                storage=initial_storage(),
                sender=super_admin)
        self.assertEqual("'BAD_MINT_BURN'", context.exception.args[-1])


def with_token_balance(storage, address, amount):
    storage["assets"]["ledger"][address] = amount
    storage["assets"]["total_supply"] = amount
    return storage


def balance_of(storage, address):
    return storage["assets"]["ledger"][address]


def total_supply(storage):
    return storage['assets']['total_supply']


def initial_storage():
    return {
        'admin': {
            'admin': super_admin,
            'paused': False,
            'pending_admin': None,
            'minter': super_admin
        },
        'metadata': {},
        'assets': {'ledger': {},
                   'operators': {},
                   'token_metadata': {},
                   'total_supply': 0,
                   },
        'oracle': {
            'role': {
                'contract': oracle_address,
                'pending_contract': None
            },
            'max_supply': 10000,
            'distributed': 0
        }
    }
