`timescale 1ns / 1ps
module soma_CNN #(parameter NUM_OF_CORE = 32,core_size = 5,colrng = 14, pool = 2, cut_type = 0)(
    input clk,
    //input clk2x,
    input rst,
    input d2s,
    input signed [39:0]data_ds,
    input signed [15:0]in_bias,    
    input phase,
    
    input v_bias,
    //input d2s,
    input r2s,
    
    output logic signed [15:0]from_core_data,
    output logic [10:0]from_core_addr,
    output logic s2d,
    output logic v_from_core
);    
    logic signed [15:0]dcut;
    logic signed [15:0]dlut;
    logic signed [15:0]data_fin;
    logic signed [39:0]data_f;    
    logic v_from_core_reg;
    logic valid1;
    logic valid2;
    logic empty1;
    logic empty2;
    logic full1;
    logic full2;   
    logic [4:0]addrb;
    logic [4:0]waddrb;
    logic en_bias1;
    logic en_bias2;
    logic en_bias3;    
    logic signed [15:0]bias;
    logic signed [39:0]dacc;//加偏置后截断前的数据    
    logic signed [15:0] pool_weight;
    logic signed [39:0] pool_bias;    
    logic d2s_reg;
    logic d2s_reg2;
    logic d2s_reg3;
    logic signed [39:0]data_ds_reg;
    logic [4:0] chan;
    logic [10:0] core_addr;
    
    logic [3:0] Ne;//池化后部分（行折叠）输出图上的位置
    logic [3:0] Ge;
    logic [9:0] location;//整体输出图上的位置    
    logic [9:0] loc;//整体输出图上的位置 
    logic [4:0] cnt_core;//记录此刻输入对应的卷积核
    logic [3:0] cnt_loc;//记录池化窗口中的数据数量
    logic [4:0] cnt_reg;
    logic [4:0] cnt_reg2;
    logic [4:0] cnt_reg3;
    logic [3:0] cnt_loc_reg;
    logic [3:0] cnt_loc_reg2;
    logic [3:0] cnt_loc_reg3;
    wire [31:0] result;
    
    logic wen;
    logic wen_reg;
    logic [10:0] loc_reg; 
    logic signed [39:0] pool_win [NUM_OF_CORE-1:0];//存储截断后的结果，准备池化

    assign en_bias1 = v_bias ? 1 : d2s;
    assign addrb = v_bias ? waddrb : cnt_core;//每个卷积核一个权重，故这里的读地址是卷积核编号


//bram_bias u_bram_bias (
//  .clka(clk),    // input wire clka
//  .ena(v_bias),      // input wire ena
//  .wea(v_bias),      // input wire [0 : 0] wea
//  .addra(waddrb),  // input wire [2 : 0] addra
//  .dina(in_bias),    // input wire [39 : 0] dina
//  .clkb(clk2x),    // input wire clkb
//  .enb(d2s),      // input wire enb
//  .addrb(cnt_core),  // input wire [2 : 0] addrb
//  .doutb(bias)  // output wire [39 : 0] doutb
//);

bram_bias your_instance_name (
  .clka(clk),    // input wire clka
  .ena(en_bias1),      // input wire ena
  .wea(v_bias),      // input wire [0 : 0] wea
  .addra(addrb),  // input wire [4 : 0] addra
  .dina(in_bias),    // input wire [39 : 0] dina
  .douta(bias)  // output wire [39 : 0] douta
);

    assign v_from_core = wen_reg;
    assign s2d = (~d2s) & phase;
    
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

    //generate fifo
//fifo_data u_fifo_data (
//  .wr_clk(clk),  // input wire wr_clk
//  .rd_clk(clk),  // input wire rd_clk
//  .din(data_fin),        // input wire [15 : 0] din
//  .wr_en(wen_reg),    // input wire wr_en
//  .rd_en(r2s),    // input wire rd_en
//  .dout(from_core_data),      // output wire [15 : 0] dout
//  .full(),      // output wire full
//  .empty(empty1)    // output wire empty
//);
//
//fifo_addr u_fifo_addr (
//  .wr_clk(clk),  // input wire wr_clk
//  .rd_clk(clk),  // input wire rd_clk
//  .din(loc_reg),        // input wire [9 : 0] din
//  .wr_en(wen_reg),    // input wire wr_en
//  .rd_en(r2s),    // input wire rd_en
//  .dout(core_addr),      // output wire [9 : 0] dout
//  .full(),      // output wire full
//  .empty(empty2)    // output wire empty
//);

    assign from_core_data = data_fin;
    assign from_core_addr = loc_reg;
    
    always@(posedge clk)
    begin
        if(!rst)
        begin
              d2s_reg <= 1'b0;
              d2s_reg2 <= 1'b0;
              d2s_reg3 <= 1'b0;
              data_ds_reg <= 0;
              v_from_core_reg<=1'b0;
              wen_reg <= 1'b0;
              loc_reg <= 0;
              location <= 0;
        end
        else
        begin
            d2s_reg <= d2s;
            d2s_reg2<=d2s_reg;
            d2s_reg3<=d2s_reg2;
            data_ds_reg <= data_ds;
            v_from_core_reg<=v_from_core;
            wen_reg <= wen;
            loc_reg <= location*NUM_OF_CORE+chan;
            location <= loc;
        end    
    end
          
    always@(posedge clk)
      begin
        if(!rst)
          begin
            cnt_core <= 0;
            cnt_loc <= 0;
          end
        else
        begin
          if(d2s)
            if(cnt_core < NUM_OF_CORE-1)
              begin
                cnt_core <= cnt_core + 1;
                cnt_loc <= cnt_loc;
              end
            else
              begin
                  cnt_core <= 0;
                  if(cnt_loc< pool*pool-1)//一个池化窗口中的四个位置
                        cnt_loc <= cnt_loc + 1;
                  else
                    cnt_loc<= 0;
              end
          else
            begin
              cnt_core <= cnt_core;
              cnt_loc <= cnt_loc;
            end
        end
      end
      
    always@(posedge clk) begin
      if(!rst)
        begin
            Ne<=0;
            Ge<=0;
        end
      else if((cnt_loc_reg3==pool*pool-1)&&(cnt_loc_reg2==0))
        begin
          if(Ne<(((colrng-core_size+1)/pool)-1)) begin
            Ne<=Ne+1;
            Ge<=Ge;
          end
          
          else begin
            Ne<=0;
            Ge<=Ge+1;
          end
        end
      else
        begin
            Ne<=Ne;
            Ge<=Ge;
      end//得到一张完整输出图上的位置
    end
      
    always@(posedge clk)
    begin
      if(!rst)begin
        cnt_reg <= 0;//延迟一个周期，用于池化
        cnt_reg2<=0;//赋值后延迟清零
        cnt_reg3<=0;
      end
      else
          begin
            cnt_reg <= cnt_core;//延迟一个周期，用于池化
            cnt_reg2<=cnt_reg;//赋值后延迟清零
            cnt_reg3<=cnt_reg2;
          end
    end
    
    always@(posedge clk)
      begin
          if(!rst)
          begin
              cnt_loc_reg <= 0;
              cnt_loc_reg2 <= 0;
              cnt_loc_reg3 <= 0;
          end
          else begin
              cnt_loc_reg <= cnt_loc;
              cnt_loc_reg2 <= cnt_loc_reg;
              cnt_loc_reg3 <= cnt_loc_reg2;
          end
    end
    
    assign dacc = data_ds_reg + bias;
    
    //cut
    cut_u cut_conv(clk,dacc,cut_type,dcut);
    
    assign dlut = (dcut>0)?dcut:0;
    
    always@(posedge clk)
    begin
      if(!rst)begin
      for(integer i=0; i< NUM_OF_CORE;i=i+1)
          pool_win[i] <= 0;    
      end
      
      else if(d2s_reg2)
        begin
          pool_win[cnt_reg2] <= (dlut>pool_win[cnt_reg2]) ? dlut : pool_win[cnt_reg2];
      end
      
      if((cnt_loc_reg3 == pool*pool-1)&&d2s_reg3)
           pool_win [cnt_reg3] <= 0; 
    end
    
    always@(posedge clk)
    begin
      if(!rst)
          data_f <= 0;
      else
        begin
          if((cnt_loc_reg3 == pool*pool-1)&&d2s_reg3)
            begin
                  data_f <= pool_win[cnt_reg3];
               end
           else
             data_f <= data_f;
       end
     end

    always@(posedge clk)
      begin
        if(!rst)
          wen <= 1'b0;
        else begin
          if((cnt_loc_reg3==pool*pool-1)&&(d2s_reg3))
            wen <= 1'b1;
          else
            wen <= 1'b0;
        end
      end
    
    cut_u cut_pool(clk,data_f,cut_type,data_fin);

    always@(posedge clk)
      begin
        if(!rst)
          begin
            loc <= 0;
            chan <= 0;
          end
        else begin
          loc <= Ge*((colrng-core_size+1)/pool)+Ne;
          chan <= cnt_reg3;
        end
      end
    
endmodule