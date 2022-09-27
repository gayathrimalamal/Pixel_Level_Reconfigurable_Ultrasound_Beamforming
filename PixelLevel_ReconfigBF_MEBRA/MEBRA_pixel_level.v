`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Indian Institute of Technology Palakkad
// Engineer: Gayathri Malamal
// 
// Create Date:    21:56:09 10/15/2019 
// Design Name: 
// Module Name:    MEBRA beamformer 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: Author: Gayathri Malamal
// G. Malamal and M. R. Panicker, "Towards A Pixel-Level Reconfigurable Digital Beamforming Core for Ultrasound Imaging," 
// in IEEE Transactions on Biomedical Circuits and Systems, vol. 14, no. 3, pp. 570-582, June 2020, doi: 10.1109/TBCAS.2020.2983759.
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module MEBRA_pixel_level( clk,/*clk_dmas,*/rst,mode,chnl_data,sign,bf_out);

parameter channels=128;	//No. of channels
parameter bit_size=8; //For 128 channels
parameter pixels=1;	//No. of pixels
parameter datasize=pixels*channels;
parameter sqrt_ip_latency=5;

input clk;
//input clk_dmas;

input rst;
input mode;
input signed [1:0]sign;
input signed [15:0]chnl_data;

//DAS
reg signed [16:0]sigma;
reg [bit_size-1:0] ch_das_cnt,ch_das_cnt_d,ch_das_cnt_d2; //for 128 channels

//DMAS
reg signed [1:0]sign_d1;
reg signed [1:0]sign_d2;
reg signed [1:0]sign_d3;
reg signed [1:0]sign_d4;
reg signed [1:0]sign_d5;
//reg signed [1:0]sign_d6;

wire sqrt_out_valid;
reg signed [16:0]sigma_sqrt;
//reg signed [16:0]sigma_sum_sqr;

wire [15:0]chnl_dout_sqrt;
//reg  [8:0]chnl_dout_sqrt_sync;
wire signed [bit_size-1:0]chnl_din_dmas;

//reg [6:0]ch_dmas_cnt,ch_dmas_cnt_d; //for 64 channels
//reg [7:0]ch_dmas_cnt,ch_dmas_cnt_d; for 128 channels
reg [bit_size-1:0]ch_dmas_cnt,ch_dmas_cnt_d; //for 256 channels
reg [2:0]compensate_sqrt_latency;

output reg signed [16:0]bf_out;

//Synchronizing sign according to square root latency which is 5
always@(posedge clk) begin
if(~mode) begin
	if(rst) begin
		sign_d1<=2'b1;
		sign_d2<=2'b1;
		sign_d3<=2'b1;
		sign_d4<=2'b1;
		sign_d5<=2'b1;
	//	sign_d6<=2'b1;
	end
	else begin
		sign_d1<=sign;
		sign_d2<=sign_d1;
		sign_d3<=sign_d2;
		sign_d4<=sign_d3;
		sign_d5<=sign_d4;
//		sign_d6<=sign_d5;
	end
end
end

squareroot dut_sqrroot          (
                            .aclk(clk),                                        // input wire aclk
                            .s_axis_cartesian_tvalid(~mode),  // input wire s_axis_cartesian_tvalid
                            .s_axis_cartesian_tdata(chnl_data),    // input wire [15 : 0] s_axis_cartesian_tdata
                            .m_axis_dout_tvalid(sqrt_out_valid),            // output wire m_axis_dout_tvalid
                            .m_axis_dout_tdata(chnl_dout_sqrt)              // output wire [15 : 0] m_axis_dout_tdata
                            );
							  
//always@(posedge clk_dmas)	begin
//	chnl_dout_sqrt_sync<=chnl_dout_sqrt[8:0];
//end						  
							  
//assign chnl_din_dmas=mode?0:((sign_d6==-2'd1)? (-1'd1*chnl_dout_sqrt_sync):chnl_dout_sqrt_sync); //sign*abs(sqrt)
assign chnl_din_dmas=mode?0:((sign_d5==-1)? -chnl_dout_sqrt[8:0]:chnl_dout_sqrt[8:0]); //sign*abs(sqrt)

always @(posedge clk)
begin
	if(rst) begin
		ch_das_cnt<=0;
	end
	else begin
		if(mode) begin
             if(ch_das_cnt<channels) begin
                ch_das_cnt<=ch_das_cnt+1'b1;
             end
		end
	end
end

always@(posedge clk) begin
         ch_das_cnt_d<=ch_das_cnt;
         ch_das_cnt_d2<=ch_das_cnt_d;
end

always @(posedge clk) begin
if(~mode)begin
	if(rst) begin
		compensate_sqrt_latency<=0;
	end
	else if(compensate_sqrt_latency<sqrt_ip_latency+1'b1) 
			compensate_sqrt_latency<=compensate_sqrt_latency+1'b1;
	else
			compensate_sqrt_latency<=compensate_sqrt_latency;
end
end

always @(posedge clk) begin
if(~mode)
begin
	if(rst) begin
		ch_dmas_cnt<=0;
//		ch_dmas_cnt_d<=0;
	end
	else if(compensate_sqrt_latency==sqrt_ip_latency+1'b1) begin
	   if(ch_dmas_cnt<channels) begin
            ch_dmas_cnt<=ch_dmas_cnt+1'b1;
  //          ch_dmas_cnt_d<=ch_dmas_cnt;
       end
	end
	else begin
		ch_dmas_cnt<=ch_dmas_cnt;
//		ch_dmas_cnt_d<=ch_dmas_cnt_d;
	end
end
end

always @(posedge clk)begin
if(~mode)
begin
	if(rst) begin
		ch_dmas_cnt_d<=0;
	end
	else begin
		ch_dmas_cnt_d<=ch_dmas_cnt;
	end
end
end

always @(posedge clk)
begin
	if(rst) begin
			sigma<=0;
	end
	
	else begin
	 		if(mode) begin
				if(ch_das_cnt_d2<channels) begin
					sigma<=sigma+chnl_data;
				end
			end
					
			 else begin
			//if(clk_cnt==sqrt_latency) begin
				sigma<=sigma+chnl_data;
			//end
			 end
	end
end
 
always @(posedge clk)begin
if(~mode)
begin
	if(rst)begin
		sigma_sqrt<=0;
		
	end
		
	else begin
		//if(clk_cnt==sqrt_latency) begin
		//  if(i1<pixels) begin
		//		if(ch<channels)
				if(ch_dmas_cnt_d<channels) begin
					sigma_sqrt<=sigma_sqrt+chnl_din_dmas;
					
				end
		//  end
		//end		
	end
end
end

always @(posedge clk) begin
	if(rst) begin
		bf_out<=0;
	end
	
	else begin
		if(mode)
			if(ch_das_cnt_d2==channels)
				bf_out<=sigma;
			else 
				bf_out<=bf_out;
		else if(ch_dmas_cnt_d==channels)
		//	bf_out<=sigma_sum_sqr;
			bf_out<=((sigma_sqrt*sigma_sqrt)-sigma)>>>1'b1;
	end
end
 
endmodule



