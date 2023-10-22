`define num_of_PE 4
`define max_num_K 384//k_Conv_Boundary
`define max_num_filter 384
`define max_num_channel 384
`define max_num_S 11
`define max_num_R 11//w_Conv_Boundary
`define max_size_output 55 // one dimension
`define max_num_Wt 60 // for caculating a boundary
`define max_num_Ht 60
`define num_of_Conv_Layer 5
`define Kc 4
`define F 4
`define I 4



`define clock_frequency 1       //unit GHZ
`define num_data 50*8/`clock_frequency/16 //8(Bytes), 16 bits for one data


typedef struct packed {
   logic[`max_num_channel-1:0] data_flow_PPU; //from ppu to decide which data flow is needed, 0 for dense data flow, 1 for sparse data flow
   logic[$clog2(`max_size_output)-1:0] num_of_compressed_data;//number of data after compression
} PPU_to_CNTL;
typedef struct packed {
    logic[$clog2(`num_of_Conv_Layer)-1:0][$clog2(`max_num_K)-1:0] k_Conv_Boundary;//calculate in testbench
    logic[$clog2(`num_of_Conv_Layer)-1:0][$clog2(`Kc*max_num_R*max_num_S/`F)-1:0] w_Conv_Boundary;
    logic[$clog2(`num_of_Conv_Layer)-1:0][$clog2(`max_num_channel)-1:0] c_Conv_Boundary;
    logic[$clog2(`num_of_Conv_Layer)-1:0][$clog2(`max_num_Wt*max_num_Ht/`I)-1:0] a_Conv_Boundary;
    logic[$clog2(`num_of_Conv_Layer)-1:0][$clog2(`max_size_output)-1:0] num_of_compressed_weight;
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
 