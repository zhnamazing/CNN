`timescale 1ns / 1ps

module mac(
    input clk,
    input rst,
    input a2d,
    input [7:0]inrng,
    input signed [15:0]din,
    input [2:0]group,
    input signed [15:0]in_weight,
    input v_weight,
    (*use_dsp="yes"*)output logic signed [39:0]dout,
    output logic finish
);
    
    logic signed [15:0]din_reg;
    logic signed [15:0]weight;
    logic [7:0]axon;
    logic [7:0]count;
    logic [10:0]addrw;
    logic [10:0]waddrw;
    logic [10:0]raddrw;
    logic en_weight;
    logic signed [31:0]mul_o;

    logic [2:0]state;
    localparam [2:0]Idle = 3'b001,Calc = 3'b010,Outp = 3'b100;
    
    assign raddrw = (axon << 3) + group;
    assign addrw = v_weight ? waddrw : raddrw;
    assign en_weight = v_weight ? 1 : a2d;

    always@(posedge clk)
    begin
        if(!rst)
        begin
            waddrw <= 0;
        end
        else
        begin
            waddrw <= v_weight ? waddrw + 1 : waddrw;
        end
    end
 
    blk_16_256_8 weight_ram(
      .clka(clk),    // input wire clka
      .ena(en_weight),      // input wire ena
      .wea(v_weight),      // input wire [0 : 0] wea
      .addra(addrw),  // input wire [10 : 0] addra
      .dina(in_weight),    // input wire [7 : 0] dina
      .douta(weight)  // output wire [7 : 0] douta
    );
    
    
LARBM_new_top booth(
        .a_i(din_reg),
        .b_i(weight),
        .rst(rst),
        .clk(clk),
        .mul_o(mul_o)
    );
    always@(posedge clk)
    begin
        if(!rst)
        begin
            state <= Idle;
            din_reg <= 0;
            axon <= 0;
            count <= 0;
            dout <= 0;
            finish <= 0;
        end
        else
            case(state)
                Idle:
                begin
                    if(a2d)
                    begin
                        state <= Calc;
                        din_reg <= din;
                        axon <= axon + 1;
                    end
                    else
                    begin
                        state <= Idle;
                    end               
                end
            
                Calc:
                begin
                    if(count == inrng)
                    begin
                        state <= Outp;
                    end
                    else
                    begin
                        state <= Calc;
                        din_reg <= din;
                        axon <= axon + 1;
                        count <= count + 1;
                    end
                    if((weight != 0) && (din_reg != 0))
                    begin
                        dout <= dout + weight*din_reg;
                    end
                    else
                    begin
                        dout <= dout;
                    end
                end
            
                Outp:
                begin
                    if(a2d)
                    begin
                        state <= Outp;
                        finish <= 1;
                    end
                    else
                    begin
                        state <= Idle;
                        din_reg <= 0;
                        axon <= 0;
                        count <= 0;
                        dout <= 0;
                        finish <= 0;
                    end                   
                end
                
                default:
                    state <= Idle;
            endcase         
    end
    
endmodule