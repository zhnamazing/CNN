`timescale 1ns / 1ps

module axon(
    input clk,
    input rst,
    input phase,
    input [7:0]inrng,
    input signed [15:0]din,
    input [7:0]waddr,
    input wen,
    input d2a,
    output logic signed [15:0]data_ad,
    output logic a2d
);
    
    logic pp;
    logic [7:0]raddr;
    logic [7:0]count;
    
    logic [2:0]state;
    localparam [2:0]Idle = 3'b001,Read = 3'b010,Wait = 3'b100;

    ppbuffer #(16,8) data_ram(clk,wen,d2a,pp,waddr,raddr,din,data_ad);

    
    //pingpong pointer
    always@(posedge clk)
    begin
        if(!rst)
            pp <= 0;
        else
            pp <= phase ? ~ pp : pp;
    end
    
    //read FSM
    always@(posedge clk)
    begin
        if(!rst)
        begin
            state <=Idle;
            raddr <= 0;
            count <= 0;
            a2d <= 0;
        end
        else
            case(state)
                Idle:
                begin
                    if(d2a)
                    begin
                        state <= Read;
                        a2d <= 1;
                        raddr <= raddr + 1;
                    end
                    else
                    begin
                        state <= Idle;
                    end
                end
                
                Read:
                begin
                    if(count == inrng)
                    begin
                        state <= Wait;
                    end
                    else
                    begin
                        state <= Read;
                        raddr <= raddr + 1;
                        count <= count + 1;
                    end
                end
                
                Wait:
                begin
                    if(d2a)
                        state <= Wait;
                    else
                    begin
                        state <= Idle;
                        raddr <= 0;
                        count <= 0;
                        a2d <= 0;
                    end
                end
                
                default:
                    state <= Idle;
            endcase
    end
         
endmodule