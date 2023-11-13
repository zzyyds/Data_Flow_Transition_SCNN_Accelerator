`timescale 1ns/100ps

module coordinate_computation #(parameter bit_width = 4, 
                                parameter input_cols = 16, parameter input_rows = 16, 
                                parameter filter_cols = 3, parameter filter_rows = 3,
                                parameter input_vector_length =  4,
                                parameter filter_vector_length = 4,
                                parameter max_index = 15,
                                parameter output_rows = input_rows - filter_rows + 1,
                                parameter output_cols = input_cols - filter_cols + 1,
                                parameter output_vector_length = input_vector_length * filter_vector_length) (
    input logic clk,
    input logic rst_n,
    input logic last_decode_input,
    //input logic last_decode_filter,
    input logic[$clog2(`max_size_R*`max_size_S)] each_filter_size,
    input logic [`num_of_Conv_Layer:0] Current_Conv_Layer,


    input logic [$clog2(max_index)-1 : 0] input_index_vector [input_vector_length-1 : 0],
    input logic [$clog2(max_index)-1 : 0] filter_index_vector [filter_vector_length-1 : 0],

    output logic [$clog2(output_rows) : 0] output_row_num [output_vector_length-1 : 0],
    output logic [$clog2(output_cols) : 0] output_col_num [output_vector_length-1 : 0],

    output logic [output_vector_length-1 : 0] valid 

);

    integer i, j, n;
    

    logic [$clog2(input_rows) : 0] input_row_num [input_vector_length-1 : 0];
    logic [$clog2(input_cols) : 0] input_col_num [input_vector_length-1 : 0];
    logic [$clog2(filter_rows) : 0] filter_row_num [filter_vector_length-1 : 0];
    logic [$clog2(filter_cols) : 0] filter_col_num [filter_vector_length-1 : 0];

    //zz change//
    logic[`num_of_Conv_Layer:0] prev_Current_Conv_Layer;
    logic Layer_change_flag;
    //--------//

    //logic [$clog2(output_rows) : 0] output_row_num_temp [output_vector_length-1 : 0];
    //logic [$clog2(output_cols) : 0] output_col_num_temp [output_vector_length-1 : 0];
    assign Layer_change_flag=prev_Current_Conv_Layer==Current_Conv_Layer?1'b0:1'b1;
    index_decoder #(.vector_length(input_vector_length), .max_index(max_index), .cols(input_cols), .rows(input_rows)) decode_input (
        .clk(clk),
        .rst_n(rst_n),
        .last_decode(last_decode_input),
        .index_vector(input_index_vector),

    
        .row_num(input_row_num),
        .col_num(input_col_num)
    );

    index_decoder_filter #(.vector_length(filter_vector_length), .max_index(max_index), .cols(filter_cols), .rows(filter_rows)) decode_filter (
        .clk(clk),
        .rst_n(rst_n),
        .index_vector(filter_index_vector),
       // .last_decode(last_decode_filter),
        .each_filter_size(each_filter_size),
        .Layer_change_flag(Layer_change_flag),
        .row_num(filter_row_num),
        .col_num(filter_col_num)
    );
    always_comb begin
        valid = 0;
        for (n=0; n<output_vector_length; n=n+1) begin
            output_row_num[n] = 0;
            output_col_num[n] = 0;
        end

        for (i=0; i<input_vector_length; i=i+1) begin

            for (j=0; j<filter_vector_length; j=j+1) begin

                output_row_num[i * filter_vector_length + j] = input_row_num[i] - filter_row_num[j] + 1; 
                output_col_num[i * filter_vector_length + j] = input_col_num[i] - filter_col_num[j] + 1; 
 
                if ((output_row_num[i * filter_vector_length + j] > 0) && (output_row_num[i * filter_vector_length + j] <= output_rows) 
                    && (output_col_num[i * filter_vector_length + j] > 0) && (output_col_num[i * filter_vector_length + j] <= output_cols)) 
                    begin
                        valid[i * filter_vector_length + j] = 1;
                    end
                    else begin
                        valid[i * filter_vector_length + j] = 0;
                    end

            end
        end 
        
    end
    always_ff@(posedge clk)begin
        if(!rst_n)begin
            prev_Current_Conv_Layer<='d0;
        end
        else begin
            prev_Current_Conv_Layer<=Current_Conv_Layer;
        end


    end

endmodule
// module Multiplier_Array
// (
// //-------------------Input-------------------------//
//     input clk,
//     input rst,


//     input Weight_MUL Weight_IN,
//     input IARAM_MUL IARAM_IN,

//     output MUL_XBAR MUL_XBAR_OUT
// );
// MUL_XBAR nx_MUL_XBAR_OUT;
// always_comb begin
//     nx_MUL_XBAR_OUT='d0;
//     for(int i=0;i<`I;i++)begin
//         if(IARAM_IN.valid)begin
//             for(int j=0;j<`F;j++)begin
//                 if(Weight_IN.valid)begin
//                     nx_MUL_XBAR_OUT.valid[i*`I+j]=1'b1;
//                     nx_MUL_XBAR_OUT.output_data[i*`I+j]=IARAM_IN.IRAM_data[i]*Weight_IN.Weight_data[j];
//                 end
//                 else begin
//                     nx_MUL_XBAR_OUT.valid[i*`I+j]=1'b0;
//                     nx_MUL_XBAR_OUT.output_data[i*`I+j]='d0;

//                 end

//             end

//         end
//         else begin

//             for(int j=0;j<`F;j++)begin
//                     nx_MUL_XBAR_OUT.valid[i*`I+j]=1'b0;
//                     nx_MUL_XBAR_OUT.output_data[i*`I+j]='d0;

//                // end
//             end


//         end

//     end


// end

// //because F=I=4 is fixed

// always_ff@(posedge clk)begin
//     if(rst)begin
//         MUL_XBAR_OUT<=#1 'd0;
//     end
//     else begin
//         MUL_XBAR_OUT<=#1 nx_MUL_XBAR_OUT;
//     end
// end




// endmodule
