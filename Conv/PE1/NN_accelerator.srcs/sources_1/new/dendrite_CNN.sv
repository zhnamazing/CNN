`timescale 1ns / 1ps
module dendrite_CNN #(parameter NUM_OF_CORE = 6,core_size = 5,colrng = 32, size = 64, stride = 1,row = 2,group = 4)(
    input clk,
    //input clk2x,
    input rst,
    input signed [15:0]data_ad,
    input a2d,//a2d=0代表本周期输入的数据无效
    input s2d,
    input [15:0]dram,
    input [NUM_OF_CORE-1:0]v1,
    input [(group-1)*size-1:0]mask,
    input phase,
    input wri,
    
    output logic [9:0]raddr,
    output logic signed [39:0]data_ds,
    output logic d2a,
    output logic d2s
    //output logic [30:0] count
);
//卷积步长为2
// pe和dendrite中raddr keep true
// 时钟周期延长到9.2 4.6
// bia用 offset_H *colrng *2 + offset_W *2代替
// offset_W <= (((offset_H+1)*stride) > ((group-1)*row - core_size)) ? ((offset_W==colrng-core_size) ? 0 : (offset_W+1)) : offset_W;
// offset_H <= (((offset_H+1)*stride) > ((group-1)*row - core_size)) ? 0 : (offset_H+1);//先行后列移动窗口

    localparam [5:0] core = core_size*core_size;
    logic [9:0] raddr_reg;
    logic signed [39:0]macout [NUM_OF_CORE-1'b1:0];
    logic signed [39:0]macout_reg [NUM_OF_CORE-1'b1:0];
    logic [3:0]sel;
    logic [7:0]bia;
    logic wri_reg;
    logic wri_reg2;
    logic [5:0]offset_H;
    logic [7:0]offset_W;
    logic [4:0]raddrw;
    logic [4:0]raddrw_reg;
    logic [4:0]raddrw_reg2;
    logic [4:0]raddrw_reg3;
    logic tail;
    logic flag;
    logic ta;
    logic tail_pic;
    logic tail_pic_reg;
    logic tail_pic_reg2;
    logic tail_reg;
    logic tail_edge;
    logic tail_edge_reg;
    logic tail_edge_reg2;
    logic a2d_reg;
    logic a2d_reg2;
    logic a2d_reg3;

//    logic [11:0]C;
    logic [3:0]H;
    logic [3:0]W;
//    logic [11:0]C1;
    logic [2:0]H1;
    logic [2:0]W1;
//    logic [11:0]C2;
    logic [2:0]H2;
    logic [2:0]W2;
//    logic [11:0]C3;
    logic [2:0]H3;
    logic [2:0]W3;
//    logic [11:0]C4;
    logic [2:0]H4;
    logic [2:0]W4;

    logic [4:0] next1;
    logic [4:0] next2;
    logic [4:0] next3;
    logic [4:0] next4;
    
    logic [7:0] next_pic1;
    logic [7:0] next_pic2;
    logic [7:0] next_pic3;
    logic [7:0] next_pic4;
    /*标记点在卷积窗口的位置
    */
    logic d2a_reg;
    logic [3:0]state1;
    logic [3:0]state1_reg;
    logic [1:0]state2;
    logic signed [39:0] data_fifo;
    localparam [3:0]Idle = 4'b0001,Calc = 4'b0010,Writ = 4'b0100,Wait = 4'b1000;
    localparam [1:0]idle = 2'b01,send = 2'b10;

    assign next1 = H1 * core_size + W1;
    assign next2 = H2 * core_size + W2;
    assign next3 = H3 * core_size + W3;
    assign next4 = H4 * core_size + W4;
    
    assign next_pic1 = H1 * colrng + W1;
    assign next_pic2 = H2 * colrng + W2;
    assign next_pic3 = H3 * colrng + W3;
    assign next_pic4 = H4 * colrng + W4;
    
genvar j;      
generate
   for (j = 0; j < NUM_OF_CORE; j = j + 1) 
     begin
    mac_CNN mymac(clk,rst,a2d_reg2,data_ad,raddrw_reg2,dram[0+:16],v1[j],macout[j]);  
   end
endgenerate  

    
    //确定读取的权重和输入在二维图上的位置
    always@(posedge clk)begin
          if(!rst)begin
            tail_reg<=1'b0;
            tail_pic_reg<=1'b0;
            tail_pic_reg2<=1'b0;
            tail_edge_reg<=1'b0;
            tail_edge_reg2<=1'b0;
            a2d_reg<=1'b0;
            a2d_reg2<=1'b0;
            a2d_reg3<=1'b0;
            raddrw_reg<=0;
            raddrw_reg2<=0;
            raddrw_reg3<=0;
            state1_reg<=Idle;
            wri_reg <= 0;
            wri_reg2 <= 0;
            raddr_reg <= 0;
          end
          else begin
            tail_reg<=tail;
            tail_pic_reg<=tail_pic;
            tail_pic_reg2<=tail_pic_reg;
            tail_edge_reg<=tail_edge;
            tail_edge_reg2<=tail_edge_reg;
            a2d_reg<=a2d;
            a2d_reg2<=a2d_reg;
            a2d_reg3<=a2d_reg2;
            raddrw_reg<=raddrw;
            raddrw_reg2<=raddrw_reg;
            raddrw_reg3<=raddrw_reg2;
            state1_reg<=state1;
            wri_reg <= wri;
            wri_reg2 <= wri_reg;
            raddr_reg <= raddr;
          end
      end
    
    always@(posedge clk)//捕捉上升沿
      begin if(!rst)
          tail_edge<=1'b0;
      else begin
        if(tail&&(!tail_reg))
            tail_edge<=1;
        else
            tail_edge<=0;
        end
    end
       
    //mux32
    always @(posedge clk or negedge rst)
    begin
      if(!rst)
        data_ds <= 0;
      else begin
        case (sel)
            6'd0: data_ds <= macout_reg[0];
            6'd1: data_ds <= macout_reg[1];
            6'd2: data_ds <= macout_reg[2];
            6'd3: data_ds <= macout_reg[3];
            6'd4: data_ds <= macout_reg[4];
            6'd5: data_ds <= macout_reg[5];
            6'd6: data_ds <= macout_reg[6];
            6'd7: data_ds <= macout_reg[7];

            default: data_ds <= macout_reg[0];
        endcase
    end
  end

//    assign neuron = offset_H * colrng + offset_W;//这里neuron是这个值在输出图中的位置，池化后得到新的位置，加进flit中
    always@(posedge clk or negedge rst)
    begin
      if(!rst)begin
        W1 <= 1;
        H1 <= 0;
        W2 <= 2;
        H2 <= 0;
        W3 <= 3;
        H3 <= 0;
        W4 <= 4;
        H4 <= 0;
      end
      
      else if((raddr == (core_size+stride)*colrng-1) && tail_edge_reg2 && (!wri_reg))
        begin
            W1 <= 1;
            H1 <= 0;
            W2 <= 2;
            H2 <= 0;
            W3 <= 3;
            H3 <= 0;
            W4 <= 4;
            H4 <= 0;
        end
      
      else if(a2d||tail_edge_reg2)begin
        if(mask[H1 * colrng + W1 + bia] == 1)
            begin
                W1 <= ((next1+1)>core-1)? core_size-1: ((next1+1)%core_size);
                H1 <= ((next1+1)>core-1)? core_size-1: ((next1+1)/core_size);

                W2 <= ((next1+2)>core-1)? core_size-1: ((next1+2)%core_size);
                H2 <= ((next1+2)>core-1)? core_size-1: ((next1+2)/core_size);

                W3 <= ((next1+3)>core-1)? core_size-1: ((next1+3)%core_size);
                H3 <= ((next1+3)>core-1)? core_size-1: ((next1+3)/core_size);

                W4 <= ((next1+4)>core-1)? core_size-1: ((next1+4)%core_size);
                H4 <= ((next1+4)>core-1)? core_size-1: ((next1+4)/core_size);
            end
         else if(mask[H2 * colrng + W2 + bia] == 1)
            begin
                W1 <= ((next2+1)>core-1)? core_size-1: ((next2+1)%core_size);
                H1 <= ((next2+1)>core-1)? core_size-1: ((next2+1)/core_size);

                W2 <= ((next2+2)>core-1)? core_size-1: ((next2+2)%core_size);
                H2 <= ((next2+2)>core-1)? core_size-1: ((next2+2)/core_size);

                W3 <= ((next2+3)>core-1)? core_size-1: ((next2+3)%core_size);
                H3 <= ((next2+3)>core-1)? core_size-1: ((next2+3)/core_size);

                W4 <= ((next2+4)>core-1)? core_size-1: ((next2+4)%core_size);
                H4 <= ((next2+4)>core-1)? core_size-1: ((next2+4)/core_size);
            end
          else if(mask[H3 * colrng + W3 + bia] == 1)
            begin
                W1 <= ((next3+1)>core-1)? core_size-1: ((next3+1)%core_size);
                H1 <= ((next3+1)>core-1)? core_size-1: ((next3+1)/core_size);

                W2 <= ((next3+2)>core-1)? core_size-1: ((next3+2)%core_size);
                H2 <= ((next3+2)>core-1)? core_size-1: ((next3+2)/core_size);

                W3 <= ((next3+3)>core-1)? core_size-1: ((next3+3)%core_size);
                H3 <= ((next3+3)>core-1)? core_size-1: ((next3+3)/core_size);

                W4 <= ((next3+4)>core-1)? core_size-1: ((next3+4)%core_size);
                H4 <= ((next3+4)>core-1)? core_size-1: ((next3+4)/core_size);               
            end
           else begin
                W1 <= ((next4+1)>core-1)? core_size-1: ((next4+1)%core_size);
                H1 <= ((next4+1)>core-1)? core_size-1: ((next4+1)/core_size);

                W2 <= ((next4+2)>core-1)? core_size-1: ((next4+2)%core_size);
                H2 <= ((next4+2)>core-1)? core_size-1: ((next4+2)/core_size);

                W3 <= ((next4+3)>core-1)? core_size-1: ((next4+3)%core_size);
                H3 <= ((next4+3)>core-1)? core_size-1: ((next4+3)/core_size);

                W4 <= ((next4+4)>core-1)? core_size-1: ((next4+4)%core_size);
                H4 <= ((next4+4)>core-1)? core_size-1: ((next4+4)/core_size);                 
            end
      end
      
      else if(tail_edge_reg)begin
        W1 <= 0;
        H1 <= 0;
        W2 <= 1;
        H2 <= 0;
        W3 <= 2;
        H3 <= 0;
        W4 <= 3;
        H4 <= 0;
      end
    end
    
    assign ta = tail_edge_reg2&&(!tail_pic_reg);
    assign tail = (raddrw == core-1) ? 1 : 0;//一个卷积窗口计算完成标志
    assign tail_pic = (raddr == (core_size+stride)*colrng-1) ? 1 : 0;//一个部分算完标志


    always@(posedge clk)
    begin
        if(!rst)
        begin
            raddr <=  0;
            raddrw <= 0;
            offset_H<=0;
            offset_W<=0;
            bia <= 0;
            //count <= 0;
        end
        
        else if((state1==Calc)&&tail_edge)
        begin
            raddr <=  raddr;
            raddrw <= raddrw;
            offset_W <= ((offset_H+stride) > ((group-1)*row - core_size)) ? ((offset_W==colrng-core_size) ? 0 : (offset_W + stride)) : offset_W;
            offset_H <= ((offset_H+stride) > ((group-1)*row - core_size)) ? 0 : (offset_H + stride);//先行后列移动窗口
//            offset_W <= (((offset_H+1)*stride) > ((group-1)*row - core_size)) ? ((offset_W*stride==colrng-core_size) ? 0 : (offset_W+1)) : offset_W;
//            offset_H <= (((offset_H+1)*stride) > ((group-1)*row - core_size)) ? 0 : (offset_H+1);//先行后列移动窗口
            bia <= bia;
            //count <= count;
        end

        else if((state1==Calc)&&tail_edge_reg)
        begin
            raddr <= raddr;
            raddrw <= raddrw;
            offset_W <= offset_W;
            offset_H <= offset_H;
            bia <= offset_H * colrng + offset_W;
            //count <= count;
        end
        
        else if((raddr == (core_size+stride)*colrng-1) && tail_edge_reg2 && (!wri))
          begin
            raddr <= 0;
            raddrw <= 0;
            //count <= count;
          end
        
        else if(a2d||tail_edge_reg2)
        begin//基于mask的跳过
          if(mask[H1 * colrng + W1 + bia] == 1)
            begin
                raddr <=  H1 * colrng + W1 + bia;
                raddrw <= H1 * core_size + W1;
                //count <= count;
            end
          else if(mask[H2 * colrng + W2 + bia] == 1)
            begin
                raddr <=  H2 * colrng + W2 + bia;
                raddrw <= H2 * core_size + W2;
                //count <= count + 1;
            end
          else if(mask[H3 * colrng + W3 + bia] == 1)
            begin
                raddr <=  H3 * colrng + W3 + bia;
                raddrw <= H3 * core_size + W3;   
                //count <= count + 2;            
            end
          else begin
                raddr <=  H4 * colrng + W4 + bia;
                raddrw <= H4 * core_size + W4;   
                
//                if(raddrw == core - 4)
//                  count <= count + 2;
//                else if(raddrw == core - 3)
//                  count <= count + 1;
//                else if(raddrw >= core - 2)
//                  count <= count;
//                else
//                  count <= count + 3;            
                   
            end

            offset_W <= offset_W;
            offset_H <= offset_H;
            bia <= bia;
        end
        else
        begin
            raddr <=  raddr;
            raddrw <= raddrw; 
            offset_W <= offset_W;
            offset_H <= offset_H;      
            bia <= bia;       
            //count <= count;            
        end
    end

    always@(posedge clk)
    begin
        if(!rst)
        begin
            state1 <= Idle;
            d2a <= 1'b0;
            flag <= 1'b0;
        end
        else
            case (state1)
                Idle:
                begin
                    flag <= flag;
                    if(phase&&s2d)//全部配置完成
                    begin
                        d2a <= 1;
                        if(a2d)
                          state1<=Calc;
                        else
                          state1<=Idle;
                    end
                    else begin
                        d2a<=0;
                        state1 <= Idle;
                    end
                end
                Calc:
                begin
                    flag <= flag;
                    if(tail_edge_reg2)//算完一个卷积窗口
                    begin
                        state1 <= Writ;
                        if(!tail_pic_reg)
                          d2a<=1;
                        else
                          d2a<=0;
                    end
                    else begin
                        state1 <= Calc;
                        if(tail&&(~tail_edge_reg))
                          d2a<=0;
                        else
                          d2a<=d2a;
                      end
                end
                Writ:
                begin
//                    flag <= flag;
                    if(raddr_reg == (core_size+stride)*colrng-1 && !wri)
                      begin
                        d2a<=0; 
                        state1 <= Wait;
                      end
                    else
                      begin
                        d2a<=1;
                        state1 <= Calc;
                      end
                end
                
                Wait:
                begin
                    if(wri_reg2)
                      begin
                        d2a<=1;
                        state1 <= Calc;
                      end
                    else
                      begin    
                        d2a<=0;
                        state1 <= Wait;
                      end
                end      

                default:begin
                    state1 <= Idle;
                    d2a<=d2a;
                  end
            endcase
    end
    
    always@(posedge clk)
      begin
        if(!rst)
          begin
            for (integer i = 0; i < NUM_OF_CORE; i = i + 1) 
              begin
                  macout_reg[i] <= 0;
              end
          end
        else if(state1_reg == Writ)
          begin
            for (integer i = 0; i < NUM_OF_CORE; i = i + 1) 
              begin
                  macout_reg[i] <= macout[i];
              end
          end
       end
    
    //send FSM
  always@(posedge clk)
    begin
        if(!rst)
        begin
            state2 <= idle;
            sel <= 0;
            d2s <= 1'b0;
            //group_reg <= 0;
        end
        else
            case (state2)
                idle: 
                begin
                    if(state1_reg == Writ)
                    begin
                        state2 <= send;
                        d2s <= 0;
                    end
                    else begin
                        state2 <= idle;
                        d2s<=0;
                      end
                end

                send:
                begin
                    if(sel == NUM_OF_CORE-1)//串行发送卷积结果
                    begin
                        state2 <= idle;
                        sel <= 0;
                        d2s <= 1;
                    end
                    else
                    begin
                        state2 <= send;
                        d2s<=1;
                        sel <= sel + 1;
                    end
                end

                default: begin
                    state2 <= idle;
                    d2s<=d2s;
                    sel<=0;
                  end
            endcase        
    end

endmodule