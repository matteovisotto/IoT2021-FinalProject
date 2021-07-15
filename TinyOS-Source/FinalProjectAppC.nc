
#include "FinalProject.h"
#define NEW_PRINTF_SEMANTICS
#include "printf.h"

configuration FinalProjectAppC {}
implementation {
  components MainC, FinalProjectC as App;
  components new AMSenderC(AM_RADIO_COUNT_MSG);
  components new AMReceiverC(AM_RADIO_COUNT_MSG);
  components new TimerMilliC();
  components SerialStartC;
   components PrintfC;
  components ActiveMessageC;
  
  App.Boot -> MainC.Boot;
  
  App.Receive -> AMReceiverC;
  App.AMSend -> AMSenderC;
  App.AMControl -> ActiveMessageC;
  App.MilliTimer -> TimerMilliC;
  App.Packet -> AMSenderC;
}


