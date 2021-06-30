//Vector Processor constants
`define VLEN        32
`define lane_size   8 //number of lanes
`define bank_size   8 //number of banks
`define clk_period  10

//IQ
`define IQ_SIZE     15
 

//Scalar ARF
`define ARF_s_busy  32
`define ARF_s_data  31:0 //32bits data

//`define ARF_s_tag   4:0 //not to be used

//Vecotr ARF
`define ARF_v_busy  32
`define ARF_v_data  31:0 //32bits data

//Vector RS
//`define rs_v_busy        41
//`define rs_v_ex          40
`define rs_v_lsq         51:49
`define rs_v_m4          48
`define rs_v_m3          47
`define rs_v_m2          46
`define rs_v_m1          45
`define rs_v_busy        44
`define rs_v_ex          43:40
`define rs_v_opcode      39:33
`define rs_v_func        32:24
`define rs_v_dest        23:19
`define rs_v_src1        18:14
`define rs_v_src2        13:9
`define rs_v_MDR_valid1  8
`define rs_v_src1_busy   7:4
`define rs_v_src2_busy   3:0
`define RS_v_SIZE          6//5


//Scalar RS 
`define rs_s_busy       35
`define rs_s_exe        34
`define rs_s_opcode     33:27
`define rs_s_dest       26:22
`define rs_s_src1       21:17
`define rs_s_src2       16:12
`define rs_s_imm12      11:0
`define RS_s_SIZE       7
//not keeping any src_busy fields as for the set of instructions we have considered, sources are avaialable
//considered set of instructions can be identified using just the opcodes, so func fileds are recorded

//LSQ for vectors
`define lsq_v_busy   32
`define lsq_v_4      31:17
`define lsq_v_3      23:16
`define lsq_v_2      8:15
`define lsq_v_1      0:7
`define LSQ_v_SIZE   8

//Miscellaneous
`define SEEK_SET 0


