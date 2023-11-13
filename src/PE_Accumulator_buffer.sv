
`timescale 1ns/100ps
module PE_Accumulator_buffer
#(parameter PE_num=1)(
//-------------------Input-------------------------//
    input clk,
    input rst,
    input [$clog2(`max_size_output)-1:0] Conv_size_output_Boundary,
    input drain_Accumulator_buffer_en,
    input crossbar_buffer_in_PACKET crossbar_buffer_data_in,
    output  Buffer_PPU_PACKET buffer_PPU_data
);
parameter  N=3, IDLE='d0, Stream_data='d1,Complete='d2;
logic [$clog2(N)-1:0] state, nx_state;
Buffer_BLOCK [`Accumulator_buffer_k_offset-1:0][`Accumulator_buffer_entry-1:0][`Accumulator_buffer_bank_size-1:0]Current_buffer ;
Buffer_BLOCK [`Accumulator_buffer_k_offset-1:0][`Accumulator_buffer_entry-1:0][`Accumulator_buffer_bank_size-1:0]nx_buffer ;

logic [$clog2(`Accumulator_buffer_k_offset)-1:0] Current_k, nx_k;

logic [$clog2(`Accumulator_buffer_entry)-1:0] Current_entry, nx_entry;
logic rst_buffer;
logic [$clog2(`max_size_output)-1:0] nx_entry_cnt,Current_entry_cnt;
logic [$clog2(`max_size_output)-1:0] nx_output_cnt,Current_output_cnt;
always_ff@(posedge clk)begin
    if(rst)begin
        state<=#1 'd0;
        Current_buffer <=#1 'd0;
        Current_k <=#1 'd0;
        Current_entry <=#1 'd0;
        Current_entry_cnt<=#1 'd0;
        Current_output_cnt<=#1 'd0;
       
    end
    else if(rst_buffer) begin
        state<=#1 'd0;
        Current_buffer <=#1 'd0;
        Current_k <=#1 'd0;
        Current_entry <=#1 'd0; 
        Current_entry_cnt<=#1 'd0;
        Current_output_cnt<=#1 'd0;
    end
    else begin
        state<=#1 nx_state;
        Current_buffer <=#1 nx_buffer;
        Current_k <=#1 nx_k;
        Current_entry <=#1 nx_entry; 
        Current_entry_cnt<=#1 nx_entry_cnt;
        Current_output_cnt<=#1 nx_output_cnt;
    end
end

always_comb begin
    nx_buffer = Current_buffer;
    nx_k = Current_k;
    nx_entry = Current_entry;
    nx_entry_cnt=Current_entry_cnt;
    nx_state =state;
    rst_buffer = 0;
    buffer_PPU_data.valid = 0;
    buffer_PPU_data.data = 0;
    nx_output_cnt = Current_output_cnt;
        for(int i =0;i<`NUM_DST;i++)begin
            if(crossbar_buffer_data_in.crossbar_buffer_valid[i])begin
            nx_buffer[crossbar_buffer_data_in.k_dir[i]][crossbar_buffer_data_in.x_dir[i]][crossbar_buffer_data_in.y_dir[i]] =
            Current_buffer[crossbar_buffer_data_in.k_dir[i]][crossbar_buffer_data_in.x_dir[i]][crossbar_buffer_data_in.y_dir[i]]+crossbar_buffer_data_in.crossbar_buffer_data[i];
    end
    end
    case(state)
        IDLE: begin
            rst_buffer = 0;
            if(drain_Accumulator_buffer_en)begin
                nx_state=Stream_data;
                
            end
            else begin
                nx_state=IDLE;
            end 
        end
        Stream_data: begin
        
            if((Current_k == (`Accumulator_buffer_k_offset-1)) && Current_entry_cnt == Conv_size_output_Boundary) begin
                nx_state=Complete;
            end
            else begin
                nx_state=Stream_data;
            end

            for(int i =0;i<`Accumulator_buffer_bank_size;i++)begin
                    if(nx_output_cnt<Conv_size_output_Boundary)begin
                        if(Current_buffer[nx_k][nx_entry][i].buffer_data[15])begin 
                            buffer_PPU_data.data[i]='d0;
                            buffer_PPU_data.valid[i] = 'd1;
                            nx_output_cnt = nx_output_cnt +'d1;
                        end
                        else begin 
                            buffer_PPU_data.data[i]=Current_buffer[nx_k][nx_entry][i].buffer_data;
                            buffer_PPU_data.valid[i] = 'd1;
                            nx_output_cnt = nx_output_cnt +'d1;
                        end
                    end
            end

            
            nx_k =(Current_entry_cnt == Conv_size_output_Boundary)?Current_k+1'b1:Current_k;
            nx_entry=(Current_entry_cnt<Conv_size_output_Boundary) ? Current_entry+1'b1 :'d0;       
            nx_entry_cnt = (Current_entry_cnt<Conv_size_output_Boundary)? Current_entry_cnt+1'b1 : 'd0;
            nx_output_cnt =nx_output_cnt<Conv_size_output_Boundary? nx_output_cnt :'d0;
        end
        Complete: begin
            rst_buffer = 'd1;
            nx_state=IDLE;
        end
            default: nx_state=IDLE;   

    endcase
end//end_comb
endmodule