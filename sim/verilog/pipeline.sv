module pipeline(
    input clk,
    input rst,
    input Conv_filter_Parameter Conv_filter_Parameter_TB,
    input [`max_num_channel-1:0][$clog2(`max_size_output)-1:0] num_of_compressed_data,
    input Dram_IARAM Dram_IARAM_out,
    input Dram_Weight Dram_Weight_out,
    input Dram_IARAM_indices Dram_IARAM_indices_out,
    input Dram_Weight_indices Dram_Weight_indices_out,
    input logic Stream_filter_finish,//From Top, Response_Stream_Complete packet
    input logic Stream_input_finish_PE,

    output logic signed[`max_num_K-1:0][`max_compressed_data-1:0][15:0] I_OARAM_S_0_TB,//SPARSE
    output logic signed[`max_num_K-1:0][`max_compressed_data-1:0][15:0] I_OARAM_S_1_TB,//SPARSE
    output logic [`max_num_K-1:0][`max_compressed_data-1:0][`bits_of_indices-1:0] I_OARAM_S_Indices_0_TB,//SPARSE
    output logic [`max_num_K-1:0][`max_compressed_data-1:0][`bits_of_indices-1:0] I_OARAM_S_Indices_1_TB,//SPARSE
    output logic [$clog2(5)-1:0]state,
    output MUL_COORD_OUT tb,
    output State_of_PE  PE_state_out_tb,
    output Req_Stream Req_Stream_PE_tb,
   output  Compress_OARAM out_tb


);




PE PE_0(
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






endmodule