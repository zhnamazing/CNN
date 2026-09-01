`timescale 1ns / 1ps
module dendrite_CNN #(parameter NUM_OF_CORE = 6,core_size = 5,colrng = 32, size = 64, stride = 1,row = 2,group = 4,core_channel=8,pool=3)(
    input clk,
    //input clk2x,
    input rst,
    input signed [15:0]data_ad,
    input a2d,//a2d=0代表本周期输入的数据无效
    input s2d,
    input [15:0]dram,
    input [6:0]v1,
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
    
    logic signed [15:0] dram_reg;
    logic [31:0] weight_en;
    
    localparam [8:0] core = core_size*core_size*core_channel;
    logic [9:0] raddr_reg;
    logic signed [39:0]macout [NUM_OF_CORE-1'b1:0];
    logic signed [39:0]macout_reg [NUM_OF_CORE-1'b1:0];
    logic [4:0]sel;
    (* keep = "true" *)logic [9:0]bia;
    logic wri_reg;
    logic wri_reg2;
    logic [5:0]offset_H;
    logic [7:0]offset_W;
    logic [8:0]raddrw;
    logic [8:0]raddrw_reg;
    logic [8:0]raddrw_reg2;
    logic [8:0]raddrw_reg3;
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
//    logic [3:0]H;
//    logic [3:0]W;
    logic [4:0]C1;
    logic [2:0]H1;
    logic [2:0]W1;
    logic [4:0]C2;
    logic [2:0]H2;
    logic [2:0]W2;
    logic [4:0]C3;
    logic [2:0]H3;
    logic [2:0]W3;
    logic [4:0]C4;
    logic [2:0]H4;
    logic [2:0]W4;

    logic [9:0] next1;
    logic [9:0] next2;
    logic [9:0] next3;
    logic [9:0] next4;
    
    logic [9:0] next_pic1;
    logic [9:0] next_pic2;
    logic [9:0] next_pic3;
    logic [9:0] next_pic4;
    /*标记点在卷积窗口的位置
    */
    logic d2a_reg;
    logic [3:0]state1;
    logic [3:0]state1_reg;
    logic [1:0]state2;
    logic signed [39:0] data_fifo;
    localparam [3:0]Idle = 4'b0001,Calc = 4'b0010,Writ = 4'b0100,Wait = 4'b1000;
    localparam [1:0]idle = 2'b01,send = 2'b10;

    //通道优先编址
    assign next1 = H1 * core_size*core_channel + W1 * core_channel + C1;
    assign next2 = H2 * core_size*core_channel + W2 * core_channel + C2;
    assign next3 = H3 * core_size*core_channel + W3 * core_channel + C3;
    assign next4 = H4 * core_size*core_channel + W4 * core_channel + C4;
    
genvar j;      
generate
   for (j = 0; j < NUM_OF_CORE; j = j + 1) 
     begin
    mac_CNN mymac(clk,rst,a2d_reg2,data_ad,raddrw_reg2,dram_reg[0+:16],weight_en[j],macout[j]);  
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
    always@(posedge clk)
      begin
        if(!rst)
          begin
            weight_en <= 0;
            dram_reg <= 0;
          end
        else begin
          dram_reg <= {{8{dram[7]}},dram[7:0]};

          case(v1)
            7'd1: weight_en <= 64'b0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001;
            7'd2: weight_en <= 64'b0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0010;
            7'd3: weight_en <= 64'b0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0100;
            7'd4: weight_en <= 64'b0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_1000;
            7'd5: weight_en <= 64'b0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001_0000;
            7'd6: weight_en <= 64'b0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0010_0000;
            7'd7: weight_en <= 64'b0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0100_0000;
            7'd8: weight_en <= 64'b0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_1000_0000;
            7'd9: weight_en <= 64'b0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001_0000_0000;
            7'd10: weight_en <= 64'b0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0010_0000_0000;
            7'd11: weight_en <= 64'b0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0100_0000_0000;
            7'd12:weight_en <= 64'b0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_1000_0000_0000;
            7'd13:weight_en <= 64'b0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001_0000_0000_0000;
            7'd14:weight_en <= 64'b0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0010_0000_0000_0000;
            7'd15:weight_en <= 64'b0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0100_0000_0000_0000;
            7'd16:weight_en <= 64'b0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_1000_0000_0000_0000;
            7'd17:weight_en <= 64'b0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001_0000_0000_0000_0000;
            7'd18:weight_en <= 64'b0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0010_0000_0000_0000_0000;
            7'd19:weight_en <= 64'b0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0100_0000_0000_0000_0000;
            7'd20:weight_en <= 64'b0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_1000_0000_0000_0000_0000;
            7'd21:weight_en <= 64'b0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001_0000_0000_0000_0000_0000;
            7'd22:weight_en <= 64'b0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0010_0000_0000_0000_0000_0000;
            7'd23:weight_en <= 64'b0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0100_0000_0000_0000_0000_0000;
            7'd24:weight_en <= 64'b0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_1000_0000_0000_0000_0000_0000;
            7'd25:weight_en <= 64'b0000_0000_0000_0000_0000_0000_0000_0000_0000_0001_0000_0000_0000_0000_0000_0000;
            7'd26:weight_en <= 64'b0000_0000_0000_0000_0000_0000_0000_0000_0000_0010_0000_0000_0000_0000_0000_0000;
            7'd27:weight_en <= 64'b0000_0000_0000_0000_0000_0000_0000_0000_0000_0100_0000_0000_0000_0000_0000_0000;
            7'd28:weight_en <= 64'b0000_0000_0000_0000_0000_0000_0000_0000_0000_1000_0000_0000_0000_0000_0000_0000;
            7'd29:weight_en <= 64'b0000_0000_0000_0000_0000_0000_0000_0000_0001_0000_0000_0000_0000_0000_0000_0000;
            7'd30:weight_en <= 64'b0000_0000_0000_0000_0000_0000_0000_0000_0010_0000_0000_0000_0000_0000_0000_0000;
            7'd31:weight_en <= 64'b0000_0000_0000_0000_0000_0000_0000_0000_0100_0000_0000_0000_0000_0000_0000_0000;
            7'd32:weight_en <= 64'b0000_0000_0000_0000_0000_0000_0000_0000_1000_0000_0000_0000_0000_0000_0000_0000;
            7'd33:weight_en <= 64'b0000_0000_0000_0000_0000_0000_0000_0001_0000_0000_0000_0000_0000_0000_0000_0000;
            7'd34:weight_en <= 64'b0000_0000_0000_0000_0000_0000_0000_0010_0000_0000_0000_0000_0000_0000_0000_0000;
            7'd35:weight_en <= 64'b0000_0000_0000_0000_0000_0000_0000_0100_0000_0000_0000_0000_0000_0000_0000_0000;
            7'd36:weight_en <= 64'b0000_0000_0000_0000_0000_0000_0000_1000_0000_0000_0000_0000_0000_0000_0000_0000;
            7'd37:weight_en <= 64'b0000_0000_0000_0000_0000_0000_0001_0000_0000_0000_0000_0000_0000_0000_0000_0000;
            7'd38:weight_en <= 64'b0000_0000_0000_0000_0000_0000_0010_0000_0000_0000_0000_0000_0000_0000_0000_0000;
            7'd39:weight_en <= 64'b0000_0000_0000_0000_0000_0000_0100_0000_0000_0000_0000_0000_0000_0000_0000_0000;
            7'd40:weight_en <= 64'b0000_0000_0000_0000_0000_0000_1000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
            7'd41:weight_en <= 64'b0000_0000_0000_0000_0000_0001_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
            7'd42:weight_en <= 64'b0000_0000_0000_0000_0000_0010_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
            7'd43:weight_en <= 64'b0000_0000_0000_0000_0000_0100_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
            7'd44:weight_en <= 64'b0000_0000_0000_0000_0000_1000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
            7'd45:weight_en <= 64'b0000_0000_0000_0000_0001_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
            7'd46:weight_en <= 64'b0000_0000_0000_0000_0010_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
            7'd47:weight_en <= 64'b0000_0000_0000_0000_0100_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
            7'd48:weight_en <= 64'b0000_0000_0000_0000_1000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
            7'd49:weight_en <= 64'b0000_0000_0000_0001_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
            7'd50:weight_en <= 64'b0000_0000_0000_0010_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
            7'd51:weight_en <= 64'b0000_0000_0000_0100_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
            7'd52:weight_en <= 64'b0000_0000_0000_1000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
            7'd53:weight_en <= 64'b0000_0000_0001_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
            7'd54:weight_en <= 64'b0000_0000_0010_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
            7'd55:weight_en <= 64'b0000_0000_0100_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
            7'd56:weight_en <= 64'b0000_0000_1000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
            7'd57:weight_en <= 64'b0000_0001_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
            7'd58:weight_en <= 64'b0000_0010_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
            7'd59:weight_en <= 64'b0000_0100_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
            7'd60:weight_en <= 64'b0000_1000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
            7'd61:weight_en <= 64'b0001_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
            7'd62:weight_en <= 64'b0010_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
            7'd63:weight_en <= 64'b0100_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
            7'd64:weight_en <= 64'b1000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
            
        default:weight_en <= 64'd0;
          endcase
        end
      end
             
    //mux32
    always @(posedge clk or negedge rst)
    begin
      if(!rst)
        data_ds <= 0;
      else begin
            data_ds <= macout_reg[sel];
      end
    end

//    assign neuron = offset_H * colrng + offset_W;//这里neuron是这个值在输出图中的位置，池化后得到新的位置，加进flit中
    always@(posedge clk or negedge rst)
    begin
      if(!rst)begin
        C1 <= 1;
        W1 <= 0;
        H1 <= 0;
        C2 <= 2;
        W2 <= 0;
        H2 <= 0;
        C3 <= 3;
        W3 <= 0;
        H3 <= 0;
        C4 <= 4;
        W4 <= 0;
        H4 <= 0;
      end
      
      else if((raddr == (core_size+stride)*colrng*core_channel-1) && tail_edge_reg2 && (!wri_reg))
        begin
            C1 <= 1;
            W1 <= 0;
            H1 <= 0;
            C2 <= 2;
            W2 <= 0;
            H2 <= 0;
            C3 <= 3;
            W3 <= 0;
            H3 <= 0;
            C4 <= 4;
            W4 <= 0;
            H4 <= 0;
        end
      
      else if(a2d||tail_edge_reg2)begin
        if(mask[H1 * colrng * core_channel + W1 * core_channel + C1 + bia] == 1)
            begin
                C1 <= ((next1+1)>core-1)? core_channel-1: ((next1+1)%core_channel);
                W1 <= ((next1+1)>core-1)? core_size-1: (((next1+1)/core_channel)%core_size);
                H1 <= ((next1+1)>core-1)? core_size-1: (((next1+1)/core_channel)/core_size);

                C2 <= ((next1+2)>core-1)? core_channel-1: ((next1+2)%core_channel);
                W2 <= ((next1+2)>core-1)? core_size-1: (((next1+2)/core_channel)%core_size);
                H2 <= ((next1+2)>core-1)? core_size-1: (((next1+2)/core_channel)/core_size);

                C3 <= ((next1+3)>core-1)? core_channel-1: ((next1+3)%core_channel);
                W3 <= ((next1+3)>core-1)? core_size-1: (((next1+3)/core_channel)%core_size);
                H3 <= ((next1+3)>core-1)? core_size-1: (((next1+3)/core_channel)/core_size);

                C4 <= ((next1+4)>core-1)? core_channel-1: ((next1+4)%core_channel);
                W4 <= ((next1+4)>core-1)? core_size-1: (((next1+4)/core_channel)%core_size);
                H4 <= ((next1+4)>core-1)? core_size-1: (((next1+4)/core_channel)/core_size);
            end
         else if(mask[H2 * colrng * core_channel + W2 * core_channel + C2 + bia] == 1)
            begin
                C1 <= ((next2+1)>core-1)? core_channel-1: ((next2+1)%core_channel);
                W1 <= ((next2+1)>core-1)? core_size-1: (((next2+1)/core_channel)%core_size);
                H1 <= ((next2+1)>core-1)? core_size-1: (((next2+1)/core_channel)/core_size);

                C2 <= ((next2+2)>core-1)? core_channel-1: ((next2+2)%core_channel);
                W2 <= ((next2+2)>core-1)? core_size-1: (((next2+2)/core_channel)%core_size);
                H2 <= ((next2+2)>core-1)? core_size-1: (((next2+2)/core_channel)/core_size);

                C3 <= ((next2+3)>core-1)? core_channel-1: ((next2+3)%core_channel);
                W3 <= ((next2+3)>core-1)? core_size-1: (((next2+3)/core_channel)%core_size);
                H3 <= ((next2+3)>core-1)? core_size-1: (((next2+3)/core_channel)/core_size);

                C4 <= ((next2+4)>core-1)? core_channel-1: ((next2+4)%core_channel);
                W4 <= ((next2+4)>core-1)? core_size-1: (((next2+4)/core_channel)%core_size);
                H4 <= ((next2+4)>core-1)? core_size-1: (((next2+4)/core_channel)/core_size);
            end
          else if(mask[H3 * colrng * core_channel + W3 * core_channel + C3 + bia] == 1)
            begin
                C1 <= ((next3+1)>core-1)? core_channel-1: ((next3+1)%core_channel);
                W1 <= ((next3+1)>core-1)? core_size-1: (((next3+1)/core_channel)%core_size);
                H1 <= ((next3+1)>core-1)? core_size-1: (((next3+1)/core_channel)/core_size);

                C2 <= ((next3+2)>core-1)? core_channel-1: ((next3+2)%core_channel);
                W2 <= ((next3+2)>core-1)? core_size-1: (((next3+2)/core_channel)%core_size);
                H2 <= ((next3+2)>core-1)? core_size-1: (((next3+2)/core_channel)/core_size);

                C3 <= ((next3+3)>core-1)? core_channel-1: ((next3+3)%core_channel);
                W3 <= ((next3+3)>core-1)? core_size-1: (((next3+3)/core_channel)%core_size);
                H3 <= ((next3+3)>core-1)? core_size-1: (((next3+3)/core_channel)/core_size);

                C4 <= ((next3+4)>core-1)? core_channel-1: ((next3+4)%core_channel);
                W4 <= ((next3+4)>core-1)? core_size-1: (((next3+4)/core_channel)%core_size);
                H4 <= ((next3+4)>core-1)? core_size-1: (((next3+4)/core_channel)/core_size);              
            end
           else begin
                C1 <= ((next4+1)>core-1)? core_channel-1: ((next4+1)%core_channel);
                W1 <= ((next4+1)>core-1)? core_size-1: (((next4+1)/core_channel)%core_size);
                H1 <= ((next4+1)>core-1)? core_size-1: (((next4+1)/core_channel)/core_size);

                C2 <= ((next4+2)>core-1)? core_channel-1: ((next4+2)%core_channel);
                W2 <= ((next4+2)>core-1)? core_size-1: (((next4+2)/core_channel)%core_size);
                H2 <= ((next4+2)>core-1)? core_size-1: (((next4+2)/core_channel)/core_size);

                C3 <= ((next4+3)>core-1)? core_channel-1: ((next4+3)%core_channel);
                W3 <= ((next4+3)>core-1)? core_size-1: (((next4+3)/core_channel)%core_size);
                H3 <= ((next4+3)>core-1)? core_size-1: (((next4+3)/core_channel)/core_size);

                C4 <= ((next4+4)>core-1)? core_channel-1: ((next4+4)%core_channel);
                W4 <= ((next4+4)>core-1)? core_size-1: (((next4+4)/core_channel)%core_size);
                H4 <= ((next4+4)>core-1)? core_size-1: (((next4+4)/core_channel)/core_size);                 
            end
      end
      
      else if(tail_edge_reg)begin
            C1 <= 0;
            W1 <= 0;
            H1 <= 0;
            C2 <= 1;
            W2 <= 0;
            H2 <= 0;
            C3 <= 2;
            W3 <= 0;
            H3 <= 0;
            C4 <= 3;
            W4 <= 0;
            H4 <= 0;
      end
    end
    
    assign ta = tail_edge_reg2&&(!tail_pic_reg);
    assign tail = (raddrw == core-1) ? 1 : 0;//一个卷积窗口计算完成标志
    assign tail_pic = (raddr == (core_size+stride)*colrng*core_channel-1) ? 1 : 0;//一个部分算完标志


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
            offset_W <= (offset_H == (group-1)*row -1 -core_size)  ? ((offset_W==colrng-core_size) ? 0 : (offset_W + stride)) : offset_W;
            offset_H <= (offset_H == (group-1)*row -1 -core_size) ? 0 : (offset_H + stride);//先行后列移动窗口
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
            bia <= offset_H * colrng * core_channel + offset_W * core_channel;
            //count <= count;
        end
        
        else if((raddr == (core_size+stride)*colrng * core_channel-1) && tail_edge_reg2 && (!wri))
          begin
            raddr <= 0;
            raddrw <= 0;
            //count <= count;
          end
        
        else if(a2d||tail_edge_reg2)
        begin//基于mask的跳过
          if(mask[H1 * colrng * core_channel + W1 * core_channel + C1 + bia] == 1)
            begin
                raddr <=  H1 * colrng * core_channel + W1 * core_channel + C1 + bia;
                raddrw <= H1 * core_size * core_channel + W1 * core_channel + C1;
                //count <= count;
            end
          else if(mask[H2 * colrng * core_channel + W2 * core_channel + C2 + bia] == 1)
            begin
                raddr <=  H2 * colrng * core_channel + W2 * core_channel + C2 + bia;
                raddrw <= H2 * core_size * core_channel + W2 * core_channel + C2;
                //count <= count + 1;
            end
          else if(mask[H3 * colrng * core_channel + W3 * core_channel + C3 + bia] == 1)
            begin
                raddr <=  H3 * colrng * core_channel + W3 * core_channel + C3 + bia;
                raddrw <= H3 * core_size * core_channel + W3 * core_channel + C3; 
                //count <= count + 2;            
            end
          else begin
                raddr <=  H4 * colrng * core_channel + W4 * core_channel + C4 + bia;
                raddrw <= H4 * core_size * core_channel + W4 * core_channel + C4;  
                
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
                    if(raddr_reg == (core_size+stride*(pool-1))*colrng*core_channel-1 && !wri)
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