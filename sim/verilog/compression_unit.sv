`timescale 1ns/100ps

module compression_unit (
  input logic clk,
  input logic rst,
  input PPU_compress_PACKET max_pooling_to_compress,
  input logic compress_restart,
 input PPU_finish_en,
  output Compress_OARAM compressed_out,
  output finish_en

);

  logic compress_restart_d1;
  logic [`pooling_out_size-1:0][`size_data-1 : 0] input_vector;
  logic[`pooling_out_size-1:0] valid_in;
  logic [$clog2(`max_index)-1:0] zero_count;
  logic [$clog2(`max_index)-1:0] index_count;

  logic [`pooling_out_size-1:0][`size_data-1 : 0] data_vector;
  logic [`pooling_out_size-1:0][$clog2(`max_index)-1 : 0] index_vector;
  logic[`pooling_out_size-1:0] valid_out;
  integer i, j, k;

  logic [$clog2(`max_index)-1:0] prev_cycle_zero_count;
  logic [$clog2(`pooling_out_size) : 0] current_cycle_valid_count;

  assign input_vector = max_pooling_to_compress.data;
  assign valid_in = max_pooling_to_compress.valid;
  
  assign compressed_out.output_data = data_vector;
  assign compressed_out.output_indices = index_vector;
  assign compressed_out.valid = valid_out;
  assign finish_en =PPU_finish_en;
// //---------------------------------------------------//
//   assign compressed_out.dense =  0;                  //
//   assign compressed_out.feature_map_channel = 0;     //    need to modify
// //---------------------------------------------------//

  

  always_comb begin
    zero_count = prev_cycle_zero_count;
    index_count = 0;
    current_cycle_valid_count = 0;

    for (j = 0; j < `pooling_out_size; j=j+1) begin
        data_vector[j] = 0;
        index_vector[j] = 0;
        valid_out[j] = 0;
    end

    for (i = 0; i < `pooling_out_size; i=i+1) begin
      if (valid_in[i] == 1) begin
        if ((input_vector[i] != 0) || (zero_count == `max_index)) begin
            data_vector[index_count] = input_vector[i];
            index_vector[index_count] = zero_count;
            valid_out[index_count] = 1;
            index_count = index_count + 1'b1;
            zero_count = 0;
        end
        else begin
            zero_count = zero_count + 1'b1;
        end
      end
    end

    for (k=0; k<`pooling_out_size; k=k+1) begin
      current_cycle_valid_count = current_cycle_valid_count + valid_out[k];
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
        prev_cycle_zero_count <=#1 0;
    end

    else begin
      if (compress_restart)
        prev_cycle_zero_count <=#1 0;
      else
        prev_cycle_zero_count <=#1 zero_count;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      compressed_out.compressed_value_count <=#1 0;
      compress_restart_d1 <=#1 0;
    end

    else begin
      compress_restart_d1 <= #1 compress_restart;
      if (compress_restart_d1)
          compressed_out.compressed_value_count <=#1 current_cycle_valid_count;
      else
          compressed_out.compressed_value_count <=#1 compressed_out.compressed_value_count + current_cycle_valid_count;
    end
  end

  assign compressed_out.compressed_value_count_valid = compress_restart;

endmodule
