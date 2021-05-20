import unittest
from pathlib import Path

from pytezos import Key, MichelsonRuntimeError

from src.ligo import LigoContract

admin = Key.generate(export=False).public_key_hash()
first_farming_contract = "KT1K7L5bQzqmVRYyrgLTHWNHQ6C5vFpYGQRk"
other_farming_contract = "KT1XnzviJ2CnVXQSYquRpM5UrTJWCA5JzTdu"
minter_contract = "KT1BEqzn5Wx8uJrZNvuS9DVHmLvG9td3fDLi"
self_address = "KT1LRboPna9yQY9BrjtQYDS1DVxhKESK4VVd"
token = ("KT1VUNmGa1JYJuNxNS4XDzwpsc9N1gpcCBN2", 1)


class ReserveContractTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        root_dir = Path(__file__).parent.parent / "ligo"
        cls.contract = LigoContract(
            root_dir / "staking" / "reserve_main.mligo", "main"
        ).get_contract()


class ClaimFeesTest(ReserveContractTest):
    def test_should_call_minter_contract(self):
        res = self.contract.claim_fees(token[0], token[1], 100).interpret(
            storage=valid_storage(), sender=first_farming_contract
        )

        self.assertEqual(1, len(res.operations))
        op = res.operations[0]
        self.assertEqual(minter_contract, op["destination"])
        self.assertEqual("0", op["amount"])
        self.assertEqual("withdraw_token", op["parameters"]["entrypoint"])
        self.assertEqual(
            {
                "prim": "Pair",
                "args": [
                    {"string": token[0]},
                    {"int": str(token[1])},
                    {"int": str(100)},
                ],
            },
            op["parameters"]["value"],
        )

    def test_should_reject_if_not_farming_contract(self):
        with self.assertRaises(MichelsonRuntimeError) as context:
            self.contract.claim_fees(token[0], token[1], 100).interpret(
                storage=valid_storage(), sender=minter_contract
            )
        self.assertEqual("'NOT_STAKING_CONTRACT'", context.exception.args[-1])


class RegisterContractTest(ReserveContractTest):
    def test_should_call_update_operator(self):
        res = self.contract.register_contract(
            other_farming_contract, other_token_contract, 1
        ).interpret(sender=admin, storage=valid_storage(), self_address=self_address)

        self.assertEqual(1, len(res.operations))
        op = res.operations[0]
        self.assertEqual(other_token_contract, op["destination"])
        self.assertEqual("0", op["amount"])
        self.assertEqual("update_operators", op["parameters"]["entrypoint"])
        params = [
            {
                "prim": "Left",
                "args": [
                    {
                        "prim": "Pair",
                        "args": [
                            {"string": self_address},
                            {"string": other_farming_contract},
                            {"int": "1"},
                        ],
                    }
                ],
            }
        ]
        self.assertEqual(
            params,
            op["parameters"]["value"],
        )

    def test_should_add_contract_and_token_to_map(self):
        res = self.contract.register_contract(
            other_farming_contract, other_token_contract, 1
        ).interpret(sender=admin, storage=valid_storage(), self_address=self_address)

        self.assertEqual(
            (other_token_contract, 1), res.storage["farms"][other_farming_contract]
        )

    def test_should_reject_if_not_admin(self):
        with self.assertRaises(MichelsonRuntimeError) as context:
            self.contract.register_contract(
                other_farming_contract, other_token_contract, 1
            ).interpret(
                sender=self_address, storage=valid_storage(), self_address=self_address
            )
        self.assertEqual("'NOT_AN_ADMIN'", context.exception.args[-1])


class RemoveContractTest(ReserveContractTest):
    def test_should_call_update_operator(self):
        res = self.contract.remove_contract(first_farming_contract).interpret(
            sender=admin, storage=valid_storage(), self_address=self_address
        )

        self.assertEqual(1, len(res.operations))
        op = res.operations[0]
        self.assertEqual(token[0], op["destination"])
        self.assertEqual("0", op["amount"])
        self.assertEqual("update_operators", op["parameters"]["entrypoint"])
        params = [
            {
                "prim": "Right",
                "args": [
                    {
                        "prim": "Pair",
                        "args": [
                            {"string": self_address},
                            {"string": first_farming_contract},
                            {"int": str(token[1])},
                        ],
                    }
                ],
            }
        ]
        self.assertEqual(
            params,
            op["parameters"]["value"],
        )

    def test_should_remove_contract_and_token_from_map(self):
        res = self.contract.remove_contract(first_farming_contract).interpret(
            sender=admin, storage=valid_storage(), self_address=self_address
        )

        self.assertEqual(None, res.storage["farms"][first_farming_contract])

    def test_should_reject_if_not_admin(self):
        with self.assertRaises(MichelsonRuntimeError) as context:
            self.contract.remove_contract(other_farming_contract).interpret(
                sender=self_address, storage=valid_storage(), self_address=self_address
            )
        self.assertEqual("'NOT_AN_ADMIN'", context.exception.args[-1])


class AdminTests(ReserveContractTest):
    def test_should_change_admin(self):
        new_admin = a_user()

        res = self.contract.change_admin(new_admin).interpret(
            storage=valid_storage(), sender=admin
        )

        self.assertEqual(new_admin, res.storage["admin"]["pending_admin"])
        self.assertEqual(admin, res.storage["admin"]["address"])

    def test_should_reject_if_not_admin(self):
        with self.assertRaises(MichelsonRuntimeError) as context:
            self.contract.change_admin(admin).interpret(
                storage=valid_storage(), sender=a_user()
            )
        self.assertEqual("'NOT_AN_ADMIN'", context.exception.args[-1])

    def test_should_confirm_new_admin(self):
        new_admin = a_user()
        storage = (
            self.contract.change_admin(new_admin)
            .interpret(storage=valid_storage(), sender=admin)
            .storage
        )

        res = self.contract.confirm_new_admin().interpret(
            storage=storage, sender=new_admin
        )

        self.assertEqual(None, res.storage["admin"]["pending_admin"])
        self.assertEqual(new_admin, res.storage["admin"]["address"])

    def test_should_refect_if_no_pending_admin(self):
        with self.assertRaises(MichelsonRuntimeError) as context:
            self.contract.confirm_new_admin().interpret(
                storage=valid_storage(), sender=admin
            )
        self.assertEqual("'NO_PENDING_ADMIN'", context.exception.args[-1])

    def test_should_reject_if_not_pending_admin(self):
        with self.assertRaises(MichelsonRuntimeError) as context:
            new_admin = a_user()
            storage = (
                self.contract.change_admin(new_admin)
                .interpret(storage=valid_storage(), sender=admin)
                .storage
            )

            self.contract.confirm_new_admin().interpret(storage=storage, sender=admin)
        self.assertEqual("'NOT_PENDING_ADMIN'", context.exception.args[-1])


other_token_contract = "KT1Q3N9j6wXCvb37LuG4nDK7HqC1KfBrpeu3"


def valid_storage():
    return {
        "admin": {"pending_admin": None, "address": admin},
        "farms": {first_farming_contract: token},
        "minter_contract": minter_contract,
    }

def a_user():
    return Key.generate(export=False).public_key_hash()