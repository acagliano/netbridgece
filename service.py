import socket, json, threading, sys, time, logging, os, asyncio, ssl
import logging.handlers

try:
    import serial, serial.tools.list_ports
except ImportError:
    print("Dependency 'pyserial' not detected. Please run 'pip3 install pyserial'.")
    exit(1)

service_active = True
calc_connected = False
dev_serial = None
dev_socket = None
dev_socket_tls = None
tls_context = ssl.create_default_context()
logservice = None
server_connected = False
server_hostname = None
TI84PCE_IDENTIFIER = (0x16C0, 0x05E1)
PACKET_MAX_SIZE = 2046

ControlCode = 0xbc
FunctionCodes = {
    "CONNECT": 0x00,
    "DISCONNECT": 0x01,
    "STARTTLS": 0x02,
    "ENDTLS": 0x03
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
    while server_connected and calc_connected and service_active:
        try:
            if dev_socket_tls == None:
                status = dev_serial.write(dev_socket.recv(PACKET_MAX_SIZE))
            else:
                status = dev_serial.write(dev_socket_tls.recv(PACKET_MAX_SIZE))
        except socket.error as e:
            logservice.log(logging.ERROR, "{}\n".format(e))

def relay():
    global dev_socket, calc_connected, server_connected
    logservice.log(logging.INFO, "Service in relay mode...")
    while calc_connected and service_active:
        try:
            while True:
                size = int.from_bytes(dev_serial.read(3), 'little')
                if not(size) or (size > PACKET_MAX_SIZE):
                    logservice.log(logging.ERROR, "Serial packet dropped, invalid size.")
                    continue
                else:
                    data = dev_serial.read(size)
                    if len(data) != size:
                        logservice.log(logging.ERROR, "Serial packet dropped, packet incomplete.")
                        continue
                    if data[0]==ControlCode:
                        if data[1]==FunctionCodes["CONNECT"]:
                            global server_hostname
                            if server_connected:
                                logservice.log(logging.ERROR, "Already connected to a server. Disconnect first.")
                            try:
                                hostinfo=str(data[2:], 'utf-8').split("\0")
                                server=server_hostname=hostinfo[0]
                                port=hostinfo[1]
                                dev_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                                dev_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
                                dev_socket.connect((server, port))
                                logservice.log(logging.INFO, "Serial bridged to {} on port {}.".format(server, port))
                                server_connected = True
                            except Exception as e:
                                logservice.log(logging.ERROR, e)
                        elif data[1]==FunctionCodes["DISCONNECT"]:
                            dev_socket.shutdown()
                            server_connected = False
                        elif data[1]==FunctionCodes["STARTTLS"]:
                            global dev_socket_tls
                            dev_socket_tls = tls_context.wrap_socket(dev_socket, server_hostname=server_hostname)
                        elif data[1]==FunctionCodes["ENDTLS"]:
                            global dev_socket_tls
                            dev_socket_tls = None
                        else:
                            logservice.log(logging.ERROR, "Invalid bridge function code. Ignoring packet.")
                    else:
                        if not(server_connected):
                            logservice.log(logging.ERROR, "Cannot relay--not connected to a server")
                            continue
                        if dev_socket_tls == None:
                            dev_socket.send(bytes(u24(size)) + data)
                        else:
                            dev_socket_tls.send(bytes(u24(size)) + data)
        except IOError:
            logservice.log(logging.INFO, "Serial device closed. Returning to listen mode.")
            calc_connected = False
            # close socket
            return
    return

def listen():
    global dev_serial, calc_connected, logservice
    logservice.log(logging.INFO, "Service in listen mode...")
    while service_active:
        ports = [x for x in serial.tools.list_ports.comports(include_links=True) if (x.vid, x.pid) == TI84PCE_IDENTIFIER]
        if len(ports):
            serial_name = ports[0].device
            logservice.log(logging.INFO, "Calculator has been detected at {}.".format(serial_name))
            dev_serial = serial.Serial(serial_name, timeout=None)
            calc_connected = True
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
