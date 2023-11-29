`timescale 1ns/100ps
`include "sys_defs.svh"

module TB_PE();

logic clk, rst;
Conv_filter_Parameter Conv_filter_Parameter_TB;
logic [`max_num_channel-1:0][$clog2(`max_size_output)-1:0] num_of_compressed_data;
Dram_TB Dram_TB_in;

logic signed[`max_num_K-1:0][`max_compressed_data-1:0][15:0] I_OARAM_S_0_TB;//SPARSE
logic signed[`max_num_K-1:0][`max_compressed_data-1:0][15:0] I_OARAM_S_1_TB;//SPARSE
logic [`max_num_K-1:0][`max_compressed_data-1:0][`bits_of_indices-1:0] I_OARAM_S_Indices_0_TB;//SPARSE
logic [`max_num_K-1:0][`max_compressed_data-1:0][`bits_of_indices-1:0] I_OARAM_S_Indices_1_TB;//SPARSE

logic signed[15:0] filter [`max_size_S *`max_size_S -1:0 ];
logic signed[15:0] data [`max_num_Wt*`max_num_Wt-1:0];
logic [3:0] data_index [`max_num_Wt*`max_num_Wt-1:0];
logic [3:0]filter_index[`max_size_S *`max_size_S -1:0 ];
int clk_cnt=0;
logic [$clog2(5)-1:0]state;
PE PE_TB(
    .clk(clk),
    .rst(rst),
    .Conv_filter_Parameter_TB(Conv_filter_Parameter_TB),
    .num_of_compressed_data(num_of_compressed_data),
    .Dram_TB_in(Dram_TB_in),
    
    .I_OARAM_S_0_TB(I_OARAM_S_0_TB),//SPARSE
    .I_OARAM_S_1_TB(I_OARAM_S_1_TB),//SPARSE
    .I_OARAM_S_Indices_0_TB(I_OARAM_S_Indices_0_TB),//SPARSE
    .I_OARAM_S_Indices_1_TB(I_OARAM_S_Indices_1_TB),//SPARSE
    .state(state)
);



always begin
    #5;
    clk=~clk;
end

int k=0;
int q=0;
initial begin
    // $readmemb("compressed_filters.txt", filter);
    // $readmemb("indices_filters.txt", filter_index);
    // $readmemb("compressed_input_activations.txt", data);
    // $readmemb("indices_input_activations.txt", data_index);
    Dram_TB_in='d0;
    clk='d0;
    rst=1'b1;
    Dram_TB_in='d0;
Conv_filter_Parameter_TB=0;
Conv_filter_Parameter_TB.k_Conv_Boundary[0]=`max_num_K_prime;
// for(int i=0;i<`max_num_K_prime:i++)begin//K/Kc
//     for(int j=0;j<`max_num_channel;j++)begin
//         Conv_filter_Parameter_TB.w_Conv_Boundary[0][i][j]=;
//     end
// end
Conv_filter_Parameter_TB.w_Conv_Boundary[0][0][0]=50;
Conv_filter_Parameter_TB.w_Conv_Boundary[0][0][1]=50;

Conv_filter_Parameter_TB.w_Conv_Boundary[0][1][0]=50;
Conv_filter_Parameter_TB.w_Conv_Boundary[0][1][1]=50;
Conv_filter_Parameter_TB.c_Conv_Boundary[0]=2;
Conv_filter_Parameter_TB.data_flow_channel[0]='b11;
Conv_filter_Parameter_TB.each_filter_size[0]=11*11;
Conv_filter_Parameter_TB.Conv_size_output_Boundary[0]=5;
Conv_filter_Parameter_TB.pooling_size_Boundary[0]= Conv_filter_Parameter_TB.Conv_size_output_Boundary[0];
 
Conv_filter_Parameter_TB.stage_pooling_Boundary [0] =0; 
Conv_filter_Parameter_TB.stage_pooling_Boundary [1] ='d8; 
Conv_filter_Parameter_TB.stage_pooling_Boundary [2] ='d16; 
Conv_filter_Parameter_TB.stride_conv[0]='d4;

for (int j=0; j<3; j++)begin
    for (int i=0; i<`max_compressed_data-1; i++) begin 
    if(i>num_of_compressed_data[j])begin
       break; 
    end
    Dram_TB_in.MEM_activations_compressed[j][i]=data[k];
    Dram_TB_in.MEM_activations_indices[j][i]=data_index[k] ;
    k=k+1;          
    end
end


    for (int j=0; j<`max_num_K_prime-1; j++)begin
        // for (int i=0; i<`max_num_channel-1; i++) begin 
            for(int y=0;y<`Kc*`max_size_R*`max_size_R-1;y++)begin
                if(y>Conv_filter_Parameter_TB.w_Conv_Boundary[0][j][0])begin
                    break;
                end
                Dram_TB_in.MEM_weight_compressed[j][0][y]=filter[q] ; 
                Dram_TB_in.MEM_weight_compressed[j][1][y]=filter[q] ;
                Dram_TB_in.MEM_weight_indices[j][0][y]=filter_index[q]  ;
                Dram_TB_in.MEM_weight_indices[j][1][y]=filter_index[q]  ;
                q=q+1;  
            end
       
    //end
    end

@(negedge clk);
    rst=1'b0;

    forever begin
        @(negedge clk);
        clk_cnt=clk_cnt+1'b1;
        if(state=='d4)begin
            break;
        end

    end
@(negedge clk);
@(negedge clk);
$finish;
end
endmodule

