`timescale 1ns / 1ps

module axon #(inrng = 32,num_of_core=64)(
    input clk,
    input rst,
    input signed [15:0]din,
    input logic [5:0]waddr,
    input logic wen,
    input [5:0] raddr,
    input d2a,
    input start,
    input signal,
    output logic data_req,
    output logic phase_reg,
    output logic signed [15:0]data_ad,
    output logic a2d, 
    output logic [inrng-1:0] mask
);
//乒乓，先读完，则a2d不拉高，raddr不会更新
//先写完，则data_req不继续要数
    
    logic pp;
    logic [7:0]count;
    
    logic [2:0]state;
    localparam [2:0]Idle = 3'b001,Read = 3'b010,Wait = 3'b100;
    logic [5:0] addr0,addr1;
    logic signed [15:0] dout0,dout1;
    logic en0,en1;
    logic pp;
    logic wr;
    logic rd;
    
    logic phase;
    logic phase_reg2;
    logic [5:0] waddr_reg;

    assign en0 = pp ? d2a : wen;
    assign en1 = pp ? wen : d2a;
    assign addr0 = pp ? raddr : waddr;
    assign addr1 = pp ? waddr : raddr;
    assign data_ad = pp ? dout0 : dout1;

//    ppbuffer #(16,5) data_ram(clk,wen,rst,d2a,pp,waddr,raddr,din,data_ad);

    assign a2d = d2a&&(state == Read);
    
    bram_axon bram0 (
      .clka(clk),    // input wire clka
      .ena(en0),      // input wire ena
      .wea(~pp),      // input wire [0 : 0] wea
      .addra(addr0),  // input wire [4 : 0] addra
      .dina(din),    // input wire [15 : 0] dina
      .douta(dout0)  // output wire [15 : 0] douta
    );
    
    bram_axon bram1 (
      .clka(clk),    // input wire clka
      .ena(en1),      // input wire ena
      .wea(pp),      // input wire [0 : 0] wea
      .addra(addr1),  // input wire [4 : 0] addra
      .dina(din),    // input wire [15 : 0] dina
      .douta(dout1)  // output wire [15 : 0] douta
    );

    always@(posedge clk)
      begin
        if(!rst)
          data_req <= 0;
        else begin
          if((state == Idle || state == Read) && start && (count <= inrng-4))
            data_req <= 1;
          else 
            data_req <= 0;
          end
        end

    always@(posedge clk)
      begin
        if(!rst)
          phase <= 1'b0;
        else if(count == inrng-1)
          phase <= 1'b1;
        else 
          phase <= phase;
      end
      
    always@(posedge clk)
      begin
        if(!rst) begin
          phase_reg <= 0;
          phase_reg2 <= 0;
          waddr_reg <= 0;
        end
      else begin
        phase_reg <= phase;
        phase_reg2 <= phase_reg;
        waddr_reg <= waddr;
      end
    end

    always@(posedge clk)//写计数
      begin
        if(!rst)
          count <= 0;
        else begin
            if(count == inrng-1)
                count <= 0;
            else if(wen && start && waddr != waddr_reg)
                count <= count + 1;
            else
                count <= count;
        end
      end
    
    always@(posedge clk)
      begin
        if(!rst)
          mask <= 0;
        else begin
          if(wen)
            begin
                mask[waddr]<=(din != 0);
            end
          else
            mask <= mask;
        end
      end

    //read FSM
    always@(posedge clk)
    begin
        if(!rst)
        begin
            state <=Idle;
            pp <= 0;
        end
        else begin
            case(state)
                Idle:
                begin
                    if(count == inrng-1)//第一次写满一个buffer进入读状态
                      begin
                        state <= Read;
                        pp <= ~pp;
                      end

                    else begin
                        state <= Idle;
                        pp <= pp;
                    end
                end
                
                Read:
                begin
                  if(count == inrng - 1)
                    begin
                      state <= Wait;
                      pp <= pp;
                    end
                  
                  else begin
                      state <= Read;
                      pp <= pp;
                    end
                end
                
                Wait:
                  begin
                    if(signal)
                        begin
                          pp <= ~pp;
                          state <= Read;
                        end
                    else begin
                      pp <= pp;
                      state <= Wait;
                    end
                  end 

                default:
                    state <= Idle;
            endcase
        end
    end
         
endmodule