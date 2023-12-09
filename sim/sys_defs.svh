`define num_of_PE 1
`define max_num_K 4//k_Conv_Boundary
`define max_num_filter 2
`define max_num_channel 2
`define max_num_K_prime `max_num_K/`Kc
`define max_size_output 55*55 // one dimension
`define max_stride_conv 4
`define num_of_Conv_Layer 1 -1
`define Kc 2
`define F 4
`define I 4
`define channel_a 2
`define max_size_R 11
`define max_size_S `max_size_R
`define max_size_W 27//4 PE, R=11 for filter
`define max_size_H `max_size_W
`define max_num_S `max_size_S
`define max_num_R `max_size_R//w_Conv_Boundary
`define max_num_Wt `max_size_W // for caculating a boundary
`define max_num_Ht `max_size_H

`define clock_frequency 1       //unit GHZ
`define num_of_data_Dram 50*8/`clock_frequency/16 //8(Bytes), 16 bits for one data
`define max_compressed_data 729
`define max_compressed_weight `max_num_S*`max_num_R
`define bits_of_indices 4
`define num_of_outputs_PPU 4 //every cycle there are num_of_outputs_PPU data from Compress module
//`define num_of_data_Dram 16
//---------------------------------------lst---------------------------------------//
`define  size_data 16
`define  Accumulator_buffer_bank_size `max_size_H
`define  Accumulator_buffer_k_offset `Kc
`define  Accumulator_buffer_entry  `max_size_H //

//`define  max_popling_size_in 11
`define  pooling_num  3
`define  pooling_size  4
`define  pooling_buffer_entry  16
`define  pooling_out_size  4
`define NUM_SRC `F*`I
`define NUM_DST 2*`F*`I

`define FIFO_DEPTH (`NUM_DST)
`define  max_popling_size_output 25
`define max_index 15 //modify for test purpose

`define max_length_output 55 //modify for test purpose
// `define FIFO_busy_state_num `FIFO_DEPTH/2;
`define VERILOG_CLOCK_PERIOD   100
`define SYNTH_CLOCK_PERIOD     100 // Clock period for synth and memory latency

typedef struct packed {
    logic[`NUM_DST-1:0] crossbar_buffer_valid;
    logic signed  [`NUM_DST-1:0][`size_data-1:0] crossbar_buffer_data;
    logic[`NUM_DST-1:0][$clog2(`Accumulator_buffer_entry)-1:0]  x_dir;  //[$clog2(`max_size_output)-1:0]
    logic[`NUM_DST-1:0][$clog2(`Accumulator_buffer_bank_size)-1:0]y_dir; //[$clog2(`max_size_output)-1:0]
    logic[`NUM_DST-1:0][$clog2(`Accumulator_buffer_k_offset)-1:0] k_dir;
} crossbar_buffer_in_PACKET;

typedef struct packed {                                             
	logic signed [`size_data-1:0] buffer_data;
} Buffer_BLOCK;

typedef struct packed { 
    logic[`Accumulator_buffer_bank_size-1:0] valid;
    logic signed [`Accumulator_buffer_bank_size-1:0][`size_data-1:0] data;

} Buffer_PPU_PACKET;


typedef struct packed {                                             
	logic signed[`size_data-1:0] buffer_data;
    logic valid;
} Buffer_Pooling_BLOCK;


typedef struct packed { 
    logic[`pooling_out_size-1:0] valid;
    logic signed [`pooling_out_size-1:0][`size_data-1:0] data;
    

} PPU_compress_PACKET;

typedef struct packed { 
    logic[`pooling_out_size-1:0] valid;
    logic signed [`pooling_out_size-1:0][`size_data-1:0] data;
    logic[`NUM_DST-1:0][$clog2(`Accumulator_buffer_entry)-1:0]  x_dir;  //[$clog2(`max_size_output)-1:0]
    logic[`NUM_DST-1:0][$clog2(`Accumulator_buffer_bank_size)-1:0]y_dir; //[$clog2(`max_size_output)-1:
    
} PPU_dense_PACKET;
//-----------------------------------------------------------------------------------//

// typedef struct packed {
//     logic signed[2:0][`max_compressed_data-1:0][15:0] MEM_activations_compressed;
//     logic signed[2:0][`max_compressed_data-1:0][`bits_of_indices-1:0] MEM_activations_indices;
//     logic signed[`num_of_Conv_Layer:0][`max_num_K_prime-1:0][`max_num_channel-1:0][`Kc*`max_size_R*`max_size_R-1:0][15:0]  MEM_weight_compressed;
//     logic signed[`num_of_Conv_Layer:0][`max_num_K_prime-1:0][`max_num_channel-1:0][`Kc*`max_size_R*`max_size_R-1:0][`bits_of_indices-1:0] MEM_weight_indices;
//     logic signed[2:0][`max_compressed_data-1:0][15:0] MEM_activations_Dense;
//     logic signed[`num_of_Conv_Layer:0][`max_num_K_prime-1:0][`max_num_channel-1:0][`Kc*`max_size_R*`max_size_S-1:0][15:0]  MEM_weight_dense;
//     logic [$clog2(`max_num_Ht*`max_num_Wt)-1:0]    size_of_activations_dense;
//     logic [`num_of_Conv_Layer:0][$clog2(`Kc*`max_size_R*`max_size_R)-1:0]    size_of_Kc_Weights_dense;
//     //logic signed[`max_num_K-1:0][`max_size_R*`max_size_R-1:0][15:0]  MEM_weight_dense;
// } Dram_TB; //interface for DRAM initializing
typedef struct packed {
    logic signed[`num_of_data_Dram-1:0][15:0] data;

    logic[`num_of_data_Dram-1:0] valid;
    logic dense; //1 for dense, 0 for sparse
    logic[$clog2(`Kc):0] filter_channel;
} Dram_Weight; //interface for compressed data written into OARAM
typedef struct packed {
    logic[`num_of_data_Dram-1:0][`bits_of_indices-1:0] indices;
    logic[`num_of_data_Dram-1:0] valid;
    logic[$clog2(`Kc):0] filter_channel;
} Dram_Weight_indices; //interface for compressed data written into OARAM
typedef struct packed {
    logic signed[`num_of_data_Dram-1:0][15:0] data;
   // logic[`num_of_data_Dram-1:0][`bits_of_indices-1:0] indices;
    logic[`num_of_data_Dram-1:0] valid;
    logic dense;
    logic[$clog2(3)-1:0] input_channel;
} Dram_IARAM; //interface for compressed data written into OARAM
typedef struct packed {
    logic[`num_of_data_Dram-1:0][`bits_of_indices-1:0] indices;
    logic[`num_of_data_Dram-1:0] valid;
    logic[$clog2(3)-1:0] input_channel;
} Dram_IARAM_indices; //interface for compressed data written into OARAM
typedef struct packed {
    logic signed[`num_of_outputs_PPU-1:0][15:0] output_data;
    logic[`num_of_outputs_PPU-1:0][`bits_of_indices-1:0] output_indices;
    //logic [$clog2(`max_size_output)-1:0]num_of_compressed_data_PPU;
    logic[`num_of_outputs_PPU-1:0] valid;
    logic dense;
    logic[$clog2(`max_num_K)-1:0] feature_map_channel;
    logic compressed_value_count_valid;
    logic [$clog2(`max_compressed_data)-1 : 0] compressed_value_count;
} PPU_OARAM; //interface for compressed data written into OARAM

typedef struct packed {
    logic signed[`num_of_outputs_PPU-1:0][15:0] output_data;
    logic[`num_of_outputs_PPU-1:0][`bits_of_indices-1:0] output_indices;
    logic[`num_of_outputs_PPU-1:0] valid;
    logic compressed_value_count_valid;
    logic [$clog2(`max_compressed_data)-1 : 0] compressed_value_count;
} PPU_OUT; //interface for compressed data written into OARAM


// typedef struct packed {
//     logic [$clog2(`max_size_output)-1:0]num_of_compressed_data_PPU;
//     logic valid;
//     logic[$clog2(`max_num_K)-1:0] which_channel;
// } PPU_RAM_PACKET;

typedef struct packed {
    logic signed[`num_of_outputs_PPU-1:0][15:0] output_data;
    logic[`num_of_outputs_PPU-1:0][`bits_of_indices-1:0] output_indices;
    logic[`num_of_outputs_PPU-1:0] valid;
    logic compressed_value_count_valid;
    logic [$clog2(`max_compressed_data)-1 : 0] compressed_value_count;
   // logic dense;
   // logic[$clog2(`max_num_K_prime)-1:0] feature_map_channel;
} Compress_OARAM; //interface for compressed data written into OARAM


// typedef struct packed {
//     logic signed[`I*`F-1:0][15:0] output_data;
//     logic[`I*`F-1:0][$clog2(`max_size_W)-1:0] x;
//     logic[`I*`F-1:0][$clog2(`max_size_H)-1:0] y;
//     logic[`I*`F-1:0][$clog2(`max_num_K)-1:0] k;
//     logic[`I*`F-1:0] valid;
// } MUL_XBAR; //for fetching inputs data for multiplier array
// typedef struct packed {
//     logic signed[`I*`F-1:0][15:0] output_data;
//     logic[`I*`F-1:0] valid;
//  } MUL_DATA; //for fetching inputs data for multiplier array

typedef struct packed {
    logic signed[`I-1:0][15:0] IRAM_data;
    // logic[`I-1:0][$clog2(`max_size_W)-1:0] IRAM_x;
    // logic[`I-1:0][$clog2(`max_size_H)-1:0] IRAM_y;
    // logic[`I-1:0][$clog2(`max_num_K)-1:0] IRAM_k;
    logic[`I-1:0] valid;
} IARAM_MUL; //for fetching inputs data for multiplier array
typedef struct packed {
    logic signed[`I-1:0][15:0] IRAM_data;
    logic[`I-1:0][`bits_of_indices-1:0] indices;
    logic[`I-1:0] valid;
} IARAM_MUL_nx; //for fetching inputs data for multiplier array
typedef struct packed {
    logic signed[`I*`F-1:0][15:0] IRAM_data;
    logic[`I*`F-1:0][$clog2(`max_size_W)-1:0]  x;
    logic[`I*`F-1:0][$clog2(`max_size_H)-1:0] y;
    logic[`I*`F-1:0] valid;
} IARAM_MUL_Dense; 
typedef struct packed {
    logic signed[`I*`F-1:0][15:0] IRAM_data;
    logic[`I*`F-1:0] valid;
} IARAM_MUL_Dense_Cal; 
typedef struct packed {
    logic signed[15:0] Weight_data;
    logic valid;
} Weight_MUL_Dense_Cal; 
typedef struct packed {
    logic signed[15:0] Weight_data;
    logic[$clog2(`max_size_W)-1:0]  x;
    logic[$clog2(`max_size_H)-1:0] y;
    logic[$clog2(`Kc):0] Kc;
    logic valid;
} Weight_MUL_Dense; 
typedef struct packed {
    logic signed[`F-1:0][15:0] Weight_data;
    // logic[`F-1:0][$clog2(`max_size_W)-1:0] IRAM_x;
    // logic[`F-1:0][$clog2(`max_size_H)-1:0] IRAM_y;
    // logic[`F-1:0][$clog2(`max_num_K)-1:0] IRAM_k;
    logic[`F-1:0] valid;
} Weight_MUL; //for fetching inputs data for multiplier array

typedef struct packed {
    logic signed[`I-1:0][15:0] Weight_data;
    logic[`I-1:0][`bits_of_indices-1:0] indices;
    logic[`I-1:0] valid;
} Weight_MUL_nx; //for fetching inputs data for multiplier array
typedef struct packed {
    logic Partial_c;
    logic[$clog2(`max_size_R)-1:0]Current_R_dense;
    logic[$clog2(`max_size_S)-1:0]Current_S_dense;
    logic[`F*`I-1:0][$clog2(`max_size_W)-1:0]Current_W_dense;
    logic[`F*`I-1:0][$clog2(`max_size_H)-1:0]Current_H_dense;
    logic[`F*`I-1:0] dense_WH_pair_valid;
    logic[$clog2(`Kc):0] Current_Kc;//new added
    logic[$clog2(`max_num_K)-1:0] Current_k;
    logic[$clog2(`max_num_channel)-1:0] Current_c;
    logic[$clog2(`max_num_K)-1:0] Current_k_dense;
    logic[$clog2(`max_num_channel)-1:0] Current_c_dense;
    logic[$clog2(`max_num_channel)-1:0] nx_c;
    logic[$clog2(`max_num_Wt*`max_num_Ht)-1:0] Current_a;
    logic[$clog2(`Kc*`max_num_R*`max_num_S):0] Current_w;
    logic next_a;

    //logic[`num_of_Conv_Layer:0][`max_num_channel-1:0] valid_channel; //valid channel for each layer
    logic[`num_of_Conv_Layer:0][`max_num_channel-1:0] data_flow_channel;//data flow type for each channel for each layer, 1 for sparse, 0 for dense flow

    logic[`num_of_Conv_Layer:0] Current_Conv_Layer;
    logic[`num_of_Conv_Layer:0] nx_Conv_Layer;
    // logic Flag_remain_H_dense;
    // logic [$clog2(`max_size_W)-1:0] remain_H_dense;
    logic [$clog2(`max_num_Wt*`max_num_Ht)-1:0] remain_a;
    logic [$clog2(`Kc*`max_num_R*`max_num_S):0] remain_w;
    logic Flag_remain_a;
    logic Flag_remain_w;

    logic[$clog2(5)-1:0] state; //current state of PE controller
 logic[$clog2(5)-1:0] nx_state; //current state of PE controller
} State_of_PE; //for fetching inputs data for multiplier array
typedef struct packed {
    logic[`num_of_Conv_Layer:0][$clog2(`max_num_K_prime):0] k_Conv_Boundary;//calculate in testbench
    logic[`num_of_Conv_Layer:0][`max_num_K_prime-1:0][`max_num_channel-1:0][$clog2(`Kc*`max_num_R*`max_num_S):0] w_Conv_Boundary;
    logic[`num_of_Conv_Layer:0][$clog2(`max_num_channel):0] c_Conv_Boundary;
   // logic[$clog2(`num_of_Conv_Layer):0][$clog2(`max_num_Wt*`max_num_Ht)-1:0] a_Conv_Boundary;
    //logic[$clog2(`num_of_Conv_Layer):0][$clog2(`max_size_output)-1:0] num_of_compressed_weight;
    logic[`num_of_Conv_Layer:0][$clog2(`max_size_R):0] Size_of_R;
    logic[`num_of_Conv_Layer:0][$clog2(`max_size_S):0] Size_of_S; //R=S
    logic[`num_of_Conv_Layer:0][$clog2(`max_size_W):0] Size_of_W;
    logic[`num_of_Conv_Layer:0][$clog2(`max_size_H):0] Size_of_H;
    logic [`num_of_Conv_Layer:0][`Kc-1:0][$clog2(`max_size_R*`max_size_S):0] offset_dense_weight;
   // logic[`num_of_Conv_Layer:0][`max_num_channel:0] valid_channel; //valid channel for each layer
    logic[1:0][`max_num_channel:0] data_flow_channel;//data flow type for each channel for each layer, 1 for sparse, 0 for dense flow
    logic[`num_of_Conv_Layer:0][$clog2(`max_size_R*`max_size_S):0] each_filter_size;
    logic [`num_of_Conv_Layer:0][$clog2(`max_length_output)-1:0] Conv_size_output_Boundary;
    logic[`num_of_Conv_Layer:0][$clog2(`max_popling_size_output)-1:0] pooling_size_Boundary;
    logic[`pooling_num-1:0][$clog2(`max_popling_size_output)-1:0] stage_pooling_Boundary;
     logic[`num_of_Conv_Layer:0][$clog2(`max_stride_conv):0] stride_conv;
} Conv_filter_Parameter;
typedef struct packed {
    logic Req_Stream_filter_valid;
    ///logic[$clog2(`max_num_filter)-1:0] Req_Stream_filter_k;//filter k
   // logic[$clog2(`num_of_Conv_Layer)-1:0] Req_Stream_Conv_Layer_num;
    logic Req_Stream_input_valid;
} Req_Stream;//PE and TOP. request filter and input in lockstep
typedef struct packed {
    logic[`num_of_data_Dram-1:0] Response_Stream_filter_valid;
    logic[`num_of_data_Dram-1:0][15:0] Response_Stream_filter_data;
    logic[`num_of_data_Dram-1:0] Response_Stream_input_valid;
    logic[`num_of_data_Dram-1:0][15:0] Response_Stream_input_data;
    logic[$clog2(`num_of_PE)-1:0] Response_for_PE_num; 
} Response_Stream_PE;
typedef struct packed {
    logic Stream_filter_finish;//brodcast for all PE
    logic[`num_of_PE-1:0] Stream_input_finish_PE;
} Response_Stream_Complete;//Top

typedef struct packed {
    logic[`num_of_data_Dram-1:0] Response_Stream_filter_valid;
    logic[`num_of_data_Dram-1:0][15:0] Response_Stream_filter_data;
    logic[`num_of_data_Dram-1:0] Response_Stream_input_valid;
    logic[`num_of_data_Dram-1:0][15:0] Response_Stream_input_data;
    logic[`num_of_PE-1:0][$clog2(`num_of_PE)-1:0] Response_for_PE_num; //may same data give 2 PE, 
} Response_Stream_Top;//Top use,not PE use
// dzc//
 



typedef struct packed {
    logic signed [15:0] data;
    logic [$clog2(`max_size_W)-1:0] x;
    logic [$clog2(`max_size_H)-1:0] y;
    logic [$clog2(`Kc)-1:0] k;
    logic valid;
} DATA_PACKET; // Data packet in crossbar

typedef struct packed {
    logic signed[`I*`F-1:0][15:0] output_data;
    logic[`I*`F-1:0] valid;
} MUL_DATA; 
typedef struct packed {
    logic signed[`I * `F-1 : 0] [$clog2(`max_length_output) : 0] output_row_num;
     logic signed[`I * `F-1 : 0] [$clog2(`max_length_output) : 0] output_col_num;
    logic [`I * `F-1 : 0] [$clog2(`Kc)  : 0] k_num;
    logic [`I * `F-1 : 0] valid;
    
    logic signed[`I*`F-1:0][15:0] output_data;
    logic reg_MA_Partial_c;
} MUL_COORD_OUT; //results of multiplier array and corresponding coordinates in activation
typedef struct packed {
    logic decode_restart;
    logic Layer_change_flag;
    logic [$clog2(`max_size_R*`max_size_S):0] each_filter_size;
    logic [`I - 1 : 0] [$clog2(`max_index)-1 : 0] input_index_vector;
    logic [`F - 1 : 0] [$clog2(`max_index)-1 : 0] filter_index_vector;
    logic [2:0] stride;
    logic [$clog2(`max_num_Ht) : 0] input_side_length;
    logic [$clog2(`max_size_R) : 0] filter_side_length;
    Weight_MUL Weight_IN;
    IARAM_MUL IARAM_IN;
    IARAM_MUL_Dense IARAM_MUL_Dense_in;
    Weight_MUL_Dense Weight_MUL_Dense_in;
    logic sparse;
    logic Partial_c;
    logic K_changing;
} MUL_COORD_IN; 


//------------------------------Updated ZZ----------------------------------------//
`define max_stride_conv 4

typedef struct packed {
    logic signed[2:0][`max_compressed_data-1:0][15:0] MEM_activations_compressed;
    logic signed[2:0][`max_compressed_data-1:0][`bits_of_indices-1:0] MEM_activations_indices;
    logic signed[`num_of_Conv_Layer:0][`max_num_K_prime-1:0][`max_num_channel-1:0][`Kc*`max_size_R*`max_size_R-1:0][15:0]  MEM_weight_compressed;
    logic signed[`num_of_Conv_Layer:0][`max_num_K_prime-1:0][`max_num_channel-1:0][`Kc*`max_size_R*`max_size_R-1:0][`bits_of_indices-1:0] MEM_weight_indices;
    logic signed[2:0][`max_compressed_data-1:0][15:0] MEM_activations_Dense;
    logic signed[`num_of_Conv_Layer:0][`max_num_K_prime-1:0][`max_num_channel-1:0][`Kc*`max_size_R*`max_size_S-1:0][15:0]  MEM_weight_dense;
    logic [$clog2(`max_num_Ht*`max_num_Wt)-1:0]    size_of_activations_dense;
    logic [`num_of_Conv_Layer:0][$clog2(`Kc*`max_size_R*`max_size_R)-1:0]    size_of_Kc_Weights_dense;
    //logic signed[`max_num_K-1:0][`max_size_R*`max_size_R-1:0][15:0]  MEM_weight_dense;
} Dram_TB; //interface for DRAM initializing









