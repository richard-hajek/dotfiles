#!/home/meowxiik/Cloud/Projects/xonsh_env/.venv/bin/xonsh

import colorama
import requests
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("--notify", action='store_true',
                    help="Send notification on fail")
parser.add_argument("groups", nargs='*',
                    help="Which groups to check")
args = parser.parse_args()


# ====================
# DEPS
# ====================
# Remember previous state
# Next level - auto deciding - Connect to Wifi? Connect to VPN?
# [x] Disable nm notifications


def get_current_state():
    pass


def apply_state(state):
    pass

#
# from pydbus import SystemBus
# bus = SystemBus()
# nm = bus.get("org.freedesktop.NetworkManager")
# class NmLib:
#
#    @staticmethod
#    def get_active_connection_ids():
#
#        Ids = set()
#
#        nm = bus.get("org.freedesktop.NetworkManager")
#        for connection in nm.ActiveConnections:
#            Ids.add(bus.get("org.freedesktop.NetworkManager", connection).Id)
#
#        return Ids
#
#    @staticmethod
#    def get_connection_by_id(Id):
#        settings = bus.get('org.freedesktop.NetworkManager', '/org/freedesktop/NetworkManager/Settings')
#
#        for connection_path in settings.ListConnections():
#            i_connection_id = bus.get('org.freedesktop.NetworkManager', connection_path).GetSettings()["connection"]["id"]
#
#            if ( Id == i_connection_id ):
#                return connection_path\
#
#        raise KeyError("Unknown network id")
#
#    @staticmethod
#    def find_active_connection(connection_path):
#        nm = bus.get("org.freedesktop.NetworkManager")
#        for connection in nm.ActiveConnections:
#            if bus.get("org.freedesktop.NetworkManager", connection).Connection == connection_path:
#                return connection
#
#        raise KeyError("Unknown path")
#
#    @staticmethod
#    def get_connection_state(connection_id):
#        pr = bus.get('org.freedesktop.NetworkManager', '/org/freedesktop/NetworkManager/Settings')
#        active_connections = NmLib.get_active_connection_ids()
#
#        for connection_path in pr.ListConnections():
#            connection = bus.get('org.freedesktop.NetworkManager', connection_path)
#            connection_id_i = connection.GetSettings()["connection"]["id"]
#
#            if connection_id == connection_id_i:
#                return connection_id in active_connections
#
#        raise KeyError("Unknown network id")
#
#    @staticmethod
#    def set_connection_state(connection_id, desired_on):
#
#        conn_path = NmLib.get_connection_by_id(connection_id)
#
#        if desired_on:
#            nm.ActivateConnection(conn_path, nm.GetDeviceByIpIface("wlp3s0"), "/")
#        else:
#            nm.DeactivateConnection(NmLib.find_active_connection(conn_path))
#
#
#
# =========
# Tester DEPS
# =========


class Status:
    SUCCESS = "Success"
    UNK = "Unknown"
    FAIL = "Fail"


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

# ####################
# TRIO BASED
# ####################


# ####################
# General Tests
# ####################


with TestCase("Internet") as internet:
    internet.ok = !(ping google.com - c 1).returncode == 0

# ####################
# Peoly Tests
# ####################


if is_in_group("peoly"):

    vpn_active = False

    if is_in_group("peoly_vpn"):

        with TestCase("Peoly VPN") as peolyvpn:
            vpn_activation_log = $(nmcli c u peoly_vpn 2>&1)

            peolyvpn.ok = ("Connection successfully activated" in vpn_activation_log or
                           "is already active" in vpn_activation_log)

            vpn_active = "is already active" in vpn_activation_log

    with TestCase("PeolyRD") as prd:
        prd.ok = !(ssh peolyrd.lo "echo ok" > /dev/null).returncode == 0

    with TestCase("Peoly Smartplan Data API") as psmdapi:
        response = requests.get(
            "http://10.0.1.58:8080/api/")

        if response.status_code != 200:
            raise Exception(
                "DataAPI return code: {response.status_code}")

        vehicles = response.json(
        )["priority_lane_vehicles"]["cars_len"]
        vehicles += response.json(
        )["incoming_vehicles"]["cars_len"]
        vehicles += response.json(
        )["outgoing_vehicles"]["cars_len"]
        people_stats = response.json()["pedestrian_stats"]
        peoples = people_stats["incoming"] + \
            people_stats["outgoing"]

        if vehicles == 0:
            raise Exception("Detected no vehicles")

        psmdapi.message = f"Total vehicles: {vehicles}, people: {peoples}"
        psmdapi.ok = True

    if is_in_group("peoly_vpn"):
        if not vpn_active:
            nmcli c d peoly_vpn > /dev/null

# ####################
# Home Network Tests
# ####################

if is_in_group("home"):

    with TestCase("Home Network") as home:
        home.ok = !(nmcli c u MeownetV4 > /dev/null 2>&1).returncode in [0]

    with TestCase("Proxmox") as proxmox:
        if not home.ok:
            raise Skip()

        proxmox.ok = !(curl - k 'https://192.168.1.101:8006' > /dev/null 2>&1).returncode == 0

    with TestCase("Transmission") as transmission:
        if not home.ok:
            raise Skip()

        transmission.ok = !(curl 'http://docker.lan:9091/transmission/web/' > /dev/null 2>&1).returncode == 0

    with TestCase("Docker") as docker:
        if not home.ok:
            raise Skip()

        docker.ok = !(ssh docker.lan echo hello > /dev/null 2>&1).returncode == 0

    with TestCase("Cloud Mount") as sshfs:
        if not home.ok:
            raise Skip()

        sshfs.ok = !(ls / media/meowxiik/Cloud/Downloads > /dev/null 2>&1).returncode == 0

    with TestCase("Syncthing Local") as syncthing:
        if not home.ok:
            raise Skip()

        syncthing.ok = !(curl http: // 127.0.0.1: 8384 / >/dev/null 2>&1).returncode == 0

    with TestCase("Syncthing Remote") as syncthing_remote:
        if not home.ok:
            raise Skip()

        syncthing_remote.ok = !(ssh data.lan curl 127.0.0.1: 8384 > /dev/null 2>&1).returncode == 0

    with TestCase("Samba Drive") as samba:
        if not home.ok:
            raise Skip()

        samba.ok = !(smbclient - L // docker.lan/public / -U user % pass > /dev/null 2>&1).returncode == 0
