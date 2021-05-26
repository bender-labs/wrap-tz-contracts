import json
import os
from io import TextIOWrapper
from pathlib import Path
from subprocess import Popen, PIPE

from pytezos import pytezos, ContractInterface, michelson_to_micheline
from pytezos.operation.result import OperationResult
from pytezos.rpc.errors import RpcError

ligo_version = "0.10.0"
# ligo_cmd = (
#     f'docker run --rm -v "$PWD":"$PWD" -w "$PWD" ligolang/ligo:{ligo_version} "$@"'
# )
ligo_cmd = (
    f'ligo'
)


def execute_command(command):
    wd = Path(__file__).parent.parent
    with Popen(command, stdout=PIPE, stderr=PIPE, shell=True, cwd=wd) as p:
        with TextIOWrapper(p.stdout) as out, TextIOWrapper(p.stderr) as err:
            michelson = out.read()
            if not michelson:
                msg = err.read()
                raise Exception(msg)
            else:
                return michelson


class LigoView:
    def __init__(self, ligo_file):
        self.ligo_file = ligo_file

    def compile(self, view_name, return_type, description="", pure=True):
        return_type = michelson_to_micheline(return_type)
        result = {
            "name": view_name,
            "description": description,
            "pure": pure,
            "implementations": [
                {
                    "michelsonStorageView": {
                        "returnType": return_type,
                        "code": self._compile_expression(view_name)
                    }
                }
            ]
        }
        parameter = self._compile_parameter(view_name)
        if parameter != json.loads('{"prim": "unit"}'):
            result["implementations"][0]["michelsonStorageView"]["parameter"] = parameter

        return result

    def _compile_expression(self, view_name):
        command = f"{ligo_cmd} compile-expression " \
                  f"--michelson-format=json " \
                  f"--init-file={self.ligo_file} " \
                  f"cameligo " \
                  f"'{view_name}_view'"
        return json.loads(execute_command(command))

    def _compile_parameter(self, view_name):
        command = f"{ligo_cmd} compile-contract " \
                  f"--michelson-format=json " \
                  f"{self.ligo_file} " \
                  f"'{view_name}'_main"
        result = json.loads(execute_command(command))
        return result[0]['args'][0]


class LigoContract:
    def __init__(self, ligo_file, main_func):
        """
        :param ligo_file: path to the contract LIGO source file.
        :param main_func: name of the contract entry point function
        """
        self.ligo_file = ligo_file
        self.main_func = main_func
        self.contract_interface = None

    def __call__(self):
        return self.get_contract()

    def compile_contract(self):
        """
        Force compilation of LIGO contract from source file and loads it into
        pytezos.
        :return: pytezos.ContractInterface
        """
        command = f"{ligo_cmd} compile-contract {self.ligo_file} {self.main_func}"
        michelson = execute_command(command)

        self.contract_interface = ContractInterface.from_michelson(michelson)
        return self.contract_interface

    def get_contract(self):
        """
        Returns pytezos contract. If it is not loaded et, compiles it from LIGO
        source file.
        :return: pytezos.ContractInterface
        """
        if self.contract_interface:
            return self.contract_interface
        else:
            return self.compile_contract()

    def _ligo_to_michelson_sanitized(self, command):
        michelson = execute_command(command)
        return self._sanitize(michelson)

    def _sanitize(self, michelson):
        stripped = michelson.strip()
        if stripped.startswith("(") and stripped.endswith(")"):
            return stripped[1:-1]
        else:
            return stripped


def get_consumed_gas(op_res):
    gs = (r["consumed_gas"] for r in OperationResult.iter_results(op_res))
    return [int(g) for g in gs]


def pformat_consumed_gas(op_res):
    gs = get_consumed_gas(op_res)
    if len(gs) == 1:
        return f"operation consumed gas: {gs[0]:,}"
    else:
        total = sum(gs)
        internal_ops_gas = [f"{g:,}" for g in gs]
        return f"operation consumed gas: {total:,} {internal_ops_gas}"


class PtzUtils:
    def __init__(self, client: pytezos, block_depth=5, num_blocks_wait=3):
        """
        :param client: PyTezosClient
        :param block_depth number of recent blocks to test when checking for operation status
        :param num_blocks_wait number of backed blocks to retry wait until failing with timeout
        """
        self.client: pytezos = client
        self.block_depth = block_depth
        self.num_blocks_wait = num_blocks_wait

    def using(self, shell=None, key=None):
        new_client = self.client.using(
            shell=shell or self.client.shell, key=key or self.client.key
        )
        return PtzUtils(
            new_client,
            block_depth=self.block_depth,
            num_blocks_wait=self.num_blocks_wait,
        )

    def wait_for_ops(self, *ops):
        """
        Waits for specified operations to be completed successfully.
        If any of the operations fails, raises exception.
        :param *ops: list of operation descriptors returned by inject()
        """

        for _ in range(self.num_blocks_wait):
            chr = (self._check_op(op) for op in ops)
            res = [op_res for op_res in chr if op_res]
            if len(ops) == len(res):
                return res
            try:
                self.client.shell.wait_next_block()
            except AssertionError:
                print("block waiting timed out")

        raise TimeoutError("waiting for operations")

    def _check_op(self, op):
        """
        Returns None if operation is not completed
        Raises error if operation failed
        Return operation result if operation is completed
        """

        op_data = op[0] if isinstance(op, tuple) else op
        op_hash = op_data["hash"]

        blocks = self.client.shell.blocks[-self.block_depth:]
        try:
            res = blocks.find_operation(op_hash)
            if not OperationResult.is_applied(res):
                raise RpcError.from_errors(OperationResult.errors(res)) from op_hash
            print(pformat_consumed_gas(res))
            return res
        except StopIteration:
            # not found
            return None
