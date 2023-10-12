/**
 * @file bridgelib.h
 * @brief Bridged-Socket Lib for Use with Serial-TCP Bridge
 * @author Anthony @e ACagliano Cagliano
 */

#include <stdint.h>
#include <stdbool.h>

/// Socket options flags for passing to @b bsocket_setoption
/// @warning USB timers not yet supported. <b>DO NOT USE BLOCKING SOCKETS UNTIL TOLD OTHERWISE.</b>
typedef enum _sockoptflags {
  SOCKET_BLOCKING,              /**< [BOOL] Should socket block (wait for completion)? */
  SOCKET_TIMEO,                 /**< [UINT24_T] Timeout, in MS, for blocking socket connect and recv. */
  SOCKET_SET_CONTROL_BYTE,      /**< [UINT8_T] Reserved byte for sending directives to bridge. */
  SOCKET_SET_RELAY_BYTE         /**< [UINT8_T] Reserved byte for relaying a packet to the TCP socket. */
  /** <b>All packets sent to the bridge MUST start with the control or relay prefix byte or an error will be returned.</b> */
} bsocket_option_t;

/// Socket directives for passing to @b bsocket_emitdirective
/// These directives apply to the bridge distributed in this repository. If using your own bridge, use whatever
/// directive mapping you used in it as well as set the Control Byte accordingly.
typedef enum _sockdirectives {
  RESERVED0,            // connect
  RESERVED1,            // disconnect
  SOCKET_STARTTLS,
  SOCKET_ENDTLS
} bsocket_directives_t;

/**
 * @brief Initializes the bridged socket device.
 * @param srlbuf     Pointer to buffer to use with serial device.
 * @param buflen    Length of the buffer in bytes.
 * @return @b true if bridged socket created successfully, @b false if error
 */
bool bsocket_create(void *srlbuf, size_t buflen);

/**
 * @brief Attempts to open a bridged connection to the host/port specified.
 * @param host    The hostname of the remote server to open a connection to.
 * @param port    The port number to connect to.
 * @return @b true if connection successful, @b false if error
 */
bool bsocket_connect(char *host, uint24_t port);

/// Close the open socket, close the serial device and cleanup the USB subsystem.
bool bsocket_close(void);

/**
 * @brief Alters socket operational parameters after initialization.
 * @param option    An option flag to set. See @b bsocket_option_t.
 * \li SOCKET\_BLOCKING - enable/disable blocking mode
 * \li SOCKET\_TIMEO - timeout (in MS) for blocking mode
 * \li SOCKET\_SET\_CONTROL\_BYTE - change control byte
 * \li SOCKET\_SET\_RELAY\_BYTE - change relay byte
 * @param value      A value to update parameter with. See expected data types below.
 * \li SOCKET\_BLOCKING - [BOOL]
 * \li SOCKET\_TIMEO - [UINT24_T]
 * \li SOCKET\_SET\_CONTROL\_BYTE - [UINT8_T]
 * \li SOCKET\_SET\_RELAY\_BYTE - [UINT8_T]
 * @return @b true if success, @b false if error
 * @warning <b>Do not use blocking sockets until further notice. USB timers not working.</b>
 */
bool bsocket_setoption(bsocket_option_t option, uint24_t value);

/**
 * @brief Sends a packet out the serial device for TCP relay.
 * @note Sent packet format is <b>[relayprefix][size_t][data]</b>. [relayprefix] is stripped by the bridge.
 * @param buffer      Pointer to data to write to the socket.
 * @param len             Length of the data at @b buffer.
 * @return  Number of bytes written to the socket. Should be equal to @b len.
 */
size_t bsocket_send(void *buffer, size_t len);

/**
 * @brief Recieves a packet relayed from the TCP socket to the serial device.
 * @param buffer    Pointer to write the data to.
 * @param len           Number of bytes to read.
 * @return  Number of bytes read. Should be less than or equal to @b len depending on socket block/non-block.
 */
size_t bsocket_recv(void *buffer, size_t len);

/**
 * @brief Sends a command to the bridge.
 * @param directive   A single-byte function code to send to the bridge.
 * \li SOCKET\_STARTTLS
 * \li SOCKET\_ENDTLS
 * @param aad                Additional data to send to the bridge along with the directive.
 * @param aad_len       Length of additional data.
 * @note Directives defined are for the bridge included with this library. If you are using your own bridge you will want to define your own directives.
 */
bool bsocket_emitdirective(bsocket_directives_t directive, void *aad, size_t len);

/// Calls the event handlers for the USB subsystem. For asnyc use processing transfers and events in code.
void bsocket_update(void);


