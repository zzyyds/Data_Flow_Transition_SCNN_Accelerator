`timescale 1ns/100ps

module coordinate_computation  (
    input logic clk,
    input logic rst,
    input logic decode_restart,
    input logic Layer_change_flag,
    input logic [$clog2(`max_size_R*`max_size_S):0] each_filter_size,

    //---------------------------------------------------//
    input logic [2:0] stride,                                  //
    input logic [$clog2(`max_num_Ht) : 0] input_side_length,   //
    input logic [$clog2(`max_size_R) : 0] filter_side_length,  //
    //---------------------------------------------------//
    input IARAM_MUL_Dense IARAM_MUL_Dense_in,            //
    input Weight_MUL_Dense Weight_MUL_Dense_in,          //
    input logic sparse,                                        //
    //---------------------------------------------------//
    input logic stall,
    input logic next_a,
    input logic first_Ex_state_cycle,

    input logic [`I - 1 : 0] [$clog2(`max_index)-1 : 0] input_index_vector,
    input logic [`F - 1 : 0] [$clog2(`max_index)-1 : 0] filter_index_vector,
    input logic K_changing,

    output logic signed [`I * `F-1 : 0] [$clog2(`max_length_output) : 0] output_row_num ,  
    output logic signed [`I * `F-1 : 0] [$clog2(`max_length_output) : 0] output_col_num ,
    output logic [`I * `F-1 : 0] [$clog2(`Kc)  : 0] k_num ,

    output logic [`I * `F-1 : 0] valid 

);
    logic signed [`I * `F-1 : 0] [$clog2(`max_length_output) : 0] nx_output_row_num ;  
    logic signed [`I * `F-1 : 0] [$clog2(`max_length_output) : 0] nx_output_col_num ;
    logic [`I * `F-1 : 0] [$clog2(`Kc)  : 0] nx_k_num ;

    logic [`I * `F-1 : 0] nx_valid ;

    integer i, j, n;

    logic signed [`I - 1 : 0] [$clog2(`max_num_Ht) : 0] input_row_num;  
    logic signed [`I - 1 : 0] [$clog2(`max_num_Wt) : 0] input_col_num;
    logic signed [`F - 1 : 0] [$clog2(`max_size_S) : 0] filter_row_num;  
    logic signed [`F - 1 : 0] [$clog2(`max_size_R) : 0] filter_col_num ;
    logic [`F - 1 : 0] [$clog2(`Kc)  : 0] k_num_temp;
    logic [`F - 1 : 0 ] res_rdy ;

    logic [7:0] input_filter_row_diff;
    logic [7:0] input_filter_col_diff;

    //logic [8:0] decode_cnt;
    //logic [8:0] invalid_tail;

    /*always_ff @(posedge clk) begin
        if (rst) begin
            decode_cnt <= 0;
        end
        else begin
            if (stall) begin
                decode_cnt <= decode_cnt;
            end
            else begin
                if (decode_cnt >= `max_compressed_weight_num-`F) begin
                    decode_cnt <= 0;
                end
                else begin
                    decode_cnt <= decode_cnt + `F;
                end
            end
        end
    end*/

    //assign invalid_tail = decode_cnt + `F - `max_compressed_weight_num;

    index_decoder_input decode_input (
        .clk(clk),
        .rst(rst),
        .decode_restart(decode_restart),
        .index_vector(input_index_vector),
        .input_side_length(input_side_length),
        .stall(stall),
        .next_a(next_a),
        .first_Ex_state_cycle(first_Ex_state_cycle),
    
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
        .stall(stall),
        .next_a(next_a),
        .K_changing(K_changing),
        //.decode_cnt(decode_cnt),
    
        .row_num(filter_row_num),  // y
        .col_num(filter_col_num),  // x
        .k_num(k_num_temp),
        .res_rdy(res_rdy)
    );

    logic signed [`I - 1 : 0] [$clog2(`max_num_Ht) : 0] input_y;  
    logic signed [`I - 1 : 0] [$clog2(`max_num_Wt) : 0] input_x;
    logic signed [`F - 1 : 0] [$clog2(`max_size_S) : 0] filter_y;  
    logic signed [`F - 1 : 0] [$clog2(`max_size_R) : 0] filter_x;
    logic [`F - 1 : 0] [$clog2(`Kc)  : 0] filter_k;

    logic[`I*`F-1:0][$clog2(`max_size_W)-1:0]  input_x_dense;
    logic[`I*`F-1:0][$clog2(`max_size_H)-1:0] input_y_dense;
    logic[`I*`F-1:0] input_valid_dense;

    logic[$clog2(`max_size_W)-1:0] filter_x_dense;
    logic[$clog2(`max_size_H)-1:0] filter_y_dense;
    logic[$clog2(`Kc):0] filter_k_dense;
    logic filter_valid_dense;

    // always_comb begin
    //     if (sparse) begin
    //         input_y = input_row_num;
    //         input_x = input_col_num;
    //         filter_y = filter_row_num;
    //         filter_x = filter_col_num;
    //         filter_k = k_num_temp;
    //     end
    //     else begin
    //         input_y = IARAM_MUL_Dense_in.y;
    //         input_x = IARAM_MUL_Dense_in.x;
    //         filter_y = Weight_MUL_Dense_in.y;
    //         filter_x = Weight_MUL_Dense_in.x;
    //         filter_k = Weight_MUL_Dense_in.Kc;
    //     end
    // end
    assign        input_y = input_row_num;
    assign        input_x = input_col_num;
    assign        filter_y = filter_row_num;
    assign        filter_x = filter_col_num;
    assign        filter_k = k_num_temp;

    assign        input_y_dense = IARAM_MUL_Dense_in.y;
    assign        input_x_dense = IARAM_MUL_Dense_in.x;
    assign        input_valid_dense = IARAM_MUL_Dense_in.valid;



    assign        filter_y_dense = Weight_MUL_Dense_in.y;
    assign        filter_x_dense = Weight_MUL_Dense_in.x;
    assign        filter_k_dense = Weight_MUL_Dense_in.Kc;
    assign        filter_valid_dense = Weight_MUL_Dense_in.valid;


    always_comb begin
        //valid = 0;
        input_filter_row_diff = 0;
        input_filter_col_diff = 0;
        for (n=0; n<`I * `F; n=n+1) begin
            nx_output_row_num[n] = 0;
            nx_output_col_num[n] = 0;
            nx_valid[n] = 0;
        end
	nx_k_num =k_num;
        if (sparse) begin

            if (stride == 1) begin
                for (i=0; i<`I; i=i+1) begin

                    for (j=0; j<`F; j=j+1) begin

                        // nx_output_row_num[i * `F + j] = input_y[i] - filter_y[j] + 1; 
                        // nx_output_col_num[i * `F + j] = input_x[i] - filter_x[j] + 1; 
                        nx_output_col_num[i * `F + j] = input_y[i] - filter_y[j] + 1; 
                        nx_output_row_num[i * `F + j] = input_x[i] - filter_x[j] + 1; 
                        nx_k_num[i * `F + j] = filter_k[j];
    
                        if ((nx_output_row_num[i * `F + j] > 0) && (nx_output_row_num[i * `F + j] <= (input_side_length - filter_side_length + 1) )
                            && (nx_output_col_num[i * `F + j] > 0) && (nx_output_col_num[i * `F + j] <= (input_side_length - filter_side_length + 1))) 
                            begin
                                nx_valid[i * `F + j] = res_rdy[j];
                            end
                            else begin
                                nx_valid[i * `F + j] = 0;
                            end

                    end
                end 
            end

            else if (stride == 4) begin
                for (i=0; i<`I; i=i+1) begin
                    for (j=0; j<`F; j=j+1) begin
                        input_filter_row_diff = input_y[i] - filter_y[j];
                        input_filter_col_diff = input_x[i] - filter_x[j];
                        nx_k_num[i * `F + j] = filter_k[j];

                        if ((input_filter_row_diff[1:0] == 2'b00) && (input_filter_col_diff[1:0] == 2'b00)) begin
                            nx_output_col_num[i * `F + j] = (input_filter_row_diff >> 2) + 1;
                            nx_output_row_num[i * `F + j] = (input_filter_col_diff >> 2) + 1;
                            nx_valid[i * `F + j] = res_rdy[j];
                        end
                        else begin
                            nx_output_col_num[i * `F + j] = 0;
                           nx_output_row_num[i * `F + j] = 0;
                            nx_valid[i * `F + j] = 0;
                        end           
                    end
                end

            end      
        end

        else begin
            if (stride == 1) begin
                for (int k=0; k<`I*`F; k=k+1) begin
                    nx_output_row_num[k] = input_y_dense[k] - filter_y_dense + 1;
                    nx_output_col_num[k] = input_x_dense[k] - filter_x_dense + 1;
                    nx_k_num[k] = filter_k_dense;
                
                    if ((nx_output_row_num[k] > 0) && (nx_output_row_num[k] <= (input_side_length - filter_side_length + 1) )
                        && (nx_output_col_num[k] > 0) && (nx_output_col_num[k] <= (input_side_length - filter_side_length + 1))) 
                        begin
                            nx_valid[k] = filter_valid_dense;
                        end
                        else begin
                            nx_valid[k] = 0;
                        end
                end
            end
            else if (stride == 4) begin
                for (int k=0; k<`I*`F; k=k+1) begin
                    input_filter_row_diff = input_y_dense[k] - filter_y_dense;
                    input_filter_col_diff = input_x_dense[k] - filter_x_dense;

                        if ((input_filter_row_diff[1:0] == 2'b00) && (input_filter_col_diff[1:0] == 2'b00)) begin
                            nx_output_row_num[k] = (input_filter_row_diff >> 2) + 1;
                            nx_output_col_num[k] = (input_filter_col_diff >> 2) + 1;
                            nx_valid[k] = filter_valid_dense;
                        end
                        else begin
                            nx_output_row_num[k] = 0;
                            nx_output_col_num[k] = 0;
                            nx_valid[k] = 0;
                        end  
                end
            end
            
        end
    end

    always_ff@(posedge clk)begin
        if(rst)begin
            output_row_num<=#1 'd0;
            output_col_num<=#1 'd0;
            k_num <=#1 'd0;
            valid <=#1 'd0;
        end
        else begin
            if(stall)begin
                output_row_num<=#1 output_row_num;
                output_col_num<=#1 output_col_num;
                k_num <=#1 k_num;
                valid <=#1 valid;
            end
            else begin
                output_row_num<=#1 nx_output_row_num;
                output_col_num<=#1 nx_output_col_num;
                k_num <=#1 nx_k_num;
                valid <=#1 nx_valid;

            end

        end

    end

    



endmodule
