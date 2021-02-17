from pathlib import Path
from unittest import TestCase

from pytezos import Key

from src.ligo import LigoContract

token_contract = 'KT1LEzyhXGKfFsczmLJdfW1p8B1XESZjMCvw'
staking_pool = Key.generate(export=False).public_key_hash()
dev_pool = Key.generate(export=False).public_key_hash()
signer_1_key = Key.generate(export=False).public_key_hash()
signer_2_key = Key.generate(export=False).public_key_hash()
signer_3_key = Key.generate(export=False).public_key_hash()


class FeesTest(TestCase):

    @classmethod
    def compile_contract(cls):
        root_dir = Path(__file__).parent.parent / "ligo"
        cls.fees_contract = LigoContract(root_dir / "fees" / "main.mligo", "main").compile_contract()

    @classmethod
    def setUpClass(cls) -> None:
        cls.compile_contract()

    def test_stacks_xtz_for_distribution(self):
        storage = self._valid_storage()
        with_xtz_to_distribute(50, storage)

        res = self.fees_contract.default().interpret(amount=50, storage=storage)

        self.assertEqual(100, res.storage["ledger"]["to_distribute"]["xtz"])

    def test_distribute_xtz_to_dev(self):
        initial_storage = self._valid_storage()
        with_xtz_to_distribute(100, initial_storage)
        initial_storage["ledger"]["distribution"][dev_pool] = {"xtz": 50, "tokens": {}}

        res = self.fees_contract.distribute([], []).interpret(storage=initial_storage,
                                                              sender=quorum_address(initial_storage))

        self.assertEqual(60, self._xtz_of(dev_pool, res.storage))

    def test_distribute_xtz_to_staking(self):
        initial_storage = self._valid_storage()
        with_xtz_to_distribute(100, initial_storage)

        res = self.fees_contract.distribute([], []).interpret(storage=initial_storage,
                                                              sender=quorum_address(initial_storage))

        self.assertEqual(40, self._xtz_of(staking_pool, res.storage))

    def test_distribute_xtz_to_signer_default_payment_address(self):
        initial_storage = self._valid_storage()
        with_xtz_to_distribute(100, initial_storage)

        res = self.fees_contract.distribute([signer_1_key], []).interpret(storage=initial_storage,
                                                                          sender=quorum_address(
                                                                              initial_storage))

        self.assertEqual(50, self._xtz_of(signer_1_key, res.storage))
        self.assertEqual(0, res.storage["ledger"]["to_distribute"]["xtz"])

    def test_distribute_xtz_to_signer_registered_payment_address(self):
        signer_1_payment_address = Key.generate(export=False).public_key_hash()
        initial_storage = self._valid_storage()
        with_xtz_to_distribute(100, initial_storage)
        initial_storage["quorum"]["signers"][signer_1_key] = signer_1_payment_address

        res = self.fees_contract.distribute([signer_1_key], []).interpret(storage=initial_storage,
                                                                          sender=quorum_address(
                                                                              initial_storage))

        self.assertEqual(50, self._xtz_of(signer_1_payment_address, res.storage))

    def test_distribute_xtz_to_several_signers_and_keeps_remaining_to_distribute(self):
        initial_storage = self._valid_storage()
        with_xtz_to_distribute(100, initial_storage)

        res = self.fees_contract.distribute([signer_1_key, signer_2_key, signer_3_key], []).interpret(
            storage=initial_storage,
            sender=quorum_address(
                initial_storage))

        self.assertEqual(16, self._xtz_of(signer_1_key, res.storage))
        self.assertEqual(16, self._xtz_of(signer_2_key, res.storage))
        self.assertEqual(16, self._xtz_of(signer_3_key, res.storage))
        self.assertEqual(2, res.storage["ledger"]["to_distribute"]["xtz"])

    def test_distribute_tokens_to_dev_pool(self):
        initial_storage = self._valid_storage()
        token_address = (token_contract, 0)
        _with_token_to_distribute(initial_storage, token_address, 100)
        initial_storage["ledger"]["distribution"][dev_pool] = {"xtz": 0, "tokens": {token_address: 10}}

        res = self.fees_contract.distribute([], [token_address]).interpret(storage=initial_storage,
                                                                           sender=quorum_address(initial_storage))

        self.assertEqual(20, self._tokens_of(dev_pool, res.storage, token_address))
        self.assertEqual(50, res.storage["ledger"]["to_distribute"]["tokens"][token_address])

    def test_distribute_tokens_to_staking(self):
        initial_storage = self._valid_storage()
        token_address = (token_contract, 0)
        _with_token_to_distribute(initial_storage, token_address, 100)
        initial_storage["ledger"]["distribution"][staking_pool] = {"xtz": 0, "tokens": {token_address: 40}}

        res = self.fees_contract.distribute([], [token_address]).interpret(storage=initial_storage,
                                                                           sender=quorum_address(initial_storage))

        self.assertEqual(80, self._tokens_of(staking_pool, res.storage, token_address))

    def test_distribute_tokens_to_signer(self):
        initial_storage = self._valid_storage()
        token_address = (token_contract, 0)
        _with_token_to_distribute(initial_storage, token_address, 100)
        initial_storage["ledger"]["distribution"][signer_1_key] = {"xtz": 0, "tokens": {token_address: 40}}

        res = self.fees_contract.distribute([signer_1_key], [token_address]).interpret(storage=initial_storage,
                                                                                       sender=quorum_address(
                                                                                           initial_storage))

        self.assertEqual(90, self._tokens_of(signer_1_key, res.storage, token_address))
        self.assertEqual(0, res.storage["ledger"]["to_distribute"]["tokens"][token_address])

    def test_distribute_several_tokens(self):
        initial_storage = self._valid_storage()
        first_token = (token_contract, 0)
        second_token = (token_contract, 1)
        _with_token_to_distribute(initial_storage, first_token, 100)
        _with_token_to_distribute(initial_storage, second_token, 200)

        res = self.fees_contract.distribute([], [first_token, second_token]).interpret(storage=initial_storage,
                                                                                       sender=quorum_address(
                                                                                           initial_storage))

        self.assertEqual(10, self._tokens_of(dev_pool, res.storage, first_token))
        self.assertEqual(20, self._tokens_of(dev_pool, res.storage, second_token))

    def _valid_storage(self):
        seed = self.fees_contract.program.storage.dummy(self.fees_contract.context).to_python_object()
        seed["governance"]["signers_fees"] = 50
        seed["governance"]["staking_fees"] = 40
        seed["governance"]["dev_fees"] = 10
        seed["governance"]["staking"] = staking_pool
        seed["governance"]["dev_pool"] = dev_pool
        return seed

    def _tokens_of(self, addr, storage, token_address):
        self.assertIn(addr, storage["ledger"]["distribution"])
        self.assertIn(token_address, storage["ledger"]["distribution"][addr]["tokens"])
        return storage["ledger"]["distribution"][addr]["tokens"][token_address]

    def _xtz_of(self, key, storage):
        self.assertIn(key, storage["ledger"]["distribution"])
        return storage["ledger"]["distribution"][key]["xtz"]


def dev_pool_address(storage):
    return storage["governance"]["dev_pool"]


def staking_address(storage):
    return storage["governance"]["staking"]


def quorum_address(storage):
    return storage["quorum"]["contract"]


def with_xtz_to_distribute(amount, initial_storage):
    initial_storage["ledger"]["to_distribute"]["xtz"] = amount


def _with_token_to_distribute(initial_storage, token_address, amount):
    initial_storage["ledger"]["to_distribute"]["tokens"][token_address] = amount
