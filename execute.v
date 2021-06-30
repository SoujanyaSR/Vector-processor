`timescale 1ns / 1ps

`include "definitions.v"

module execute();


///////////////////////////////////////////////RS scan for//////////////Ex unit///////////////////////////////////////

   //RS scan for free execution unit
   //vector
     integer i,m,n,e1,k,busy1, busy2;
     reg [3:0] src_busy_temp[2:1];
     reg [3:0] temp_ex;
     reg [31:0] temp_a, temp_b;
     integer r1;
     always @(posedge var.clk)
     begin
      //#(`clk_period*2);
       //#`clk_period;
       //#8;
        
       // if(!var.EX_v_busy)
       // begin
            for(m=0;m<`RS_v_SIZE;m=m+1)
            begin
                if(var.RS_v[m][`rs_v_busy] && (var.RS_v[m][`rs_v_ex]!=4'b1111))
                begin
                    
                    case (var.RS_v[m][`rs_v_opcode])
                        7'b0000111:
                        begin
                               //scan the busy bit of ARF_scalar
                               RS_s_busy_scan(1,busy1);
                              //if source is available     
                              if(!busy1)
                              begin   
                              //calculating the effective address for Loading elements
                              
                              if(var.ex_v_counter < (`VLEN/`lane_size))                             
                              begin
                             
                             //address = i+initial_address
                             //+(loop_count*(VLEN/n))
                             //for 0 to 7 elements : counter = 0
                             //for 8 to 15 elements : counter = 1
                             //for 16 to 23 elements : counter = 2
                             //for 24 to 31 elements : counter = 3
                             $display("clk_%0t--->  Iteration:%d VLoad[%d] Exe", $time*0.0001,var.loopcount,m+1);
                             
                              LSQ_scan();        
                             var.LSQ[var.LSQ_v_idx][(var.ex_v_counter*8)+7 -: 8]= 
                             var.ARF_scalar[var.RS_v[m][`rs_v_src1]][`ARF_s_data] + var.ex_v_counter
                             //+ (var.loopcount * (`VLEN/`lane_size))
                             ;
                             
                             var.RS_v[m][`rs_v_lsq]  = var.LSQ_v_idx;
                                                          
                              temp_ex = var.RS_v[m][`rs_v_ex];
                              temp_ex[var.ex_v_counter] = 1'b1;
                              var.RS_v[m][`rs_v_ex] <= temp_ex;
                              
                              if(var.ex_v_counter == 2'b11) 
                                var.LSQ[var.LSQ_v_idx][`lsq_v_busy] = 1'b1;
                                
                                //increment the counter 
                                  var.ex_v_counter = (var.ex_v_counter+1)%4;
                             end//if counter
                             end//if src available                                                                           
                        end//ld
                        
                        7'b0100111:
                        begin
                              //scan the busy bit of ARF_scalar
                              RS_s_busy_scan(1,busy1);
                              //if source is available     
                              if(!busy1)
                              begin 
                              //calculating the effective address for Storing elements  
                               if(var.ex_v_counter < (`VLEN/`lane_size))                             
                              begin
                             
                             //address = i+initial_address
                             //+(loop_count*(VLEN/n))
                             //for 0 to 7 elements : counter = 0
                             //for 8 to 15 elements : counter = 1
                             //for 16 to 23 elements : counter = 2
                             //for 24 to 31 elements : counter = 3
                             LSQ_scan(); 
                             var.LSQ[var.LSQ_v_idx][(var.ex_v_counter*8)+7 -: 8]= 
                             var.ARF_scalar[var.RS_v[m][`rs_v_src1]][`ARF_s_data] + var.ex_v_counter
                             //+(var.loopcount * (`VLEN/`lane_size))
                             ;
                               $display("clk_%0t--->  Iteration:%d Vstore Exe ",$time*0.0001,var.loopcount);
                             
                             var.RS_v[m][`rs_v_lsq]  = var.LSQ_v_idx;
                             
                              temp_ex = var.RS_v[m][`rs_v_ex];
                              temp_ex[var.ex_v_counter] = 1'b1;
                              var.RS_v[m][`rs_v_ex] <= temp_ex;
                              
                              if(var.ex_v_counter == 2'b11) 
                                var.LSQ[var.LSQ_v_idx][`lsq_v_busy] = 1'b1;
                                
                                //increment the counter 
                                  var.ex_v_counter = (var.ex_v_counter+1)%4;
                             end//if counter
                            end//if src available
                        end//st
                        
                        7'b1010111: //addi and subi
                        begin
                             
                             case(var.RS_v[m][`rs_v_func])
                             
                             9'b000000000: 
                                begin
                                    //vector src availablitiy check
                                    RS_v_busy_scan(1,busy1);
                                    RS_v_busy_scan(2,busy2);
                                    
                                   if(!busy1 && !busy2 ) 
                                   begin
                                   $display("clk_%0t--->  Iteration:%d Vadd Exe V%d +V%d ", $time*0.0001,var.loopcount,var.RS_v[m][`rs_v_src1],var.RS_v[m][`rs_v_src2]); 
                                  if( var.ex_v_counter < (`VLEN/`lane_size))                                  
                                  begin                                       
                                         //for 0 to 7 elements : counter = 0
                                         //for 8 to 15 elements : counter = 1
                                         //for 16 to 23 elements : counter = 2
                                         //for 24 to 31 elements : counter = 3
//                                        
                                             for(var.ex_v_lanes=0; var.ex_v_lanes<`lane_size; var.ex_v_lanes=var.ex_v_lanes+1)
                                             begin
                                             //dest_address+ (count*8) + i
                                             //concatenating busy=0 and sum                                                                                         
                                             temp_a = (var.ARF_vector_temp[var.RS_v[m][`rs_v_src1]][(var.ex_v_counter)*`lane_size+var.ex_v_lanes][`ARF_v_data]);
                                             temp_b = (var.ARF_vector_temp[var.RS_v[m][`rs_v_src2]][(var.ex_v_counter)*`lane_size+var.ex_v_lanes][`ARF_v_data]);                                             
                                             var.ARF_vector_temp[var.RS_v[m][`rs_v_dest]][(var.ex_v_counter)*`lane_size+var.ex_v_lanes] =
                                                {1'b0,temp_a+temp_b};
                                              
                                             end//for var.ex_v_lanes
                                             
                                            temp_ex = var.RS_v[m][`rs_v_ex];
                                            temp_ex[var.ex_v_counter] = 1'b1;
                                            var.RS_v[m][`rs_v_ex] <= temp_ex;
                                        
//                                         end//if:src check
                                        
                                    //increment the counter 
                                  var.ex_v_counter = (var.ex_v_counter+1)%4;
                                      
                                end //if: var.ex_v_counter 
                                end//if src available
                              end//case addi;
                              
                           9'b000010100: //sub
                           begin
                                RS_s_busy_scan(1,busy1);
                                RS_v_busy_scan(2,busy2);
                               //if source is available
                               if( !busy1 && !busy2)                              
                              begin 
                              $display("clk_%0t--->  Iteration:%d Vsub Exe V%d - 1 ", $time*0.0001,var.loopcount,var.RS_v[m][`rs_v_src2]); 
                                if(var.ex_v_counter < (`VLEN/`lane_size))
                                  begin
                                         //for 0 to 7 elements : counter = 0
                                         //for 8 to 15 elements : counter = 1
                                         //for 16 to 23 elements : counter = 2
                                         //for 24 to 31 elements : counter = 3
                                         
                                             for(var.ex_v_lanes=0; var.ex_v_lanes<`lane_size; var.ex_v_lanes=var.ex_v_lanes+1)
                                             begin
                                             //dest_address+ (count*8) + i
                                             //concatenating busy=0 and sum
                                                   temp_a =  (var.ARF_vector_temp[var.RS_v[m][`rs_v_src2]][(var.ex_v_counter)*`lane_size+var.ex_v_lanes][`ARF_v_data]);
                                                   temp_b = (var.ARF_scalar[var.RS_v[m][`rs_v_src1]]);
                                                   var.ARF_vector_temp[var.RS_v[m][`rs_v_dest]][(var.ex_v_counter)*`lane_size+var.ex_v_lanes] =
                                                     {1'b0,temp_a - temp_b};
                                               
                                             end//for var.ex_v_lanes
                                             
                                             temp_ex = var.RS_v[m][`rs_v_ex];
                                             temp_ex[var.ex_v_counter] = 1'b1;
                                             var.RS_v[m][`rs_v_ex] <= temp_ex;                                            
                                             
//                                         end//if:src check                                        
                                                                                  
                                   //increment the counter 
                                  var.ex_v_counter = (var.ex_v_counter+1)%4;
                                      
                                end //if: var.ex_v_counter
                                end//if src available
                           
                           end//case sub 
                           
                           endcase//add,sub    
                        end//vadd,vsub
                        
                    endcase//case: opcode
                    m = `RS_v_SIZE;
                end    
            end//for m
        //end//if:ex_busy
     end //always   
    
     
     //scalar :---------------------------- Ex/Mem(single unit)----------------------------------------
     reg [11:0]imm12;
     reg [31:0] temp_a1;
     integer id;
     always @(posedge var.clk)
     begin
        //#(`clk_period*2);
        //#10
        if(!var.EX_s_busy)
        begin
            for(n=0;n<`RS_s_SIZE;n=n+1)
            begin
                if(var.RS_s[n][`rs_s_busy] && !var.RS_s[n][`rs_s_exe])
                begin
                    case (var.RS_s[n][`rs_s_opcode])
                        7'b0010011: //ADDi
                        begin
                            //#10;
                            imm12 = var.RS_s[n][`rs_s_imm12];
                            temp_a1 = var.ARF_scalar[var.RS_s[n][`rs_s_src1]][`ARF_s_data];
                            
                            if(!imm12[11])
                                var.ARF_s_temp_data[var.RS_s[n][`rs_s_dest]]= temp_a1 + {{21{1'b0}},imm12[10:0]};
                            else
                                var.ARF_s_temp_data[var.RS_s[n][`rs_s_dest]] = temp_a1 - {{21{1'b0}},imm12[10:0]} ;
                             $display("clk_%0t--->  Iteration:%d Addi Exe %d +/- immed. %b| %d = %d",$time*0.0001,var.loopcount,temp_a1,imm12[11],imm12[10:0],var.ARF_s_temp_data[var.RS_s[n][`rs_s_dest]]);
                            var.ARF_s_temp_busy[var.RS_s[n][`rs_s_dest]] = 1'b0;
                            var.RS_s[n][`rs_s_exe] <= 1'b1;
                        end//addi
                        
                        7'b1100011://BNE
                        begin
                            //#10;
                            if(var.ex_v_store_done)
                            begin
                                var.loopcount = var.loopcount + 1; //increment the loopcount after the store is wb
                                $display("clk_%0t--->  Iteration:%d BNE Exe src1=%d src2=%d ",$time*0.0001,var.loopcount,var.ARF_s_temp_data[var.RS_s[n][`rs_s_src1]],var.ARF_scalar[var.RS_s[n][`rs_s_src2]]);
                                if( (var.ARF_s_temp_data[var.RS_s[n][`rs_s_src1]]!=var.ARF_scalar[var.RS_s[n][`rs_s_src2]]) //recent R5 required--> Forwarding from temp
                                 && var.loopcount<10) 
                                 //BNE R5 not equal to 0 
                                 //0 to 9: 10 loops : VLEN = 32; 32elements per loop*10loops = 320
                                begin
                                     //pc update
                                     imm12 = var.RS_s[n][`rs_s_imm12];
                                     if(!imm12[11])
                                         var.ex_s_bne_target = var.pc + (imm12*2);
                                     else
                                         var.ex_s_bne_target = var.pc - (imm12*2);                                    
                                      
                                      var.pc = var.ex_s_bne_target;  
                                      var.RS_s[n][`rs_s_exe] = 1'b1;
                                      
                                      //////////Reset IQ, RS_s and LSQ for next iteration
                                      reset_for_next_itr();
                                        
                                     // $stop;
                                end//if:loop
                                
                                else
                                    begin
                                       $display("clk_%0t--->  Iteration:%d \n Program Execution Completed Successfully!",$time*0.0001,var.loopcount);
                                       $fclose(var.file2);
                                      $stop;
                                       
                                    end  
                                   //Ending the program execution when calulation A[i]+B[i]-1 for 320 elements completes
                                     
                            end//if:store done
                            //else ex will be 0 and continuously scanned till store is done                           
                             
                        end//bne
                       
                    endcase//case: opcode
                   
                    n = `RS_s_SIZE;
                end    
            end//for m
        end//if:ex_busy
     end //always 
          
     
     


//////////////////////////////////////////////////////////

task automatic LSQ_scan;
begin
for(e1 = 0; e1 < `LSQ_v_SIZE; e1=e1+1)
    begin
        if(!var.LSQ[e1][`lsq_v_busy]) //if atleast one lsq is free
        begin
            var.LSQ_v_idx = e1;
            var.LSQ_v_full = 1'b0;
            e1 = `LSQ_v_SIZE;            
        end //if 
        else
            var.LSQ_v_full = 1'b1;
 end//for lsq 
end                             
endtask  

task automatic RS_v_busy_scan;
    input src;
    output busy_v;
begin
    busy_v = 0;
    
    for(k=0;k<8;k=k+1)
     begin  
     
        if(src==1) 
        begin                                 
            busy_v = busy_v| var.ARF_vector_temp[var.RS_v[m][`rs_v_src1]][(var.ex_v_counter*8)+k][`ARF_v_busy];
            //$display("clk_%0t--->  Iteration:%dRS_v_scan for rs[%d] %b...", $time*0.0001,loopcount,m,var.ARF_vector_temp[var.RS_v[m][`rs_v_src1]][(var.ex_v_counter*8)+(32*var.loopcount)+k][`ARF_v_busy]);
            if(!busy_v) 
            begin//21                            
            
            case(var.ex_v_counter)
                0:var.RS_v[m][`rs_v_src1_busy] = 4'b1110;
                1:var.RS_v[m][`rs_v_src1_busy] = 4'b1100;
                2:var.RS_v[m][`rs_v_src1_busy] = 4'b1000;
                3:var.RS_v[m][`rs_v_src1_busy] = 4'b0000 ;                       
            endcase 
           end //if busy
        end//if src1      
        else
        begin
            busy_v = busy_v| var.ARF_vector_temp[var.RS_v[m][`rs_v_src2]][(var.ex_v_counter*8)+k][`ARF_v_busy];            
           if(!busy_v) 
            begin//21                            
            
                case(var.ex_v_counter)
                    0:var.RS_v[m][`rs_v_src2_busy] = 4'b1110;
                    1:var.RS_v[m][`rs_v_src2_busy] = 4'b1100;
                    2:var.RS_v[m][`rs_v_src2_busy] = 4'b1000;
                    3:var.RS_v[m][`rs_v_src2_busy] = 4'b0000 ;                       
                endcase 
            
            end//if busy
         end//if src2
     end

end

endtask


task automatic RS_s_busy_scan;

    input src;
    output busy_s;
begin
    if(src==1)
    begin
          
         if(!var.ARF_scalar[var.RS_v[m][`rs_v_src1]][`ARF_s_busy] )
             var.RS_v[m][`rs_v_src1_busy] = 4'h0;
         
         if(!var.RS_v[m][`rs_v_src1_busy] == 4'h0)
            busy_s = 1'b1; 
         else
           busy_s = 1'b0; 
    end       
      
   else
   begin
        if(!var.ARF_scalar[var.RS_v[m][`rs_v_src2]][`ARF_s_busy] )
             var.RS_v[m][`rs_v_src2_busy] = 4'h0;
         
         if(!var.RS_v[m][`rs_v_src2_busy] == 4'h0)
            busy_s = 1'b1; 
         else
           busy_s = 1'b0;
    end       
             
        
end

endtask

task automatic reset_for_next_itr;
begin
 //clearing IQ 
    for(i=0; i<`IQ_SIZE;i=i+1)
    begin
       var.IQ[i] = {32{1'b0}};
    end                                    
   //clearing RS_s 
   for(i=0; i<`RS_s_SIZE;i=i+1)
   begin
      var.RS_s[i] = {36{1'b0}};
   end 
   //clear LSQ  
   for(i=0;i<`LSQ_v_SIZE;i=i+1)
   begin
      var.LSQ[i] = {33{1'b0}};
   end//clear lsq
   
   //write back for Scalar
   for(id=0;id<32;id=id+1)
    begin
         var.ARF_scalar[id][`ARF_s_data] = var.ARF_s_temp_data[id];
         var.ARF_scalar[id][`ARF_s_busy] = var.ARF_s_temp_busy[id];
    end
   
   //reset 
   var.bne_instr_detect = 1'b0;
   var.IQ_count = 1'b0;
   var.IQ_tail=3'h0;
   var.IQ_head=3'h0;
   var.decoder_en = 1'b0;
   var.is_vector = 1'b0;
   var.is_scalar = 1'b0;
   var.ex_v_store_done = 1'b0; 
   var.ex_v_counter  = 2'h0; 
   var.mem_v_counter = 2'h0; 
   var.wb_v_counter1  = 2'h0;
   var.wb_v_counter2  = 2'h0;                                     
   var.IQ_tail=3'b000;
   var.IQ_busy=1'b0;     
   var.decoder_busy=0;   
   var.RS_v_FULL = 0;    
   var.EX_v_busy = 0;    
   var.EX_s_busy = 1'b0; 
   var.LSQ_v_full = 1'b0;
                                        
end
endtask                                        
    
endmodule




