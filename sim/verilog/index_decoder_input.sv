`timescale 1ns/100ps

module index_decoder_input
    #(
      parameter N=$clog2(`max_num_Wt*`max_num_Ht)+2,
      parameter M=$clog2(`max_num_Wt)+1,
      parameter N_ACT = M+N-1
    )
(

    input logic clk,
    input logic rst,
    input logic decode_restart,
    input logic [`I-1:0][$clog2(`max_index)-1 : 0] index_vector, 
    input [$clog2(`max_num_Ht) : 0] input_side_length,
    input logic stall,
    input logic next_a,
    input logic first_Ex_state_cycle,

    output  logic [`I-1:0][$clog2(`max_num_Ht) : 0] row_num ,
    output  logic [`I-1:0][$clog2(`max_num_Wt) : 0] col_num 

);

    logic [`I-1:0]                data_rdy  ;  
    logic [`I-1:0][N-1:0]         dividend  ;   
    logic [M-1:0]                 divisor;    
    logic [`I-1:0]                res_rdy   ;
    logic [`I-1:0][N_ACT-M:0]     quotient  ;  
    logic [`I-1:0][M-1:0]         remainder ; 

    logic [`I-1:0][N-1:0] sequence_num ;
    logic [`I-1:0][N-1:0] sequence_num_d1 ;
    logic [N-1:0] head_start_index;

    assign divisor = input_side_length;

    always_ff @(posedge clk) begin
        if (rst) begin
            head_start_index <=#1 0;
        end
        else begin
            if (decode_restart)begin
                head_start_index <=#1 0;
            end
            else if(next_a)begin
                head_start_index <=#1 sequence_num[`I-1];
            end    
            else begin
                head_start_index<=#1 head_start_index;
            end
        end
    end

    integer i, k, p, q, m, n;
    always_comb begin

        for (i=0; i<`I; i=i+1) begin
            sequence_num[i] = 0;
            dividend[i]='d0;
            data_rdy[i]='d0;

        end

        //if (!stall) begin
            sequence_num[0] = head_start_index + index_vector[0] + 1;
            for (q=1; q<`I; q=q+1) begin
                sequence_num[q] = sequence_num[q-1] + index_vector[q] + 1;
            end
        //end
       // else begin
          //  sequence_num = sequence_num_d1;
//end
                for(int i=0;i<`F;i++)begin
                dividend[i]=sequence_num[i];
                data_rdy[i] = 1;
                end

    end

  
    genvar j;
    generate
        for (j=0; j<`I; j=j+1) begin: gen_divider
            divider div (
                .clk(clk),
                .rst(rst),
                .data_rdy(data_rdy[j]),
                .dividend(dividend[j]),
                .divisor(divisor),
                .k_in(),
                .stall(stall),

                .res_rdy(res_rdy[j]),
                .quotient(quotient[j]),
                .remainder(remainder[j]),
                .k_out()
            );
        end
    endgenerate

    // always_ff@(posedge clk) begin
    //     if (rst) begin
    //         for (k=0; k<`I; k=k+1) begin
    //             data_rdy[k] <= 0;
    //             dividend[k] <= 0;
    //         end
    //     end

    //     else begin
    //         for (k=0; k<`I; k=k+1) begin
    //             data_rdy[k] <= 1;
    //             dividend[k] <= sequence_num[k];
    //         end
    //     end
    // end

    always_comb begin
        for (m=0; m<`I; m=m+1) begin
            row_num[m] = 0;
            col_num[m] = 0;
        end

        for (p=0; p<`I; p=p+1) begin
            if (res_rdy[p]) begin
                row_num[p] = (remainder[p]==0) ? quotient[p] : quotient[p]+1;
                col_num[p] = (remainder[p]==0) ? input_side_length : remainder[p];
            end
        end
    end

//------------------------------------------------------//
    always_ff @(posedge clk) begin
        if (rst) begin
            for (n=0; n<`I; n=n+1) begin
                sequence_num_d1[n] <=#1 0;
            end
        end
        else begin
            for (n=0; n<`I; n=n+1) begin
                if(!stall)begin
                sequence_num_d1[n] <=#1 sequence_num[n];
                end
                else begin
                    sequence_num_d1[n]<=#1 sequence_num_d1[n];

                end
            end
        end
    end
endmodule
