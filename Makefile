CONTIKI_PROJECT = final_project
all: $(CONTIKI_PROJECT)

#UIP_CONF_IPV6=1

CONTIKI = ../..
include $(CONTIKI)/Makefile.include
