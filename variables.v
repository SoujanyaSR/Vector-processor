`include "definitions.v"
module var;
    
     reg clk;
     
     //Memories
     reg [7:0] ins_mem [0:43];//byte addressable memory
     reg [31:0] data_mem [0:119][0:`bank_size-1];//word addressable data memory - V1,V2,V4 //    
     
     
     //Register files     
     reg  [32:0] ARF_scalar   [0:31]; //for 32 architectural register file registers   
     reg [32:0] ARF_vector [0:31][0:31] ;
     reg [32:0] ARF_vector_temp [0:31][0:31] ; // VLEN = 32;elements each of 32bits 
     //duplication of ARF_vector / temp storage to aid chaining and proper write back    
             
     
    //example  v1[5]--- ARF_vector[0][5][`ARF_v_data] 

    //Fetch stage variables
     reg IQ_busy;
     reg [5:0] pc;//44=101100, point upto 64 instruction
     reg [31:0] IQ [0:`IQ_SIZE-1];//each of 32 bits, even two will be sufficient,
     //NO STALLING IS REQUIRED FOR GIVEN SET OF INSTRUCTIONS
     reg [3:0] IQ_tail;// to point 8 inst., tail to push intructions
     reg [3:0] IQ_head;//to pull instruction
     integer IQ_count;// no. of instruction present in IQ
     reg bne_instr_detect;
     reg decoder_en;
     
    
     //decode stage variables
     
     reg is_vector,is_scalar;
     reg decoder_busy;
     reg [3:0] loopcount; //for 10 loops
     
     

     //RS_v : Vector Add/sub as well as for load/store to do in-order execution
     reg RS_v_FULL;    
     //reg [41:0] RS_v [0:`RS_v_SIZE-1];//for 5 vector instruction
     reg [51:0] RS_v [0:`RS_v_SIZE-1];//for 5 vector instruction
     reg [2:0] RS_available;
        

     //Execution unit variables
     //vector
     reg EX_v_busy;
     reg ex_v_store_done;
     reg [1:0] ex_v_counter;
     reg [3:0] ex_v_lanes; //to compare 1000 i.e, 8 lanes
     
     //variables for memory accessing     
     //lsq
     reg [32:0] LSQ [0:7];
     reg [2:0] LSQ_v_idx;
     reg    LSQ_v_full;
      
     reg [1:0]mem_v_counter;
     
     //scalar
      reg EX_s_busy;
      reg [35:0] RS_s[0:`RS_s_SIZE-1];
       reg [2:0] RS_idx;
     reg  RS_s_FULL;
     reg [5:0] ex_s_bne_target;
     
     //Write back variables
     reg [31:0] ARF_s_temp_data [0:31];
     reg ARF_s_temp_busy [0:31];
     reg [1:0] wb_v_counter1;
     reg [1:0] wb_v_counter2;      
     
     //iteration variables
     integer i,j, p,q,file1,file2,f_position,seek;
     
     //initializations
     vector_proc proc1();
     initial
     begin
        //Resetting feilds and registers
        //clearing IQ 
        for(i=0; i<`IQ_SIZE;i=i+1)
         begin
            IQ[i] = {32{1'b0}};
         end 
        
        //clearing RS_v initially
         for(i=0; i<`RS_v_SIZE;i=i+1)
         begin
            RS_v[i] = {52{1'b0}};
         end  
         //clearing RS_s initially
         for(i=0; i<`RS_s_SIZE;i=i+1)
         begin
            RS_s[i] = {36{1'b0}};
         end  
         
         //clearing ARF_scalar
         for(i=5; i<32;i=i+1)
         begin
            ARF_s_temp_data[i] = 32'd0;
            ARF_s_temp_busy[i] = 1'b0;
         end 
         //clearning ARF_vector and its temp
         for(i=0; i<32;i=i+1)
         for(j=0; j<32;j=j+1)
         begin
            //ARF_vector[i][j] = {32{1'b0}};
            //ARF_vector_temp[i][j] = {32{1'b0}};         
            
         end 
         
         //clear LSQ
         for(i=0; i<`LSQ_v_SIZE;i=i+1)
         begin
            LSQ[i] = {33{1'b0}};
         end 
         
          $display("clk_%0t----------------------Vector Processor --------------- \n Function: C[i] = A[i]+B[i]-1\n",$time*0.0001);
         //Initializations   
         $readmemh("instructions_hex.dat",ins_mem);
         file1 = $fopen("data_1.dat","r");
         file2 = $fopen("data_2.dat","w");
         for(p=0;p<80;p=p+1)
         begin
            for(q=0;q<8;q=q+1)
            begin
                $fscanf(file1,"%d",data_mem[p][q]); 
                $fwrite(file2,"%d",data_mem[p][q]);          
            end
                $fwrite(file2,"\n" );
            end 
            $fclose(file1); 
            
         clk=1'b1;
          
         IQ_tail=3'b000;
         IQ_head=3'b000;
         pc=6'd0;
         IQ_count=0;
         IQ_busy=1'b0;
         bne_instr_detect = 1'b0;
         decoder_en = 1'b0;
         decoder_busy=0;        
        
         RS_v_FULL = 0;
         EX_v_busy = 0;
         EX_s_busy = 1'b0;
         LSQ_v_full = 1'b0;
         ex_v_store_done = 0;
          RS_idx = 1'b0;
          LSQ_v_idx = 3'h0;
        
         loopcount = 4'h0;
         ex_v_counter  = 2'h0;
         mem_v_counter = 2'h0;
         wb_v_counter1  = 2'h0;
         wb_v_counter2  = 2'h0;
         
          
         for(i=0; i<32;i=i+1)
         begin
            ARF_scalar[i] = 33'd0;
         end 
         //setting initial address
         
        //R0 for bne
         ARF_scalar[0][`ARF_s_data] = 32'd0;///scalar   
         ARF_scalar[0][`ARF_s_busy] = 1'b0;
         ARF_s_temp_data[0] = 32'd0;
         ARF_s_temp_busy[0] = 1'b0; 
         //R1:A  
         ARF_scalar[1][`ARF_s_data] = 32'd0;
         ARF_scalar[1][`ARF_s_busy] = 1'b0;
         //R2:B
         ARF_scalar[2][`ARF_s_data]= 32'd40;        
         ARF_scalar[2][`ARF_s_busy]= 1'b0;
         //R3:C
         ARF_scalar[3][`ARF_s_data] = 32'd80;
         ARF_scalar[3][`ARF_s_busy]= 1'b0;
         //R4://scalar to be subtracted
         ARF_scalar[4][`ARF_s_data]= 32'd1;
         ARF_scalar[4][`ARF_s_busy]= 1'b0; 
         ARF_s_temp_data[4] = 32'd1;
         ARF_s_temp_busy[4] = 1'b0;
          
         //R5://loopcounter var
         ARF_scalar[5][`ARF_s_data]= 32'd10;
         ARF_scalar[5][`ARF_s_busy]= 1'b0; 
         
              
        
     end
     always begin
     #5 clk =~clk ;
     end
     
     
     endmodule