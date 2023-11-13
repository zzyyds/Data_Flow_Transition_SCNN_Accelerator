`timescale 1ns/100ps

module divider
    #( 
      parameter max_index = 15,
      parameter rows = 16,
      parameter cols = 16,
      parameter N=$clog2(cols*rows)+1,
      parameter M=$clog2(cols)+1,
      parameter N_ACT = M+N-1)
    (
      input logic                     clk,
      input logic                     rst_n,
      input logic                     data_rdy ,  
      input logic [N-1:0]             dividend,  
      input logic [M-1:0]             divisor,    

      output logic                    res_rdy ,
      output logic [N_ACT-M:0]        merchant ,  
      output logic [M-1:0]            remainder ); 

    logic [N_ACT-M-1:0]   dividend_t [N_ACT-M:0] ;
    logic [M-1:0]         divisor_t [N_ACT-M:0] ;
    logic [M-1:0]         remainder_t [N_ACT-M:0];
    logic [N_ACT-M:0]     rdy_t ;
    logic [N_ACT-M:0]     merchant_t [N_ACT-M:0] ;

    divider_cell      #(.N(N_ACT), .M(M))
       u_divider_step0
    ( .clk              (clk),
      .rst_n             (rst_n),
      .en               (data_rdy),
      .dividend         ({{(M){1'b0}}, dividend[N-1]}),
      .divisor          (divisor),                  
      .merchant_ci      ({(N_ACT-M+1){1'b0}}),   
      .dividend_ci      (dividend[N_ACT-M-1:0]), 
      .dividend_kp      (dividend_t[N_ACT-M]),   
      .divisor_kp       (divisor_t[N_ACT-M]),    
      .rdy              (rdy_t[N_ACT-M]),
      .merchant         (merchant_t[N_ACT-M]),   
      .remainder        (remainder_t[N_ACT-M])   
      );

    genvar               i ;
    generate
        for(i=1; i<=N_ACT-M; i=i+1) begin: sqrt_stepx
            divider_cell      #(.N(N_ACT), .M(M))
              u_divider_step
              (.clk              (clk),
               .rst_n             (rst_n),
               .en               (rdy_t[N_ACT-M-i+1]),
               .dividend         ({remainder_t[N_ACT-M-i+1], dividend_t[N_ACT-M-i+1][N_ACT-M-i]}),   
               .divisor          (divisor_t[N_ACT-M-i+1]),
               .merchant_ci      (merchant_t[N_ACT-M-i+1]),
               .dividend_ci      (dividend_t[N_ACT-M-i+1]),
               .divisor_kp       (divisor_t[N_ACT-M-i]),
               .dividend_kp      (dividend_t[N_ACT-M-i]),
               .rdy              (rdy_t[N_ACT-M-i]),
               .merchant         (merchant_t[N_ACT-M-i]),
               .remainder        (remainder_t[N_ACT-M-i])
              );
        end 
    endgenerate

    assign res_rdy       = rdy_t[0];
    assign merchant      = merchant_t[0];  
    assign remainder     = remainder_t[0]; 

endmodule