`timescale 1ns/100ps

module Xbar (
    input   logic                                           clock, 
    input   logic                                           reset,
    
    input logic[$clog2(5)-1:0]                              state_PE_controller,
    input   MUL_COORD_OUT                                   mul_cord_packet,
    input sparse,
    output  logic                                           busy,
    output  logic                                              empty,

    // Inteface with acummulate buffer
    output  crossbar_buffer_in_PACKET                       buffer_packet,
    output logic                                            XBAR_Partial_c

    
);  

    // Extract input packet
    DATA_PACKET [`NUM_SRC-1:0]                      in_packet;
    logic       [`NUM_DST-1:0]                      out_valid ;
    logic       [`NUM_DST-1:0]                      FIFO_empty;




    DATA_PACKET [`NUM_DST-1:0][`FIFO_DEPTH-1:0]             FIFO;
    logic       [`NUM_DST-1:0][$clog2(`FIFO_DEPTH)-1:0]     rd_ptr;
    logic       [`NUM_DST-1:0][$clog2(`FIFO_DEPTH)-1:0]     wr_ptr;

    DATA_PACKET [`NUM_DST-1:0][`FIFO_DEPTH-1:0]             nx_FIFO;
    logic       [`NUM_DST-1:0][$clog2(`FIFO_DEPTH)-1:0]     nx_rd_ptr;
    logic       [`NUM_DST-1:0][$clog2(`FIFO_DEPTH)-1:0]     nx_wr_ptr;

    logic       [`NUM_DST-1:0]                              fifo_busy;      // busy means more than one valid entry in this fifo

    logic [`NUM_DST-1:0][$clog2(`FIFO_DEPTH):0] num_remain_FIFO, nx_num_remain_FIFO;

    logic [$clog2(`NUM_DST)-1:0]    idx;                // Output fifo select

    assign empty= &FIFO_empty;
    always_ff @(posedge clock) begin
        if (reset) begin
           // out_fifo    <=#1 0;
            rd_ptr      <=#1 0;
            wr_ptr      <=#1 0;
            FIFO<=#1 'd0;
            XBAR_Partial_c<=#1 'd0;
            
            for(int i=0;i<`FIFO_DEPTH;i++)begin
                num_remain_FIFO[i]<=#1 `FIFO_DEPTH;
            end
        end else begin
            FIFO    <= #1 nx_FIFO;
            rd_ptr <= #1 nx_rd_ptr;
            wr_ptr<= #1 nx_wr_ptr;
            num_remain_FIFO<=#1 nx_num_remain_FIFO;
            if(state_PE_controller=='d2)begin
                XBAR_Partial_c<= #1 mul_cord_packet.reg_MA_Partial_c? 1'b1:XBAR_Partial_c;
            end
            else begin
                XBAR_Partial_c<=#1  'd0;
        end
            end
            
    end


    always_comb begin
    buffer_packet='d0;
    nx_FIFO   = FIFO;
    nx_wr_ptr= wr_ptr;
    nx_rd_ptr= rd_ptr;
    nx_num_remain_FIFO=num_remain_FIFO;
    FIFO_empty='d0;
        for(int i=0;i<`NUM_DST;i++)begin
            if(nx_num_remain_FIFO[i]!=`FIFO_DEPTH)begin
                buffer_packet.crossbar_buffer_valid[i]=1'b1;
                buffer_packet.crossbar_buffer_data[i]=FIFO[i][nx_rd_ptr[i]].data;
                buffer_packet.x_dir[i]=FIFO[i][nx_rd_ptr[i]].x;
                buffer_packet.y_dir[i]=FIFO[i][nx_rd_ptr[i]].y;
                buffer_packet.k_dir[i]=FIFO[i][nx_rd_ptr[i]].k;
                nx_rd_ptr[i]=nx_rd_ptr[i]+1'b1;
                nx_num_remain_FIFO[i]=nx_num_remain_FIFO[i]+1'b1;
            end
        end
        for(int i=0;i<`NUM_DST;i++)begin
            FIFO_empty[i]=nx_num_remain_FIFO[i]==`FIFO_DEPTH;
        end
        for (int n = 0; n < `NUM_SRC; n++) begin
                in_packet[n].data   = mul_cord_packet.output_data[n];
                in_packet[n].valid  = mul_cord_packet.valid[n];
                in_packet[n].y      = mul_cord_packet.output_row_num[n] - 1;    // The x, y, and k need to subtract by 1 according to Guangze
                in_packet[n].x      = mul_cord_packet.output_col_num[n] - 1;
                in_packet[n].k      = sparse?mul_cord_packet.k_num[n]-1:mul_cord_packet.k_num[n];
        end

        for(int i=0;i<`NUM_SRC;i++)begin
            if(in_packet[i].valid)begin
                idx = in_packet[i].y[4:0];                        // Select which output fifo to go to
                nx_FIFO[idx][nx_wr_ptr[idx]]=in_packet[i];
                nx_wr_ptr[idx]=nx_wr_ptr[idx]+1'b1;
                nx_num_remain_FIFO[idx]=nx_num_remain_FIFO[idx]-1'b1;
            end

        end



        for (int i=0;i<`FIFO_DEPTH;i++)begin
            fifo_busy[i]=num_remain_FIFO[i]<`NUM_SRC;
        end


         busy=|fifo_busy;
        
        end

       



endmodule
    // always_ff@(posedge clk)begin
    //     if(rst)begin
    //         output_row_num<=#1 'd0;
    //         output_col_num<=#1 'd0;
    //         k_num <=#1 'd0;
    //         valid <=#1 'd0;
    //     end
    //     else begin
    //         output_row_num<=#1 nx_output_row_num;
    //         output_col_num<=#1 nx_output_col_num;
    //         k_num <=#1 nx_k_num;
    //         valid <=#1 nx_valid;
    //     end

    // end