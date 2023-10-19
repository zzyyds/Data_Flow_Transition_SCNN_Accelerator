`define num_of_PE 4
`define max_num_filter 384
`define num_of_Conv_Layer 5
// `define num_of_filters_1 96//K1
`define Kc 4
//`define k1_Boundary `num_of_filters_1/`Kc-1 //k1'
`define C1 3

`define R1 11
`define S1 11
`define F1 `Kc*`S1 //can be defined random
`define w1_Boundary `Kc*`R1*`S1/`F1//=R1
`define I1 `F1 //I1=F1, maybe better for flow control
`define c1_Boundary `C1-1
`define clock_frequency 1       //unit GHZ
`define num_data 50*8/`clock_frequency/16 //8(Bytes), 16 bits for one data

typedef struct packed {
    logic[$clog2(55):0] W; //W of feature map//max for num  of W in alexnet is 55 for conv layer
    logic[$clog2(55):0] H;
    logic[$clog2(384):0] C;
} input_activation_Parameter;//used in PPU
typedef struct packed {
    logic[$clog2(num_of_Conv_Layer)-1:0][$clog2(384):0] k_Conv_Boundary;//calculate in testbench
} filter_Parameter;
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

    logic Stream_filter_finish;//brodcast for all PE
    logic[$clog2(`num_of_PE)-1:0] Stream_input_finish_PE_num;
} Response_Stream_PE;
typedef struct packed {
    logic[`num_data-1:0] Response_Stream_filter_valid;
    logic[`num_data-1:0][15:0] Response_Stream_filter_data;
    logic[`num_data-1:0] Response_Stream_input_valid;
    logic[`num_data-1:0][15:0] Response_Stream_input_data;
    logic[`num_of_PE-1:0][$clog2(`num_of_PE)-1:0] Response_for_PE_num; //may same data give 2 PE, 
    logic Stream_filter_finish;//brodcast for all PE
    logic[`num_of_PE-1:0] Stream_input_finish_PE_num;
} Response_Stream_Top;//Top use,not PE use
 