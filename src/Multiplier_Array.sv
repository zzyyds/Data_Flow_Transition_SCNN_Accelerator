module Multiplier_Array
(
//-------------------Input-------------------------//
    input clk,
    input rst,


    input Weight_MUL Weight_IN,
    input IARAM_MUL IARAM_IN,

    output MUL_XBAR MUL_XBAR_OUT
);
MUL_XBAR nx_MUL_XBAR_OUT;
always_comb begin
    nx_MUL_XBAR_OUT='d0;
    for(int i=0;i<`I;i++)begin
        if(IARAM_IN.valid)begin
            for(int j=0;j<`F;j++)begin
                if(Weight_IN.valid)begin
                    nx_MUL_XBAR_OUT.valid[i*`I+j]=1'b1;
                    nx_MUL_XBAR_OUT.output_data[i*`I+j]=IARAM_IN.IRAM_data[i]*Weight_IN.Weight_data[j];
                end
                else begin
                    nx_MUL_XBAR_OUT.valid[i*`I+j]=1'b0;
                    nx_MUL_XBAR_OUT.output_data[i*`I+j]='d0;

                end

            end

        end
        else begin

            for(int j=0;j<`F;j++)begin
                // if(Weight_IN.valid)begin
                //     MUL_XBAR_OUT.valid[i+j]=1'b1;
                //     MUL_XBAR_OUT.output_data[i+j]=IARAM_IN.IRAM_data;
                // end
                // else begin
                    nx_MUL_XBAR_OUT.valid[i*`I+j]=1'b0;
                    nx_MUL_XBAR_OUT.output_data[i*`I+j]='d0;

               // end
            end


        end

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
