`timescale 1ns / 1ps

module pe #(parameter FLIT_WIDTH = 48, CREDIT_WIDTH = 3, ID_BITS = 6,num_of_core=10,inrng = 32)(
    input clk, 
    input rst,
    input ren_out,
    input start,
    input [FLIT_WIDTH-1:0]from_router_flit,
    input v_from_router,

    output logic[FLIT_WIDTH-1:0]to_router_flit,
    output logic v_to_router,
    output data_req,
    //output logic [30:0] count,
  
    input [CREDIT_WIDTH - 1:0]credit_r,
    input [ID_BITS - 1:0]router_id
);
    logic signed [15:0]data_ad;
    logic a2d;
    logic phase;

    logic signed [39:0]data_ds;
    logic d2a;
    logic d2s;

    logic signed [15:0]from_core_data;
    logic [10:0]from_core_addr;
    logic s2d;
    logic v_from_core;

    logic signed [15:0]din;
    logic [5:0] waddr;
    logic [5:0] raddr;
    logic wen;
    logic [15:0]dram;
    logic [8:0]v1;
    logic signed [39:0]in_bias;
    logic v_bias;
    logic init;
    logic r2s;
    logic [inrng-1:0] mask;
    logic signal;
    logic [22:0] weight_info;
    logic [22:0] data_info;


    axon #(inrng)inst_axon (
        .clk               (clk),
        .rst               (rst),
        .phase_reg         (phase),
        .din               (din),
        .waddr             (waddr),
        .wen               (wen),
        .d2a               (d2a),
        .data_ad           (data_ad),
        .a2d               (a2d),
        .mask              (mask),
        .raddr             (raddr),
        .start             (start),
        .data_req          (data_req),
        .signal            (signal)
    );

    dendrite #(inrng,num_of_core) inst_dendrite(
        .clk               (clk),
        .rst               (rst),
        //.count             (count),
        .phase             (phase),
        .data_ad           (data_ad),
        .a2d               (a2d),
        .s2d               (s2d),
//        .dram              (dram),
//        .v1                (v1),
        .weight_info       (weight_info),
        .data_ds           (data_ds),
        .d2a               (d2a),
        .d2s               (d2s),
        .mask              (mask),
        .raddr             (raddr),
        .signal            (signal)
    );

    soma #(num_of_core)inst_soma (
        .clk               (clk),
        .rst               (rst),
        .data_ds           (data_ds),
        .d2s               (d2s),
        .r2s               (r2s),
        .in_bias           (in_bias),
        .v_bias            (v_bias),
        .phase             (phase),
        .from_core_data    (from_core_data),
        .from_core_addr    (from_core_addr),
        .s2d               (s2d),
        .v_from_core       (v_from_core)
    );

    NI  # (
        .FLIT_WIDTH(FLIT_WIDTH),
        .CREDIT_WIDTH(CREDIT_WIDTH),
        .ID_BITS(ID_BITS)
    )
    inst_NI (
        .clk               (clk),
        .rst               (rst),
        .from_core_data    (from_core_data),
        .from_core_addr    (from_core_addr),
        .v_from_core       (v_from_core),
        .from_router_flit  (from_router_flit),
        .v_from_router     (v_from_router),
        .din               (din),
        .waddr             (waddr),
        .wen               (wen),
//        .dram              (dram),
//        .v1                (v1),
//        .data_info         (data_info),
        .weight_info       (weight_info),
        .in_bias           (in_bias),
        .v_bias            (v_bias),
        .init              (init),
        .to_router_flit    (to_router_flit),
        .v_to_router       (v_to_router),
        .credit_r          (credit_r),
        .r2s               (r2s),
        .ren_out           (ren_out)
    );

endmodule