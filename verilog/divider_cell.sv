`timescale 1ns/100ps

module divider_cell
    #(
      parameter N=8,
      parameter M=4)
    (
      input logic                     clk,
      input logic                     rst,
      input logic                     en,
      input logic [M:0]               dividend,
      input logic [M-1:0]             divisor,
      input logic [N-M:0]             quotient_ci, 
      input logic [N-M-1:0]           dividend_ci, 
      input logic [$clog2(`max_num_K):0] k_in,

      output logic [N-M-1:0]      dividend_kp,  
      output logic [M-1:0]        divisor_kp,  
      output logic                rdy ,
      output logic [N-M:0]        quotient ,  
      output logic [M-1:0]        remainder,
      output logic [$clog2(`max_num_K):0] k_out
    );

    always_ff@(posedge clk) begin
        if (rst) begin
            rdy            <= 'b0 ;
            quotient       <= 'b0 ;
            remainder      <= 'b0 ;
            divisor_kp     <= 'b0 ;
            dividend_kp    <= 'b0 ;
            k_out          <= 'b0 ;
        end
        else if (en) begin
            rdy            <= 1'b1 ;
            divisor_kp     <= divisor ;  
            dividend_kp    <= dividend_ci ;  
            k_out <= k_in;

            if (dividend >= {1'b0, divisor}) begin
                quotient    <= (quotient_ci<<1) + 1'b1 ; 
                remainder   <= dividend - {1'b0, divisor} ; 
            end
            else begin
                quotient    <= quotient_ci<<1 ;  
                remainder   <= dividend ;        
            end
        end 
        else begin
            rdy            <= 'b0 ;
            quotient       <= 'b0 ;
            remainder      <= 'b0 ;
            divisor_kp     <= 'b0 ;
            dividend_kp    <= 'b0 ;
            k_out          <= 'b0 ;
        end
    end

endmodule