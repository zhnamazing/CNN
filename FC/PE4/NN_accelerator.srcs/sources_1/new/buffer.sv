`timescale 1ns / 1ps

module buffer #(parameter DATA_WIDTH = 8, Q_DEPTH_BITS = 5) (
    input clk,
    input rst,
    input [DATA_WIDTH-1:0] write_data,
    input wrtEn,
    input rdEn,
    
    output logic [DATA_WIDTH-1:0] read_data,
    output logic valid,  
    output logic empty,
    output logic full
); 

    localparam Q_DEPTH    = 1 << Q_DEPTH_BITS; 
    
    reg  [Q_DEPTH_BITS-1:0]   front; 
    reg  [Q_DEPTH_BITS-1:0]   rear;
    reg  [DATA_WIDTH - 1: 0]  queue [0:Q_DEPTH-1];
    reg  [Q_DEPTH_BITS:0]     current_size;
    wire bare   = (current_size == 0); 
    wire filled = (current_size == Q_DEPTH); 
    integer i; 

//--------------Code Starts Here----------------------- 
always @ (posedge clk) begin
    if (!rst) 
    begin
          front        <= 0; 
          rear         <= 0; 
          current_size <= 0; 
          
          for(integer i = 0; i< 2**Q_DEPTH_BITS;i=i+1)
            queue[i] <= 0;
    end 
    else  
    begin 
        if(bare & wrtEn & rdEn) begin 
            queue [rear]  <= queue [rear];
            rear          <= rear;
            front         <= front;
            current_size  <= 0; 
        end 
        else begin 
            queue [rear]  <= (wrtEn & ~filled)? write_data : queue [rear];
            rear          <= (wrtEn & ~filled)? (rear == (Q_DEPTH -1))? 0 : 
                                (rear + 1) : rear;
            front         <= (rdEn & ~bare)? (front == (Q_DEPTH -1))? 0 : 
                                (front + 1) : front;
            current_size  <= (wrtEn & ~rdEn & ~filled)? (current_size + 1) : 
                                (~wrtEn & rdEn & ~bare)? 
                                (current_size -1): current_size; 
        end 
    end
end

//----------------------------------------------------
// Drive the outputs
//----------------------------------------------------
assign  read_data   = (wrtEn & rdEn & bare)? write_data : queue [front];
assign  valid       = (((wrtEn & rdEn & bare) | (rdEn & ~bare))& rst)? 1 : 0;
assign  empty       = (~rst | bare |(~wrtEn & rdEn & (current_size == 1)));
assign  full        = (rst & filled);

     
endmodule