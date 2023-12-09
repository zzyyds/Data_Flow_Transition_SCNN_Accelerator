`timescale 1ns/100ps

module divider
    #( 
      parameter N=$clog2(`max_num_Wt*`max_num_Ht)+2,
      parameter M=$clog2(`max_num_Wt)+1,
      parameter N_ACT = M+N-1
      )
    (
      input logic                     clk,
      input logic                     rst,
      input logic                     data_rdy,  
      input logic [N-1:0]             dividend,  
      input logic [M-1:0]             divisor,  
      input logic [$clog2(`max_num_K):0] k_in,
      input logic                     stall,

      output logic                    res_rdy ,
      output logic [N_ACT-M:0]        quotient ,  
      output logic [M-1:0]            remainder,
      output logic [$clog2(`max_num_K):0] k_out
    );

    logic [N_ACT-M:0][N_ACT-M-1:0]   dividend_t ;
    logic [N_ACT-M:0][M-1:0]         divisor_t ;
    logic [N_ACT-M:0][M-1:0]         remainder_t ;
    logic [N_ACT-M:0]                rdy_t ;
    logic [N_ACT-M:0][N_ACT-M:0]     quotient_t ;
    logic [N_ACT-M:0][$clog2(`max_num_K):0] k_out_t ;

    divider_cell      #(.N(N_ACT), .M(M))
       u_divider_step0
    ( .clk              (clk),
      .rst             (rst),
      .en               (data_rdy),
      .busy              (stall),
      .dividend         ({{(M){1'b0}}, dividend[N-1]}),
      .divisor          (divisor),     
      .k_in             (k_in),

      .quotient_ci      ({(N_ACT-M+1){1'b0}}),   
      .dividend_ci      (dividend[N_ACT-M-1:0]), 
      .dividend_kp      (dividend_t[N_ACT-M]),   
      .divisor_kp       (divisor_t[N_ACT-M]),    
      .rdy              (rdy_t[N_ACT-M]),
      .quotient         (quotient_t[N_ACT-M]),   
      .remainder        (remainder_t[N_ACT-M]),
      .k_out            (k_out_t[N_ACT-M])
      );

    genvar               i ;
    generate
        for(i=1; i<=N_ACT-M; i=i+1) begin: sqrt_stepx
            divider_cell      #(.N(N_ACT), .M(M))
              u_divider_step
              (.clk              (clk),
               .rst             (rst),
               .en               (rdy_t[N_ACT-M-i+1]),
               .dividend         ({remainder_t[N_ACT-M-i+1], dividend_t[N_ACT-M-i+1][N_ACT-M-i]}),   
               .divisor          (divisor_t[N_ACT-M-i+1]),
               .quotient_ci      (quotient_t[N_ACT-M-i+1]),
               .dividend_ci      (dividend_t[N_ACT-M-i+1]),
               .k_in             (k_out_t[N_ACT-M-i+1]),
               .busy              (stall),

               .divisor_kp       (divisor_t[N_ACT-M-i]),
               .dividend_kp      (dividend_t[N_ACT-M-i]),
               .rdy              (rdy_t[N_ACT-M-i]),
               .quotient         (quotient_t[N_ACT-M-i]),
               .remainder        (remainder_t[N_ACT-M-i]),
               .k_out            (k_out_t[N_ACT-M-i])
              );
        end 
    endgenerate

    assign res_rdy       = rdy_t[0];
    assign quotient      = quotient_t[0];  
    assign remainder     = remainder_t[0]; 
    assign k_out         = k_out_t[0];

endmodule