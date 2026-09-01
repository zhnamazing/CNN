`timescale 1ns / 1ps

module bram #(parameter DATA_WIDTH = 16,DEPTH = 25,ADDR_WIDTH = 8)(
	input clk,
    input rst,
    input en,
    input we,   //0:read 1:write
    input [ADDR_WIDTH-1:0] addr1,
    input [ADDR_WIDTH-1:0] addr2,
    input [ADDR_WIDTH-1:0] addr3,
    input [DATA_WIDTH-1:0] din,
    output logic [DATA_WIDTH-1:0] dout1 = 0,
    output logic [DATA_WIDTH-1:0] dout2 = 0,
    output logic [DATA_WIDTH-1:0] dout3 = 0
); 

    logic [DATA_WIDTH-1:0] ram [DEPTH-1:0] = '{default:0};

//read
    always@(posedge clk)
    begin
        if((~we)&en)
            dout1 <= ram[addr1];
        else
            dout1 <= 0;
    end
    
    always@(posedge clk)
    begin
        if((~we)&en)
            dout2 <= ram[addr2];
        else
            dout2 <= 0;
    end
    
    always@(posedge clk)
    begin
        if((~we)&en)
            dout3 <= ram[addr3];
        else
            dout3 <= 0;
    end
          
//write
    always@(posedge clk)
    begin
      if(we && en)
          ram[addr1] <= din;
    end
           
endmodule