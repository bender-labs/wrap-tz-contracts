from unittest import TestCase

from pytezos import michelson
from pytezos.repl.parser import MichelsonRuntimeError
from src.ligo import LigoContract

source = 'tz1irF8HUsQp2dLhKNMhteG1qALNU9g3pfdN'
user = 'tz1grSQDByRpnVs7sPtaprNZRp531ZKz6Jmm'
fee_contract = 'tz1et19hnF9qKv6yCbbxjS1QDXB5HVx6PCVk'
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
                                                                            sender=source)
        self.assertEquals(res.storage['admin']['administrator'], other_party)

    def test_rejects_mint_if_not_signer(self):
        with self.assertRaises(MichelsonRuntimeError) as context:
            self.bender_contract.mint_token(mint_parameters()).interpret(
                storage=valid_storage(),
                sender=user)

        self.assertEquals("NOT_SIGNER", context.exception.message)

    def test_calls_fa2_mint_for_user_and_fees_contract(self):
        amount = 1 * 10 ** 16

        res = self.bender_contract.mint_token(
            mint_parameters(amount=amount)).interpret(
            storage=valid_storage(fees_ratio=1),
            sender=source)

        self.assertEquals(1, len(res.operations))
        user_mint = res.operations[0]
        self.assertEquals('0', user_mint['amount'])
        self.assertEquals(f'{token_contract}%tokens', user_mint['destination'])
        self.assertEquals('tokens', user_mint['parameters']['entrypoint'])
        self.assertEquals(michelson.converter.convert(
            f'( Right {{ Pair "{user}" (Pair 1 {int(0.9999 * 10 ** 16)} )  ; Pair "{fee_contract}" (Pair 1 {int(0.0001 * 10 ** 16)} )}})'),
            user_mint['parameters']['value'])

    def test_generates_only_one_mint_if_fees_to_low(self):
        amount = 1

        res = self.bender_contract.mint_token(
            mint_parameters(amount=amount)).interpret(
            storage=valid_storage(fees_ratio=1),
            sender=source)

        self.assertEquals(1, len(res.operations))
        user_mint = res.operations[0]
        self.assertEquals(michelson.converter.convert(
            f'( Right {{ Pair "{user}" (Pair 1 {amount} )}})'),
            user_mint['parameters']['value'])

    def test_saves_tx_id(self):
        tx_id = bytes.fromhex("386bf131803cba7209ff9f43f7be0b1b4112605942d3743dc6285ee400cc8c2d")

        res = self.bender_contract.mint_token(
            mint_parameters(tx_id=tx_id)).interpret(
            storage=valid_storage(),
            sender=source)

        self.assertDictEqual({tx_id.hex(): None}, res.big_map_diff['assets/mints'])

    def test_cannot_replay_same_tx(self):
        with self.assertRaises(MichelsonRuntimeError) as context:
            self.bender_contract.mint_token(
                mint_parameters(tx_id=b'aTx')).interpret(
                storage=valid_storage(mints={b'aTx': None}),
                sender=source)
        self.assertEquals("TX_ALREADY_MINTED", context.exception.message)

    def test_burn_amount_for_account(self):
        amount = 100

        res = self.bender_contract.burn(
            burn_parameters(amount=amount)).interpret(
            storage=valid_storage(fees_ratio=1),
            source=user
        )

        self.assertEquals(1, len(res.operations))
        burn_operation = res.operations[0]
        self.assertEqual('0', burn_operation['amount'])
        self.assertEqual(f'{token_contract}%tokens', burn_operation['destination'])
        self.assertEqual('tokens', burn_operation['parameters']['entrypoint'])
        self.assertEqual(michelson.converter.convert(f'(Left (Left {{ Pair "{user}" (Pair 1 {amount} )}}))'),
                         burn_operation['parameters']['value'])

    def test_set_fees_ratio(self):
        res = self.bender_contract.set_fees_ratio(10).interpret(
            storage=valid_storage(),
            source=source
        )

        self.assertEquals(10, res.storage['assets']['fees_ratio'])

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
            source=source
        )

        self.assertIn(b'ethContract'.hex(), res.storage['assets']['tokens'])
        add_token = res.operations[0]
        self.assertEqual(token_contract + '%tokens', add_token['destination'])
        # needs more asserts, but we will wait for metadata fa2 spec to be stable and included


def valid_storage(mints=None, fees_ratio=0, tokens=None):
    if mints is None:
        mints = {}
    if tokens is None:
        tokens = {b'BOB': 1}
    return {
        "admin": {
            "administrator": source,
            "signer": source
        },
        "assets": {
            "governance": source,
            "fa2_contract": "KT1LEzyhXGKfFsczmLJdfW1p8B1XESZjMCvw",
            "fees_contract": fee_contract,
            "fees_ratio": fees_ratio,
            "tokens": tokens,
            "mints": mints
        }
    }


def mint_parameters(tx_id=bytes.fromhex("e1286c8cdafc9462534bce697cf3bf7e718c2241c6d02763e4027b072d371b7c"), owner=user, amount=2):
    return {"token_id": b'BOB',
            "tx_id": tx_id,
            "owner": owner,
            "amount": amount
            }


def burn_parameters(amount=2):
    return {"token_id": b'BOB',
            "amount": amount,
            "destination": b"ethAddress"
            }
