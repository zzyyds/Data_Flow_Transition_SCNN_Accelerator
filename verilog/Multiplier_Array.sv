module Multiplier_Array
(
//-------------------Input-------------------------//
    input clk,
    input rst,


    input Weight_MUL Weight_IN,
    input IARAM_MUL IARAM_IN,
    input sparse,
    input IARAM_MUL_Dense_Cal IARAM_MUL_Dense_out,
    input Weight_MUL_Dense_Cal Weight_MUL_Dense_out,

    output MUL_XBAR MUL_XBAR_OUT
);
MUL_XBAR nx_MUL_XBAR_OUT;
logic[`F*`I-1:0][15:0]data_in;
logic[`F*`I-1:0] data_valid;
logic[`F*`I-1:0][15:0] weight_in;
logic[`F*`I-1:0] weight_valid;
always_comb begin

    if(sparse)begin
        for(int i=0;i<`F*`I;i++)begin
            for(int j=0;j<`I;j++)begin
                data_in[i]=IARAM_IN.IRAM_data[j];
                data_valid[i]=IARAM_IN.valid[i];
            end
        end
        for(int i=0;i<`F*`I;i++)begin
            for(int j=0;j<`I;j++)begin
                weight_in[i]=Weight_IN.Weight_data[j];
                weight_valid[i]=Weight_IN.valid[i];
            end
        end

    end
    else begin
        data_in=IARAM_MUL_Dense_out.IRAM_data;
        data_valid=IARAM_MUL_Dense_out.valid;
        for(int i=0;i<`F*`I;i++)begin
            weight_in[i]=Weight_MUL_Dense_out.Weight_data;
            weight_valid[i]=Weight_MUL_Dense_out.valid;
        end

    end
    for(int i=0;i<`F*`I;i++)begin
        nx_MUL_XBAR_OUT.output_data[i]=data_in[i]*weight_in[i];
        nx_MUL_XBAR_OUT.valid[i]=data_valid[i]&&weight_valid[i];


    end


end

//because F=I=4 is fixed

always_ff@(posedge clk)begin
    if(rst)begin
        MUL_XBAR_OUT<=#1 'd0;
    end
    else begin
        MUL_XBAR_OUT<=#1 nx_MUL_XBAR_OUT;
    end
end




endmodule