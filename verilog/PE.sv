`timescale 1ns/100ps
module PE(
    input clk,
    input rst,
    input Conv_filter_Parameter Conv_filter_Parameter_TB,
    input [`max_num_channel-1:0][$clog2(`max_size_output)-1:0] num_of_compressed_data,
    input Dram_TB Dram_TB_in,

    output logic signed[`max_num_K-1:0][`max_compressed_data-1:0][15:0] I_OARAM_S_0_TB,//SPARSE
    output logic signed[`max_num_K-1:0][`max_compressed_data-1:0][15:0] I_OARAM_S_1_TB,//SPARSE
    output logic [`max_num_K-1:0][`max_compressed_data-1:0][`bits_of_indices-1:0] I_OARAM_S_Indices_0_TB,//SPARSE
    output logic [`max_num_K-1:0][`max_compressed_data-1:0][`bits_of_indices-1:0] I_OARAM_S_Indices_1_TB,//SPARSE
    output logic [$clog2(5)-1:0]state


);
logic [`num_of_Conv_Layer:0][$clog2(`max_size_H):0] Size_of_H;
logic [`num_of_Conv_Layer:0][$clog2(`max_size_R):0] Size_of_S;
logic Stream_filter_finish,Stream_input_finish_PE;
Req_Stream Req_Stream_PE;
IARAM_MUL_nx IARAM_MUL_out;
State_of_PE  PE_state_out;
Weight_MUL_nx Weight_MUL_out;
PPU_OARAM PPU_OARAM_in;
Compress_OARAM compress_out;
Dram_IARAM Dram_IARAM_out;
Dram_Weight Dram_Weight_out;
Dram_IARAM_indices Dram_IARAM_indices_out;
Dram_Weight_indices Dram_Weight_indices_out;
logic last_decode_input;
logic[$clog2(`max_num_channel)-1:0] prev_channel;
logic[`num_of_Conv_Layer:0] prev_layer;
logic [$clog2(`Accumulator_buffer_k_offset)-1:0] kc_num;
logic [$clog2(`Accumulator_buffer_k_offset)-1:0] k_num, reg_k_num;
Buffer_PPU_PACKET buffer_PPU_data;
logic last_compress;
PPU_compress_PACKET pooling_compress_out;
MUL_XBAR MUL_XBAR_in;
MUL_COORD_IN Mult_Coord_in;
MUL_COORD_OUT Mult_Coord_out;
logic busy;
crossbar_buffer_in_PACKET crossbar_buffer_data_in;
logic PPU_finish_en;
logic max_pool_finish;
logic compress_finish;
logic Layer_change_flag;
logic [`max_num_channel-1:0][$clog2(`max_size_output)-1:0] num_of_compressed_data_PPU_out;
//PPU_RAM_PACKET PPU_RAM_PACKET_in;
IARAM_MUL_Dense IARAM_MUL_Dense_out;
Weight_MUL_Dense Weight_MUL_Dense_out;
assign k_num=PE_state_out.Current_c=='d0 ?PE_state_out.Current_k*`Kc +kc_num:PE_state_out.Current_k*`Kc +kc_num+1'b1;
assign last_compress=k_num==reg_k_num?'d0:'d1;
assign last_decode_input=prev_channel==PE_state_out.Current_c?'d0:'d1;
assign Layer_change_flag=prev_layer==PE_state_out.Current_Conv_Layer?'d0:'d1;
assign state=PE_state_out.state;
assign Size_of_S=Conv_filter_Parameter_TB.Size_of_S[PE_state_out.Current_Conv_Layer];
assign Size_of_H=Conv_filter_Parameter_TB.Size_of_H[PE_state_out.Current_Conv_Layer];
always_ff@(posedge clk)begin
    if(rst)begin
        prev_channel<=#1 'd0;
        prev_layer<=#1 'd0;
        reg_k_num<=#1 'd0;
    end
    else begin
        prev_channel<=#1 PE_state_out.Current_c;
        prev_layer<=#1 PE_state_out.Current_Conv_Layer;
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
    .Size_of_H(Size_of_H),
    .Size_of_S(Size_of_S),
    .Dram_IARAM_in(Dram_IARAM_out),
    .Dram_Weight_in(Dram_Weight_out),
    .Dram_IARAM_indices_in(Dram_IARAM_indices_out),
    .Dram_Weight_indices_in(Dram_Weight_indices_out),
    .busy(busy),
   // .PPU_RAM_PACKET_in(PPU_RAM_PACKET_in),

    .IARAM_MUL_out(IARAM_MUL_out),
    
    .I_OARAM_S_0_TB(I_OARAM_S_0_TB),//SPARSE
    .I_OARAM_S_1_TB(I_OARAM_S_1_TB),//SPARSE
    .I_OARAM_S_Indices_0_TB(I_OARAM_S_Indices_0_TB),//SPARSE
    .I_OARAM_S_Indices_1_TB(I_OARAM_S_Indices_1_TB),//SPARSE
    .Weight_MUL_out(Weight_MUL_out),
    .IARAM_MUL_Dense_out(IARAM_MUL_Dense_out),
    .Weight_MUL_Dense_out(Weight_MUL_Dense_out),
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

assign Mult_Coord_in.decode_restart=last_decode_input;

assign Mult_Coord_in.Layer_change_flag=Layer_change_flag;
assign Mult_Coord_in.each_filter_size=Conv_filter_Parameter_TB.each_filter_size[PE_state_out.Current_Conv_Layer];
assign Mult_Coord_in.input_index_vector=IARAM_MUL_out.indices;
assign Mult_Coord_in.filter_index_vector=Weight_MUL_out.indices;

assign Mult_Coord_in.Weight_IN.valid = Weight_MUL_out.valid;
assign Mult_Coord_in.IARAM_IN.valid = IARAM_MUL_out.valid;
assign Mult_Coord_in.Weight_IN.Weight_data = Weight_MUL_out.Weight_data;
assign Mult_Coord_in.IARAM_IN.IRAM_data = IARAM_MUL_out.IRAM_data;
assign Mult_Coord_in.stride=Conv_filter_Parameter_TB.stride_conv[PE_state_out.Current_Conv_Layer];
assign Mult_Coord_in.input_side_length=Conv_filter_Parameter_TB.Size_of_W[PE_state_out.Current_Conv_Layer];
assign Mult_Coord_in.filter_side_length=Conv_filter_Parameter_TB.Size_of_R[PE_state_out.Current_Conv_Layer];
assign Mult_Coord_in.IARAM_MUL_Dense.IRAM_data=IARAM_MUL_Dense_out.IRAM_data;
assign Mult_Coord_in.IARAM_MUL_Dense.x=IARAM_MUL_Dense_out.x;
assign Mult_Coord_in.IARAM_MUL_Dense.y=IARAM_MUL_Dense_out.y;
assign Mult_Coord_in.IARAM_MUL_Dense.valid=IARAM_MUL_Dense_out.valid;

assign Mult_Coord_in.Weight_MUL_Dense_out.Weight_data=Weight_MUL_Dense_out.Weight_data;
assign Mult_Coord_in.Weight_MUL_Dense_out.x=Weight_MUL_Dense_out.x;
assign Mult_Coord_in.Weight_MUL_Dense_out.y=Weight_MUL_Dense_out.y;
assign Mult_Coord_in.Weight_MUL_Dense_out.Kc=Weight_MUL_Dense_out.Kc;
assign Mult_Coord_in.Weight_MUL_Dense_out.valid=Weight_MUL_Dense_out.valid;
assign Mult_Coord_in.sparse=Conv_filter_Parameter_TB.data_flow_channel[PE_state_out.Current_Conv_Layer][PE_state_out.Current_c];
Mult_Coord  Mult_Coord_U0(
    .clk(clk),
    .rst(rst),
    .Mult_Coord_in(Mult_Coord_in),
    .Mult_Coord_out(Mult_Coord_out)
);




Xbar Xbar(
    .clock(clk), 
    .reset(rst),
    
    // Interface with PE
    .mul_cord_packet(Mult_Coord_out),
    .busy(busy), //backpressrue to MA

    // Inteface with acummulate buffer
    .buffer_packet(crossbar_buffer_data_in)

);  

PE_Accumulator_buffer PE_Accumulator_buffer_U0
(
//-------------------Input-------------------------//
    .clk(clk),
    .rst(rst),
    .Conv_size_output_Boundary(Conv_filter_Parameter_TB.Conv_size_output_Boundary[PE_state_out.Current_Conv_Layer]),//testbench
    .drain_Accumulator_buffer_en(PE_state_out.state=='d3),
    .crossbar_buffer_data_in(crossbar_buffer_data_in),
    .buffer_PPU_data(buffer_PPU_data)
);

max_pooling max_pooling_U0(
  .clk(clk),
  .rst(rst),
  .ppu_data_in(buffer_PPU_data),
  .pooling_size_Boundary(Conv_filter_Parameter_TB.pooling_size_Boundary[PE_state_out.Current_Conv_Layer]),//testbench
  .stage_pooling_Boundary(Conv_filter_Parameter_TB.stage_pooling_Boundary),//testbench
  .kc_num(kc_num),
  .pooling_compress_out_reg(pooling_compress_out),
  .PPU_finish_en(max_pool_finish)
);
compression_unit compression_unit_U0(
  .clk(clk),
  .rst(rst),
  .PPU_finish_en(max_pool_finish),
  .max_pooling_to_compress(pooling_compress_out),
  .compress_restart(last_compress),
  .compressed_out(compress_out),
  .finish_en(compress_finish)
);
// assign  PPU_RAM_PACKET_in.num_of_compressed_data_PPU = compress_out.compressed_value_count;
// assign  PPU_RAM_PACKET_in.valid =compress_out.compressed_value_count_valid;
// assign  PPU_RAM_PACKET_in.which_channel =k_num;
always_comb begin 
    if(Conv_filter_Parameter_TB.data_flow_channel[PE_state_out.Current_Conv_Layer+'b1][k_num])begin//sparse
        PPU_OARAM_in.dense = 0;
        PPU_OARAM_in.output_data=compress_out.output_data;
        PPU_OARAM_in.output_indices=compress_out.output_indices;
        PPU_OARAM_in.valid=pooling_compress_out.valid;
        PPU_OARAM_in.feature_map_channel =k_num;
        PPU_OARAM_in.compressed_value_count_valid=compress_out.compressed_value_count_valid;
        PPU_OARAM_in.compressed_value_count=compress_out.compressed_value_count;
    end
    else begin//dense
        PPU_OARAM_in.output_data=pooling_compress_out.data;
        PPU_OARAM_in.output_indices=0;
        PPU_OARAM_in.valid=pooling_compress_out.valid;
        PPU_OARAM_in.feature_map_channel =k_num;
        PPU_OARAM_in.dense =1;
        PPU_OARAM_in.compressed_value_count_valid=0;
        PPU_OARAM_in.compressed_value_count=0;
    end
end

endmodule