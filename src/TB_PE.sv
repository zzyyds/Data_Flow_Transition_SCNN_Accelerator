`timescale 1ns/100ps
`include "sys_defs.svh"

module TB_PE();
logic clk, rst;
Conv_filter_Parameter Conv_filter_Parameter_TB;
logic [`max_num_channel-1:0][$clog2(`max_size_output)-1:0] num_of_compressed_data;
Dram_TB Dram_TB_in;
logic signed[`max_num_K-1:0][`max_compressed_data-1:0][15:0] I_OARAM_S_0_TB;
logic signed[`max_num_K-1:0][`max_compressed_data-1:0][15:0] I_OARAM_S_0_TB;//SPARSE
logic signed[`max_num_K-1:0][`max_compressed_data-1:0][15:0] I_OARAM_S_1_TB;//SPARSE
logic [`max_num_K-1:0][`max_compressed_data-1:0][`bits_of_indices-1:0] I_OARAM_S_Indices_0_TB;//SPARSE
logic [`max_num_K-1:0][`max_compressed_data-1:0][`bits_of_indices-1:0] I_OARAM_S_Indices_1_TB;//SPARSE
PE PE_TB(
    .clk(clk),
    .rst(rst),
    .Conv_filter_Parameter_TB(Conv_filter_Parameter_TB),
    .num_of_compressed_data(num_of_compressed_data),
    .Dram_TB_in(Dram_TB_in),

    .I_OARAM_S_0_TB(I_OARAM_S_0_TB),//SPARSE
    .I_OARAM_S_1_TB(I_OARAM_S_1_TB),//SPARSE
    .I_OARAM_S_Indices_0_TB(I_OARAM_S_Indices_0_TB),//SPARSE
    .I_OARAM_S_Indices_1_TB(I_OARAM_S_Indices_1_TB)//SPARSE
);



always begin
    #5;
    clk=~clk;
end
initial begin
    clk='d0;
    rst='d1;
    //Stream_filter_finish=1'b0;
    PPU_finish_en='d0;
    Dram_TB_in='d0;
    num_of_compressed_data='d0;
   // Stream_input_finish_PE='d0;
    //Dram_Weight_in='d0;
    Conv_filter_Parameter_TB.k_Conv_Boundary[0]=4;// k' if there is remainder for k/kc, need to care, but for alextnet, may not need to care 
    for (int i=0;i<`max_num_K_prime;i++)begin
        Conv_filter_Parameter_TB.w_Conv_Boundary[0][i]=6+i;//rewrite
    end

    
    Conv_filter_Parameter_TB.c_Conv_Boundary[0]=3;
    //Conv_filter_Parameter_TB.a_Conv_Boundary[0]=10;
    //Conv_filter_Parameter_TB.num_of_compressed_weight[0]=4;
    Conv_filter_Parameter_TB.valid_channel[0]='d0;; //valid channel for each layer
    Conv_filter_Parameter_TB.data_flow_channel[0]='d0;
    Conv_filter_Parameter_TB.valid_channel[0]='b 111; //valid channel for each layer
    Conv_filter_Parameter_TB.data_flow_channel[0]='b 111;
    //Dram_IARAM_in='d0;


    Conv_filter_Parameter_TB.Size_of_R[0]='d5;
    Conv_filter_Parameter_TB.Size_of_S[0]='d5;
    Conv_filter_Parameter_TB.Size_of_W[0]='d21;
    Conv_filter_Parameter_TB.Size_of_H[0]='d21;//8PE
    PPU_OARAM_in='d0;
    for(int i=0;i<3;i++)begin
        for(int j=0;j<20;j++)begin
            Dram_TB_in.MEM_activations_compressed[i][j]=j+2;
            Dram_TB_in.MEM_activations_indices[i][j]=j;

        end
    end
    for(int i=0;i<Conv_filter_Parameter_TB.k_Conv_Boundary[0];i++)begin
        for(int j=0;j<Conv_filter_Parameter_TB.w_Conv_Boundary[0][0];j++)begin
            Dram_TB_in.MEM_weight_compressed[i][j]=j+1;
            Dram_TB_in.MEM_weight_indices[i][j]=j;

        end
    end
    for(int i =0;i<`max_num_channel;i++)begin
        num_of_compressed_data[i]=16+4*i;

    end
    @(negedge clk);
    rst='d0;
    // @(posedge clk);// state=1
    // for(int i =0;i<`num_of_data_Dram;i++)begin
    //     Dram_IARAM_in.data[i]=i;
    //     Dram_IARAM_in.indices[i]=i+1;
    //     Dram_IARAM_in.valid[i]=1'b1;
    // end
    // @(posedge clk);
    // for(int i =0;i<`num_of_data_Dram;i++)begin
    //     Dram_IARAM_in.data[i]=i*2;
    //     Dram_IARAM_in.indices[i]=i+1;
    //     Dram_IARAM_in.valid[i]=1'b1;
    // end
   // Stream_input_finish_PE='d1;
     @(posedge clk);
    // for(int i =0;i<`num_of_data_Dram;i++)begin//Dram_Weight_in.dense=0
    //     Dram_Weight_in.data[i]=i*2;
    //     Dram_Weight_in.indices[i]=i+1;
    //     Dram_Weight_in.valid[i]=1'b1;
    // end
    @(posedge clk);
    // for(int i =0;i<`num_of_data_Dram;i++)begin//Dram_Weight_in.dense=0
    //     Dram_Weight_in='d0;
    // end

    @(posedge clk);
       // Stream_input_finish_PE=1'b0;
    
        // Stream_filter_finish=1'b1;

    for (int i=0;i<100;i++)begin
        @(negedge clk);
       // Stream_filter_finish=1'b0;
    end
    @(negedge clk);
    @(negedge clk);
    @(negedge clk);
    @(posedge clk);
        for(int i =0;i<`num_of_outputs_PPU;i++)begin
            PPU_OARAM_in.valid[i]=1'b1;
            PPU_OARAM_in.output_data[i]=i;
            PPU_OARAM_in.output_indices[i]=i;
        end
    @(posedge clk);
        for(int i =0;i<`num_of_outputs_PPU;i++)begin
            PPU_OARAM_in.valid[i]=1'b1;
            PPU_OARAM_in.output_data[i]=i+1;
            PPU_OARAM_in.output_indices[i]=i+1;
        end
        // for(int i =0;i<`num_of_outputs_PPU;i++)begin
        //     Dram_Weight_in.data[i]=i;
        //     Dram_Weight_in.indices[i]=i+1;
        //     Dram_Weight_in.valid[i]=1'b1;
        // end
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