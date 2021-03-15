from pathlib import Path
from unittest import TestCase

from pytezos import Key, MichelsonRuntimeError

from src.ligo import LigoContract

super_admin = Key.generate(export=False).public_key_hash()
user = Key.generate(export=False).public_key_hash()
self_address = 'KT1RXpLtz22YgX24QQhxKVyKvtKZFaAVtTB9'
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
        storage = with_unfrozen_balance(initial_storage(), user, 100)
        destination = Key.generate(export=False).public_key_hash()

        result = self.contract.transfer([
            {
                "from_": user, "txs": [{"to_": destination, "token_id": 0, "amount": 10}]
            }]).interpret(storage=storage, sender=user)

        self.assertEqual(10, balance_of(result.storage, destination, 0))
        self.assertEqual(90, balance_of(result.storage, user, 0))

    def test_should_reject_other_transfers(self):
        with self.assertRaises(MichelsonRuntimeError) as context:
            storage = with_token_balance(initial_storage(), user, 2, 100)
            destination = Key.generate(export=False).public_key_hash()

            self.contract.transfer([
                {
                    "from_": user, "txs": [{"to_": destination, "token_id": 2, "amount": 10}]
                }]).interpret(storage=storage, sender=user)
        self.assertEqual("'FROZEN_TOKEN_NOT_TRANSFERABLE'", context.exception.args[-1])

    def test_admin_should_transfer_frozen_tokens(self):
        storage = with_token_balance(initial_storage(), user, 1, 100)
        destination = Key.generate(export=False).public_key_hash()

        result = self.contract.transfer([
            {
                "from_": user, "txs": [{"to_": destination, "token_id": 1, "amount": 10}]
            }]).interpret(storage=storage, sender=super_admin)

        self.assertEqual(10, balance_of(result.storage, destination, 1))
        self.assertEqual(90, balance_of(result.storage, user, 1))


class DaoTest(GovernanceTokenTest):

    def test_should_swap_frozen_to_proposal(self):
        storage = with_token_balance(initial_storage(), user, 1, 100)

        result = self.contract.lock([
            {
                "from_": user, "proposal_id": 2, "amount": 10
            }]
        ).interpret(storage=storage, sender=dao_address)

        self.assertEqual(90, balance_of(result.storage, user, 1))
        self.assertEqual(10, balance_of(result.storage, user, 2))
        self.assertEqual(10, total_supply_of(result.storage, 2))
        self.assertEqual(90, total_supply_of(result.storage, 1))

    def test_should_fail_to_swap_if_not_enough(self):
        storage = initial_storage()
        with self.assertRaises(MichelsonRuntimeError) as context:
            self.contract.lock([
                {
                    "from_": user, "proposal_id": 2, "amount": 10
                }]
            ).interpret(storage=storage, sender=dao_address)

        self.assertEqual("('FA2_INSUFFICIENT_BALANCE' * (10 * 0))", context.exception.args[-1])

    def test_should_fail_if_not_dao(self):
        storage = with_token_balance(initial_storage(), user, 1, 100)
        with self.assertRaises(MichelsonRuntimeError) as context:
            self.contract.lock([
                {
                    "from_": user, "proposal_id": 2, "amount": 10
                }]
            ).interpret(storage=storage, sender=user)

        self.assertEqual("'UNAUTHORIZED'", context.exception.args[-1])

    def test_should_unlock(self):
        storage = with_token_balance(initial_storage(), user, 2, 100)

        result = self.contract.unlock([
            {
                "from_": user, "proposal_id": 2, "amount": 10
            }]
        ).interpret(storage=storage, sender=dao_address)

        self.assertEqual(10, balance_of(result.storage, user, 1))
        self.assertEqual(90, balance_of(result.storage, user, 2))
        self.assertEqual(90, total_supply_of(result.storage, 2))
        self.assertEqual(10, total_supply_of(result.storage, 1))

    def test_get_total_supply(self):
        storage = initial_storage();
        storage["assets"]["total_supply"][0] = 300

        res = self.contract.get_total_supply(dao_address).interpret(storage=storage, sender=dao_address)

        self.assertEqual(1, len(res.operations))
        callback = res.operations[0]
        self.assertEqual(dao_address, callback['destination'])
        self.assertEqual({'int': '300'}, callback['parameters']['value'])

    def test_should_migrate_dao(self):
        storage = initial_storage()

        res = self.contract.migrate_dao(self_address).interpret(storage=storage, sender=dao_address)

        self.assertEqual(self_address, res.storage['dao']['pending_contract'])

    def test_should_confirm_dao_migration(self):
        storage = initial_storage()
        storage['dao']['pending_contract'] = self_address

        res = self.contract.confirm_dao_migration().interpret(storage=storage, sender=self_address)

        self.assertEqual(None, res.storage['dao']['pending_contract'])
        self.assertEqual(self_address, res.storage['dao']['contract'])


def with_unfrozen_balance(storage, address, amount):
    return with_token_balance(storage, address, 0, amount)


def with_token_balance(storage, address, token_id, amount):
    storage["assets"]["ledger"][(address, token_id)] = amount
    storage["assets"]["total_supply"][token_id] = amount
    return storage


def balance_of(storage, address, token):
    return storage["assets"]["ledger"][(address, token)]


def total_supply_of(storage, token_id):
    return storage['assets']['total_supply'][token_id]


def initial_storage():
    return {'admin': {'admin': super_admin, 'paused': {}, 'pending_admin': None},
            'assets': {'ledger': {}, 'operators': {},
                       'token_metadata': {}, 'total_supply': {0: 0, 1: 0}},
            'dao': {
                'contract': dao_address,
                'pending_contract': None
            }
            }
