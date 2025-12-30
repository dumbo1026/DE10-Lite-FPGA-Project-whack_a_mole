`define TimeExpire_sec 32'd25000000
`define TimeExpire_keypad 32'd250000
`define TimeExpire_dotMatrix 32'd2500

`define MAX_SCORE 3'd999    // 999 points
`define GAME_TIME 7'd60     // 60 seconds

module whack_a_mole (
    input wire clk,
    input wire start,               // start button
    input wire reset,               // reset button
    input wire [3:0] keypadCol,

    output wire [3:0] keypadRow,
    output wire [6:0] seg_score_0,           // 3-digit 7-segment display for score
    output wire [6:0] seg_score_1,
    output wire [6:0] seg_score_2,
    output wire [6:0] seg_time_left_0,       // 2-digit 7-segment display for time left
    output wire [6:0] seg_time_left_1,
    output wire [7:0] dotRow, output wire [7:0] dotCol
    // 8x8 dot matrix for mole display 
);
    wire is_started;            // turn to 1 when the game is started，由 game_state 控制
    wire [9:0] score;           // 由 score_display 控制
    wire [5:0] time_left;       // 由 time_display 控制

    wire  [2:0] row_seed = 3'b101;       // seed for lfsr3
    wire  [2:0] col_seed = 3'b011;       // should be non-zero

    wire [1:0] rand_position_row, rand_position_col;     // random position generated for mole  (00 01 10 11)
    wire [1:0] mole_position_row, mole_position_col;     // current mole position on dot matrix (00 01 10 11)
    wire mole_is_hitted;        // 由 keypad_controller 控制

    wire clk_sec, clk_keypad, clk_dotMatrix;

    clk_div clk_div_sec (clk, reset, `TimeExpire_sec, clk_sec);
    clk_div clk_div_keypad (clk, reset, `TimeExpire_keypad, clk_keypad);
    clk_div clk_div_dotMatrix (clk, reset, `TimeExpire_dotMatrix, clk_dotMatrix);

    random_position_generator rpg_m (clk_dotMatrix, reset, row_seed, col_seed, rand_position_row, rand_position_col);

    game_state game_state_m (reset, start, clk_sec, time_left, is_started);

    mole_position_updater mole_position_updater_m (clk_dotMatrix, is_started, mole_is_hitted, rand_position_row, rand_position_col, mole_position_row, mole_position_col);

    dot_matrix dot_matrix_m (clk_dotMatrix, is_started, mole_position_row, mole_position_col, dotRow, dotCol);

    keypad_controller keypad_controller_m (clk_keypad, is_started, keypadCol, mole_position_row, mole_position_col, mole_is_hitted, keypadRow);

    score_display score_display_m (clk, reset, mole_is_hitted, score, seg_score_0, seg_score_1, seg_score_2);

    time_display time_display_m (clk_sec, reset, is_started, time_left, seg_time_left_0, seg_time_left_1);

endmodule


// 任務 (1)
// 管理 output_clk
module clk_div (
    input wire         clk,
    input wire         rst,
    input wire  [31:0] TimeExpire,
    output reg         output_clk
);
// input 包含 clk, rst. output_clk, 其中一種 TimeExpire

/*
要求:
    1. 當 rst = 0 時, 重製 clk, output_clk
    2. 當 rst = 1 時, output_clk 每經過 TimeExpire 個 clk 週期就翻轉一次
*/

endmodule


// 偽隨機數產生器 (產生地鼠位置)
module lfsr3 (
    input  wire       clk,
    input  wire       rst,    // reset
    input  wire [2:0] seed,   // should be non-zero
    output reg  [1:0] out     // 2-bit output
);
    reg [2:0] state;
    wire feedback = state[2] ^ state[0];

    always @(posedge clk or negedge rst) begin      // 以 clk_dotMatrix 產生隨機數
        if (!rst) begin
            state <= (seed == 3'b000) ? 3'b001 : seed;
        end
        else begin
            state <= {feedback, state[2:1]};
        end
    end

    always @(*) begin
        case (state[1:0])
            2'b00: out = 2'd0;
            2'b01: out = 2'd1;
            2'b10: out = 2'd2;
            2'b11: out = 2'd3;
            default: out = 2'd0;
        endcase
    end
endmodule


// 地鼠位置產生器 (管理 rand_row, rand_col)
module random_position_generator (
    input wire  clk,
    input wire  rst,
    input wire [2:0] row_seed,
    input wire [2:0] col_seed,

    output reg [1:0] rand_row,
    output reg [1:0] rand_col
);
    lfsr3 lfsr3_m_row (clk, rst, row_seed, rand_row);

    lfsr3 lfsr3_m_col (clk, rst, col_seed, rand_col);

endmodule


// 遊戲狀態 (管理 is_started)
module game_state (
    input wire       reset,
    input wire       start,
    input wire       clk_sec,
    input wire [5:0] time_left,
    output reg       is_started = 0
);
    always @(negedge reset or posedge clk_sec) begin
        if (!reset) begin
            is_started <= 1'b0;
        end
        else if (!start) begin
            is_started <= 1'b1;
        end
        else if (is_started && time_left == 0) begin
            is_started <= 1'b0;
        end
    end

endmodule


// 地鼠位置更新 (管理 mole_position)
module mole_position_updater (
    input wire       clk_dotMatrix,
    input wire       is_started,
    input wire       mole_is_hitted,
    input wire [1:0] rand_position_row,
    input wire [1:0] rand_position_col,
    output reg [1:0] mole_position_row,
    output reg [1:0] mole_position_col
);
    always @(posedge clk_dotMatrix) begin    // 地鼠位置更新
        if (is_started && mole_is_hitted) begin
            mole_position_row <= rand_position_row;
            mole_position_col <= rand_position_col;
            // mole_is_hitted 的更新交給 score_display 模組
        end
    end

endmodule


// 任務 (2)
// 管理 dotRow, dotCol
// module dot_matrix (
//     input wire       clk,
//     input wire       is_started,
//     input wire [1:0] mole_row,
//     input wire [1:0] mole_col,
//     output reg [7:0] dotRow,
//     output reg [7:0] dotCol
// );

// 1. input 包含 clk, is_started, mole_row, mole_col
// 2. output 為 dotRow, dotCol

/*
要求:
    1. 當 is_started = 0 時, 代表遊戲尚未開始或已結束, 設計並顯示一個 dotMatrix 圖案 (自由發揮)
    2. 當 is_started = 1 時, 根據 mole_row, mole_col 即時顯示地鼠位置 (地鼠大小 2x2)
*/
module dot_matrix (
    input wire        clk,          // 連接至 clk_dotMatrix (掃描時鐘)
    input wire        rst,          // [新增] 連接至 reset (系統重置)
    input wire        is_started,   // 遊戲狀態
    input wire [1:0]  mole_row,     // 地鼠邏輯列 (0~3)
    input wire [1:0]  mole_col,     // 地鼠邏輯行 (0~3)
    output reg [7:0]  dotRow,       // 物理列輸出 (Active Low: 0為亮)
    output reg [7:0]  dotCol        // 物理行輸出 (Active High: 1為亮)
);

    // 掃描計數器 (0~7)
    reg [2:0] scan_cnt;

    // 1. 掃描計數器控制 (加入 Reset 確保初始狀態確定)
    always @(posedge clk or negedge rst) begin
        if (!rst)
            scan_cnt <= 3'd0;
        else
            scan_cnt <= scan_cnt + 1;
    end

    // 2. Row Driver: 控制列掃描 (Active Low)
    // 利用位移運算產生循環的 0 (例如: 11111110 -> 11111101...)
    always @(*) begin
        dotRow = ~(8'd1 << scan_cnt);
    end

    // 3. Col Driver: 控制行數據 (顯示圖案)
    always @(*) begin
        if (!is_started) begin
            // --- 待機模式：顯示同心方塊動畫效果 (靜態圖案，依靠視覺暫留) ---
            case (scan_cnt)
                3'd0, 3'd7: dotCol = 8'b11111111; // 上下邊框
                3'd1, 3'd6: dotCol = 8'b10000001; // 外圈
                3'd2, 3'd5: dotCol = 8'b10111101; // 中圈
                3'd3, 3'd4: dotCol = 8'b10100101; // 內圈
                default:    dotCol = 8'h00;
            endcase
        end 
        else begin
            // --- 遊戲模式：顯示 2x2 地鼠 ---
            // 邏輯：scan_cnt[2:1] 等於除以 2，將 0~7 的物理列映射到 0~3 的邏輯列
            if (scan_cnt[2:1] == mole_row) begin
                // 根據 mole_col 決定水平位置
                // 3 (二進制 11) 代表地鼠寬度為 2 點
                // 左移 (mole_col * 2) 格
                dotCol = 8'd3 << (mole_col * 2);
            end 
            else begin
                dotCol = 8'h00;
            end
        end
    end

endmodule

    
//endmodule


// 任務 (3)
// 管理 keypadRow, mole_is_hitted
module keypad_controller (
    input wire       clk,
    input wire       is_started,
    input wire [3:0] keypadCol,
    input wire [1:0] mole_row,
    input wire [1:0] mole_col,
    output reg       mole_is_hitted = 0,
    output reg [3:0] keypadRow
);

// 1. input 包含 clk, is_started, keypadCol, mole_row, mole_col
// 2. output 為  keypadRow, mole_is_hitted

/*
要求:
    1. 當 is_started = 0 時, keypadRow 設為 4'b0000
    2. 當 is_started = 1 時, 根據 keypadRow, keypadCol 與 mole_row, mole_col 判斷是否擊中地鼠
       若擊中了，mole_is_hitted 設為 1
       沒有擊中則什麼都不做 (你想讓他做些什麼也可以)
    3. 每一次的 clk posedge 都要將 mole_is_hitted 指派回 0
*/

endmodule


// 任務 (4)
// 管理 score, seg_score_0 ~ 2
module score_display (
    input wire clk,
    input wire reset,
    input wire mole_is_hitted,
    output reg [9:0] score = 0,
    output reg [6:0] seg_score_0, seg_score_1, seg_score_2
);
    reg hitted_d1;
    always @(posedge clk or negedge reset) begin
        if (!reset) score <= 0;
        else begin
            hitted_d1 <= mole_is_hitted;
            if (mole_is_hitted && !hitted_d1 && score < `MAX_SCORE)  // 避免連續加分
                score <= score + 1;
        end
    end
    /*
    要求:
        將 score 轉換成 3-digit 7-segment display 即時顯示在 seg_score_0 ~ 2 上
    */
endmodule


// 任務 (5)
// 管理 time_left, seg_time_left_0 ~ 1
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

endmodule
