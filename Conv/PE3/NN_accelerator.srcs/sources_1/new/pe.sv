`timescale 1ns / 1ps

module pe #(parameter FLIT_WIDTH = 48, CREDIT_WIDTH = 3, ID_BITS = 6)(
    input clk, 
    input rst,
    input [FLIT_WIDTH-1:0]from_router_flit,
    input v_from_router,

    output logic[FLIT_WIDTH-1:0]to_router_flit,
    output logic v_to_router,
  
    input [CREDIT_WIDTH - 1:0]credit_r,
    input [ID_BITS - 1:0]router_id
);
   
    logic phase;
    logic [7:0]inrng;
    logic [7:0]outrng;
    logic [4:0]cut_type;
    logic [2:0]post_type;
    logic [3:0]pool;
    logic [2:0]co;

    logic signed [15:0]data_ad;
    logic a2d;

    logic signed [39:0]data_ds;
    logic [7:0]neuron;
    logic d2a;
    logic d2s;

    logic signed [15:0]from_core_data;
    logic [7:0]from_core_addr;
    logic s2d;
    logic v_from_core;

    logic signed [15:0]din;
    logic [7:0]waddr;
    logic wen;
    logic [15:0]dram;
    logic [31:0]v1;
    logic signed [39:0]in_bias;
    logic signed [7:0]in_flut;
    logic v_bias;
    logic v_flut;
    logic [26:0]in_config;
    logic v_config;
    logic init;
    logic r2s;

    myconfig  inst_myconfig (
        .clk               (clk),
        .rst               (rst),
        .in_config         (in_config),
        .v_config          (v_config),
        .init              (init),
        .wen               (wen),
        .phase             (phase),
        .inrng             (inrng),
        .outrng            (outrng),
        .cut_type          (cut_type),
        .post_type         (post_type),
        .pool              (pool),
        .co                (co)
    );

    axon  inst_axon (
        .clk               (clk),
        .rst               (rst),
        .phase             (phase),
        .inrng             (inrng),
        .din               (din),
        .waddr             (waddr),
        .wen               (wen),
        .d2a               (d2a),
        .data_ad           (data_ad),
        .a2d               (a2d)
    );

    dendrite  inst_dendrite (
        .clk               (clk),
        .rst               (rst),
        .phase             (phase),
        .inrng             (inrng),
        .outrng            (outrng),
        .data_ad           (data_ad),
        .a2d               (a2d),
        .s2d               (s2d),
        .dram              (dram),
        .v1                (v1),
        .data_ds           (data_ds),
        .neuron            (neuron),
        .d2a               (d2a),
        .d2s               (d2s)
    );

    soma  inst_soma (
        .clk               (clk),
        .rst               (rst),
        .data_ds           (data_ds),
        .neuron            (neuron),
        .cut_type          (cut_type),
        .post_type         (post_type),
        .d2s               (d2s),
        .r2s               (r2s),
        .in_bias           (in_bias),
        .v_bias            (v_bias),
        .from_core_data    (from_core_data),
        .from_core_addr    (from_core_addr),
        .s2d               (s2d),
        .v_from_core       (v_from_core)
    );

    Multi_NI  # (
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
        .dram              (dram),
        .v1                (v1),
        .in_bias           (in_bias),
        .in_flut           (in_flut),
        .v_bias            (v_bias),
        .v_flut            (v_flut),
        .in_config         (in_config),
        .v_config          (v_config),
        .init              (init),
        .to_router_flit    (to_router_flit),
        .v_to_router       (v_to_router),
        .credit_r          (credit_r),
        .r2s               (r2s),
        .router_id         (router_id)
    );

endmodule