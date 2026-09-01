`timescale 1ns / 1ps
module tb_for_test_timing#(parameter output_row = 1, output_col = 1,NUM_OF_CORE = 32);
    
    localparam [7:0] size = output_row*output_col;
    
    reg clk;
    reg clk2x;
    reg rst;
    
    logic signed [14:0] count;
    logic [4:0] num;
    logic [7:0] waddr;
    logic v_to_router;
    logic signed [15:0] data;
    logic [10:0] addrout;
    logic [15:0] coreout;
    logic v_from_router;
    logic [13:0] raddr;
    
    logic led;
    logic mark;
    logic [10:0] loc;
    logic ren_out;
    logic start;
    logic signed [15:0] OFMb [31:0]; 

    logic signed [15:0] OFM [31:0];//32个数组，每个数组size个元素，每个元素是一个16位有符号数
    logic [10:0] addr [31:0]; 

    // 初始化数组

    // 写入逻辑
    task compare_arrays;
            begin
                for (int i = 0; i < 32; i = i + 1) begin//逐个输出通道比较
                        if ((OFMb[i] != OFM[i]) || (addr[i]!= i))//输出编址通道优先
                        begin
                            #10
                            mark <= 0;  // 拉低 mark 信号
                            loc <= i;  // 记录不匹配的位置
                        end

                end
            end
        endtask
    

    
    integer i;
    integer file_handle;
    
    assign ren_out = 1;
    always#5 clk = ~clk;
    always#2.5 clk2x = ~clk2x;
    
    initial begin
      clk = 1;
      clk2x = 1;
      rst = 0;
      count = -1;
      v_from_router = 0;
      waddr = 0;
      num = 0;
      led = 0;
      
      for(int i=0 ; i <32 ;i = i + 1)
        begin
          OFMb[i] = 16'd0;
        end
        
      for (int i = 0; i < 32; i = i + 1)
          begin
              OFM[i]= 16'h0;
              addr[i]= 11'h0;
          end

        
      mark = 1;
      loc = 0;
    
    file_handle = $fopen("C:/Users/zuohaonan/Desktop/NN_accelerator/ofm_data03.txt", "r");
    i = 0;

    // 读取文件中的每个数，直到到达文件末尾
    while (i<NUM_OF_CORE*size) begin
      // 读取一个32位的十六进制数
      $fscanf(file_handle, "%h\n", OFMb[i]);
      i = i + 1;
    end

    // 关闭文件
    $fclose(file_handle); // 关闭文件
        
      #1100 rst = 1;
      
      #120000
      
      compare_arrays(); 
      
        #176
        
        if(mark)
          led = 1;
        else
          led = 0;
          
        #100 $finish;
    end
    
  always@(posedge clk)
     begin
       if(rst)begin
         if(count<9500)
            count <= count + 1;
         else
           count <= count;
       end
     end
     
   always@(posedge clk)
       begin
         if(!rst) begin
           raddr <= 0;
           v_from_router <= 0;
           start <= 0;
        end
        
        else begin 
          if((count >= 0)&&(count < 9313))
            begin
              v_from_router <= 1;
              raddr <= raddr + 1;
            end
          
          else begin
              v_from_router <= 0;
              raddr <= raddr;
            end
            
          if(count == 9350)
            start <= 1;
            
          end
        end

    always @(negedge clk)
      begin
       if(v_to_router)
            begin
                OFM[num] <= data;
                addr[num] <= addrout;
            end
    end
     
   always@(negedge clk)
     begin
         if(v_to_router)
           begin
             if(num<NUM_OF_CORE-1)
             begin
               num <= num + 1;
               waddr <= waddr;
             end
             else begin
               num <= 0;
               waddr <= waddr+1;
             end          
           end
         
         else begin
           num <= num;
           waddr <= waddr;
         end
   end

    
    for_test u(
      .clk(clk),
      .clk2x(clk2x),
      .rst(rst),
      .start(start),
      .count(count),
      .raddr_in(raddr),
      .dataout(data),
      .v_from_router_in(v_from_router),
      .v_to_router(v_to_router),
      .addrout(addrout),
      .coreout(coreout),
      .ren_out(ren_out)
//      .count2(count2),
//      .countz(countz)
    );

endmodule