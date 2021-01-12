from unittest import TestCase

from pytezos import michelson
from pytezos.repl.parser import MichelsonRuntimeError
from src.ligo import LigoContract

super_admin = 'tz1irF8HUsQp2dLhKNMhteG1qALNU9g3pfdN'
user = 'tz1grSQDByRpnVs7sPtaprNZRp531ZKz6Jmm'
fees_contract = 'tz1et19hnF9qKv6yCbbxjS1QDXB5HVx6PCVk'
token_contract = 'KT1LEzyhXGKfFsczmLJdfW1p8B1XESZjMCvw'
other_party = 'tz3SYyWM9sq9eWTxiA8KHb36SAieVYQPeZZm'


class BenderTest(TestCase):

    @classmethod
    def compile_contract(cls):
        cls.bender_contract = LigoContract("../ligo/minter/main.religo", "main").compile_contract()

    @classmethod
    def setUpClass(cls):
        cls.compile_contract()
        cls.maxDiff = None

    def test_changes_administrator(self):
        res = self.bender_contract.set_administrator(other_party).interpret(storage=valid_storage(),
                                                                            sender=super_admin)
        self.assertEquals(res.storage['admin']['administrator'], other_party)

    def test_rejects_mint_if_not_signer(self):
        with self.assertRaises(MichelsonRuntimeError) as context:
            self.bender_contract.mint_token(mint_parameters()).interpret(
                storage=valid_storage(),
                sender=user)

        self.assertEquals("NOT_SIGNER", context.exception.message)

    def test_cant_mint_if_paused(self):
        with self.assertRaises(MichelsonRuntimeError) as context:
            self.bender_contract.mint_token(mint_parameters()).interpret(
                storage=valid_storage(paused=True),
                sender=super_admin)

        self.assertEquals("CONTRACT_PAUSED", context.exception.message)

    def test_calls_fa2_mint_for_user_and_fees_contract(self):
        amount = 1 * 10 ** 16

        res = self.bender_contract.mint_token(
            mint_parameters(amount=amount)).interpret(
            storage=valid_storage(fees_ratio=1),
            sender=super_admin)

        self.assertEquals(1, len(res.operations))
        user_mint = res.operations[0]
        self.assertEquals('0', user_mint['amount'])
        self.assertEquals(f'{token_contract}%tokens', user_mint['destination'])
        self.assertEquals('tokens', user_mint['parameters']['entrypoint'])
        self.assertEquals(michelson.converter.convert(
            f'( Right {{ Pair "{user}" (Pair 1 {int(0.9999 * 10 ** 16)} )  ; Pair "{fees_contract}" (Pair 1 {int(0.0001 * 10 ** 16)} )}})'),
            user_mint['parameters']['value'])

    def test_generates_only_one_mint_if_fees_to_low(self):
        amount = 1

        res = self.bender_contract.mint_token(
            mint_parameters(amount=amount)).interpret(
            storage=valid_storage(fees_ratio=1),
            sender=super_admin)

        self.assertEquals(1, len(res.operations))
        user_mint = res.operations[0]
        self.assertEquals(michelson.converter.convert(
            f'( Right {{ Pair "{user}" (Pair 1 {amount} )}})'),
            user_mint['parameters']['value'])

    def test_unwrap_amount_for_account_and_distribute_fees(self):
        amount = 100
        fees = 1

        res = self.bender_contract.unwrap(
            unwrap_parameters(amount=amount, fees=fees)).interpret(
            storage=valid_storage(fees_ratio=100),
            source=user
        )

        self.assertEqual(2, len(res.operations))
        burn_operation = res.operations[0]
        self.assertEqual('0', burn_operation['amount'])
        self.assertEqual(f'{token_contract}%tokens', burn_operation['destination'])
        self.assertEqual('tokens', burn_operation['parameters']['entrypoint'])
        self.assertEqual(michelson.converter.convert(f'(Left (Left {{ Pair "{user}" (Pair 1 {amount + fees} )}}))'),
                         burn_operation['parameters']['value'])
        mint_operation = res.operations[1]
        self.assertEqual('0', mint_operation['amount'])
        self.assertEqual(f'{token_contract}%tokens', mint_operation['destination'])
        self.assertEqual('tokens', mint_operation['parameters']['entrypoint'])
        self.assertEqual(michelson.converter.convert(f'(Right {{ Pair "{fees_contract}" (Pair 1 {fees} )}})'),
                         mint_operation['parameters']['value'])

    def test_rejects_unwrap_with_fees_to_low(self):
        amount = 100
        fees = 1
        with self.assertRaises(MichelsonRuntimeError) as context:
            self.bender_contract.unwrap(
                unwrap_parameters(amount=amount, fees=fees)).interpret(
                storage=valid_storage(fees_ratio=200),
                source=user
            )
        self.assertEqual("FEES_TOO_LOW", context.exception.message)

    def test_rejects_unwrap_for_small_amount(self):
        amount = 10
        fees = 1
        with self.assertRaises(MichelsonRuntimeError) as context:
            self.bender_contract.unwrap(
                unwrap_parameters(amount=amount, fees=fees)).interpret(
                storage=valid_storage(fees_ratio=200),
                source=user
            )
        self.assertEqual("AMOUNT_TOO_SMALL", context.exception.message)

    def test_saves_tx_id(self):
        tx_id = bytes.fromhex("386bf131803cba7209ff9f43f7be0b1b4112605942d3743dc6285ee400cc8c2d")

        res = self.bender_contract.mint_token(
            mint_parameters(tx_id=tx_id)).interpret(
            storage=valid_storage(),
            sender=super_admin)

        self.assertDictEqual({tx_id.hex(): None}, res.big_map_diff['assets/mints'])

    def test_cannot_replay_same_tx(self):
        with self.assertRaises(MichelsonRuntimeError) as context:
            self.bender_contract.mint_token(
                mint_parameters(tx_id=b'aTx')).interpret(
                storage=valid_storage(mints={b'aTx': None}),
                sender=super_admin)
        self.assertEquals("TX_ALREADY_MINTED", context.exception.message)

    def test_cannot_unwrap_if_paused(self):
        with self.assertRaises(MichelsonRuntimeError) as context:
            self.bender_contract.unwrap(
                unwrap_parameters()).interpret(
                storage=valid_storage(paused=True),
                sender=super_admin)
        self.assertEquals("CONTRACT_PAUSED", context.exception.message)

    def test_set_wrapping_fees(self):
        res = self.bender_contract.set_wrapping_fees(10).interpret(
            storage=valid_storage(),
            source=super_admin
        )

        self.assertEquals(10, res.storage['governance']['wrapping_fees'])

    def test_set_unwrapping_fees(self):
        res = self.bender_contract.set_unwrapping_fees(10).interpret(
            storage=valid_storage(),
            source=super_admin
        )

        self.assertEquals(10, res.storage['governance']['unwrapping_fees'])

    def test_set_governance(self):
        res = self.bender_contract.set_governance(user).interpret(
            storage=valid_storage(),
            source=super_admin
        )

        self.assertEquals(user, res.storage['governance']['contract'])

    def test_set_fees_contract(self):
        res = self.bender_contract.set_fees_contract(user).interpret(
            storage=valid_storage(),
            source=super_admin
        )

        self.assertEquals(user, res.storage['governance']['fees_contract'])

    def test_add_token(self):
        res = self.bender_contract.add_token({
            "token_id": 1,
            "eth_contract": b"ethContract",
            "eth_symbol": "TUSD",
            "symbol": "WTUSD",
            "name": "True usd Wrapped",
            "decimals": 16
        }).interpret(
            storage=valid_storage(tokens={}),
            source=super_admin
        )

        self.assertIn(b'ethContract'.hex(), res.storage['assets']['tokens'])
        add_token = res.operations[0]
        self.assertEqual(token_contract + '%tokens', add_token['destination'])
        # needs more asserts, but we will wait for metadata fa2 spec to be stable and included

    def test_can_pause(self):
        res = self.bender_contract.pause_contract(True) \
            .interpret(storage=valid_storage(), source=super_admin)

        self.assertEquals(True, res.storage['admin']['paused'])

    def test_confirm_fa2_admin(self):
        res = self.bender_contract.confirm_tokens_administrator(None).interpret(storage=valid_storage(),
                                                                                source=super_admin)

        self.assertEquals(1, len(res.operations))
        op = res.operations[0]
        self.assertEquals(token_contract + "%admin", op["destination"])
        self.assertEquals(michelson.converter.convert('(Left (Left Unit))')
                          , op["parameters"]["value"])

    def test_pause_token(self):
        res = self.bender_contract.pause_tokens([{"token_id": 0, "paused": True}, {"token_id": 1, "paused": False}]) \
            .interpret(storage=valid_storage(), source=super_admin)

        self.assertEquals(1, len(res.operations))
        op = res.operations[0]
        self.assertEquals(token_contract + "%admin", op["destination"])
        self.assertEquals(michelson.converter.convert('(Left (Right { Pair 0 True ; Pair 1 False } ))'),
                          op["parameters"]["value"])

    def test_change_token_admin(self):
        res = self.bender_contract.change_tokens_administrator(user) \
            .interpret(storage=valid_storage(), source=super_admin)

        self.assertEquals(1, len(res.operations))
        op = res.operations[0]
        self.assertEquals(token_contract + "%admin", op["destination"])
        self.assertEquals(michelson.converter.convert(f'(Right "{user}")'),
                          op["parameters"]["value"])


def valid_storage(mints=None, fees_ratio=0, tokens=None, paused=False):
    if mints is None:
        mints = {}
    if tokens is None:
        tokens = {b'BOB': 1}
    return {
        "admin": {
            "administrator": super_admin,
            "signer": super_admin,
            "paused": paused
        },
        "assets": {
            "fa2_contract": "KT1LEzyhXGKfFsczmLJdfW1p8B1XESZjMCvw",
            "tokens": tokens,
            "mints": mints
        },
        "governance": {
            "contract": super_admin,
            "fees_contract": fees_contract,
            "wrapping_fees": fees_ratio,
            "unwrapping_fees": fees_ratio,
        }
    }


def mint_parameters(tx_id=bytes.fromhex("e1286c8cdafc9462534bce697cf3bf7e718c2241c6d02763e4027b072d371b7c"), owner=user,
                    amount=2):
    return {"token_id": b'BOB',
            "tx_id": tx_id,
            "owner": owner,
            "amount": amount
            }


def unwrap_parameters(amount=2, fees=1):
    return {"token_id": b'BOB',
            "amount": amount,
            "fees": fees,
            "destination": b"ethAddress"
            }
