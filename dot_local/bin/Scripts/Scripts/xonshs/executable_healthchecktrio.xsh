#!/home/meowxiik/Cloud/Projects/xonsh_env/.venv/bin/xonsh

import colorama
import requests
import argparse
import trio
import asyncio
from pydbus import SystemBus

parser = argparse.ArgumentParser()
parser.add_argument("--notify", action='store_true', help="Send notification on fail")
parser.add_argument("groups", nargs='*', help="Which groups to check")
parser.add_argument("--debug", action="store_true")
args = parser.parse_args()

DEBUG=False

def dprint(*args, **kwargs):
    if DEBUG:
        print(*args, **kwargs)

#=========
#System bus wifi 
#=========


bus = SystemBus()
nm = bus.get("org.freedesktop.NetworkManager")
class NmLib:

   @staticmethod
   def get_active_connection_ids():
       Ids = set()
       nm = bus.get("org.freedesktop.NetworkManager")
       for connection in nm.ActiveConnections:
           Ids.add(bus.get("org.freedesktop.NetworkManager", connection).Id)
       return Ids
   
   @staticmethod
   def get_connection_by_id(Id):
       settings = bus.get('org.freedesktop.NetworkManager', '/org/freedesktop/NetworkManager/Settings')
       for connection_path in settings.ListConnections():
           i_connection_id = bus.get('org.freedesktop.NetworkManager', connection_path).GetSettings()["connection"]["id"]
           if ( Id == i_connection_id ):
               return connection_path
       raise KeyError("Unknown network id")
   
   @staticmethod
   def find_active_connection(connection_path):
       nm = bus.get("org.freedesktop.NetworkManager")
       for connection in nm.ActiveConnections:
           if bus.get("org.freedesktop.NetworkManager", connection).Connection == connection_path:
               return connection
       raise KeyError("Unknown path")
   
   @staticmethod
   def get_connection_state(connection_id):
       pr = bus.get('org.freedesktop.NetworkManager', '/org/freedesktop/NetworkManager/Settings')
       active_connections = NmLib.get_active_connection_ids()
       for connection_path in pr.ListConnections():
           connection = bus.get('org.freedesktop.NetworkManager', connection_path)
           connection_id_i = connection.GetSettings()["connection"]["id"]
           if connection_id == connection_id_i:
               return connection_id in active_connections
       raise KeyError("Unknown network id")

   @staticmethod
   def set_connection_state(connection_id, desired_on):
       conn_path = NmLib.get_connection_by_id(connection_id)
       if desired_on:
           nm.ActivateConnection(conn_path, nm.GetDeviceByIpIface("wlp3s0"), "/")
       else:
           nm.DeactivateConnection(NmLib.find_active_connection(conn_path))

#=========
# Tester DEPS
# =========


class Status:
    SUCCESS = "Success"
    UNK = "Unknown"
    FAIL = "Fail"
    START = "Started"


class Skip(Exception):
    pass


def is_in_group(group):
    if len(args.groups) == 0:
        return True
    return group in args.groups


def category(name):
    print("=> Category: {name}")


def message(test_name, status, info):

    if status == Status.SUCCESS:
        print("[" + colorama.Fore.GREEN + colorama.Style.BRIGHT +
              "OK" + colorama.Style.RESET_ALL + "] ", end="")
    elif status == Status.UNK:
        print("[" + colorama.Fore.YELLOW + colorama.Style.BRIGHT +
              "UNK" + colorama.Style.RESET_ALL + "] ", end="")
    elif status == Status.FAIL:
        print("[" + colorama.Fore.RED + colorama.Style.BRIGHT +
              "FAIL" + colorama.Style.RESET_ALL + "] ", end="")
    else:
        print(f"[O] {status} ", end="")


    print(test_name, end="")

    if info:
        print(" - " + info)
    else:
        print()

    if status == Status.FAIL and args.notify:
        notify-send - a "Healthcheck" f"{test_name}" f"{test_name} {status} {info}"


class TestCase:

    def __init__(self, name):
        self.name = name
        self.ok = None
        self.message = ""

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_value, traceback):

        if exc_type == Skip:
            exc_type, exc_value, traceback = None, None, None

        if traceback:
            message(self.name, Status.FAIL,
                    f"{exc_type=}, {exc_value=}")
            self.ok = False
        elif self.ok is None:
            message(self.name, Status.UNK, self.message)
        elif self.ok:
            message(self.name, Status.SUCCESS, self.message)
        elif not self.ok:
            message(self.name, Status.FAIL, self.message)
        else:
            message(self.name, Status.UNK, self.message)

        return True

class AsyncTestCase:
    def __init__(self, name, logger):
        self.name = name
        self.ok = None
        self.message = ""
        self.logger = logger
    
    async def __aenter__(self):
        await self.logger(self.name, Status.START, "")
        return self
    
    async def __aexit__(self, exc_type, exc_value, traceback):

        #print(f"Aexit {exc_type=}, {exc_value=}, {traceback=}")
        #print(f"self {self.ok=}, {self.message=}")

        if exc_type == Skip:
            exc_type, exc_value, traceback = None, None, None

        if traceback:
            await self.logger(self.name, Status.FAIL, f"{exc_type=}, {exc_value=}")
            self.ok = False
        elif self.ok is None:
            await self.logger(self.name, Status.UNK, self.message)
        elif self.ok:
            await self.logger(self.name, Status.SUCCESS, self.message)
        elif not self.ok:
            await self.logger(self.name, Status.FAIL, self.message)
        else:
            await self.logger(self.name, Status.UNK, self.message)
        
        return True

class Logger:
    def __init__(self, debug=False):
        self.send_channel, self.receive_channel = None, None
        self.ready = trio.Event()
        self.started = set()
        self.have_tasks = trio.Event()
        self.debug = debug
    
    async def log(self, name, status, exc):
        await self.ready.wait()

        if bool(status is not Status.START) or bool(self.debug):
            await self.send_channel.send((name, status, exc))

        if status == Status.START:
            self.started.add(name)
            self.have_tasks.set()
        else:
            self.started.discard(name)

            if len(self.started) == 0:
                await self.send_channel.aclose()
    
    async def run(self):
        self.send_channel, self.receive_channel = trio.open_memory_channel(0)
        self.started = set()
        self.ready.set()
        async with self.receive_channel:
            async for name, status,exc in self.receive_channel:
                message(name, status, exc)
        self.ready = trio.Event()
        self.abort = trio.Event()
        self.have_tasks = trio.Event()
    
    async def run2(self):
        await trio.sleep(1) # Wait a sec and abort if no tasks were scheduled
        if not self.have_tasks.is_set():
            await self.send_channel.aclose()



# ========
# GENERAL
# ========

async def internet(logger):
    async with AsyncTestCase("Internet", logger) as internet:

        def cmd():
            return !(ping google.com -c 1)
        
        result = (await trio.to_thread.run_sync(cmd))
        internet.ok = result.returncode == 0

# =========
# HOME
# =========


async def test_command(logger, name, command, ok_returncodes=[0]):
    async with AsyncTestCase(name, logger) as case:

        def cmd():
            return !( bash -c @(command) )
        
        case.ok = (await trio.to_thread.run_sync(cmd)).returncode in ok_returncodes

async def test_lambda(logger, name, lb):
    async with AsyncTestCase(name, logger) as case:
        case.ok = (await trio.to_thread.run_sync(lb))

async def home_network(logger):

    def set_home_network():
        target_network = "MeownetV4"
        if target_network not in NmLib.get_active_connection_ids():
            NmLib.set_connection_state(target_network, True)
        return target_network in NmLib.get_active_connection_ids()

    await test_lambda(logger, "Home Network", set_home_network)

async def home_proxmox(logger):
    await test_command(logger, "Proxmox", "curl -k 'https://192.168.1.101:8006' > /dev/null 2>&1")

async def home_transmission(logger):
    await test_command(logger, "Transmission", "curl 'http://docker.lan:9091/transmission/web/' > /dev/null 2>&1")

async def home_docker(logger):
    await test_command(logger, "Docker", "ssh docker.lan echo hello > /dev/null 2>&1")

async def home_cloud_mount(logger):
    await test_command(logger, "Cloud Mount", "ls /media/meowxiik/Cloud/Downloads > /dev/null 2>&1")

async def home_syncthing_local(logger):
    await test_command(logger, "Syncthing Local", "curl http://127.0.0.1:8384/ >/dev/null 2>&1")

async def home_syncthing_remote(logger):
    await test_command(logger, "Syncthing Remote", "ssh data.lan curl 127.0.0.1:8384 > /dev/null 2>&1")

async def home_samba(logger):
    await test_command(logger, "Samba", "smbclient -L //docker.lan/public/ -U user%pass > /dev/null 2>&1")

# =========
# Peoly
# =========

async def peoly_vpn(logger):
    async with AsyncTestCase("Peoly VPN", logger) as peolyvpn:

        def cmd():
             return $(nmcli c u peoly_vpn 2>&1)

        vpn_activation_log = await trio.to_thread.run_sync(cmd)

        peolyvpn.ok = ("Connection successfully activated" in vpn_activation_log or "is already active" in vpn_activation_log)

async def peoly_vpn_off(logger):
    async with AsyncTestCase("Peoly VPN Off", logger) as peolyvpn:

        def cmd():
             return $(nmcli c d peoly_vpn > /dev/null)

        await trio.to_thread.run_sync(cmd)
        peolyvpn.ok = True

async def peoly_rd(logger):
    async with AsyncTestCase("PeolyRD", logger) as prd:
        def cmd():
            return !(ssh peolyrd.lo "echo ok" > /dev/null).returncode == 0
        
        prd.ok = await trio.to_thread.run_sync(cmd)

async def peoly_sm_data(logger):
    async with AsyncTestCase("Peoly Smartplan Data API", logger) as psmdapi:

        def cmd():
            response = requests.get(
                "http://10.0.1.58:8080/api/")

            if response.status_code != 200:
                return (None, None), Exception(f"DataAPI return code: {response.status_code}")

            vehicles = response.json()["priority_lane_vehicles"]["cars_len"]
            vehicles += response.json()["incoming_vehicles"]["cars_len"]
            vehicles += response.json()["outgoing_vehicles"]["cars_len"]
            people_stats = response.json()["pedestrian_stats"]
            peoples = people_stats["incoming"] + people_stats["outgoing"]

            if vehicles == 0:
                return (None, None), Exception("Detected no vehicles")
            
            return (vehicles, peoples), None

        (vehicles, peoples), exc = await trio.to_thread.run_sync(cmd)

        if exc:
            raise exc

        psmdapi.message = f"Total vehicles: {vehicles}, people: {peoples}"
        psmdapi.ok = True


# ####################
# TRIO BASED
# ####################

async def main(args):

    logger = Logger(args.debug)
    
    dprint("== PREPARE ==")

    async with trio.open_nursery() as nursery:
        nursery.start_soon(logger.run)
        nursery.start_soon(logger.run2)
        nursery.start_soon(internet, logger.log)

        if is_in_group("home"):
            nursery.start_soon(home_network, logger.log)
        
        if is_in_group("peoly_vpn"):
            nursery.start_soon(peoly_vpn, logger.log)

    dprint("== MAIN ==")

    async with trio.open_nursery() as n:
        n.start_soon(logger.run)
        n.start_soon(logger.run2)

        if is_in_group("peoly"):
            n.start_soon(peoly_rd, logger.log)
            n.start_soon(peoly_sm_data, logger.log)
        
        if is_in_group("home"):
            n.start_soon(home_docker, logger.log)
            n.start_soon(home_proxmox, logger.log)
            n.start_soon(home_transmission, logger.log)
            n.start_soon(home_cloud_mount, logger.log)
            n.start_soon(home_syncthing_local, logger.log)
            n.start_soon(home_syncthing_remote, logger.log)
            n.start_soon(home_samba, logger.log)

    dprint("== CLOSING ==")    
    
    async with trio.open_nursery() as nursery:
        nursery.start_soon(logger.run)
        nursery.start_soon(logger.run2)

        if is_in_group("peoly_vpn"):
            nursery.start_soon(peoly_vpn_off, logger.log)

    dprint("== OK ==")

if __name__ == "__main__":
    args = parser.parse_args([] if "__file__" not in globals() else None)
    DEBUG = args.debug
    trio.run(main, args)