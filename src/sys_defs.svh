`define num_of_PE 1
`define max_num_K 16//k_Conv_Boundary
`define max_num_filter 384
`define max_num_channel 384
`define max_num_K_prime `max_num_K/`Kc
`define max_size_output 55 // one dimension

`define num_of_Conv_Layer 1 -1
`define Kc 4
`define F 4
`define I 4
`define max_size_R 11
`define max_size_S `max_size_R
`define max_size_W 16+11//4 PE, R=11 for filter
`define max_size_H `max_size_W
`define max_num_S `max_size_S
`define max_num_R `max_size_R//w_Conv_Boundary
`define max_num_Wt `max_size_W // for caculating a boundary
`define max_num_Ht `max_size_H

`define clock_frequency 1       //unit GHZ
`define num_data 50*8/`clock_frequency/16 //8(Bytes), 16 bits for one data
`define max_compressed_data `max_size_H*`max_size_W
`define bits_of_indices 4
`define num_of_outputs_PPU 8 //every cycle there are num_of_outputs_PPU data from Compress module
`define num_of_data_Dram 16

typedef struct packed {
    logic[`num_of_data_Dram-1:0][15:0] data;
    logic[`num_of_data_Dram-1:0][`bits_of_indices-1:0] indices;
    logic[`num_of_data_Dram-1:0] valid;
} Dram_IARAM; //interface for compressed data written into OARAM

typedef struct packed {
    logic[`num_of_outputs_PPU-1:0][15:0] output_data;
    logic[`num_of_outputs_PPU-1:0][`bits_of_indices-1:0] output_indices;
    logic[`num_of_outputs_PPU-1:0] valid;
} PPU_OARAM; //interface for compressed data written into OARAM


typedef struct packed {
    logic[`I*`F-1:0][15:0] output_data;
    logic[`I*`F-1:0][`bits_of_indices-1:0] output_indices;
    logic[`I*`F-1:0] valid;
} MUL_XBAR; //for fetching inputs data for multiplier array


typedef struct packed {
    logic[`I-1:0][15:0] IRAM_data;
    logic[`I-1:0][$clog2(`max_size_W)-1:0] IRAM_x;
    logic[`I-1:0][$clog2(`max_size_H)-1:0] IRAM_y;
    logic[`I-1:0][$clog2(`max_num_K)-1:0] IRAM_k;
    logic[`I-1:0] valid;
} IARAM_MUL; //for fetching inputs data for multiplier array
typedef struct packed {
    logic[`I-1:0][15:0] IRAM_data;
    logic[`I-1:0][`bits_of_indices-1:0] indices;
    logic[`I-1:0] valid;
} IARAM_MUL_nx; //for fetching inputs data for multiplier array
typedef struct packed {
    logic[`F-1:0][15:0] Weight_data;
    logic[`F-1:0][$clog2(`max_size_W)-1:0] IRAM_x;
    logic[`F-1:0][$clog2(`max_size_H)-1:0] IRAM_y;
    logic[`F-1:0][$clog2(`max_num_K)-1:0] IRAM_k;
    logic[`F-1:0] valid;
} Weight_MUL; //for fetching inputs data for multiplier array

typedef struct packed {
    logic[`I-1:0][15:0] Weight_data;
    logic[`I-1:0][`bits_of_indices-1:0] indices;
    logic[`I-1:0] valid;
} Weight_MUL_nx; //for fetching inputs data for multiplier array
typedef struct packed {
    logic[$clog2(`max_size_R)-1:0]Current_R_dense;
    logic[$clog2(`max_size_S)-1:0]Current_S_dense;
    logic[$clog2(`max_size_W)-1:0]Current_W_dense;
    logic[$clog2(`max_size_H)-1:0]Current_H_dense;

    logic[$clog2(`max_num_K)-1:0] Current_k;
    logic[$clog2(`max_num_channel)-1:0] Current_c;
    logic[$clog2(`max_num_Wt*`max_num_Ht)-1:0] Current_a;
    logic[$clog2(`Kc*`max_num_R*`max_num_S):0] Current_w;

    logic[$clog2(`num_of_Conv_Layer):0][`max_num_channel-1:0] valid_channel; //valid channel for each layer
    logic[$clog2(`num_of_Conv_Layer):0][`max_num_channel-1:0] data_flow_channel;//data flow type for each channel for each layer, 1 for sparse, 0 for dense flow

    logic[$clog2(`num_of_Conv_Layer):0] Current_Conv_Layer;
    logic Flag_remain_H_dense;
    logic [$clog2(`max_size_W)-1:0] remain_H_dense;
    logic [$clog2(`max_num_Wt*`max_num_Ht)-1:0] remain_a;
    logic [$clog2(`Kc*`max_num_R*`max_num_S):0] remain_w;
    logic Flag_remain_a;
    logic Flag_remain_w;

    logic[$clog2(5)-1:0] state; //current state of PE controller

} State_of_PE; //for fetching inputs data for multiplier array
typedef struct packed {
    logic[$clog2(`num_of_Conv_Layer):0][$clog2(`max_num_K)-1:0] k_Conv_Boundary;//calculate in testbench
    logic[$clog2(`num_of_Conv_Layer):0][$clog2(`Kc*`max_num_R*`max_num_S)-1:0] w_Conv_Boundary;
    logic[$clog2(`num_of_Conv_Layer):0][$clog2(`max_num_channel)-1:0] c_Conv_Boundary;
   // logic[$clog2(`num_of_Conv_Layer):0][$clog2(`max_num_Wt*`max_num_Ht)-1:0] a_Conv_Boundary;
    //logic[$clog2(`num_of_Conv_Layer):0][$clog2(`max_size_output)-1:0] num_of_compressed_weight;
    logic[$clog2(`num_of_Conv_Layer):0][$clog2(`max_size_R)-1:0] Size_of_R;
    logic[$clog2(`num_of_Conv_Layer):0][$clog2(`max_size_S)-1:0] Size_of_S; //R=S
    logic[$clog2(`num_of_Conv_Layer):0][$clog2(`max_size_W)-1:0] Size_of_W;
    logic[$clog2(`num_of_Conv_Layer):0][$clog2(`max_size_H)-1:0] Size_of_H;

    logic[$clog2(`num_of_Conv_Layer):0][`max_num_channel-1:0] valid_channel; //valid channel for each layer
    logic[$clog2(`num_of_Conv_Layer):0][`max_num_channel-1:0] data_flow_channel;//data flow type for each channel for each layer, 1 for sparse, 0 for dense flow
} Conv_filter_Parameter;
typedef struct packed {
    logic Req_Stream_filter_valid;
    logic[$clog2(`max_num_filter)-1:0] Req_Stream_filter_k;//filter k
    logic[$clog2(`num_of_Conv_Layer)-1:0] Req_Stream_Conv_Layer_num;
    logic Req_Stream_input_valid;
} Req_Stream;//PE and TOP. request filter and input in lockstep
typedef struct packed {
    logic[`num_data-1:0] Response_Stream_filter_valid;
    logic[`num_data-1:0][15:0] Response_Stream_filter_data;
    logic[`num_data-1:0] Response_Stream_input_valid;
    logic[`num_data-1:0][15:0] Response_Stream_input_data;
    logic[$clog2(`num_of_PE)-1:0] Response_for_PE_num; 
} Response_Stream_PE;
typedef struct packed {
    logic Stream_filter_finish;//brodcast for all PE
    logic[`num_of_PE-1:0] Stream_input_finish_PE;
} Response_Stream_Complete;//Top

typedef struct packed {
    logic[`num_data-1:0] Response_Stream_filter_valid;
    logic[`num_data-1:0][15:0] Response_Stream_filter_data;
    logic[`num_data-1:0] Response_Stream_input_valid;
    logic[`num_data-1:0][15:0] Response_Stream_input_data;
    logic[`num_of_PE-1:0][$clog2(`num_of_PE)-1:0] Response_for_PE_num; //may same data give 2 PE, 
} Response_Stream_Top;//Top use,not PE use
 