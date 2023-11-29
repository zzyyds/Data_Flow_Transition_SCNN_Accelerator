module coordinate_computation  (
    input logic clk,
    input logic rst,
    input logic decode_restart,
    input logic Layer_change_flag,
    input logic [$clog2(`max_size_R*`max_size_S):0] each_filter_size,

    //---------------------------------------------------//
    input [2:0] stride,                                  //
    input [$clog2(`max_num_Ht) : 0] input_side_length,   //
    input [$clog2(`max_size_R) : 0] filter_side_length,  //
    //---------------------------------------------------//
    input IARAM_MUL_Dense IARAM_MUL_Dense_in,            //
    input Weight_MUL_Dense Weight_MUL_Dense_in,          //
    input sparse,                                        //
    //---------------------------------------------------//

    input logic [`I - 1 : 0] [$clog2(`max_index)-1 : 0] input_index_vector,
    input logic [`F - 1 : 0] [$clog2(`max_index)-1 : 0] filter_index_vector,

    output logic [`I * `F-1 : 0] [$clog2(`max_size_output) : 0] output_row_num ,  
    output logic [`I * `F-1 : 0] [$clog2(`max_size_output) : 0] output_col_num ,
    output logic [`I * `F-1 : 0] [$clog2(`max_num_K)  : 0] k_num ,

    output logic [`I * `F-1 : 0] valid 

);

    integer i, j, n;

    logic [`I - 1 : 0] [$clog2(`max_num_Ht) : 0] input_row_num;  
    logic [`I - 1 : 0] [$clog2(`max_num_Wt) : 0] input_col_num;
    logic [`F - 1 : 0] [$clog2(`max_size_S) : 0] filter_row_num;  
    logic [`F - 1 : 0] [$clog2(`max_size_R) : 0] filter_col_num ;
    logic [`F - 1 : 0] [$clog2(`max_num_K)  : 0] k_num_temp;
    logic [`F - 1 : 0 ] res_rdy ;

    logic [7:0] input_filter_row_diff;
    logic [7:0] input_filter_col_diff;

    index_decoder_input decode_input (
        .clk(clk),
        .rst(rst),
        .decode_restart(decode_restart),
        .index_vector(input_index_vector),
        .input_side_length(input_side_length),
    
        .row_num(input_row_num),
        .col_num(input_col_num)
    );

    index_decoder_filter decode_filter (
        .clk(clk),
        .rst(rst),
        .index_vector(filter_index_vector),
        //.last_decode(last_decode_filter),
        .each_filter_size(each_filter_size),
        .Layer_change_flag(Layer_change_flag),
        .filter_side_length(filter_side_length),
    
        .row_num(filter_row_num),  // y
        .col_num(filter_col_num),  // x
        .k_num(k_num_temp),
        .res_rdy(res_rdy)
    );

    logic [`I - 1 : 0] [$clog2(`max_num_Ht) : 0] input_y;  
    logic [`I - 1 : 0] [$clog2(`max_num_Wt) : 0] input_x;
    logic [`F - 1 : 0] [$clog2(`max_size_S) : 0] filter_y;  
    logic [`F - 1 : 0] [$clog2(`max_size_R) : 0] filter_x;
    logic [`F - 1 : 0] [$clog2(`max_num_K)  : 0] filter_k;

    always_comb begin
        if (sparse) begin
            input_y = input_row_num;
            input_x = input_col_num;
            filter_y = filter_row_num;
            filter_x = filter_col_num;
            filter_k = k_num_temp;
        end
        else begin
            input_y = IARAM_MUL_Dense_in.y;
            input_x = IARAM_MUL_Dense_in.x;
            filter_y = Weight_MUL_Dense_in.y;
            filter_x = Weight_MUL_Dense_in.x;
            filter_k = Weight_MUL_Dense_in.Kc;
        end
    end

    always_comb begin
        //valid = 0;
        input_filter_row_diff = 0;
        input_filter_col_diff = 0;
        for (n=0; n<`I * `F; n=n+1) begin
            output_row_num[n] = 0;
            output_col_num[n] = 0;
            valid[n] = 0;
        end

        if (stride == 1) begin
            for (i=0; i<`I; i=i+1) begin

                for (j=0; j<`F; j=j+1) begin

                    output_row_num[i * `F + j] = input_y[i] - filter_y[j] + 1; 
                    output_col_num[i * `F + j] = input_x[i] - filter_x[j] + 1; 
                    k_num[i * `F + j] = filter_k[j];
 
                    if ((output_row_num[i * `F + j] > 0) && (output_row_num[i * `F + j] <= (input_side_length - filter_side_length + 1) )
                        && (output_col_num[i * `F + j] > 0) && (output_col_num[i * `F + j] <= (input_side_length - filter_side_length + 1))) 
                        begin
                            valid[i * `F + j] = res_rdy[j];
                        end
                        else begin
                            valid[i * `F + j] = 0;
                        end

                end
            end 
        end

        else if (stride == 4) begin
            for (i=0; i<`I; i=i+1) begin
                for (j=0; j<`F; j=j+1) begin
                    input_filter_row_diff = input_y[i] - filter_y[j];
                    input_filter_col_diff = input_x[i] - filter_x[j];
                    k_num[i * `F + j] = filter_k[j];

                    if ((input_filter_row_diff[1:0] == 2'b00) && (input_filter_col_diff[1:0] == 2'b00)) begin
                        output_row_num[i * `F + j] = (input_filter_row_diff >> 2) + 1;
                        output_col_num[i * `F + j] = (input_filter_col_diff >> 2) + 1;
                        valid[i * `F + j] = res_rdy[j];
                    end
                    else begin
                        output_row_num[i * `F + j] = 0;
                        output_col_num[i * `F + j] = 0;
                        valid[i * `F + j] = 0;
                    end           
                end
            end
        end      
    end

endmodule