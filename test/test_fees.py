from pathlib import Path
from unittest import TestCase

from pytezos import Key

from src.ligo import LigoContract

token_contract = 'KT1LEzyhXGKfFsczmLJdfW1p8B1XESZjMCvw'
staking_contract = 'KT1X82SpRG97yUYpyiYSWN4oPFYSq46BthCi'


class FeesTest(TestCase):

    @classmethod
    def compile_contract(cls):
        root_dir = Path(__file__).parent.parent / "ligo"
        cls.fees_contract = LigoContract(root_dir / "fees" / "main.mligo", "main").compile_contract()

    @classmethod
    def setUpClass(cls) -> None:
        cls.compile_contract()

    def test_stacks_xtz_for_distribution(self):
        res = self.fees_contract.default().interpret(amount=100, storage=self._valid_storage())

        self.assertEqual(100, res.storage["ledger"]["to_distribute"]["xtz"])

    def test_distribute_xtz_to_dev(self):
        initial_storage = self._valid_storage()
        initial_storage["ledger"]["to_distribute"]["xtz"] = 100

        res = self.fees_contract.distribute([], []).interpret(storage=initial_storage,
                                                              sender=quorum_address(initial_storage))

        dev_pool = dev_pool_address(res.storage)
        self.assertIn(dev_pool, res.storage["ledger"]["distribution"])
        self.assertEqual(10, res.storage["ledger"]["distribution"][dev_pool]["xtz"])

    def test_distribute_xtz_to_staking(self):
        initial_storage = self._valid_storage()
        initial_storage["ledger"]["to_distribute"]["xtz"] = 100

        res = self.fees_contract.distribute([], []).interpret(storage=initial_storage,
                                                              sender=quorum_address(initial_storage))

        staking_pool = staking_address(res.storage)
        self.assertIn(staking_pool, res.storage["ledger"]["distribution"])
        self.assertEqual(40, res.storage["ledger"]["distribution"][staking_pool]["xtz"])

    def test_distribute_xtz_to_signer_default_payment_address(self):
        signer_1_key = Key.generate(export=False)
        initial_storage = self._valid_storage()
        initial_storage["ledger"]["to_distribute"]["xtz"] = 100

        res = self.fees_contract.distribute([signer_1_key.public_key_hash()], []).interpret(storage=initial_storage,
                                                                                            sender=quorum_address(
                                                                                                initial_storage))

        self.assertIn(signer_1_key.public_key_hash(), res.storage["ledger"]["distribution"])
        self.assertEqual(50, res.storage["ledger"]["distribution"][signer_1_key.public_key_hash()]["xtz"])
        self.assertEqual(0, res.storage["ledger"]["to_distribute"]["xtz"])

    def test_distribute_xtz_to_signer_registered_payment_address(self):
        signer_1_key = Key.generate(export=False).public_key_hash()
        signer_1_payment_address = Key.generate(export=False).public_key_hash()
        initial_storage = self._valid_storage()
        initial_storage["ledger"]["to_distribute"]["xtz"] = 100
        initial_storage["quorum"]["signers"][signer_1_key] = signer_1_payment_address

        res = self.fees_contract.distribute([signer_1_key], []).interpret(storage=initial_storage,
                                                                          sender=quorum_address(
                                                                              initial_storage))

        self.assertIn(signer_1_payment_address, res.storage["ledger"]["distribution"])
        self.assertEqual(50, res.storage["ledger"]["distribution"][signer_1_payment_address]["xtz"])

    def test_distribute_xtz_to_several_signers_and_keeps_remaining_to_distribute(self):
        signer_1_key = Key.generate(export=False).public_key_hash()
        signer_2_key = Key.generate(export=False).public_key_hash()
        signer_3_key = Key.generate(export=False).public_key_hash()
        initial_storage = self._valid_storage()
        initial_storage["ledger"]["to_distribute"]["xtz"] = 100

        res = self.fees_contract.distribute([signer_1_key, signer_2_key, signer_3_key], []).interpret(
            storage=initial_storage,
            sender=quorum_address(
                initial_storage))

        self.assertIn(signer_1_key, res.storage["ledger"]["distribution"])
        self.assertIn(signer_2_key, res.storage["ledger"]["distribution"])
        self.assertIn(signer_3_key, res.storage["ledger"]["distribution"])
        self.assertEqual(16, res.storage["ledger"]["distribution"][signer_1_key]["xtz"])
        self.assertEqual(16, res.storage["ledger"]["distribution"][signer_2_key]["xtz"])
        self.assertEqual(16, res.storage["ledger"]["distribution"][signer_3_key]["xtz"])
        self.assertEqual(2, res.storage["ledger"]["to_distribute"]["xtz"])

    def test_distribute_tokens_to_dev_pool(self):
        initial_storage = self._valid_storage()
        token_address = (token_contract, 0)
        initial_storage["ledger"]["to_distribute"]["tokens"][token_address] = 100

        res = self.fees_contract.distribute([], [token_address]).interpret(storage=initial_storage,
                                                                           sender=quorum_address(initial_storage))

        dev_pool = dev_pool_address(res.storage)
        self.assertIn(dev_pool, res.storage["ledger"]["distribution"])
        self.assertIn(token_address, res.storage["ledger"]["distribution"][dev_pool]["tokens"])
        self.assertEqual(10, res.storage["ledger"]["distribution"][dev_pool]["tokens"][token_address])

    def _valid_storage(self):
        seed = self.fees_contract.program.storage.dummy(self.fees_contract.context).to_python_object()
        seed["governance"]["signers_fees"] = 50
        seed["governance"]["staking_fees"] = 40
        seed["governance"]["dev_fees"] = 10
        seed["governance"]["staking"] = staking_contract
        return seed


def dev_pool_address(storage):
    return storage["governance"]["dev_pool"]


def staking_address(storage):
    return storage["governance"]["staking"]


def quorum_address(storage):
    return storage["quorum"]["contract"]
