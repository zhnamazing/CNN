`timescale 1ns / 1ps

module bram #(parameter DATA_WIDTH = 16,DEPTH = 25,ADDR_WIDTH = 8)(
	input clk,
    input rst,
    input en,
    input we,   //0:read 1:write
    input [ADDR_WIDTH-1:0] addr,
    input [DATA_WIDTH-1:0] din,
    output logic [DATA_WIDTH-1:0] dout
); 

    logic [DATA_WIDTH-1:0] ram [DEPTH-1:0];

//read
    always@(posedge clk)
    begin
        if(!rst)
            dout <= 0;
        else if((~we)&en)
            dout <= ram[addr];
    end
          
//write
    always@(posedge clk)
    begin
        if(!rst)
          begin
            for(integer i=0;i<DEPTH;i=i+1)
              ram[i] <= 0;
          end
        else if(we&en)
            ram[addr] <= din;
    end
           
endmodule