`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Indian Institute of Technology Palakkad, India
// Engineer: Gayathri Malamal
// 
// Create Date: 04.12.2019 11:45:47
// Design Name: 
// Module Name: MEBRA Wrapper Module
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: G. Malamal and M. R. Panicker, "Towards A Pixel-Level Reconfigurable Digital Beamforming Core for Ultrasound Imaging,"
// in IEEE Transactions on Biomedical Circuits and Systems, vol. 14, no. 3, pp. 570-582, June 2020, doi: 10.1109/TBCAS.2020.2983759.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module MEBRA_wrapper(clk,rst,mode,bf_out);

parameter channels=128;	//No. of channels
parameter bit_size=8; //For 128 channels
parameter pixels=1;	//No. of pixels
parameter datasize=channels;
parameter sqrt_latency=5;

input clk,rst;
input mode; //Control signal to select the beamforming mode das/dmas
reg signed [15:0] rfdata;
output signed [16:0]bf_out;

reg signed [15:0] interp_data[0:datasize-1];
//reg [7:0]j;
reg [bit_size-1:0]j;

initial begin
  	$readmemb("cl_interpdata_pixel1_128ch.txt",interp_data);// reading from a text file
end

always@(posedge clk) begin
   if(rst) 
			j<=0;
			
	else if(j<channels) 
			j<=j+1;
end		
		
always@(posedge clk) begin
   if(rst) begin
		rfdata<=0;
   	end
	else if(j<channels) begin
		rfdata<=interp_data[j];
	end
	else 
	   rfdata<=0;
end

MEBRA  #(channels,bit_size,pixels,datasize,sqrt_latency) uut (clk,rst,mode,rfdata,bf_out );
 
endmodule
