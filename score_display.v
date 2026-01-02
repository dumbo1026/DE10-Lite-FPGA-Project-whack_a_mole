module score_display (
    input  wire [15:0] score,  // 輸入分數
    output wire [7:0]  hex0,   // 個位數 (顯示)
    output wire [7:0]  hex1,   // 十位數 (顯示)
    output wire [7:0]  hex2,   // 百位數 (顯示)
    output wire [7:0]  hex3,   // 關閉
    output wire [7:0]  hex4,   // 關閉
    output wire [7:0]  hex5    // 關閉
);

    // 內部變數：用來處理不超過 999 的分數
    wire [15:0] display_score;
    
    // 如果分數 > 999，強制鎖定在 999，否則顯示原分數
    assign display_score = (score > 999) ? 16'd999 : score;

    // 計算個、十、百位
    wire [3:0] digit0;
    wire [3:0] digit1;
    wire [3:0] digit2;

    assign digit0 = display_score % 10;
    assign digit1 = (display_score / 10) % 10;
    assign digit2 = (display_score / 100) % 10;

    // --- 實例化解碼器 ---
    // 顯示分數的位數
    segment_decoder u0 (.digit(digit0), .seg_out(hex0));
    segment_decoder u1 (.digit(digit1), .seg_out(hex1));
    segment_decoder u2 (.digit(digit2), .seg_out(hex2));

    // --- 將沒用到的顯示器關閉 ---
    assign hex3 = 8'hFF;
    assign hex4 = 8'hFF;
    assign hex5 = 8'hFF;

endmodule


module segment_decoder (
    input  wire [3:0] digit,
    output reg  [7:0] seg_out
);
    always @(*) begin
        case (digit)
            //                        gfedcba (dp)
            4'h0: seg_out = 8'b11000000; // 0
            4'h1: seg_out = 8'b11111001; // 1
            4'h2: seg_out = 8'b10100100; // 2
            4'h3: seg_out = 8'b10110000; // 3
            4'h4: seg_out = 8'b10011001; // 4
            4'h5: seg_out = 8'b10010010; // 5
            4'h6: seg_out = 8'b10000010; // 6
            4'h7: seg_out = 8'b11111000; // 7
            4'h8: seg_out = 8'b10000000; // 8
            4'h9: seg_out = 8'b10010000; // 9
            default: seg_out = 8'b11111111; // 全滅
        endcase
    end
endmodule
