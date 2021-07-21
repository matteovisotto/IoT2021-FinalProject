
#include "Timer.h"
#include "FinalProject.h"
#include "printf.h"

#define N_MOTES 5

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

  uint16_t packetCounter = 0;
  bool locked;
  uint8_t myId = 0;
  uint8_t motes[N_MOTES];
  uint16_t packets[N_MOTES];
  uint8_t rID;
  uint16_t pID;
  
  event void Boot.booted() {
  	memset(motes, 0, sizeof(motes));
  	memset(packets, 0, sizeof(packets));
  	myId = TOS_NODE_ID;
    call AMControl.start();
  }

  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
    uint16_t freq = 500;
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
	
	  packetCounter++;
      rcm->sender_id = TOS_NODE_ID;
      rcm->packet_id = packetCounter;
      
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
    	
    	pID = rcm->packet_id;
    	rID = rcm->sender_id;
    	
    	if(packets[rID-1] == pID-1 || motes[rID-1] == 0){
    		packets[rID-1] = pID;
    		motes[rID-1]++;
    		if(motes[rID-1] == 10){
    			motes[rID-1] = 0;
    			printf("{\"my_id\":%u, \"other_id\":%u}\n", myId, rID);
    			printfflush();
    		}
    	} else {
    		motes[rID-1] = 1; //The first non-consecutive packet has been received
    		packets[rID-1] = pID; 
    	} 
    	
    	//printf("DEBUG: myID: %u - rID: %u - pID: %u - Last_pID: %u - Counter: %u\n", myId, rID, pID, packets[rID-1], motes[rID-1]);
    	//printfflush();
    	return bufPtr;
    }
  }

  event void AMSend.sendDone(message_t* bufPtr, error_t error) {
    if (&packet == bufPtr) {
      locked = FALSE;
    }
  }

}




