module MEM(
    input clk,
    input rst,
    input Req_Stream Req_Stream_PE,
    input State_of_PE  PE_state_in,
    input Dram_TB Dram_TB_in,
    input Conv_filter_Parameter Conv_filter_Parameter_TB,
    input [`max_num_channel-1:0][$clog2(`max_size_output)-1:0]num_of_compressed_data,

    output Dram_IARAM Dram_IARAM_out,
    output Dram_Weight Dram_Weight_out,
    output Dram_IARAM_indices Dram_IARAM_indices_out,
    output Dram_Weight_indices Dram_Weight_indices_out,
    output logic Stream_filter_finish,//From Top, Response_Stream_Complete packet
    output logic Stream_input_finish_PE
);

Dram_IARAM nx_Dram_IARAM_out;
Dram_Weight nx_Dram_Weight_out;
Dram_IARAM_indices nx_Dram_IARAM_indices_out;
Dram_Weight_indices nx_Dram_Weight_indices_out;
logic signed[2:0][`max_compressed_data-1:0][15:0] MEM_activations_compressed;
logic signed[2:0][`max_compressed_data-1:0][`bits_of_indices-1:0] MEM_activations_indices;
logic signed[`num_of_Conv_Layer:0][`max_num_K_prime-1:0][`Kc*`max_size_R*`max_size_S-1:0][15:0]  MEM_weight_compressed;
logic signed[`num_of_Conv_Layer:0][`max_num_K_prime-1:0][`Kc*`max_size_R*`max_size_S-1:0][`bits_of_indices-1:0] MEM_weight_indices;
//logic signed[`max_num_K-1:0][`max_size_R*`max_size_S-1:0][15:0]  MEM_weight_dense;
parameter IDLE='d0, Stream_activations_compressed='d1, Stream_activations_indices='d2, Stream_activations_dense='d3,state_MEM_weight_compressed='d4, state_MEM_weight_indices='d5,state_MEM_weight_dense='d6, N=7;
logic [$clog2(N)-1:0] state,nx_state;

logic[$clog2(`max_num_Wt*`max_num_Ht)-1:0] nx_remain_activations;
logic [$clog2(`Kc*`max_num_R*`max_num_S)-1:0] nx_remain_weight;

logic[$clog2(3)-1:0] current_channel_activations,nx_current_channel_activations;
logic[$clog2(`max_num_Wt*`max_num_Ht)-1:0] current_activations,nx_current_activations;
logic[$clog2(`max_size_R*`max_size_S)-1:0]current_weight_ptr,nx_current_weight_ptr;


always_ff@(posedge clk)begin
    if(rst)begin
        MEM_activations_compressed<=#1 Dram_TB_in.MEM_activations_compressed;
        MEM_activations_indices<=#1 Dram_TB_in.MEM_activations_indices;
        MEM_weight_compressed<=#1 Dram_TB_in.MEM_weight_compressed;
        MEM_weight_indices<=#1 Dram_TB_in.MEM_weight_indices;
       // MEM_weight_dense<=#1 Dram_TB_in.MEM_weight_dense;
        state<=#1 'd0;
        current_channel_activations<=#1 'd0;
        current_activations<=#1 'd0;
        current_weight_ptr<=#1 'd0;
        Dram_IARAM_out<=#1 'd0;
        Dram_Weight_out<=#1 'd0;
        Dram_IARAM_indices_out<=#1 'd0;
        Dram_Weight_indices_out<=#1 'd0;
    end
    else begin
        MEM_activations_compressed<=#1 MEM_activations_compressed;
        MEM_activations_indices<=#1 MEM_activations_indices;
        MEM_weight_compressed<=#1 MEM_weight_compressed;
        MEM_weight_indices<=#1 MEM_weight_indices;
        state<=#1 nx_state;
        current_channel_activations<=#1 nx_current_channel_activations;
        current_activations<=#1 nx_current_activations;
        current_weight_ptr<=#1 nx_current_weight_ptr;
        Dram_IARAM_out<=#1 nx_Dram_IARAM_out;
        Dram_Weight_out<=#1 nx_Dram_Weight_out;
        Dram_IARAM_indices_out<=#1 nx_Dram_IARAM_indices_out;
        Dram_Weight_indices_out<=#1 nx_Dram_Weight_indices_out;
    end

end
always_comb begin
    nx_Dram_IARAM_out='d0;
    nx_Dram_Weight_out='d0;
    nx_Dram_IARAM_indices_out='d0;
    nx_Dram_Weight_indices_out='d0;
    nx_current_channel_activations=current_channel_activations;
    nx_current_activations=current_activations;
    Stream_input_finish_PE='d0;
    Stream_filter_finish='d0;
    nx_current_weight_ptr=current_weight_ptr;
    nx_remain_activations=num_of_compressed_data[current_channel_activations]-current_activations;
    nx_remain_weight=Conv_filter_Parameter_TB.w_Conv_Boundary[PE_state_in.Current_Conv_Layer][PE_state_in.Current_k]-current_weight_ptr;
    case(state)
        IDLE:
            begin
                if(PE_state_in.Current_k==0 &&PE_state_in.Current_Conv_Layer==0&&Req_Stream_PE.Req_Stream_input_valid)begin
                    nx_state=Stream_activations_compressed;
                end
                else if(Req_Stream_PE.Req_Stream_filter_valid)begin
                    nx_state=MEM_weight_compressed;
                end
                else begin
                    nx_state=IDLE;
                end

            end
        
        Stream_activations_compressed:
            begin
                    nx_Dram_IARAM_out.dense='d0;
                    for(int i=0;i<`num_of_data_Dram;i++)begin
                        nx_Dram_IARAM_out.valid[i]=1'b1;
                        nx_Dram_IARAM_out.data[i]=MEM_activations_compressed[nx_current_channel_activations][nx_current_activations];
                        nx_Dram_IARAM_out.input_channel=nx_current_channel_activations;
                        nx_current_activations=nx_current_activations+1'b1;
                        nx_remain_activations=nx_remain_activations-1'b1;
                        if(nx_remain_activations==0)begin
                            nx_current_activations='d0;
                            // if(current_channel_activations==Conv_filter_Parameter_TB.c_Conv_Boundary[PE_state_in.Current_Conv_Layer]-1'b1)begin
                            //     nx_current_channel_activations='d0;  
                            //     nx_state= Stream_activations_indices;// to the activation dense
                            // end
                            // else begin
                            //     nx_current_channel_activations=nx_current_channel_activations+1'b1;
                            //     nx_state=Stream_activations_compressed;
                            // end
                            nx_state=Stream_activations_indices;
                            break;
                        end
                    end
                end    
        
        Stream_activations_indices:
            begin
                for(int i=0;i<`num_of_data_Dram;i++)begin
                        nx_Dram_IARAM_indices_out.valid[i]=1'b1;
                        nx_Dram_IARAM_indices_out.indices[i]=MEM_activations_compressed[nx_current_channel_activations][nx_current_activations];
                        nx_Dram_IARAM_indices_out.input_channel=nx_current_channel_activations;
                        nx_current_activations=nx_current_activations+1'b1;
                        nx_remain_activations=nx_remain_activations-1'b1;
                        if(nx_remain_activations==0)begin
                            nx_current_activations='d0;
                            if(current_channel_activations==Conv_filter_Parameter_TB.c_Conv_Boundary[PE_state_in.Current_Conv_Layer]-1'b1)begin
                                nx_current_channel_activations='d0;
                                nx_state= state_MEM_weight_compressed;
                                Stream_input_finish_PE=1'b1;
                            end
                            else begin
                                nx_current_channel_activations=nx_current_channel_activations+1'b1;
                                if(Conv_filter_Parameter_TB.data_flow_channel[PE_state_in.Current_Conv_Layer][nx_current_channel_activations])begin
                                    nx_state=Stream_activations_compressed;
                                end
                                else begin
                                    nx_state=Stream_activations_dense;
                                end   
                            end
                            break;
                        end
                    end
            end
        Stream_activations_dense://add later
            begin


            end

        state_MEM_weight_compressed:
            begin
                for(int i=0;i<`num_of_data_Dram;i++)begin
                    nx_Dram_Weight_out.valid[i]=1'b1;
                    nx_Dram_Weight_out.data[i]=MEM_weight_compressed[PE_state_in.Current_Conv_Layer][PE_state_in.Current_k][nx_current_weight_ptr];
                    nx_current_weight_ptr=nx_current_weight_ptr+1'b1;
                    nx_remain_weight=nx_remain_weight-1'b1;
                    if(nx_remain_weight==0)begin
                        nx_current_weight_ptr='d0;
                        nx_state= state_MEM_weight_indices;
                        break;
                    end
                end
            end
        state_MEM_weight_indices:
            begin
                for(int i=0;i<`num_of_data_Dram;i++)begin
                    nx_Dram_Weight_indices_out.valid[i]=1'b1;
                    nx_Dram_Weight_indices_out.indices[i]=MEM_weight_indices[PE_state_in.Current_Conv_Layer][PE_state_in.Current_k][nx_current_weight_ptr];
                    nx_current_weight_ptr=nx_current_weight_ptr+1'b1;
                    nx_remain_weight=nx_remain_weight-1'b1;
                    if(nx_remain_weight==0)begin
                        nx_current_weight_ptr='d0;
                        nx_state= state_MEM_weight_dense;
                        break;
                    end
                end

            end     
        state_MEM_weight_dense://add later
            begin
                Stream_filter_finish=1'b1;
                nx_state= IDLE;
            end
        default:
            begin
                nx_state= IDLE;
            end
        
              
    endcase
end
endmodule