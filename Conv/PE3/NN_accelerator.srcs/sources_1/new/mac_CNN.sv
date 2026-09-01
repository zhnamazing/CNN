`timescale 1ns / 1ps
module mac_CNN(
    input clk,
    //input clk2x,
    input rst,
    input a2d,
    input signed [15:0]din,
    input [8:0]raddrw,
    input signed [15:0]in_weight,
    input v_weight,
    (*use_dsp="yes"*)output logic signed [39:0]dout
);
    logic start_reg;
    logic signed [15:0]weight;
    logic signed [15:0]weight_reg;
    logic a2d_reg;
    logic [8:0]addrw;
    logic [8:0]waddrw;
    logic en_weight;
    
    logic [2:0]state;
    localparam [2:0]Idle = 3'b001,Calc = 3'b010,Outp = 3'b100;
    wire [31:0] result;
    
    assign addrw = v_weight ? waddrw : raddrw;
    assign en_weight = v_weight ? 1 : a2d;//axon的请响应信号到来，才会使能读出权重

    always@(posedge clk)
    begin
        if(!rst)
          begin
            waddrw <= 0;
          end
        else begin
            waddrw <= v_weight ? waddrw + 1 : waddrw;
          end
    end

//bram_weight u_bram_weight (
//  .clka(clk),    // input wire clka
//  .ena(v_weight),      // input wire ena
//  .wea(v_weight),      // input wire [0 : 0] wea
//  .addra(waddrw),  // input wire [4 : 0] addra
//  .dina(in_weight),    // input wire [15 : 0] dina
//  .clkb(clk2x),    // input wire clkb
//  .enb(a2d),      // input wire enb
//  .addrb(raddrw),  // input wire [4 : 0] addrb
//  .doutb(weight)  // output wire [15 : 0] doutb
//);

bram_weight your_instance_name (
  .clka(clk),    // input wire clka
  .ena(en_weight),      // input wire ena
  .wea(v_weight),      // input wire [0 : 0] wea
  .addra(addrw),  // input wire [7 : 0] addra
  .dina(in_weight),    // input wire [15 : 0] dina
  .douta(weight)  // output wire [15 : 0] douta
);

   always@(posedge clk)
     begin
       if(!rst)
         begin
           weight_reg <= 0;
           a2d_reg <= 1'b0;
         end
       else begin
         weight_reg <= weight;
         a2d_reg <= a2d;
       end
     end
    
    always@(posedge clk)
    begin
        if(!rst)
        begin
            state <= Idle;
            dout <= 0;
        end
        else begin
            case(state)
                Idle:
                begin
                    if(a2d_reg)
                        state <= Calc;
                    else
                        state <= Idle;   
                        
                    dout<=dout;         
                end
            
                Calc:
                begin
                    dout <= dout + din*weight_reg;
                    if(!a2d_reg)
                        state <= Outp;
                    else
                        state <= Calc;
                end
            
                Outp:
                begin
                    state <= Idle;
                    dout <= 0;//清零准备下次累加                 
                end
                default: begin
                    state <= Idle;
                    dout<=dout;
                end
            endcase 
          end        
    end
endmodule