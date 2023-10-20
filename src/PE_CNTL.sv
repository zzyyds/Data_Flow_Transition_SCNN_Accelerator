`timescale 1ns/100ps
module PE_CNTL
#(parameter PE_num=1)(
//-------------------Input-------------------------//
    input clk,
    input rst,
    PPU_to_CNTL PPU_to_CNTL_in,
    Conv_filter_Parameter Conv_filter_Parameter_TB,
    input PPU_finish_en,
    input Stream_filter_finish,//From Top, Response_Stream_Complete packet
    input Stream_input_finish_PE,

//--------------------output------------------------//
    output Req_Stream Req_Stream_PE,
    //output logic drain_Accumulator_buffer_en



);
parameter  N=4, IDLE='d0, Stream_Conv_Layer='d1, Ex_Conv_Layer='d3, Conv_Layer_PPU='d4;
logic[$clog2(N)-1:0] state, nx_state;
logic Current_data_flow;
logic[$clog2(`num_of_Conv_Layer)-1:0] Current_Conv_Layer, nx_Conv_Layer;
logic[$clog2(`max_num_K)-1:0] Current_k, nx_k;
logic[$clog2(`max_num_channel)-1:0] Current_c, nx_c;
logic[$clog2(`max_num_Wt*`max_num_Ht/`I)-1:0] Current_a, nx_a;
logic[$clog2(`Kc*max_num_R*max_num_S/`F):0] Current_w, nx_w;
logic[$clog2(`max_num_K)-1:0] reg_k_Conv_Boundary;
logic[$clog2(`Kc*max_num_R*max_num_S/`F)-1:0] reg_w_Conv_Boundary;
logic[$clog2(`max_num_channel)-1:0] reg_c_Conv_Boundary;
logic[$clog2(`max_num_Wt*max_num_Ht/`I)-1:0] reg_a_Conv_Boundary;

logic Partial_w, Partial_a, Partial_c, Partial_k, reg_Partial_k;
always_ff@(posedge clk)begin
    if(rst)begin
        state<=#1 'd0;
        Current_Conv_Layer<=#1 'd0;
        Current_k<=#1 'd0;
        Current_c<=#1 'd0;
        Current_a<=#1 'd0;
        Current_w<=#1 'd0;
        Current_data_flow<=#1 'd0;
        reg_k_Conv_Boundary<=#1 'd0;
        reg_w_Conv_Boundary<=#1 'd0;
        reg_c_Conv_Boundary<=#1 'd0;
        reg_a_Conv_Boundary<=#1 'd0;
        reg_Partial_k<=#1 'd0;
       // drain_Accumulator_buffer_en<=#1 'd0;// aftern entering PPU state
    end
    else begin
        state<=#1 nx_state;
        Current_Conv_Layer<=#1 nx_Conv_Layer;
        Current_k<=#1 nx_k;
        Current_c<=#1 nx_c;
        Current_a<=#1 nx_a;
        Current_w<=#1 nx_w;
        reg_Partial_k<=#1 Partial_k;
        Current_data_flow<=#1 PPU_to_CNTL_in.data_flow_PPU;
        reg_k_Conv_Boundary<=#1 Conv_filter_Parameter_TB.k_Conv_Boundary;
        reg_w_Conv_Boundary<=#1 Conv_filter_Parameter_TB.num_of_compressed_weight[nx_Conv_Layer];//maybe always need compressed version for weight
        reg_c_Conv_Boundary<=#1 Conv_filter_Parameter_TB.c_Conv_Boundary;
        reg_a_Conv_Boundary<=#1 PPU_to_CNTL_in.data_flow_PPU? PPU_to_CNTL_in.num_of_compressed_data : Conv_filter_Parameter_TB.a_Conv_Boundary;
    end
end
always_comb begin
    nx_Conv_Layer='d0;
    Req_Stream_PE='d0;
    case(state)
        IDLE: 
            if(!rst)begin
                nx_state=Stream_Conv_Layer;
            end
            else begin
                nx_state=IDLE;
            end
        Stream_Conv_Layer:
            if(Current_Conv_Layer==0)begin
                Req_Stream_PE.Req_Stream_filter_valid='d1;
                Req_Stream_PE.Req_Stream_filter_k=Current_k;
                Req_Stream_PE.Req_Stream_Conv_Layer_num=Current_Conv_Layer;
                Req_Stream_PE.Req_Stream_input_valid='d1;
                if(Stream_filter_finish && Stream_input_finish_PE)begin
                    nx_state=Ex_Conv_Layer;
                end
                else begin
                    nx_state=Stream_Conv_Layer;
                end
            end
            else begin
                Req_Stream_PE.Req_Stream_filter_valid='d1;
                Req_Stream_PE.Req_Stream_filter_k=Current_k;
                if(Stream_filter_finish)begin
                    nx_state=Ex_Conv_Layer;
                end
                else begin
                    nx_state=Stream_Conv_Layer;
                end
            end

        Ex_Conv_Layer:
            if(Current_data_flow)begin //sparse data flow //maybe can combine together, same with each other
                Partial_w=Current_w==reg_w_Conv_Boundary;
                Partial_a=Current_a==reg_a_Conv_Boundary&&Partial_w;
                Partial_c=Current_c==reg_c_Conv_Boundary&&Partial_a;
                Partial_k=Current_k==reg_k_Conv_Boundary&&Partial_c;

                nx_k=Partial_c?current_k+1'b1;
                nx_c=!Partial_k&&Partial_c?'d0:Partial_a?current_c+1'b1:current_c;
                nx_a=!Partial_c&&Partial_a?'d0:Partial_w?current_a+`I:current_a;
                nx_w=!Partial_a&&Partial_w?'d0:current_w+`F:current_w;
                if(Partial_k)begin
                    nx_state=Conv_Layer_PPU;
                end
                else begin
                    nx_state=Ex_Conv_Layer;
                end
            end
            else begin// dense data flow
                Partial_w=Current_w==reg_w_Conv_Boundary;
                Partial_a=Current_a==reg_a_Conv_Boundary&&Partial_w;
                Partial_c=Current_c==reg_c_Conv_Boundary&&Partial_a;
                Partial_k=Current_k==reg_k_Conv_Boundary&&Partial_c;

                nx_k=Partial_c?current_k+1'b1;
                nx_c=!Partial_k&&Partial_c?'d0:Partial_a?current_c+1'b1:current_c;
                nx_a=!Partial_c&&Partial_a?'d0:Partial_w?current_a+`I:current_a;
                nx_w=!Partial_a&&Partial_w?'d0:current_w+`F:current_w;
                if(Partial_k)begin
                    nx_state=Conv_Layer_PPU;
                end
                else begin
                    nx_state=Ex_Conv_Layer;
                end
            end
        Conv_Layer_PPU:
            if(PPU_finish_en) begin
                if(reg_Partial_k && Current_Conv_Layer==num_of_Conv_Layer)begin //currently do noe consider FC layer
                        Partial_k='d0;
                        nx_k='d0;
                        nx_state=IDLE;
                end
                else begin
                    if(reg_Partial_k)begin
                        Partial_k='d0;
                        nx_k='d0;
                        nx_Conv_Layer=Current_Conv_Layer+1'b1;
                        nx_state=Stream_Conv_Layer;
                    end
                    else begin
                        nx_state=Stream_Conv_Layer;
                    end
                end

            end
            else begin
                nx_state=Conv_Layer_PPU;
            end    

        default: nx_state=IDLE;

        
    endcase
end
endmodule