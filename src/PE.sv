module PE(
    input clk,
    input rst,
    input Conv_filter_Parameter Conv_filter_Parameter_TB,
    input [`max_num_channel-1:0][$clog2(`max_size_output)-1:0] num_of_compressed_data,
    input Dram_TB Dram_TB_in,

    output logic signed[`max_num_K-1:0][`max_compressed_data-1:0][15:0] I_OARAM_S_0_TB,//SPARSE
    output logic signed[`max_num_K-1:0][`max_compressed_data-1:0][15:0] I_OARAM_S_1_TB,//SPARSE
    output logic [`max_num_K-1:0][`max_compressed_data-1:0][`bits_of_indices-1:0] I_OARAM_S_Indices_0_TB,//SPARSE
    output logic [`max_num_K-1:0][`max_compressed_data-1:0][`bits_of_indices-1:0] I_OARAM_S_Indices_1_TB//SPARSE


);
logic Stream_filter_finish,Stream_input_finish_PE;
Req_Stream Req_Stream_PE;
IARAM_MUL_nx IARAM_MUL_out;
State_of_PE  PE_state_out;
Weight_MUL_nx Weight_MUL_out;
PPU_OARAM PPU_OARAM_in;
Dram_IARAM Dram_IARAM_out;
Dram_Weight Dram_Weight_out;
Dram_IARAM_indices Dram_IARAM_indices_out;
Dram_Weight_indices Dram_Weight_indices_out;
logic last_decode_input;
logic[$clog2(`max_num_channel)-1:0] prev_channel;
logic [$clog2(`Accumulator_buffer_k_offset)-1:0] kc_num;
logic [$clog2(`Accumulator_buffer_k_offset)-1:0] k_num, reg_k_num;
Buffer_PPU_PACKET buffer_PPU_data;
logic [$clog2(`Accumulator_buffer_k_offset)-1:0] kc_num;
logic last_compress;
PPU_compress_PACKET pooling_compress_out;
MUL_XBAR MUL_XBAR_in;
logic busy;
crossbar_buffer_in_PACKET crossbar_buffer_data_in;
logic [`max_num_channel-1:0][$clog2(`max_size_output)-1:0] num_of_compressed_data_PPU_out;
assign k_num=PE_state_out.Current_k*`Kc +kc_num;
assign last_compress=k_num==reg_k_num?'d0:'d1;
assign last_decode_input=prev_channel==PE_state_out.Current_c?'d0:'d1;
always_ff@(posedge clk)begin
    if(rst)begin
        prev_channel<=#1 'd0;
        reg_k_num<=#1 'd0;
    end
    else begin
        prev_channel<=#1 PE_state_out.Current_c;
        reg_k_num<=#1 k_num;
    end
end


PE_CNTL  PE_CNTL_U0
(
//-------------------Input-------------------------//
    .clk(clk),
    .rst(rst),
    .num_of_compressed_data(num_of_compressed_data),
    .Conv_filter_Parameter_TB(Conv_filter_Parameter_TB),
    .PPU_finish_en(PPU_finish_en),
    .Stream_filter_finish(Stream_filter_finish),
    .Stream_input_finish_PE(Stream_input_finish_PE),
    .num_of_compressed_data_PPU(num_of_compressed_data_PPU_out),
    .busy(busy),

//--------------------output------------------------//
    .Req_Stream_PE(Req_Stream_PE),
    .PE_state_out(PE_state_out)
);

I_OARAM I_OARAM_U0(
    .clk(clk),
    .rst(rst),
    .PE_state_out(PE_state_out),
    .PPU_OARAM_in(PPU_OARAM_in),
    .Dram_IARAM_in(Dram_IARAM_out),
    .Dram_Weight_in(Dram_Weight_out),
    .Dram_IARAM_indices_in(Dram_IARAM_indices_out),
    .Dram_Weight_indices_in(Dram_Weight_indices_out),
    .busy(busy),
    .PPU_RAM_PACKET_in(PPU_RAM_PACKET_in),

    .IARAM_MUL_out(IARAM_MUL_out),
    
    .I_OARAM_S_0_TB(I_OARAM_S_0_TB),//SPARSE
    .I_OARAM_S_1_TB(I_OARAM_S_1_TB),//SPARSE
    .I_OARAM_S_Indices_0_TB(I_OARAM_S_Indices_0_TB),//SPARSE
    .I_OARAM_S_Indices_1_TB(I_OARAM_S_Indices_1_TB),//SPARSE
    .Weight_MUL_out(Weight_MUL_out),
    .num_of_compressed_data_PPU_out(num_of_compressed_data_PPU_out)
);

MEM DRAM_MEM_Simple(
    .clk(clk),
    .rst(rst),
    .Req_Stream_PE(Req_Stream_PE),
    .PE_state_in(PE_state_out),
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


coordinate_computation  coordinate_computation_U0(
    .clk(clk),
    .rst(rst),
    .last_decode_input(last_decode_input),
    .each_filter_size(Conv_filter_Parameter_TB.each_filter_size[PE_state_out.Current_Conv_Layer]),

    .IARAM_MUL_out(IARAM_MUL_out),
    .Weight_MUL_out(Weight_MUL_out),


    .MUL_XBAR(MUL_XBAR_in)
);

Xbar Xbar(
    .clock(clk), 
    .reset(rst),
    
    // Interface with PE
    .MUL_XBAR(MUL_XBAR_in),
    .busy(busy), //backpressrue to MA

    // Inteface with acummulate buffer
    .crossbar_buffer_data_in(crossbar_buffer_data_in),
    
);  

PE_Accumulator_buffer PE_Accumulator_buffer_U0
(
//-------------------Input-------------------------//
    .clk(clk),
    .rst(rst),
    .Conv_size_output_Boundary(Conv_filter_Parameter_TB.Conv_size_output_Boundary),//testbench
    .drain_Accumulator_buffer_en(PE_state_out.state=='d3),
    .crossbar_buffer_data_in(crossbar_buffer_data_in),
    .buffer_PPU_data(buffer_PPU_data)
);

max_pooling max_pooling_U0(
  .clk(clk),
  .rst(rst),
  .ppu_data_in(buffer_PPU_data),
  .pooling_size_Boundary(Conv_filter_Parameter_TB.pooling_size_Boundary),//testbench
  .stage_pooling_Boundary(Conv_filter_Parameter_TB.stage_pooling_Boundary),//testbench
  .kc_num(kc_num),
  .pooling_compress_out_reg(pooling_compress_out),
  .PPU_finish_en(PPU_finish_en)
);
compress_vector compress_vector_U0(
  .clk(clk),
  .rst(rst),
  .pooling_compress_out(pooling_compress_out),
  .last_compress(last_compress),
  .k_num(k_num),
  .PPU_OARAM(PPU_OARAM)
);
endmodule