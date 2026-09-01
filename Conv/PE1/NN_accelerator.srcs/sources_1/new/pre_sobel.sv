`timescale 1ns / 1ps
module pre_sobel #(parameter colrng = 32, row_sobel = 4)(
    input clk,
    input rst,
    input wen,
    input [10:0] waddr,
    input signed [15:0] din,
    input [2:0] state_wr,
    output logic signed [15:0] data_bram,
    output logic [7:0] count_temp
);
    logic signed [15:0] din_reg;
    logic [7:0] count;
    logic [9:0] temp_size;
    logic signed [15:0] data_wr;
    logic signed [15:0] data_x;
    logic signed [15:0] data_y;
    logic signed [15:0] data_wrp;
    logic signed [15:0] data_xp;
    logic signed [15:0] data_yp;
    logic WE;//双口ram的读写控制
    logic [row_sobel-1:0] EN;  
    logic signed [15:0] threshold = 24;  //原本的中位数是24 
    
    logic [2:0]state_wr_reg;
    logic [2:0]state_wr_reg2;
    logic [2:0]state_wr_reg3;
    logic [2:0]state_wr_reg4;
    
    logic signed [15:0] temp_up;
    logic signed [15:0] temp_down;
    logic signed [15:0] porta [row_sobel-1:0];
    logic signed [15:0] portb [row_sobel-1:0];
    logic [5:0] addra;
    logic [5:0] addrb;
    
    logic signed [15:0] a;
    logic signed [15:0] b;
    logic signed [15:0] c;
    logic signed [15:0] d;
    logic signed [15:0] e;
    logic signed [15:0] f;
    logic signed [15:0] g;
    logic signed [15:0] h;
    logic signed [15:0] k;
    logic signed [15:0] A;
    logic signed [15:0] B;
    logic signed [15:0] t1;
    logic signed [15:0] t2;
    
    logic signed [15:0] data_xab;
    logic signed [15:0] data_yab;

    logic [7:0] addr_temp;//一直累加，是输入图上的绝对位置（加colrng）
    logic [7:0] addr_t;
    logic [7:0] addr_t_reg;
    logic [7:0] addr_t_reg2;
    
    logic [2:0] pos1;
    logic [2:0] pos2;
    logic [2:0] pos3;
    
    logic signed [15:0] c_temp;
    logic signed [15:0] d_temp;
   
    localparam [2:0]Start_temp = 3'd000,Start = 3'd001,Writ_temp = 3'b010,Writ = 3'b011,Wait_wr = 3'b100;  
    
    always@(posedge clk)
      begin
        if(!rst) begin
          state_wr_reg <= Start_temp;
          state_wr_reg2 <= Start_temp;
          state_wr_reg3 <= Start_temp;
          state_wr_reg4 <= Start_temp;
          addr_t <= 0;
          addr_t_reg <= 0;
          addr_t_reg2 <= 0;
          count_temp <= 0;
          din_reg <= 0;
        end
        
        else begin
          state_wr_reg <= state_wr;
          state_wr_reg2 <= state_wr_reg;
          state_wr_reg3 <= state_wr_reg2;
          state_wr_reg4 <= state_wr_reg3;
          addr_t <= addr_temp;
          addr_t_reg <= addr_t;
          addr_t_reg2 <= addr_t_reg;
          count_temp <= count;
          din_reg <= din;
        end
      end
    
    assign temp_size = row_sobel*colrng;
    
    
    always@(posedge clk)
      begin
        if(!rst)
          begin
            addra <= 0;
            addrb <= 0;
          end
      else begin
        if((state_wr == Writ_temp)||(state_wr == Start_temp))
          begin
            addra <= waddr%colrng;
            addrb <= 0;
          end
        else if((state_wr == Writ)||(state_wr == Start))
          begin
            addra <= (((addr_temp)%colrng == 0)?(addr_temp)%colrng:(addr_temp-1)%colrng);
            addrb <= (addr_temp+1)%colrng;
          end
        else begin
          addra <= addra;
          addrb <= addrb;
        end
      end
    end
    
    
    always@(posedge clk)
      begin
        if(!rst)
          begin
            EN <= 6'b0;
            WE <= 1'b0;
          end
        else begin
          for(integer i = 0; i< row_sobel ;i = i+1)
            begin
              WE <= ((state_wr == Start_temp)||(state_wr == Writ_temp));
              
              if(((state_wr == Start_temp)||(state_wr == Writ_temp)))
                begin
                  if(wen&&((((waddr+colrng)/colrng)%row_sobel)==i))
                    EN[i] <= 1'b1;
                  else
                    EN[i] <= 1'b0;
                end
              else if(((state_wr == Start)||(state_wr == Writ)))
                EN[i] <= 1'b1;
              else
                EN[i] <= 1'b0;
            end
          end
      end
        
genvar i;
generate
    for (i = 0; i < row_sobel; i = i + 1) 
      begin
    bram_sobel u_bram_sobel (
      .clka(clk),    // input wire clka
      .ena(EN[i]),      // input wire ena
      .wea(WE),      // input wire [0 : 0] wea
      .addra(addra),  // input wire [4 : 0] addra
      .dina(din_reg),    // input wire [15 : 0] dina
      .douta(porta[i]),  // output wire [15 : 0] douta
      .clkb(clk),    // input wire clkb
      .enb(EN[i]),      // input wire enb
      .web(1'b0),      // input wire [0 : 0] web
      .addrb(addrb),  // input wire [4 : 0] addrb
      .dinb(),    // input wire [15 : 0] dinb
      .doutb(portb[i])  // output wire [15 : 0] doutb
    );
    end
endgenerate

    assign c_temp = {{4{c[11]}},c[11:0]};
    assign d_temp = {{4{d[11]}},d[11:0]};

    always@(posedge clk)
      begin
        if(!rst)
          begin
            temp_up <= 0;
            temp_down <= 0;
          end
        else begin
            temp_up <= portb[((addr_t_reg/colrng)+3)%4];
            temp_down <= portb[((addr_t_reg/colrng)+1)%4];
          end
       end

    always@(posedge clk)
      begin
        if(!rst)
            addr_temp <= colrng;
        else begin
          if(((state_wr == Start)||(state_wr == Writ)))
            begin
              if(addr_temp == temp_size - 1)
                addr_temp <= 0;
              else
                addr_temp <= addr_temp + 1;
            end
          else
            addr_temp <= addr_temp;
        end
      end  
      
    always @(posedge clk)
      begin
        if(!rst)
          begin
            count<=0;
          end
        else begin
          if(wen&&((state_wr == Start_temp)||(state_wr == Writ_temp)))
              begin   
              if(count == colrng*(row_sobel-1)-1)//第一轮之后每次仅需多读进三行
                  count <= colrng;
              else
                  count <= count +1;
              end
              else begin
                count <= count;
              end
        end
      end    
      
      always@(posedge clk)
        begin
          if(!rst)
            begin
              pos1 <= 0;
              pos2 <= 0;
              pos3 <= 0;
            end
          else begin
            if((state_wr_reg == Start)||(state_wr_reg == Writ))
              begin
                  pos1 <= ((addr_t/colrng)+3)%4;
                  pos2 <= (addr_t/colrng)%4;
                  pos3 <= ((addr_t/colrng)+1)%4;
              end
            else begin
                  pos1 <= 0;
                  pos2 <= 0;
                  pos3 <= 0;
                end
              end
            end
        
        always@(posedge clk)
          begin
            if(!rst)
              begin
                a <= 0;
                b <= 0;
                c <= 0;
                d <= 0;
                e <= 0;
                f <= 0;
                g <= 0;
                h <= 0;
                k <= 0;
                A <= 0;
                B <= 0;   
              end
            else if((state_wr_reg2 == Start)||(state_wr_reg2 == Writ))
              begin
                a <= porta[pos1] - portb[pos3];
                b <= portb[pos1] - porta[pos3];
                c <= temp_up - temp_down;
                d <= portb[pos2] - porta[pos2];
                e <= porta[pos1] + porta[pos3];
                f <= portb[pos1] + portb[pos3];
                g <= porta[pos1] - porta[pos3];
                h <= portb[pos1] - portb[pos3];
                k <= porta[pos1] - porta[pos3];
                A <= portb[pos2];
                B <=  - porta[pos2];   
              end
            else begin
                a <= 0;
                b <= 0;
                c <= 0;
                d <= 0;
                e <= 0;
                f <= 0;
                g <= 0;
                h <= 0;
                k <= 0;
                A <= 0;
                B <= 0;   
            end
           end
              
            assign t1 = b-a;
            assign t2 = a+b; 

      always@(posedge clk)
        begin
          if(!rst)
          begin
            data_x <= 0;
            data_y <= 0;
          end
          else if((state_wr_reg3 == Start)||(state_wr_reg3 == Writ))
          begin
            if((addr_t_reg2)%colrng == 0)
              begin
                data_x <= f + 2*A;
                data_y <= h + 2*k;
              end
            else if((addr_t_reg2)%colrng == (colrng-1))
              begin
                data_x <= 2*B - e;
                data_y <= g + 2*c_temp;
              end
            else
              begin
                data_x <= t1 + 2*d_temp;
                data_y <= t2 + 2*c_temp;              
              end
          end
          else begin
              data_x <= 0;
              data_y <= 0;
          end
        end

        always@(posedge clk)
          begin
            if(!rst)
              data_wr <= 0;
            else if((state_wr_reg4 == Start)||(state_wr_reg4 == Writ))
              data_wr <= data_xab + data_yab;
            else
              data_wr <= 0;
          end
          
      assign data_xab = data_x >0?data_x:-data_x;
      assign data_yab = data_y >0?data_y:-data_y;
      assign data_bram = (data_wr>threshold) ? data_wr : 16'd0;
    
endmodule