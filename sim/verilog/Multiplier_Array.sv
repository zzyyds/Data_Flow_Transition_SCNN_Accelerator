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
    input stall,
    input Partial_c,

        output MUL_DATA MUL_XBAR_OUT,
    output logic reg_MA_Partial_c
);
parameter N=$clog2(`max_num_Wt*`max_num_Ht)+2;
MUL_DATA nx_MUL_XBAR_OUT;
logic signed[`F*`I-1:0][15:0]data_in;
logic[`F*`I-1:0] data_valid;
logic signed[`F*`I-1:0][15:0] weight_in;
logic[`F*`I-1:0] weight_valid;

MUL_DATA shift_reg[N:0];
logic reg_Partial_c[N:0];
assign MUL_XBAR_OUT=stall?'d0:sparse?shift_reg[N]:shift_reg[0];
assign reg_MA_Partial_c=stall?'d0:sparse?reg_Partial_c[N]:reg_Partial_c[0];
always_comb begin
    nx_MUL_XBAR_OUT='d0;

    if(sparse)begin
        for(int i=0;i<`I;i++)begin
            for(int j=0;j<`I;j++)begin
                data_in[i*`I+j]=IARAM_IN.IRAM_data[i];
                data_valid[i*`I+j]=IARAM_IN.valid[i];
            end
        end
        for(int i=0;i<`F;i++)begin
            for(int j=0;j<`F;j++)begin
                weight_in[i*`F+j]=Weight_IN.Weight_data[j];
                weight_valid[i*`F+j]=Weight_IN.valid[j];
            end
        end

    end
    else begin
        data_in=IARAM_MUL_Dense_out.IRAM_data;
        data_valid=IARAM_MUL_Dense_out.valid;
        for (int i=0;i<`F*`I;i++)begin
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

        for(int i=0;i<N+1;i++)begin
            shift_reg[i]<=#1 'd0;        
            reg_Partial_c[i]<=#1 'd0;
        end

    end
    else begin
        if(stall)begin
            shift_reg<=#1 shift_reg;
            for(int i=0;i<N+1;i++)begin
                reg_Partial_c[i]<=#1 'd0;
            end

        end
        else begin
            shift_reg[0]<=#1 nx_MUL_XBAR_OUT;
        //<=#1 nx_MUL_XBAR_OUT;
            for(int i=1;i<N+1;i++)begin
                shift_reg[i]<=#1 shift_reg[i-1];
            end
            reg_Partial_c[0]<=#1 Partial_c;
            for(int i=1;i<N+1;i++)begin
                reg_Partial_c[i]<=#1 reg_Partial_c[i-1];
            end

        end

    end
end




endmodule