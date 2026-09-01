`timescale 1ns / 1ps
module tb_for_test2#(parameter size = 64);
       
    reg clk;
    reg clk2x;
    reg rst;
    
    logic signed [14:0] count;
    logic [8:0] num;
    logic [7:0] waddr;
    logic v_to_router;
    logic signed [15:0] data;
    logic [10:0] addrout;
    logic [15:0] coreout;
    logic v_from_router;
    logic [13:0] raddr;
    logic [30:0] count2;
    
    logic led;
    logic mark;
    logic [10:0] loc;
    logic ren_out;
    logic start;
    logic signed [15:0] OFMb [size-1:0]; 

    logic signed [15:0] OFM [size-1:0];//32个数组，每个数组size个元素，每个元素是一个16位有符号数
    logic [5:0] addr [size-1:0]; 
    
    wire [5:0] router_ID = 16'b0000000000000001;
    wire [2:0]credit_r = 0;
    logic data_req;
    logic[47:0]from_router_flit;
    logic[47:0]to_router_flit;
    
    logic [47:0] ram [3072]; 

    initial $readmemh("C:/Users/zuohaonan/Desktop/PE4/NN_accelerator/source_CNN04.txt", ram);
    

    // 初始化数组

    // 写入逻辑
    task compare_arrays;
            begin
                for (int i = 0; i < size; i = i + 1) begin//逐个输出通道比较
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
    always#2.5 clk = ~clk;
    
    initial begin
      clk = 1;
      rst = 0;
      count = -1;
      v_from_router = 0;
      waddr = 0;
      num = 0;
      led = 0;
      
      for(int i=0 ; i <size ;i = i + 1)
        begin
          OFMb[i] = 16'd0;
        end
        
      for (int i = 0; i < size; i = i + 1)
          begin
              OFM[i]= 16'd0;
              addr[i]= 6'd0;
          end

        
      mark = 1;
      loc = 0;
    
    file_handle = $fopen("C:/Users/zuohaonan/Desktop/PE4/NN_accelerator/ofm_data04.txt", "r");
    i = 0;

    // 读取文件中的每个数，直到到达文件末尾
    while (i<size) begin
      // 读取一个32位的十六进制数
      $fscanf(file_handle, "%h\n", OFMb[i]);
      i = i + 1;
    end

    // 关闭文件
    $fclose(file_handle); // 关闭文件
        
      #1100 rst = 1;
      
     wait (num == size-1)
      begin
      #20
      
      compare_arrays(); 
        
        if(mark)
          led = 1;
        else
          led = 0;
      end
          
        #100 $finish;
    end
    
  always@(posedge clk)
     begin
       if(rst)begin
         if(count<2250)
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
           from_router_flit <= 0;
        end
        
        else begin 
          if(((count >= 0)&&(count < 2240))||(data_req && start && (raddr < 2273)))
            begin
              v_from_router <= 1;
              raddr <= raddr + 1;
              from_router_flit <= ram[raddr];
            end
            
//            else if(raddr == 2274)
//              begin
//                raddr <= 2242;
//                v_from_router <= v_from_router;
//              end
          
          else begin
              v_from_router <= 0;
              raddr <= raddr;
              from_router_flit <= 0;
            end
            
          if(count == 2250)
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
               num <= num + 1;
               waddr <= waddr;    
           end
         
         else begin
           num <= num;
           waddr <= waddr;
         end
   end

    pe  inst_pe (
        .clk               (clk),
        .rst               (rst),
        .start             (start),
        .from_router_flit  (from_router_flit),
        .v_from_router     (v_from_router),
        .to_router_flit    (to_router_flit),
        .v_to_router       (v_to_router),
        .credit_r          (credit_r),
        .ren_out           (ren_out),
        .data_req          (data_req)
        //.count             (count2)
//        .countz            (countz)
    );
    
    assign coreout = to_router_flit[45:30];
    assign data = to_router_flit[15:0];
    assign addrout = to_router_flit[26:16];
    
//    for_test2 u(
//      .clk(clk),
//      .rst(rst),
//      .start(start),
//      .count(count),
//      .raddr_in(raddr),
//      .dataout(data),
//      .v_from_router_in(v_from_router),
//      .v_to_router(v_to_router),
//      .addrout(addrout),
//      .coreout(coreout),
//      .ren_out(ren_out)
//      //.count2(count2)
////      .countz(countz)
//    );

endmodule