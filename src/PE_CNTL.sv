`timescale 1ns/100ps
module PE_CNTL
#(parameter PE_num=1)(
//-------------------Input-------------------------//
    input clk,
    input rst,
    PPU_to_CNTL PPU_to_CNTL_in,
    Conv_filter_Parameter Conv_filter_Parameter_TB,
    
    input Stream_filter_finish,//From Top, Response_Stream_Complete packet
    input Stream_input_finish_PE,

//--------------------output------------------------//
    output Req_Stream Req_Stream_PE;



);
parameter  N=4, IDLE='d0, Stream_Conv_Layer='d1, Ex_Conv_Layer='d3, Conv_Layer_PPU='d4;
logic[$clog2(N)-1:0] state, nx_state;
logic Current_data_flow;
logic[$clog2(`num_of_Conv_Layer)-1:0] Current_Conv_Layer, nx_Conv_Layer;
logic[$clog2(`max_num_K)-1:0] Current_k, nx_k;
logic[$clog2(`max_num_channel)-1:0] Current_c, nx_c;
logic[$clog2(`max_num_Wt*`max_num_Ht/`I)-1:0] Current_a, nx_a;
logic[$clog2(`Kc*max_num_R*max_num_S/`F):0] Current_w, nx_w;
logic Partial_w, Partial_a, Partial_c, Partial_k;
logic[$clog2(`max_num_K)-1:0] reg_k_Conv_Boundary;
logic[$clog2(`Kc*max_num_R*max_num_S/`F)-1:0] reg_w_Conv_Boundary;
logic[$clog2(`max_num_channel)-1:0] reg_c_Conv_Boundary;
logic[$clog2(`max_num_Wt*max_num_Ht/`I)-1:0] reg_a_Conv_Boundary;
always_ff@(posedge clk)begin
    if(rst)begin
        state<=#1 'd0;
        Current_Conv_Layer<=#1 'd0;
        Current_k<=#1 'd0;
        Current_data_flow<=#1 'd1;
        reg_k_Conv_Boundary<=#1 'd0;
        reg_w_Conv_Boundary<=#1 'd0;
        reg_c_Conv_Boundary<=#1 'd0;
        reg_a_Conv_Boundary<=#1 'd0;
    end
    else begin
        state<=#1 nx_state;
        Current_Conv_Layer<=#1 nx_Conv_Layer;
        Current_k<=#1 nx_k;
        Current_data_flow<=#1 PPU_to_CNTL_in.data_flow_PPU;
        reg_k_Conv_Boundary<=#1 Conv_filter_Parameter_TB.k_Conv_Boundary;
        reg_w_Conv_Boundary<=#1 Conv_filter_Parameter_TB.w_Conv_Boundary;
        reg_c_Conv_Boundary<=#1 Conv_filter_Parameter_TB.c_Conv_Boundary;
        reg_a_Conv_Boundary<=#1 Current_data_flow? PPU_to_CNTL_in.num_of_compressed_data : Conv_filter_Parameter_TB.a_Conv_Boundary;
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
            if(Current_data_flow)begin //sparse data flow


            end
            else begin// dense data flow

            end

        default: nx_state=IDLE;

        
    endcase
end
endmodule