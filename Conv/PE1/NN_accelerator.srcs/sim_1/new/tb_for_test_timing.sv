`timescale 1ns / 1ps
module tb_for_test_timing#(parameter output_row = 14, output_col = 14,NUM_OF_CORE = 8);
    
    localparam [7:0] size = output_row*output_col;
    
    reg clk;
    reg rst;
    
    logic signed [14:0] count;
    logic [2:0] num;
    logic [7:0] waddr;
    logic v_to_router;
    logic signed [15:0] data;
    logic [10:0] addrout;
    logic [15:0] coreout;
    logic v_from_router;
    logic [10:0] raddr;
    
    logic [30:0] count2;
    
    logic led;
    logic mark;
    logic [10:0] loc;
    logic ren_out;
    logic start;
    logic data_req;
    
    logic signed [15:0] OFM [NUM_OF_CORE*size-1:0]; 
    logic [47:0]from_router_flit;
    logic [47:0]to_router_flit;
    
    logic signed [15:0] OFM1 [size-1:0]; 
    logic signed [15:0] OFM2 [size-1:0]; 
    logic signed [15:0] OFM3 [size-1:0]; 
    logic signed [15:0] OFM4 [size-1:0]; 
    logic signed [15:0] OFM5 [size-1:0]; 
    logic signed [15:0] OFM6 [size-1:0];   
    logic signed [15:0] OFM7 [size-1:0]; 
    logic signed [15:0] OFM8 [size-1:0];  
    
    logic [10:0] addr1 [size-1:0];
    logic [10:0] addr2 [size-1:0];
    logic [10:0] addr3 [size-1:0];
    logic [10:0] addr4 [size-1:0];
    logic [10:0] addr5 [size-1:0];
    logic [10:0] addr6 [size-1:0];
    logic [10:0] addr7 [size-1:0];
    logic [10:0] addr8 [size-1:0];
    
    integer i;
    integer file_handle;
    
    wire [5:0] router_ID = 16'b0000000000000001;
    wire [2:0]credit_r = 0;
    
    assign ren_out = 1;
    always#2.5 clk = ~clk;

    logic [47:0] ram [2048]; 

    initial $readmemh("C:/Users/zuohaonan/Desktop/PE1/NN_accelerator/source_CNN01.txt", ram);
    
    
    always@(posedge clk)
      begin
        if(!rst)
          from_router_flit <= 0;
        else
          from_router_flit <= ram[raddr];
      end
    
    initial begin
      clk = 1;
     // clk2x = 1;
      rst = 0;
      count = -1;
      v_from_router = 0;
      waddr = 0;
      num = 0;
      led = 0;
      
      for(i=0 ; i<NUM_OF_CORE*size ;i = i + 1)
        begin
          OFM[i] = 16'd0;
        end
        
      mark = 1;
      loc = 0;
      
    
    file_handle = $fopen("C:/Users/zuohaonan/Desktop/PE1/NN_accelerator/ofm_data01.txt", "r");
//    file_handle = $fopen("../../../../ofm_data01.txt", "r");
    i = 0;

    // 读取文件中的每个数，直到到达文件末尾
    while (i<NUM_OF_CORE*size) begin
      // 读取一个32位的十六进制数
      $fscanf(file_handle, "%h\n", OFM[i]);
      i = i + 1;
    end

    // 关闭文件
    $fclose(file_handle); // 关闭文件
        
      #1100 rst = 1;

    wait (waddr == size-1 && num == NUM_OF_CORE-1)
      begin
      #20
      for (i = 0;i < NUM_OF_CORE*size; i = i + 1)
      begin
      #10
         if((i>=0)&&(i<size))
          begin
//            if((OFM[i] != OFM1[i])||(addr1[i]!=i)||(chan1[i]!=0))
         if((OFM[i] != OFM1[i])||(addr1[i]!=i*NUM_OF_CORE))  
            begin
              mark <= 0;
              loc <= i;
            end
          end
        
        else if((i>=size)&&(i<2*size))
          begin
          
          if((OFM[i] != OFM2[i-size])||(addr2[i-size]!=(i-size)*NUM_OF_CORE+1))
//            if((OFM[i] != OFM2[i-size])||(addr2[i-size]!=(i-size))||(chan2[i-size]!=1))
            begin
              mark <= 0;
              loc <= i;
            end
          end
          
         else if((i>=2*size)&&(i<3*size))
          begin
          if((OFM[i] != OFM3[i-2*size])||(addr3[i-2*size]!=(i-2*size)*NUM_OF_CORE+2))
//            if((OFM[i] != OFM3[i-2*size])||(addr3[i-2*size]!=(i-2*size))||(chan3[i-2*size]!=2))
            begin
              mark <= 0;
              loc <= i;
            end
          end
          
          else if((i>=3*size)&&(i<4*size))
          begin
            if((OFM[i] != OFM4[i-3*size])||(addr4[i-3*size]!=(i-3*size)*NUM_OF_CORE+3))
//            if((OFM[i] != OFM4[i-3*size])||(addr4[i-3*size]!=(i-3*size))||(chan4[i-3*size]!=3))
            begin
              mark <= 0;
              loc <= i;
            end
          end
          
          else if((i>=4*size)&&(i<5*size))
          begin
            if((OFM[i] != OFM5[i-4*size])||(addr5[i-4*size]!=(i-4*size)*NUM_OF_CORE+4))
//            if((OFM[i] != OFM5[i-4*size])||(addr5[i-4*size]!=(i-4*size))||(chan5[i-4*size]!=4))
            begin
              mark <= 0;
              loc <= i;
            end
          end
          
          else if((i>=5*size)&&(i<6*size))
          begin
            if((OFM[i] != OFM6[i-5*size])||(addr6[i-5*size]!=(i-5*size)*NUM_OF_CORE+5))
//            if((OFM[i] != OFM6[i-5*size])||(addr6[i-5*size]!=(i-5*size))||(chan6[i-5*size]!=5))
            begin
              mark <= 0;
              loc <= i;
            end
          end
          
          else if((i>=6*size)&&(i<7*size))
          begin
            if((OFM[i] != OFM7[i-6*size])||(addr7[i-6*size]!=(i-6*size)*NUM_OF_CORE+6))
//            if((OFM[i] != OFM7[i-6*size])||(addr7[i-6*size]!=(i-6*size))||(chan7[i-6*size]!=6))
            begin
              mark <= 0;
              loc <= i;
            end
          end
          
          else if((i>=7*size)&&(i<8*size))
          begin
//            if((OFM[i] != OFM8[i-7*size])||(addr8[i-7*size]!=(i-7*size))||(chan8[i-7*size]!=7))
            if((OFM[i] != OFM8[i-7*size])||(addr8[i-7*size]!=(i-7*size)*NUM_OF_CORE+7))
            begin
              mark <= 0;
              loc <= i;
            end
          end
          
         end
        if(mark)
          led = 1;
        else
          led = 0;
          
        #100 $finish;
       end
    end
    
  always@(posedge clk)
     begin
       if(rst)begin
         if(count<3500)
            count <= count + 1;
         else
           count <= count;
       end
     end
     
   //assign v_from_router = ((count >= 1)&&(count < 225) || (data_req && start && (raddr < 1279))) ? 1 : 0;
     
   always@(posedge clk)
       begin
         if(!rst) begin
           raddr <= 0;
           start <= 0;
           v_from_router <= 0;
        end
        
        else begin 
          if(((count >= 0)&&(count < 225)) || (data_req && start && (raddr < 1280)))
            begin
              v_from_router <= 1;
              raddr <= raddr + 1;
            end
            
        else if(raddr == 1280)
          begin
            raddr <= 225;
            v_from_router <= v_from_router;
          end

          else begin
            raddr <= raddr;
            v_from_router <= 0;
          end
            
//          else begin
//              raddr <= raddr;
//              v_from_router <= 0;
//            end
            
          if(count == 240)
            start <= 1;
          else
            start <= start;
          end
        end     
     
   always@(posedge clk)
     begin
       if(!rst)begin
               
      for(integer i = 0; i < size; i=i+1)begin
          OFM1 [i] <= 16'd0;
          OFM2 [i] <= 16'd0;
          OFM3 [i] <= 16'd0;
          OFM4 [i] <= 16'd0;
          OFM5 [i] <= 16'd0;
          OFM6 [i] <= 16'd0;
          OFM7 [i] <= 16'd0;
          OFM8 [i] <= 16'd0;
          
          addr1 [i] <= 10'd0;
          addr2 [i] <= 10'd0;
          addr3 [i] <= 10'd0;
          addr4 [i] <= 10'd0;
          addr5 [i] <= 10'd0;
          addr6 [i] <= 10'd0;
          addr7 [i] <= 10'd0;
          addr8 [i] <= 10'd0;
        end
      end
      
      else begin
       if(v_to_router)begin
       case(num)
        0:begin
          OFM1[waddr] <=data;
          addr1[waddr]<=addrout;
        end
          
        1:begin
          OFM2[waddr] <=data;
          addr2[waddr]<=addrout;
        end
        
        2:begin
          OFM3[waddr] <=data;
          addr3[waddr]<=addrout;
        end
        
        3:begin
          OFM4[waddr] <=data;
          addr4[waddr]<=addrout;
        end        
        
        4:begin
          OFM5[waddr] <=data;
          addr5[waddr]<=addrout;
        end
        
        5:begin
          OFM6[waddr] <=data;
          addr6[waddr]<=addrout;
        end
 
        6:begin
          OFM7[waddr] <=data;
          addr7[waddr]<=addrout;
        end
        
        7:begin
          OFM8[waddr] <=data;
          addr8[waddr]<=addrout;
        end        
        
        default: OFM1[0] <= OFM1[0];
      endcase
     end
         if(v_to_router)
           begin
             if(num<NUM_OF_CORE-1)
               num <= num + 1;
             else begin
             
             if(waddr == size-1)
               num <= num;
             else
               num <= 0;            
               waddr <= waddr+1;
             end          
           end
         
         else begin
           num <= num;
           waddr <= waddr;
         end
   end
 end
 
     pe_CNN  inst_pe (
        .clk               (clk),
        .rst               (rst),
        .start             (start),
        .from_router_flit  (from_router_flit),
        .v_from_router     (v_from_router),
        .to_router_flit    (to_router_flit),
        .v_to_router       (v_to_router),
        .credit_r          (credit_r),
        .router_ID         (router_ID),
        .ren_out           (ren_out),
        .data_req          (data_req)
        //.count             (count2)
//        .countz            (countz)
    );
    
    assign coreout = to_router_flit[45:30];
    assign data = to_router_flit[15:0];
    assign addrout = to_router_flit[26:16];
    
//    for_test u(
//      .clk(clk),
//      //.clk2x(clk2x),
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