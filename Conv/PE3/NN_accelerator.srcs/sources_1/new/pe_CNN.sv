`timescale 1ns / 1ps
//core+(pool-1)×stride=(个数-1)×行数
//行数=pool×stride
//sobel行数=行数+2
//换尺寸需要修改：sobel中行数 dendrite中WH初值（三处）
module pe_CNN #(parameter FLIT_WIDTH = 48, CREDIT_WIDTH = 3, ID_BITS = 6,NUM_OF_CORE = 32,core_size = 3,colrng = 5, pool = 3,stride = 1,cut_type = 0,core_channel=32)(
    input clk, 
    //input clk2x,
    input rst,
    input start,
    input [FLIT_WIDTH-1:0]from_router_flit,
    input v_from_router,
    input [(ID_BITS - 1):0] router_ID,
    input ren_out,

    output logic[FLIT_WIDTH-1:0]to_router_flit,
    output logic v_to_router,
    output logic data_req,
  
    input [CREDIT_WIDTH - 1:0]credit_r
    //output logic [30:0] count
//    output logic [30:0] countz
);
    
    localparam [2:0] row = pool*stride;
    localparam [8:0] size = row*colrng*core_channel;
    localparam [2:0] group =(((core_size-stride)%row)==0)? ((core_size-stride)/row) + 2 :((core_size-stride)/row+1) + 2;
    localparam [2:0] row_sobel = row + 2;
    
    logic phase;
    logic locked;
    logic reset;

    logic signed [15:0]data_ad;
    logic a2d;

    logic signed [39:0]data_ds;
    logic d2a;
    logic d2s;
    logic wri;

    logic signed [15:0]from_core_data;
    logic [10:0]from_core_addr;
    logic s2d;
    logic v_from_core;
    logic empty;

    logic signed [15:0]din;
    logic [10:0]waddr;
    logic [9:0]raddr;
    logic wen;
    logic [15:0]dram;
    logic [6:0]v1;
    logic signed [15:0]in_bias;
    logic signed [15:0]pool_weight;
    logic signed [39:0]pool_bias;
    logic v_bias;
    
    logic [36:0]in_config;
    logic v_config;
    logic init;
    logic r2s;
    logic [2:0]channel;
    logic [2:0] core_num;
    logic [2:0]rowslice;
    logic [(group-1)*size-1:0]mask;
    logic v_pool_weight;
    logic v_pool_bias;
    
    assign reset = rst;

    axon_CNN  #(NUM_OF_CORE, core_size, colrng, size, stride, row_sobel, group, row, core_channel,pool)inst_axon (
        .clk               (clk),
        //.clk2x             (clk2x),
        .rst               (reset),
        .start             (start),
        .din               (din),
        .waddr             (waddr),
        .wen               (wen),
        .raddr             (raddr),
        .d2a               (d2a),
        .data_ad           (data_ad),
        .a2d               (a2d),
        .mask              (mask),
        .phase             (phase),
//        .countz            (countz),
        .wri               (wri),
        .data_req          (data_req)
    );

    dendrite_CNN  #(NUM_OF_CORE, core_size, colrng, size, stride, row, group, core_channel,pool)inst_dendrite (
        .clk               (clk),
        //.clk2x             (clk2x),
        .rst               (reset),
        .phase             (phase),
        .data_ad           (data_ad),
        .a2d               (a2d),
        .s2d               (s2d),
        .dram              (dram),
        .v1                (v1),
        .mask              (mask),
        .raddr             (raddr),
        .data_ds           (data_ds),
        .d2a               (d2a),
        .d2s               (d2s),    
        //.count             (count),
        .wri               (wri)
    );

    soma_CNN  #(NUM_OF_CORE, core_size, colrng, pool ,cut_type)inst_soma (
        .clk               (clk),
        //.clk2x             (clk2x),
        .rst               (reset),
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

    Multi_NI  # (
        .FLIT_WIDTH(FLIT_WIDTH),
        .CREDIT_WIDTH(CREDIT_WIDTH),
        .ID_BITS(ID_BITS)
    )
    inst_NI (
        .router_ID         (router_ID),
        .clk               (clk),
        .rst               (reset),
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
        .v_bias            (v_bias),
        .init              (init),
        .to_router_flit    (to_router_flit),
        .v_to_router       (v_to_router),
        .credit_r          (credit_r),
        .r2s               (r2s),
        .ren_out           (ren_out)
    );
    
//       clk_wiz_0 instance_name
//   (
//    // Clock out ports
//    .clk_out1(clk2x),     // output clk4x
//    // Status and control signals
//    .reset(1'b0), // input reset
//    .locked(locked),       // output locked
//   // Clock in ports
//    .clk_in1(clk)
//   );      // input clk_in1

endmodule