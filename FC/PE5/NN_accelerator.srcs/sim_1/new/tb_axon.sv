`timescale 1ns / 1ps

module tb_axon;
    
    reg clk;
    reg clk2x;
    reg rst;
    reg signed [15:0]din;
    reg [10:0]waddr;//数据在输入图上的位置
    reg wen;
    reg [9:0]raddr;//数据在子图上的位置
    reg d2a;
    reg start;
    
    wire logic signed [15:0]data_ad;
    wire logic a2d;
    wire logic [671:0]mask;
    
    wire [9:0] in_num = 672;
    wire phase;
    wire wri;

    wire data_req;
    reg data_req_reg;

    axon_CNN  #(.NUM_OF_CORE(32), .core_size(5), .colrng(14), .size(224), .stride(1), .row_sobel(0), .group(4), .row(2), .core_channel(8))
    test (
        .clk               (clk),
        .clk2x             (clk2x),
        .rst               (rst),
        .start             (start),
        .din               (din),
        .waddr             (waddr),
        .wen               (wen),
        .raddr             (raddr),
        .d2a               (d2a),
        .data_ad           (data_ad),
        .a2d               (a2d),
        .mask              (mask),
        .phase             (phase),
//        .countz            (countz),
        .wri               (wri),
        .data_req          (data_req)
    );
    
    reg signed [13:0] count;
    reg signed [13:0] count_fast;
    
    always #1 clk2x = ~clk2x;
    always #2 clk = ~clk;

    initial begin
       clk <=1;
       clk2x <= 1;
       rst <=0;
       count <=0;
       count_fast <= -1;
       wen <=0;
       d2a <=0;
       raddr <= 0;
       #1100 
       rst <=1;
       start <= 1;
    end
    
     always@(posedge clk)
         begin

            data_req_reg <= data_req;
        //  if(rst)begin
        //    if(count<3500)
        //       count <= count + 1;
        //    else
        //      $finish;
        //   end
            
          if(data_req_reg)
            begin
              count <= count + 1;
              wen<=1;
              waddr<=count;
              
              if((count == 3)||(count == 680)||(count==226))
                din <= 0;
              else
                din<=(count+1);

            end
          
          // else if((count>=2448)&&(count<2672))
          //   begin
          //     wen<=1;
          //     din<=(count-1551);
          //     waddr<=(count-1552);
          //   end
          
          // else if((count>=410)&&(count<500))
          //   begin
          //     wen<=1;
          //     din<=(count-199);
          //     waddr<=(count-200);
          //   end
            
          // else if((count>=1145)&&(count<1235))
          //   begin
          //     wen<=1;
          //     din<=(count-844);
          //     waddr<=(count-845);
          //   end
          
          else begin
              count <= count;
              wen<=0;
              din<=0;
              waddr<=0;
            end            

      end

     always@(posedge clk2x)
         begin
         if(rst)begin
           if(count_fast<7000)
              count_fast <= count_fast + 1;
           else
             $finish;
          end

          if((count_fast>=1352)&&(count_fast<5352))
            begin
              if((count_fast-1352)%28==25||(count_fast-1352)%28==26||(count_fast-1352)%28==27)
                d2a<=0;
              else
                d2a<=1;
                
              if(count_fast == 5351)
                raddr <= 671;
              else
                raddr<=((count_fast-1352)%671);
            end
          
          else if(count_fast>=5357)
            begin
              if((count_fast-5357)%28==25||(count_fast-5357)%28==26||(count_fast-5357)%28==27)
                d2a<=0;
              else
                d2a<=1;

              raddr<=((count_fast-5357)%671);
            end
          
          else begin
              d2a <= 0;
              raddr<=0;
          end     
        end
endmodule