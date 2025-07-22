module fm_demod(
    input           clk             ,
    input           rst             ,
    //解调参数
    input           i_valid         ,
    input [15:0]    i_data_i        ,
    input [15:0]    i_data_q        ,
    output reg          o_rdy       ,
    output reg [23:0]   o_data    

);
    reg [23:0] data;
    wire            fm_valid          ;
    wire [23:0]     fm_i              ;
    wire [23:0]     fm_q              ;

    wire            fm_rdy            ;
    wire [47 : 0]   m_axis_dout_tdata ;
    wire [23:0]     fm_phase          ;  
    //AM 解调

    assign fm_valid     = i_valid                        ;
    assign fm_i         = {{8{i_data_i[15]}},i_data_i}   ;
    assign fm_q         = {{8{i_data_q[15]}},i_data_q}   ;           
   
    cordic_translate cordic_translate (
        .aclk                     (clk                      ),                                        // input wire aclk
        .s_axis_cartesian_tvalid  (fm_valid                 ),  // input wire s_axis_cartesian_tvalid
        .s_axis_cartesian_tdata   ({fm_i,fm_q}              ),    // input wire [47 : 0] s_axis_cartesian_tdata
        .m_axis_dout_tvalid       (fm_rdy                   ),            // output wire m_axis_dout_tvalid
        .m_axis_dout_tdata        (m_axis_dout_tdata        )              // output wire [47 : 0] m_axis_dout_tdata
    );

    reg [23:0] fm_phase_d;

    assign fm_phase = m_axis_dout_tdata[24 +:24];
    always @(posedge clk)begin
        if(rst)begin
            o_rdy       <= 0;
            o_data      <= 0;
            o_data      <= 0;
        end
        else begin
            o_rdy       <= fm_rdy;
            fm_phase_d  <= fm_phase[23:0];
            o_data <= ($signed(fm_phase - fm_phase_d) > $signed(24'h200000) || 
                    $signed(fm_phase - fm_phase_d) < $signed(24'hE00000)) ? 
                    o_data:(fm_phase - fm_phase_d);
            data <= fm_phase - fm_phase_d;
        end
    end
        
endmodule

