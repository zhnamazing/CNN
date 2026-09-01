`timescale 1ns / 1ps
module axon_CNN #(parameter NUM_OF_CORE = 6,core_size = 5,colrng = 32,size = 64, stride = 1,row_sobel = 4,group = 4,row=2)(
    input clk,
    //input clk2x,
    input rst,
    input signed [15:0]din,
    input [10:0]waddr,//数据在输入图上的位置
    input wen,
    input start,
    input [9:0]raddr,//数据在子图上的位置
    input d2a,
    output logic signed [15:0]data_ad,
    output logic a2d,
    output logic [(group-1)*size-1:0]mask,
    output logic phase,
    output logic wri,
    output logic data_req
//    output logic [30:0] countz
);
    logic [size-1:0] mask_reg;
    logic signed [15:0]dfifo;
    logic valid1;
    logic valid2;
    logic [3:0] num1;
    logic [3:0] num2;
    logic flag;
    logic flag2;
    logic wr;
    logic rd;
    logic wr_reg;
    logic wr_reg2;
    logic wr_reg3;
    logic wr_reg4;
    logic wr_reg5;
    logic wr_reg6;
    logic [1:0] Num;//代表此周期哪一个buffer正在写入
    logic [1:0] Num_reg;
    logic [1:0] Num_reg2;
    logic [1:0] Num_reg3;
    logic [1:0] Num_reg4;
    logic signed [15:0] dout [3:0];
    logic [group-1:0] en_slow;
    logic [group-1:0] we_slow;
    logic [group-1:0] en_fast;
    logic [group-1:0] we_fast;
    logic [group-1:0] en;
    logic [group-1:0] we;

    logic [8:0] addr_slow [3:0];
    logic [8:0] addr_fast [3:0];
    logic [8:0] addr [3:0];   
    logic [7:0] add;
    logic [1:0] N;
    logic [1:0] N_reg;
    logic [1:0] N_reg2;
    logic [1:0] N_reg3;
    logic [1:0] N_reg4;
    logic [7:0] count_wr;//每次计数一个ram的大小，每轮清零

    logic [7:0] count_wr_reg;
    logic [7:0] count_wr_reg2;
    logic [7:0] count_wr_reg3;
    logic [7:0] count_wr_reg4;
    logic [7:0] count_wr_reg5;
    logic [7:0] count;
    logic [10:0] waddr_t;
    logic rd_reg;
    logic [1:0] wr_edge;
    logic [1:0] rd_edge;
    logic [1:0] wr_edge_reg;
    logic [1:0] rd_edge_reg;
    logic [9:0] raddr_reg;
    logic [9:0] raddr_reg2;
    logic [1:0] area;//从三个里面的哪个读取
    logic [1:0] loc;
    logic [1:0] loc_reg;
    logic [1:0] loc_reg2;
    logic [1:0] state_rd;
    logic [1:0] state_rd_reg;
    localparam [1:0]Wait_rd = 2'b01,Read = 2'b10;
    logic [2:0]state_wr;    
    logic [2:0]state_wr_reg;
    logic [2:0]state_wr_reg2;
    logic [2:0]state_wr_reg3;
    logic [2:0]state_wr_reg4;
    logic [2:0]state_wr_reg5;
    logic rden;
    logic [7:0] count_temp;
    logic signed [15:0] data_bram;
        
    localparam [2:0]Start_temp = 3'd000,Start = 3'd001,Writ_temp = 3'b010,Writ = 3'b011,Wait_wr = 3'b100;  
        
    assign rden = ((state_wr == Writ_temp)||(state_wr == Start_temp));
    assign wri = wr_reg5;
    
    always@(posedge clk)
      begin
        if(!rst)
          data_req <= 0;
        else begin
          if(((state_wr == Writ_temp)||(state_wr == Start_temp))&& start &&(count_temp <= colrng*(row_sobel-1)-5))
            data_req <= 1;
          else 
            data_req <= 0;
          end
        end

    pre_sobel #(colrng,row_sobel) u_sobel (
        .clk(clk),
        .rst(rst),
        .wen(wen),
        .waddr(waddr),
        .din(din),
        .state_wr(state_wr),
        .data_bram(data_bram),
        .count_temp(count_temp)
    );
    
    always @(posedge clk)
      if(!rst)
        begin
          N <= 2'd0;
        end
      else begin
        if((state_wr_reg == Start)&&(state_wr == Start_temp))       
          begin
            N <= N + 1;
          end
        else begin
          N <= N;
        end
      end

    assign  add = count_wr_reg4%size;
    
    always@(*)
      begin
        for(integer i=0; i <  group ; i=i+1)
          begin
            en[i] = (state_wr_reg5 == Start_temp || state_wr_reg5 == Start)? en_slow[i]:((i==Num_reg4)? en_slow[i] : en_fast[i]);
            we[i] = (state_wr_reg5 == Start_temp || state_wr_reg5 == Start)? en_slow[i]:((i==Num_reg4)?  we_slow[i] : we_fast[i]);
            addr[i] = (state_wr_reg5 == Start_temp || state_wr_reg5 == Start)? addr_slow[i]:(i==Num_reg4)?  addr_slow[i] : addr_fast[i];
          end
        end
            
    always@(posedge clk)
    begin
      if(!rst)
      begin
        en_slow <= 3'b000;
        we_slow <= 3'b000;
//        countz <= 0;
              
        for(integer i = 0; i < group; i = i + 1)
          addr_slow[i] <= 0;
      end
    else begin
      
//      if((|en_slow)&&(data_bram == 0))
//        countz <= countz + 1;
        
      
      if(state_wr_reg4 == Start) begin//第一次写入
            case(N_reg3)
              2'd0:begin
                en_slow <= 4'b0001;
                we_slow <= 4'b0001;
                addr_slow[0] <= add;
                addr_slow[1] <= 0;
                addr_slow[2] <= 0;
                addr_slow[3] <= 0;
                end
              2'd1:begin
                en_slow <= 4'b0010;
                we_slow <= 4'b0010;
                addr_slow[0] <= 0;
                addr_slow[1] <= add;
                addr_slow[2] <= 0;
                addr_slow[3] <= 0;
              end

               2'd2:begin
                en_slow <= 4'b0100;
                we_slow <= 4'b0100;
                addr_slow[0] <= 0;
                addr_slow[1] <= 0;
                addr_slow[2] <= add;
                addr_slow[3] <= 0;
              end
                
               default:begin
                en_slow <= 4'b1000;
                we_slow <= 4'b1000;
                addr_slow[0] <= 0;
                addr_slow[1] <= 0;
                addr_slow[2] <= 0;
                addr_slow[3] <= add;
                end

            endcase 
        end  
      
      else begin
        for(integer i=0;i<group;i=i+1)
          begin
          if((i==Num_reg3)&&(state_wr_reg4==Writ))
          begin
            en_slow[i] <= 1'b1;
            we_slow[i] <= 1'b1;
            addr_slow[i] <= count_wr_reg4%size;
          end
          else begin
            en_slow[i] <= 0;
            we_slow[i] <= 0;
            addr_slow[i] <= 0;
          end
        end
      end
    end
  end
  
  always@(posedge clk)
    begin
      if(!rst)
      begin
        en_fast <= 4'b0000;
        we_fast <= 4'b0000;
              
        for(integer i = 0; i < group; i = i + 1)
          addr_fast[i] <= 0;
      end
    else begin      
        for(integer i=0;i<group;i=i+1)
          begin
          if((i==loc)&&(state_rd_reg==Read))
          begin
            en_fast[i] <= 1;
            we_fast[i] <= 0;
            addr_fast[i] <= (raddr_reg)%size;
          end
          else begin
            en_fast[i] <= 0;
            we_fast[i] <= 0;
            addr_fast[i] <= 0;
          end
        end
      end
    end
    
    always@(posedge clk)
      begin
        loc <= (Num+(raddr/size)+1)%group;
        data_ad <= dout[loc_reg2];
      end
    
    always@(posedge clk)
      begin
        if(!rst) begin
          wr_reg <= 1'b0;
          wr_reg2 <= 1'b0;
          wr_reg3 <= 1'b0;
          wr_reg4 <= 1'b0;
          wr_reg5 <= 1'b0;
          wr_reg6 <= 1'b0;
          count_wr_reg <= 0;
          count_wr_reg2 <= 0;
          count_wr_reg3 <= 0;
          count_wr_reg4 <= 0;
          count_wr_reg5 <= 0;
          state_wr_reg <= Start_temp;
          state_wr_reg2 <= Start_temp;
          state_wr_reg3 <= Start_temp;
          state_wr_reg4 <= Start_temp;
          state_wr_reg5 <= Start_temp;
          N_reg <= 0;
          N_reg2 <= 0;
          N_reg3 <= 0;
          N_reg4 <= 0;
          Num_reg <= 0;
          Num_reg2 <= 0;
          Num_reg3 <= 0;
          Num_reg4 <= 0;
        end
        
        else begin
          wr_reg <= wr;
          wr_reg2 <= wr_reg;
          wr_reg3 <= wr_reg2;
          wr_reg4 <= wr_reg3;
          wr_reg5 <= wr_reg4;
          wr_reg6 <= wr_reg5;
          count_wr_reg <= count_wr;
          count_wr_reg2 <= count_wr_reg;
          count_wr_reg3 <= count_wr_reg2;
          count_wr_reg4 <= count_wr_reg3;
          count_wr_reg5 <= count_wr_reg4;
          state_wr_reg <= state_wr;
          state_wr_reg2 <= state_wr_reg;
          state_wr_reg3 <= state_wr_reg2;
          state_wr_reg4 <= state_wr_reg3;
          state_wr_reg5 <= state_wr_reg4;
          N_reg <= N;
          N_reg2 <= N_reg;
          N_reg3 <= N_reg2;
          N_reg4 <= N_reg3;
          Num_reg <= Num;
          Num_reg2 <= Num_reg;
          Num_reg3 <= Num_reg2;
          Num_reg4 <= Num_reg3;
        end
      end
      
    always@(posedge clk)
    begin
      if(!rst)
        begin
          rd_reg <= 1'b0;
          raddr_reg <=0;
          raddr_reg2 <=0;
          loc_reg<=0;
          loc_reg2<=0;
          state_rd_reg <= Wait_rd;
        end
      else begin
          rd_reg <= rd;
          raddr_reg <= raddr;
          raddr_reg2 <= raddr_reg;
          loc_reg <= loc;
          loc_reg2 <= loc_reg;
          state_rd_reg <= state_rd;
      end
    end
      
     always@(posedge clk)//写计数
      begin
        if(!rst)
          count_wr<=0;
        else begin 
          if(((state_wr == Start)||(state_wr == Writ)))
            begin
              if(count_wr == size-1)
                count_wr <= 8'd0;
              else
                count_wr <= count_wr +1;
            end
        end
      end
      
genvar j;      
generate
   for (j = 0; j < group; j = j + 1) 
     begin   
    bram_input your_instance_name (
      .clka(clk),    // input wire clka
      .ena(en[j]),      // input wire ena
      .wea(we[j]),      // input wire [0 : 0] wea
      .addra(addr[j]),  // input wire [8 : 0] addra
      .dina(data_bram),    // input wire [15 : 0] dina
      .douta(dout[j])  // output wire [15 : 0] douta
    );
   end
endgenerate  
        
    
    assign a2d =(d2a&&(!(rd_reg&&(!wr_reg))));
    
    always@(posedge clk)
      begin
        if(!rst)begin
            mask <= 192'b0;
            flag <= 0;
          end
          
        else if(state_wr_reg5 == Start)
          begin
                flag <= flag;
                mask[count_wr_reg5+N_reg4*size] <= (data_bram!=0);
          end
            

          else if(wr_reg5&&rd)
            begin
              if(!flag)
                begin
                  mask[(group-2)*size-1:0] <= mask[(group-1)*size-1:size];
                  mask[(group-1)*size-1:(group-2)*size] <= mask_reg[size-1:0];
                  flag <= 1;
                end
              else begin 
                  mask <= mask;
                  flag <= flag;
                end
            end

            else begin
              mask <= mask;
              flag <= 0;
            end
        end   
        
    always@(posedge clk)
      begin
        if(!rst)
          begin
            rd_edge <= 2'b00;
            wr_edge <= 2'b00;
            rd_edge_reg <= 2'b00;
            wr_edge_reg <= 2'b00;
          end
        else begin
            rd_edge <= {rd_edge[0],rd};
            wr_edge <= {wr_edge[0],wr};
            rd_edge_reg <= rd_edge;
            wr_edge_reg <= wr_edge;
        end
      end
    
    always@(posedge clk)
      begin
        if(!rst)
          begin
            Num<=group-1;//Num标记正在写入的bram
            flag2 <= 0;
          end
//        else if((rd_edge_reg == 2'b01&&wr_reg)||(wr_edge_reg == 2'b01&&rd_reg)) begin
        else if(rd && wr_reg5)
          begin
            if(!flag2)
              begin
                flag2 <= 1;
                  if(Num == group-1)
                    Num <= 0;
                  else
                    Num <= Num + 1;
              end
            else begin
              flag2 <= flag2;
              Num <= Num;
            end
        end
          else begin
            Num <= Num;
            flag2 <= 0;
          end
        end  
    
    always@(posedge clk)
      begin
        if(!rst)begin
            for (integer i=0;i<size;i=i+1)
              mask_reg[i] <= 0;
          end
        else if(state_wr_reg5 == Writ)
          mask_reg[count_wr_reg5%size] <= (data_bram != 0);
      end
    
    always@(posedge clk)
      begin
        if(!rst)
          phase = 1'b0;
        else if((wr_reg5 == 1)&&(N_reg4 == group-2))
          phase = 1'b1;
      end
            
    always@(posedge clk)//写状态机
    begin
        if(!rst)
        begin
            state_wr <= Start_temp;
            wr <= 1'b0;
        end
        else
            case(state_wr)
                Start_temp:
                begin                    
                    if(count_temp == colrng*(row_sobel-1)-1)//确保已经得到一个完整的输入图（部分）
                    begin
                        state_wr <= Start;
                        wr<=wr;
                    end
                    else
                    begin
                       state_wr <= Start_temp;
                       wr<=wr;
                    end
                end
                
                Start:
                begin                    
                    if(count_wr == (size-1)&&(N!=group-2))//确保已经得到一个完整的输入图（部分）
                    begin
                        state_wr <= Start_temp;
                        wr<=wr;
                    end
                    else if(count_wr == (size-1)&&(N==group-2))
                    begin
                        state_wr <= Writ_temp;
                        wr<=1'b1;
                    end
                    else
                    begin
                       state_wr <= Start;
                       wr<=wr;
                    end
                end                
                Writ_temp:
                begin
                    if(count_temp == colrng*(row_sobel-1)-1)//确保已经得到一个完整的输入图（部分）
                    begin
                        state_wr <= Writ;
                        wr<=0;
                    end
                    else
                    begin
                       state_wr <= Writ_temp;
                       wr<=0;

                    end
                end
                Writ:
                begin               
                    if(count_wr == (size-1))
                    begin
                        wr<=1;
                        state_wr<=Wait_wr;
                    end
                    else begin
                        state_wr <= Writ;
                        wr<=0;
                    end
                end
                Wait_wr:
                begin
                  if(rd)begin
                    state_wr <= Writ_temp;
                    wr <= 0;
                  end
                  else begin
                    state_wr <= Wait_wr;
                    wr<=wr;
                  end
                end
                default:begin
                    state_wr <= Wait_wr;
                    wr<=wr;
                  end
            endcase
    end
    
   always@(posedge clk)//读状态机
    begin
        if(!rst)
        begin
            state_rd <=Wait_rd;
            rd <= 1'b0;
        end
        else
            case(state_rd)
                Read:
                begin
                    if((raddr == ((core_size+stride)*colrng-1))&&d2a)
                    begin
                          rd <= 1;
                          state_rd <= Wait_rd;
                    end
                    
                    else if(rd)
                      begin
                            state_rd <= Wait_rd;
                            rd<=1;
                    end
                    
                    else begin   
                        state_rd <= Read;
                        rd<=rd;
                    end
                end                
                Wait_rd:
                begin
                    if((state_wr == Writ_temp)&&(wr_reg6==1))
                    begin
                        state_rd <= Read;
                        rd<=0;
                    end
                    else
                    begin
                        state_rd <= Wait_rd;
                        rd<=rd;
                    end
                end                 
                default:begin
                    state_rd <= Wait_rd;
                    rd<=rd;
                  end
            endcase
    end
endmodule