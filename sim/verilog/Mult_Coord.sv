`timescale 1ns/100ps

module Mult_Coord 
(
    input logic clk,
    input logic rst,
    input MUL_COORD_IN Mult_Coord_in,
    input logic stall,
    input logic next_a,
    input logic first_Ex_state_cycle,
    output MUL_COORD_OUT Mult_Coord_out

);
    logic [`I * `F-1 : 0] coord_valid;
    MUL_COORD_OUT Mult_Coord_out_temp;
    MUL_DATA MUL_XBAR_OUT;
    IARAM_MUL_Dense_Cal IARAM_MUL_Dense_out;
    Weight_MUL_Dense_Cal Weight_MUL_Dense_out;
    coordinate_computation coord (
        .clk(clk),
        .rst(rst),
        .decode_restart(Mult_Coord_in.decode_restart),
        .Layer_change_flag(Mult_Coord_in.Layer_change_flag),
        .each_filter_size(Mult_Coord_in.each_filter_size),
        .input_index_vector(Mult_Coord_in.input_index_vector),
        .filter_index_vector(Mult_Coord_in.filter_index_vector),
        .stride(Mult_Coord_in.stride),
        .input_side_length(Mult_Coord_in.input_side_length),
        .filter_side_length(Mult_Coord_in.filter_side_length),
        .IARAM_MUL_Dense_in(Mult_Coord_in.IARAM_MUL_Dense_in),            //
        .Weight_MUL_Dense_in(Mult_Coord_in.Weight_MUL_Dense_in),          //
        .sparse(Mult_Coord_in.sparse), 
        .stall(stall),
        .next_a(next_a), 
        .first_Ex_state_cycle(first_Ex_state_cycle),
        .K_changing(Mult_Coord_in.K_changing),       

        .output_row_num(Mult_Coord_out_temp.output_row_num),
        .output_col_num(Mult_Coord_out_temp.output_col_num),//
        .k_num(Mult_Coord_out_temp.k_num),
        .valid(coord_valid)
    );

    assign IARAM_MUL_Dense_out.valid=Mult_Coord_in.IARAM_MUL_Dense_in.valid;
    assign  IARAM_MUL_Dense_out.IRAM_data=Mult_Coord_in.IARAM_MUL_Dense_in.IRAM_data;
    assign Weight_MUL_Dense_out.valid=Mult_Coord_in.Weight_MUL_Dense_in.valid;
    assign Weight_MUL_Dense_out.Weight_data=Mult_Coord_in.Weight_MUL_Dense_in.Weight_data;
    Multiplier_Array mult (
        .clk(clk),
        .rst(rst),
        .Weight_IN(Mult_Coord_in.Weight_IN),
        .IARAM_IN(Mult_Coord_in.IARAM_IN),
        .sparse(Mult_Coord_in.sparse),
        .IARAM_MUL_Dense_out(IARAM_MUL_Dense_out),
        .Weight_MUL_Dense_out(Weight_MUL_Dense_out),
        .stall(stall),
        .Partial_c(Mult_Coord_in.Partial_c),

        .MUL_XBAR_OUT(MUL_XBAR_OUT),
        .reg_MA_Partial_c(reg_MA_Partial_c)
    );

    assign Mult_Coord_out_temp.output_data = MUL_XBAR_OUT.output_data;
    assign Mult_Coord_out_temp.valid = coord_valid & MUL_XBAR_OUT.valid;
    assign Mult_Coord_out_temp.reg_MA_Partial_c=reg_MA_Partial_c;


    assign Mult_Coord_out = Mult_Coord_out_temp;

endmodule