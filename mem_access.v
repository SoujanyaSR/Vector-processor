`timescale 1ns / 1ps

`include "definitions.v"

module mem_access();

//iteration variables
integer im1, im2, im3, im4;
//memory
//for M1
always @(posedge var.clk)
begin
//#(`clk_period)
//scan RS for Busy and ex = 0001 or 0011 or 0111 or 1111
for(im1=0;im1<`RS_v_SIZE;im1=im1+1)
            begin
                if(var.RS_v[im1][`rs_v_busy] && (var.RS_v[im1][`rs_v_ex]!=4'b0000))
                begin
                   var.RS_v[im1][`rs_v_m1] <= 1'b1; 
                   $display("clk_%0t--->  Iteration:%d Mem1 of Instr:%d ", $time*0.0001,var.loopcount,im1+1); 
                end//if check flags
            end//for RS scan
                    

end//always

//for M2
always @(posedge var.clk)
begin
//scan RS for Busy and M1
for(im2=0;im2<`RS_v_SIZE;im2=im2+1)
            begin
                if(var.RS_v[im2][`rs_v_busy] && var.RS_v[im2][`rs_v_m1] && (var.RS_v[im2][`rs_v_opcode]== 7'b0000111 || var.RS_v[im2][`rs_v_opcode]==7'b0100111))
                begin
                   var.RS_v[im2][`rs_v_m2] <= 1'b1; 
                   $display("clk_%0t--->  Iteration:%d Mem2 of Instr:%d ", $time*0.0001,var.loopcount,im2+1); 
                end//if check flags
            end//for RS scan
end//always


//for M3
always @(posedge var.clk)
begin
//scan RS for Busy and M2
for(im3=0;im3<`RS_v_SIZE;im3=im3+1)
            begin
                if(var.RS_v[im3][`rs_v_busy] && var.RS_v[im3][`rs_v_m2] && (var.RS_v[im3][`rs_v_opcode]== 7'b0000111 || var.RS_v[im3][`rs_v_opcode]==7'b0100111))
                begin
                   var.RS_v[im3][`rs_v_m3] <= 1'b1;
                   $display("clk_%0t--->  Iteration:%d Mem3 of Instr:%d ", $time*0.0001,var.loopcount,im3+1);  
                end//if check flags
            end//for RS scan

end//always
reg [31:0] temp_c;
integer im5;
//for M4
always @(posedge var.clk)
begin
//scan RS for Busy and M3
for(im4=0;im4<`RS_v_SIZE;im4=im4+1)
            begin
                if(var.RS_v[im4][`rs_v_busy] && var.RS_v[im4][`rs_v_m3] && (var.RS_v[im4][`rs_v_opcode]== 7'b0000111 || var.RS_v[im4][`rs_v_opcode]==7'b0100111))
                begin
                    $display("clk_%0t--->  Iteration:%d Mem4 of Instr:%d ", $time*0.0001,var.loopcount,im4+1);
                   var.RS_v[im4][`rs_v_m4] <= 1'b1;
                   //check lqs if load
                   //if opcode load: load values from data mem reg to arf_vector temp
                   if( var.RS_v[im4][`rs_v_opcode] == 7'b0000111 )
                   begin
                    //get the lsq address and the EAC based on the counter
                    //mem_v_counter
                        for(im5 = 0 ; im5<`lane_size; im5 = im5+1)
                        begin
                            temp_c= var.data_mem[var.LSQ[var.RS_v[im4][`rs_v_lsq]][(var.mem_v_counter*8)+7 -: 8]][im5];                            
                            var.ARF_vector_temp[ var.RS_v[im4][`rs_v_dest]][(var.mem_v_counter*8)+im5] = { 1'b0,temp_c};//data,busy
                             
                        end//for lanes
                        
                        var.mem_v_counter <= (var.mem_v_counter+1)%4;                                   
                   end//load
                   
                 end//if check flags
            end//for RS scan
            
            

end//always

endmodule
