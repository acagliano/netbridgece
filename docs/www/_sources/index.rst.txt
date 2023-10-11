netbridgece Library
=====================
**A bridged socket interface for the TI-84+ CE.**

This library allows you to interface with a serial-tcp bridge running on a computer (ie bridged socket) while giving you the feeling of interacting with a standard socket API. The socket internally handles the configuration and maintainence of the state of the USB subsystem so that you do not need to deal with callbacks, events, or the SRL/USB drivers in your code. Simply use the provided API to send/recv data, emit directives to the bridge, and disconnect/close like you would a normal socket.

In order to use this library, the **tcp bridge** needs to be running on your computer with an active Internet connection. This program can be found in the *tcpbridge* folder and is called *bridge.py*.

----

API Documentation
^^^^^^^^^^^^^^^^^^

.. doxygenfunction:: bsocket_create
  :project: BRDGLIB
  
.. doxygenfunction:: bsocket_connect
  :project: BRDGLIB
  
.. doxygenfunction:: bsocket_close
  :project: BRDGLIB
  
.. doxygenfunction:: bsocket_setoption
  :project: BRDGLIB
  
.. doxygenfunction:: bsocket_send
  :project: BRDGLIB
  
.. doxygenfunction:: bsocket_recv
  :project: BRDGLIB

.. doxygenfunction:: bsocket_emitdirective
  :project: BRDGLIB
  
.. doxygenfunction:: bsocket_sendpacket
  :project: BRDGLIB
  
.. doxygendefine:: BSOCKET_PS
  :project: BRDGLIB
  
.. doxygenfunction:: bsocket_update
  :project: BRDGLIB

