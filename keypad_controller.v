module keypad_controller (
    input wire       clk,
    input wire       is_started,
    input wire [3:0] keypadCol,
    input wire [1:0] mole_row,
    input wire [1:0] mole_col,
    output reg       mole_is_hitted = 0,
    output reg [3:0] keypadRow
);

    always @(posedge clk) begin
        mole_is_hitted <= 1'b0;
        if (!is_started) begin
            keypadRow <= 4'b0000;
        end
        else begin
            case (mole_row)
                2'd0: keypadRow <= 4'b1110; // 0 for row to be detected
                2'd1: keypadRow <= 4'b1101;
                2'd2: keypadRow <= 4'b1011;
                2'd3: keypadRow <= 4'b0111;
                default: keypadRow <= 4'b1111;
            endcase
            if (keypadCol[mole_col] == 1'b0) begin // 0 when pressed
                mole_is_hitted <= 1'b1;
            end
        end
    end

endmodule