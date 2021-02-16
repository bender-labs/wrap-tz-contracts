from src.deploy import Deploy
from src.minter import Minter
from src.quorum import Quorum
from src.token import Token
from src.ligo import PtzUtils
import fire
from pytezos import pytezos, PyTezosClient


class Client(object):
    def __init__(self, shell="http://localhost:8732", key="edsk3QoqBuvdamxouPhin7swCvkQNgq4jP5KZPbwWNnwdZpSpJiEbq"):
        client: PyTezosClient = pytezos.using(
            key=key,
            shell=shell)
        utils = PtzUtils(client)
        self.minter = Minter(utils)
        self.token = Token(utils)
        self.quorum = Quorum(utils)
        self.deploy = Deploy(client)


if __name__ == '__main__':
    fire.Fire(Client)
