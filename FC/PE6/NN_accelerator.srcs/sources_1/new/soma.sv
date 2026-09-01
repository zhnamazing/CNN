`timescale 1ns / 1ps
module soma#(num_of_core = 64)(
    input clk,
    input rst,
    input signed [39:0]data_ds, 
    input signed [39:0]in_bias,
    input v_bias,
    input d2s,
    input r2s,
    input phase,
    output logic signed [15:0]from_core_data,
    output logic [10:0]from_core_addr,
    output logic s2d,
    output logic v_from_core
);
    logic [7:0]neuron_reg1;
    logic signed [40:0]dacc;
    logic signed [39:0]data_ds_reg1;
    logic signed [15:0]dcut;
    logic signed [15:0]dlut;
    logic signed [15:0]dbin;
    logic d2s_reg1;
    logic d2s_reg2;
    logic valid1;
    logic valid2;
    logic empty1;
    logic empty2;
    logic full1;
    logic full2;
    logic signed [39:0]bias;
    logic [7:0]addrb;
    logic [7:0]waddrb;
    logic [5:0] cnt;
    logic [5:0] cnt_reg;
    logic [5:0] cnt_reg2;
    logic en_bias;
    logic en_flut;

    assign v_from_core = d2s_reg2;
    assign s2d = (~d2s) & phase;
    assign en_bias = v_bias ? 1 : d2s;
    assign addrb = v_bias ? waddrb : cnt;
    
  always@(posedge clk)
    begin
        if(!rst)
        begin
            waddrb <= 0;
        end
        else
        begin
            waddrb <= v_bias ? waddrb + 1 : waddrb;
        end
    end

//    bram #(40,64,6) bias_ram(
//      .clk(clk),    // input wire clka
//      .rst(rst),
//      .en(en_bias),      // input wire ena
//      .we(v_bias),      // input wire [0 : 0] wea
//      .addr(addrb),  // input wire [7 : 0] addra
//      .din(in_bias),    // input wire [39 : 0] dina
//      .dout(bias)  // output wire [39 : 0] douta
//    );
    bram_soma your_instance_name (
      .clka(clk),    // input wire clka
      .ena(en_bias),      // input wire ena
      .wea(v_bias),      // input wire [0 : 0] wea
      .addra(addrb),  // input wire [5 : 0] addra
      .dina(in_bias),    // input wire [39 : 0] dina
      .douta(bias)  // output wire [39 : 0] douta
    );

    //generate fifo
//    buffer #(16,5) data_buffer(clk,rst,dlut,d2s_reg2,r2s,from_core_data,valid1,empty1,full1);
//    buffer #(6,5) addr_buffer(clk,rst,cnt_reg2,d2s_reg2,r2s,from_core_addr,valid2,empty2,full2);

    assign from_core_data = dlut;
    assign from_core_addr = cnt_reg2;
    
    always@(posedge clk)
    begin
        if(!rst)
        begin
            d2s_reg1 <= 0;
            d2s_reg2 <= 0;
            data_ds_reg1 <= 0;
            cnt_reg <= 0;
            cnt_reg2 <= 0;
        end
        else
        begin
            d2s_reg1 <= d2s;
            d2s_reg2 <= d2s_reg1;
            data_ds_reg1 <= data_ds;
            cnt_reg <= cnt;
            cnt_reg2 <= cnt_reg;
        end    
    end
    
    always@(posedge clk)
    begin
        if(!rst)
            cnt <= 0;
        else begin
            if(d2s)
              begin
                if(cnt < num_of_core-1)
                  cnt <= cnt + 1;
                else
                  cnt <= 0;
              end
            else begin
                cnt <= cnt;
            end
        end    
    end
    
    assign dacc = d2s_reg1 ? (data_ds_reg1 + bias) : 0;
    
    always@(posedge clk)
      begin
        if((dacc[39:15] == 25'b0_0000_0000_0000_0000_0000_0000)||(dacc[39:15] == 25'b1_1111_1111_1111_1111_1111_1111))
           dcut <= {dacc[39],dacc[0+:15]};
        else
           dcut <= dacc[39] ? 16'b1000_0000_0000_0000 : 16'b0111_1111_1111_1111;
        end
        
    assign dlut = (dcut>0)? {{4{dcut[11]}},dcut[11:0]} : 0;  
    
endmodule