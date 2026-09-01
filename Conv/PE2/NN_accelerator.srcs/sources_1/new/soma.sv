
`timescale 1ns / 1ps

module soma(
    input clk,
    input rst,
    input signed [39:0]data_ds,
    input [7:0]neuron, 
    input [4:0]cut_type,
    input [2:0]post_type,    
    input signed [39:0]in_bias,
    input v_bias,
    input d2s,
    input r2s,
    output logic signed [15:0]from_core_data,
    output logic [7:0]from_core_addr,
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
    logic valid1;
    logic valid2;
    logic empty1;
    logic empty2;
    logic full1;
    logic full2;
    logic signed [39:0]bias;
    logic [7:0]addrb;
    logic [7:0]waddrb;
    logic en_bias;
    logic en_flut;


   

    assign v_from_core = valid1 & valid2;
    assign s2d = (~d2s) & empty1 & empty2;
    assign en_bias = v_bias ? 1 : d2s;
    assign addrb = v_bias ? waddrb : neuron;
    
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

     blk_40_256 bias_ram(
      .clka(clk),    // input wire clka
      .ena(en_bias),      // input wire ena
      .wea(v_bias),      // input wire [0 : 0] wea
      .addra(addrb),  // input wire [7 : 0] addra
      .dina(in_bias),    // input wire [39 : 0] dina
      .douta(bias)  // output wire [39 : 0] douta
    );

    //generate fifo
    buffer #(16,5) data_buffer(clk,rst,dbin,d2s_reg1,r2s,from_core_data,valid1,empty1,full1);
    buffer #(8,5) addr_buffer(clk,rst,neuron_reg1,d2s_reg1,r2s,from_core_addr,valid2,empty2,full2);
    
    always@(posedge clk)
    begin
        if(!rst)
        begin
            d2s_reg1 <= 0;
            neuron_reg1 <= 0;
        end
        else
        begin
            d2s_reg1 <= d2s;
            neuron_reg1 <= neuron;
        end    
    end
    
    always@(posedge clk)
    begin
        if(!rst)
        begin
            data_ds_reg1 <= 0;
        end
        else
        begin
            data_ds_reg1 <= data_ds;
        end    
    end
    
    
    assign dacc = data_ds_reg1 + bias;
    //cut
    always@(*)
    begin
        case(cut_type)
            5'd0:
            begin
                if((dacc[40:15] == 26'b00_0000_0000_0000_0000_0000_0000)||(dacc[40:15] == 26'b11_1111_1111_1111_1111_1111_1111))
                    dcut = {dacc[40],dacc[0+:15]};
                else
                    dcut = dacc[40] ? 16'b1000_0000_0000_0000 : 16'b0111_1111_1111_1111;
            end

            5'd1:
            begin
                if((dacc[40:16] == 25'b0_0000_0000_0000_0000_0000_0000)||(dacc[40:16] == 25'b1_1111_1111_1111_1111_1111_1111))
                    dcut = {dacc[40],dacc[1+:15]};
                else
                    dcut = dacc[40] ? 16'b1000_0000_0000_0000 : 16'b0111_1111_1111_1111;
            end

            5'd2:
            begin
                if((dacc[40:17] == 24'b0000_0000_0000_0000_0000_0000)||(dacc[40:17] == 24'b1111_1111_1111_1111_1111_1111))
                   dcut = {dacc[40],dacc[2+:15]};
                else
                    dcut = dacc[40] ? 16'b1000_0000_0000_0000 : 16'b0111_1111_1111_1111;
            end

            5'd3:
            begin
                if((dacc[40:18] == 23'b000_0000_0000_0000_0000_0000)||(dacc[40:18] == 23'b111_1111_1111_1111_1111_1111))
                   dcut = {dacc[40],dacc[3+:15]};
                else
                    dcut = dacc[40] ? 16'b1000_0000_0000_0000 : 16'b0111_1111_1111_1111;
            end

            5'd4:
            begin
                if((dacc[40:19] == 22'b00_0000_0000_0000_0000_0000)||(dacc[40:19] == 22'b11_1111_1111_1111_1111_1111))
                   dcut = {dacc[40],dacc[4+:15]};
                else
                    dcut = dacc[40] ? 16'b1000_0000_0000_0000 : 16'b0111_1111_1111_1111;
            end

            5'd5:
            begin
                if((dacc[40:20] == 21'b0_0000_0000_0000_0000_0000)||(dacc[40:20] == 21'b1_1111_1111_1111_1111_1111))
                   dcut = {dacc[40],dacc[5+:15]};
                else
                    dcut = dacc[40] ? 16'b1000_0000_0000_0000 : 16'b0111_1111_1111_1111;
            end

            5'd6:
            begin
               if((dacc[40:21] == 20'b0000_0000_0000_0000_0000)||(dacc[40:21] == 20'b1111_1111_1111_1111_1111))
                   dcut = {dacc[40],dacc[6+:15]};
                else
                    dcut = dacc[40] ? 16'b1000_0000_0000_0000 : 16'b0111_1111_1111_1111;
            end
            
            5'd7:
            begin
                if((dacc[40:22] == 19'b000_0000_0000_0000_0000)||(dacc[40:22] == 19'b111_1111_1111_1111_1111))
                   dcut = {dacc[40],dacc[7+:15]};
                else
                    dcut = dacc[40] ? 16'b1000_0000_0000_0000 : 16'b0111_1111_1111_1111; 
            end

            5'd8:
            begin
                if((dacc[40:23] == 18'b00_0000_0000_0000_0000)||(dacc[40:23] == 18'b11_1111_1111_1111_1111))
                   dcut = {dacc[40],dacc[8+:15]};
                else
                    dcut = dacc[40] ? 16'b1000_0000_0000_0000 : 16'b0111_1111_1111_1111;
            end

            5'd9:
            begin
               if((dacc[40:24] == 17'b0_0000_0000_0000_0000)||(dacc[40:24] == 17'b1_1111_1111_1111_1111))
                   dcut = {dacc[40],dacc[9+:15]};
                else
                    dcut = dacc[40] ? 16'b1000_0000_0000_0000 : 16'b0111_1111_1111_1111;
            end

            5'd10:
            begin
                if((dacc[40:25] == 16'b0000_0000_0000_0000)||(dacc[40:25] == 16'b1111_1111_1111_1111))
                   dcut = {dacc[40],dacc[10+:15]};
                else
                    dcut = dacc[40] ? 16'b1000_0000_0000_0000 : 16'b0111_1111_1111_1111;
            end
            
            5'd11:
            begin
                if((dacc[40:26] == 15'b000_0000_0000_0000)||(dacc[40:26] == 15'b111_1111_1111_1111))
                   dcut = {dacc[40],dacc[11+:15]};
                else
                    dcut = dacc[40] ? 16'b1000_0000_0000_0000 : 16'b0111_1111_1111_1111;
            end

            5'd12:
            begin
                if((dacc[40:27] == 14'b00_0000_0000_0000)||(dacc[40:27] == 14'b11_1111_1111_1111))
                   dcut = {dacc[40],dacc[12+:15]};
                else
                    dcut = dacc[40] ? 16'b1000_0000_0000_0000 : 16'b0111_1111_1111_1111;
            end

            5'd13:
            begin
                if((dacc[40:28] == 13'b0_0000_0000_0000)||(dacc[40:28] == 13'b1_1111_1111_1111))
                   dcut = {dacc[40],dacc[13+:15]};
                else
                    dcut = dacc[40] ? 16'b1000_0000_0000_0000 : 16'b0111_1111_1111_1111;
            end

            5'd14:
            begin
                if((dacc[40:29] == 12'b0000_0000_0000)||(dacc[40:29] == 12'b1111_1111_1111))
                   dcut = {dacc[40],dacc[14+:15]};
                else
                    dcut = dacc[40] ? 16'b1000_0000_0000_0000 : 16'b0111_1111_1111_1111;
            end

            5'd15:
             begin
                if((dacc[40:30] == 11'b000_0000_0000)||(dacc[40:30] == 11'b111_1111_1111))
                   dcut = {dacc[40],dacc[15+:15]};
                else
                    dcut = dacc[40] ? 16'b1000_0000_0000_0000 : 16'b0111_1111_1111_1111;
            end

            5'd16:
            begin
                 if((dacc[40:31] == 10'b00_0000_0000)||(dacc[40:31] == 10'b11_1111_1111))
                   dcut = {dacc[40],dacc[16+:15]};
                else
                    dcut = dacc[40] ? 16'b1000_0000_0000_0000 : 16'b0111_1111_1111_1111;
            end
            
            5'd17:
            begin
                 if((dacc[40:32] == 9'b0_0000_0000)||(dacc[40:32] == 9'b1_1111_1111))
                   dcut = {dacc[40],dacc[17+:15]};
                else
                    dcut = dacc[40] ? 16'b1000_0000_0000_0000 : 16'b0111_1111_1111_1111;
            end
            5'd18:
            begin
                 if((dacc[40:33] == 8'b0000_0000)||(dacc[40:33] == 8'b1111_1111))
                   dcut = {dacc[40],dacc[18+:15]};
                else
                    dcut = dacc[40] ? 16'b1000_0000_0000_0000 : 16'b0111_1111_1111_1111;
            end
           5'd19:
            begin
                if((dacc[40:34] == 7'b000_0000)||(dacc[40:34] == 7'b111_1111))
                   dcut = {dacc[40],dacc[19+:15]};
                else
                    dcut = dacc[40] ? 16'b1000_0000_0000_0000 : 16'b0111_1111_1111_1111;
            end
           5'd20:
            begin
                if((dacc[40:35] == 6'b00_0000)||(dacc[40:35] == 6'b11_1111))
                   dcut = {dacc[40],dacc[20+:15]};
                else
                    dcut = dacc[40] ? 16'b1000_0000_0000_0000 : 16'b0111_1111_1111_1111;
            end
           5'd21:
            begin
               if((dacc[40:36] == 5'b0_0000)||(dacc[40:36] == 5'b1_1111))
                   dcut = {dacc[40],dacc[21+:15]};
                else
                    dcut = dacc[40] ? 16'b1000_0000_0000_0000 : 16'b0111_1111_1111_1111;
            end
           5'd22:
            begin
                if((dacc[40:37] == 4'b0000)||(dacc[40:37] == 4'b1111))
                   dcut = {dacc[40],dacc[22+:15]};
                else
                    dcut = dacc[40] ? 16'b1000_0000_0000_0000 : 16'b0111_1111_1111_1111;
            end
           5'd23:
            begin
                if((dacc[40:38] == 3'b000)||(dacc[40:38] == 3'b111))
                   dcut = {dacc[40],dacc[23+:15]};
                else
                    dcut = dacc[40] ? 16'b1000_0000_0000_0000 : 16'b0111_1111_1111_1111;;
            end
           5'd24:
            begin
                if((dacc[40:39] == 2'b00)||(dacc[40:39] == 2'b11))
                   dcut = {dacc[40],dacc[24+:15]};
                else
                    dcut = dacc[40] ? 16'b1000_0000_0000_0000 : 16'b0111_1111_1111_1111;
            end
           5'd25:
                  dcut =dacc[25+:16];
           default:                 
                  dcut =dacc[25+:16];
        endcase
    end
    
        assign dlut = (dcut>0)?dcut:0;
        
        
        always@(*)begin
            if(post_type==0)begin
                dbin = dcut;
            end
            else begin 
                dbin = dlut;
            end
        end 
     

endmodule