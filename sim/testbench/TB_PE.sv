`timescale 1ns/100ps
//`include "sys_defs.svh"

module TB_PE();

logic clk, rst;
Conv_filter_Parameter Conv_filter_Parameter_TB;
logic [`max_num_channel-1:0][$clog2(`max_size_output)-1:0] num_of_compressed_data;
Dram_TB Dram_TB_in;

logic signed[`max_num_K-1:0][`max_compressed_data-1:0][15:0] I_OARAM_S_0_TB;//SPARSE
logic signed[`max_num_K-1:0][`max_compressed_data-1:0][15:0] I_OARAM_S_1_TB;//SPARSE
logic [`max_num_K-1:0][`max_compressed_data-1:0][`bits_of_indices-1:0] I_OARAM_S_Indices_0_TB;//SPARSE
logic [`max_num_K-1:0][`max_compressed_data-1:0][`bits_of_indices-1:0] I_OARAM_S_Indices_1_TB;//SPARSE

logic signed[15:0] filter [100 -1:0 ];
logic signed[15:0] data [439-1:0];
logic [3:0] data_index [439-1:0];
logic [3:0]filter_index[100 -1:0 ];
logic signed[15:0] filter_dense [484-1:0 ];
logic signed[15:0] data_dense [1458-1:0];
int clk_cnt=0;
logic [$clog2(5)-1:0]state;
MUL_COORD_OUT tb;
State_of_PE  PE_state_out_tb;

Compress_OARAM out_tb;

Dram_IARAM Dram_IARAM_out;
Dram_Weight Dram_Weight_out;
Dram_IARAM_indices Dram_IARAM_indices_out;
 Dram_Weight_indices Dram_Weight_indices_out;
logic Stream_filter_finish;//From Top, Response_Stream_Complete packet
logic Stream_input_finish_PE;

Req_Stream Req_Stream_PE_tb;




parameter N=$clog2(`max_num_Wt*`max_num_Ht)+2;
pipeline pipeline_TB(
    .clk(clk),
    .rst(rst),
    .Conv_filter_Parameter_TB(Conv_filter_Parameter_TB),
    .num_of_compressed_data(num_of_compressed_data),

    .Dram_IARAM_out(Dram_IARAM_out),
    .Dram_Weight_out(Dram_Weight_out),
    .Dram_IARAM_indices_out(Dram_IARAM_indices_out),
    .Dram_Weight_indices_out(Dram_Weight_indices_out),
    .Stream_filter_finish(Stream_filter_finish),//From Top, Response_Stream_Complete packet
    .Stream_input_finish_PE(Stream_input_finish_PE),
    
    .I_OARAM_S_0_TB(I_OARAM_S_0_TB),//SPARSE
    .I_OARAM_S_1_TB(I_OARAM_S_1_TB),//SPARSE
    .I_OARAM_S_Indices_0_TB(I_OARAM_S_Indices_0_TB),//SPARSE
    .I_OARAM_S_Indices_1_TB(I_OARAM_S_Indices_1_TB),//SPARSE
    .state(state),
    .tb(tb),
    .PE_state_out_tb(PE_state_out_tb),
    .Req_Stream_PE_tb(Req_Stream_PE_tb),
    .out_tb(out_tb)
);
MEM DRAM_MEM_Simple(
    .clk(clk),
    .rst(rst),
    .Req_Stream_PE(Req_Stream_PE_tb),
    .PE_state_in(PE_state_out_tb),
    .Dram_TB_in(Dram_TB_in),//need add
    .Conv_filter_Parameter_TB(Conv_filter_Parameter_TB),
    .num_of_compressed_data(num_of_compressed_data),

    .Dram_IARAM_out(Dram_IARAM_out),
    .Dram_Weight_out(Dram_Weight_out),
    .Dram_IARAM_indices_out(Dram_IARAM_indices_out),
    .Dram_Weight_indices_out(Dram_Weight_indices_out),
    .Stream_filter_finish(Stream_filter_finish),//From Top, Response_Stream_Complete packet
    .Stream_input_finish_PE(Stream_input_finish_PE)
);



always begin
    #5;
    clk=~clk;
end

int k=0;
int q=0;
int a=0;
int s=0;
integer  out_data;
int sum;
int out_indices;
int k_0;
int k_1;
initial begin

    $readmemh("compressed_filters.txt", filter);
    $readmemb("indices_filters_b.txt", filter_index);
    $readmemh("compressed_input_activations.txt", data);
    $readmemb("indices_input_activations_b.txt", data_index);

    $readmemh("dense_filters.txt", filter_dense);
    $readmemh("dense_input_activations.txt", data_dense);
    out_data = $fopen("out_data.txt","w");
out_indices = $fopen("out_indices.txt","w");
    k_0 = $fopen("k_0.txt","w");
    k_1 = $fopen("k_1.txt","w");
    Dram_TB_in='d0;
    clk='d0;
    rst=1'b1;
    Dram_TB_in='d0;
Conv_filter_Parameter_TB=0;
Conv_filter_Parameter_TB.k_Conv_Boundary[0]=`max_num_K_prime;
// for(int i=0;i<`max_num_K_prime:i++)begin//K/Kc
//     for(int j=0;j<`max_num_channel;j++)begin
//         Conv_filter_Parameter_TB.w_Conv_Boundary[0][i][j]=;
//     ende
// end


Conv_filter_Parameter_TB.Size_of_H[0]=27;
Conv_filter_Parameter_TB.Size_of_W[0]=27;
Conv_filter_Parameter_TB.Size_of_S[0]=11;
Conv_filter_Parameter_TB.Size_of_R[0]=11;
Conv_filter_Parameter_TB.w_Conv_Boundary[0][0][0]=50;
Conv_filter_Parameter_TB.w_Conv_Boundary[0][0][1]=50;

Conv_filter_Parameter_TB.w_Conv_Boundary[0][1][0]=50;
Conv_filter_Parameter_TB.w_Conv_Boundary[0][1][1]=50;
Conv_filter_Parameter_TB.c_Conv_Boundary[0]=2;
Conv_filter_Parameter_TB.data_flow_channel[0]='b10;
Conv_filter_Parameter_TB.data_flow_channel[1]='b11;
Conv_filter_Parameter_TB.each_filter_size[0]=11*11;
Conv_filter_Parameter_TB.Conv_size_output_Boundary[0]=17;
Conv_filter_Parameter_TB.pooling_size_Boundary[0]= Conv_filter_Parameter_TB.Conv_size_output_Boundary[0];
 
Conv_filter_Parameter_TB.stage_pooling_Boundary [0] =0; 
Conv_filter_Parameter_TB.stage_pooling_Boundary [1] ='d8; 
Conv_filter_Parameter_TB.stage_pooling_Boundary [2] ='d16; 
Conv_filter_Parameter_TB.stride_conv[0]='d1;

num_of_compressed_data[0]='d219;
num_of_compressed_data[1]='d220;
num_of_compressed_data[2]='d0;
Dram_TB_in =0;
Dram_TB_in.size_of_activations_dense=Conv_filter_Parameter_TB.Size_of_H[0]*Conv_filter_Parameter_TB.Size_of_W[0];
Dram_TB_in.size_of_Kc_Weights_dense[0]=`Kc*Conv_filter_Parameter_TB.Size_of_S[0]*Conv_filter_Parameter_TB.Size_of_R[0];
@(negedge clk);
for(int i=0;i<`Kc;i++)begin
Conv_filter_Parameter_TB.offset_dense_weight[0][i]=i*Conv_filter_Parameter_TB.each_filter_size[0];

end
for (int j=0; j<3; j++)begin
    for (int i=0; i<`max_compressed_data; i++) begin 
        if(i<num_of_compressed_data[j])begin

        Dram_TB_in.MEM_activations_compressed[j][i]=data[k];
        Dram_TB_in.MEM_activations_indices[j][i]=data_index[k] ;
        k=k+1;          
    end
end
end
for (int j=0; j<3; j++)begin
    for (int i=0; i<Dram_TB_in.size_of_activations_dense; i++) begin 

        Dram_TB_in.MEM_activations_Dense[j][i]=data_dense[a];

        a=a+1;
    end

end

    for (int j=0; j<`max_num_K_prime; j++)begin

            for(int y=0;y<`Kc*`max_size_R*`max_size_R-1;y++)begin
                if(y<Conv_filter_Parameter_TB.w_Conv_Boundary[0][j][0])begin
                Dram_TB_in.MEM_weight_compressed[0][j][0][y]=filter[q] ; 
                Dram_TB_in.MEM_weight_compressed[0][j][1][y]=filter[q] ;
                Dram_TB_in.MEM_weight_indices[0][j][0][y]=filter_index[q]  ;
                Dram_TB_in.MEM_weight_indices[0][j][1][y]=filter_index[q]  ;
                q=q+1;  

                end

            end
       
    //end
    end
    for (int j=0; j<`max_num_K_prime; j++)begin

            for(int y=0;y<`Kc*`max_size_R*`max_size_R;y++)begin
                if(y<Dram_TB_in.size_of_Kc_Weights_dense[0])begin
                Dram_TB_in.MEM_weight_dense[0][j][0][y]=filter_dense[s] ; 
                Dram_TB_in.MEM_weight_dense[0][j][1][y]=filter_dense[s] ;

                s=s+1;  

                end

            end
       
    //end
    end
@(negedge clk);
    rst=1'b0;

    // $display("N:",N);

    forever begin
        @(negedge clk);
        clk_cnt=clk_cnt+1'b1;
        for(int i=0; i<`I * `F;i++) begin
        if(out_tb.valid[i])begin//&&PE_state_out_tb.Current_c=='d0
        $fwrite(out_data,"%d\n",out_tb.output_data[i]);
        $fwrite(out_indices,"%d\n",out_tb.output_indices[i]);
        end
        end  
        for(int i=0; i<`I * `F;i++) begin
        if(tb.valid[i] && PE_state_out_tb.Current_k=='d0)begin//&&PE_state_out_tb.Current_c=='d0
        $fwrite(k_0,"%d\n",tb.output_data[i]);

        end
        end 
        for(int i=0; i<`I * `F;i++) begin
        if(tb.valid[i] && PE_state_out_tb.Current_k=='d1)begin//&&PE_state_out_tb.Current_c=='d0
        $fwrite(k_1,"%d\n",tb.output_data[i]);

        end
        end 



        if(state=='d4)begin
            break;
        end

    end
@(negedge clk);
// $display("sum:",sum);
@(negedge clk);
    $fclose(out_data);
    $fclose(out_indices);
        $fclose(k_0);
    $fclose(k_1);

$finish;
end
endmodule

