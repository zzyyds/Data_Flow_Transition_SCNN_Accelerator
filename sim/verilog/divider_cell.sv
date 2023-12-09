`timescale 1ns/100ps
//`include "sys_defs.svh"
module divider_cell
    #(
      parameter N=8,
      parameter M=4)
    (
      input logic                     clk,
      input logic                     rst,
      input logic                     en,
      input logic                     busy,
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
            rdy            <=#1 'b0 ;
            quotient       <=#1 'b0 ;
            remainder      <=#1 'b0 ;
            divisor_kp     <=#1 'b0 ;
            dividend_kp    <=#1 'b0 ;
            k_out          <=#1 'b0 ;
        end
        else if(busy)begin
            dividend_kp<=#1 dividend_kp;
            divisor_kp<=#1 divisor_kp;
            rdy<=#1 rdy;
            quotient<=#1 quotient;
            remainder<=#1 remainder;
            k_out<=#1 k_out;

        end
        else if (en) begin
            rdy            <= #1 1'b1 ;
            divisor_kp     <= #1 divisor ;  
            dividend_kp    <=#1 dividend_ci ;  
            k_out <= k_in;

            if (dividend >= {1'b0, divisor}) begin
                quotient    <=#1 (quotient_ci<<1) + 1'b1 ; 
                remainder   <=#1 dividend - {1'b0, divisor} ; 
            end
            else begin
                quotient    <=#1 quotient_ci<<1 ;  
                remainder   <=#1 dividend ;        
            end
        end 
        else begin
            rdy            <=#1 'b0 ;
            quotient       <=#1 'b0 ;
            remainder      <=#1 'b0 ;
            divisor_kp     <=#1 'b0 ;
            dividend_kp    <=#1 'b0 ;
            k_out          <=#1 'b0 ;
        end
    end

endmodule
