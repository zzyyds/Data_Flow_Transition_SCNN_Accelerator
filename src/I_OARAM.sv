
module I_OARAM(
    input clk,
    input rst,
    input State_of_PE  PE_state_out,
    input PPU_OARAM PPU_OARAM_in,
    input Dram_IARAM Dram_IARAM_in,
    input Dram_Weight Dram_Weight_in,
    input Dram_IARAM_indices Dram_IARAM_indices_in,
    input Dram_Weight_indices Dram_Weight_indices_in,
    input busy,
    input PPU_RAM_PACKET PPU_RAM_PACKET_in,

    output IARAM_MUL_nx IARAM_MUL_out,
    output logic signed[`max_num_K-1:0][`max_compressed_data-1:0][15:0] I_OARAM_S_0_TB,//SPARSE
    output logic signed[`max_num_K-1:0][`max_compressed_data-1:0][15:0] I_OARAM_S_1_TB,//SPARSE
    output logic [`max_num_K-1:0][`max_compressed_data-1:0][`bits_of_indices-1:0] I_OARAM_S_Indices_0_TB,//SPARSE
    output logic [`max_num_K-1:0][`max_compressed_data-1:0][`bits_of_indices-1:0] I_OARAM_S_Indices_1_TB,//SPARSE
    output Weight_MUL_nx Weight_MUL_out,
    output logic [`max_num_channel-1:0][$clog2(`max_size_output)-1:0] num_of_compressed_data_PPU_out


);

logic [`max_num_channel-1:0][$clog2(`max_size_output)-1:0] nx_num_of_compressed_data_PPU;

IARAM_MUL_nx nx_IARAM_MUL_out_0;
IARAM_MUL_nx nx_IARAM_MUL_out_1;

//IARAM_MUL_nx IARAM_MUL_out;
//Weight_MUL_nx nx_Weight_MUL_out;
logic [`max_num_K_prime-1:0][$clog2(`max_compressed_data)-1:0] ptr_OARAM, nx_ptr_OARAM; 
logic [$clog2(`max_num_Wt*`max_num_Ht)-1:0] nx_remain_a;
logic [$clog2(`Kc*`max_num_R*`max_num_S):0] nx_remain_w;
logic Which_IARAM;// 0 for I_OARAM_S_0, 1 for I_OARAM_S_1
logic signed[`max_num_K-1:0][`max_compressed_data-1:0][15:0] I_OARAM_S_0;//SPARSE
logic signed[`max_num_K-1:0][`max_compressed_data-1:0][15:0] I_OARAM_S_1;//SPARSE
logic[`max_num_K-1:0][`max_compressed_data-1:0][`bits_of_indices-1:0] I_OARAM_S_Indices_0;//SPARSE
logic[`max_num_K-1:0][`max_compressed_data-1:0][`bits_of_indices-1:0] I_OARAM_S_Indices_1;//SPARSE


logic[`max_num_K-1:0][`max_compressed_data-1:0][15:0] nx_OARAM_data,nx_IARAM_data_stream;//SPARSE
logic[`max_num_K-1:0][`max_compressed_data-1:0][`bits_of_indices-1:0] nx_OARAM_Indices, nx_IARAM_Indices_stream;//SPARSE

logic [3-1:0][$clog2(`max_compressed_data)-1:0] ptr_IARAM_stream, nx_ptr_IARAM_stream; 
logic [3-1:0][$clog2(`max_compressed_data)-1:0] ptr_IARAM_stream_indices, nx_ptr_IARAM_stream_indices; 
//------------------------------Weight--------------------------------------------//
logic signed [`max_size_R*`max_size_R-1:0][15:0] Weight_Buffer,nx_Weight_Buffer;//SPARSE
logic[`max_size_R*`max_size_R-1:0][3:0] Weight_Indices,nx_Weight_Indices;//SPARSE
logic signed[`max_size_R*`max_size_R-1:0][15:0] Weight_Buffer_Dense,nx_Weight_Buffer_Dense;
logic[`max_size_R*`max_size_R-1:0] ptr_weight_stream,nx_ptr_weight_stream;
logic[`max_size_R*`max_size_R-1:0] ptr_weight_stream_indices,nx_ptr_weight_stream_indices;
logic[`max_size_R*`max_size_R-1:0] ptr_weight_PPU,nx_ptr_weight_PPU;
logic[`max_size_R*`max_size_R-1:0] ptr_weight_PPU_indices,nx_ptr_weight_PPU_indices;
logic[$clog2(`Kc*`max_num_R*`max_num_S):0] Weight_Buffer_S_index;//w
logic[$clog2(`max_num_Wt*`max_num_Ht)-1:0]  IARAM_S_index;//a
assign Which_IARAM=PE_state_out.Current_Conv_Layer[0];//even =0, odd =1;
assign Weight_Buffer_S_index=(PE_state_out.Current_w==0)?0:PE_state_out.Current_w+1'b1;
assign IARAM_S_index=(PE_state_out.Current_a==0)?0:PE_state_out.Current_a+1'b1;
assign  nx_num_of_compressed_data_PPU[PPU_RAM_PACKET_in.which_channel]=PPU_RAM_PACKET_in.valid?PPU_RAM_PACKET_in.which_channel:nx_num_of_compressed_data_PPU[PPU_RAM_PACKET_in.which_channel];
always_comb begin
    IARAM_MUL_out='d0;
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
    nx_Weight_Buffer=Weight_Buffer;
    nx_Weight_Indices=Weight_Indices;
    nx_ptr_weight_stream=ptr_weight_stream;
    nx_ptr_weight_PPU=ptr_weight_PPU;
    nx_ptr_IARAM_stream_indices=ptr_IARAM_stream_indices;
    nx_ptr_weight_stream_indices=ptr_weight_stream_indices;
    nx_ptr_weight_PPU_indices=ptr_weight_PPU_indices;
    if(!busy)begin
         if(PE_state_out.state=='d1)begin
        nx_ptr_OARAM='d0;
        nx_ptr_weight_PPU='d0;
//--------------------------------------------------inputs---------------------------------------------------//
        if(Dram_IARAM_in.dense)begin//Dense
           // 

        end
        else begin//Sparse
            for(int i=0;i<`num_of_data_Dram;i++)begin
                if(Dram_IARAM_in.valid[i])begin
                    nx_IARAM_data_stream[Dram_IARAM_in.input_channel][nx_ptr_IARAM_stream[Dram_IARAM_in.input_channel]]=Dram_IARAM_in.data[i];
                   // nx_IARAM_Indices_stream[Dram_IARAM_in.input_channel][nx_ptr_IARAM_stream[Dram_IARAM_in.input_channel]]=Dram_IARAM_in.indices[i];
                    nx_ptr_IARAM_stream[Dram_IARAM_in.input_channel]=nx_ptr_IARAM_stream[Dram_IARAM_in.input_channel]+1'b1;
                end
                else begin
                    nx_IARAM_data_stream=nx_IARAM_data_stream;
                   // nx_IARAM_Indices_stream=nx_IARAM_Indices_stream;
                    nx_ptr_IARAM_stream=nx_ptr_IARAM_stream;
                end
            end
        //    Dram_IARAM_indices_in

            for(int i=0;i<`num_of_data_Dram;i++)begin
                if(Dram_IARAM_indices_in.valid[i])begin
                    nx_IARAM_Indices_stream[Dram_IARAM_indices_in.input_channel][nx_ptr_IARAM_stream_indices[Dram_IARAM_indices_in.input_channel]]=Dram_IARAM_indices_in.indices[i];
                    nx_ptr_IARAM_stream_indices[Dram_IARAM_indices_in.input_channel]=nx_ptr_IARAM_stream_indices[Dram_IARAM_indices_in.input_channel]+1'b1;
                end
                else begin
                    nx_IARAM_Indices_stream=nx_IARAM_Indices_stream;
                    nx_ptr_IARAM_stream_indices=nx_ptr_IARAM_stream_indices;
                end
            end
        end
//-------------------------------------------------Weight---------------------------------------------------//
        if(Dram_Weight_in.dense)begin//Dense
           // 

        end
        else begin //Sparse
            for(int i=0;i<`num_of_data_Dram;i++)begin
                if(Dram_Weight_in.valid[i])begin
                    nx_Weight_Buffer[nx_ptr_weight_stream]=Dram_Weight_in.data[i];
                    //nx_Weight_Indices[nx_ptr_weight_stream]=Dram_Weight_in.indices[i];
                    nx_ptr_weight_stream=nx_ptr_weight_stream+1;
                end
                else begin
                    nx_Weight_Buffer[nx_ptr_weight_stream]=nx_Weight_Buffer[nx_ptr_weight_stream];
                    nx_ptr_weight_stream=nx_ptr_weight_stream;                
                end
            end

        end

        for(int i=0;i<`num_of_data_Dram;i++)begin
            if(Dram_Weight_indices_in.valid[i])begin
                nx_Weight_Indices[nx_ptr_weight_stream]=Dram_Weight_indices_in.indices[i];
                nx_ptr_weight_stream_indices=nx_ptr_weight_stream_indices+1'b1;
            end
            else begin
                nx_Weight_Indices=nx_Weight_Indices;
                nx_ptr_weight_stream_indices=nx_ptr_weight_stream_indices;                
            end
        end
    end
    else if(PE_state_out.state=='d2)begin
        nx_ptr_IARAM_stream='d0;
        nx_ptr_OARAM='d0;
        nx_ptr_weight_stream='d0;
        nx_ptr_IARAM_stream_indices='d0;
        nx_ptr_weight_stream_indices='d0;
        nx_ptr_weight_PPU_indices='d0;
        if(PE_state_out.data_flow_channel[PE_state_out.Current_Conv_Layer][PE_state_out.Current_c])begin//Sparse
            for(int i=0;i<`I;i++)begin
                nx_IARAM_MUL_out_0.IRAM_data[i]=I_OARAM_S_0[PE_state_out.Current_c][IARAM_S_index+i];
            end
            for(int i=0;i<`I;i++)begin
                nx_IARAM_MUL_out_1.IRAM_data[i]=I_OARAM_S_1[PE_state_out.Current_c][IARAM_S_index+i];
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
                Weight_MUL_out.Weight_data[i]=Weight_Buffer[Weight_Buffer_S_index+i];
                Weight_MUL_out.indices[i]=Weight_Indices[Weight_Buffer_S_index+i];
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
        nx_ptr_weight_stream='d0;
        for(int i=0;i<`num_of_outputs_PPU;i++)begin
            if(PPU_OARAM_in.valid[i])begin
                nx_OARAM_data[PE_state_out.Current_k*`Kc+PPU_OARAM_in.feature_map_channel][nx_ptr_OARAM[PPU_OARAM_in.feature_map_channel]]=PPU_OARAM_in.output_data[i];
                nx_OARAM_Indices[PE_state_out.Current_k*`Kc+PPU_OARAM_in.feature_map_channel][nx_ptr_OARAM[PPU_OARAM_in.feature_map_channel]]=PPU_OARAM_in.output_indices[i];
                nx_ptr_OARAM[PPU_OARAM_in.feature_map_channel]=nx_ptr_OARAM[PPU_OARAM_in.feature_map_channel]+1'b1;
            end
            else begin
                nx_OARAM_data=nx_OARAM_data;
                nx_OARAM_Indices=nx_OARAM_Indices;
                nx_ptr_OARAM=nx_ptr_OARAM;
            end
        end

        if(Dram_Weight_in.dense)begin//Dense
           // 

        end
        else begin //Sparse
            for(int i=0;i<`num_of_data_Dram;i++)begin
                if(Dram_Weight_in.valid[i])begin
                    nx_Weight_Buffer[nx_ptr_weight_PPU]=Dram_Weight_in.data[i];
                    nx_ptr_weight_PPU=nx_ptr_weight_PPU+1;
                end
                else begin
                    nx_Weight_Buffer[nx_ptr_weight_PPU]=nx_Weight_Buffer[nx_ptr_weight_PPU];
                    nx_ptr_weight_PPU=nx_ptr_weight_PPU;                
                end
            end
        end

        

        for(int i=0;i<`num_of_data_Dram;i++)begin
            if(Dram_Weight_indices_in.valid[i])begin
                nx_Weight_Indices[nx_ptr_weight_PPU_indices]=Dram_Weight_indices_in.indices[i];
                nx_ptr_weight_PPU_indices=nx_ptr_weight_PPU_indices+1;
            end
            else begin
                nx_Weight_Buffer=nx_Weight_Buffer;
                nx_ptr_weight_PPU_indices=nx_ptr_weight_PPU_indices;                
            end
        end
    end


    end



end

always_ff@(posedge clk)begin
    if(rst)begin
        I_OARAM_S_0<=#1 'd0;//SPARSE
        I_OARAM_S_1<=#1 'd0;//SPARSE
        I_OARAM_S_Indices_0<=#1 'd0;//SPARSE
        I_OARAM_S_Indices_1<=#1 'd0;//SPARSE
        Weight_Buffer<=#1 'd0;
        Weight_Indices<=#1 'd0;
        ptr_OARAM<=#1 'd0;
        ptr_IARAM_stream<=#1 'd0;

        Weight_Buffer_Dense<=#1 'd0;
        ptr_weight_stream<=#1 'd0;
        ptr_weight_PPU<=#1 'd0;
        ptr_IARAM_stream_indices<=#1 'd0;
        ptr_weight_stream_indices<=#1 'd0;
        ptr_weight_PPU_indices<=#1 'd0;
        num_of_compressed_data_PPU_out<=#1 'd0;
    end
    else begin
        num_of_compressed_data_PPU_out<=#1 nx_num_of_compressed_data_PPU;
        ptr_IARAM_stream<=#1 nx_ptr_IARAM_stream;
        ptr_OARAM<=#1 nx_ptr_OARAM;
        ptr_weight_stream<=#1 nx_ptr_weight_stream;
        Weight_Buffer<=#1 nx_Weight_Buffer;
        Weight_Indices<=#1 nx_Weight_Indices;
        ptr_weight_PPU<=#1 nx_ptr_weight_PPU;
        Weight_Buffer_Dense<=#1 nx_Weight_Buffer_Dense;
        ptr_IARAM_stream_indices<=#1 nx_ptr_IARAM_stream_indices;
        ptr_weight_stream_indices<=#1 nx_ptr_weight_stream_indices;
        ptr_weight_PPU_indices<=#1 nx_ptr_weight_PPU_indices;
        if(PE_state_out.state=='d1)begin
            if(Which_IARAM)begin
                I_OARAM_S_1<=#1 nx_IARAM_data_stream;
                I_OARAM_S_0<=#1 I_OARAM_S_0;

                I_OARAM_S_Indices_1<=#1 nx_IARAM_Indices_stream;//SPARSE
                I_OARAM_S_Indices_0<=#1 I_OARAM_S_Indices_0;
            end
            else begin
                I_OARAM_S_0<=#1 nx_IARAM_data_stream;
                I_OARAM_S_1<=#1 I_OARAM_S_1; 

                I_OARAM_S_Indices_0<=#1 nx_IARAM_Indices_stream;//SPARSE
                I_OARAM_S_Indices_1<=#1 I_OARAM_S_Indices_1;

            end
        end
        else if(PE_state_out.state=='d3)begin
            if(Which_IARAM)begin
                I_OARAM_S_0<=#1 nx_OARAM_data;
                I_OARAM_S_1<=#1 I_OARAM_S_1;

                I_OARAM_S_Indices_0<=#1 nx_OARAM_Indices;//SPARSE
                I_OARAM_S_Indices_1<=#1 I_OARAM_S_Indices_1;
            end
            else begin
                I_OARAM_S_1<=#1 nx_OARAM_data;
                I_OARAM_S_0<=#1 I_OARAM_S_0; 

                I_OARAM_S_Indices_1<=#1 nx_OARAM_Indices;//SPARSE
                I_OARAM_S_Indices_0<=#1 I_OARAM_S_Indices_0;

            end
        end
        else begin
            I_OARAM_S_0<=#1 I_OARAM_S_0;
            I_OARAM_S_1<=#1 I_OARAM_S_1;
            I_OARAM_S_Indices_0<=#1 I_OARAM_S_Indices_0;
            I_OARAM_S_Indices_1<=#1 I_OARAM_S_Indices_1;

        end
    end

end

endmodule