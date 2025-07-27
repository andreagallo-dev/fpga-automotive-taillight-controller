## Clock
set_property -dict { PACKAGE_PIN E3    IOSTANDARD LVCMOS33 } [get_ports CLK100MHZ];
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports CLK100MHZ];

## Buttuns
set_property -dict { PACKAGE_PIN N17   IOSTANDARD LVCMOS33 } [get_ports BTNC];      #Brake buttun
set_property -dict { PACKAGE_PIN M17   IOSTANDARD LVCMOS33 } [get_ports rst];       #Reset buttun
set_property -dict { PACKAGE_PIN M18   IOSTANDARD LVCMOS33 } [get_ports BTNU];      #Emergency buttun
set_property -dict { PACKAGE_PIN P17   IOSTANDARD LVCMOS33 } [get_ports BTNL];      #Emergency buttun

## Switch 
set_property -dict { PACKAGE_PIN J15   IOSTANDARD LVCMOS33 } [get_ports {swt[0]}];  #Right turn switch
set_property -dict { PACKAGE_PIN L16   IOSTANDARD LVCMOS33 } [get_ports {swt[1]}];
set_property -dict { PACKAGE_PIN M13   IOSTANDARD LVCMOS33 } [get_ports {swt[2]}];
set_property -dict { PACKAGE_PIN R15   IOSTANDARD LVCMOS33 } [get_ports {swt[3]}];
set_property -dict { PACKAGE_PIN R17   IOSTANDARD LVCMOS33 } [get_ports {swt[4]}];
set_property -dict { PACKAGE_PIN T18   IOSTANDARD LVCMOS33 } [get_ports {swt[5]}];
set_property -dict { PACKAGE_PIN U18   IOSTANDARD LVCMOS33 } [get_ports {swt[6]}];
set_property -dict { PACKAGE_PIN R13   IOSTANDARD LVCMOS33 } [get_ports {swt[7]}];  #Four wat switch
set_property -dict { PACKAGE_PIN T8    IOSTANDARD LVCMOS33 } [get_ports {swt[8]}];  #Reverse switch
set_property -dict { PACKAGE_PIN U8    IOSTANDARD LVCMOS33 } [get_ports {swt[9]}];
set_property -dict { PACKAGE_PIN R16   IOSTANDARD LVCMOS33 } [get_ports {swt[10]}];
set_property -dict { PACKAGE_PIN T13   IOSTANDARD LVCMOS33 } [get_ports {swt[11]}];
set_property -dict { PACKAGE_PIN H6    IOSTANDARD LVCMOS33 } [get_ports {swt[12]}];
set_property -dict { PACKAGE_PIN U12   IOSTANDARD LVCMOS33 } [get_ports {swt[13]}];
set_property -dict { PACKAGE_PIN U11   IOSTANDARD LVCMOS33 } [get_ports {swt[14]}];
set_property -dict { PACKAGE_PIN V10   IOSTANDARD LVCMOS33 } [get_ports {swt[15]}]; #Left turn switch

## LED 
set_property -dict { PACKAGE_PIN H17   IOSTANDARD LVCMOS33 } [get_ports {led[0]}];  #Right brake
set_property -dict { PACKAGE_PIN K15   IOSTANDARD LVCMOS33 } [get_ports {led[1]}];  #Right turn
set_property -dict { PACKAGE_PIN J13   IOSTANDARD LVCMOS33 } [get_ports {led[2]}];
set_property -dict { PACKAGE_PIN N14   IOSTANDARD LVCMOS33 } [get_ports {led[3]}];
set_property -dict { PACKAGE_PIN R18   IOSTANDARD LVCMOS33 } [get_ports {led[4]}];
set_property -dict { PACKAGE_PIN V17   IOSTANDARD LVCMOS33 } [get_ports {led[5]}];
set_property -dict { PACKAGE_PIN U17   IOSTANDARD LVCMOS33 } [get_ports {led[6]}];  # Reverse
set_property -dict { PACKAGE_PIN U16   IOSTANDARD LVCMOS33 } [get_ports {led[7]}];  # Central brake
set_property -dict { PACKAGE_PIN V16   IOSTANDARD LVCMOS33 } [get_ports {led[8]}];
set_property -dict { PACKAGE_PIN T15   IOSTANDARD LVCMOS33 } [get_ports {led[9]}];
set_property -dict { PACKAGE_PIN U14   IOSTANDARD LVCMOS33 } [get_ports {led[10]}];
set_property -dict { PACKAGE_PIN T16   IOSTANDARD LVCMOS33 } [get_ports {led[11]}];
set_property -dict { PACKAGE_PIN V15   IOSTANDARD LVCMOS33 } [get_ports {led[12]}];
set_property -dict { PACKAGE_PIN V14   IOSTANDARD LVCMOS33 } [get_ports {led[13]}];
set_property -dict { PACKAGE_PIN V12   IOSTANDARD LVCMOS33 } [get_ports {led[14]}]; #Left turn
set_property -dict { PACKAGE_PIN V11   IOSTANDARD LVCMOS33 } [get_ports {led[15]}]; #Left brake 

## 7-segment display
set_property -dict { PACKAGE_PIN T10   IOSTANDARD LVCMOS33 } [get_ports {segments[0]}];
set_property -dict { PACKAGE_PIN R10   IOSTANDARD LVCMOS33 } [get_ports {segments[1]}];
set_property -dict { PACKAGE_PIN K16   IOSTANDARD LVCMOS33 } [get_ports {segments[2]}];
set_property -dict { PACKAGE_PIN K13   IOSTANDARD LVCMOS33 } [get_ports {segments[3]}];
set_property -dict { PACKAGE_PIN P15   IOSTANDARD LVCMOS33 } [get_ports {segments[4]}];
set_property -dict { PACKAGE_PIN T11   IOSTANDARD LVCMOS33 } [get_ports {segments[5]}];
set_property -dict { PACKAGE_PIN L18   IOSTANDARD LVCMOS33 } [get_ports {segments[6]}];
set_property -dict { PACKAGE_PIN J17   IOSTANDARD LVCMOS33 } [get_ports {AN[0]}];
set_property -dict { PACKAGE_PIN J18   IOSTANDARD LVCMOS33 } [get_ports {AN[1]}];
set_property -dict { PACKAGE_PIN T9    IOSTANDARD LVCMOS33 } [get_ports {AN[2]}];
set_property -dict { PACKAGE_PIN J14   IOSTANDARD LVCMOS33 } [get_ports {AN[3]}];
set_property -dict { PACKAGE_PIN P14   IOSTANDARD LVCMOS33 } [get_ports {AN[4]}];
set_property -dict { PACKAGE_PIN T14   IOSTANDARD LVCMOS33 } [get_ports {AN[5]}];
set_property -dict { PACKAGE_PIN K2    IOSTANDARD LVCMOS33 } [get_ports {AN[6]}];
set_property -dict { PACKAGE_PIN U13   IOSTANDARD LVCMOS33 } [get_ports {AN[7]}];