`timescale 1ns / 1ps

module tb_dendrite;
     
    reg clk;
    reg clk2x;
    reg rst;
    
    wire [11:0]outrng=56;//28*2
    wire [2:0]filter_row=5;
    wire [2:0]filter_col=5;
    wire [5:0]rowslice=6;
    wire [7:0]colrng=32; 
    
    reg signed [15:0]data_ad;
    logic a2d;
    reg s2d;
    reg [15:0]dram;
    reg [31:0]v1;
    reg phase;
    wire [671:0]mask={672{1'b1}};
    
    wire logic [7:0]raddr;
    wire logic signed [40:0]data_ds;
    wire logic d2a;
    wire logic d2s;
    
    //  dendrite_CNN  test (
//         .clk               (clk),
//         .rst               (rst),
// //        .outrng            (outrng),
//         .filter_row        (filter_row),
//         .phase             (phase),
//         .filter_col        (filter_col),
// //        .rowslice          (rowslice),
//         .colrng            (colrng),
//         .data_ad           (data_ad),
//         .a2d               (a2d),
//         .s2d               (s2d),
//         .dram              (dram),
//         .v1                (v1),
//         .mask              (mask),
//         .raddr             (raddr),
//         .data_ds           (data_ds),
//         .d2a               (d2a),
//         .d2s               (d2s)
//     );
    dendrite_CNN  #(.NUM_OF_CORE(32), .core_size(5), .colrng(14), .size(224), .stride(1), .row(2), .group(4), .core_channel(8)) test (
        .clk               (clk),
        .clk2x             (clk2x),
        .rst               (reset),
        .phase             (phase),
        .data_ad           (data_ad),
        .a2d               (a2d),
        .s2d               (s2d),
        .dram              (dram),
        .v1                (v1),
        .mask              (mask),
        .raddr             (raddr),
        .data_ds           (data_ds),
        .d2a               (d2a),
        .d2s               (d2s),    
//        .count             (count),
        .wri               (wri)
    );
    
    reg signed [12:0] count;
    
    always #5 clk = ~clk;
    always #2.5 clk = ~clk;

    initial begin
       clk<=0;
       rst<=0;
       count<=-1;
       v1<=16'b0;
       a2d<=0;
       s2d<=0;
       dram<=0;
       data_ad<=0;
       phase<=1;
       #1100 
       rst<=1;
    end
 
    always@(posedge clk)
    begin
         if(rst)begin
           if(count<8000)
              count <= count + 1;
           else
             $finish;
          end
      if((count>=150)&&(((count-150)%27>=0)&&((count-15)%27<=24)))
        a2d<=1;
      else
        a2d<=0;
        
      if((count>=0)&&(count<200))
          begin
            v1<=16'b0000000000000001;
            dram<=count+1;
          end
          
      else if((count>=200)&&(count<400))
          begin
            v1<=16'b0000000000000010;
            dram<=count-199;
          end
      
      else if((count>=400)&&(count<600))
          begin
            v1<=16'b0000000000000100;
            dram<=count-399;
          end
          
      else if((count>=600)&&(count<800))
          begin
            v1<=16'b0000000000001000;
            dram<=count-599;
          end
          
      else if((count>=800)&&(count<1000))
          begin
            v1<=16'b0000000000010000;
            dram<=count-799;
          end
          
      else if((count>=1000)&&(count<1200))
          begin
            v1<=16'b0000000000100000;
            dram<=count-124;
          end
            if((count>=0)&&(count<200))
          begin
            v1<=16'b0000000000000001;
            dram<=count+1;
          end
          
      else if((count>=200)&&(count<400))
          begin
            v1<=16'b0000000000000010;
            dram<=count-199;
          end
      
      else if((count>=400)&&(count<600))
          begin
            v1<=16'b0000000000000100;
            dram<=count-399;
          end
          
      else if((count>=600)&&(count<800))
          begin
            v1<=16'b0000000000001000;
            dram<=count-599;
          end
          
      else if((count>=800)&&(count<1000))
          begin
            v1<=16'b0000000000010000;
            dram<=count-799;
          end
          
      else if((count>=1000)&&(count<1200))
          begin
            v1<=16'b0000000000100000;
            dram<=count-124;
          end
            if((count>=0)&&(count<200))
          begin
            v1<=16'b0000000000000001;
            dram<=count+1;
          end
          
      else if((count>=200)&&(count<400))
          begin
            v1<=16'b0000000000000010;
            dram<=count-199;
          end
      
      else if((count>=400)&&(count<600))
          begin
            v1<=16'b0000000000000100;
            dram<=count-399;
          end
          
      else if((count>=600)&&(count<800))
          begin
            v1<=16'b0000000000001000;
            dram<=count-599;
          end
          
      else if((count>=800)&&(count<1000))
          begin
            v1<=16'b0000000000010000;
            dram<=count-799;
          end
          
      else if((count>=1000)&&(count<1200))
          begin
            v1<=16'b0000000000100000;
            dram<=count-124;
          end
            if((count>=0)&&(count<200))
          begin
            v1<=16'b0000000000000001;
            dram<=count+1;
          end
          
      else if((count>=200)&&(count<400))
          begin
            v1<=16'b0000000000000010;
            dram<=count-199;
          end
      
      else if((count>=400)&&(count<600))
          begin
            v1<=16'b0000000000000100;
            dram<=count-399;
          end
          
      else if((count>=600)&&(count<800))
          begin
            v1<=16'b0000000000001000;
            dram<=count-599;
          end
          
      else if((count>=800)&&(count<1000))
          begin
            v1<=16'b0000000000010000;
            dram<=count-799;
          end
          
      else if((count>=1000)&&(count<1200))
          begin
            v1<=16'b0000000000100000;
            dram<=count-124;
          end
            // if(count==149)
            //   s2d<=1;
            // else
            //   s2d<=0;
          
          else if(count==150)
          begin
            v1<=0;
            s2d<=1;
            dram<=0;
          end
          
          else if((count>=151)&&(count<153))
          begin
            v1<=0;
            s2d<=1;
            dram<=0;
          end
          
          else if((count>=153)&&(count<1800))
          begin
            v1<=0;
            s2d<=1;
            data_ad<=((count-153)%25+1);
          end
    end
endmodule
