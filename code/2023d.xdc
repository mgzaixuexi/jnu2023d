#####set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets D0_clk_50m_xout/inst/clk_in1_clk_50MHz_Xout] 
# 在.xdc文件中添加以下约束
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets u_clk_wiz_0/inst/clk_in1_clk_wiz_0]
create_clock -period 20.000 -name sys_clk [get_ports sys_clk]

set_property -dict {PACKAGE_PIN C2 IOSTANDARD LVCMOS33} [get_ports sys_clk]
 
set_property -dict {PACKAGE_PIN AD19 IOSTANDARD LVCMOS33} [get_ports sys_rst_n]

set_property -dict {PACKAGE_PIN AF20 IOSTANDARD LVCMOS33} [get_ports key[0]]
set_property -dict {PACKAGE_PIN AE20 IOSTANDARD LVCMOS33} [get_ports key[1]]
set_property -dict {PACKAGE_PIN AE21 IOSTANDARD LVCMOS33} [get_ports key[2]]

set_property -dict {PACKAGE_PIN W14  IOSTANDARD LVCMOS33} [get_ports seg_sel[0]]
set_property -dict {PACKAGE_PIN W15  IOSTANDARD LVCMOS33} [get_ports seg_sel[1]]
set_property -dict {PACKAGE_PIN Y15  IOSTANDARD LVCMOS33} [get_ports seg_sel[2]]
set_property -dict {PACKAGE_PIN AC16 IOSTANDARD LVCMOS33} [get_ports seg_sel[3]]
set_property -dict {PACKAGE_PIN AF22 IOSTANDARD LVCMOS33} [get_ports seg_sel[4]]  

set_property -dict {PACKAGE_PIN U14  IOSTANDARD LVCMOS33} [get_ports seg_led[0]]
set_property -dict {PACKAGE_PIN R16  IOSTANDARD LVCMOS33} [get_ports seg_led[1]]
set_property -dict {PACKAGE_PIN N16  IOSTANDARD LVCMOS33} [get_ports seg_led[2]]
set_property -dict {PACKAGE_PIN U15  IOSTANDARD LVCMOS33} [get_ports seg_led[3]]
set_property -dict {PACKAGE_PIN T14  IOSTANDARD LVCMOS33} [get_ports seg_led[4]] 
set_property -dict {PACKAGE_PIN T15  IOSTANDARD LVCMOS33} [get_ports seg_led[5]]
set_property -dict {PACKAGE_PIN V14  IOSTANDARD LVCMOS33} [get_ports seg_led[6]]
set_property -dict {PACKAGE_PIN P16  IOSTANDARD LVCMOS33} [get_ports seg_led[7]] 

####------DAC J1
set_property -dict {PACKAGE_PIN B1  IOSTANDARD LVCMOS33} [get_ports da_clk]
set_property -dict {PACKAGE_PIN F7  IOSTANDARD LVCMOS33} [get_ports da_data[0]]
set_property -dict {PACKAGE_PIN D6  IOSTANDARD LVCMOS33} [get_ports da_data[1]]
set_property -dict {PACKAGE_PIN A5  IOSTANDARD LVCMOS33} [get_ports da_data[2]]
set_property -dict {PACKAGE_PIN B5  IOSTANDARD LVCMOS33} [get_ports da_data[3]]
set_property -dict {PACKAGE_PIN A4  IOSTANDARD LVCMOS33} [get_ports da_data[4]] 
set_property -dict {PACKAGE_PIN B4  IOSTANDARD LVCMOS33} [get_ports da_data[5]]
set_property -dict {PACKAGE_PIN A3  IOSTANDARD LVCMOS33} [get_ports da_data[6]]
set_property -dict {PACKAGE_PIN C3  IOSTANDARD LVCMOS33} [get_ports da_data[7]]  
set_property -dict {PACKAGE_PIN A2  IOSTANDARD LVCMOS33} [get_ports da_data[8]]
set_property -dict {PACKAGE_PIN B2  IOSTANDARD LVCMOS33} [get_ports da_data[9]]

####------ADC J5
set_property -dict {PACKAGE_PIN L25  IOSTANDARD LVCMOS33} [get_ports ad_clk]
set_property -dict {PACKAGE_PIN D26  IOSTANDARD LVCMOS33} [get_ports ad_data[0]]
set_property -dict {PACKAGE_PIN D24  IOSTANDARD LVCMOS33} [get_ports ad_data[1]]
set_property -dict {PACKAGE_PIN E26  IOSTANDARD LVCMOS33} [get_ports ad_data[2]]
set_property -dict {PACKAGE_PIN D25  IOSTANDARD LVCMOS33} [get_ports ad_data[3]]
set_property -dict {PACKAGE_PIN F25  IOSTANDARD LVCMOS33} [get_ports ad_data[4]] 
set_property -dict {PACKAGE_PIN E25  IOSTANDARD LVCMOS33} [get_ports ad_data[5]]
set_property -dict {PACKAGE_PIN G25  IOSTANDARD LVCMOS33} [get_ports ad_data[6]]
set_property -dict {PACKAGE_PIN G26  IOSTANDARD LVCMOS33} [get_ports ad_data[7]]  
set_property -dict {PACKAGE_PIN J25  IOSTANDARD LVCMOS33} [get_ports ad_data[8]]
set_property -dict {PACKAGE_PIN H26  IOSTANDARD LVCMOS33} [get_ports ad_data[9]]
set_property -dict {PACKAGE_PIN K25  IOSTANDARD LVCMOS33} [get_ports ad_otr]