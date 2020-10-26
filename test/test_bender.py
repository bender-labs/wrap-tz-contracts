from unittest import TestCase
from subprocess import Popen, PIPE
from io import TextIOWrapper

from pytezos import ContractInterface, michelson
from pytezos.repl.parser import MichelsonRuntimeError

source = 'tz1irF8HUsQp2dLhKNMhteG1qALNU9g3pfdN'
user = 'tz1grSQDByRpnVs7sPtaprNZRp531ZKz6Jmm'
fee_contract = 'tz1et19hnF9qKv6yCbbxjS1QDXB5HVx6PCVk'
token_contract = 'KT1LEzyhXGKfFsczmLJdfW1p8B1XESZjMCvw'
other_party = 'tz3SYyWM9sq9eWTxiA8KHb36SAieVYQPeZZm'


class BenderTest(TestCase):

    @classmethod
    def compile_contract(cls):
        command = f"ligo compile-contract ../ligo/bender.religo main"
        compiled_michelson = cls._ligo_to_michelson(command)
        cls.bender_contract = ContractInterface.create_from(compiled_michelson)

    @classmethod
    def _ligo_to_michelson(cls, command):
        with Popen(command, stdout=PIPE, stderr=PIPE, shell=True) as p:
            with TextIOWrapper(p.stdout) as out, TextIOWrapper(p.stderr) as err:
                michelson = out.read()
                if not michelson:
                    msg = err.read()
                    raise Exception(msg)
                else:
                    return michelson

    @classmethod
    def setUpClass(cls):
        cls.compile_contract()
        cls.maxDiff = None

    def test_changes_administrator(self):
        res = self.bender_contract.setAdministrator(other_party).interpret(storage=valid_storage(),
                                                                           sender=source)
        self.assertEquals(res.storage['administrator'], other_party)

    def test_rejects_mint_if_not_admin(self):
        with self.assertRaises(MichelsonRuntimeError):
            self.bender_contract.mint(mint_parameters()).interpret(
                storage=valid_storage(),
                sender=user)

    def test_calls_fa12_mint_for_user_and_fees_contract(self):
        amount = 1 * 10 ** 16

        res = self.bender_contract.mint(
            mint_parameters(amount=amount)).interpret(
            storage=valid_storage(fees_ratio=1),
            sender=source)

        self.assertEquals(1, len(res.operations))
        user_mint = res.operations[0]
        self.assertEquals('0', user_mint['amount'])
        self.assertEquals(f'{token_contract}%tokens', user_mint['destination'])
        self.assertEquals('tokens', user_mint['parameters']['entrypoint'])
        self.assertEquals(michelson.converter.convert(
            f'( Right {{ Pair {int(0.9999 * 10 ** 16)} "{user}" ; Pair {int(0.0001 * 10 ** 16)} "{fee_contract}" }})'),
            user_mint['parameters']['value'])

    def test_generates_only_one_mint_if_fees_to_low(self):
        amount = 1

        res = self.bender_contract.mint(
            mint_parameters(amount=amount)).interpret(
            storage=valid_storage(fees_ratio=1),
            sender=source)

        self.assertEquals(1, len(res.operations))
        user_mint = res.operations[0]
        self.assertEquals(michelson.converter.convert(
            f'( Right {{ Pair {amount} "{user}" }})'),
            user_mint['parameters']['value'])

    def test_saves_tx_id(self):
        res = self.bender_contract.mint(
            mint_parameters(tx_id='aTx')).interpret(
            storage=valid_storage(),
            sender=source)

        self.assertDictEqual({'aTx': None}, res.big_map_diff['mints'])

    def test_cannot_replay_same_tx(self):
        with self.assertRaises(MichelsonRuntimeError):
            self.bender_contract.mint(
                mint_parameters(tx_id='aTx')).interpret(
                storage=valid_storage(mints={'aTx': None}),
                sender=source)

    def test_burn_amount_for_account(self):
        amount = 100

        res = self.bender_contract.burn(
            burn_parameters(amount=amount)).interpret(
            storage=valid_storage(fees_ratio=1),
            source=user)

        self.assertEquals(1, len(res.operations))
        burn_operation = res.operations[0]
        self.assertEquals('0', burn_operation['amount'])
        self.assertEquals(f'{token_contract}%tokens', burn_operation['destination'])
        self.assertEquals('tokens', burn_operation['parameters']['entrypoint'])
        self.assertEquals(michelson.converter.convert(f'(Left {{ Pair {amount} "{user}" }})'),
                          burn_operation['parameters']['value'])

    def test_set_fees_ratio(self):
        res = self.bender_contract.setFeesRatio(10).interpret(
            storage=valid_storage(),
            source=source
        )

        self.assertEquals(10, res.storage['feesRatio'])

    def test_add_token(self):
        res = self.bender_contract.addToken('BOB', token_contract).interpret(
            storage=valid_storage(tokens={}),
            source=source
        )

        self.assertEquals(res.storage['tokens'], {'BOB': token_contract})

    def test_remove_token(self):
        res = self.bender_contract.removeToken('BOB').interpret(
            storage=valid_storage(),
            source=source
        )

        self.assertEquals(res.storage['tokens'], {})


def valid_storage(mints=None, fees_ratio=0, tokens=None):
    if mints is None:
        mints = {}
    if tokens is None:
        tokens = {'BOB': token_contract}
    return {
        "administrator": source,
        "feesContract": fee_contract,
        "feesRatio": fees_ratio,
        "tokens": tokens,
        "mints": mints
    }


def mint_parameters(tx_id="txId", owner=user, amount=2):
    return {"tokenId": "BOB",
            "mainChainTxId": tx_id,
            "owner": owner,
            "amount": amount
            }


def burn_parameters(amount=2):
    return {"tokenId": "BOB",
            "amount": amount
            }
