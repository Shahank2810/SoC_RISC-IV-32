module axi_bridge (
    input  wire        aclk,
    input  wire        aresetn,

    // Master Interface (From riscv_soc)
    input  wire        mem_awvalid_i,
    input  wire [31:0] mem_awaddr_o,
    input  wire [7:0]  mem_awlen_o,
    input  wire [2:0]  mem_awsize_o,
    input  wire [1:0]  mem_awburst_o,
    input  wire [3:0]  mem_awid_o,
    input  wire        mem_awlock_o,
    input  wire [2:0]  mem_awprot_o,
    output wire        mem_awready_i,

    input  wire        mem_wvalid_o,
    input  wire [31:0] mem_wdata_o,
    input  wire [3:0]  mem_wstrb_o,
    input  wire        mem_wlast_o,
    output wire        mem_wready_i,

    output wire        mem_bvalid_i,
    output wire [1:0]  mem_bresp_i,
    output wire [3:0]  mem_bid_i,
    input  wire        mem_bready_o,

    input  wire        mem_arvalid_o,
    input  wire [31:0] mem_araddr_o,
    input  wire [7:0]  mem_arlen_o,
    input  wire [2:0]  mem_arsize_o,
    input  wire [1:0]  mem_arburst_o,
    input  wire [3:0]  mem_arid_o,
    input  wire        mem_arlock_o,
    input  wire [2:0]  mem_arprot_o,
    output wire        mem_arready_i,

    output wire        mem_rvalid_i,
    output wire [31:0] mem_rdata_i,
    output wire [1:0]  mem_rresp_i,
    output wire [3:0]  mem_rid_i,
    output wire        mem_rlast_i,
    input  wire        mem_rready_o,

    // Slave Interface (To AXI Interconnect S00_AXI)
    output wire        s_axi_awvalid,
    output wire [31:0] s_axi_awaddr,
    output wire [7:0]  s_axi_awlen,
    output wire [2:0]  s_axi_awsize,
    output wire [1:0]  s_axi_awburst,
    output wire [3:0]  s_axi_awid,
    output wire        s_axi_awlock,
    output wire [2:0]  s_axi_awprot,
    input  wire        s_axi_awready,

    output wire        s_axi_wvalid,
    output wire [31:0] s_axi_wdata,
    output wire [3:0]  s_axi_wstrb,
    output wire        s_axi_wlast,
    input  wire        s_axi_wready,

    input  wire        s_axi_bvalid,
    input  wire [1:0]  s_axi_bresp,
    input  wire [3:0]  s_axi_bid,
    output wire        s_axi_bready,

    output wire        s_axi_arvalid,
    output wire [31:0] s_axi_araddr,
    output wire [7:0]  s_axi_arlen,
    output wire [2:0]  s_axi_arsize,
    output wire [1:0]  s_axi_arburst,
    output wire [3:0]  s_axi_arid,
    output wire        s_axi_arlock,
    output wire [2:0]  s_axi_arprot,
    input  wire        s_axi_arready,

    input  wire        s_axi_rvalid,
    input  wire [31:0] s_axi_rdata,
    input  wire [1:0]  s_axi_rresp,
    input  wire [3:0]  s_axi_rid,
    input  wire        s_axi_rlast,
    output wire        s_axi_rready
);

    // AW Channel
    assign s_axi_awvalid = mem_awvalid_i;
    assign s_axi_awaddr  = mem_awaddr_o;
    assign s_axi_awlen   = mem_awlen_o;
    assign s_axi_awsize  = mem_awsize_o;
    assign s_axi_awburst = mem_awburst_o;
    assign s_axi_awid    = mem_awid_o;
    assign s_axi_awlock  = mem_awlock_o;
    assign s_axi_awprot  = mem_awprot_o;
    assign mem_awready_i = s_axi_awready;

    // W Channel
    assign s_axi_wvalid  = mem_wvalid_o;
    assign s_axi_wdata   = mem_wdata_o;
    assign s_axi_wstrb   = mem_wstrb_o;
    assign s_axi_wlast   = mem_wlast_o;
    assign mem_wready_i  = s_axi_wready;

    // B Channel
    assign mem_bvalid_i  = s_axi_bvalid;
    assign mem_bresp_i   = s_axi_bresp;
    assign mem_bid_i     = s_axi_bid;
    assign s_axi_bready  = mem_bready_o;

    // AR Channel
    assign s_axi_arvalid = mem_arvalid_o;
    assign s_axi_araddr  = mem_araddr_o;
    assign s_axi_arlen   = mem_arlen_o;
    assign s_axi_arsize  = mem_arsize_o;
    assign s_axi_arburst = mem_arburst_o;
    assign s_axi_arid    = mem_arid_o;
    assign s_axi_arlock  = mem_arlock_o;
    assign s_axi_arprot  = mem_arprot_o;
    assign mem_arready_i = s_axi_arready;

    // R Channel
    assign mem_rvalid_i  = s_axi_rvalid;
    assign mem_rdata_i   = s_axi_rdata;
    assign mem_rresp_i   = s_axi_rresp;
    assign mem_rid_i     = s_axi_rid;
    assign mem_rlast_i   = s_axi_rlast;
    assign s_axi_rready  = mem_rready_o;

endmodule
