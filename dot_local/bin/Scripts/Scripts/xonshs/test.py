from pydbus import SystemBus
from time import sleep

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
        settings = bus.get(
            "org.freedesktop.NetworkManager", "/org/freedesktop/NetworkManager/Settings"
        )

        for connection_path in settings.ListConnections():
            i_connection_id = bus.get(
                "org.freedesktop.NetworkManager", connection_path
            ).GetSettings()["connection"]["id"]

            if Id == i_connection_id:
                return connection_path
        raise KeyError("Unknown network id")

    @staticmethod
    def find_active_connection(connection_path):
        nm = bus.get("org.freedesktop.NetworkManager")
        for connection in nm.ActiveConnections:
            if (
                bus.get("org.freedesktop.NetworkManager", connection).Connection
                == connection_path
            ):
                return connection

        raise KeyError("Unknown path")

    @staticmethod
    def get_connection_state(connection_id):
        pr = bus.get(
            "org.freedesktop.NetworkManager", "/org/freedesktop/NetworkManager/Settings"
        )
        active_connections = NmLib.get_active_connection_ids()

        for connection_path in pr.ListConnections():
            connection = bus.get("org.freedesktop.NetworkManager", connection_path)
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


print(NmLib.get_connection_state("PolySearch"))
print(NmLib.get_connection_state("Costa Coffee 2"))

NmLib.set_connection_state("Costa Coffee 2", False)

sleep(1)
NmLib.set_connection_state("Costa Coffee 2", True)
