from pathlib import Path
from unittest import TestCase

from pytezos import Key

from src.ligo import LigoContract

token_contract = 'KT1LEzyhXGKfFsczmLJdfW1p8B1XESZjMCvw'
self_address = 'KT1RXpLtz22YgX24QQhxKVyKvtKZFaAVtTB9'
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

    def _valid_storage(self):
        seed = self.fees_contract.program.storage.dummy(self.fees_contract.context).to_python_object()
        seed["governance"]["signers_fees"] = 50
        seed["governance"]["staking_fees"] = 40
        seed["governance"]["dev_fees"] = 10
        seed["governance"]["staking"] = staking_pool
        seed["governance"]["dev_pool"] = dev_pool
        return seed


class FeesQuorumTest(FeesTest):

    def test_should_set_quorum_address(self):
        storage = self._valid_storage()
        quorum = quorum_address(storage)

        res = self.fees_contract.set_quorum_contract(self_address).interpret(storage=storage, sender=quorum)

        self.assertEqual(self_address, quorum_address(res.storage))

    def test_should_set_signer_payment_address(self):
        payment_address = Key.generate(export=False).public_key_hash()
        storage = self._valid_storage()

        res = self.fees_contract.set_signer_payment_address(signer_1_key, payment_address) \
            .interpret(storage=storage,
                       sender=quorum_address(
                           storage))

        self.assertEqual(payment_address, res.storage["quorum"]["signers"][signer_1_key])


class FeesDistributionTest(FeesTest):

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
        with_token_to_distribute(initial_storage, token_address, 100)
        initial_storage["ledger"]["distribution"][dev_pool] = {"xtz": 0, "tokens": {token_address: 10}}

        res = self.fees_contract.distribute([], [token_address]).interpret(storage=initial_storage,
                                                                           sender=quorum_address(initial_storage))

        self.assertEqual(20, self._tokens_of(dev_pool, res.storage, token_address))
        self.assertEqual(50, res.storage["ledger"]["to_distribute"]["tokens"][token_address])

    def test_distribute_tokens_to_staking(self):
        initial_storage = self._valid_storage()
        token_address = (token_contract, 0)
        with_token_to_distribute(initial_storage, token_address, 100)
        initial_storage["ledger"]["distribution"][staking_pool] = {"xtz": 0, "tokens": {token_address: 40}}

        res = self.fees_contract.distribute([], [token_address]).interpret(storage=initial_storage,
                                                                           sender=quorum_address(initial_storage))

        self.assertEqual(80, self._tokens_of(staking_pool, res.storage, token_address))

    def test_distribute_tokens_to_signer(self):
        initial_storage = self._valid_storage()
        token_address = (token_contract, 0)
        with_token_to_distribute(initial_storage, token_address, 100)
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
        with_token_to_distribute(initial_storage, first_token, 100)
        with_token_to_distribute(initial_storage, second_token, 200)

        res = self.fees_contract.distribute([], [first_token, second_token]).interpret(storage=initial_storage,
                                                                                       sender=quorum_address(
                                                                                           initial_storage))

        self.assertEqual(10, self._tokens_of(dev_pool, res.storage, first_token))
        self.assertEqual(20, self._tokens_of(dev_pool, res.storage, second_token))

    def _tokens_of(self, addr, storage, token_address):
        self.assertIn(addr, storage["ledger"]["distribution"])
        self.assertIn(token_address, storage["ledger"]["distribution"][addr]["tokens"])
        return storage["ledger"]["distribution"][addr]["tokens"][token_address]

    def _xtz_of(self, key, storage):
        self.assertIn(key, storage["ledger"]["distribution"])
        return storage["ledger"]["distribution"][key]["xtz"]


class FeesCollectTest(FeesTest):

    def test_stacks_xtz_for_distribution(self):
        storage = self._valid_storage()
        with_xtz_to_distribute(50, storage)

        res = self.fees_contract.default().interpret(amount=50, storage=storage)

        self.assertEqual(100, res.storage["ledger"]["to_distribute"]["xtz"])

    def test_stacks_token_for_distribution(self):
        storage = self._valid_storage()
        with_listed_token(storage, token_contract)
        batch = {"from_": None,
                 "txs": [{"to_": "KT1RXpLtz22YgX24QQhxKVyKvtKZFaAVtTB9", "token_id": 0, "amount": 100}]}

        res = self.fees_contract.tokens_received([batch], Key.generate(export=False).public_key_hash()).interpret(
            storage=storage,
            sender=token_contract,
            self_address=self_address)

        self.assertEqual(100, self._tokens_to_distribute(res.storage, (token_contract, 0)))

    def test_stacks_several_tokens_for_distribution(self):
        storage = self._valid_storage()
        with_listed_token(storage, token_contract)
        batch = {"from_": None,
                 "txs": [{"to_": self_address, "token_id": 0, "amount": 100},
                         {"to_": self_address, "token_id": 1, "amount": 200}]}

        res = self.fees_contract.tokens_received([batch], Key.generate(export=False).public_key_hash()).interpret(
            storage=storage,
            sender=token_contract,
            self_address=self_address)

        self.assertEqual(100, self._tokens_to_distribute(res.storage, (token_contract, 0)))
        self.assertEqual(200, self._tokens_to_distribute(res.storage, (token_contract, 1)))

    def test_does_not_stack_tokens_to_other_receiver(self):
        storage = self._valid_storage()
        with_listed_token(storage, token_contract)
        batch = {"from_": None,
                 "txs": [{"to_": self_address, "token_id": 0, "amount": 100},
                         {"to_": dev_pool, "token_id": 0, "amount": 200}]}

        res = self.fees_contract.tokens_received([batch], Key.generate(export=False).public_key_hash()).interpret(
            storage=storage,
            sender=token_contract,
            self_address=self_address)

        self.assertEqual(100, self._tokens_to_distribute(res.storage, (token_contract, 0)))

    def _tokens_to_distribute(self, storage, token):
        self.assertIn(token, storage["ledger"]["to_distribute"]["tokens"])
        return storage["ledger"]["to_distribute"]["tokens"][token]


def dev_pool_address(storage):
    return storage["governance"]["dev_pool"]


def staking_address(storage):
    return storage["governance"]["staking"]


def quorum_address(storage):
    return storage["quorum"]["contract"]


def with_xtz_to_distribute(amount, initial_storage):
    initial_storage["ledger"]["to_distribute"]["xtz"] = amount


def with_token_to_distribute(initial_storage, token_address, amount):
    initial_storage["ledger"]["to_distribute"]["tokens"][token_address] = amount


def with_listed_token(storage, contract):
    storage["minter"]["listed_tokens"] = [contract]
