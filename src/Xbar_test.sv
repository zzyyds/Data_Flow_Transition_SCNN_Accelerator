`timescale 1ns/100ps
`ifndef CLOCK_PERIOD
`define CLOCK_PERIOD 10
`endif

`include "sys_defs.svh"

module testbench;
    logic                           clock; 
    logic                           reset;
    
    // Interface with PE
    DATA_PACKET                     in_packet [`NUM_SRC-1:0];
    logic                           busy;


    // Inteface with acummulate buffer
    DATA_PACKET                     out_packet [`NUM_DST-1:0];
    logic [`NUM_DST-1:0]            out_valid; 
    
    Xbar Xbar_inst(
        .clock      (clock),
        .reset      (reset),

        .in_packet  (in_packet),
        .busy       (busy),

        .out_packet (out_packet),
        .out_valid  (out_valid)
    );

    int in_file;

    initial begin
        $display("========================================");
        $display("Begin simulation");

        in_file = $fopen("input2.txt", "r");

        // Initialize input
        clock           = 0;
        reset           = 0;
        for (int i = 0; i < `NUM_SRC; i++)
            in_packet[i]       = 0;
    

        // Reset datapath
        @(negedge clock)
        reset = 1;
        @(negedge clock)
        reset = 0;

        // Read signal from file and send value to datapath on every clock cycle
        //while (!$feof(in_file)) begin
            @(posedge clock)
            #1
            if (~busy) begin
                for (int i = 0; i < `NUM_SRC; i++) begin
                    in_packet[i].valid = 1;
                    $fscanf(in_file, "index=%d, data=%d", in_packet[i].index, in_packet[i].data);

                end
            end
        //end

        @(posedge clock)
        #1
        for (int i = 0; i < `NUM_SRC; i++)
            in_packet[i]    = 0;
        
        while (busy) @(posedge clock);

        #(`CLOCK_PERIOD)
        $fclose(in_file);
        //$fclose(out_file);
        $display("========================================");
        $finish;

    end



    always @(negedge clock) begin

        $display("@ Time:%4.0f",$time);
        $display("-------------------------");
        $display("FIFO[0]: rd_ptr=%0d  wt_ptr=%0d", Xbar_inst.rd_ptr[0], Xbar_inst.wt_ptr[0]);
        $display("-------------------------");
        for (int j = 0; j < `NUM_DST; j++) begin
            if (out_valid[j]) begin
                $display("@dst_port[%d]  data valid=%b  data=%d  dest_index=%d",
                    j, out_packet[j].valid, out_packet[j].data, out_packet[j].index);
            end else begin
                $display("@dst_port[%d]  port invalid", j);
            end
        end
        $display("busy:%b", busy);
        $display("-------------------------\n\n");
        $display("in_packet[0]: valid=%b, dest_index=%d, data=%d",
            Xbar_inst.in_packet[0].valid,
            Xbar_inst.in_packet[0].index,
            Xbar_inst.in_packet[0].data
        );
        //$fwrite(out_file, "%d\n", finst);

    end


    always begin
        #(`CLOCK_PERIOD/2.0);
        clock = ~clock;
    end

endmodule