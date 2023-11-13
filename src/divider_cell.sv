`timescale 1ns/100ps

module divider_cell
    #(
      parameter N=8,
      parameter M=4)
    (
      input logic                     clk,
      input logic                     rst_n,
      input logic                     en,
      input logic [M:0]               dividend,
      input logic [M-1:0]             divisor,
      input logic [N-M:0]             merchant_ci , 
      input logic [N-M-1:0]           dividend_ci , 

      output logic [N-M-1:0]      dividend_kp,  
      output logic [M-1:0]        divisor_kp,  
      output logic                rdy ,
      output logic [N-M:0]        merchant ,  
      output logic [M-1:0]        remainder   
    );

    always_ff@(posedge clk) begin
        if (!rst_n) begin
            rdy            <= 'b0 ;
            merchant       <= 'b0 ;
            remainder      <= 'b0 ;
            divisor_kp     <= 'b0 ;
            dividend_kp    <= 'b0 ;
        end
        else if (en) begin
            rdy            <= 1'b1 ;
            divisor_kp     <= divisor ;  
            dividend_kp    <= dividend_ci ;  
            if (dividend >= {1'b0, divisor}) begin
                merchant    <= (merchant_ci<<1) + 1'b1 ; 
                remainder   <= dividend - {1'b0, divisor} ; 
            end
            else begin
                merchant    <= merchant_ci<<1 ;  
                remainder   <= dividend ;        
            end
        end 
        else begin
            rdy            <= 'b0 ;
            merchant       <= 'b0 ;
            remainder      <= 'b0 ;
            divisor_kp     <= 'b0 ;
            dividend_kp    <= 'b0 ;
        end
    end

endmodule