`timescale 1ns/100ps
module PE_CNTL
#(parameter PE_num=1)(
//-------------------Input-------------------------//
    input clk,
    input rst,
    //PPU_to_CNTL PPU_to_CNTL_in,
    input [`max_num_channel-1:0][$clog2(`max_size_output)-1:0]num_of_compressed_data,
    input Conv_filter_Parameter Conv_filter_Parameter_TB,
    input PPU_finish_en,
    input Stream_filter_finish,//From Top, Response_Stream_Complete packet
    input Stream_input_finish_PE,
    input [`max_num_channel-1:0][$clog2(`max_size_output)-1:0]num_of_compressed_data_PPU,
    input busy,
    input Xbar_empty,
    input XBAR_Partial_c,

//--------------------output------------------------//
    output Req_Stream Req_Stream_PE,
    //output logic Current_data_flow //calculating indice
    //output logic drain_Accumulator_buffer_en
    output State_of_PE  PE_state_out
);

parameter  N=5, IDLE='d0, Stream_Conv_Layer='d1, Ex_Conv_Layer='d2, Conv_Layer_PPU='d3,Complete='d4;
logic[$clog2(N)-1:0] state, nx_state;
// logic ,reg_Stream_input_finish_PE;
//logic[$clog2(`num_of_Conv_Layer):0][`max_num_channel-1:0] reg_valid_channel;
logic[$clog2(`num_of_Conv_Layer):0][`max_num_channel-1:0] reg_data_flow_channel; 
logic[$clog2(`num_of_Conv_Layer):0] Current_Conv_Layer, nx_Conv_Layer;
logic[$clog2(`max_num_K)-1:0] Current_k, nx_k;
logic[$clog2(`max_num_channel)-1:0] Current_c, nx_c,reg_Current_c;
//---------------------------------For Sparse Data Flow-------------------------------------//
logic[$clog2(`max_num_Wt*`max_num_Ht)-1:0] Current_a, nx_a;
logic[$clog2(`Kc*`max_num_R*`max_num_S):0] Current_w, nx_w;

logic[$clog2(`max_num_K)-1:0] reg_k_Conv_Boundary;
logic[$clog2(`Kc*`max_num_R*`max_num_S):0] reg_w_Conv_Boundary;
logic[$clog2(`max_num_channel)-1:0] reg_c_Conv_Boundary;
logic[$clog2(`max_num_Wt*`max_num_Ht)-1:0] reg_a_Conv_Boundary;
logic [$clog2(`max_num_Wt*`max_num_Ht)-1:0] remain_a;
logic [$clog2(`Kc*`max_num_R*`max_num_S):0] remain_w;
logic Flag_remain_a, Flag_remain_w;
logic Partial_w,reg_Partial_w, Partial_a, reg_Partial_a,Partial_c,reg_Partial_c, Partial_k, reg_Partial_k;
logic reg_Stream_input_finish_PE;
logic reg_Stream_filter_finish;
logic reg_PPU_finish_en;
//---------------------------------For Dense Data Flow-------------------------------------// For easy to debug
logic Partial_R_dense, reg_Partial_R_dense, Partial_S_dense,reg_Partial_S_dense;
logic[`F*`I:0] Partial_H_dense,reg_Partial_H_dense,Partial_W_dense,reg_Partial_W_dense;
logic [`F*`I:0] Partial_H_dense_tb,Partial_W_dense_tb,Partial_H_dense_tb_init,Partial_W_dense_tb_init;
logic[`F*`I:0] dense_WH_pair_valid,reg_dense_WH_pair_valid,dense_WH_pair_valid_init;
logic[`F*`I:0][$clog2(`max_size_W)-1:0]  nx_W_dense_init,nx_W_dense,reg_W_dense;
logic[`F*`I:0][$clog2(`max_size_H)-1:0] nx_H_dense_init,nx_H_dense,reg_H_dense;
logic[$clog2(`max_size_R)-1:0]Current_R_dense, nx_R_dense;//reg_Current_R_dense
logic[$clog2(`max_size_S)-1:0]Current_S_dense, nx_S_dense;//reg_Current_S_dense;
logic[$clog2(`max_size_W)-1:0]Current_W_dense;
logic[$clog2(`max_size_H)-1:0]Current_H_dense;
logic[$clog2(`max_size_W)-1:0] reg_Size_of_W;
logic[$clog2(`max_size_W)-1:0] reg_Size_of_H;
logic[$clog2(`max_size_R):0] reg_Size_of_R;
logic[$clog2(`max_size_S):0] reg_Size_of_S;

// logic Flag_remain_H_dense;
// logic [$clog2(`max_size_W)-1:0] remain_H_dense;
logic[$clog2(`max_stride_conv):0] current_stride_conv;
logic [$clog2(`Kc)-1:0] Current_Kc,nx_Kc;
logic reg_Partial_R_dense_complete,Partial_R_dense_complete;
assign PE_state_out.Current_R_dense=Current_R_dense;
assign PE_state_out.Current_S_dense=Current_S_dense;
assign PE_state_out.Partial_c=reg_Partial_c;
assign PE_state_out.Current_W_dense=reg_W_dense[15:0];
assign PE_state_out.Current_H_dense=reg_H_dense[15:0];
assign PE_state_out.dense_WH_pair_valid=reg_Partial_c?'d0:reg_dense_WH_pair_valid;

assign PE_state_out.Current_k_dense=Current_k;
assign PE_state_out.Current_c_dense=Current_c;
assign PE_state_out.Current_k=Current_k;
assign PE_state_out.Current_c=Current_c;
assign PE_state_out.Current_a=Current_a;
assign PE_state_out.Current_w=Current_w;

assign PE_state_out.Current_Conv_Layer=Current_Conv_Layer;
assign PE_state_out.Current_Kc=Current_Kc;

assign remain_a=reg_a_Conv_Boundary<=(`F-1)?reg_a_Conv_Boundary+1'b1:reg_a_Conv_Boundary-Current_a;
assign remain_w=reg_w_Conv_Boundary<=(`F-1)?reg_w_Conv_Boundary+1'b1:reg_w_Conv_Boundary-Current_w;
assign Flag_remain_a=(remain_a>=`I)?1'b1:1'b0;
assign Flag_remain_w=(remain_w>=`F)?1'b1:1'b0;
assign PE_state_out.remain_a=remain_a;
assign PE_state_out.remain_w=remain_w;
assign PE_state_out.Flag_remain_a=Flag_remain_a;
assign PE_state_out.Flag_remain_w=Flag_remain_w;
// assign remain_H_dense=reg_Size_of_H[Current_Conv_Layer]-Current_H_dense;
// assign Flag_remain_H_dense=(remain_H_dense>=16)?1'b1:1'b0;
// assign PE_state_out.remain_H_dense=remain_H_dense;
// assign PE_state_out.Flag_remain_H_dense=Flag_remain_H_dense;


assign PE_state_out.state=state;
assign PE_state_out.nx_state=nx_state;
assign PE_state_out.next_a=Partial_w&&(reg_Partial_w==0);
assign PE_state_out.nx_c=nx_c;
always_ff@(posedge clk)begin
    if(rst)begin
        state<=#1 'd0;
        reg_Current_c<=#1 'd0;
        Current_Conv_Layer<=#1 'd0;
        Current_k<=#1  'd0;
        Current_c<=#1  'd0;
        Current_a<=#1 'd0;
        Current_w<=#1  'd0;
        reg_data_flow_channel<=#1  'd0;
        //reg_valid_channel<=#1  'd0;
        reg_k_Conv_Boundary<= #1 'd0;
        reg_w_Conv_Boundary<=#1  'd0;
        reg_c_Conv_Boundary<=#1 'd0;
        reg_a_Conv_Boundary<=#1  'd0;
        reg_Partial_k<=#1  'd0;
        reg_Partial_w<= #1 'd0;
        reg_Partial_a<=#1 'd0;
        reg_Partial_c<=#1 'd0;
        reg_Stream_input_finish_PE<=#1 'd0;

        reg_Size_of_W<=#1 'd0;
        reg_Size_of_H<= #1 'd0;
        reg_Size_of_R<=#1 'd0;
        reg_Size_of_S<= #1 'd0;
        Current_R_dense<= #1 'd0;
        Current_S_dense<=#1 'd0;
        Current_W_dense<=#1  'd0;
        Current_H_dense<= #1 'd0;
        reg_Partial_R_dense_complete<=#1 'd0;

        reg_Partial_R_dense<= #1 'd0;
        reg_Partial_S_dense<=#1  'd0;
        reg_Partial_W_dense<=#1  'd0;
        reg_Partial_H_dense<= #1 'd0;
        current_stride_conv<=#1  'd0;
        reg_H_dense<=#1  'd0;
        reg_W_dense<=#1 'd0;
        reg_dense_WH_pair_valid<= #1 'd0;
        Current_Kc<=#1 'd0;
       // drain_Accumulator_buffer_en<=#1 'd0;// aftern entering PPU state
       reg_Stream_filter_finish<=#1 'd0;
       reg_PPU_finish_en<=#1 'd0;
    end
    else begin
        reg_Partial_R_dense_complete<=#1 Partial_R_dense_complete;
        reg_Current_c<= #1 Current_c;
        state<= #1 nx_state;
        Current_Conv_Layer<=#1 nx_Conv_Layer;
        Current_k<=#1 nx_k;
        Current_c<= #1 nx_c;
        Current_a<=#1  nx_a;
        Current_w<=#1  nx_w;
        reg_Partial_k<= #1 Partial_k;
        reg_Partial_w<=#1  Partial_w;
        reg_Partial_a<=#1  Partial_a;
        reg_Partial_c<= #1 Partial_c;
        Current_Kc<=#1 nx_Kc;
        //reg_valid_channel[nx_Conv_Layer]<= #1 Conv_filter_Parameter_TB.valid_channel[nx_Conv_Layer];
        reg_data_flow_channel[nx_Conv_Layer]<= #1 Conv_filter_Parameter_TB.data_flow_channel[nx_Conv_Layer];
        reg_k_Conv_Boundary<= #1 Conv_filter_Parameter_TB.k_Conv_Boundary[nx_Conv_Layer]-1;
        reg_w_Conv_Boundary<= #1 Conv_filter_Parameter_TB.w_Conv_Boundary[nx_Conv_Layer][nx_k][nx_c]-1;//maybe always need compressed version for weight
        reg_c_Conv_Boundary<=#1 Conv_filter_Parameter_TB.c_Conv_Boundary[nx_Conv_Layer]-1;
        current_stride_conv<=#1  Conv_filter_Parameter_TB.stride_conv[nx_Conv_Layer];

        if(nx_Conv_Layer==0)begin
            for(int i=0;i<`max_num_channel;i++)begin
                reg_a_Conv_Boundary<= #1 num_of_compressed_data[nx_c]-1;
            end
        end
        else begin
            for(int i=0;i<`max_num_channel;i++)begin
                reg_a_Conv_Boundary<= #1 num_of_compressed_data_PPU[nx_c]-1;
            end   
        end
        reg_Size_of_W<= #1 Conv_filter_Parameter_TB.Size_of_W[nx_Conv_Layer]-Conv_filter_Parameter_TB.Size_of_R[nx_Conv_Layer];
        reg_Size_of_H<=#1 Conv_filter_Parameter_TB.Size_of_H[nx_Conv_Layer]-Conv_filter_Parameter_TB.Size_of_S[nx_Conv_Layer];
        reg_Size_of_R<= #1 Conv_filter_Parameter_TB.Size_of_R[nx_Conv_Layer]-1;
        reg_Size_of_S<= #1 Conv_filter_Parameter_TB.Size_of_S[nx_Conv_Layer]-1;

        reg_Partial_R_dense<= #1 Partial_R_dense;
        reg_Partial_S_dense<= #1 Partial_S_dense;
        reg_Partial_W_dense<=#1  Partial_W_dense;
        reg_Partial_H_dense<= #1 Partial_H_dense;
        Current_R_dense<=  #1 (nx_state==Ex_Conv_Layer||state==Ex_Conv_Layer)?nx_R_dense:'d0;
        Current_S_dense<= #1  (nx_state==Ex_Conv_Layer||state==Ex_Conv_Layer)?nx_S_dense:'d0;
        Current_W_dense<= #1  (nx_state==Ex_Conv_Layer||state==Ex_Conv_Layer)?nx_W_dense[`F*`I]:'d0;
        Current_H_dense<= #1  (nx_state==Ex_Conv_Layer||state==Ex_Conv_Layer)?nx_H_dense[`F*`I]:'d0;

        if(state==Stream_Conv_Layer)begin
            reg_Stream_input_finish_PE<= #1 Stream_input_finish_PE? 1'b1:reg_Stream_input_finish_PE;
        end
        else begin
            reg_Stream_input_finish_PE<=#1  'd0;
        end
        if(state==Conv_Layer_PPU)begin
            reg_Stream_filter_finish<=#1 Stream_filter_finish?1'b1:reg_Stream_filter_finish;
        end
        else begin
            reg_Stream_filter_finish<=#1 'd0;
        end
        if(state==Conv_Layer_PPU)begin
            reg_PPU_finish_en<=#1 PPU_finish_en?1'b1:reg_PPU_finish_en;
        end
        else begin
            reg_PPU_finish_en<=#1 'd0;
        end
        reg_W_dense<=#1 nx_W_dense;
        reg_H_dense<= #1 nx_H_dense;
        reg_dense_WH_pair_valid<= #1 (nx_state==Ex_Conv_Layer||state==Ex_Conv_Layer)?dense_WH_pair_valid:'d0;
    end
end

always_comb begin
    Partial_R_dense_complete=reg_Partial_R_dense_complete;
    nx_Conv_Layer=Current_Conv_Layer;
    Req_Stream_PE='d0;
    Partial_w=reg_Partial_w;
    Partial_a=reg_Partial_a;
    Partial_c=reg_Partial_c;
    Partial_k=reg_Partial_k;
    nx_k=Current_k;
    nx_c=Current_c;
    nx_a=Current_a;
    nx_w=Current_w;
    nx_R_dense=Current_R_dense;
    nx_S_dense=Current_S_dense;
    // nx_W_dense='d0;
    // nx_H_dense='d0;
    // nx_W_dense[0]=Current_W_dense;
    // nx_H_dense[0]=Current_H_dense;
    nx_H_dense=reg_H_dense;
    nx_W_dense=reg_W_dense;
    Partial_R_dense=reg_Partial_R_dense;
    Partial_S_dense=reg_Partial_S_dense;
    Partial_W_dense=reg_Partial_W_dense;
    Partial_H_dense=reg_Partial_H_dense;
    //PE_state_out.valid_channel[Current_Conv_Layer]=reg_valid_channel[Current_Conv_Layer];
    PE_state_out.data_flow_channel[Current_Conv_Layer]=reg_data_flow_channel[Current_Conv_Layer];
    dense_WH_pair_valid='d0;
    Partial_H_dense_tb='d0;
    Partial_W_dense_tb='d0;
    nx_H_dense_init='d0;
    nx_W_dense_init='d0;
    dense_WH_pair_valid_init='d0;
    Partial_W_dense_tb_init='d0;
    Partial_H_dense_tb_init='d0;
    nx_Kc=Current_Kc;
    nx_state =state;
    //initial state for next dense data flow
    for(int i=0;i<`F*`I+1;i++)begin
        Partial_H_dense_tb_init[i+1]=(nx_H_dense_init[i]+current_stride_conv)>reg_Size_of_H;
        Partial_W_dense_tb_init[i+1]=(nx_W_dense_init[i]+current_stride_conv)>reg_Size_of_W&&Partial_H_dense_tb_init[i+1];
        if(Partial_W_dense_tb_init[i+1])begin
            nx_W_dense_init[`F*`I]=nx_W_dense_init[i];
            nx_H_dense_init[`F*`I]=nx_H_dense_init[i];
            break;
        end
        nx_W_dense_init[i+1]=!Partial_W_dense_tb_init[i+1]&&Partial_H_dense_tb_init[i+1]?nx_W_dense_init[i]+current_stride_conv:nx_W_dense_init[i];
        nx_H_dense_init[i+1]=Partial_H_dense_tb_init[i+1]?'d0:nx_H_dense_init[i]+current_stride_conv;
        dense_WH_pair_valid_init[i]=1'b1;
    end
    case(state)
        IDLE: 
            if(!rst)begin
                nx_state=Stream_Conv_Layer;
            end
            else begin
                nx_state=IDLE;
            end
        Stream_Conv_Layer:
            if(Current_Conv_Layer==0&&Current_k==0)begin
                    Req_Stream_PE.Req_Stream_filter_valid='d1;
                    Req_Stream_PE.Req_Stream_input_valid='d1;
                    if(Stream_filter_finish && reg_Stream_input_finish_PE)begin
                        nx_state=Ex_Conv_Layer;
                            nx_W_dense=nx_W_dense_init;
                            nx_H_dense=nx_H_dense_init;
                            dense_WH_pair_valid=dense_WH_pair_valid_init;
                    end
                    else begin
                        nx_state=Stream_Conv_Layer;
                    end

            end

            else begin
                Req_Stream_PE.Req_Stream_filter_valid='d1;

                if(Stream_filter_finish)begin
                    nx_state=Ex_Conv_Layer;
                        if(!reg_data_flow_channel[nx_Conv_Layer][nx_c])begin
                            nx_W_dense=nx_W_dense_init;
                            nx_H_dense=nx_H_dense_init;
                            dense_WH_pair_valid=dense_WH_pair_valid_init;
                        end

                end
                else begin
                    nx_state=Stream_Conv_Layer;
                end
            end

        Ex_Conv_Layer:
            if(!busy)begin
                
                 if (reg_data_flow_channel[nx_Conv_Layer][nx_c]) begin//sparse data flow

                 
                Partial_w=(Current_w==(reg_w_Conv_Boundary-`F) || reg_w_Conv_Boundary<`F || (!Flag_remain_w));
                Partial_a=(Current_a==(reg_a_Conv_Boundary-`I)|| reg_a_Conv_Boundary<`I || (!Flag_remain_a))&&Partial_w;
                Partial_c=Current_c==reg_c_Conv_Boundary&&Partial_a;
                Partial_k=Current_k==reg_k_Conv_Boundary&&Partial_c;

                //nx_k=Partial_c?Current_k+1'b1:Current_k; 
                nx_c=!Partial_k&&Partial_c?'d0:Partial_a?Current_c+1'b1:Current_c;
                nx_a=(Partial_c || Partial_a )?'d0:!Partial_w?Current_a:(Current_a==0)?Current_a+'d3:Current_a+`I;
                nx_w=(Partial_a || Partial_w )?'d0:(Current_w==0)?Current_w+'d3:Current_w+`F;//:Current_w+remain_w

                    if(Partial_c)begin
                        // nx_state=Conv_Layer_PPU;
                                Partial_w=reg_Partial_w;
                                Partial_a=reg_Partial_a;
                                //Partial_c=reg_Partial_c;

                               // nx_k=Current_k;
                                nx_c=Current_c;
                                nx_a=Current_a;
                                nx_w=Current_w;

                        if(Xbar_empty && XBAR_Partial_c)begin
                            nx_state=Conv_Layer_PPU;
                            //nx_k=Current_k+1'b1;
                            Partial_w='d0;
                            Partial_a='d0;
                            Partial_c='d0;

                            Partial_S_dense='d0;
                            Partial_R_dense='d0;
                            Partial_R_dense_complete='d0;
                            Partial_H_dense='d0;
                            Partial_W_dense='d0;


                            nx_c='d0;
                            nx_a='d0;
                            nx_w='d0;

                            nx_W_dense='d0;
                            nx_H_dense='d0;
                            nx_R_dense='d0;
                            nx_S_dense='d0;

                        end
                         else begin
                             if(reg_Partial_c)begin
                        //         Partial_w=reg_Partial_w;
                        //         Partial_a=reg_Partial_a;
                             Partial_c=reg_Partial_c;

                        //         nx_k=Current_k;
                        //         nx_c=Current_c;
                        //         nx_a=Current_a;
                        //         nx_w=Current_w;
                             end

                         end

                    end
                    else begin
                        nx_state=Ex_Conv_Layer;
                    end
                    if(!reg_data_flow_channel[nx_Conv_Layer][nx_c])begin
                            nx_W_dense=nx_W_dense_init;
                            nx_H_dense=nx_H_dense_init;
                            dense_WH_pair_valid=dense_WH_pair_valid_init;
                    end
                end
                else begin//dense data flow //dot production

                    Partial_S_dense=Current_S_dense==reg_Size_of_S;
                    Partial_R_dense=Current_R_dense==reg_Size_of_R&&Partial_S_dense;

                    Partial_R_dense_complete=Partial_R_dense&&(nx_Kc==`Kc-1);
                    nx_Kc=Partial_R_dense?nx_Kc+1'b1:nx_Kc;

                        for(int i=0;i<`F*`I+1;i++)begin
                            
                            // Partial_H_dense[i]=(nx_H_dense[i]+current_stride_conv)>reg_Size_of_H;
                            // Partial_W_dense[i]=(nx_W_dense[i]+current_stride_conv)>reg_Size_of_W;
                            // Partial_H_dense_current_data[i]=(nx_H_dense[i])>=reg_Size_of_H;
                            // Partial_W_dense_current_data[i]=(nx_W_dense[i])>=reg_Size_of_W;
                            if(i!=16&&reg_Partial_W_dense[i] && reg_Partial_H_dense[i]&&Partial_R_dense_complete)begin
                                nx_W_dense='d0;
                                nx_H_dense='d0;
                                Partial_W_dense[`F*`I]=1'b1;
                                Partial_H_dense[`F*`I]=1'b1;
                                dense_WH_pair_valid='d0;
                                break;
                            end
                            else if(Partial_R_dense_complete)begin
                                nx_W_dense[0]=reg_W_dense[`F*`I];
                                nx_H_dense[0]=reg_H_dense[`F*`I];
                                Partial_H_dense[i]=(nx_H_dense[i]+current_stride_conv)>reg_Size_of_H;
                                Partial_W_dense[i]=(nx_W_dense[i]+current_stride_conv)>reg_Size_of_W;
                                dense_WH_pair_valid[0]=reg_dense_WH_pair_valid[`F*`I];
                                nx_W_dense[i+1]=(Partial_W_dense[i])?nx_W_dense[i]:Partial_H_dense[i]?nx_W_dense[i]+current_stride_conv:nx_W_dense[i];
                                nx_H_dense[i+1]=!Partial_W_dense[i]&&Partial_H_dense[i]?'d0:(Partial_W_dense[i]&&Partial_H_dense[i])?nx_H_dense[i]:nx_H_dense[i]+current_stride_conv;
                                dense_WH_pair_valid[i+1]=Partial_H_dense[i]&&Partial_W_dense[i]?'d0:1'b1;
                            end
                            else if(!Partial_R_dense_complete)begin
                                nx_W_dense=reg_W_dense;
                                nx_H_dense=reg_H_dense;
                                dense_WH_pair_valid=reg_dense_WH_pair_valid;

                            end
                            

                            //end 
                        end
                    Partial_c=Current_c==reg_c_Conv_Boundary&&reg_Partial_W_dense[`F*`I-1]&&reg_Partial_H_dense[`F*`I-1]&&Partial_R_dense_complete;
                    Partial_k=Current_k==reg_k_Conv_Boundary&&Partial_c;
                    nx_k=Partial_c?Current_k+1'b1:Current_k;//all need to add reg
                    nx_c=!Partial_k&&Partial_c?'d0:reg_Partial_W_dense[`F*`I-1] &&reg_Partial_H_dense[`F*`I-1]&&Partial_R_dense_complete?Current_c+1'b1:Current_c;
                    nx_R_dense=Partial_R_dense?'d0:!Partial_S_dense?Current_R_dense:Current_R_dense+'d1;
                    nx_S_dense=Partial_R_dense || Partial_S_dense?'d0:Current_S_dense+1'b1;

                    nx_W_dense=(Current_c!=nx_c && (!reg_data_flow_channel[nx_Conv_Layer][nx_c]))?nx_W_dense_init:nx_W_dense;
                    nx_H_dense=(Current_c!=nx_c && (!reg_data_flow_channel[nx_Conv_Layer][nx_c]))?nx_W_dense_init:nx_H_dense;
                    nx_Kc=nx_c!=Current_c?'d0:nx_Kc;
                    if(Partial_c)begin
                        if(Xbar_empty)begin
                            nx_state=Conv_Layer_PPU;
                        end
                        else begin
                            nx_H_dense=reg_H_dense;
                            nx_W_dense=reg_W_dense;
                            nx_R_dense=Current_R_dense;
                            nx_S_dense=Current_S_dense;
                            //nx_k=Current_k;
                            //nx_c=Current_c;
                            Partial_c=reg_Partial_c;
                            Partial_R_dense=reg_Partial_R_dense;
                            Partial_S_dense=reg_Partial_S_dense;
                            Partial_W_dense=reg_Partial_W_dense;
                            Partial_H_dense=reg_Partial_H_dense;
                        end
                        //nx_state=Conv_Layer_PPU;


                    end
                    else begin
                        nx_state=Ex_Conv_Layer;
 
                    end

                     
                end   
                if(nx_c!=Current_c&& (!reg_data_flow_channel[nx_Conv_Layer][nx_c]))begin
                            nx_W_dense=nx_W_dense_init;
                            nx_H_dense=nx_H_dense_init;
                            dense_WH_pair_valid=dense_WH_pair_valid_init;
                            Partial_H_dense='d0;
                            Partial_W_dense='d0;

                end

            
            end
    
           

        Conv_Layer_PPU:
        begin

           // if() begin

                

                if(!reg_Partial_k &&(PPU_finish_en||reg_PPU_finish_en)&& (reg_Stream_filter_finish||Stream_filter_finish))begin
                        Partial_w='d0;
                        Partial_a='d0;
                        Partial_c='d0;

                        Partial_S_dense='d0;
                        Partial_R_dense='d0;
                        Partial_R_dense_complete='d0;
                        Partial_H_dense='d0;
                        Partial_W_dense='d0;


                        nx_c='d0;
                        nx_a='d0;
                        nx_w='d0;


                        nx_W_dense=nx_W_dense_init;
                        nx_H_dense=nx_H_dense_init;
                        dense_WH_pair_valid=dense_WH_pair_valid_init;
                        nx_R_dense='d0;
                        nx_S_dense='d0;
                        

                        
                        nx_k=Current_k+1'b1;
                        nx_state=Ex_Conv_Layer; //for nx k'
                end
                else if(reg_Partial_k && Current_Conv_Layer==`num_of_Conv_Layer&&(PPU_finish_en||reg_PPU_finish_en))begin //currently do not consider FC layer
                        
                        // Partial_k='d0;
                        // nx_k='d0;
                        // Partial_w='d0;
                        // Partial_a='d0;
                        // Partial_c='d0;

                        // Partial_S_dense='d0;
                        // Partial_R_dense='d0;
                        // Partial_R_dense_complete='d0;
                        // Partial_H_dense='d0;
                        // Partial_W_dense='d0;


                        // nx_c='d0;
                        // nx_a='d0;
                        // nx_w='d0;

                        // nx_W_dense='d0;
                        // nx_H_dense='d0;
                        // nx_R_dense='d0;
                        // nx_S_dense='d0;
                        nx_state=Complete;
                end
                else if(reg_Partial_k &&Current_Conv_Layer!=`num_of_Conv_Layer&&(PPU_finish_en||reg_PPU_finish_en))begin
                        Partial_k='d0;
                        nx_k='d0;
                        nx_Conv_Layer=Current_Conv_Layer+1'b1;
                        nx_state=Ex_Conv_Layer;

                end
                else begin
                    nx_state=Conv_Layer_PPU;
                end
                //else if((PPU_finish_en||reg_PPU_finish_en)&&(reg_Stream_filter_finish||Stream_filter_finish))begin

                    // if(reg_Partial_k&&Current_Conv_Layer!=`num_of_Conv_Layer)begin

                    // end
               // end


            //end
            if(reg_Stream_filter_finish||reg_Partial_k)begin
                Req_Stream_PE.Req_Stream_filter_valid='d0;
            end
            else begin
                //nx_state=Conv_Layer_PPU;
                Req_Stream_PE.Req_Stream_filter_valid='d1;
            end  
        end
            
        Complete: 
            $display("Complete!");

        default: nx_state=IDLE;

        
    endcase
end//end_comb
endmodule