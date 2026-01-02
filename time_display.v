`define GAME_TIME 7'd60     // 60 seconds

module time_display (
    input wire       clk_sec,
    input wire       rst,
    input wire       is_started,
    output reg [5:0] time_left = 0,
    output reg [6:0] seg_time_left_0,
    output reg [6:0] seg_time_left_1
);

// 1. input 包含 clk_sec
// 2. output 為 time_left, 2-digit 7-segment display 的 seg_time_left_0 ~ 1

/*
要求:
    1. is_started 控制 time_left 是否開始倒數
    2. 當 clk_sec 遇到 posedge， time_left 減 1，直到 time_left 為 0 為止
    3. 當 rst 被按下， time_left 回復到 GAME_TIME
    4. 將 time_left 轉換成 2-digit 7-segment display 即時顯示在 seg_time_left_0 ~ 1 上
*/

wire [3:0] digit_0 = time_left % 10;
wire [3:0] digit_1 = time_left / 10;

always @(posedge clk_sec or posedge rst) begin
	if (rst) begin
		time_left <= `GAME_TIME;
	end else if (is_started && time_left > 0) begin
		time_left <= time_left - 1'b1;
	end
end

function [6:0] decode_7seg(input [3:0] num);
	case (num)
		4'd0: decode_7seg = 7'b1000000; // 0
		4'd1: decode_7seg = 7'b1111001; // 1
		4'd2: decode_7seg = 7'b0100100; // 2
		4'd3: decode_7seg = 7'b0110000; // 3
		4'd4: decode_7seg = 7'b0011001; // 4
		4'd5: decode_7seg = 7'b0010010; // 5
		4'd6: decode_7seg = 7'b0000010; // 6
		4'd7: decode_7seg = 7'b1111000; // 7
		4'd8: decode_7seg = 7'b0000000; // 8
		4'd9: decode_7seg = 7'b0010000; // 9
		default: decode_7seg = 7'b1111111; // light out
	endcase
endfunction

always @(*) begin
	seg_time_left_0 = decode_7seg(digit_0);
	seg_time_left_1 = decode_7seg(digit_1);
end

endmodule
