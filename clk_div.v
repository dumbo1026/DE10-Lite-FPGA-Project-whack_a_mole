// 25000000 1 sec

module clk_div(
	input clk,
	input rst,
	input [31:0] TimeExpire,
	output reg div_clk);
reg [31:0] counter;

always@(posedge clk or negedge rst)
begin
	if (!rst) // reset when rst is 0
	begin
		counter <= 0;
		div_clk <= 0;
	end
	else
	begin
		if (counter == TimeExpire)
		begin
			counter <= 0;
			div_clk <= ~div_clk;
		end
		else
		begin
			counter <= counter + 1;
		end
	end
end


endmodule
