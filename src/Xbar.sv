`include "sys_defs.svh"

module Xbar (
    input   logic                                           clock, 
    input   logic                                           reset,
    
    // Interface with PE
    input   MUL_COORD_OUT                                   mul_cord_packet,
    output  logic                                           busy,

    // Inteface with acummulate buffer
    output  crossbar_buffer_in_PACKET                       buffer_packet,
    output  logic       [`NUM_DST-1:0]                      out_valid                 // Output valid flag
    
);  

    // Extract input packet
    DATA_PACKET [`NUM_SRC-1:0]                              in_packet;
    genvar n;
    generate
        for (n = 0; n < `NUM_DST; n++) begin
            assign in_packet[n].data   = mul_cord_packet.output_data[n];
            assign in_packet[n].valid  = mul_cord_packet.valid[n];
            assign in_packet[n].y      = mul_cord_packet.output_row_num[n] - 1;    // The x, y, and k need to subtract by 1 according to Guangze
            assign in_packet[n].x      = mul_cord_packet.output_col_num[n] - 1;
            assign in_packet[n].k      = mul_cord_packet.k_num[n] - 1;
        end
    endgenerate


    DATA_PACKET [`NUM_DST-1:0][`FIFO_DEPTH-1:0]             out_fifo;
    logic       [`NUM_DST-1:0][$clog2(`FIFO_DEPTH)-1:0]     rd_ptr;
    logic       [`NUM_DST-1:0][$clog2(`FIFO_DEPTH)-1:0]     wt_ptr;

    DATA_PACKET [`NUM_DST-1:0][`FIFO_DEPTH-1:0]             next_out_fifo;
    logic       [`NUM_DST-1:0][$clog2(`FIFO_DEPTH)-1:0]     next_rd_ptr;
    logic       [`NUM_DST-1:0][$clog2(`FIFO_DEPTH)-1:0]     next_wt_ptr;

    logic       [`NUM_DST-1:0]                              fifo_busy;      // busy means more than one valid entry in this fifo
    //logic       [`NUM_DST-1:0]                              fifo_full;      // full means this fifo is full
    //logic                                                   full;

    always_ff @(posedge clock) begin
        if (reset) begin
            out_fifo    <= 0;
            rd_ptr      <= 0;
            wt_ptr      <= 0;
        end else begin
            out_fifo    <= next_out_fifo;
            rd_ptr      <= next_rd_ptr;
            wt_ptr      <= next_wt_ptr;
        end
    end


    logic [$clog2(`NUM_DST)-1:0]    idx;                // Output fifo select

    always_comb begin
        
        // Default
        next_out_fifo   = out_fifo;
        next_wt_ptr     = wt_ptr;
        next_rd_ptr     = rd_ptr;

        for (int j = 0; j < `NUM_DST; j++) begin
            if (rd_ptr[j] != wt_ptr[j]) begin
                next_rd_ptr[j] = (rd_ptr[j] + 1) % `FIFO_DEPTH;      // Pop one packet unless empty  
            end 
        end

        idx = 0;

        if (~busy) begin
            // Push input data packet to output fifo
            for (int i = 0; i < `NUM_SRC; i++) begin
                if (in_packet[i].valid) begin
                    idx = in_packet[i].y % `NUM_DST;                        // Select which output fifo to go to
                    next_out_fifo[idx][next_wt_ptr[idx]] = in_packet[i];
                    next_wt_ptr[idx] = (next_wt_ptr[idx] + 1) % `FIFO_DEPTH;
                end
            end
        end
    end


    logic [$clog2(`FIFO_DEPTH):0]       num_entry [`NUM_DST-1:0];               // Number of valid entries in each fifo

    DATA_PACKET [`NUM_DST-1:0]          out_packet;

    genvar l;
    generate
        for (l = 0; l < `NUM_DST; l++) begin
            assign out_packet[l] = out_fifo[l][rd_ptr[l]];
            assign out_valid[l]  = rd_ptr[l] != wt_ptr[l];                      // If not empty, then there must be data available
            assign num_entry[l]  = (wt_ptr[l] < rd_ptr[l]) ? (wt_ptr[l] + `FIFO_DEPTH - rd_ptr[l]) : (wt_ptr[l] - rd_ptr[l]);
            assign fifo_busy[l]  = num_entry[l] >= (`FIFO_DEPTH/2);             // If the fifo is more than halfly full, assert busy and make the multipliers stall
            //assign fifo_full[l]  = (wt_ptr + 1) == rd_ptr;                    // When the two pointers are different except for the overflow bit (currently not used)
        end
    endgenerate


    assign busy = |fifo_busy;
    //assign full = |fifo_full;

    // Pack output packet
    generate
        for (l = 0; l < `NUM_DST; l++) begin
            assign buffer_packet.crossbar_buffer_valid[l]   = out_packet[l].valid & out_valid[l];
            assign buffer_packet.crossbar_buffer_data[l]    = out_packet[l].data;
            assign buffer_packet.x_dir[l]                   = out_packet[l].x;
            assign buffer_packet.y_dir[l]                   = out_packet[l].y;
            assign buffer_packet.k_dir[l]                   = out_packet[l].k;
        end
    endgenerate

endmodule
