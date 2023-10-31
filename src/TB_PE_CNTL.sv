`timescale 1ns/100ps
`include "sys_defs.svh"
module TB_PE_CNTL();
logic clk,rst,PPU_finish_en,Stream_filter_finish,Stream_input_finish_PE;
logic [`max_num_channel-1:0][$clog2(`max_size_output)-1:0]num_of_compressed_data;
Conv_filter_Parameter Conv_filter_Parameter_TB;
Req_Stream Req_Stream_PE;
parameter PE_num=1;
PE_CNTL 
#(.PE_num(PE_num))
PE_CNTL_U0
(
//-------------------Input-------------------------//
    .clk(clk),
    .rst(rst),
    .num_of_compressed_data(num_of_compressed_data),
    .Conv_filter_Parameter_TB(Conv_filter_Parameter_TB),
    .PPU_finish_en(PPU_finish_en),
    .Stream_filter_finish(Stream_filter_finish),
    .Stream_input_finish_PE(Stream_input_finish_PE),

//--------------------output------------------------//
    .Req_Stream_PE(Req_Stream_PE)
);
always begin
    #5;
    clk=~clk;
end
initial begin
    clk='d0;
    rst='d1;
    Stream_filter_finish=1'b0;
    PPU_finish_en='d0;
    num_of_compressed_data='d0;
    Stream_input_finish_PE='d0;
    Conv_filter_Parameter_TB.k_Conv_Boundary=8;
    Conv_filter_Parameter_TB.w_Conv_Boundary=16;
    Conv_filter_Parameter_TB.c_Conv_Boundary=3;
    Conv_filter_Parameter_TB.a_Conv_Boundary=12;
    Conv_filter_Parameter_TB.num_of_compressed_weight=4;
    Conv_filter_Parameter_TB.valid_channel='d0;; //valid channel for each layer
    Conv_filter_Parameter_TB.data_flow_channel='d0;
    Conv_filter_Parameter_TB.valid_channel[0]='b 111; //valid channel for each layer
    Conv_filter_Parameter_TB.data_flow_channel[0]='b 111;

    for(int i =0;i<`max_num_channel;i++)begin
        num_of_compressed_data[i]=16+4*i;

    end
    @(negedge clk);
    rst='d0;
    @(negedge clk);
    Stream_input_finish_PE='d1;
   
    @(negedge clk);
        Stream_input_finish_PE=1'b0;
         Stream_filter_finish=1'b1;
    for (int i=0;i<100;i++)begin
        @(negedge clk);
        Stream_filter_finish=1'b0;
    end
    @(negedge clk);
    PPU_finish_en='d1;
    @(negedge clk);
    PPU_finish_en='d0;
    @(negedge clk);
         Stream_filter_finish=1'b1;
    for (int i=0;i<100;i++)begin
        @(negedge clk);
        Stream_filter_finish=1'b0;
    end
    
    @(negedge clk);
    PPU_finish_en='d1;
    @(negedge clk);
    PPU_finish_en='d0;
        @(negedge clk);
    PPU_finish_en='d0;
    @(negedge clk);
         Stream_filter_finish=1'b1;
    for (int i=0;i<100;i++)begin
        @(negedge clk);
        Stream_filter_finish=1'b0;
    end
      @(negedge clk);
    PPU_finish_en='d1;
    @(negedge clk);
    PPU_finish_en='d0;
    @(negedge clk);
         Stream_filter_finish=1'b1;
    for (int i=0;i<100;i++)begin
        @(negedge clk);
        Stream_filter_finish=1'b0;
    end
      @(negedge clk);
    PPU_finish_en='d1;
    @(negedge clk);
    PPU_finish_en='d0;
    @(negedge clk);
         Stream_filter_finish=1'b1;
    for (int i=0;i<100;i++)begin
        @(negedge clk);
        Stream_filter_finish=1'b0;
    end
      @(negedge clk);
    PPU_finish_en='d1;
    @(negedge clk);
    PPU_finish_en='d0;
    @(negedge clk);
         Stream_filter_finish=1'b1;
    for (int i=0;i<100;i++)begin
        @(negedge clk);
        Stream_filter_finish=1'b0;
    end
          @(negedge clk);
    PPU_finish_en='d1;
    @(negedge clk);
    PPU_finish_en='d0;
    @(negedge clk);
         Stream_filter_finish=1'b1;
    for (int i=0;i<100;i++)begin
        @(negedge clk);
        Stream_filter_finish=1'b0;
    end
              @(negedge clk);
    PPU_finish_en='d1;
    @(negedge clk);
    PPU_finish_en='d0;
    @(negedge clk);
         Stream_filter_finish=1'b1;
    for (int i=0;i<100;i++)begin
        @(negedge clk);
        Stream_filter_finish=1'b0;
    end
        PPU_finish_en='d1;
    @(negedge clk);
        @(negedge clk);
         Stream_filter_finish=1'b1;
    $finish;

end
endmodule