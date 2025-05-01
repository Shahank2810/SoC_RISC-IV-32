`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.02.2025 00:13:59
// Design Name: 
// Module Name: csr
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`include "riscv_defs.v"
`define MIP_EXT_INT  32'h800

module riscv_csr (
    input clk_i,
    input rst_i,
    input intr_i,
    input opcode_valid_i,
    input [57:0] opcode_instr_i,
    input [31:0] opcode_opcode_i,
    input [31:0] opcode_pc_i,
    input [4:0] opcode_rd_idx_i,
    input [4:0] opcode_ra_idx_i,
    input [4:0] opcode_rb_idx_i,
    input [31:0] opcode_ra_operand_i,
    input [31:0] opcode_rb_operand_i,
    input branch_exec_request_i,
    input [31:0] branch_exec_pc_i,
    input [31:0] cpu_id_i,
    input [31:0] reset_vector_i,
    input fault_store_i,
    input fault_load_i,
    input fault_misaligned_store_i,
    input fault_misaligned_load_i,
    input fault_page_store_i,
    input fault_page_load_i,
    input [31:0] fault_addr_i,
    
    output reg [4:0] writeback_idx_o,
    output  writeback_squash_o,
    output reg [31:0] writeback_value_o,
    output reg stall_o,
    output reg branch_csr_request_o,
    output reg [31:0] branch_csr_pc_o

    
);

wire excep;
reg [1:0] MPRIV;
wire intrp;
reg MIE_EN,MIP_EN,MEPC_EN,MCAUSE_EN, MSCRATCH_EN, MTVEC_EN,MSTATUS_EN;
reg [31:0] DIN;
wire interrupt;
wire MRET;

assign MRET = &(~((`INST_MRET_MASK & opcode_opcode_i)^`INST_MRET));
assign priv = MPRIV;
//debug
assign excp = excep;

wire intri;
assign intri = intr_i;

//MCAUSE REGISTER----------------------------------------------------------------------------------------------------------------------------------------
    reg illegal;
    reg [31:0] MCAUSE_REG;
    reg [31:0] MCAUSE;
    reg exc, intr;
    assign cause = MCAUSE_REG;
    
    assign MC = MCAUSE_REG;
    assign excep = exc;
    assign intrp = intr;
    
    always @(*) begin
        illegal = 1'b0;
        exc = 1'b0;
        MCAUSE_REG = 32'b0;
        intr = 1'b0;
        
        if (opcode_instr_i[`ENUM_INST_INVALID] || 
            ((MPRIV != `PRIV_MACHINE) && 
             ((opcode_instr_i[`ENUM_INST_CSRRW] | 
               opcode_instr_i[`ENUM_INST_CSRRS] | 
               opcode_instr_i[`ENUM_INST_CSRRC] | 
               opcode_instr_i[`ENUM_INST_CSRRWI] | 
               opcode_instr_i[`ENUM_INST_CSRRSI] | 
               opcode_instr_i[`ENUM_INST_CSRRCI]) && 
              opcode_valid_i && 
              (opcode_opcode_i[29:28] == 2'b11)))) begin
            illegal = 1'b1;
        end
        else illegal = 1'b0;
         
        if (intri) begin
            exc = 1'b0;
            MCAUSE_REG = `MCAUSE_INTERRUPT;
            intr = 1'b1;
        end else if (branch_exec_request_i == 1'b1 && (branch_exec_pc_i[0] | branch_exec_pc_i[1])) begin
            exc = 1'b1;
            MCAUSE_REG = `MCAUSE_MISALIGNED_FETCH;
            intr = 1'b0;
        end else if (opcode_instr_i[`ENUM_INST_FAULT]) begin
            exc = 1'b1;
            MCAUSE_REG = `MCAUSE_FAULT_FETCH;
            intr = 1'b0;
        end else if (illegal) begin
            exc = 1'b1;
            MCAUSE_REG = `MCAUSE_ILLEGAL_INSTRUCTION;
            intr = 1'b0;
        end else if (opcode_instr_i[`ENUM_INST_EBREAK]) begin
            exc = 1'b1;
            MCAUSE_REG = `MCAUSE_BREAKPOINT;
            intr = 1'b0;
        end else if (fault_misaligned_load_i) begin
            exc = 1'b1;
            MCAUSE_REG = `MCAUSE_MISALIGNED_LOAD;
            intr = 1'b0;
        end else if (fault_load_i) begin
            exc = 1'b1;
            MCAUSE_REG = `MCAUSE_FAULT_LOAD;
            intr = 1'b0;
        end else if (fault_misaligned_store_i) begin
            exc = 1'b1;
            MCAUSE_REG = `MCAUSE_MISALIGNED_STORE;
            intr = 1'b0;
        end else if (fault_store_i) begin
            exc = 1'b1;
            MCAUSE_REG = `MCAUSE_FAULT_STORE;
            intr = 1'b0;
        end else if (opcode_instr_i[`ENUM_INST_ECALL] && MPRIV == `PRIV_USER) begin
            exc = 1'b1;
            MCAUSE_REG = `MCAUSE_ECALL_U;
            intr = 1'b0;
        end else if (opcode_instr_i[`ENUM_INST_ECALL] && MPRIV == `PRIV_SUPER) begin
            exc = 1'b1;
            MCAUSE_REG = `MCAUSE_ECALL_S;
            intr = 1'b0;
        end else if (opcode_instr_i[`ENUM_INST_ECALL] && MPRIV == `PRIV_MACHINE) begin
            exc = 1'b1;
            MCAUSE_REG = `MCAUSE_ECALL_M;
            intr = 1'b0;
        end else if (opcode_instr_i[`ENUM_INST_PAGE_FAULT]) begin
            exc = 1'b1;
            MCAUSE_REG = `MCAUSE_PAGE_FAULT_INST;
            intr = 1'b0;
        end else if (fault_page_load_i) begin
            exc = 1'b1;
            MCAUSE_REG = `MCAUSE_PAGE_FAULT_LOAD;
            intr = 1'b0;
        end else if (fault_page_store_i) begin
            exc = 1'b1;
            MCAUSE_REG = `MCAUSE_PAGE_FAULT_STORE;
            intr = 1'b0;
        end else begin
            exc = 1'b0;
            MCAUSE_REG = 32'b0;
            intr = 1'b0;
        end
        
    end
    
    always @(posedge clk_i) begin
        if (!rst_i) 
            MCAUSE <= 32'b0;
        else begin
            if (exc == 1'b1 || intr == 1'b1) 
                MCAUSE <= MCAUSE_REG;
            else if (MCAUSE_EN) 
                MCAUSE <= DIN;
        end
    end

//MIE----------------------------------------------------------------------------------------------------------------------------------------------
reg [31:0] MIE;
always@(posedge clk_i) begin
if(!rst_i) MIE<=32'b0;
else
begin
if(MIE_EN) MIE<=DIN;
end
end


//MIP-----------------------------------------------------------------------------------------------------------------------------------------------
reg [31:0] MIP;
always@(posedge clk_i) begin
if(!rst_i) MIP<=32'b0;
else
begin
if(intrp) MIP<= `MIP_EXT_INT;
else if(MIP_EN)MIP<=DIN;
end
end



//MSTATUS----------------------------------------------------------------------------------------------------------------------------------------------
reg [31:0] MSTATUS;
always @(posedge clk_i) begin
   if (!rst_i) begin
        MSTATUS <= 32'b0;
   end      
   else begin
   if (excep == 1'b1 || interrupt) begin
    MSTATUS[`SR_MPIE_R] <= MSTATUS[`SR_MIE_R];
    MSTATUS[`SR_SPIE_R] <= MSTATUS[`SR_SIE_R];
    MSTATUS[`SR_UPIE_R] <= MSTATUS[`SR_UIE_R];
    MSTATUS[`SR_MIE_R] <= 1'b0;
    MSTATUS[`SR_MPP_R] <= MPRIV;
    end    
    else if (MRET) begin
            MSTATUS[`SR_MIE_R] <= MSTATUS[`SR_MPIE_R];
            MSTATUS[`SR_SIE_R] <= MSTATUS[`SR_SPIE_R];
            MSTATUS[`SR_UIE_R] <= MSTATUS[`SR_UPIE_R];
    end
    else if(MSTATUS_EN) MSTATUS <= DIN;
end
end

//--------------------------------------------------------------------------------------------------------------------------------------------------

always @(posedge clk_i) begin
   if (!rst_i == 1'b1) begin
      MPRIV <= 2'b11;
   end else begin
      if (excep == 1'b1 || interrupt) begin
         MPRIV <= `PRIV_MACHINE;
      end else if (MRET) begin
         MPRIV <= MSTATUS[`SR_MPP_R];
      end
   end
end




//-------------------------------------------------------------------------------------------------------------------------------------------------------------------
assign interrupt = (|(MIP & MIE) & MSTATUS[`SR_MIE_R]);


//MEPC--------------------------------------------------------------------------------------------------------------------------------------
reg[31:0] MEPC;
always@(posedge clk_i) begin
if(!rst_i)MEPC<=32'b0;
else
    begin
        if(excep == 1'b1 || interrupt) begin
            if((opcode_opcode_i & `INST_WFI_MASK) == `INST_WFI)MEPC<=opcode_pc_i+4;
            else MEPC<=opcode_pc_i;
        end
        else if(MEPC_EN) MEPC<=DIN;      
    end
end

//MSCRATCH-----------------------------------------------------------------------------------------------------------------------------------------
reg [31:0] MSCRATCH;
always@(posedge clk_i) begin
if(!rst_i) MSCRATCH<=32'b0;
else
begin
if(MSCRATCH_EN) MSCRATCH<=DIN;
end
end

//MTVEC-------------------------------------------------------------------------------------------------------------------------------------------------
reg [31:0] MTVEC;
always@(posedge clk_i) begin
if(!rst_i) MTVEC<=32'b0;
else
begin
if(MTVEC_EN) MTVEC<=DIN;
end
end

//MCYCLE-----------------------------------------------------------------------------------------------------------------------------------------------------
reg [31:0] MCYCLE;
always@(posedge clk_i) begin
if(!rst_i) MCYCLE<=32'b0;
else
begin
MCYCLE <= MCYCLE + 1;
end
end

//EN--------------------------------------------------------------------------------------------------------------------------------------------------------------
reg writeback_squash;
always@(*) begin

    writeback_squash=1'b1;
      writeback_idx_o=5'b0;
      MSTATUS_EN = 1'b0;
      MIE_EN= 1'b0;
      MIP_EN=1'b0;
      MEPC_EN=1'b0;
      MCAUSE_EN=1'b0;
      MSCRATCH_EN=1'b0;
      MTVEC_EN=1'b0;
      writeback_value_o=32'b0;
    if(opcode_valid_i && (opcode_instr_i[`ENUM_INST_CSRRW] | opcode_instr_i[`ENUM_INST_CSRRS] | 
         opcode_instr_i[`ENUM_INST_CSRRC] | opcode_instr_i[`ENUM_INST_CSRRWI] | 
         opcode_instr_i[`ENUM_INST_CSRRSI] | opcode_instr_i[`ENUM_INST_CSRRCI])&& stall_o!=1'b1)//--
    begin
         writeback_idx_o=opcode_rd_idx_i;
         if(opcode_rd_idx_i==1'b0)writeback_squash=1'b1;
         else writeback_squash=1'b0;
         case (opcode_opcode_i[31:20]) 
            `CSR_MSTATUS: begin
              MSTATUS_EN = 1'b1;
              MIE_EN= 1'b0;
              MIP_EN=1'b0;
              MEPC_EN=1'b0;
              MCAUSE_EN=1'b0;
              MSCRATCH_EN=1'b0;
              MTVEC_EN=1'b0;
              writeback_value_o=MSTATUS;
              end
              `CSR_MIE: begin
              MSTATUS_EN = 1'b0;
              MIE_EN= 1'b1;
              MIP_EN=1'b0;
              MEPC_EN=1'b0;
              MCAUSE_EN=1'b0;
              MSCRATCH_EN=1'b0;
              MTVEC_EN=1'b0;
              writeback_value_o=MIE;
              end
              `CSR_MIP: begin
              MSTATUS_EN = 1'b0;
              MIE_EN= 1'b0;
              MIP_EN=1'b1;
              MEPC_EN=1'b0;
              MCAUSE_EN=1'b0;
              MSCRATCH_EN=1'b0;
              MTVEC_EN=1'b0;
              writeback_value_o=MIP;
              end
              `CSR_MTVEC: begin
              MSTATUS_EN = 1'b0;
              MIE_EN= 1'b0;
              MIP_EN=1'b0;
              MEPC_EN=1'b0;
              MCAUSE_EN=1'b0;
              MSCRATCH_EN=1'b0;
              MTVEC_EN=1'b1;
              writeback_value_o=MTVEC;
              end
              `CSR_MEPC: begin
              MSTATUS_EN = 1'b0;
              MIE_EN= 1'b0;
              MIP_EN=1'b0;
              MEPC_EN=1'b1;
              MCAUSE_EN=1'b0;
              MSCRATCH_EN=1'b0;
              MTVEC_EN=1'b0;
              writeback_value_o=MEPC;
              end
              `CSR_MCAUSE: begin
              MSTATUS_EN = 1'b0;
              MIE_EN= 1'b0;
              MIP_EN=1'b0;
              MEPC_EN=1'b0;
              MCAUSE_EN=1'b1;
              MSCRATCH_EN=1'b0;
              MTVEC_EN=1'b0;
              writeback_value_o=MCAUSE;
              end
              `CSR_MSCRATCH: begin
              MSTATUS_EN = 1'b0;
              MIE_EN= 1'b0;
              MIP_EN=1'b0;
              MEPC_EN=1'b0;
              MCAUSE_EN=1'b0;
              MSCRATCH_EN=1'b1;
              MTVEC_EN=1'b0;
              writeback_value_o=MSCRATCH;
              end
              default: begin
              MSTATUS_EN = 1'b0;
              MIE_EN= 1'b0;
              MIP_EN=1'b0;
              MEPC_EN=1'b0;
              MCAUSE_EN=1'b0;
              MSCRATCH_EN=1'b0;
              MTVEC_EN=1'b0;
              writeback_value_o=32'b0;
              end
         endcase
    end
    else
    begin
      writeback_squash=1'b1;
      writeback_idx_o=5'b0;
      MSTATUS_EN = 1'b0;
      MIE_EN= 1'b0;
      MIP_EN=1'b0;
      MEPC_EN=1'b0;
      MCAUSE_EN=1'b0;
      MSCRATCH_EN=1'b0;
      MTVEC_EN=1'b0;
      writeback_value_o=32'b0;
      end 
end

//DIN--------------------------------------------------------------------------------------------------------------------------------------
always@(*) begin
    if(opcode_valid_i) begin
	     DIN=32'b0;
        if(opcode_instr_i[`ENUM_INST_CSRRW]) begin
            DIN=opcode_ra_operand_i;
        end
        else if(opcode_instr_i[`ENUM_INST_CSRRWI]) begin
            DIN={27'b0,opcode_opcode_i[19:15]};
        end
        else
        begin
          case (opcode_opcode_i[31:20]) 
            `CSR_MSTATUS: begin
                if(opcode_instr_i[`ENUM_INST_CSRRS]) begin
                 DIN=opcode_ra_operand_i|MSTATUS;
                end
                else if(opcode_instr_i[`ENUM_INST_CSRRC]) begin
                 DIN=~opcode_ra_operand_i&MSTATUS;
                end
                else if(opcode_instr_i[`ENUM_INST_CSRRSI]) begin
                 DIN={27'b0,opcode_opcode_i[19:15]}|MSTATUS;
                end
                else if(opcode_instr_i[`ENUM_INST_CSRRCI]) begin
                 DIN={27'h7ffffff,~opcode_opcode_i[19:15]}&MSTATUS;
                end
                else DIN=32'b0;
             end
            `CSR_MIE: begin
                if(opcode_instr_i[`ENUM_INST_CSRRS]) begin
                 DIN=opcode_ra_operand_i|MIE;
                end
                else if(opcode_instr_i[`ENUM_INST_CSRRC]) begin
                 DIN=~opcode_ra_operand_i&MIE;
                end
                else if(opcode_instr_i[`ENUM_INST_CSRRSI]) begin
                 DIN={27'b0,opcode_opcode_i[19:15]}|MIE;
                end
                else if(opcode_instr_i[`ENUM_INST_CSRRCI]) begin
                 DIN={27'h7ffffff,~opcode_opcode_i[19:15]}&MIE;
                end
                else DIN=32'b0; 
             end
            `CSR_MIP: begin
                if(opcode_instr_i[`ENUM_INST_CSRRS]) begin
                 DIN=opcode_ra_operand_i|MIP;
                end
                else if(opcode_instr_i[`ENUM_INST_CSRRC]) begin
                 DIN=~opcode_ra_operand_i&MIP;
                end
                else if(opcode_instr_i[`ENUM_INST_CSRRSI]) begin
                 DIN={27'b0,opcode_opcode_i[19:15]}|MIP;
                end
                else if(opcode_instr_i[`ENUM_INST_CSRRCI]) begin
                 DIN={27'h7ffffff,~opcode_opcode_i[19:15]}&MIP;
                end
                else DIN=32'b0;
             end
            `CSR_MTVEC: begin
                if(opcode_instr_i[`ENUM_INST_CSRRS]) begin
                 DIN=opcode_ra_operand_i|MTVEC;
                end
                else if(opcode_instr_i[`ENUM_INST_CSRRC]) begin
                 DIN=~opcode_ra_operand_i&MTVEC;
                end
                else if(opcode_instr_i[`ENUM_INST_CSRRSI]) begin
                 DIN={27'b0,opcode_opcode_i[19:15]}|MTVEC;
                end
                else if(opcode_instr_i[`ENUM_INST_CSRRCI]) begin
                 DIN={27'h7ffffff,~opcode_opcode_i[19:15]}&MTVEC;
                end
                else DIN=32'b0;
             end
            `CSR_MEPC: begin
                if(opcode_instr_i[`ENUM_INST_CSRRS]) begin
                 DIN=opcode_ra_operand_i|MEPC;
                end
                else if(opcode_instr_i[`ENUM_INST_CSRRC]) begin
                 DIN=~opcode_ra_operand_i&MEPC;
                end
                else if(opcode_instr_i[`ENUM_INST_CSRRSI]) begin
                 DIN={27'b0,opcode_opcode_i[19:15]}|MEPC;
                end
                else if(opcode_instr_i[`ENUM_INST_CSRRCI]) begin
                 DIN={27'h7ffffff,~opcode_opcode_i[19:15]}&MEPC;
                end
                else DIN=32'b0;
             end
            `CSR_MCAUSE: begin
                if(opcode_instr_i[`ENUM_INST_CSRRS]) begin
                 DIN=opcode_ra_operand_i|MCAUSE;
                end
                else if(opcode_instr_i[`ENUM_INST_CSRRC]) begin
                 DIN=~opcode_ra_operand_i&MCAUSE;
                end
                else if(opcode_instr_i[`ENUM_INST_CSRRSI]) begin
                 DIN={27'b0,opcode_opcode_i[19:15]}|MCAUSE;
                end
                else if(opcode_instr_i[`ENUM_INST_CSRRCI]) begin
                 DIN={27'h7ffffff,~opcode_opcode_i[19:15]}&MCAUSE;
                end
                else DIN=32'b0;
             end
            `CSR_MSCRATCH: begin
                if(opcode_instr_i[`ENUM_INST_CSRRS]) begin
                 DIN=opcode_ra_operand_i|MSCRATCH;
                end
                else if(opcode_instr_i[`ENUM_INST_CSRRC]) begin
                 DIN=~opcode_ra_operand_i&MSCRATCH;
                end
                else if(opcode_instr_i[`ENUM_INST_CSRRSI]) begin
                 DIN={27'b0,opcode_opcode_i[19:15]}|MSCRATCH;
                end
                else if(opcode_instr_i[`ENUM_INST_CSRRCI]) begin
                 DIN={27'h7ffffff,~opcode_opcode_i[19:15]}&MSCRATCH;
                end
                else DIN=32'b0;
             end
            default: begin
                DIN=32'b0;
            end
         endcase
        end
    end
    else DIN=32'b0;
end


//pc----------------------------------------------------------------------------------------------------------------------------------------
always@(*)begin
    if(MRET) branch_csr_pc_o=MEPC;
    else if(MTVEC[0]==1'b0 && MTVEC[1]==1'b0)branch_csr_pc_o={MTVEC[31:2],2'b0};
    else if(interrupt) branch_csr_pc_o={MTVEC[31:2],2'b0}+4*MCAUSE;
    else branch_csr_pc_o={MTVEC[31:2],2'b0};
end

//stall_o-------------------------------------------------------------------------------------------------------------------------------------
reg [1:0] curr_state, next_state;
reg squash_stall;
always@(posedge clk_i) begin
if(!rst_i) curr_state<=2'b0;
else curr_state<=next_state;
end

always@(*) begin
next_state=2'b0;
        stall_o=1'b0;
        squash_stall=1'b1;
        branch_csr_request_o=1'b1;
case(curr_state)
    2'b0: begin
        if(MRET)begin
        next_state=2'b0;
        stall_o=1'b0;
        squash_stall=1'b1;
        branch_csr_request_o=1'b1;
        end
        else if((intrp == 1'b1 &&  MSTATUS[`SR_MIE_R])|| excep ==1'b1) begin//----
        next_state=2'b1;
        stall_o=1'b1;
        squash_stall=1'b1;
        branch_csr_request_o=1'b0;
        end
        else if(opcode_opcode_i & `INST_WFI_MASK == `INST_WFI)begin
        next_state=2'b11;
        stall_o=1'b1;
        squash_stall=1'b1;
        branch_csr_request_o=1'b0;
        end
        else begin
        next_state=2'b0;
        stall_o=1'b0;
        squash_stall=1'b0;
        branch_csr_request_o=1'b0;
        end
     end
     2'b1: begin
        next_state=2'b10;
        stall_o=1'b1;
        squash_stall=1'b1;
        branch_csr_request_o=1'b0;
     end
     2'b10: begin
        next_state=2'b0;
        stall_o=1'b0;
        squash_stall=1'b1;
        branch_csr_request_o=1'b1;
     end
     2'b11: begin
       if(intrp == 1'b1 || excep ==1'b1) begin
        next_state=2'b1;
        stall_o=1'b1;
        squash_stall=1'b1;
        branch_csr_request_o=1'b0;
        end
        else begin
        next_state=2'b11;
        stall_o=1'b1;
        squash_stall=1'b1;
        branch_csr_request_o=1'b0;
        end
     end
     default:begin
       next_state=2'b0;
       stall_o=1'b0;
       squash_stall=1'b0;
       branch_csr_request_o=1'b0;
     end
endcase
end

assign writeback_squash_o = (writeback_squash|squash_stall);

endmodule



















