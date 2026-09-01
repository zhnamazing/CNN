`timescale 1ns / 1ps

module dendrite#(inrng = 32,num_of_core = 64)(
    input clk,
    input rst,
    input signed [15:0]data_ad,
    input a2d,
    input s2d,
    input [22:0] weight_info,
//    input signed [15:0]dram,
//    input [6:0] v1,
    input [inrng-1:0] mask,
    input phase,
    output logic signed [39:0]data_ds,
    output logic [7:0]neuron,
    output logic d2a,
    output logic d2s,
    output logic [5:0] raddr,
    output logic signal
    //output logic [30:0] count
);
    logic signed [15:0] dram_reg;
    logic [63:0] weight_en;
    logic [5:0] raddr_reg;
    
    logic signed [15:0]dram;
    logic [6:0] v1;
    
    logic [2:0]group;
    logic [2:0]group_reg; 
    logic signed [39:0]macout[0:num_of_core-1];
    logic signed [39:0]macout_reg[0:num_of_core-1];
    logic [5:0]sel;
    logic finish;

    logic [5:0] raddr_next1;
    logic [5:0] raddr_next2;
    logic [5:0] raddr_next3;
    logic [5:0] raddr_next4;

    logic [3:0]state1;
    logic [1:0]state2;
    logic [3:0]state1_reg;
    localparam [3:0]Idle = 4'b0001,Calc = 4'b0010,Writ = 4'b0100,Rest = 4'b1000;
    localparam [1:0]idle = 2'b01,send = 2'b10;
    
    genvar j;      
    generate
    for (j = 0; j < num_of_core; j = j + 1) 
        begin
          mac #(inrng) mymac(clk,rst,a2d,data_ad,dram_reg[0+:16],raddr,weight_en[j],macout[j]);  
        end
    endgenerate 
    //generate mac 输入广播到所有，每个MAC负责一个输出；下一轮迭代
    
    assign signal = (sel == num_of_core-1);
    
always@(posedge clk)
    begin
        if(!rst) begin
            weight_en <= 0;
            dram_reg <= 0;
        end
        else begin
            dram_reg <= weight_info[15:0];
            
            if (weight_info[22:16] >= 7'd1 && weight_info[22:16] <= 7'd64) begin
                weight_en <= (64'b1 << (weight_info[22:16] - 7'd1));
            end
            else begin
                weight_en <= 64'd0;
            end
        end
    end
//      begin
//        if(!rst)
//          begin
//            weight_en <= 0;
//            dram_reg <= 0;
//          end
//        else begin
//          dram_reg <= weight_info[15:0];

//          case(weight_info[22:16])
//            7'd1: weight_en <= 64'b0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001;
//            7'd2: weight_en <= 64'b0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0010;
//            7'd3: weight_en <= 64'b0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0100;
//            7'd4: weight_en <= 64'b0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_1000;
//            7'd5: weight_en <= 64'b0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001_0000;
//            7'd6: weight_en <= 64'b0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0010_0000;
//            7'd7: weight_en <= 64'b0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0100_0000;
//            7'd8: weight_en <= 64'b0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_1000_0000;
//            7'd9: weight_en <= 64'b0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001_0000_0000;
//            7'd10: weight_en <= 64'b0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0010_0000_0000;
//            7'd11: weight_en <= 64'b0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0100_0000_0000;
//            7'd12:weight_en <= 64'b0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_1000_0000_0000;
//            7'd13:weight_en <= 64'b0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001_0000_0000_0000;
//            7'd14:weight_en <= 64'b0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0010_0000_0000_0000;
//            7'd15:weight_en <= 64'b0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0100_0000_0000_0000;
//            7'd16:weight_en <= 64'b0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_1000_0000_0000_0000;
//            7'd17:weight_en <= 64'b0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001_0000_0000_0000_0000;
//            7'd18:weight_en <= 64'b0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0010_0000_0000_0000_0000;
//            7'd19:weight_en <= 64'b0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0100_0000_0000_0000_0000;
//            7'd20:weight_en <= 64'b0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_1000_0000_0000_0000_0000;
//            7'd21:weight_en <= 64'b0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001_0000_0000_0000_0000_0000;
//            7'd22:weight_en <= 64'b0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0010_0000_0000_0000_0000_0000;
//            7'd23:weight_en <= 64'b0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0100_0000_0000_0000_0000_0000;
//            7'd24:weight_en <= 64'b0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_1000_0000_0000_0000_0000_0000;
//            7'd25:weight_en <= 64'b0000_0000_0000_0000_0000_0000_0000_0000_0000_0001_0000_0000_0000_0000_0000_0000;
//            7'd26:weight_en <= 64'b0000_0000_0000_0000_0000_0000_0000_0000_0000_0010_0000_0000_0000_0000_0000_0000;
//            7'd27:weight_en <= 64'b0000_0000_0000_0000_0000_0000_0000_0000_0000_0100_0000_0000_0000_0000_0000_0000;
//            7'd28:weight_en <= 64'b0000_0000_0000_0000_0000_0000_0000_0000_0000_1000_0000_0000_0000_0000_0000_0000;
//            7'd29:weight_en <= 64'b0000_0000_0000_0000_0000_0000_0000_0000_0001_0000_0000_0000_0000_0000_0000_0000;
//            7'd30:weight_en <= 64'b0000_0000_0000_0000_0000_0000_0000_0000_0010_0000_0000_0000_0000_0000_0000_0000;
//            7'd31:weight_en <= 64'b0000_0000_0000_0000_0000_0000_0000_0000_0100_0000_0000_0000_0000_0000_0000_0000;
//            7'd32:weight_en <= 64'b0000_0000_0000_0000_0000_0000_0000_0000_1000_0000_0000_0000_0000_0000_0000_0000;
//            7'd33:weight_en <= 64'b0000_0000_0000_0000_0000_0000_0000_0001_0000_0000_0000_0000_0000_0000_0000_0000;
//            7'd34:weight_en <= 64'b0000_0000_0000_0000_0000_0000_0000_0010_0000_0000_0000_0000_0000_0000_0000_0000;
//            7'd35:weight_en <= 64'b0000_0000_0000_0000_0000_0000_0000_0100_0000_0000_0000_0000_0000_0000_0000_0000;
//            7'd36:weight_en <= 64'b0000_0000_0000_0000_0000_0000_0000_1000_0000_0000_0000_0000_0000_0000_0000_0000;
//            7'd37:weight_en <= 64'b0000_0000_0000_0000_0000_0000_0001_0000_0000_0000_0000_0000_0000_0000_0000_0000;
//            7'd38:weight_en <= 64'b0000_0000_0000_0000_0000_0000_0010_0000_0000_0000_0000_0000_0000_0000_0000_0000;
//            7'd39:weight_en <= 64'b0000_0000_0000_0000_0000_0000_0100_0000_0000_0000_0000_0000_0000_0000_0000_0000;
//            7'd40:weight_en <= 64'b0000_0000_0000_0000_0000_0000_1000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
//            7'd41:weight_en <= 64'b0000_0000_0000_0000_0000_0001_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
//            7'd42:weight_en <= 64'b0000_0000_0000_0000_0000_0010_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
//            7'd43:weight_en <= 64'b0000_0000_0000_0000_0000_0100_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
//            7'd44:weight_en <= 64'b0000_0000_0000_0000_0000_1000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
//            7'd45:weight_en <= 64'b0000_0000_0000_0000_0001_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
//            7'd46:weight_en <= 64'b0000_0000_0000_0000_0010_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
//            7'd47:weight_en <= 64'b0000_0000_0000_0000_0100_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
//            7'd48:weight_en <= 64'b0000_0000_0000_0000_1000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
//            7'd49:weight_en <= 64'b0000_0000_0000_0001_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
//            7'd50:weight_en <= 64'b0000_0000_0000_0010_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
//            7'd51:weight_en <= 64'b0000_0000_0000_0100_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
//            7'd52:weight_en <= 64'b0000_0000_0000_1000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
//            7'd53:weight_en <= 64'b0000_0000_0001_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
//            7'd54:weight_en <= 64'b0000_0000_0010_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
//            7'd55:weight_en <= 64'b0000_0000_0100_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
//            7'd56:weight_en <= 64'b0000_0000_1000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
//            7'd57:weight_en <= 64'b0000_0001_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
//            7'd58:weight_en <= 64'b0000_0010_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
//            7'd59:weight_en <= 64'b0000_0100_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
//            7'd60:weight_en <= 64'b0000_1000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
//            7'd61:weight_en <= 64'b0001_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
//            7'd62:weight_en <= 64'b0010_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
//            7'd63:weight_en <= 64'b0100_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
//            7'd64:weight_en <= 64'b1000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
            
//        default:weight_en <= 64'd0;
//          endcase
//        end
//      end



    //mux32
    always @(*)
      begin
        data_ds = macout_reg[sel];
      end
      
    always@(posedge clk)
      begin
        if(!rst) begin
          state1_reg <= 0;
          raddr_reg <= 0;
        end
        else begin
          state1_reg <= state1;
          raddr_reg <= raddr;
        end
      end
    
    assign finish = (raddr_reg == inrng-1);
    
    always@(posedge clk)
      begin
        if(!rst)
          begin
            for (integer i = 0; i < num_of_core; i = i + 1) 
                  macout_reg[i] <= 0;
          end
        else begin
          if(state1_reg == Writ)
            begin
              for (integer i = 0; i < num_of_core; i = i + 1) 
                  macout_reg[i] <= macout[i];
              end
          else begin
             for (integer i = 0; i < num_of_core; i = i + 1) 
                  macout_reg[i] <= macout_reg[i];
                end
              end
            end
            
    
    // assign neuron = sel + (group_reg << 5);//每个group32个结果，neuron是输出神经元

    always@(posedge clk)
      begin
        if(!rst)
          begin
            raddr <= 0;
            //count <= 0;
          end
        else begin
            if(a2d)
              begin
                if(mask[raddr_next1])
                begin
                  raddr <= raddr_next1;
                  //count <= count;
                end

                else if(mask[raddr_next2])
                begin
                    raddr <= raddr_next2;
                    //count <= count + 1;
                end
                
                else if(mask[raddr_next3])
                 begin
                    raddr  <= raddr_next3;
                    //count <= count + 2;
                  end

                else begin
                  raddr <= raddr_next4;
                  
//                  if(raddr == inrng - 4)
//                    count <= count + 2;
//                  else if(raddr == inrng - 3)
//                    count <= count + 1;
//                  else if(raddr >= inrng - 2)
//                    count <= count;
//                  else
//                    count <= count + 3; 
                  end
              end
            
            else if(&finish)
              begin
                raddr <= 0;
                //count <= count;
              end
            else begin
                raddr <= raddr;
                //count <= count;
              end
            end
        end
    
    always@(posedge clk)
      begin
        if(!rst)
          begin
            raddr_next1 <= 1;
            raddr_next2 <= 2;
            raddr_next3 <= 3;
            raddr_next4 <= 4;
          end
        else begin
            if(a2d)
              begin
                if(mask[raddr_next1])
                begin
                    raddr_next1 <= (raddr_next1+1>inrng-1) ? inrng-1 : raddr_next1+1;
                    raddr_next2 <= (raddr_next2+1>inrng-1) ? inrng-1 : raddr_next2+1;
                    raddr_next3 <= (raddr_next3+1>inrng-1) ? inrng-1 : raddr_next3+1;
                    raddr_next4 <= (raddr_next4+1>inrng-1) ? inrng-1 : raddr_next4+1;
                end

                else if(mask[raddr_next2])
                begin
                    raddr_next1 <= (raddr_next1+2>inrng-1) ? inrng-1 : raddr_next1+2;
                    raddr_next2 <= (raddr_next2+2>inrng-1) ? inrng-1 : raddr_next2+2;
                    raddr_next3 <= (raddr_next3+2>inrng-1) ? inrng-1 : raddr_next3+2;
                    raddr_next4 <= (raddr_next4+2>inrng-1) ? inrng-1 : raddr_next4+2;
                end
                
                else if(mask[raddr_next3])
                begin
                    raddr_next1 <= (raddr_next1+3>inrng-1) ? inrng-1 : raddr_next1+3;
                    raddr_next2 <= (raddr_next2+3>inrng-1) ? inrng-1 : raddr_next2+3;
                    raddr_next3 <= (raddr_next3+3>inrng-1) ? inrng-1 : raddr_next3+3;
                    raddr_next4 <= (raddr_next4+3>inrng-1) ? inrng-1 : raddr_next4+3;
                end

                else begin
                    raddr_next1 <= (raddr_next1+4>inrng-1) ? inrng-1 : raddr_next1+4;
                    raddr_next2 <= (raddr_next2+4>inrng-1) ? inrng-1 : raddr_next2+4;
                    raddr_next3 <= (raddr_next3+4>inrng-1) ? inrng-1 : raddr_next3+4;
                    raddr_next4 <= (raddr_next4+4>inrng-1) ? inrng-1 : raddr_next4+4;
                end
              end
              
            else if(finish)
              begin
                raddr_next1 <= 1;
                raddr_next2 <= 2;
                raddr_next3 <= 3;
                raddr_next4 <= 4;              
              end
              
            else begin
                raddr_next1 <= raddr_next1;
                raddr_next2 <= raddr_next2;
                raddr_next3 <= raddr_next3;
                raddr_next4 <= raddr_next4;
            end
        end
    end

    //calculate FSM
    always@(posedge clk)
    begin
        if(!rst)
        begin
            state1 <= Idle;
            group <= 0;
            d2a <= 0;
        end
        else
            case (state1)
                Idle:
                begin
                    if(phase&&s2d)
                    begin
                        state1 <= Calc;
                        d2a <= 1;
                    end
                    else begin
                        state1 <= Idle;
                        d2a <= d2a;
                    end
                end
                Calc:
                begin
                    if(&finish == 1)
                      begin
                        state1 <= Writ;
                        d2a <= 0;
                      end
                    else begin
                        state1 <= Calc;
                        d2a <= d2a;
                    end
                end
                Writ:
                begin
                    d2a <= 0;
                    state1 <= Rest;
                end
                
                Rest://还没算完进入reset
                 begin
                   if(signal)
                    begin
                        d2a <= 1;
                        state1 <= Calc;
                    end    
                      else begin
                        d2a <= 0;
                        state1 <= Rest;
                      end
                 end
                default:
                    state1 <= Idle;
            endcase
    end

    //send FSM
    always@(posedge clk)
    begin
        if(!rst)
        begin
            state2 <= idle;
            sel <= 0;
            d2s <= 0;
        end
        else
            case (state2)
                idle: 
                begin
                    if(state1_reg == Writ)
                    begin
                        state2 <= send;
                        d2s <= 1;
                    end
                    else begin
                        state2 <= idle;
                        d2s <= d2s;
                    end
                end

                send:
                begin
                    if(sel == num_of_core-1)
                    begin
                        state2 <= idle;
                        sel <= 0;
                        d2s <= 0;
                    end
                    else
                    begin
                        state2 <= send;
                        sel <= sel + 1;
                        d2s <= d2s;
                    end
                end

                default: 
                    state2 <= idle;
            endcase    
    end
endmodule