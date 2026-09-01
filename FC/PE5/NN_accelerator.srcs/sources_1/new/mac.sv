`timescale 1ns / 1ps

module mac #(inrng = 32)(
    input clk,
    input rst,
    input a2d,
    input signed [15:0]din,
    input signed [15:0]in_weight,
    input [5:0] raddrw,
    input v_weight,
    (*use_dsp="yes"*)output logic signed [39:0]dout
);
    
    logic signed [15:0]din_reg;
    logic a2d_reg;
    logic a2d_reg2;
    logic signed [15:0]weight;
    logic signed [15:0]weight_reg;
    logic [7:0]count;
    logic [5:0]addrw;
    logic [5:0]waddrw;
    logic [5:0]raddrw_reg;
    logic [5:0]raddrw_reg2;
    logic en_weight;
    logic signed [31:0]mul_o;

    logic [2:0]state;
    localparam [2:0]Idle = 3'b001,Calc = 3'b010,Outp = 3'b100;
    
    assign addrw = v_weight ? waddrw : raddrw;
    assign en_weight = v_weight ? 1 : a2d;

    always@(posedge clk)
    begin
        if(!rst)
        begin
            waddrw <= 0;
        end
        else begin
          if(v_weight)
            begin
              if(waddrw < inrng - 1)
                waddrw <= waddrw + 1;
              else
                waddrw <= waddrw;
           end
        end
    end

    always@(posedge clk)
      begin
        if(!rst)
          begin
            din_reg <= 0;
            a2d_reg <= 0;
            a2d_reg2 <= 0;
            weight_reg <= 0;
            raddrw_reg <= 0;
            raddrw_reg2 <= 0;
          end
        else begin
            din_reg <= din;
            a2d_reg <= a2d;
            a2d_reg2 <= a2d_reg;
            weight_reg <= weight;
            raddrw_reg <=raddrw;
            raddrw_reg2 <=raddrw_reg;
        end
      end
 
//    bram #(16,32,5) weight_ram(
//      .clk(clk),    // input wire clka
//      .rst(rst),
//      .en(en_weight),      // input wire ena
//      .we(v_weight),      // input wire [0 : 0] wea
//      .addr(addrw),  // input wire [10 : 0] addra
//      .din(in_weight),    // input wire [7 : 0] dina
//      .dout(weight)  // output wire [7 : 0] douta
//    );
    bram_mac weight_ram (
      .clka(clk),    // input wire clka
      .ena(en_weight),      // input wire ena
      .wea(v_weight),      // input wire [0 : 0] wea
      .addra(addrw),  // input wire [4 : 0] addra
      .dina(in_weight),    // input wire [15 : 0] dina
      .douta(weight)  // output wire [15 : 0] douta
    );
    
    always@(posedge clk)
    begin
        if(!rst)
        begin
            state <= Idle;
            dout <= 0;
//            finish <= 0;
        end
        else
            case(state)
                Idle:
                begin
                    if(a2d_reg)
                    begin
                        state <= Calc;
                    end
                    else
                    begin
                        state <= Idle;
                    end 
                    
                    dout <= dout;              
                end
            
                Calc:
                begin
                    if(!a2d)
                    begin
                        state <= Outp;
                    end
                    else
                    begin
                        state <= Calc;
                    end
                        dout <= dout + weight_reg*din_reg;
                end
            
                Outp:
                begin
                    state <= Idle;
                    dout <= 0;
//                    finish <= 0;      
                end
                
                default:
                    state <= Idle;
            endcase         
    end 
endmodule