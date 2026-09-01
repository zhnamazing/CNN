`timescale 1ns / 1ps
module Multi_NI #(parameter FLIT_WIDTH = 48, CREDIT_WIDTH = 6, ID_BITS = 6)(
    input clk, 
    input rst,
    input signed [15:0]from_core_data,
    input [10:0]from_core_addr,
    input v_from_core,
    input [FLIT_WIDTH-1:0]from_router_flit,
    input v_from_router,
    input [5:0] router_ID,
    input ren_out,

    output logic signed [15:0]din,
    output logic [10:0]waddr,
    output logic wen,

    output logic signed [15:0]dram,
    output logic [6:0]v1,//代表需要用哪些卷积核

    output logic signed [15:0]in_bias,
    output logic v_bias,
    output logic signed [39:0]pool_bias,
    output logic signed [15:0]pool_weight,
    output logic v_pool_bias,
    output logic v_pool_weight,
    
    output logic [24:0]in_config,
    output logic v_config,

    output logic init,

    output logic [FLIT_WIDTH-1:0]to_router_flit,
    output logic v_to_router,
  
    input [CREDIT_WIDTH - 1:0]credit_r,
    output logic r2s
);
    logic signed [15:0] data;
    logic [FLIT_WIDTH - 1:0]from_core_flitin;
    logic wen_out;
    logic [FLIT_WIDTH - 1:0]from_core_flitout;
    logic v_flitout;
    logic [3:0]size_out;
    
    assign data = to_router_flit[15:0];

    logic [26:0]router_addr;
    logic [1:0]v_num;
    logic [15:0] from_core_data_reg;
    logic [10:0] from_core_addr_reg;
    logic v_from_core_reg;

    logic [FLIT_WIDTH-1:0] from_core_flitout_reg;
    logic v_flitout_reg;
    logic [FLIT_WIDTH-1:0] t_to_router_flit;
    logic t_v_to_router;
    logic t_ren_out;
    
    logic wen_reg;
    logic [25:0]in_rlut;
    logic v_rlut;
    logic [5:0]addrr;
    logic [5:0]waddrr;
    logic en_rlut;
    logic test;

    assign addrr = v_rlut ? waddrr : from_core_addr[5:0];//根据RAM地址，取出RAM地址+路由地址
    assign en_rlut = v_rlut ? 1 : v_from_core;
    
    always@(posedge clk)begin
      if(!rst)
      begin
        wen_reg <=0;
      end
      else begin
            wen_reg <=wen;
        end
      end

    always@(posedge clk)
    begin
        if(!rst)
        begin
            waddrr <= 0;
        end
        else
        begin
            waddrr <= v_rlut ? waddrr + 1 : waddrr;
        end
    end

    always@(posedge clk)
    begin
        if(!rst)
        begin
            din <= 0;
            waddr <= 0;
            wen <= 0;
            dram <= 0;
            v1 <= 0;
            in_bias <= 0;
            v_bias <= 0;
            init <= 0;
        end
        else
        begin
            init<=1;
            if(v_from_router)
            begin
                if(from_router_flit[29] == 0)
                begin
                    din <= from_router_flit[0+:16];
                    waddr <= from_router_flit[16+:11];
                    wen <= 1;
                    dram <= 0;
                    v1 <= 0;
                    v_bias <= 0;
                end
                else begin
                    din <= 0;
                    waddr <= 0;                  
                    case (from_router_flit[16+:7])
                        7'd0:
                        begin
                            wen <= 0;
                            v1 <= 0;
                            v_bias <= 0;
                            dram <= from_router_flit[0+:16];
                        end
                        7'd1:
                        begin
                            wen <= 0;
                            v1 <= 7'd1;
                            v_bias <= 0;
                            dram <= from_router_flit[0+:16];
                        end
                        7'd2:
                        begin
                            wen <= 0;
                            v1 <= 7'd2;
                            v_bias <= 0;
                            dram <= from_router_flit[0+:16];
                        end
                        7'd3:
                        begin
                            wen <= 0;
                            v1 <= 7'd3;
                            v_bias <= 0;
                            dram <= from_router_flit[0+:16];
                        end
                        7'd4:
                        begin
                            wen <= 0;
                            v1 <= 7'd4;
                            v_bias <= 0;
                            dram <= from_router_flit[0+:16];
                        end
                        7'd5:
                        begin
                            wen <= 0;
                            v1 <= 7'd5;
                            v_bias <= 0;
                            dram <= from_router_flit[0+:16];
                        end
                        7'd6:
                        begin
                            wen <= 0;
                            v1 <= 7'd6;
                            v_bias <= 0;
                            dram <= from_router_flit[0+:16];
                        end
                        7'd7:
                        begin
                            wen <= 0;
                            v1 <= 7'd7;
                            v_bias <= 0;
                            dram <= from_router_flit[0+:16];
                        end
                        7'd8:
                        begin
                            wen <= 0;
                            v1 <= 7'd8;
                            v_bias <= 0;
                            dram <= from_router_flit[0+:16];
                        end
                        7'd9:
                        begin
                            wen <= 0;
                            v1 <= 7'd9;
                            v_bias <= 0;
                            dram <= from_router_flit[0+:16];
                        end
                        7'd10:
                        begin
                            wen <= 0;
                            v1 <= 7'd10;
                            v_bias <= 0;
                            dram <= from_router_flit[0+:16];
                        end
                        7'd11:
                        begin
                            wen <= 0;
                            v1 <= 7'd11;
                            v_bias <= 0;
                            dram <= from_router_flit[0+:16];
                        end
                        7'd12:
                        begin
                            wen <= 0;
                            v1 <= 7'd12;
                            v_bias <= 0;
                            dram <= from_router_flit[0+:16];
                        end
                        7'd13:
                        begin
                            wen <= 0;
                            v1 <= 7'd13;
                            v_bias <= 0;
                            dram <= from_router_flit[0+:16];
                        end
                        7'd14:
                        begin
                            wen <= 0;
                            v1 <= 7'd14;
                            v_bias <= 0;
                            dram <= from_router_flit[0+:16];
                        end
                        7'd15:
                        begin
                            wen <= 0;
                            v1 <= 7'd15;
                            v_bias <= 0;
                            dram <= from_router_flit[0+:16];
                        end
                        7'd16:
                        begin
                            wen <= 0;
                            v1 <= 7'd16;
                            v_bias <= 0;
                            dram <= from_router_flit[0+:16];
                        end

                        7'd17:
                        begin
                            wen <= 0;
                            v1 <= 7'd17;
                            v_bias <= 0;
                            dram <= from_router_flit[0+:16];
                        end
                        7'd18:
                        begin
                            wen <= 0;
                            v1 <= 7'd18;
                            v_bias <= 0;
                            dram <= from_router_flit[0+:16];
                        end
                        7'd19:
                        begin
                            wen <= 0;
                            v1 <= 7'd19;
                            v_bias <= 0;
                            dram <= from_router_flit[0+:16];
                        end
                        7'd20:
                        begin
                            wen <= 0;
                            v1 <= 7'd20;
                            v_bias <= 0;
                            dram <= from_router_flit[0+:16];
                        end
                        7'd21:
                        begin
                            wen <= 0;
                            v1 <= 7'd21;
                            v_bias <= 0;
                            dram <= from_router_flit[0+:16];
                        end
                        7'd22:
                        begin
                            wen <= 0;
                            v1 <= 7'd22;
                            v_bias <= 0;
                            dram <= from_router_flit[0+:16];
                        end
                        7'd23:
                        begin
                            wen <= 0;
                            v1 <= 7'd23;
                            v_bias <= 0;
                            dram <= from_router_flit[0+:16];
                        end
                        7'd24:
                        begin
                            wen <= 0;
                            v1 <= 7'd24;
                            v_bias <= 0;
                            dram <= from_router_flit[0+:16];
                        end
                        7'd25:
                        begin
                            wen <= 0;
                            v1 <= 7'd25;
                            v_bias <= 0;
                            dram <= from_router_flit[0+:16];
                        end
                        7'd26:
                        begin
                            wen <= 0;
                            v1 <= 7'd26;
                            v_bias <= 0;
                            dram <= from_router_flit[0+:16];
                        end
                        7'd27:
                        begin
                            wen <= 0;
                            v1 <= 7'd27;
                            v_bias <= 0;
                            dram <= from_router_flit[0+:16];
                        end
                        7'd28:
                        begin
                            wen <= 0;
                            v1 <= 7'd28;
                            v_bias <= 0;
                            dram <= from_router_flit[0+:16];
                        end
                        7'd29:
                        begin
                            wen <= 0;
                            v1 <= 7'd29;
                            v_bias <= 0;
                            dram <= from_router_flit[0+:16];
                        end
                        7'd30:
                        begin
                            wen <= 0;
                            v1 <= 7'd30;
                            v_bias <= 0;
                            dram <= from_router_flit[0+:16];
                        end
                        7'd31:
                        begin
                            wen <= 0;
                            v1 <= 7'd31;
                            v_bias <= 0;
                            dram <= from_router_flit[0+:16];
                        end
                        7'd32:
                        begin
                            wen <= 0;
                            v1 <= 7'd32;
                            v_bias <= 0;
                            dram <= from_router_flit[0+:16];
                        end
                        7'd33:
                        begin
                            wen <= 0;
                            v1 <= 7'd33;
                            v_bias <= 0;
                            dram <= from_router_flit[0+:16];
                        end
                        7'd34:
                        begin
                            wen <= 0;
                            v1 <= 7'd34;
                            v_bias <= 0;
                            dram <= from_router_flit[0+:16];
                        end
                        7'd35:
                        begin
                            wen <= 0;
                            v1 <= 7'd35;
                            v_bias <= 0;
                            dram <= from_router_flit[0+:16];
                        end
                        7'd36:
                        begin
                            wen <= 0;
                            v1 <= 7'd36;
                            v_bias <= 0;
                            dram <= from_router_flit[0+:16];
                        end
                        7'd37:
                        begin
                            wen <= 0;
                            v1 <= 7'd37;
                            v_bias <= 0;
                            dram <= from_router_flit[0+:16];
                        end
                        7'd38:
                        begin
                            wen <= 0;
                            v1 <= 7'd38;
                            v_bias <= 0;
                            dram <= from_router_flit[0+:16];
                        end
                        7'd39:
                        begin
                            wen <= 0;
                            v1 <= 7'd39;
                            v_bias <= 0;
                            dram <= from_router_flit[0+:16];
                        end
                        7'd40:
                        begin
                            wen <= 0;
                            v1 <= 7'd40;
                            v_bias <= 0;
                            dram <= from_router_flit[0+:16];
                        end
                        7'd41:
                        begin
                            wen <= 0;
                            v1 <= 7'd41;
                            v_bias <= 0;
                            dram <= from_router_flit[0+:16];
                        end
                        7'd42:
                        begin
                            wen <= 0;
                            v1 <= 7'd42;
                            v_bias <= 0;
                            dram <= from_router_flit[0+:16];
                        end
                        7'd43:
                        begin
                            wen <= 0;
                            v1 <= 7'd43;
                            v_bias <= 0;
                            dram <= from_router_flit[0+:16];
                        end
                        7'd44:
                        begin
                            wen <= 0;
                            v1 <= 7'd44;
                            v_bias <= 0;
                            dram <= from_router_flit[0+:16];
                        end
                        7'd45:
                        begin
                            wen <= 0;
                            v1 <= 7'd45;
                            v_bias <= 0;
                            dram <= from_router_flit[0+:16];
                        end
                        7'd46:
                        begin
                            wen <= 0;
                            v1 <= 7'd46;
                            v_bias <= 0;
                            dram <= from_router_flit[0+:16];
                        end
                        7'd47:
                        begin
                            wen <= 0;
                            v1 <= 7'd47;
                            v_bias <= 0;
                            dram <= from_router_flit[0+:16];
                        end
                        7'd48:
                        begin
                            wen <= 0;
                            v1 <= 7'd48;
                            v_bias <= 0;
                            dram <= from_router_flit[0+:16];
                        end

                        7'd49:
                        begin
                            wen <= 0;
                            v1 <= 7'd49;
                            v_bias <= 0;
                            dram <= from_router_flit[0+:16];
                        end
                        7'd50:
                        begin
                            wen <= 0;
                            v1 <= 7'd50;
                            v_bias <= 0;
                            dram <= from_router_flit[0+:16];
                        end
                        7'd51:
                        begin
                            wen <= 0;
                            v1 <= 7'd51;
                            v_bias <= 0;
                            dram <= from_router_flit[0+:16];
                        end
                        7'd52:
                        begin
                            wen <= 0;
                            v1 <= 7'd52;
                            v_bias <= 0;
                            dram <= from_router_flit[0+:16];
                        end
                        7'd53:
                        begin
                            wen <= 0;
                            v1 <= 7'd53;
                            v_bias <= 0;
                            dram <= from_router_flit[0+:16];
                        end
                        7'd54:
                        begin
                            wen <= 0;
                            v1 <= 7'd54;
                            v_bias <= 0;
                            dram <= from_router_flit[0+:16];
                        end
                        7'd55:
                        begin
                            wen <= 0;
                            v1 <= 7'd55;
                            v_bias <= 0;
                            dram <= from_router_flit[0+:16];
                        end
                        7'd56:
                        begin
                            wen <= 0;
                            v1 <= 7'd56;
                            v_bias <= 0;
                            dram <= from_router_flit[0+:16];
                        end
                        7'd57:
                        begin
                            wen <= 0;
                            v1 <= 7'd57;
                            v_bias <= 0;
                            dram <= from_router_flit[0+:16];
                        end
                        7'd58:
                        begin
                            wen <= 0;
                            v1 <= 7'd58;
                            v_bias <= 0;
                            dram <= from_router_flit[0+:16];
                        end
                        7'd59:
                        begin
                            wen <= 0;
                            v1 <= 7'd59;
                            v_bias <= 0;
                            dram <= from_router_flit[0+:16];
                        end
                        7'd60:
                        begin
                            wen <= 0;
                            v1 <= 7'd60;
                            v_bias <= 0;
                            dram <= from_router_flit[0+:16];
                        end
                        7'd61:
                        begin
                            wen <= 0;
                            v1 <= 7'd61;
                            v_bias <= 0;
                            dram <= from_router_flit[0+:16];
                        end
                        7'd62:
                        begin
                            wen <= 0;
                            v1 <= 7'd62;
                            v_bias <= 0;
                            dram <= from_router_flit[0+:16];
                        end
                        7'd63:
                        begin
                            wen <= 0;
                            v1 <= 7'd63;
                            v_bias <= 0;
                            dram <= from_router_flit[0+:16];
                        end
                        7'd64:
                        begin
                            wen <= 0;
                            v1 <= 7'd64;
                            v_bias <= 0;
                            dram <= from_router_flit[0+:16];
                        end
                        7'd65:
                        begin
                            in_bias <= from_router_flit[0+:16];
                            wen <= 0;
                            v1 <= 0;
                            v_bias <= 1;
                        end
//                        7'd66:
//                        begin
//                            in_bias[16+:16] <= from_router_flit[0+:16];
//                            wen <= 0;
//                            v1 <= 0;
//                            v_bias <= 0;
//                        end
//                        7'd67:
//                        begin
//                            in_bias[32+:8] <= from_router_flit[0+:8];
//                            wen <= 0;
//                            v1 <= 0;
//                            v_bias <= 1;
//                        end
                        default:
                        begin
                            wen <= 0;
                            v1 <= 0;
                            v_bias <= 0;
                        end 
                    endcase
            end
          end
            else begin
                din <= 0;
                waddr <= 0;
                wen <= 0;
                dram <= 0;
                v1 <= 0;
                v_bias <= 0;
            end
        end
    end
   

//bram #(27, 56, 6) rlut_ram(
//	.clk(clk),
//    .rst(rst),
//    .en (en_rlut),
//    .we (v_rlut),
//    .addr(addrr),
//    .din(in_rlut),
//    .dout(router_addr)
//); 

    fifo_NI #(FLIT_WIDTH, 5) fifo_out(
        clk,
        rst,
        from_core_flitin,
        wen_out,
        ren_out,
    
        from_core_flitout,
        v_flitout,
        size_out
    );
    
//    assign r2s = (size_out > 28) ? 0:1;
    assign r2s = 1;

    always@(posedge clk)
    begin
        if(!rst)
        begin
            v_from_core_reg <= 0;
            from_core_data_reg <= 0;
            from_core_addr_reg <= 0;
        end
        else
        begin
            v_from_core_reg <= v_from_core;
            from_core_data_reg <= from_core_data;
            from_core_addr_reg <= from_core_addr;
        end    
    end

    assign from_core_flitin = {1'b0,1'b0, {16{1'b0}},1'b1,{2{1'b0}},from_core_addr_reg,from_core_data_reg};
    assign wen_out = v_from_core_reg;

    //credit reg
    integer i;

    always @(posedge clk) begin
        if(!rst)begin
            from_core_flitout_reg <= 0;
            v_flitout_reg <= 0;
        end
        else begin
            if(v_flitout) begin
                from_core_flitout_reg <= from_core_flitout;
                v_flitout_reg <= 1;
            end
            else begin
                from_core_flitout_reg <= from_core_flitout_reg;
                v_flitout_reg <= ren_out ? 0:v_flitout_reg;
            end
        end
    end

    always @(*) begin
            t_to_router_flit = from_core_flitout_reg;
            t_to_router_flit[46] = 0;
            t_v_to_router = v_flitout_reg;
            t_ren_out = 1;
    end

    assign to_router_flit = t_to_router_flit;
    assign v_to_router = t_v_to_router;

endmodule