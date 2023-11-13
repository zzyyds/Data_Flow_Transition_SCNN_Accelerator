`timescale 1ns/100ps

module index_decoder 
    #(parameter vector_length = 4,
      parameter max_index = 15,
      parameter cols = 16,
      parameter rows = 16,
      parameter N=$clog2(cols*rows)+1,
      parameter M=$clog2(cols)+1,
      parameter N_ACT = M+N-1)
       (

    input logic clk,
    input logic rst_n,
    input logic last_decode,
    input logic [$clog2(max_index)-1 : 0] index_vector [0 : vector_length-1],

    output logic [$clog2(rows) : 0] row_num [0 : vector_length-1],
    output logic [$clog2(cols) : 0] col_num [0 : vector_length-1]

);

    logic                 data_rdy  [0 : vector_length-1];  
    logic [N-1:0]         dividend  [0 : vector_length-1];   
    logic [M-1:0]         divisor;    
    logic                 res_rdy   [0 : vector_length-1];
    logic [N_ACT-M:0]     merchant  [0 : vector_length-1];  
    logic [M-1:0]         remainder [0 : vector_length-1]; 

    logic [N-1:0] sequence_num [0 : vector_length-1];
    logic [N-1:0] head_start_index;

    assign divisor = cols;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            head_start_index <= 0;
        end
        else begin
            if (last_decode)
                head_start_index <= 0;
            else
                head_start_index <= sequence_num[vector_length-1];
        end    
    end

    integer i, k, p, q, m;
    always_comb begin
        for (i=0; i<vector_length; i=i+1) begin
            sequence_num[i] = 0;
        end
        sequence_num[0] = head_start_index + index_vector[0] + 1;
        for (q=1; q<vector_length; q=q+1) begin
            sequence_num[q] = sequence_num[q-1] + index_vector[q] + 1;
        end
    end

  
    genvar j;
    generate
        for (j=0; j<vector_length; j=j+1) begin: gen_divider
            divider #(.max_index(max_index), .rows(rows), .cols(cols)) div (
                .clk(clk),
                .rst_n(rst_n),
                .data_rdy(data_rdy[j]),
                .dividend(dividend[j]),
                .divisor(divisor),

                .res_rdy(res_rdy[j]),
                .merchant(merchant[j]),
                .remainder(remainder[j])
            );
        end
    endgenerate

    always_ff@(posedge clk) begin
        if (!rst_n) begin
            for (k=0; k<vector_length; k=k+1) begin
                data_rdy[k] <= 0;
                dividend[k] <= 0;
            end
        end

        else begin
            for (k=0; k<vector_length; k=k+1) begin
                data_rdy[k] <= 1;
                dividend[k] <= sequence_num[k];
            end
        end
    end

    always_comb begin
        for (m=0; m<vector_length; m=m+1) begin
            row_num[m] = 0;
            col_num[m] = 0;
        end

        for (p=0; p<vector_length; p=p+1) begin
            if (res_rdy[p]) begin
                row_num[p] = (remainder[p]==0) ? merchant[p] : merchant[p]+1;
                col_num[p] = (remainder[p]==0) ? cols : remainder[p];
            end
        end
    end

endmodule
