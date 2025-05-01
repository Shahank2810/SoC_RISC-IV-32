//Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2020.2 (win64) Build 3064766 Wed Nov 18 09:12:45 MST 2020
//Date        : Tue Apr  8 06:26:03 2025
//Host        : HPVICTUS running 64-bit major release  (build 9200)
//Command     : generate_target design_2_wrapper.bd
//Design      : design_2_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module design_2_wrapper
   (clk_in1_0,
    gpio_input_i_0,
    gpio_output_enable_o_0,
    gpio_output_o_0,
    inport_araddr_i_0,
    inport_arready_o_0,
    inport_arvalid_i_0,
    inport_awaddr_i_0,
    inport_awready_o_0,
    inport_awvalid_i_0,
    inport_bready_i_0,
    inport_bresp_o_0,
    inport_bvalid_o_0,
    inport_rdata_o_0,
    inport_rready_i_0,
    inport_rresp_o_0,
    inport_rvalid_o_0,
    inport_wdata_i_0,
    inport_wready_o_0,
    inport_wstrb_i_0,
    inport_wvalid_i_0,
    reset_vector_i_0,
    rst_cpu_i_0,
    rst_i_0,
    spi_clk_o_0,
    spi_cs_o_0,
    spi_miso_i_0,
    spi_mosi_o_0,
    uart_rxd_o_0,
    uart_txd_i_0);
  input clk_in1_0;
  input [31:0]gpio_input_i_0;
  output [31:0]gpio_output_enable_o_0;
  output [31:0]gpio_output_o_0;
  input [31:0]inport_araddr_i_0;
  output inport_arready_o_0;
  input inport_arvalid_i_0;
  input [31:0]inport_awaddr_i_0;
  output inport_awready_o_0;
  input inport_awvalid_i_0;
  input inport_bready_i_0;
  output [1:0]inport_bresp_o_0;
  output inport_bvalid_o_0;
  output [31:0]inport_rdata_o_0;
  input inport_rready_i_0;
  output [1:0]inport_rresp_o_0;
  output inport_rvalid_o_0;
  input [31:0]inport_wdata_i_0;
  output inport_wready_o_0;
  input [3:0]inport_wstrb_i_0;
  input inport_wvalid_i_0;
  input [31:0]reset_vector_i_0;
  input rst_cpu_i_0;
  input rst_i_0;
  output spi_clk_o_0;
  output spi_cs_o_0;
  input spi_miso_i_0;
  output spi_mosi_o_0;
  output uart_rxd_o_0;
  input uart_txd_i_0;

  wire clk_in1_0;
  wire [31:0]gpio_input_i_0;
  wire [31:0]gpio_output_enable_o_0;
  wire [31:0]gpio_output_o_0;
  wire [31:0]inport_araddr_i_0;
  wire inport_arready_o_0;
  wire inport_arvalid_i_0;
  wire [31:0]inport_awaddr_i_0;
  wire inport_awready_o_0;
  wire inport_awvalid_i_0;
  wire inport_bready_i_0;
  wire [1:0]inport_bresp_o_0;
  wire inport_bvalid_o_0;
  wire [31:0]inport_rdata_o_0;
  wire inport_rready_i_0;
  wire [1:0]inport_rresp_o_0;
  wire inport_rvalid_o_0;
  wire [31:0]inport_wdata_i_0;
  wire inport_wready_o_0;
  wire [3:0]inport_wstrb_i_0;
  wire inport_wvalid_i_0;
  wire [31:0]reset_vector_i_0;
  wire rst_cpu_i_0;
  wire rst_i_0;
  wire spi_clk_o_0;
  wire spi_cs_o_0;
  wire spi_miso_i_0;
  wire spi_mosi_o_0;
  wire uart_rxd_o_0;
  wire uart_txd_i_0;

  design_2 design_2_i
       (.clk_in1_0(clk_in1_0),
        .gpio_input_i_0(gpio_input_i_0),
        .gpio_output_enable_o_0(gpio_output_enable_o_0),
        .gpio_output_o_0(gpio_output_o_0),
        .inport_araddr_i_0(inport_araddr_i_0),
        .inport_arready_o_0(inport_arready_o_0),
        .inport_arvalid_i_0(inport_arvalid_i_0),
        .inport_awaddr_i_0(inport_awaddr_i_0),
        .inport_awready_o_0(inport_awready_o_0),
        .inport_awvalid_i_0(inport_awvalid_i_0),
        .inport_bready_i_0(inport_bready_i_0),
        .inport_bresp_o_0(inport_bresp_o_0),
        .inport_bvalid_o_0(inport_bvalid_o_0),
        .inport_rdata_o_0(inport_rdata_o_0),
        .inport_rready_i_0(inport_rready_i_0),
        .inport_rresp_o_0(inport_rresp_o_0),
        .inport_rvalid_o_0(inport_rvalid_o_0),
        .inport_wdata_i_0(inport_wdata_i_0),
        .inport_wready_o_0(inport_wready_o_0),
        .inport_wstrb_i_0(inport_wstrb_i_0),
        .inport_wvalid_i_0(inport_wvalid_i_0),
        .reset_vector_i_0(reset_vector_i_0),
        .rst_cpu_i_0(rst_cpu_i_0),
        .rst_i_0(rst_i_0),
        .spi_clk_o_0(spi_clk_o_0),
        .spi_cs_o_0(spi_cs_o_0),
        .spi_miso_i_0(spi_miso_i_0),
        .spi_mosi_o_0(spi_mosi_o_0),
        .uart_rxd_o_0(uart_rxd_o_0),
        .uart_txd_i_0(uart_txd_i_0));
endmodule
