netbridgece Library
=====================
**A bridged socket interface for the TI-84+ CE.**

This library allows you to interface with a serial-tcp bridge running on a computer (ie bridged socket) while giving you the feeling of interacting with a standard socket API. The socket internally handles the configuration and maintainence of the state of the USB subsystem so that you do not need to deal with callbacks, events, or the SRL/USB drivers in your code. Simply use the provided API to send/recv data, emit directives to the bridge, and disconnect/close like you would a normal socket.

In order to use this library, the **tcp bridge** needs to be running on your computer with an active Internet connection. This program can be found in the *tcpbridge* folder and is called *bridge.py*.

----

The expectation of the bridge is that a single byte prefix the incoming data (calc=>bridge) to tell the bridge whether the data is a **directive** or a **relay**. A directive begins with the static prefix :code:`0xFB`, then an instruction byte that controls what function to run. A relay packet begins with the static prefix :code:`0x00` and then has the data to forward to the socket.

While it is recommended to use the included bridge software, a different bridge can be used as long as it follows the same prefixing strategy. Imagine your bridge uses the prefix byte :code:`0xC0` for directives and :code:`0xFF` for relay. To support that with this library, you will need to run the following after socket creation:

.. code-block:: c
  
  bsocket_setoption(SOCKET_SET_CONTROL_BYTE, 0xC0);
  bsocket_setoption(SOCKET_SET_RELAY_BYTE, 0xFF);
  
It is also possible that your bridge supports directives that the included bridge doesn't. You can still use the :code:`bsocket_emitdirective()` function. Define your directive, make sure to assemble your AAD properly, and emit it to the bridge using this function. Everything should work fine.

.. code-block:: c

  bsocket_emitdirective(MY_NEW_DIRECTIVE, my_aad, sizeof(my_aad));

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

