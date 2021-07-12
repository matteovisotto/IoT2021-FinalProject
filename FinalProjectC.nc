
#include "Timer.h"
#include "FinalProject.h"
#include "printf.h"

module FinalProjectC @safe() {
  uses {
    interface Boot;
    interface Receive;
    interface AMSend;
    interface Timer<TMilli> as MilliTimer;
    interface SplitControl as AMControl;
    interface Packet;
  }
}
implementation {

  message_t packet;

  bool locked;
  uint16_t rCounter = 0;
  uint8_t myId = 0;
  
  
  event void Boot.booted() {
  	myId = TOS_NODE_ID;
    call AMControl.start();
    printf("Booted\n");
    printf("Mote id: %u\n", TOS_NODE_ID);
    printfflush();
  }

  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
    uint16_t freq = 500;
    printf("Frequenza: %ld\n", freq);
    printfflush();
    call MilliTimer.startPeriodic(freq);
    }
    else {
      call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t err) {
    // do nothing
  }
  
  event void MilliTimer.fired() {
    if (locked) {
      return;
    }
    else {	
   
      radio_count_msg_t* rcm = (radio_count_msg_t*)call Packet.getPayload(&packet, sizeof(radio_count_msg_t));
      if (rcm == NULL) {
	return;
      }

      rcm->sender_id = TOS_NODE_ID;
      if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(radio_count_msg_t)) == SUCCESS) {
	locked = TRUE;
      }
    }
  }


  event message_t* Receive.receive(message_t* bufPtr, 
				   void* payload, uint8_t len) {
				   
    if (len != sizeof(radio_count_msg_t)){
    	return bufPtr;
    } else {
    	radio_count_msg_t* rcm = (radio_count_msg_t*) payload;
    	rCounter++;
    	printf("Sender ID: %u\n", rcm->sender_id);
    	printfflush();
    	
    	
    	return bufPtr;
    }
  }

  event void AMSend.sendDone(message_t* bufPtr, error_t error) {
    if (&packet == bufPtr) {
      locked = FALSE;
    }
  }

}




