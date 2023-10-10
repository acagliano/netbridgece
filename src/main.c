/*
 *--------------------------------------
 * Program Name:
 * Author:
 * License:
 * Description:
 *--------------------------------------
*/

#include <srldrvce.h>
#include <usbdrvce.h>

#include <debug.h>
#include <keypadc.h>
#include <stdbool.h>
#include <string.h>
#include <tice.h>

enum _connstate {
  CSTATE_NO_DEVICE,
  CSTATE_USB_UP,
  CSTATE_SRL_UP,
  CSTATE_RELAY_UP
};

struct bsocket {
  srl_device_t dev_srl;
  usb_device_t *dev_usb;
  void (*update)();
  uint8_t connstate;
  struct {
    bool blocking;
    uint24_t timeo;
    bool prefix_size;
    void *misc_headers;
    size_t misc_headers_len;} sockopts;
  struct {bool connected;} remote;
  uint8_t buffer[1024];
};
struct bsocket bs;
bool bsock_timeout = false;

static usb_error_t timeout_action(usb_timer_t *timer){
  bsock_timeout = true;
  return USB_SUCCESS;
}

static usb_error_t handle_usb_event(usb_event_t event, void *event_data,
                                    usb_callback_data_t *callback_data __attribute__((unused))) {
  usb_error_t err;
  /* Delegate to srl USB callback */
  if ((err = srl_UsbEventCallback(event, event_data, callback_data)) != USB_SUCCESS)
    return err;
  
  /* Enable newly connected devices */
  switch(event){
    case USB_DEVICE_CONNECTED_EVENT:
      if (!(usb_GetRole() & USB_ROLE_DEVICE)){
        if(bs.connstate == CSTATE_SRL_UP) return USB_SUCCESS;
        bs.dev_usb = event_data;
        usb_ResetDevice(bs.dev_usb);
      }
      return USB_SUCCESS;
      break;
    case USB_HOST_CONFIGURE_EVENT:
    {
      usb_device_t host = usb_FindDevice(NULL, NULL, USB_SKIP_HUBS);
      if(host) bs.dev_usb = host;
      goto serial_open;
      // break;
    }
    case USB_DEVICE_RESUMED_EVENT:
    case USB_DEVICE_ENABLED_EVENT:
      bs.dev_usb = event_data;
    serial_open:
      if(srl_Open(&bs.dev_srl, bs.dev_usb, bs.buffer, sizeof(bs.buffer), SRL_INTERFACE_ANY, 9600)==SRL_SUCCESS) bs.connstate = CSTATE_SRL_UP;
      return USB_SUCCESS;
      break;
    case USB_DEVICE_SUSPENDED_EVENT:
    case USB_DEVICE_DISABLED_EVENT:
    case USB_DEVICE_DISCONNECTED_EVENT:
      srl_Close(&bs.dev_srl);
      bs.connstate = CSTATE_NO_DEVICE;
      return USB_SUCCESS;
      
  }
  return USB_SUCCESS;
}

bool bsocket_create(void){
  const usb_standard_descriptors_t *desc = srl_GetCDCStandardDescriptors();
  usb_error_t usb_error = usb_Init(handle_usb_event, NULL, desc, USB_DEFAULT_INIT_FLAGS);
  uint8_t hs_resp = 0;
  if(usb_error) return NULL;
  bs.connstate != CSTATE_USB_UP;
  do {
    usb_HandleEvents();
    if(bs.connstate == CSTATE_SRL_UP)
      if(srl_Read(&bs.dev_srl, &hs_resp, 1))
        if(hs_resp == 0xBC) bs.connstate == CSTATE_RELAY_UP;
  } while(bs.connstate != CSTATE_RELAY_UP);
  if(bs.connstate != CSTATE_RELAY_UP) return false;
  bs.update = usb_HandleEvents;
  bs.sockopts.blocking = false;
  bs.sockopts.timeo = 0;
  bs.sockopts.prefix_size = true;
  bs.sockopts.misc_headers = NULL;
  bs.sockopts.misc_headers_len = 0;
  return true;
}

bool bsocket_connect(char *host, uint24_t port){
  uint8_t ctl_byte = 0xBC;
  uint8_t in_buf[2];
  usb_timer_t timer;
  timer.handler = timeout_action;
  size_t bytes_read = 0;
  size_t packet_size = strlen(host) + sizeof(ctl_byte) + sizeof(port) + 1;
  srl_Write(&bs.dev_srl, &packet_size, sizeof(packet_size));
  srl_Write(&bs.dev_srl, &ctl_byte, 1);
  srl_Write(&bs.dev_srl, host, strlen(host)+1);
  srl_Write(&bs.dev_srl, &port, sizeof(port));
  bsock_timeout = false;
  usb_StartTimerMs(&timer, bs.sockopts.timeo);
  do {
    usb_HandleEvents();
    bytes_read += srl_Read(&bs.dev_srl, &in_buf[bytes_read], 2-bytes_read);
    if(bytes_read == 2) break;
  } while (!bsock_timeout);
  usb_StopTimer(&timer);
  if(in_buf[0] == 0xBC) {
    bs.remote.connected = in_buf[1];
    return bs.remote.connected;
  }
  else return false;
}


bool bsocket_close(void){
  srl_Close(&bs.dev_srl);
  usb_Cleanup();
  memset(&bs, 0, sizeof(bs));
}

typedef enum _sockoptflags {
  SOCKET_BLOCKING,
  SOCKET_TIMEO,
  SOCKET_PREFIX_SIZE,
  SOCKET_SET_MISC_HEADERS,
  SOCKET_SET_MISC_HEADERS_LEN
} bsocket_option_t;
bool bsocket_setoption(bsocket_option_t option, uint24_t value){
  switch(option){
    case SOCKET_BLOCKING:
      bs.sockopts.blocking = (bool)value;
      break;
    case SOCKET_TIMEO:
      bs.sockopts.timeo = value;
      break;
    case SOCKET_PREFIX_SIZE:
      bs.sockopts.prefix_size = (bool)value;
      break;
    case SOCKET_SET_MISC_HEADERS:
      bs.sockopts.misc_headers = (void*)value;
      break;
    case SOCKET_SET_MISC_HEADERS_LEN:
      bs.sockopts.misc_headers_len = (size_t)value;
      break;
    default:
      return false;
  }
  return true;
}


size_t bsocket_send(void *buffer, size_t len){
  if(bs.sockopts.prefix_size) srl_Write(&bs.dev_srl, &len, sizeof(len));
  if(bs.sockopts.misc_headers) {
    srl_Write(&bs.dev_srl,
              &bs.sockopts.misc_headers_len,
              sizeof(bs.sockopts.misc_headers_len));
    srl_Write(&bs.dev_srl,
              bs.sockopts.misc_headers,
              bs.sockopts.misc_headers_len);
  }
  return srl_Write(&bs.dev_srl, buffer, len);
}

size_t bsocket_recv(void *buffer, size_t len){
  size_t bytes_read = 0;
  usb_timer_t timer;
  timer.handler = timeout_action;
  bsock_timeout = false;
  usb_StartTimerMs(&timer, bs.sockopts.timeo);
  do {
    usb_HandleEvents();
    srl_Read(&bs.dev_srl, &buffer[bytes_read], len-bytes_read);
    if(bytes_read == len) break;
  } while(!bsock_timeout);
  usb_StopTimer(&timer);
  return bytes_read;
}

int main(void) {
}
