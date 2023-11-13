module max_pooling(
  input clk,
  input rst,
  input  Buffer_PPU_PACKET ppu_data_in,
  input [$clog2(`max_popling_size_output)-1:0] pooling_size_Boundary,
  input [`pooling_num-1:0][$clog2(`max_popling_size_output)-1:0] stage_pooling_Boundary,
  output logic [$clog2(`Accumulator_buffer_k_offset)-1:0] kc_num,
  output  PPU_compress_PACKET pooling_compress_out
);
parameter  N=3, IDLE='d0, pooling='d1,Complete='d2;
logic [$clog2(N)-1:0] state, nx_state;
 Buffer_Pooling_BLOCK [`Accumulator_buffer_bank_size-1:0][`pooling_buffer_entry-1:0]Current_buffer;
 Buffer_Pooling_BLOCK [`Accumulator_buffer_bank_size-1:0][`pooling_buffer_entry-1:0]nx_buffer ;
logic [$clog2(`pooling_buffer_entry)-1:0] Current_entry, nx_entry;//  write to which buffer entry
logic [$clog2(`Accumulator_buffer_bank_size)-1:0] nx_entry_cnt,Current_entry_cnt;// which entry in k
logic [$clog2(`pooling_num)-1:0] nx_pooling_cnt, Current_pooling_cnt;// which  stage 
logic [$clog2(`max_popling_size_output)-1:0] nx_stage_pooling_Boundary_cnt,Current_stage_pooling_Boundary_cnt;//nx stage pooling 0 8 16
logic [$clog2(`pooling_buffer_entry)-1:0] nx_pooling_entry_cnt,Current_pooling_entry_cnt;// which buffer entry
logic [$clog2(`Accumulator_buffer_k_offset)-1:0] nx_k,Current_k;// which buffer entry
logic pooling_finish;


// logic test_1;
// logic test_2;
assign kc_num=Current_k;
always_ff@(posedge clk)begin
    if(rst)begin
        state<=#1 'd0;
        Current_buffer <=#1 'd0;
        Current_entry <=#1 'd0;
        Current_entry_cnt<=#1 'd0;
        Current_pooling_cnt<=#1 'd0;
        Current_stage_pooling_Boundary_cnt<=#1 stage_pooling_Boundary[0];
        Current_pooling_entry_cnt<=#1 'd0;
        Current_k<=#1 'd0;
    end
    else if(pooling_finish) begin
        state<=#1 'd0;
        Current_buffer <=#1 'd0;
        Current_entry <=#1 'd0;
        Current_entry_cnt<=#1 'd0;
        Current_pooling_cnt<=#1 'd0;
        Current_stage_pooling_Boundary_cnt<=#1 stage_pooling_Boundary[0];
        Current_pooling_entry_cnt<=#1 'd0;
        Current_k<=#1 'd0;
    end
    else begin
        state<=#1 nx_state;
        Current_buffer <=#1 nx_buffer;
        Current_entry <=#1 nx_entry; 
        Current_entry_cnt<=#1 nx_entry_cnt;
        Current_pooling_cnt<=#1 nx_pooling_cnt;
        Current_stage_pooling_Boundary_cnt<=#1 nx_stage_pooling_Boundary_cnt;
        Current_pooling_entry_cnt<=#1 nx_pooling_entry_cnt;
        Current_k<=#1 nx_k;
    end
end

always_comb begin
    nx_buffer = Current_buffer;
    nx_entry = Current_entry;
    nx_pooling_cnt=Current_pooling_cnt;
    pooling_compress_out.valid = 0;
    pooling_compress_out.data = 0;
    nx_stage_pooling_Boundary_cnt = Current_stage_pooling_Boundary_cnt;
    nx_pooling_entry_cnt = Current_pooling_entry_cnt;
    nx_entry_cnt = Current_entry_cnt;
    nx_k = Current_k;


    for(int i =0;i<`Accumulator_buffer_bank_size;i++)begin
      if(ppu_data_in.valid[i]) begin
      nx_buffer[i][Current_entry].buffer_data = ppu_data_in.data[i];
      end
    end
    nx_entry = (!ppu_data_in.valid[0])? Current_entry:(Current_entry == `pooling_buffer_entry-1)? 'd0:Current_entry+1;
    


    case(state)
        IDLE: begin
            if(Current_entry=='d2)begin
                nx_state=pooling;
            end
            else begin
                nx_state=IDLE;
            end 
            pooling_finish = 'b0;
        end
        pooling: begin 
            nx_pooling_cnt = (Current_pooling_cnt == `pooling_num-1)|| (pooling_size_Boundary-1 <=stage_pooling_Boundary[1])? 0:Current_pooling_cnt+'d1;
            
            nx_entry_cnt = (!(Current_pooling_cnt == `pooling_num-1))&&(pooling_size_Boundary-1 >stage_pooling_Boundary[1])? Current_entry_cnt:((Current_entry_cnt+2)==pooling_size_Boundary-1)&& 
            ((Current_pooling_cnt == `pooling_num-1)||pooling_size_Boundary-1 <=stage_pooling_Boundary[1])? 'd0 
                            :Current_entry_cnt+'d2;
                            

            nx_k = ((Current_entry_cnt+2)==pooling_size_Boundary-1) && ((Current_pooling_cnt == `pooling_num-1)|| (pooling_size_Boundary-1 <=stage_pooling_Boundary[1])) ?
                      Current_k+'d1: Current_k ;
              for(int j =0;j<`pooling_out_size;j++)begin
                   if((j*2+Current_stage_pooling_Boundary_cnt +2) < pooling_size_Boundary+1    ) begin


                    pooling_compress_out.data[j] =(Current_buffer[j*2+nx_stage_pooling_Boundary_cnt][nx_pooling_entry_cnt].buffer_data >   //[0,0], 
                                                  Current_buffer[j*2+nx_stage_pooling_Boundary_cnt][nx_pooling_entry_cnt+1].buffer_data ) ?
                                                  Current_buffer[j*2+nx_stage_pooling_Boundary_cnt][nx_pooling_entry_cnt].buffer_data :
                                                  Current_buffer[j*2+nx_stage_pooling_Boundary_cnt][nx_pooling_entry_cnt+1].buffer_data;

                    pooling_compress_out.data[j] =(pooling_compress_out.data[j] >  
                                                  Current_buffer[j*2+nx_stage_pooling_Boundary_cnt][nx_pooling_entry_cnt+2].buffer_data ) ?
                                                  pooling_compress_out.data[j] :
                                                  Current_buffer[j*2+nx_stage_pooling_Boundary_cnt][nx_pooling_entry_cnt+2].buffer_data;

                    pooling_compress_out.data[j] =(pooling_compress_out.data[j] > 
                                                  Current_buffer[j*2+nx_stage_pooling_Boundary_cnt+1][nx_pooling_entry_cnt].buffer_data ) ?
                                                  pooling_compress_out.data[j] :
                                                  Current_buffer[j*2+nx_stage_pooling_Boundary_cnt+1][nx_pooling_entry_cnt].buffer_data;
                                                  
                    pooling_compress_out.data[j] =(pooling_compress_out.data[j] > 
                                                  Current_buffer[j*2+nx_stage_pooling_Boundary_cnt+1][nx_pooling_entry_cnt+1].buffer_data ) ?
                                                  pooling_compress_out.data[j] :
                                                  Current_buffer[j*2+nx_stage_pooling_Boundary_cnt+1][nx_pooling_entry_cnt+1].buffer_data;

                    pooling_compress_out.data[j] =(pooling_compress_out.data[j] > 
                                                  Current_buffer[j*2+nx_stage_pooling_Boundary_cnt+1][nx_pooling_entry_cnt+2].buffer_data ) ?
                                                  pooling_compress_out.data[j] :
                                                  Current_buffer[j*2+nx_stage_pooling_Boundary_cnt+1][nx_pooling_entry_cnt+2].buffer_data;  

                    pooling_compress_out.data[j] =(pooling_compress_out.data[j] > 
                                                  Current_buffer[j*2+nx_stage_pooling_Boundary_cnt+2][nx_pooling_entry_cnt].buffer_data ) ?
                                                  pooling_compress_out.data[j] :
                                                  Current_buffer[j*2+nx_stage_pooling_Boundary_cnt+2][nx_pooling_entry_cnt].buffer_data ;

                     pooling_compress_out.data[j] =(pooling_compress_out.data[j] > 
                                                  Current_buffer[j*2+nx_stage_pooling_Boundary_cnt+2][nx_pooling_entry_cnt+1].buffer_data ) ?
                                                  pooling_compress_out.data[j] :
                                                  Current_buffer[j*2+nx_stage_pooling_Boundary_cnt+2][nx_pooling_entry_cnt+1].buffer_data;
                                                                       
                     pooling_compress_out.data[j] =(pooling_compress_out.data[j] >
                                                  Current_buffer[j*2+nx_stage_pooling_Boundary_cnt+2][nx_pooling_entry_cnt+2].buffer_data ) ?
                                                  pooling_compress_out.data[j] :
                                                  Current_buffer[j*2+nx_stage_pooling_Boundary_cnt+2][nx_pooling_entry_cnt+2].buffer_data  ;
              
                     pooling_compress_out.valid[j]='d1;

                end
              end
            nx_stage_pooling_Boundary_cnt = (nx_pooling_cnt <= `pooling_num-1)? stage_pooling_Boundary[nx_pooling_cnt]:stage_pooling_Boundary[0];

            nx_pooling_entry_cnt =(Current_pooling_cnt < `pooling_num-1)&&(pooling_size_Boundary-1 >stage_pooling_Boundary[1]) &&((Current_entry_cnt+2)<pooling_size_Boundary-1) ?
             Current_pooling_entry_cnt :((Current_pooling_cnt == `pooling_num-1)||(pooling_size_Boundary-1 <=stage_pooling_Boundary[1]))&&((Current_entry_cnt+2)==pooling_size_Boundary-1)?
                            Current_pooling_entry_cnt+'d3:Current_pooling_entry_cnt +'d2 ; 

                    
            if((Current_k == (`Accumulator_buffer_k_offset-1)) && ((Current_entry_cnt+2)==pooling_size_Boundary-1) && ((Current_pooling_cnt == `pooling_num-1)|| (pooling_size_Boundary-1 <=stage_pooling_Boundary[1]))) begin
                nx_state=Complete;
            end
            else begin
                nx_state=pooling;
            end
        end

        Complete: begin
            pooling_finish = 'b1;
            nx_state=IDLE;
        end
            default: nx_state=IDLE;    
    endcase
end//end_comb
endmodule