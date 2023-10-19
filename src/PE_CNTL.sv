`timescale 1ns/100ps
module PE_CNTL
#(parameter Wt=60,Ht=60, PE_num=1)(
//-------------------Input-------------------------//
    input clk,
    input rst,
    filter_Parameter filter_Parameter_TB,
    input_activation_Parameter input_activation_Parameter_PPU,

    output Req_Stream Req_Stream_PE;



);
parameter a1_Boundary=Wt*Ht/`I1, N=4, IDLE='d0, Stream_Conv_Layer='d1, Ex_Conv_Layer='d3, Conv_Layer_PPU='d4;
logic[$clog2(N)-1:0] state,nx_state;
logic[$clog2(`num_of_Conv_Layer)-1:0] Current_Conv_Layer, nx_Conv_Layer;
logic[$clog2(`max_num_filter)-1:0] Current_k, nx_k;
always_ff@(posedge clk)begin
    if(rst)begin
        state<=#1 'd0;
        Current_Conv_Layer<=#1 'd0;
        Current_k<=#1 'd0;
    end
    else begin
        state<=#1 nx_state;
        Current_Conv_Layer<=#1 nx_Conv_Layer;
        Current_k<=#1 nx_k;
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
            Req_Stream_PE.Req_Stream_filter_valid='d1;
            Req_Stream_PE.Req_Stream_filter_k=Current_k;
            Req_Stream_PE.Req_Stream_Conv_Layer_num=Current_Conv_Layer;
            Req_Stream_PE.Req_Stream_input_valid='d1;
        default: nx_state=IDLE;
            
        
    endcase
end
endmodule