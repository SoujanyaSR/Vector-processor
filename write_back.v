`timescale 1ns / 1ps

`include "definitions.v"

module write_back();

integer iw1, iw2;
always @(posedge var.clk)
begin
    
    //ex 0001 , M4 : 0 to 7
    //
    //wb_v_counter
    for(iw1=0;iw1<`RS_v_SIZE;iw1=iw1+1)
            begin
                if(var.RS_v[iw1][`rs_v_busy] && var.RS_v[iw1][`rs_v_ex]!= 4'b0000)
                begin
                   //check for opcodes 
                  
                   case(var.RS_v[iw1][`rs_v_opcode])
                        7'b0000111://load
                        begin
                           
                             //scan RS for Busy and M4 : for load/store (4 clk cycle latency with pipelining)
                              $display("clk_%0t--->  Iteration:%d Writeback of Vload%d ",$time*0.0001,var.loopcount,iw1+1);
                             if(var.RS_v[iw1][`rs_v_m4])
                             begin                             
                                      
                             //writing back to ARF register file
                              for(iw2 = 0 ; iw2<`lane_size; iw2 = iw2+1)
                             begin
                                 var.ARF_vector[ var.RS_v[iw1][`rs_v_dest]][(var.wb_v_counter1*8)+iw2]= var.ARF_vector_temp[ var.RS_v[iw1][`rs_v_dest]][(var.wb_v_counter1*8)+iw2];                                 
                                     
                             end//for lanes
                                 
                                 //clearing RS_v after write back of 32 elements is finished
                                 if(var. wb_v_counter1 == 2'b11)
                                 begin
                                     var.RS_v[iw1] <= {52{1'b0}};                                     
                                end     
                                       
                                var. wb_v_counter1 = (var.wb_v_counter1 + 1 )%4;
                             
                             end//if load
                        
                        end//case load
                        
                         7'b0100111:
                         begin
                              //scan RS for Busy and M4 : for load/store (4 clk cycle latency with pipelining)
                              if(var.RS_v[iw1][`rs_v_m4])
                              begin
                                  $display("clk_%0t--->  Iteration:%d Writeback of Vstore %d ",$time*0.0001,var.loopcount,iw1+1);
                                  for(iw2 = 0 ; iw2<`lane_size; iw2 = iw2+1)
                                      begin
                                          var.data_mem[var.LSQ[var.RS_v[iw1][`rs_v_lsq]][(var.wb_v_counter1*8)+7 -: 8]][iw2] = 
                                          var.ARF_vector_temp[ var.RS_v[iw1][`rs_v_src2]][(var.wb_v_counter1*8)+iw2];
                                          $fwrite(var.file2,"%d",var.ARF_vector_temp[ var.RS_v[iw1][`rs_v_src2]][(var.wb_v_counter1*8)+iw2]);
                                       end                                  
                                        $fwrite(var.file2,"\n");
                                    if(var. wb_v_counter1 == 2'b11)
                                    begin
                                      var.RS_v[iw1] <= {52{1'b0}};
                                      var.ex_v_store_done <= 1'b1;
                                    end  
                                        
                                 var. wb_v_counter1 = (var.wb_v_counter1 + 1 )%4;
                              
                              end//if store
                         
                         end//case store
                   
                         7'b1010111: //add/sub
                         begin
                              //scan RS for Busy and M1 : for add/sub (1clk cycle latency)
                              if(var.RS_v[iw1][`rs_v_m1])
                              begin
							   $display("clk_%0t--->  Iteration:%d Writeback of Addi +/- %d ",$time*0.0001,var.loopcount,iw2+1);

                                        //writing back to ARF register file
                                    for(iw2 = 0 ; iw2<`lane_size; iw2 = iw2+1)
                                   begin
                                       var.ARF_vector[ var.RS_v[iw1][`rs_v_dest]][(var.wb_v_counter2*8)+iw2]= var.ARF_vector_temp[ var.RS_v[iw1][`rs_v_dest]][(var.wb_v_counter2*8)+iw2]; 
                                   end//for lanes
                                       
                                       //clearing RS_v after write back of 32 elements is finished
                                       if(var. wb_v_counter2 == 2'b11)
                                           var.RS_v[iw1] <= {52{1'b0}};
                                             
                                      var. wb_v_counter2 = (var.wb_v_counter2 + 1 )%4;                             
                              
                              end//if add sub
                         
                         end//case add/sub  
                   
                 endcase                 
                end//if
            end//for RS scan
    
    
        
    //reset m flags at the last writeback24:32
    
end //always
////////////////////////////////////////////////////////////////////////////////////////////////

  
endmodule
