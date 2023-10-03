import socket, json, threading, sys, time, logging, os, asyncio, ssl
import logging.handlers

try:
    import serial, serial.tools.list_ports
except ImportError:
    print("Dependency 'pyserial' not detected. Please run 'pip3 install pyserial'.")
    exit(1)

service_active = True
tls_context = ssl.create_default_context()

calc = {
    "serial": None
}
remote = {
    "host": None,
    "socket": None,
    "socket_tls": None
}
logservice = None
TI84PCE_IDENTIFIER = (0x16C0, 0x05E1)
PACKET_MAX_SIZE = 2046

ControlCode = 0xbc
FunctionCodes = {
    "PING": 0x00,
    "CONNECT": 0x01,
    "DISCONNECT": 0x02,
    "STARTTLS": 0x03,
    "ENDTLS": 0x04
}

def u24(*args):
    o=[]
    for arg in args:
        if int(arg)<0: arg = abs(int(arg))
        else: arg = int(arg)
        o.extend(list(int(arg).to_bytes(3,'little')))
    return o

def tcp_recv():
    global service_active, server_connected
    while calc["serial"] and remote["socket"] and service_active:
        try:
            if remote["socket_tls"]:
                status = calc["serial"].write(remote["socket_tls"].recv(PACKET_MAX_SIZE))
            else:
                status = calc["serial"].write(remote["socket"].recv(PACKET_MAX_SIZE))
        except socket.error as e:
            logservice.log(logging.ERROR, e)

def relay():
    global calc, remote
    logservice.log(logging.INFO, "Service in relay mode...")
    while calc["serial"] and service_active:
        try:
            size = int.from_bytes(calc["serial"].read(3), 'little')
            if not(size) or (size > PACKET_MAX_SIZE):
                logservice.log(logging.ERROR, "Serial packet dropped, invalid size.")
                continue
            else:
                data = calc["serial"].read(size)
                if len(data) != size:
                    logservice.log(logging.ERROR, "Serial packet dropped, packet incomplete.")
                    continue
                if data[0]==ControlCode:
                    if data[1]==FunctionCodes["PING"]:
                        calc["serial"].write(b'\x02\x00\x00\xBC\x00')
                    elif data[1]==FunctionCodes["CONNECT"]:
                        try:
                            if remote["socket"]:
                                logservice.log(logging.ERROR, "Already connected to a server. Disconnecting.")
                                remote["socket"].shutdown()
                            hostinfo=str(data[2:], 'utf-8').split("\0")
                            hostname = hostinfo[0]
                            port = int(hostinfo[1])
                            remote["socket"] = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                            remote["socket"].setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
                            remote["socket"].connect((hostname, port))
                            logservice.log(logging.INFO, "Serial bridged to {} on port {}.".format(hostname, port))
                            remote["host"] = (hostname, port)
                            calc["serial"].write(b'\x03\x00\x00\xBC\x01\x00')
                        except Exception as e:
                            logservice.log(logging.ERROR, e)
                            calc["serial"].write(b'\x03\x00\x00\xBC\x01\x00')
                    elif data[1]==FunctionCodes["DISCONNECT"]:
                        remote["socket"].shutdown()
                        remote["socket"].close()
                        remote["socket"] = None
                        remote["host"] = None
                    elif data[1]==FunctionCodes["STARTTLS"]:
                        remote["socket_tls"] = tls_context.wrap_socket(dev_socket, server_hostname=remote["host"][0])
                    elif data[1]==FunctionCodes["ENDTLS"]:
                        remote["socket_tls"] = None
                    else:
                        logservice.log(logging.ERROR, "Invalid bridge function code {}. Ignoring packet.".format(data[1]))
                else:
                    if remote["socket"] == None:
                        logservice.log(logging.ERROR, "Cannot relay--not connected to a server")
                        continue
                    if remote["socket_tls"]:
                        remote["socket_tls"].send(bytes(u24(size)) + data)
                    else:
                        remote["socket"].send(bytes(u24(size)) + data)
        except IOError:
            logservice.log(logging.INFO, "Serial device closed. Returning to listen mode.")
            calc["serial"].reset_input_buffer()
            calc["serial"].reset_output_buffer()
            calc["serial"].close()
            if remote["tls_socket"]:
                remote["tls_socket"].shutdown()
                remote["tls_socket"].close()
                remote["tls_socket"] = None
            if remote["socket"]:
                remote["socket"].shutdown()
                remote["socket"].close()
                remote["socket"] = None
            return
    return

def listen():
    global calc, logservice
    logservice.log(logging.INFO, "Service in listen mode...")
    while service_active:
        ports = [x for x in serial.tools.list_ports.comports(include_links=True) if (x.vid, x.pid) == TI84PCE_IDENTIFIER]
        if len(ports):
            serial_name = ports[0].device
            logservice.log(logging.INFO, "Calculator has been detected at {}.".format(serial_name))
            calc["serial"] = serial.Serial(serial_name, timeout=None)
            relay()
        time.sleep(0.5)

def init_logger():
    global logservice
    logservice = logging.getLogger("ti84pce-serial-bridge")
    logservice.setLevel(logging.INFO)
    format=logging.Formatter("%(asctime)s: %(levelname)s: %(message)s")
    stream_handler = logging.StreamHandler()
    stream_handler.setFormatter(format)
    logservice.addHandler(stream_handler)

init_logger()
listen()
