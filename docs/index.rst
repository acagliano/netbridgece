NETBRIDGECE Library
=====================
**A bridged socket interface for the TI-84+ CE.**

This library allows you to interface with a serial-tcp bridge running on a computer (ie bridged socket) while giving you the feeling of interacting with a standard socket API. The socket internally handles the configuration and maintainence of the state of the USB subsystem so that you do not need to deal with callbacks and events in your code. Simply use the provided API to send/recv data, emit directives to the bridge, and disconnect/close like you would a normal socket.

In order to use this library, the **tcp bridge** needs to be running on your computer with an active Internet connection. This program can be found in the *tcpbridge* folder and is called *bridge.py*.

----

API Documentation
^^^^^^^^^^^^^^^^^^

