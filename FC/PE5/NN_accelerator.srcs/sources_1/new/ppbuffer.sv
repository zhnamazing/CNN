`timescale 1ns / 1ps

module ppbuffer #(parameter DATA_WIDTH = 16,ADDR_WIDTH = 5)(
    input clk,
    input wen,
    input rst,
    input d2a,
    input pp,
    input [ADDR_WIDTH - 1:0] waddr,
    input [ADDR_WIDTH - 1:0] raddr,
    input [DATA_WIDTH - 1:0] din,
    output logic [DATA_WIDTH - 1:0] dout
);
    
    logic en0;
    logic en1;
    logic [ADDR_WIDTH - 1:0] addr0;
    logic [ADDR_WIDTH - 1:0] addr1;
    logic [DATA_WIDTH - 1:0] dout0;
    logic [DATA_WIDTH - 1:0] dout1;
    
    bram #(16,32,5) ram0(
      .clk(clk),    // input wire clka
      .rst(rst),
      .en(en0),      // input wire ena
      .we(~pp),      // input wire [0 : 0] wea
      .addr(addr0),  // input wire [7 : 0] addra
      .din(din),    // input wire [7 : 0] dina
      .dout(dout0)  // output wire [7 : 0] douta
    );
    bram #(16,32,5) ram1(
      .clk(clk),    // input wire clka
      .rst(rst),
      .en(en1),      // input wire ena
      .we(pp),      // input wire [0 : 0] wea
      .addr(addr1),  // input wire [7 : 0] addra
      .din(din),    // input wire [7 : 0] dina
      .dout(dout1)  // output wire [7 : 0] douta
    );
    
    assign en0 = pp ? d2a : wen;
    assign en1 = pp ? wen : d2a;
    assign addr0 = pp ? raddr : waddr;
    assign addr1 = pp ? waddr : raddr;
    assign dout = pp ? dout0 : dout1;
    
endmodule