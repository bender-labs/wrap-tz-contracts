from pathlib import Path
from unittest import TestCase

from pytezos import michelson_to_micheline, MichelsonRuntimeError, Key
from src.ligo import LigoContract

user = 'tz1grSQDByRpnVs7sPtaprNZRp531ZKz6Jmm'
fees_contract = 'tz1et19hnF9qKv6yCbbxjS1QDXB5HVx6PCVk'
token_contract = 'KT1LEzyhXGKfFsczmLJdfW1p8B1XESZjMCvw'
nft_contract = 'KT1X82SpRG97yUYpyiYSWN4oPFYSq46BthCi'
other_party = 'tz3SYyWM9sq9eWTxiA8KHb36SAieVYQPeZZm'
self_address = 'KT1RXpLtz22YgX24QQhxKVyKvtKZFaAVtTB9'
dev_pool = Key.generate(export=False).public_key_hash()
staking_pool = Key.generate(export=False).public_key_hash()
signer_1_key = Key.generate(export=False).public_key_hash()
signer_2_key = Key.generate(export=False).public_key_hash()
signer_3_key = Key.generate(export=False).public_key_hash()
quorum_contract = 'KT1Qjq1Yp27QUT8s8ECRbra48pbDmfWa1u2K'
oracle = 'KT1TDjmcU182CyFdNBpnqbecPSJDPNRBKqFZ'
admin = Key.generate(export=False).public_key_hash()
governance = Key.generate(export=False).public_key_hash()


class MinterTest(TestCase):
    @classmethod
    def compile_contract(cls):
        root_dir = Path(__file__).parent.parent / "ligo"
        cls.minter_contract = LigoContract(root_dir / "minter" / "main.mligo", "main").compile_contract()

    @classmethod
    def setUpClass(cls):
        cls.compile_contract()
        cls.maxDiff = None

    def _tokens_of(self, storage, addr, token_address):
        key = (addr,) + token_address
        self.assertIn(key, storage["fees"]["tokens"])
        return storage["fees"]["tokens"][key]

    def _xtz_of(self, address, storage):
        self.assertIn(address, storage["fees"]["xtz"])
        return storage["fees"]["xtz"][address]


class MintErc20Test(MinterTest):

    def test_rejects_mint_if_not_signer(self):
        with self.assertRaises(MichelsonRuntimeError) as context:
            self.minter_contract.mint_erc20(mint_erc20_parameters()).interpret(
                storage=valid_storage(),
                sender=user)

        self.assertEqual("'NOT_SIGNER'", context.exception.args[-1])

    def test_cant_mint_if_paused(self):
        with self.assertRaises(MichelsonRuntimeError) as context:
            self.minter_contract.mint_erc20(mint_erc20_parameters()).interpret(
                storage=valid_storage(paused=True),
                sender=quorum_contract)

        self.assertEqual("'CONTRACT_PAUSED'", context.exception.args[-1])

    def test_cannot_replay_same_tx(self):
        with self.assertRaises(MichelsonRuntimeError) as context:
            self.minter_contract.mint_erc20(
                mint_erc20_parameters(block_hash=b'aTx', log_index=3)).interpret(
                storage=valid_storage(mints={(b'aTx', 3): None}),
                sender=quorum_contract)
        self.assertEqual("'TX_ALREADY_MINTED'", context.exception.args[-1])

    def test_saves_tx_id(self):
        block_hash = bytes.fromhex("386bf131803cba7209ff9f43f7be0b1b4112605942d3743dc6285ee400cc8c2d")
        log_index = 5

        res = self.minter_contract.mint_erc20(
            mint_erc20_parameters(block_hash=block_hash, log_index=log_index)).interpret(
            storage=valid_storage(),
            sender=quorum_contract)

        self.assertIn((block_hash, log_index), res.storage["assets"]["mints"])

    def test_calls_fa2_mint_for_user_and_collect_fees(self):
        amount = 1 * 10 ** 16

        res = self.minter_contract.mint_erc20(
            mint_erc20_parameters(amount=amount)).interpret(
            storage=valid_storage(fees_ratio=1),
            self_address=self_address,
            sender=quorum_contract)

        self.assertEqual(1, len(res.operations))
        user_mint = res.operations[0]
        self.assertEqual('0', user_mint['amount'])
        self.assertEqual(f'{token_contract}', user_mint['destination'])
        self.assertEqual('tokens', user_mint['parameters']['entrypoint'])
        collected_fees = int(0.0001 * 10 ** 16)
        self.assertEqual(michelson_to_micheline(
            f'( Right {{ Pair "{user}"  1 {int(0.9999 * 10 ** 16)}  ; Pair "{self_address}" 1 {collected_fees} }})'),
            user_mint['parameters']['value'])
        self.assertEqual(collected_fees, self._tokens_of(res.storage, self_address, (token_contract, 1)))

    def test_should_stack_fees(self):
        amount = 1 * 10 ** 16
        storage = valid_storage(fees_ratio=1)
        with_token_to_distribute((token_contract, 1), 100, storage)

        res = self.minter_contract.mint_erc20(
            mint_erc20_parameters(amount=amount)).interpret(
            storage=storage,
            self_address=self_address,
            sender=quorum_contract)

        collected_fees = int(0.0001 * 10 ** 16)
        self.assertEqual(collected_fees + 100, self._tokens_of(res.storage, self_address, (token_contract, 1)))

    def test_generates_only_one_mint_if_fees_to_low(self):
        amount = 1

        res = self.minter_contract.mint_erc20(
            mint_erc20_parameters(amount=amount)).interpret(
            storage=valid_storage(fees_ratio=1),
            sender=quorum_contract)

        self.assertEqual(1, len(res.operations))
        user_mint = res.operations[0]
        self.assertEqual(michelson_to_micheline(
            f'( Right {{ Pair "{user}" 1 {amount}}})'),
            user_mint['parameters']['value'])


class UnwrapErc20Test(MinterTest):

    def test_cannot_unwrap_if_paused(self):
        with self.assertRaises(MichelsonRuntimeError) as context:
            self.minter_contract.unwrap_erc20(
                unwrap_fungible_parameters()).interpret(
                storage=valid_storage(paused=True),
                sender=user)
        self.assertEqual("'CONTRACT_PAUSED'", context.exception.args[-1])

    def test_rejects_unwrap_with_fees_to_low(self):
        amount = 100
        fees = 1
        with self.assertRaises(MichelsonRuntimeError) as context:
            self.minter_contract.unwrap_erc20(
                unwrap_fungible_parameters(amount=amount, fees=fees)).interpret(
                storage=valid_storage(fees_ratio=200),
                source=user
            )
        self.assertEqual("'FEES_TOO_LOW'", context.exception.args[-1])

    def test_takes_no_fees_if_amount_to_small(self):
        amount = 10
        fees = 0

        res = self.minter_contract.unwrap_erc20(
            unwrap_fungible_parameters(amount=amount, fees=fees)).interpret(
            storage=valid_storage(fees_ratio=200),
            source=user
        )

        self.assertEqual(1, len(res.operations))
        burn_operation = res.operations[0]
        self.assertEqual('0', burn_operation['amount'])
        self.assertEqual(f'{token_contract}', burn_operation['destination'])
        self.assertEqual('tokens', burn_operation['parameters']['entrypoint'])
        self.assertEqual(michelson_to_micheline(f'(Left {{ Pair "{user}" 1 {amount} }})'),
                         burn_operation['parameters']['value'])

    def test_unwrap_amount_for_account_and_distribute_fees(self):
        amount = 100
        fees = 1

        res = self.minter_contract.unwrap_erc20(
            unwrap_fungible_parameters(amount=amount, fees=fees)).interpret(
            storage=valid_storage(fees_ratio=100),
            self_address=self_address,
            source=user
        )

        self.assertEqual(2, len(res.operations))
        burn_operation = res.operations[0]
        self.assertEqual('0', burn_operation['amount'])
        self.assertEqual(f'{token_contract}', burn_operation['destination'])
        self.assertEqual('tokens', burn_operation['parameters']['entrypoint'])
        self.assertEqual(michelson_to_micheline(f'(Left {{ Pair "{user}" 1 {amount + fees} }})'),
                         burn_operation['parameters']['value'])
        mint_operation = res.operations[1]
        self.assertEqual('0', mint_operation['amount'])
        self.assertEqual(f'{token_contract}', mint_operation['destination'])
        self.assertEqual('tokens', mint_operation['parameters']['entrypoint'])
        self.assertEqual(michelson_to_micheline(f'(Right {{ Pair "{self_address}" 1 {fees} }})'),
                         mint_operation['parameters']['value'])
        self.assertEqual(fees, self._tokens_of(res.storage, self_address, (token_contract, 1)))

    def test_should_stack_unwrap_fees(self):
        amount = 100
        fees = 1
        storage = valid_storage(fees_ratio=100)
        stacked_fees = 200
        with_token_to_distribute((token_contract, 1), stacked_fees, storage)

        res = self.minter_contract.unwrap_erc20(
            unwrap_fungible_parameters(amount=amount, fees=fees)).interpret(
            storage=storage,
            self_address=self_address,
            source=user
        )

        self.assertEqual(fees + stacked_fees, self._tokens_of(res.storage, self_address, (token_contract, 1)))


class ERC721Test(MinterTest):

    def test_calls_erc721_mint(self):
        res = self.minter_contract.mint_erc721(mint_erc721_parameters(token_id=5)) \
            .interpret(storage=valid_storage(nft_fees=20), sender=quorum_contract, amount=20, self_address=self_address)

        self.assertEqual(1, len(res.operations))
        user_mint = res.operations[0]
        self.assertEqual('0', user_mint['amount'])
        self.assertEqual(f'{nft_contract}', user_mint['destination'])
        self.assertEqual('tokens', user_mint['parameters']['entrypoint'])
        self.assertEqual(michelson_to_micheline(
            f'( Right {{ Pair "{user}" 5 1 }})'),
            user_mint['parameters']['value'])
        self.assertEqual(20, self._xtz_of(self_address, res.storage))

    def test_should_stack_wrapping_fees(self):
        storage = valid_storage(nft_fees=20)
        stacked_fees = 40
        with_xtz_to_distribute(stacked_fees, storage)

        res = self.minter_contract.mint_erc721(mint_erc721_parameters(token_id=5)) \
            .interpret(storage=storage, sender=quorum_contract, amount=20, self_address=self_address)

        self.assertEqual(stacked_fees + 20, self._xtz_of(self_address, res.storage))

    def test_unwrap_nft(self):
        token_id = 1337
        fees = 10

        res = self.minter_contract.unwrap_erc721(
            unwrap_nft_parameters(token_id=token_id)).interpret(
            storage=valid_storage(nft_fees=fees),
            sender=user,
            amount=10,
            self_address=self_address
        )

        self.assertEqual(1, len(res.operations))
        burn_operation = res.operations[0]
        self.assertEqual('0', burn_operation['amount'])
        self.assertEqual(f'{nft_contract}', burn_operation['destination'])
        self.assertEqual('tokens', burn_operation['parameters']['entrypoint'])
        self.assertEqual(michelson_to_micheline(f'(Left {{ Pair "{user}" 1337 1}})'),
                         burn_operation['parameters']['value'])
        self.assertEqual(10, self._xtz_of(self_address, res.storage))

    def test_should_stack_unwrapping_fees(self):
        token_id = 1337
        fees = 10
        stacked_fees = 50
        storage = valid_storage(nft_fees=fees)
        with_xtz_to_distribute(stacked_fees, storage)

        res = self.minter_contract.unwrap_erc721(
            unwrap_nft_parameters(token_id=token_id)).interpret(
            storage=storage,
            sender=user,
            amount=10,
            self_address=self_address
        )

        self.assertEqual(fees + stacked_fees, self._xtz_of(self_address, res.storage))

    def test_rejects_mint_if_not_signer(self):
        with self.assertRaises(MichelsonRuntimeError) as context:
            self.minter_contract.mint_erc721(mint_erc721_parameters(token_id=5)).interpret(
                storage=valid_storage(),
                sender=user)

        self.assertEqual("'NOT_SIGNER'", context.exception.args[-1])

    def test_cant_mint_if_paused(self):
        with self.assertRaises(MichelsonRuntimeError) as context:
            self.minter_contract.mint_erc721(mint_erc721_parameters(token_id=5)).interpret(
                storage=valid_storage(paused=True),
                sender=quorum_contract)

        self.assertEqual("'CONTRACT_PAUSED'", context.exception.args[-1])

    def test_cannot_replay_same_tx(self):
        with self.assertRaises(MichelsonRuntimeError) as context:
            self.minter_contract.mint_erc721(
                mint_erc721_parameters(token_id=5, block_hash=b'aTx', log_index=3)).interpret(
                storage=valid_storage(mints={(b'aTx', 3): None}),
                sender=quorum_contract)
        self.assertEqual("'TX_ALREADY_MINTED'", context.exception.args[-1])

    def test_saves_tx_id(self):
        block_hash = bytes.fromhex("386bf131803cba7209ff9f43f7be0b1b4112605942d3743dc6285ee400cc8c2d")
        log_index = 5

        res = self.minter_contract.mint_erc721(
            mint_erc721_parameters(block_hash=block_hash, log_index=log_index)).interpret(
            storage=valid_storage(), amount=3,
            sender=quorum_contract)

        self.assertIn((block_hash, log_index), res.storage["assets"]["mints"])


class GovernanceTest(MinterTest):

    def test_should_accept_only_oracle(self):
        with self.assertRaises(MichelsonRuntimeError) as context:
            self.minter_contract.set_erc20_wrapping_fees(10).interpret(
                storage=valid_storage(),
                source=user
            )
        self.assertEqual("'NOT_GOVERNANCE'", context.exception.args[-1])

    def test_set_wrapping_fees(self):
        res = self.minter_contract.set_erc20_wrapping_fees(10).interpret(
            storage=valid_storage(),
            source=governance
        )

        self.assertEqual(10, res.storage['governance']['erc20_wrapping_fees'])

    def test_set_unwrapping_fees(self):
        res = self.minter_contract.set_erc20_unwrapping_fees(10).interpret(
            storage=valid_storage(),
            source=governance
        )

        self.assertEqual(10, res.storage['governance']['erc20_unwrapping_fees'])

    def test_set_erc721_wrapping_fees(self):
        res = self.minter_contract.set_erc721_wrapping_fees(10).interpret(
            storage=valid_storage(),
            source=governance
        )

        self.assertEqual(10, res.storage['governance']['erc721_wrapping_fees'])

    def test_set_erc721_unwrapping_fees(self):
        res = self.minter_contract.set_erc721_unwrapping_fees(10).interpret(
            storage=valid_storage(),
            source=governance
        )

        self.assertEqual(10, res.storage['governance']['erc721_unwrapping_fees'])

    def test_set_governance(self):
        res = self.minter_contract.set_governance(user).interpret(
            storage=valid_storage(),
            source=governance
        )

        self.assertEqual(user, res.storage['governance']['contract'])

    def test_should_set_fees_share(self):
        storage = valid_storage()

        res = self.minter_contract.set_fees_share({"dev_pool": 20, "staking": 55, "signers": 25}) \
            .interpret(storage=storage,
                       sender=governance)

        self.assertEqual(20, res.storage["governance"]["fees_share"]["dev_pool"])
        self.assertEqual(55, res.storage["governance"]["fees_share"]["staking"])
        self.assertEqual(25, res.storage["governance"]["fees_share"]["signers"])

    def test_should_reject_fees_share_when_sum_is_not_100(self):
        storage = valid_storage()
        with self.assertRaises(MichelsonRuntimeError) as context:
            self.minter_contract.set_fees_share({"dev_pool": 19, "staking": 55, "signers": 25}).interpret(
                storage=storage,
                sender=governance)
        self.assertEqual("'BAD_FEES_RATIO'", context.exception.args[-1])

    def test_set_dev_pool(self):
        result = self.minter_contract.set_dev_pool(user).interpret(storage=valid_storage(), sender=governance)

        self.assertEqual(user, result.storage['governance']['dev_pool'])

    def test_set_staking(self):
        result = self.minter_contract.set_staking(user).interpret(storage=valid_storage(), sender=governance)

        self.assertEqual(user, result.storage['governance']['staking'])


class AdminTest(MinterTest):

    def test_changes_administrator(self):
        res = self.minter_contract.set_administrator(other_party).interpret(storage=valid_storage(),
                                                                            sender=admin)
        self.assertEqual(res.storage['admin']['administrator'], admin)
        self.assertEqual(res.storage['admin']['pending_admin'], other_party)

    def test_only_admin_changes_administrator(self):
        with self.assertRaises(MichelsonRuntimeError) as context:
            self.minter_contract.set_administrator(other_party).interpret(storage=valid_storage(),
                                                                          sender=user)
        self.assertEqual("'NOT_ADMIN'", context.exception.args[-1])

    def test_new_admin_can_confirm(self):
        storage = valid_storage()
        storage['admin']['pending_admin'] = other_party

        res = self.minter_contract.confirm_minter_admin().interpret(storage=storage,
                                                                    sender=other_party)

        self.assertEqual(res.storage['admin']['administrator'], other_party)
        self.assertEqual(res.storage['admin']['pending_admin'], None)

    def test_only_pending_admin_can_confirm(self):
        with self.assertRaises(MichelsonRuntimeError) as context:
            storage = valid_storage()
            storage['admin']['pending_admin'] = other_party

            self.minter_contract.confirm_minter_admin().interpret(storage=storage,
                                                                  sender=admin)
        self.assertEqual("'NOT_A_PENDING_ADMIN'", context.exception.args[-1])

    def test_cannot_confirm_if_no_pending_admin(self):
        with self.assertRaises(MichelsonRuntimeError) as context:
            storage = valid_storage()

            self.minter_contract.confirm_minter_admin().interpret(storage=storage,
                                                                  sender=admin)
        self.assertEqual("'NO_PENDING_ADMIN'", context.exception.args[-1])

    def test_can_pause(self):
        res = self.minter_contract.pause_contract(True) \
            .interpret(storage=valid_storage(), source=admin)

        self.assertEqual(True, res.storage['admin']['paused'])

    def test_only_admin_can_pause(self):
        with self.assertRaises(MichelsonRuntimeError) as context:
            self.minter_contract.pause_contract(True) \
                .interpret(storage=valid_storage(), source=user)
        self.assertEqual("'NOT_ADMIN'", context.exception.args[-1])

    def test_changes_oracle(self):
        res = self.minter_contract.set_oracle(other_party).interpret(storage=valid_storage(),
                                                                     sender=admin)
        self.assertEqual(other_party, res.storage['admin']['oracle'])

    def test_only_admin_can_change_oracle(self):
        with self.assertRaises(MichelsonRuntimeError) as context:
            self.minter_contract.set_oracle(other_party) \
                .interpret(storage=valid_storage(), source=user)
        self.assertEqual("'NOT_ADMIN'", context.exception.args[-1])

    def test_changes_signer(self):
        res = self.minter_contract.set_signer(other_party).interpret(storage=valid_storage(), sender=admin)

        self.assertEqual(other_party, res.storage['admin']['signer'])

    def test_only_admin_can_change_signer(self):
        with self.assertRaises(MichelsonRuntimeError) as context:
            self.minter_contract.set_signer(other_party) \
                .interpret(storage=valid_storage(), source=user)
        self.assertEqual("'NOT_ADMIN'", context.exception.args[-1])


class TokenTest(MinterTest):

    def test_rejects_xtz_transfer(self):
        with self.assertRaises(MichelsonRuntimeError) as context:
            self.minter_contract.set_administrator(other_party).interpret(storage=valid_storage(),
                                                                          sender=admin,
                                                                          amount=10
                                                                          )
        self.assertEqual("'FORBIDDEN_XTZ'", context.exception.args[-1])

    def test_only_signer_can_add_token(self):
        with self.assertRaises(MichelsonRuntimeError) as context:
            self.minter_contract.add_erc20({
                "eth_contract": b"ethContract",
                "token_address": ("KT19RiH4xg7vjgxeBeFU5eBmhS5W9bcpDwL6", 2)
            }).interpret(
                storage=valid_storage(tokens={}),
                source=user
            )
        self.assertEqual("'NOT_SIGNER'", context.exception.args[-1])

    def test_add_fungible_token(self):
        res = self.minter_contract.add_erc20({
            "eth_contract": b"ethContract",
            "token_address": ("KT19RiH4xg7vjgxeBeFU5eBmhS5W9bcpDwL6", 2)
        }).interpret(
            storage=valid_storage(tokens={}),
            source=quorum_contract
        )

        self.assertIn(b'ethContract', res.storage['assets']['erc20_tokens'])
        self.assertEqual(("KT19RiH4xg7vjgxeBeFU5eBmhS5W9bcpDwL6", 2),
                         res.storage['assets']['erc20_tokens'][b'ethContract'])
        self.assertEqual(0, len(res.operations))

    def test_add_nft(self):
        res = self.minter_contract.add_erc721({
            "eth_contract": b"ethContract",
            "token_contract": "KT19RiH4xg7vjgxeBeFU5eBmhS5W9bcpDwL6"
        }).interpret(
            storage=valid_storage(tokens={}),
            source=quorum_contract
        )

        self.assertIn(b'ethContract', res.storage['assets']['erc721_tokens'])
        self.assertEqual("KT19RiH4xg7vjgxeBeFU5eBmhS5W9bcpDwL6",
                         res.storage['assets']['erc721_tokens'][b'ethContract'])
        self.assertEqual(0, len(res.operations))


class FeesDistributionTest(MinterTest):

    def test_should_be_called_by_oracle_only(self):
        with self.assertRaises(MichelsonRuntimeError) as context:
            self.minter_contract.distribute_xtz([]).interpret(storage=valid_storage(),
                                                              sender=other_party,
                                                              self_address=self_address)
        self.assertEqual("'NOT_ORACLE'", context.exception.args[-1])

    def test_distribute_xtz_to_dev(self):
        initial_storage = valid_storage()
        with_xtz_to_distribute(100, initial_storage)
        initial_storage["fees"]["xtz"][dev_pool] = 50

        res = self.minter_contract.distribute_xtz([]).interpret(storage=initial_storage,
                                                                sender=oracle,
                                                                self_address=self_address)

        self.assertEqual(60, self._xtz_of(dev_pool, res.storage))

    def test_distribute_xtz_to_staking(self):
        initial_storage = valid_storage()
        with_xtz_to_distribute(100, initial_storage)

        res = self.minter_contract.distribute_xtz([]).interpret(storage=initial_storage,
                                                                sender=oracle,
                                                                self_address=self_address)

        self.assertEqual(40, self._xtz_of(staking_pool, res.storage))

    def test_distribute_xtz_to_signer_default_payment_address(self):
        initial_storage = valid_storage()
        with_xtz_to_distribute(100, initial_storage)

        res = self.minter_contract.distribute_xtz([signer_1_key]).interpret(storage=initial_storage,
                                                                            sender=oracle,
                                                                            self_address=self_address)

        self.assertEqual(50, self._xtz_of(signer_1_key, res.storage))
        self.assertEqual(0, self._xtz_of(self_address, res.storage))

    def test_distribute_xtz_to_signer_registered_payment_address(self):
        signer_1_payment_address = Key.generate(export=False).public_key_hash()
        initial_storage = valid_storage()
        with_xtz_to_distribute(100, initial_storage)
        initial_storage["fees"]["signers"][signer_1_key] = signer_1_payment_address

        res = self.minter_contract.distribute_xtz([signer_1_key]).interpret(storage=initial_storage,
                                                                            sender=oracle,
                                                                            self_address=self_address)

        self.assertEqual(50, self._xtz_of(signer_1_payment_address, res.storage))

    def test_distribute_xtz_to_several_signers_and_keeps_remaining_to_distribute(self):
        initial_storage = valid_storage()
        with_xtz_to_distribute(100, initial_storage)

        res = self.minter_contract.distribute_xtz([signer_1_key, signer_2_key, signer_3_key]).interpret(
            storage=initial_storage,
            sender=oracle,
            self_address=self_address)

        self.assertEqual(16, self._xtz_of(signer_1_key, res.storage))
        self.assertEqual(16, self._xtz_of(signer_2_key, res.storage))
        self.assertEqual(16, self._xtz_of(signer_3_key, res.storage))
        self.assertEqual(2, self._xtz_of(self_address, res.storage))

    def test_distribute_tokens_to_dev_pool(self):
        initial_storage = valid_storage()
        token_address = (token_contract, 0)
        with_token_to_distribute(token_address, 100, initial_storage)
        initial_storage["fees"]["tokens"][(dev_pool, token_contract, 0)] = 10

        res = self.minter_contract.distribute_tokens([], [token_address]).interpret(storage=initial_storage,
                                                                                    sender=oracle,
                                                                                    self_address=self_address)

        self.assertEqual(50, self._tokens_of(res.storage, self_address, token_address))
        self.assertEqual(20, self._tokens_of(res.storage, dev_pool, token_address))

    def test_distribute_tokens_to_staking(self):
        initial_storage = valid_storage()
        token_address = (token_contract, 0)
        with_token_to_distribute(token_address, 100, initial_storage)
        initial_storage["fees"]["tokens"][(staking_pool, token_contract, 0)] = 40

        res = self.minter_contract.distribute_tokens([], [token_address]).interpret(storage=initial_storage,
                                                                                    sender=oracle,
                                                                                    self_address=self_address)

        self.assertEqual(80, self._tokens_of(res.storage, staking_pool, token_address))

    def test_distribute_tokens_to_signer(self):
        initial_storage = valid_storage()
        token_address = (token_contract, 0)
        with_token_to_distribute(token_address, 100, initial_storage)
        initial_storage["fees"]["tokens"][(signer_1_key, token_contract, 0)] = 40

        res = self.minter_contract.distribute_tokens([signer_1_key], [token_address]).interpret(storage=initial_storage,
                                                                                                sender=oracle,
                                                                                                self_address=self_address)

        self.assertEqual(90, self._tokens_of(res.storage, signer_1_key, token_address))
        self.assertEqual(0, self._tokens_of(res.storage, self_address, token_address))

    def test_distribute_several_tokens(self):
        initial_storage = valid_storage()
        first_token = (token_contract, 0)
        second_token = (token_contract, 1)
        with_token_to_distribute(first_token, 100, initial_storage)
        with_token_to_distribute(second_token, 200, initial_storage)

        res = self.minter_contract.distribute_tokens([], [first_token, second_token]).interpret(storage=initial_storage,
                                                                                                self_address=self_address,
                                                                                                sender=oracle)

        self.assertEqual(10, self._tokens_of(res.storage, dev_pool, first_token))
        self.assertEqual(20, self._tokens_of(res.storage, dev_pool, second_token))


class FeesClaimTest(MinterTest):

    def test_should_withdraw_some_xtz(self):
        storage = valid_storage()
        with_xtz_balance(signer_1_key, 100, storage)

        res = self.minter_contract.withdraw_xtz(40).interpret(storage=storage, sender=signer_1_key)

        self.assertEqual(1, len(res.operations))
        self.assertEqual(signer_1_key, res.operations[0]['destination'])
        self.assertEqual("40", res.operations[0]['amount'])
        self.assertEqual('default', res.operations[0]['parameters']['entrypoint'])
        self.assertEqual(60, self._xtz_of(signer_1_key, res.storage))

    def test_should_fail_if_not_enough_xtz(self):
        with self.assertRaises(MichelsonRuntimeError) as context:
            storage = valid_storage()
            with_xtz_balance(signer_1_key, 100, storage)

            self.minter_contract.withdraw_xtz(101).interpret(storage=storage, sender=signer_1_key)
        self.assertEqual("'NOT_ENOUGH_XTZ'", context.exception.args[-1])

    def test_should_withdraw_all_xtz(self):
        storage = valid_storage()
        with_xtz_balance(signer_1_key, 100, storage)

        res = self.minter_contract.withdraw_all_xtz().interpret(storage=storage, sender=signer_1_key)

        self.assertEqual(1, len(res.operations))
        self.assertEqual(signer_1_key, res.operations[0]['destination'])
        self.assertEqual("100", res.operations[0]['amount'])
        self.assertEqual('default', res.operations[0]['parameters']['entrypoint'])
        self.assertEqual(None, self._xtz_of(signer_1_key, res.storage))

    def test_should_emit_no_xtz_transfer_if_nothing(self):
        storage = valid_storage()
        with_xtz_balance(signer_1_key, 0, storage)

        res = self.minter_contract.withdraw_all_xtz().interpret(storage=storage, sender=signer_1_key)

        self.assertEqual(0, len(res.operations))

    def test_should_transfer_all_tokens_from_contract(self):
        storage = valid_storage()
        first_token_address = (token_contract, 0)
        second_token_address = (token_contract, 1)
        with_token_balance(signer_1_key, first_token_address, 100, storage)
        with_token_balance(signer_1_key, second_token_address, 200, storage)

        res = self.minter_contract.withdraw_all_tokens(token_contract, [0, 1]).interpret(storage=storage,
                                                                                         sender=signer_1_key,
                                                                                         self_address=self_address)

        self.assertEqual(1, len(res.operations))
        transfer = res.operations[0]
        self.assertEqual(token_contract, transfer['destination'])
        self.assertEqual("0", transfer['amount'])
        self.assertEqual('transfer', transfer['parameters']['entrypoint'])
        self.assertEqual(michelson_to_micheline(
            f'{{ Pair "{self_address}" {{ Pair "{signer_1_key}" 1 200 ; Pair "{signer_1_key}" 0 100 }} }}'),
            transfer['parameters']['value'])

        self.assertEqual(None, self._tokens_of(res.storage, signer_1_key, first_token_address))
        self.assertEqual(None, self._tokens_of(res.storage, signer_1_key, second_token_address))

    def test_should_transfer_token(self):
        storage = valid_storage()
        token_address = (token_contract, 0)
        with_token_balance(signer_1_key, token_address, 100, storage)

        res = self.minter_contract.withdraw_token(token_contract, 0, 40).interpret(storage=storage,
                                                                                   sender=signer_1_key,
                                                                                   self_address=self_address)

        self.assertEqual(1, len(res.operations))
        self.assertEqual(token_contract, res.operations[0]['destination'])
        self.assertEqual("0", res.operations[0]['amount'])
        self.assertEqual('transfer', res.operations[0]['parameters']['entrypoint'])
        self.assertEqual(michelson_to_micheline(f'{{ Pair "{self_address}" {{ Pair "{signer_1_key}" 0 40 }} }}'),
                         res.operations[0]['parameters']['value'])

        t = self._tokens_of(res.storage, signer_1_key, token_address)
        self.assertEqual(60, t)

    def test_should_fail_if_not_enough_token(self):
        with self.assertRaises(MichelsonRuntimeError) as context:
            storage = valid_storage()
            token_address = (token_contract, 0)
            with_token_balance(signer_1_key, token_address, 100, storage)

            self.minter_contract.withdraw_token(token_contract, 0, 101).interpret(storage=storage,
                                                                                  sender=signer_1_key,
                                                                                  self_address=self_address)

        self.assertEqual("'NOT_ENOUGH_BALANCE'", context.exception.args[-1])


class QuorumOpsTest(MinterTest):

    def test_set_signer_payment_address(self):
        payment_address = Key.generate(export=False).public_key_hash()
        storage = valid_storage()

        res = self.minter_contract.signer_ops(signer_1_key, payment_address) \
            .interpret(storage=storage,
                       sender=quorum_contract)

        self.assertEqual(payment_address, res.storage["fees"]["signers"][signer_1_key])

    def test_should_only_be_called_by_quorum_contract(self):
        with self.assertRaises(MichelsonRuntimeError) as context:
            payment_address = Key.generate(export=False).public_key_hash()
            self.minter_contract.signer_ops(signer_1_key, payment_address) \
                .interpret(storage=(valid_storage()),
                           sender=other_party)

        self.assertEqual("'NOT_SIGNER'", context.exception.args[-1])


def with_xtz_to_distribute(amount, initial_storage):
    with_xtz_balance(self_address, amount, initial_storage)


def with_xtz_balance(address, amount, initial_storage):
    initial_storage["fees"]["xtz"][address] = amount


def with_token_to_distribute(token_address, amount, initial_storage):
    with_token_balance(self_address, token_address, amount, initial_storage)


def with_token_balance(address, token_address, amount, initial_storage):
    initial_storage["fees"]["tokens"][(address,) + token_address] = amount


def valid_storage(mints=None, fees_ratio=0, nft_fees=1, tokens=None, paused=False):
    if mints is None:
        mints = {}
    if tokens is None:
        tokens = {b'BOB': [token_contract, 1]}
    return {
        "admin": {
            "administrator": admin,
            "signer": quorum_contract,
            "oracle": oracle,
            "paused": paused,
            "pending_admin": None
        },
        "assets": {
            "erc20_tokens": tokens,
            "erc721_tokens": {b'NFT': nft_contract},
            "mints": mints
        },
        "governance": {
            "contract": governance,
            "staking": staking_pool,
            "dev_pool": dev_pool,
            "erc20_wrapping_fees": fees_ratio,
            "erc20_unwrapping_fees": fees_ratio,
            "erc721_wrapping_fees": nft_fees,
            "erc721_unwrapping_fees": nft_fees,
            "fees_share": {
                "dev_pool": 10,
                "staking": 40,
                "signers": 50
            }
        },
        "fees": {
            "signers": {},
            "tokens": {},
            "xtz": {}
        },
        "metadata": {}
    }


def mint_erc20_parameters(
        block_hash=bytes.fromhex("e1286c8cdafc9462534bce697cf3bf7e718c2241c6d02763e4027b072d371b7c"),
        log_index=1,
        owner=user,
        amount=2):
    return {"erc_20": b'BOB',
            "event_id": {"block_hash": block_hash, "log_index": log_index},
            "owner": owner,
            "amount": amount
            }


def mint_erc721_parameters(block_hash=bytes.fromhex("e1286c8cdafc9462534bce697cf3bf7e718c2241c6d02763e4027b072d371b7c"),
                           log_index=1,
                           owner=user,
                           token_id=2):
    return {"erc_721": b'NFT',
            "event_id": {"block_hash": block_hash, "log_index": log_index},
            "owner": owner,
            "token_id": token_id
            }


def unwrap_fungible_parameters(amount=2, fees=1):
    return {"erc_20": b'BOB',
            "amount": amount,
            "fees": fees,
            "destination": b"ethAddress"
            }


def unwrap_nft_parameters(token_id=2):
    return {"erc_721": b'NFT',
            "token_id": token_id,
            "destination": b"ethAddress"
            }
