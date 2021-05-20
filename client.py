from src.deploy import Deploy
from src.governance import Governance
from src.minter import Minter
from src.quorum import Quorum
from src.staking import Staking
from src.token import Token
import fire
from pytezos import pytezos, PyTezosClient


class Client(object):
    def __init__(self, shell="http://localhost:8732", key="edsk3QoqBuvdamxouPhin7swCvkQNgq4jP5KZPbwWNnwdZpSpJiEbq"):
        client: PyTezosClient = pytezos.using(
            key=key,
            shell=shell)
        self.minter = Minter(client)
        self.token = Token(client)
        self.quorum = Quorum(client)
        self.deploy = Deploy(client)
        self.governance = Governance(client)
        self.staking = Staking(client)


if __name__ == '__main__':
    fire.Fire(Client)
