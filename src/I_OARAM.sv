
module I_OARAM(
    input clk,
    input rst,
    input State_of_PE  PE_state_out,
    input PPU_OARAM PPU_OARAM_in,
    input Dram_IARAM Dram_IARAM_in,

    output IARAM_MUL_nx IARAM_MUL_out,
    output Weight_MUL_nx Weight_MUL_out


);
IARAM_MUL_nx nx_IARAM_MUL_out_0;
IARAM_MUL_nx nx_IARAM_MUL_out_1;
//IARAM_MUL_nx IARAM_MUL_out;
//Weight_MUL_nx nx_Weight_MUL_out;
logic [`max_num_K-1:0][$clog2(`max_compressed_data)-1:0] ptr_OARAM, nx_ptr_OARAM; 
logic [$clog2(`max_num_Wt*`max_num_Ht)-1:0] nx_remain_a;
logic [$clog2(`Kc*`max_num_R*`max_num_S):0] nx_remain_w;
logic Which_IARAM;// 0 for I_OARAM_S_0, 1 for I_OARAM_S_1
logic[`max_num_K-1:0][`max_compressed_data-1:0][15:0] I_OARAM_S_0;//SPARSE
logic[`max_num_K-1:0][`max_compressed_data-1:0][15:0] I_OARAM_S_1;//SPARSE
logic[`max_num_K-1:0][`max_compressed_data-1:0][3:0] I_OARAM_S_Indices_0;//SPARSE
logic[`max_num_K-1:0][`max_compressed_data-1:0][3:0] I_OARAM_S_Indices_1;//SPARSE


logic[`max_num_K-1:0][`max_compressed_data-1:0][15:0] nx_OARAM_data,nx_IARAM_data_stream;//SPARSE
logic[`max_num_K-1:0][`max_compressed_data-1:0][3:0] nx_OARAM_Indices, nx_IARAM_Indices_stream;//SPARSE
logic [`max_num_K-1:0][$clog2(`max_compressed_data)-1:0] ptr_IARAM_stream, nx_ptr_IARAM_stream; 
assign Which_IARAM=PE_state_out.Current_Conv_Layer[0];//even =0, odd =1;
always_comb begin
    nx_IARAM_MUL_out_0='d0;
    nx_IARAM_MUL_out_1='d0;
    Weight_MUL_out='d0;
    nx_remain_a=PE_state_out.remain_a;
    nx_remain_w=PE_state_out.remain_w;
    nx_OARAM_data=Which_IARAM?I_OARAM_S_0:I_OARAM_S_1;
    nx_OARAM_Indices=Which_IARAM?I_OARAM_S_0:I_OARAM_S_1;
    nx_IARAM_Indices_stream=Which_IARAM?I_OARAM_S_1:I_OARAM_S_0;
    nx_IARAM_data_stream=Which_IARAM?I_OARAM_S_1:I_OARAM_S_0;
    nx_ptr_OARAM=ptr_OARAM;
  
    nx_ptr_IARAM_stream=ptr_IARAM_stream;
    if(PE_state_out.state=='d1)begin
        nx_ptr_OARAM='d0;
        for(int i=0;i<`num_of_data_Dram;i++)begin
            if(Dram_IARAM_in.valid[i])begin
                nx_IARAM_data_stream[PE_state_out.Current_k][nx_ptr_IARAM_stream]=Dram_IARAM_in.data[i];
                nx_IARAM_Indices_stream[PE_state_out.Current_k][nx_ptr_IARAM_stream]=Dram_IARAM_in.indices[i];
                nx_ptr_IARAM_stream=nx_ptr_IARAM_stream+1'b1;
            end
            else begin
                nx_IARAM_data_stream[PE_state_out.Current_k][nx_ptr_IARAM_stream]=nx_IARAM_data_stream[PE_state_out.Current_k][nx_ptr_IARAM_stream];
                nx_IARAM_Indices_stream[PE_state_out.Current_k][nx_ptr_IARAM_stream]=nx_IARAM_Indices_stream[PE_state_out.Current_k][nx_ptr_IARAM_stream];
                nx_ptr_IARAM_stream=nx_ptr_IARAM_stream;
            end
        end

    end
    else if(PE_state_out.state=='d2)begin
        nx_ptr_IARAM_stream='d0;
        nx_ptr_OARAM='d0;
        if(PE_state_out.data_flow_channel[PE_state_out.Current_Conv_Layer][PE_state_out.Current_c])begin//Sparse
            for(int i=0;i<`I;i++)begin
                nx_IARAM_MUL_out_0.IRAM_data[i]=I_OARAM_S_0[PE_state_out.Current_k][PE_state_out.Current_a+i];
            end
            for(int i=0;i<`I;i++)begin
                nx_IARAM_MUL_out_1.IRAM_data[i]=I_OARAM_S_1[PE_state_out.Current_k][PE_state_out.Current_a+i];
            end

            if(PE_state_out.Flag_remain_a)begin//valid all 1
                for(int i=0;i<`I;i++)begin
                    nx_IARAM_MUL_out_0.valid[i]=1'b1;
                    nx_IARAM_MUL_out_1.valid[i]=1'b1;
                end
            end
            else begin
                for(int i=0;i<`I;i++)begin

                    if(nx_remain_a==0)begin
                        break;
                    end
                    nx_IARAM_MUL_out_0.valid[i]=1'b1;
                    nx_IARAM_MUL_out_1.valid[i]=1'b1;
                    nx_remain_a=nx_remain_a-1'b1;
                end
            end

            
            for(int i=0;i<`F;i++)begin
                Weight_MUL_out.Weight_data[i]=I_OARAM_S_0[PE_state_out.Current_k][PE_state_out.Current_a+i];
            end

    

            if(PE_state_out.Flag_remain_w)begin//valid all 1
                for(int i=0;i<`I;i++)begin
                    Weight_MUL_out.valid[i]=1'b1;
                end
            end
            else begin
                for(int i=0;i<`I;i++)begin
                    if(nx_remain_w==0)begin
                        break;
                    end
                    Weight_MUL_out.valid[i]=1'b1;
                    nx_remain_w=nx_remain_w-1'b1;
                end
            end

            IARAM_MUL_out=Which_IARAM?nx_IARAM_MUL_out_1:nx_IARAM_MUL_out_0;

        end

        else begin//Dense


        end
    end
    else if(PE_state_out.state=='d3)begin
        nx_ptr_IARAM_stream='d0;
        for(int i=0;i<`num_of_outputs_PPU;i++)begin
            if(PPU_OARAM_in.valid[i])begin
                nx_OARAM_data[PE_state_out.Current_k][nx_ptr_OARAM]=PPU_OARAM_in.output_data[i];
                nx_OARAM_Indices[PE_state_out.Current_k][nx_ptr_OARAM]=PPU_OARAM_in.output_indices[i];
                nx_ptr_OARAM=nx_ptr_OARAM+1'b1;
            end
            else begin
                nx_OARAM_data[PE_state_out.Current_k][nx_ptr_OARAM]=nx_OARAM_data[PE_state_out.Current_k][nx_ptr_OARAM];
                nx_OARAM_Indices[PE_state_out.Current_k][nx_ptr_OARAM]=nx_OARAM_Indices[PE_state_out.Current_k][nx_ptr_OARAM];
                nx_ptr_OARAM=nx_ptr_OARAM;
            end
        end
    end


    else begin


    end
    

end

always_ff@(posedge clk)begin
    if(rst)begin
        I_OARAM_S_0<='d0;//SPARSE
        I_OARAM_S_1<='d0;//SPARSE
        I_OARAM_S_Indices_0<='d0;//SPARSE
        I_OARAM_S_Indices_1<='d0;//SPARSE

        ptr_OARAM<='d0;
        ptr_IARAM_stream<='d0;
    end
    else begin
        ptr_IARAM_stream<=nx_ptr_IARAM_stream;
        ptr_OARAM<=nx_ptr_OARAM;
        if(PE_state_out.state=='d1)begin
            if(Which_IARAM)begin
                I_OARAM_S_0[PE_state_out.Current_k]<=nx_IARAM_data_stream[PE_state_out.Current_k];
                I_OARAM_S_1[PE_state_out.Current_k]<=I_OARAM_S_1[PE_state_out.Current_k];

                I_OARAM_S_Indices_0[PE_state_out.Current_k]<=nx_IARAM_Indices_stream[PE_state_out.Current_k];//SPARSE
                I_OARAM_S_Indices_1[PE_state_out.Current_k]<=I_OARAM_S_Indices_1[PE_state_out.Current_k];
            end
            else begin
                I_OARAM_S_1[PE_state_out.Current_k]<=nx_IARAM_data_stream[PE_state_out.Current_k];
                I_OARAM_S_0[PE_state_out.Current_k]<=I_OARAM_S_0[PE_state_out.Current_k]; 

                I_OARAM_S_Indices_1[PE_state_out.Current_k]<=nx_IARAM_Indices_stream[PE_state_out.Current_k];//SPARSE
                I_OARAM_S_Indices_0[PE_state_out.Current_k]<=I_OARAM_S_Indices_0[PE_state_out.Current_k];

            end
        end
        else if(PE_state_out.state=='d3)begin
            if(Which_IARAM)begin
                I_OARAM_S_0[PE_state_out.Current_k]<=nx_OARAM_data[PE_state_out.Current_k];
                I_OARAM_S_1[PE_state_out.Current_k]<=I_OARAM_S_1[PE_state_out.Current_k];

                I_OARAM_S_Indices_0[PE_state_out.Current_k]<=nx_OARAM_Indices[PE_state_out.Current_k];//SPARSE
                I_OARAM_S_Indices_1[PE_state_out.Current_k]<=I_OARAM_S_Indices_1[PE_state_out.Current_k];
            end
            else begin
                I_OARAM_S_1[PE_state_out.Current_k]<=nx_OARAM_data[PE_state_out.Current_k];
                I_OARAM_S_0[PE_state_out.Current_k]<=I_OARAM_S_0[PE_state_out.Current_k]; 

                I_OARAM_S_Indices_1[PE_state_out.Current_k]<=nx_OARAM_Indices[PE_state_out.Current_k];//SPARSE
                I_OARAM_S_Indices_0[PE_state_out.Current_k]<=I_OARAM_S_Indices_0[PE_state_out.Current_k];

            end
        end
        else begin
            I_OARAM_S_0<=I_OARAM_S_0;
            I_OARAM_S_1<=I_OARAM_S_1;
            I_OARAM_S_Indices_0<=I_OARAM_S_Indices_0;
            I_OARAM_S_Indices_1<=I_OARAM_S_Indices_1;

        end
    end

end

endmodule