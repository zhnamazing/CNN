`timescale 1ns / 1ps
module for_test(
    input clk,
    //input clk2x,
    input rst,
    input signed [14:0] count,
    input start,
    
    input [12:0] raddr_in, 
    input v_from_router_in,
    input ren_out,
    
    output logic signed [15:0] dataout,
    output logic [10:0] addrout,
    output logic [15:0] coreout,
    output logic v_to_router
    //output logic [30:0] count2
//    output logic [30:0] countz
);
    parameter FLIT_WIDTH = 48;
    parameter CREDIT_WIDTH = 6;
    parameter ID_BITS = 6;
    parameter ROW_BITS = 3;
    parameter COL_BITS = 3;
    
    wire [(ID_BITS - 1):0] router_ID = 16'b0000000000000001;
    wire [CREDIT_WIDTH - 1:0]credit_r = 0;
    
    logic [12:0] raddr;
    logic v_from_router;
    logic ena;
    logic [12:0] raddr_p;
    logic v_from_router_p;
    logic data_req;
    
    assign ena = (!start)||data_req;
    
    always@(posedge clk)
      begin
        if(!rst)
          begin
            raddr_p <= 0;
            v_from_router_p <= 0;
          end
        else begin
          if(data_req && start && (raddr_p < 1568))
            begin
              raddr_p <= raddr_p + 1;
              v_from_router_p <= 1;
            end
          else begin
              raddr_p <= raddr_p;
              v_from_router_p <= 0;
            end
          end
        end
    
    logic [FLIT_WIDTH-1:0]from_router_flit;
    logic[FLIT_WIDTH-1:0]to_router_flit;
    
    assign raddr = start ? (raddr_p+6497) : raddr_in;
    assign v_from_router = start ? v_from_router_p : v_from_router_in;


    pe_CNN  inst_pe (
        .clk               (clk),
       // .clk2x             (clk2x),
        .rst               (rst),
        .start             (start),
        .from_router_flit  (from_router_flit),
        .v_from_router     (v_from_router),
        .to_router_flit    (to_router_flit),
        .v_to_router       (v_to_router),
        .credit_r          (credit_r),
        .router_ID         (router_ID),
        .ren_out           (ren_out),
        .data_req          (data_req)
        //.count             (count2)
//        .countz            (countz)
    );
    
    blk_mem_gen_0 bram_test (
  .clka(clk),    // input wire clka
  .ena (ena),      // input wire ena
  .wea(1'b0),      // input wire [0 : 0] wea
  .addra(raddr),  // input wire [9 : 0] addra
  .dina(),    // input wire [47 : 0] dina
  .douta(from_router_flit)  // output wire [47 : 0] douta
);
    assign coreout = to_router_flit[45:30];
    assign dataout = to_router_flit[15:0];
    assign addrout = to_router_flit[26:16];
    

endmodule