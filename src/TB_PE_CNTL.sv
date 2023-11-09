`timescale 1ns/100ps
`include "sys_defs.svh"
module TB_PE_CNTL();
logic clk,rst,PPU_finish_en,Stream_filter_finish,Stream_input_finish_PE;
logic [`max_num_channel-1:0][$clog2(`max_size_output)-1:0]num_of_compressed_data;
Conv_filter_Parameter Conv_filter_Parameter_TB;
Req_Stream Req_Stream_PE;
parameter PE_num=1;
IARAM_MUL_nx IARAM_MUL_out;
State_of_PE  PE_state_out;
Weight_MUL_nx Weight_MUL_out;
PPU_OARAM PPU_OARAM_in;
Dram_IARAM Dram_IARAM_in;
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
    .Req_Stream_PE(Req_Stream_PE),
    .PE_state_out(PE_state_out)
);

I_OARAM I_OARAM_U0(
    .clk(clk),
    .rst(rst),
    .PE_state_out(PE_state_out),
    .PPU_OARAM_in(PPU_OARAM_in),
    .Dram_IARAM_in(Dram_IARAM_in),

    .IARAM_MUL_out(IARAM_MUL_out),
    .Weight_MUL_out(Weight_MUL_out)
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
    Conv_filter_Parameter_TB.k_Conv_Boundary[0]=4;// k' if there is remainder for k/kc, need to care, but for alextnet, may not need to care 
    Conv_filter_Parameter_TB.w_Conv_Boundary[0]=6;
    Conv_filter_Parameter_TB.c_Conv_Boundary[0]=3;
    //Conv_filter_Parameter_TB.a_Conv_Boundary[0]=10;
    //Conv_filter_Parameter_TB.num_of_compressed_weight[0]=4;
    Conv_filter_Parameter_TB.valid_channel[0]='d0;; //valid channel for each layer
    Conv_filter_Parameter_TB.data_flow_channel[0]='d0;
    Conv_filter_Parameter_TB.valid_channel[0]='b 111; //valid channel for each layer
    Conv_filter_Parameter_TB.data_flow_channel[0]='b 111;
    Dram_IARAM_in='d0;


    Conv_filter_Parameter_TB.Size_of_R[0]='d5;
    Conv_filter_Parameter_TB.Size_of_S[0]='d5;
    Conv_filter_Parameter_TB.Size_of_W[0]='d21;
    Conv_filter_Parameter_TB.Size_of_H[0]='d21;//8PE
    PPU_OARAM_in='d0;
    for(int i =0;i<`max_num_channel;i++)begin
        num_of_compressed_data[i]=16+4*i;

    end
    @(negedge clk);
    rst='d0;
    @(posedge clk);
    for(int i =0;i<`num_of_data_Dram;i++)begin
        Dram_IARAM_in.data[i]=i;
        Dram_IARAM_in.indices[i]=i+1;
        Dram_IARAM_in.valid[i]=1'b1;
    end
    @(posedge clk);
    for(int i =0;i<`num_of_data_Dram;i++)begin
        Dram_IARAM_in.data[i]=i*2;
        Dram_IARAM_in.indices[i]=i+1;
        Dram_IARAM_in.valid[i]=1'b1;
    end
    Stream_input_finish_PE='d1;
   
    @(negedge clk);
        Stream_input_finish_PE=1'b0;
         Stream_filter_finish=1'b1;
    for (int i=0;i<100;i++)begin
        @(negedge clk);
        Stream_filter_finish=1'b0;
    end
    @(negedge clk);
    @(negedge clk);
    @(negedge clk);
    @(negedge clk);
        for(int i =0;i<`num_of_outputs_PPU;i++)begin
            PPU_OARAM_in.valid[i]=1'b1;
            PPU_OARAM_in.output_data[i]=i;
            PPU_OARAM_in.output_indices[i]=i;
        end
    @(negedge clk);
        for(int i =0;i<`num_of_outputs_PPU;i++)begin
            PPU_OARAM_in.valid[i]=1'b1;
            PPU_OARAM_in.output_data[i]=i+1;
            PPU_OARAM_in.output_indices[i]=i+1;
        end
    @(negedge clk);
        PPU_OARAM_in<='d0;
        PPU_finish_en='d1;
    @(negedge clk);

    @(negedge clk);
    




//     @(negedge clk);
//     PPU_finish_en='d1;
//     @(negedge clk);
//     PPU_finish_en='d0;
//     @(negedge clk);
//          Stream_filter_finish=1'b1;
//     for (int i=0;i<5000;i++)begin
//         @(negedge clk);
//         Stream_filter_finish=1'b0;
//     end
//     @(negedge clk);
//     PPU_finish_en='d1;
//     @(negedge clk);
//     PPU_finish_en='d0;
//         @(negedge clk);
//     PPU_finish_en='d0;
//     @(negedge clk);
//          Stream_filter_finish=1'b1;
//     for (int i=0;i<5000;i++)begin
//         @(negedge clk);
//         Stream_filter_finish=1'b0;
//     end
//       @(negedge clk);
//     PPU_finish_en='d1;
//     @(negedge clk);
//     PPU_finish_en='d0;
//     @(negedge clk);
//          Stream_filter_finish=1'b1;
//     for (int i=0;i<5000;i++)begin
//         @(negedge clk);
//         Stream_filter_finish=1'b0;
//     end
//       @(negedge clk);
//     PPU_finish_en='d1;
//     @(negedge clk);
//     PPU_finish_en='d0;
//     @(negedge clk);
//          Stream_filter_finish=1'b1;
//     for (int i=0;i<5000;i++)begin
//         @(negedge clk);
//         Stream_filter_finish=1'b0;
//     end
//       @(negedge clk);
//     PPU_finish_en='d1;
//     @(negedge clk);
//     PPU_finish_en='d0;
//     @(negedge clk);
//          Stream_filter_finish=1'b1;
//     for (int i=0;i<5000;i++)begin
//         @(negedge clk);
//         Stream_filter_finish=1'b0;
//     end
//           @(negedge clk);
//     PPU_finish_en='d1;
//     @(negedge clk);
//     PPU_finish_en='d0;
//     @(negedge clk);
//          Stream_filter_finish=1'b1;
//     for (int i=0;i<5000;i++)begin
//         @(negedge clk);
//         Stream_filter_finish=1'b0;
//     end
//               @(negedge clk);
//     PPU_finish_en='d1;
//     @(negedge clk);
//     PPU_finish_en='d0;
//     @(negedge clk);
//          Stream_filter_finish=1'b1;
//     for (int i=0;i<5000;i++)begin
//         @(negedge clk);
//         Stream_filter_finish=1'b0;
//     end
//         PPU_finish_en='d1;
//     @(negedge clk);
//    @(negedge clk);
//     PPU_finish_en='d0;
//     @(negedge clk);
//          Stream_filter_finish=1'b1;
//     for (int i=0;i<5000;i++)begin
//         @(negedge clk);
//         Stream_filter_finish=1'b0;
//     end
//               @(negedge clk);
//     PPU_finish_en='d1;
//     @(negedge clk);
//     PPU_finish_en='d0;
    @(negedge clk);
    
    $finish;

end
endmodule