`timescale 1ns/100ps

module compress_vector #(
  parameter bit_width = 4,
  parameter vector_length = 16,
  parameter max_index = 15
) (
  input logic clk,
  input logic rst_n,
  input logic [bit_width-1 : 0] input_vector [0 : vector_length-1],
  input logic last_compress,
  output logic 
  output logic [bit_width-1 : 0] data_vector [0 : vector_length-1],
  output logic [$clog2(max_index)-1 : 0] index_vector [0 : vector_length-1]
);

  // Internal signals
  logic [$clog2(max_index)-1:0] zero_count;
  logic [$clog2(max_index)-1:0] index_count;
  integer i, j;

  // Track zeros from the previous cycle to correctly index the first element
  logic [$clog2(max_index)-1:0] prev_cycle_zero_count;

  always_comb begin
    zero_count = prev_cycle_zero_count;
    index_count = 0;
    for (j = 0; j < vector_length; j=j+1) begin
        data_vector[j] = 0;
        index_vector[j] = 0;
    end

    for (i = 0; i < vector_length; i=i+1) begin
        if ((input_vector[i] != 0) || (zero_count == max_index)) begin
            data_vector[index_count] = input_vector[i];
            index_vector[index_count] = zero_count;
            index_count = index_count + 1'b1;
            zero_count = 0;
        end

        else begin
            zero_count = zero_count + 1'b1;
        end
    end
  end

  always_ff @(posedge clk) begin
    if (!rst_n) begin
        prev_cycle_zero_count <= 0;
    end

    else begin
      if (last_compress)
        prev_cycle_zero_count <= 0;
      else
        prev_cycle_zero_count <= zero_count;
    end
  end

endmodule
