`timescale 1ns/100ps

module index_decoder_filter 
    #(
      parameter N=$clog2(`max_num_Wt*`max_num_Ht)+2,
      parameter M=$clog2(`max_num_Wt)+1,
      parameter N_ACT = M+N-1
      )
(

    input logic clk,
    input logic rst,
    input logic stall,
   // input logic last_decode,
    input logic [`F - 1 : 0] [$clog2(`max_index)-1 : 0] index_vector ,  
    input logic [$clog2(`max_size_R*`max_size_S) : 0] each_filter_size,
    input logic Layer_change_flag,
    input [$clog2(`max_size_R) : 0] filter_side_length,  //
    //input logic [8:0] decode_cnt,
    input logic next_a,
    input logic K_changing,

    output logic [`F - 1 : 0] [$clog2(`max_size_S) : 0] row_num ,
    output logic [`F - 1 : 0] [$clog2(`max_size_R) : 0] col_num ,
    output logic [`F - 1 : 0] [$clog2(`Kc) : 0] k_num ,
    output logic [`F - 1 : 0] res_rdy 

);
    logic [`F - 1 : 0]                data_rdy;  
    logic [`F - 1 : 0][N-1:0]         dividend;   
    logic [M-1:0]                     divisor;    
    //logic                 res_rdy   ;
    logic [`F - 1 : 0][N_ACT-M:0]     quotient;  
    logic [`F - 1 : 0][M-1:0]         remainder; 
    logic [`F - 1 : 0][$clog2(`Kc):0] k_in;
    logic [`F - 1 : 0][$clog2(`Kc):0] k_out;

    logic [`F - 1 : 0][N-1:0] sequence_num;
    logic [`F - 1 : 0][$clog2(`Kc):0] k_num_temp;
    logic [N-1:0] head_start_index;
    logic [$clog2(`Kc):0] prev_k;

    logic [`F - 1 : 0][N-1:0] sequence_num_d1;
    logic [`F - 1 : 0][$clog2(`Kc):0] k_num_temp_d1;

    assign divisor = filter_side_length;

    always_ff @(posedge clk) begin
        if (rst || Layer_change_flag || next_a||K_changing) begin
            head_start_index <= 0;
            prev_k <= 1;
        end

        else begin
            /*if (decode_cnt +`F > `max_compressed_weight_num) begin
                head_start_index <= 0;
                prev_k <= 1;               
            end
            else begin*/
            if(stall)begin
                head_start_index <=#1 head_start_index;
                prev_k <=#1 prev_k;
            end
            else begin

                head_start_index <=#1  sequence_num[`F-1];
                prev_k <=#1 k_num_temp[`F-1];
            end    
        end
    end

    integer i, k, p, q, m, n;
    always_comb begin
        for (i=0; i<`F; i=i+1) begin
            sequence_num[i] = 0;
            k_num_temp[i] = 0;
            data_rdy[i] = 0;
            dividend[i] = 0;
             k_in[i] = 0;
                
        end

        // if (!stall) begin
            k_num_temp[0] = prev_k;
            sequence_num[0] = head_start_index + index_vector[0] + 1;

            if (sequence_num[0] > each_filter_size)begin
                sequence_num[0] = sequence_num[0] - each_filter_size;
                k_num_temp[0] = prev_k + 1;
            end
            
            for (q=1; q<`F; q=q+1) begin
                sequence_num[q] = sequence_num[q-1] + index_vector[q] + 1;
                k_num_temp[q] = k_num_temp[q-1];

               /* if ((decode_cnt +`F > `max_compressed_weight_num) && (index_vector[q] == 0))begin 
                    sequence_num[q] = sequence_num[q-1];
                    k_num_temp[q] = k_num_temp[q-1];
                end

                else begin*/
                    if (sequence_num[q] > each_filter_size) begin
                        sequence_num[q] = sequence_num[q] - each_filter_size;
                        k_num_temp[q] = k_num_temp[q-1] + 1;
                    end
                //end
            end
        // end
        // else begin
        //     k_num_temp = k_num_temp_d1;
        //     sequence_num = sequence_num_d1;
        // end
        for(int i=0;i<`F;i++)begin
                dividend[i]=sequence_num[i];
                data_rdy[i] = 1;
                k_in[i] = k_num_temp[i];

        end


    end

    genvar j;
    generate
        for (j=0; j<`F; j=j+1) begin: gen_divider
            divider div ( 
                .clk(clk),
                .rst(rst),
                .data_rdy(data_rdy[j]),
                .dividend(dividend[j]),
                .divisor(divisor),
                .k_in(k_in[j]),
                .stall(stall),

                .res_rdy(res_rdy[j]),
                .quotient(quotient[j]),
                .remainder(remainder[j]),
                .k_out(k_out[j])
            );
        end
    endgenerate

    // always_ff@(posedge clk) begin
    //     if (rst || Layer_change_flag || next_a) begin
    //         for (k=0; k<`F; k=k+1) begin
    //             data_rdy[k] <= 0;
    //             dividend[k] <= 0;
    //             k_in[k] <= 0;

    //         end
    //     end

    //     else begin
    //         for (k=0; k<`F; k=k+1) begin
    //             data_rdy[k] <= 1;
    //             dividend[k] <= sequence_num[k];
    //             k_in[k] <= k_num_temp[k];
    //         end
    //     end
    // end

    always_comb begin
        for (m=0; m<`F; m=m+1) begin
            row_num[m] = 0;
            col_num[m] = 0;
            k_num[m] = 0;
        end

        for (p=0; p<`F; p=p+1) begin
            if (res_rdy[p]) begin
                row_num[p] = (remainder[p]==0) ? quotient[p] : quotient[p]+1;
                col_num[p] = (remainder[p]==0) ? filter_side_length : remainder[p];
                k_num[p] = k_out[p];
            end
        end
    end

//------------------------------------------------------//
    always_ff @(posedge clk) begin
        if (rst || Layer_change_flag || next_a) begin
            for (n=0; n<`F; n=n+1) begin
                sequence_num_d1[n] <=#1 0;
                k_num_temp_d1[n] <=#1 0;
            end
        end
        else begin
            for (n=0; n<`F; n=n+1) begin
                if(!stall)begin
                    sequence_num_d1[n] <=#1 sequence_num[n];
                    k_num_temp_d1[n] <=#1 k_num_temp[n];
                end
                else begin
                    sequence_num_d1[n]<=#1 sequence_num_d1[n];
                    k_num_temp_d1[n]<=#1 k_num_temp_d1[n];
                end

            end
        end
    end

endmodule