
`timescale 1ns/100ps
module PE_Accumulator_buffer
(
//-------------------Input-------------------------//
    input clk,
    input rst,
    input [$clog2(`max_length_output)-1:0] Conv_size_output_Boundary,
    input drain_Accumulator_buffer_en,
    input Stream_filter_finish,
    input PPU_finish_en,
    input crossbar_buffer_in_PACKET crossbar_buffer_data_in,
    output  Buffer_PPU_PACKET buffer_PPU_data
);
parameter  N=3, IDLE='d0, Stream_data='d1,Complete='d2,finish='d3;
logic [$clog2(N)-1:0] state, nx_state;
Buffer_BLOCK [`Accumulator_buffer_k_offset-1:0][`Accumulator_buffer_entry-1:0][`Accumulator_buffer_bank_size-1:0]Current_buffer ;
Buffer_BLOCK [`Accumulator_buffer_k_offset-1:0][`Accumulator_buffer_entry-1:0][`Accumulator_buffer_bank_size-1:0]nx_buffer ;
logic reg_Stream_filter_finish;
logic [$clog2(`Accumulator_buffer_k_offset)-1:0] Current_k, nx_k;

logic [$clog2(`Accumulator_buffer_entry)-1:0] Current_entry, nx_entry;
logic rst_buffer;
logic [$clog2(`Accumulator_buffer_entry)-1:0] nx_entry_cnt,Current_entry_cnt;

logic reg_PPU_finish_en;
logic [1:0]finish_cnt,nx_finish_cnt;
always_ff@(posedge clk)begin
    if(rst)begin
        state<=#1 'd0;
        Current_buffer <=#1 'd0;
        Current_k <=#1 'd0;
        Current_entry <=#1 'd0;
        Current_entry_cnt<=#1 'd0;

        reg_Stream_filter_finish<=#1 'd0;
        reg_PPU_finish_en<=#1 'd0;
        	finish_cnt<=#1 'd0;
       
    end
    else if(rst_buffer) begin
        state<=#1 'd0;
        Current_buffer <=#1 'd0;
        Current_k <=#1 'd0;
        Current_entry <=#1 'd0; 
        Current_entry_cnt<=#1 'd0;

        reg_Stream_filter_finish<=#1 'd0;
        reg_PPU_finish_en<= #1 'd0;
        	finish_cnt<=#1 nx_finish_cnt;
    end
    else begin
        state<=#1 nx_state;
        Current_buffer <=#1 nx_buffer;
        Current_k <=#1 nx_k;
        Current_entry <=#1 nx_entry; 
        Current_entry_cnt<=#1 nx_entry_cnt;
        finish_cnt<=#1 'd0;


        //reg_Stream_filter_finish<=#1 Stream_filter_finish;
        if(drain_Accumulator_buffer_en)begin
            reg_Stream_filter_finish<=#1 Stream_filter_finish?1'b1:reg_Stream_filter_finish;
        end
        else begin
            reg_Stream_filter_finish<=#1 Stream_filter_finish;
        end

        if(drain_Accumulator_buffer_en)begin
            reg_PPU_finish_en<=#1 PPU_finish_en?1'b1:reg_PPU_finish_en;
        end
        else begin
            reg_PPU_finish_en<= #1 PPU_finish_en;
        end

    end
end

always_comb begin
    nx_finish_cnt= finish_cnt;
    nx_buffer = Current_buffer;
    nx_k = Current_k;
    nx_entry = Current_entry;
    nx_entry_cnt=Current_entry_cnt;
    nx_state =state;
    rst_buffer = 0;
    buffer_PPU_data.valid = 0;
    buffer_PPU_data.data = 0;

        for(int i =0;i<`NUM_DST;i++)begin
            if(crossbar_buffer_data_in.crossbar_buffer_valid[i])begin
            nx_buffer[crossbar_buffer_data_in.k_dir[i]][crossbar_buffer_data_in.x_dir[i]][i] =
            Current_buffer[crossbar_buffer_data_in.k_dir[i]][crossbar_buffer_data_in.x_dir[i]][i]+crossbar_buffer_data_in.crossbar_buffer_data[i];
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
        


            for(int i =0;i<`Accumulator_buffer_bank_size;i++)begin
                    if(i<Conv_size_output_Boundary)begin
                   
                        if(Current_buffer[nx_k][nx_entry][i].buffer_data[15])begin 
                            buffer_PPU_data.data[i]='d0;
                            buffer_PPU_data.valid[i] = 'd1;

                        end
                        else begin 
                            buffer_PPU_data.data[i]=Current_buffer[nx_k][nx_entry][i].buffer_data;
                            buffer_PPU_data.valid[i] = 'd1;

                        end
                    end
            end

            
            nx_k =(Current_entry_cnt == Conv_size_output_Boundary-'d1)?Current_k+1'b1:Current_k;
            nx_entry=(Current_entry_cnt<Conv_size_output_Boundary-'d1) ? Current_entry+1'b1 :'d0;       
            nx_entry_cnt = (Current_entry_cnt<Conv_size_output_Boundary-'d1)? Current_entry_cnt+1'b1 : 'd0;
            if((Current_k == (`Accumulator_buffer_k_offset-1)) && Current_entry == Conv_size_output_Boundary-'d1) begin
                nx_state=Complete;
            end
            else begin
                nx_state=Stream_data;
            end

        end
        Complete: begin
            if((reg_Stream_filter_finish||Stream_filter_finish)&&(reg_PPU_finish_en||PPU_finish_en) )begin

                nx_state=finish;
            end

        end
        finish: begin
                            rst_buffer = 'd1;
            nx_finish_cnt =nx_finish_cnt+'d1;
            if((finish_cnt=='d2) )begin

                nx_state=IDLE;
            end
            else begin
                nx_state=finish;
            end

        end
            default: nx_state=IDLE;   

    endcase
end//end_comb
endmodule
