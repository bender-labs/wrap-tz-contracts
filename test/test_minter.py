from pathlib import Path
from unittest import TestCase

from pytezos import michelson_to_micheline, MichelsonRuntimeError
from src.ligo import LigoContract

super_admin = 'tz1irF8HUsQp2dLhKNMhteG1qALNU9g3pfdN'
user = 'tz1grSQDByRpnVs7sPtaprNZRp531ZKz6Jmm'
fees_contract = 'tz1et19hnF9qKv6yCbbxjS1QDXB5HVx6PCVk'
token_contract = 'KT1LEzyhXGKfFsczmLJdfW1p8B1XESZjMCvw'
nft_contract = 'KT1X82SpRG97yUYpyiYSWN4oPFYSq46BthCi'
other_party = 'tz3SYyWM9sq9eWTxiA8KHb36SAieVYQPeZZm'



class BenderTest(TestCase):

    @classmethod
    def compile_contract(cls):
        root_dir = Path(__file__).parent.parent / "ligo"
        cls.bender_contract = LigoContract(root_dir / "minter" / "main.mligo", "main").compile_contract()

    @classmethod
    def setUpClass(cls):
        cls.compile_contract()
        cls.maxDiff = None

    def test_rejects_xtz_transfer(self):
        with self.assertRaises(MichelsonRuntimeError) as context:
            self.bender_contract.set_administrator(other_party).interpret(storage=valid_storage(),
                                                                          sender=super_admin,
                                                                          amount=10
                                                                          )
        self.assertEqual("'FORBIDDEN_XTZ'", context.exception.args[-1])

    def test_changes_administrator(self):
        res = self.bender_contract.set_administrator(other_party).interpret(storage=valid_storage(),
                                                                            sender=super_admin)
        self.assertEqual(res.storage['admin']['administrator'], other_party)

    def test_rejects_mint_if_not_signer(self):
        with self.assertRaises(MichelsonRuntimeError) as context:
            self.bender_contract.mint_erc20(mint_erc20_parameters()).interpret(
                storage=valid_storage(),
                sender=user)

        self.assertEqual("'NOT_SIGNER'", context.exception.args[-1])

    def test_cant_mint_if_paused(self):
        with self.assertRaises(MichelsonRuntimeError) as context:
            self.bender_contract.mint_erc20(mint_erc20_parameters()).interpret(
                storage=valid_storage(paused=True),
                sender=super_admin)

        self.assertEqual("'CONTRACT_PAUSED'", context.exception.args[-1])

    def test_calls_fa2_mint_for_user_and_fees_contract(self):
        amount = 1 * 10 ** 16

        res = self.bender_contract.mint_erc20(
            mint_erc20_parameters(amount=amount)).interpret(
            storage=valid_storage(fees_ratio=1),
            sender=super_admin)

        self.assertEqual(1, len(res.operations))
        user_mint = res.operations[0]
        self.assertEqual('0', user_mint['amount'])
        self.assertEqual(f'{token_contract}', user_mint['destination'])
        self.assertEqual('tokens', user_mint['parameters']['entrypoint'])
        self.assertEqual(michelson_to_micheline(
            f'( Right {{ Pair "{user}"  1 {int(0.9999 * 10 ** 16)}  ; Pair "{fees_contract}" 1 {int(0.0001 * 10 ** 16)} }})'),
            user_mint['parameters']['value'])

    def test_calls_erc721_mint(self):
        res = self.bender_contract.mint_erc721(mint_erc721_parameters(token_id=5)) \
            .interpret(storage=valid_storage(nft_fees=20), sender=super_admin, amount=20)

        self.assertEqual(2, len(res.operations))
        user_mint = res.operations[0]
        self.assertEqual('0', user_mint['amount'])
        self.assertEqual(f'{nft_contract}', user_mint['destination'])
        self.assertEqual('tokens', user_mint['parameters']['entrypoint'])
        self.assertEqual(michelson_to_micheline(
            f'( Right {{ Pair "{user}" 5 1 }})'),
            user_mint['parameters']['value'])
        fees = res.operations[1]
        self.assertEqual('20', fees['amount'])
        self.assertEqual(f'{fees_contract}', fees['destination'])
        self.assertEqual('default', fees['parameters']['entrypoint'])
        self.assertEqual(michelson_to_micheline('Unit'),
                         fees['parameters']['value'])

    def test_generates_only_one_mint_if_fees_to_low(self):
        amount = 1

        res = self.bender_contract.mint_erc20(
            mint_erc20_parameters(amount=amount)).interpret(
            storage=valid_storage(fees_ratio=1),
            sender=super_admin)

        self.assertEqual(1, len(res.operations))
        user_mint = res.operations[0]
        self.assertEqual(michelson_to_micheline(
            f'( Right {{ Pair "{user}" 1 {amount}}})'),
            user_mint['parameters']['value'])

    def test_unwrap_amount_for_account_and_distribute_fees(self):
        amount = 100
        fees = 1

        res = self.bender_contract.unwrap_erc20(
            unwrap_fungible_parameters(amount=amount, fees=fees)).interpret(
            storage=valid_storage(fees_ratio=100),
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
        self.assertEqual(michelson_to_micheline(f'(Right {{ Pair "{fees_contract}" 1 {fees} }})'),
                         mint_operation['parameters']['value'])

    def test_rejects_unwrap_with_fees_to_low(self):
        amount = 100
        fees = 1
        with self.assertRaises(MichelsonRuntimeError) as context:
            self.bender_contract.unwrap_erc20(
                unwrap_fungible_parameters(amount=amount, fees=fees)).interpret(
                storage=valid_storage(fees_ratio=200),
                source=user
            )
        self.assertEqual("'FEES_TOO_LOW'", context.exception.args[-1])

    def test_rejects_unwrap_for_small_amount(self):
        amount = 10
        fees = 1
        with self.assertRaises(MichelsonRuntimeError) as context:
            self.bender_contract.unwrap_erc20(
                unwrap_fungible_parameters(amount=amount, fees=fees)).interpret(
                storage=valid_storage(fees_ratio=200),
                source=user
            )
        self.assertEqual("'AMOUNT_TOO_SMALL'", context.exception.args[-1])

    def test_unwrap_nft(self):
        token_id = 1337
        fees = 10

        res = self.bender_contract.unwrap_erc721(
            unwrap_nft_parameters(token_id=token_id)).interpret(
            storage=valid_storage(nft_fees=fees),
            source=user,
            amount=10
        )

        self.assertEqual(2, len(res.operations))
        burn_operation = res.operations[0]
        self.assertEqual('0', burn_operation['amount'])
        self.assertEqual(f'{nft_contract}', burn_operation['destination'])
        self.assertEqual('tokens', burn_operation['parameters']['entrypoint'])
        self.assertEqual(michelson_to_micheline(f'(Left {{ Pair "{user}" 1337 1}})'),
                         burn_operation['parameters']['value'])
        fees_operation = res.operations[1]
        self.assertEqual('10', fees_operation['amount'])
        self.assertEqual(f'{fees_contract}', fees_operation['destination'])
        self.assertEqual('default', fees_operation['parameters']['entrypoint'])
        self.assertEqual(michelson_to_micheline('Unit'),
                         fees_operation['parameters']['value'])

    def test_saves_tx_id(self):
        block_hash = bytes.fromhex("386bf131803cba7209ff9f43f7be0b1b4112605942d3743dc6285ee400cc8c2d")
        log_index = 5

        res = self.bender_contract.mint_erc20(
            mint_erc20_parameters(block_hash=block_hash, log_index=log_index)).interpret(
            storage=valid_storage(),
            sender=super_admin)

        self.assertIn((block_hash, log_index), res.storage["assets"]["mints"])

    def test_cannot_replay_same_tx(self):
        with self.assertRaises(MichelsonRuntimeError) as context:
            self.bender_contract.mint_erc20(
                mint_erc20_parameters(block_hash=b'aTx', log_index=3)).interpret(
                storage=valid_storage(mints={(b'aTx', 3): None}),
                sender=super_admin)
        self.assertEqual("'TX_ALREADY_MINTED'", context.exception.args[-1])

    def test_cannot_unwrap_if_paused(self):
        with self.assertRaises(MichelsonRuntimeError) as context:
            self.bender_contract.unwrap_erc20(
                unwrap_fungible_parameters()).interpret(
                storage=valid_storage(paused=True),
                sender=super_admin)
        self.assertEqual("'CONTRACT_PAUSED'", context.exception.args[-1])

    def test_set_wrapping_fees(self):
        res = self.bender_contract.set_erc20_wrapping_fees(10).interpret(
            storage=valid_storage(),
            source=super_admin
        )

        self.assertEqual(10, res.storage['governance']['erc20_wrapping_fees'])

    def test_set_unwrapping_fees(self):
        res = self.bender_contract.set_erc20_unwrapping_fees(10).interpret(
            storage=valid_storage(),
            source=super_admin
        )

        self.assertEqual(10, res.storage['governance']['erc20_unwrapping_fees'])

    def test_set_governance(self):
        res = self.bender_contract.set_governance(user).interpret(
            storage=valid_storage(),
            source=super_admin
        )

        self.assertEqual(user, res.storage['governance']['contract'])

    def test_set_fees_contract(self):
        res = self.bender_contract.set_fees_contract(user).interpret(
            storage=valid_storage(),
            source=super_admin
        )

        self.assertEqual(user, res.storage['governance']['fees_contract'])

    def test_add_fungible_token(self):
        res = self.bender_contract.add_erc20({
            "eth_contract": b"ethContract",
            "token_address": ["KT19RiH4xg7vjgxeBeFU5eBmhS5W9bcpDwL6", 2]
        }).interpret(
            storage=valid_storage(tokens={}),
            source=super_admin
        )

        self.assertIn(b'ethContract', res.storage['assets']['erc20_tokens'])
        self.assertEqual(("KT19RiH4xg7vjgxeBeFU5eBmhS5W9bcpDwL6", 2),
                         res.storage['assets']['erc20_tokens'][b'ethContract'])
        self.assertEqual(0, len(res.operations))

    def test_add_nft(self):
        res = self.bender_contract.add_erc721({
            "eth_contract": b"ethContract",
            "token_contract": "KT19RiH4xg7vjgxeBeFU5eBmhS5W9bcpDwL6"
        }).interpret(
            storage=valid_storage(tokens={}),
            source=super_admin
        )

        self.assertIn(b'ethContract', res.storage['assets']['erc721_tokens'])
        self.assertEqual("KT19RiH4xg7vjgxeBeFU5eBmhS5W9bcpDwL6",
                         res.storage['assets']['erc721_tokens'][b'ethContract'])
        self.assertEqual(0, len(res.operations))

    def test_can_pause(self):
        res = self.bender_contract.pause_contract(True) \
            .interpret(storage=valid_storage(), source=super_admin)

        self.assertEqual(True, res.storage['admin']['paused'])

    def test_confirm_fa2_admin(self):
        res = self.bender_contract.confirm_tokens_administrator([token_contract]).interpret(storage=valid_storage(),
                                                                                            source=super_admin)

        self.assertEqual(1, len(res.operations))
        op = res.operations[0]
        self.assertEqual(token_contract, op["destination"])
        self.assertEqual("admin", op["parameters"]["entrypoint"])
        self.assertEqual(michelson_to_micheline('(Left (Left Unit))')
                         , op["parameters"]["value"])

    def test_pause_token(self):
        res = self.bender_contract.pause_tokens([{"contract": token_contract, "tokens": [1], "paused": True}]) \
            .interpret(storage=valid_storage(), source=super_admin)

        self.assertEqual(1, len(res.operations))
        op_fungible = res.operations[0]
        self.assertEqual(token_contract, op_fungible["destination"])
        self.assertEqual("admin", op_fungible["parameters"]["entrypoint"])
        self.assertEqual(michelson_to_micheline('(Left (Right {  Pair 1 True } ))'),
                         op_fungible["parameters"]["value"])

    def test_change_token_admin(self):
        res = self.bender_contract.change_tokens_administrator(user, [token_contract, nft_contract]) \
            .interpret(storage=valid_storage(), source=super_admin)

        self.assertEqual(2, len(res.operations))
        op = res.operations[0]
        self.assertEqual(token_contract, op["destination"])
        self.assertEqual("admin", op["parameters"]["entrypoint"])
        self.assertEqual(michelson_to_micheline(f'(Right "{user}")'),
                         op["parameters"]["value"])
        op = res.operations[1]
        self.assertEqual(nft_contract, op["destination"])
        self.assertEqual("admin", op["parameters"]["entrypoint"])
        self.assertEqual(michelson_to_micheline(f'(Right "{user}")'),
                         op["parameters"]["value"])


def valid_storage(mints=None, fees_ratio=0, nft_fees=1, tokens=None, paused=False):
    if mints is None:
        mints = {}
    if tokens is None:
        tokens = {b'BOB': [token_contract, 1]}
    return {
        "admin": {
            "administrator": super_admin,
            "signer": super_admin,
            "paused": paused
        },
        "assets": {
            "erc20_tokens": tokens,
            "erc721_tokens": {b'NFT': nft_contract},
            "mints": mints
        },
        "governance": {
            "contract": super_admin,
            "fees_contract": fees_contract,
            "erc20_wrapping_fees": fees_ratio,
            "erc20_unwrapping_fees": fees_ratio,
            "erc721_wrapping_fees": nft_fees,
            "erc721_unwrapping_fees": nft_fees
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
