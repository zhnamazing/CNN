`timescale 1ns / 1ps

module myconfig(
    input clk,
    input rst,
    input [26:0]in_config,
    input v_config,
    input init,
    input wen,
    output logic phase,
    output logic [7:0]inrng,
    output logic [7:0]outrng,
    output logic [4:0]cut_type,
    output logic [2:0]post_type,
    output logic [3:0]pool,
    output logic [2:0]co
);

    logic [26:0]config_reg;
    logic [8:0]num;

    always@(posedge clk)
    begin
        if(!rst)
        begin
            config_reg <= 0;
        end
        else if(v_config)
        begin
            config_reg <= in_config;
        end
    end

    assign inrng = init ? config_reg[0+:8] : 0;
    assign outrng = init ? config_reg[8+:8] : 0;
    assign cut_type = init ? config_reg[16+:5] : 0;
    assign post_type = init ? config_reg[21+:3] : 0;
    assign co = init ? config_reg[24+:3] : 0;

    always@(*)
    begin
        case (post_type)
            3'd0: pool = 0;
            3'd1: pool = 0;
            3'd2: pool = 3;
            3'd3: pool = 3;
            3'd4: pool = 8;
            3'd5: pool = 8;
            3'd6: pool = 15;
            3'd7: pool = 15;
            default: pool = 0;
        endcase
    end

    always@(posedge clk)
    begin
        if(!rst)
        begin
            num <= 0;
        end
        else if(init)
        begin
            if(num == (inrng + 1))
                num <= 0;
            else
                num <= wen ? num + 1 : num;
        end
    end 

    assign phase = init ? (num == (inrng + 1)) : 0;

endmodule