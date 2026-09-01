`timescale 1ns / 1ps

module dendrite(
    input clk,
    input rst,
    input phase,
    input [7:0]inrng,
    input [7:0]outrng,
    input signed [15:0]data_ad,
    input a2d,
    input s2d,
    input [15:0]dram,
    input [31:0]v1,
    output logic signed [39:0]data_ds,
    output logic [7:0]neuron,
    output logic d2a,
    output logic d2s
);

    logic [2:0]group;
    logic [2:0]group_reg; 
    logic signed [39:0]macout[0:31];
    logic signed [39:0]macout_reg[0:31];
    logic [31:0]finish;
    logic [4:0]sel;

    logic [3:0]state1;
    logic [1:0]state2;
    localparam [3:0]Idle = 4'b0001,Calc = 4'b0010,Writ = 4'b0100,Rest = 4'b1000;
    localparam [1:0]idle = 2'b01,send = 2'b10;
    
    //generate mac 输入广播到所有，每个MAC负责一个输出；下一轮迭代
    mac mymac0(clk,rst,a2d,inrng,data_ad,group,dram[0+:16],v1[0],macout[0],finish[0]);
    mac mymac1(clk,rst,a2d,inrng,data_ad,group,dram[0+:16],v1[1],macout[1],finish[1]);
    mac mymac2(clk,rst,a2d,inrng,data_ad,group,dram[0+:16],v1[2],macout[2],finish[2]);
    mac mymac3(clk,rst,a2d,inrng,data_ad,group,dram[0+:16],v1[3],macout[3],finish[3]);
    mac mymac4(clk,rst,a2d,inrng,data_ad,group,dram[0+:16],v1[4],macout[4],finish[4]);
    mac mymac5(clk,rst,a2d,inrng,data_ad,group,dram[0+:16],v1[5],macout[5],finish[5]);
    mac mymac6(clk,rst,a2d,inrng,data_ad,group,dram[0+:16],v1[6],macout[6],finish[6]);
    mac mymac7(clk,rst,a2d,inrng,data_ad,group,dram[0+:16],v1[7],macout[7],finish[7]);
    mac mymac8(clk,rst,a2d,inrng,data_ad,group,dram[0+:16],v1[8],macout[8],finish[8]);
    mac mymac9(clk,rst,a2d,inrng,data_ad,group,dram[0+:16],v1[9],macout[9],finish[9]);
    mac mymac10(clk,rst,a2d,inrng,data_ad,group,dram[0+:16],v1[10],macout[10],finish[10]);
    mac mymac11(clk,rst,a2d,inrng,data_ad,group,dram[0+:16],v1[11],macout[11],finish[11]);
    mac mymac12(clk,rst,a2d,inrng,data_ad,group,dram[0+:16],v1[12],macout[12],finish[12]);
    mac mymac13(clk,rst,a2d,inrng,data_ad,group,dram[0+:16],v1[13],macout[13],finish[13]);
    mac mymac14(clk,rst,a2d,inrng,data_ad,group,dram[0+:16],v1[14],macout[14],finish[14]);
    mac mymac15(clk,rst,a2d,inrng,data_ad,group,dram[0+:16],v1[15],macout[15],finish[15]);
    mac mymac16(clk,rst,a2d,inrng,data_ad,group,dram[0+:16],v1[16],macout[16],finish[16]);
    mac mymac17(clk,rst,a2d,inrng,data_ad,group,dram[0+:16],v1[17],macout[17],finish[17]);
    mac mymac18(clk,rst,a2d,inrng,data_ad,group,dram[0+:16],v1[18],macout[18],finish[18]);
    mac mymac19(clk,rst,a2d,inrng,data_ad,group,dram[0+:16],v1[19],macout[19],finish[19]);
    mac mymac20(clk,rst,a2d,inrng,data_ad,group,dram[0+:16],v1[20],macout[20],finish[20]);
    mac mymac21(clk,rst,a2d,inrng,data_ad,group,dram[0+:16],v1[21],macout[21],finish[21]);
    mac mymac22(clk,rst,a2d,inrng,data_ad,group,dram[0+:16],v1[22],macout[22],finish[22]);
    mac mymac23(clk,rst,a2d,inrng,data_ad,group,dram[0+:16],v1[23],macout[23],finish[23]);
    mac mymac24(clk,rst,a2d,inrng,data_ad,group,dram[0+:16],v1[24],macout[24],finish[24]);
    mac mymac25(clk,rst,a2d,inrng,data_ad,group,dram[0+:16],v1[25],macout[25],finish[25]);
    mac mymac26(clk,rst,a2d,inrng,data_ad,group,dram[0+:16],v1[26],macout[26],finish[26]);
    mac mymac27(clk,rst,a2d,inrng,data_ad,group,dram[0+:16],v1[27],macout[27],finish[27]);
    mac mymac28(clk,rst,a2d,inrng,data_ad,group,dram[0+:16],v1[28],macout[28],finish[28]);
    mac mymac29(clk,rst,a2d,inrng,data_ad,group,dram[0+:16],v1[29],macout[29],finish[29]);
    mac mymac30(clk,rst,a2d,inrng,data_ad,group,dram[0+:16],v1[30],macout[30],finish[30]);
    mac mymac31(clk,rst,a2d,inrng,data_ad,group,dram[0+:16],v1[31],macout[31],finish[31]);

    //mux32
    always @(*)
    begin
        case (sel)
            5'd0: data_ds = macout_reg[0];
            5'd1: data_ds = macout_reg[1];
            5'd2: data_ds = macout_reg[2];
            5'd3: data_ds = macout_reg[3];
            5'd4: data_ds = macout_reg[4];
            5'd5: data_ds = macout_reg[5];
            5'd6: data_ds = macout_reg[6];
            5'd7: data_ds = macout_reg[7];
            5'd8: data_ds = macout_reg[8];
            5'd9: data_ds = macout_reg[9];
            5'd10: data_ds = macout_reg[10];
            5'd11: data_ds = macout_reg[11];
            5'd12: data_ds = macout_reg[12];
            5'd13: data_ds = macout_reg[13];
            5'd14: data_ds = macout_reg[14];
            5'd15: data_ds = macout_reg[15];
            5'd16: data_ds = macout_reg[16];
            5'd17: data_ds = macout_reg[17];
            5'd18: data_ds = macout_reg[18];
            5'd19: data_ds = macout_reg[19];
            5'd20: data_ds = macout_reg[20];
            5'd21: data_ds = macout_reg[21];
            5'd22: data_ds = macout_reg[22];
            5'd23: data_ds = macout_reg[23];
            5'd24: data_ds = macout_reg[24];
            5'd25: data_ds = macout_reg[25];
            5'd26: data_ds = macout_reg[26];
            5'd27: data_ds = macout_reg[27];
            5'd28: data_ds = macout_reg[28];
            5'd29: data_ds = macout_reg[29];
            5'd30: data_ds = macout_reg[30];
            5'd31: data_ds = macout_reg[31];
            default: data_ds = macout_reg[0];
        endcase
    end

    assign neuron = sel + (group_reg << 5);

    //calculate FSM
    always@(posedge clk)
    begin
        if(!rst)
        begin
            state1 <= Idle;
            group <= 0;
            d2a <= 0;
            for (integer i = 0; i < 32; i = i + 1) 
            begin
                macout_reg[i] <= 0;
            end
        end
        else
            case (state1)
                Idle:
                begin
                    if(phase)
                    begin
                        state1 <= Calc;
                        d2a <= 1;
                    end
                    else
                        state1 <= Idle;
                end
                Calc:
                begin
                    if((&finish == 1) && (s2d == 1))
                        state1 <= Writ;
                    else
                        state1 <= Calc;
                end
                Writ:
                begin
                    for (integer i = 0; i < 32; i = i + 1) 
                    begin
                        macout_reg[i] <= macout[i];
                    end
                    d2a <= 0;
                    if((32 * (group + 1)) < (outrng + 1))
                        state1 <= Rest;
                    else
                    begin
                        state1 <= Idle;
                        group <= 0;
                    end
                end
                Rest:
                begin
                    if(!a2d)
                    begin
                        state1 <= Calc;
                        d2a <= 1;
                        group <= group + 1;
                    end
                    else
                        state1 <= Rest;
                end
                default:
                    state1 <= Idle;
            endcase
    end

    //send FSM
    always@(posedge clk)
    begin
        if(!rst)
        begin
            state2 <= idle;
            sel <= 0;
            d2s <= 0;
            group_reg <= 0;
        end
        else
            case (state2)
                idle: 
                begin
                    if(state1 == Writ)
                    begin
                        state2 <= send;
                        d2s <= 1;
                        group_reg <= group;
                    end
                    else
                        state2 <= idle;
                end

                send:
                begin
                    if((sel == 31)||(outrng == neuron))
                    begin
                        state2 <= idle;
                        sel <= 0;
                        d2s <= 0;
                        group_reg <= 0;
                    end
                    else
                    begin
                        state2 <= send;
                        sel <= sel + 1;
                    end
                end

                default: 
                    state2 <= idle;
            endcase
            
    end

endmodule