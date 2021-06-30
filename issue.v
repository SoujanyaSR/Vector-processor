`include "definitions.v"

module fetch();
     
     always @ (posedge var.clk)
     begin
         //check ---
       // #`clk_period;
        //fetch unless previous instruction is bne       
        if(!var.IQ_busy && !var.bne_instr_detect )
        
        begin
            $display ("clk_%0t--->  Iteration:%d FETCH STAGE : \n \n",$time*0.0001,var.loopcount); 
            var.IQ[var.IQ_tail][7:0]=var.ins_mem[var.pc+6'd3];
            var.IQ[var.IQ_tail][15:8]=var.ins_mem[var.pc+6'd2];
            var.IQ[var.IQ_tail][23:16]=var.ins_mem[var.pc+6'd1];
            var.IQ[var.IQ_tail][31:24]=var.ins_mem[var.pc];
            
            var.IQ_count = var.IQ_count+1;
            if(var.IQ_count>0 && var.IQ[var.IQ_tail][6:0]== 7'b1100011)
            begin
                var.bne_instr_detect=1'b1;                
                $display("clk_%0t--->  Iteration:%d BNE detected!",$time*0.0001,var.loopcount);                
            end
          
             $display("clk_%0t--->  Iteration:%d Fetching instr: %h \n PC= %b \n IQ_tail= %b \n",$time*0.0001,var.loopcount, var.IQ[var.IQ_tail],var.pc,var.IQ_tail);
              
            var.pc=var.pc+6'd4;
            var.IQ_tail=var.IQ_tail+4'b0001;
           
            if(var.IQ_count==`IQ_SIZE)
            begin
                var.IQ_busy=1'b1;
                 $display("clk_%0t--->  Iteration:%d stall, IQ=FULL, Current PC = %b\n",$time*0.0001,var.loopcount,var.pc);               
            end  
            
            //enabling decoder if atleast one instr is received
            if(var.IQ_count > 0)
                var.decoder_en <= 1'b1; 
            
        end

       end
     
     endmodule



     module decode();
     
     integer i,j,k, busy;
     always @ (posedge var.clk)
     begin//1
        
         // #(`clk_period); //check---
          
        if(!var.decoder_busy && var.decoder_en && var.IQ_head < var.IQ_tail)
        begin//2
       
        $display("clk_%0t--->  Iteration:%dDECODE STAGE : \n",$time*0.0001,var.loopcount);
        var.is_vector = 1'b0;
        var.is_scalar = 1'b0;
        
            $display("clk_%0t--->  Iteration:%d Decode instr %h, opcode: %b",$time*0.0001,var.loopcount,var.IQ[var.IQ_head], var.IQ[var.IQ_head][6:0]);
            if((var.IQ[var.IQ_head][6:0]==7'b0000111) || (var.IQ[var.IQ_head][6:0]==7'b0100111) || (var.IQ[var.IQ_head][6:0]==7'b1010111))
                var.is_vector = 1'b1;
            else if ((var.IQ[var.IQ_head][6:0]==7'b0010011) || (var.IQ[var.IQ_head][6:0]==7'b1100011))
                var.is_scalar=1;
            else
                begin//4
                    $display("clk_%0t--->  Iteration:%d invalid opcode !\n",$time*0.0001,var.loopcount);
                   // $stop;
                end//4

                        
         // ------------------------------------------Vector Decoding  ------------------------------------------
            //vector instr decoding
            if(var.is_vector)
            begin//5
               // if(!var.RS_v_FULL) 
                begin//6
                    
                //extract vector instr feilds
                case(var.IQ[var.IQ_head][6:0])
                    7'b0000111: //vector loads
                    begin//8
                        RS_v_scan();
                        var.RS_v[var.RS_available][`rs_v_opcode]=var.IQ[var.IQ_head][6:0];
                        var.RS_v[var.RS_available][`rs_v_dest] =var.IQ[var.IQ_head][11:7];
                        //making register value at dest invalid till instruction is executed 
                        for(i=0;i<32;i=i+1)                       
                            var.ARF_vector_temp[var.RS_v[var.RS_available][`rs_v_dest]][i][`ARF_v_busy]=1'b1;
                        var.RS_v[var.RS_available][`rs_v_src1] =var.IQ[var.IQ_head][19:15];
                         //scalar ARF
                        if(var.ARF_s_temp_busy[var.RS_v[var.RS_available][`rs_v_src1]])
                        begin
                           var.RS_v[var.RS_available][`rs_v_src1_busy] = 4'b1111;
                        end                      

                    end//8
                    7'b0100111: //vector stores
                    begin//9
                        RS_v_scan();
                        var.RS_v[var.RS_available][`rs_v_opcode]=var.IQ[var.IQ_head][6:0];
                        var.RS_v[var.RS_available][`rs_v_src1] =var.IQ[var.IQ_head][19:15];// rs1
                        var.RS_v[var.RS_available][`rs_v_src2] =var.IQ[var.IQ_head][11:7]; //vs2

                        //check for scalar address busy
                        if(var.ARF_s_temp_data[var.RS_v[var.RS_available][`rs_v_src1]])
                        begin
                           var.RS_v[var.RS_available][`rs_v_src1_busy] = 4'b1111;
                        end 
                        
                        //check fro vector data busy
                        
                        var.RS_v[var.RS_available][`rs_v_src2_busy] = 4'b1111;

                        for(j=0; j<4; j=j+1)
                        begin//10
                            busy = 0;
                        for(k=0;k<8;k=k+1)
                        begin//11

                            busy = busy| var.ARF_vector[var.RS_v[var.RS_available][`rs_v_src2]][j*8+32*var.loopcount+k][`ARF_v_busy];
                            //increment loopcount when bne is executed
                            
                        end//11
                            if(!busy) 
                            begin//12                            
                            
                            case(j)
                                0: var.RS_v[var.RS_available][`rs_v_src2_busy] = 4'b1110;
                                1:var.RS_v[var.RS_available][`rs_v_src2_busy] = 4'b1100;
                                2:
                                var.RS_v[var.RS_available][`rs_v_src2_busy] = 4'b1000;
                                3: 
                                var.RS_v[var.RS_available][`rs_v_src2_busy] = 4'b0000 ;                       
                            endcase 
                            end//12
                             
                        end//10
                    
                    end//9
                    7'b1010111: //vector add and sub
                    begin//13
                        RS_v_scan();   
                        var.RS_v[var.RS_available][`rs_v_opcode]=var.IQ[var.IQ_head][6:0];
                        var.RS_v[var.RS_available][`rs_v_func]={var.IQ[var.IQ_head][31:26],var.IQ[var.IQ_head][14:12]};

                        //check for src1
                        case(var.IQ[var.IQ_head][14:12])
                        3'b000://add
                        begin//14
                            //vector data src1
                            
                        var.RS_v[var.RS_available][`rs_v_src1] =var.IQ[var.IQ_head][19:15];// vs1
                        var.RS_v[var.RS_available][`rs_v_src2] =var.IQ[var.IQ_head][24:20]; //vs2 
                         var.RS_v[var.RS_available][`rs_v_dest] =var.IQ[var.IQ_head][11:7];// vd
                         for(i=0;i<32;i=i+1) 
                            var.ARF_vector_temp[var.RS_v[var.RS_available][`rs_v_dest]][i][`ARF_v_busy]=1'b1;
                          
                        var.RS_v[var.RS_available][`rs_v_src1_busy] = 4'b1111;
                        

                        for(j=0; j<4; j=j+1)
                        begin//15
                            busy = 0;
                        for(k=0;k<8;k=k+1)
                        begin//16

                            busy = busy| var.ARF_vector[var.RS_v[var.RS_available][`rs_v_src1]][j*8+32*var.loopcount+k][`ARF_v_busy];
                            //increment loopcount when bne is executed
                            
                        end//16
                            if(!busy) 
                            begin //17                           
                            
                            case(j)
                                0: var.RS_v[var.RS_available][`rs_v_src1_busy] = 4'b1110;
                                1:var.RS_v[var.RS_available][`rs_v_src1_busy] = 4'b1100;
                                2:
                                var.RS_v[var.RS_available][`rs_v_src1_busy] = 4'b1000;
                                3: 
                                var.RS_v[var.RS_available][`rs_v_src1_busy] = 4'b0000 ;                       
                            endcase 
                            end//17
                             
                        end//15
                        
                        end//14

                        3'b100://sub
                        begin//18
                                
                                 var.RS_v[var.RS_available][`rs_v_src1] =var.IQ[var.IQ_head][19:15];// rs1
                                var.RS_v[var.RS_available][`rs_v_src2] =var.IQ[var.IQ_head][24:20]; //vs2 
                                var.RS_v[var.RS_available][`rs_v_dest] =var.IQ[var.IQ_head][11:7];// vd
                                for(i=0;i<32;i=i+1) 
                                    var.ARF_vector_temp[var.RS_v[var.RS_available][`rs_v_dest]][i][`ARF_v_busy]=1'b1;
                                
                            //scalar data src1
                            if(var.ARF_s_temp_busy[var.RS_v[var.RS_available][`rs_v_src1]])
                            begin
                             var.RS_v[var.RS_available][`rs_v_src1_busy] = 4'b1111;
                            end                            
                        end//18
                        endcase
                        
                         //vector data src2   
                        var.RS_v[var.RS_available][`rs_v_src2_busy] = 4'b1111;

                        for(j=0; j<4; j=j+1)
                        begin//19
                            busy = 0;
                        for(k=0;k<8;k=k+1)
                        begin//20

                            busy = busy| var.ARF_vector[var.RS_v[var.RS_available][`rs_v_src2]][j*8+32*var.loopcount+k][`ARF_v_busy];
                            //increment loopcount when bne is executed
                            
                        end//20
                            if(!busy) 
                            begin//21                            
                            
                            case(j)
                                0: var.RS_v[var.RS_available][`rs_v_src2_busy] = 4'b1110;
                                1:var.RS_v[var.RS_available][`rs_v_src2_busy] = 4'b1100;
                                2:
                                var.RS_v[var.RS_available][`rs_v_src2_busy] = 4'b1000;
                                3: 
                                var.RS_v[var.RS_available][`rs_v_src2_busy] = 4'b0000 ;                       
                            endcase 
                            end//21
                             
                        end//19
                        
                    end//13
                endcase //for vector opcodes

                var.RS_v[var.RS_available][`rs_v_busy] <= 1'b1;

                end //12               
            end
           // ------------------------------------------Scalar Decoding  ------------------------------------------
            //scalar instr decoding
            else if(var.is_scalar)
                begin
                    RS_s_scan();
                    var.RS_s[var.RS_idx][`rs_s_opcode] = var.IQ[var.IQ_head][6:0]; 

                    //extract scalar instr fields
                    case(var.RS_s[var.RS_idx][`rs_s_opcode])
                        7'b0010011://aadi
                        begin 
                        
                            var.RS_s[var.RS_idx][`rs_s_src1] = var.IQ[var.IQ_head][19:15];
                            var.RS_s[var.RS_idx][`rs_s_dest] = var.IQ[var.IQ_head][11:7];
                            var.ARF_s_temp_busy[var.RS_s[var.RS_idx][`rs_s_dest]] = 1'b1;
                            //m
                            var.RS_s[var.RS_idx][`rs_s_imm12]= var.IQ[var.IQ_head][31:20];                           

                        end
                        7'b1100011://bne
                        begin
                             var.RS_s[var.RS_idx][`rs_s_src1] = var.IQ[var.IQ_head][19:15];
                             var.RS_s[var.RS_idx][`rs_s_src2] = var.IQ[var.IQ_head][24:20];
                             var.RS_s[var.RS_idx][`rs_s_imm12]= {var.IQ[var.IQ_head][31],var.IQ[var.IQ_head][7],var.IQ[var.IQ_head][30:25],var.IQ[var.IQ_head][11:8]};

                        end
                    endcase
                        var.RS_s[var.RS_idx][`rs_s_busy] <= 1'b1;
                    
                end
             if(var.IQ_head != var.IQ_tail)   
                var.IQ_head=var.IQ_head+4'd1;
               
           // var.IQ_count=var.IQ_count-1;
        end

    end//1
    
    
 ///////////////////////////////////////////////////RS Scanning///////////////////////////////////////////////// 
 //tasks

 task automatic RS_v_scan;
 begin
     
     for(i=0;i<`RS_v_SIZE;i=i+1)
         begin
            if( var.RS_v[i][`rs_v_busy] != 1 ) //if we find atleast 1 RS free
            begin
                var.RS_v_FULL = 0;
                var.decoder_busy = 0;
                var.RS_available = i;
                i = `RS_v_SIZE;
            end

            else
            begin
                var.RS_v_FULL = 1;
                var.decoder_busy = 1;
               // $display("clk_%0t--->  Iteration:%d RS FULL---stall \n");
            end
         end
end         
 endtask 
 
  task automatic RS_s_scan;
   begin
         for(i=0;i<`RS_s_SIZE;i=i+1)
         begin
            if( var.RS_s[i][`rs_s_busy] != 1 ) //if we find atleast 1 RS free
            begin
                var.RS_s_FULL = 0;
                var.decoder_busy = 0;
                var.RS_idx = i;
                i = `RS_s_SIZE;
            end

            else
            begin
                var.RS_s_FULL = 1;
                var.decoder_busy = 1;
                //$display("clk_%0t--->  Iteration:%d RS FULL---stall \n");
            end
         end
         
     end
     endtask
   
  endmodule
  