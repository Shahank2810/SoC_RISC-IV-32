// Includes
`include "riscv_defs.v" // Assuming this contains INST_*, CSR_*, etc.

module riscv_lsu
(
    // Inputs (Same as original)
    input clk_i,
    input rst_i, //active high
    input opcode_valid_i,
    input [ 57:0] opcode_instr_i,
    input [ 31:0] opcode_opcode_i,
    input [ 31:0] opcode_pc_i,
    input [ 4:0] opcode_rd_idx_i,
    input [ 4:0] opcode_ra_idx_i,
    input [ 4:0] opcode_rb_idx_i,
    input [ 31:0] opcode_ra_operand_i,
    input [ 31:0] opcode_rb_operand_i,
    input [ 31:0] mem_data_rd_i,
    input mem_accept_i,
    input mem_ack_i,
    input mem_error_i,
    input [ 10:0] mem_resp_tag_i,

    // Outputs (Same as original)
    output reg [31:0] mem_addr_o,
    output reg [31:0] mem_data_wr_o,
    output reg        mem_rd_o,
    output reg [3:0]  mem_wr_o,
    output reg        mem_cacheable_o,
    output reg [10:0] mem_req_tag_o,
    output reg        mem_invalidate_o,
    output reg        mem_flush_o,
    // *** NOTE: Making writeback outputs combinational wires now ***
    // *** This reflects their typical behavior based on mem_resp_tag_i ***
    output wire [4:0]  writeback_idx_o,
    output wire       writeback_squash_o,
    output wire [31:0] writeback_value_o,
    // *** Fault outputs become combinational wires ***
    output wire        fault_store_o,
    output wire        fault_load_o,
    output wire        fault_misaligned_store_o,
    output wire        fault_misaligned_load_o,
    output wire        fault_page_store_o,
    output wire        fault_page_load_o,
    output wire [31:0] fault_addr_o,
    // *** Stall output is now driven by FSM state ***
    output wire        stall_o
);

// Parameters
parameter MEM_CACHE_ADDR_MIN = 32'h00000000;
parameter MEM_CACHE_ADDR_MAX = 32'h7fffffff;

// --- FSM State Definition ---
parameter FSM_IDLE        = 2'b00;
parameter FSM_WAIT_ACCEPT = 2'b01; // Request issued, waiting for memory to accept
parameter FSM_WAIT_ACK    = 2'b10; // Request accepted, waiting for memory ack

reg [1:0] current_state, next_state;


// Intermediate registers & wires (Keep original calculation logic)
wire load_byte_req, load_half_word_req, load_word_req, store_byte_req, store_half_word_req, store_word_req, load_instr, store_instr, load_signed_instr;

reg [31:0]  mem_addr_temp;         // Combinational result
reg         mem_unaligned_temp;    // Combinational result
reg [31:0]  mem_data_temp;         // Combinational result
wire        mem_rd_temp;           // Combinational result
reg [3:0]   mem_wr_temp;           // Combinational result
wire        mem_flush_temp;        // Combinational result
wire        mem_invalidate_temp;   // Combinational result

wire        mem_unaligned;         // Combinational result

wire cache_flush, cache_writeback, cache_invalidate; // Combinational result

// Internal signals for load operation (Keep original logic)
wire [1:0]  addr_lsb_tag;
wire        load_word_tag;
wire        load_byte_tag;
wire        load_half_tag;
wire        load_signed_tag;
reg [31:0]  wb_result_reg; // Combinational result

// --- Combinational Decoding & Calculation (Keep original logic) ---

// Decoding the opcode
assign load_byte_req = ((opcode_opcode_i & `INST_LB_MASK) == `INST_LB) || ((opcode_opcode_i & `INST_LBU_MASK) == `INST_LBU);
assign load_half_word_req = ((opcode_opcode_i & `INST_LH_MASK) == `INST_LH) || ((opcode_opcode_i & `INST_LHU_MASK) == `INST_LHU);
assign load_word_req = ((opcode_opcode_i & `INST_LW_MASK) == `INST_LW) || ((opcode_opcode_i & `INST_LWU_MASK) == `INST_LWU); // Assume LWU defined if used
assign store_byte_req = ((opcode_opcode_i & `INST_SB_MASK) == `INST_SB);
assign store_half_word_req = ((opcode_opcode_i & `INST_SH_MASK) == `INST_SH);
assign store_word_req = ((opcode_opcode_i & `INST_SW_MASK) == `INST_SW);

assign load_instr = load_byte_req || load_half_word_req || load_word_req;
assign store_instr =  store_byte_req || store_half_word_req || store_word_req;
// Recalculate load_signed_instr based ONLY on signed opcodes
assign load_signed_instr = ((opcode_opcode_i & `INST_LB_MASK) == `INST_LB) ||
                           ((opcode_opcode_i & `INST_LH_MASK) == `INST_LH) ||
                           ((opcode_opcode_i & `INST_LW_MASK) == `INST_LW);

assign cache_flush      = opcode_valid_i && ((opcode_opcode_i & `INST_CSRRW_MASK) == `INST_CSRRW) && (opcode_opcode_i[31:20] == `CSR_DFLUSH);
assign cache_writeback  = opcode_valid_i && ((opcode_opcode_i & `INST_CSRRW_MASK) == `INST_CSRRW) && (opcode_opcode_i[31:20] == `CSR_DWRITEBACK); // Keep decode, even if unused later
assign cache_invalidate = opcode_valid_i && ((opcode_opcode_i & `INST_CSRRW_MASK) == `INST_CSRRW) && (opcode_opcode_i[31:20] == `CSR_DINVALIDATE);
wire   cache_op         = cache_flush || cache_invalidate; // Is it a cache op we handle?


// Computing output memory address
always @ (*) begin
   mem_addr_temp = 32'b0; // Default
    if (opcode_valid_i) begin
        if (cache_op) // Check generic cache op first
            mem_addr_temp = opcode_ra_operand_i; // Assume address from rs1 for cache ops
        else if (load_instr)
            mem_addr_temp = opcode_ra_operand_i + {{20{opcode_opcode_i[31]}}, opcode_opcode_i[31:20]}; // I-imm
        else if (store_instr)
            mem_addr_temp = opcode_ra_operand_i + {{20{opcode_opcode_i[31]}}, opcode_opcode_i[31:25], opcode_opcode_i[11:7]}; // S-imm
   end
end

// Computing memory unaligned signal
always @(*) begin
    mem_unaligned_temp = 1'b0; // Default
    if (opcode_valid_i) begin
        if (load_word_req || store_word_req)
            mem_unaligned_temp = (mem_addr_temp[1:0] != 2'b0);
        else if (load_half_word_req || store_half_word_req)
            mem_unaligned_temp = mem_addr_temp[0];
    end
end
// Final misalignment signal only matters if it's a memory access instruction
assign mem_unaligned = opcode_valid_i && (load_instr || store_instr) && mem_unaligned_temp;

// Computing mem_data_temp and mem_wr_temp (Store Data Formatting)
always @(*) begin
     mem_data_temp  = 32'b0;
     mem_wr_temp    = 4'b0;
    if (opcode_valid_i && store_instr && !mem_unaligned_temp) begin // Only format if valid store and aligned
        if (store_word_req) begin
            mem_data_temp  = opcode_rb_operand_i;
            mem_wr_temp    = 4'b1111;
        end else if (store_half_word_req) begin
            // Use shifting for potentially cleaner logic
            mem_data_temp  = opcode_rb_operand_i[15:0] << (mem_addr_temp[1] ? 16 : 0);
            mem_wr_temp    = mem_addr_temp[1] ? 4'b1100 : 4'b0011;
        end else if (store_byte_req) begin
            mem_data_temp  = opcode_rb_operand_i[7:0] << (mem_addr_temp[1:0] * 8);
            mem_wr_temp    = (1 << mem_addr_temp[1:0]); // More compact byte enable generation
        end
    end
end

// Temp signals for requests (based on calc results, before FSM/stall logic)
assign mem_rd_temp = opcode_valid_i && load_instr && !mem_unaligned_temp;
assign mem_flush_temp = cache_flush;
assign mem_invalidate_temp = cache_invalidate;
wire mem_wr_req_temp = |mem_wr_temp; // Is there any write byte enable set?

// Is this a valid operation for the LSU to potentially handle?
wire is_lsu_operation = opcode_valid_i && (load_instr || store_instr || cache_op);

// --- FSM Logic ---

// State Register
always @(posedge clk_i or negedge rst_i) begin
    if (!rst_i) begin
        current_state <= FSM_IDLE;
    end else begin
        current_state <= next_state;
    end
end

// Next State Logic (Combinational)
always @(*) begin
    next_state = current_state; // Default: remain in current state

    case (current_state)
        FSM_IDLE: begin
            // If valid LSU operation arrives AND it's NOT misaligned
            if (is_lsu_operation && !mem_unaligned) begin
                if (!mem_accept_i) begin
                    next_state = FSM_WAIT_ACCEPT; // Memory not ready, wait for accept
                end else begin
                    next_state = FSM_WAIT_ACK;    // Memory accepted, proceed to wait for ack
                end
            end
             // Ignore misaligned access or non-LSU ops, stay IDLE
        end

        FSM_WAIT_ACCEPT: begin
            // If memory accepts the pending request
            if (mem_accept_i) begin
                next_state = FSM_WAIT_ACK; // Move to wait for ack
            end
            // else stay in WAIT_ACCEPT, keep trying
        end

        FSM_WAIT_ACK: begin
            // If memory acknowledges completion (success or error)
            if (mem_ack_i) begin
                next_state = FSM_IDLE; // Operation complete, return to idle
            end
            // else stay in WAIT_ACK
        end

        default: next_state = FSM_IDLE;
    endcase

     // If a misaligned fault is detected combinationally, force back to IDLE immediately
     // This allows the pipeline control/CSR to handle the fault without waiting
     if (mem_unaligned) begin
        next_state = FSM_IDLE;
     end
end

// Stall Output (Combinational based on FSM state)
// Stall if the FSM is not IDLE OR if a misaligned access is detected this cycle
assign stall_o = (next_state != FSM_IDLE) || mem_unaligned;

// --- Registered Output Logic (Memory Interface) ---

// Drive memory interface based on FSM state and calculated values
always @(posedge clk_i or negedge rst_i) begin
    if (!rst_i) begin
        mem_addr_o       <= 32'b0;
        mem_data_wr_o    <= 32'b0;
        mem_rd_o         <= 1'b0;
        mem_wr_o         <= 4'b0;
        mem_cacheable_o  <= 1'b0;
        mem_req_tag_o    <= 11'b0;
        mem_invalidate_o <= 1'b0;
        mem_flush_o      <= 1'b0;
    end else begin
        // Default: De-assert requests, hold other values unless actively driving
        mem_rd_o         <= 1'b0;
        mem_wr_o         <= 4'b0;
        mem_invalidate_o <= 1'b0;
        mem_flush_o      <= 1'b0;

        // Actions based on *entering* a state or *being* in a state
        if (next_state == FSM_WAIT_ACCEPT && current_state == FSM_IDLE) begin
            // First cycle trying to issue request, but memory not ready
            mem_addr_o      <= mem_addr_temp;
            mem_data_wr_o   <= mem_data_temp;
            mem_rd_o        <= mem_rd_temp;       // Assert requests
            mem_wr_o        <= mem_wr_temp;
            mem_invalidate_o<= mem_invalidate_temp;
            mem_flush_o     <= mem_flush_temp;
            mem_cacheable_o <= (mem_addr_temp >= MEM_CACHE_ADDR_MIN && mem_addr_temp <= MEM_CACHE_ADDR_MAX) || cache_op;
            mem_req_tag_o   <= {load_signed_instr, load_word_req, load_half_word_req, load_byte_req, mem_addr_temp[1:0], opcode_rd_idx_i};
        end
        else if (current_state == FSM_WAIT_ACCEPT) begin
             // Holding in WAIT_ACCEPT, keep asserting request
            mem_addr_o      <= mem_addr_o; // Hold previous value (already set)
            mem_data_wr_o   <= mem_data_wr_o; // Hold previous value
            mem_rd_o        <= mem_rd_temp; // Keep asserting requests
            mem_wr_o        <= mem_wr_temp;
            mem_invalidate_o<= mem_invalidate_temp;
            mem_flush_o     <= mem_flush_temp;
            mem_cacheable_o <= mem_cacheable_o; // Hold previous value
            mem_req_tag_o   <= mem_req_tag_o;   // Hold previous value
        end
        else if (next_state == FSM_WAIT_ACK && current_state == FSM_IDLE) begin
             // Request accepted on first try
            mem_addr_o      <= mem_addr_temp;
            mem_data_wr_o   <= mem_data_temp;
            mem_rd_o        <= mem_rd_temp;       // Assert requests this cycle
            mem_wr_o        <= mem_wr_temp;
            mem_invalidate_o<= mem_invalidate_temp;
            mem_flush_o     <= mem_flush_temp;
            mem_cacheable_o <= (mem_addr_temp >= MEM_CACHE_ADDR_MIN && mem_addr_temp <= MEM_CACHE_ADDR_MAX) || cache_op;
            mem_req_tag_o   <= {load_signed_instr, load_word_req, load_half_word_req, load_byte_req, mem_addr_temp[1:0], opcode_rd_idx_i};
        end
        else if (next_state == FSM_WAIT_ACK && current_state == FSM_WAIT_ACCEPT) begin
             // Request accepted after waiting
             // Outputs were held in WAIT_ACCEPT, keep them for the cycle acceptance happens
            mem_addr_o      <= mem_addr_o;
            mem_data_wr_o   <= mem_data_wr_o;
            mem_rd_o        <= mem_rd_temp; // Assert request one last time on acceptance
            mem_wr_o        <= mem_wr_temp;
            mem_invalidate_o<= mem_invalidate_temp;
            mem_flush_o     <= mem_flush_temp;
            mem_cacheable_o <= mem_cacheable_o;
            mem_req_tag_o   <= mem_req_tag_o;
        end
        // Note: When *in* FSM_WAIT_ACK (current_state == FSM_WAIT_ACK), requests are de-asserted by default logic above.
        // Address/data/tag could optionally be held here if needed for debug/error, or cleared.

        else if (next_state == FSM_IDLE) begin // Returning to IDLE
             // Clear outputs explicitly when returning to idle
             mem_addr_o       <= 32'b0;
             mem_data_wr_o    <= 32'b0;
             mem_cacheable_o  <= 1'b0;
             mem_req_tag_o    <= 11'b0;
             // Requests already cleared by default
        end
    end
end


// --- Fault Output Generation (Combinational Wires) ---
// Combinational check for memory error ACK
wire fault_mem_error  = mem_ack_i & mem_error_i; // Error only valid with ACK

assign fault_misaligned_load_o  = mem_unaligned & load_instr;
assign fault_misaligned_store_o = mem_unaligned & store_instr;
// Fault only valid if ACK received AND it was for the correct instruction type
assign fault_load_o             = fault_mem_error & load_instr; // Assumes ACK relates to current load
assign fault_store_o            = fault_mem_error & store_instr;// Assumes ACK relates to current store

// Default page faults to 0
assign fault_page_store_o = 1'b0;
assign fault_page_load_o  = 1'b0;

// Report faulting address (combinational based on calculation)
assign fault_addr_o = ( (fault_mem_error & (load_instr | store_instr))) ? mem_addr_temp : 32'b0;

// --- Load Data Formatting & Writeback (Combinational Wires) ---

// Tag decoding (same as original)
assign addr_lsb_tag    = mem_resp_tag_i[6:5];
assign load_byte_tag   = mem_resp_tag_i[7];
assign load_half_tag   = mem_resp_tag_i[8];
assign load_word_tag   = mem_resp_tag_i[9];
assign load_signed_tag = mem_resp_tag_i[10];
wire [4:0] wb_idx_tag  = mem_resp_tag_i[4:0]; // Extracted Rd index from tag

// Combinational Load Data Formatting Logic (kept original, but removed fault address path)
always @ (*) begin
    wb_result_reg = 32'b0; // Default value
    // Handle responses ONLY if ACK is present and NO error occurred, AND target is not X0
    // Also ensure it was actually a load instruction using load_*_tag signals
    if (mem_ack_i && !mem_error_i && |wb_idx_tag) begin
        if (load_byte_tag) begin
            case (addr_lsb_tag) // Select correct byte
                2'b00: wb_result_reg = mem_data_rd_i[7:0];
                2'b01: wb_result_reg = mem_data_rd_i[15:8];
                2'b10: wb_result_reg = mem_data_rd_i[23:16];
                2'b11: wb_result_reg = mem_data_rd_i[31:24];
                default: wb_result_reg = 32'bx; // Should not happen
            endcase
            // Sign/Zero extend based on tag
            if (load_signed_tag) begin // LB
                wb_result_reg = {{24{wb_result_reg[7]}}, wb_result_reg[7:0]};
            end else begin // LBU
                wb_result_reg = {{24{1'b0}}, wb_result_reg[7:0]};
            end
        end else if (load_half_tag) begin
            case (addr_lsb_tag[1]) // Select correct half
                 1'b0: wb_result_reg = mem_data_rd_i[15:0];
                 1'b1: wb_result_reg = mem_data_rd_i[31:16];
                 default: wb_result_reg = 32'bx; // Should not happen
            endcase
             // Sign/Zero extend based on tag
            if (load_signed_tag) begin // LH
                 wb_result_reg = {{16{wb_result_reg[15]}}, wb_result_reg[15:0]};
            end else begin // LHU
                 wb_result_reg = {{16{1'b0}}, wb_result_reg[15:0]};
            end
        end else if (load_word_tag) begin // LW
            wb_result_reg = mem_data_rd_i;
        end
        // else: Not a recognized load type from tag, wb_result_reg remains 0
    end
end

// Final Writeback Outputs (Combinational)
// Writeback index is valid only if ACK is high, no error, and it was a load tag
assign writeback_idx_o = (mem_ack_i && !mem_error_i && (load_byte_tag || load_half_tag || load_word_tag)) ? wb_idx_tag : 5'b0;
// Writeback value is the formatted result under same conditions
assign writeback_value_o = (mem_ack_i && !mem_error_i && (load_byte_tag || load_half_tag || load_word_tag)) ? wb_result_reg : 32'b0;
// Squash if misaligned load detected OR if a memory error occurred on a load ACK
assign writeback_squash_o = (fault_misaligned_load_o | (fault_mem_error & load_instr))|| !mem_ack_i || !load_instr;


endmodule