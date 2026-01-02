`timescale 1ns / 1ps

// Module compare và swap
module compare_swap(
    input [7:0] a,
    input [7:0] b,
    output [7:0] min,
    output [7:0] max
);
    assign min = (a < b) ? a : b;
    assign max = (a < b) ? b : a;
endmodule

// Module tính median của 9 giá trị sử dụng Sorting Network
// Sử dụng Batcher's odd-even mergesort network
module median_9(
    input [7:0] p0, p1, p2, p3, p4, p5, p6, p7, p8,
    output [7:0] median
);
    // Layer 1: So sánh các cặp
    wire [7:0] L1_0, L1_1, L1_2, L1_3, L1_4, L1_5, L1_6, L1_7;
    compare_swap cs1_0(p0, p1, L1_0, L1_1);
    compare_swap cs1_1(p3, p4, L1_2, L1_3);
    compare_swap cs1_2(p6, p7, L1_4, L1_5);
    compare_swap cs1_3(p2, p5, L1_6, L1_7);
    wire [7:0] L1_8;
    assign L1_8 = p8;

    // Layer 2
    wire [7:0] L2_0, L2_1, L2_2, L2_3, L2_4, L2_5, L2_6, L2_7, L2_8;
    compare_swap cs2_0(L1_0, L1_2, L2_0, L2_1);
    compare_swap cs2_1(L1_1, L1_3, L2_2, L2_3);
    compare_swap cs2_2(L1_4, L1_8, L2_4, L2_5);
    compare_swap cs2_3(L1_6, L1_5, L2_6, L2_7);
    assign L2_8 = L1_7;

    // Layer 3
    wire [7:0] L3_0, L3_1, L3_2, L3_3, L3_4, L3_5, L3_6, L3_7, L3_8;
    compare_swap cs3_0(L2_0, L2_4, L3_0, L3_1);
    compare_swap cs3_1(L2_1, L2_6, L3_2, L3_3);
    compare_swap cs3_2(L2_2, L2_5, L3_4, L3_5);
    compare_swap cs3_3(L2_3, L2_7, L3_6, L3_7);
    assign L3_8 = L2_8;

    // Layer 4
    wire [7:0] L4_0, L4_1, L4_2, L4_3, L4_4, L4_5, L4_6, L4_7, L4_8;
    compare_swap cs4_0(L3_1, L3_4, L4_1, L4_2);
    compare_swap cs4_1(L3_3, L3_6, L4_3, L4_4);
    compare_swap cs4_2(L3_5, L3_8, L4_5, L4_6);
    assign L4_0 = L3_0;
    assign L4_7 = L3_7;
    assign L4_8 = L3_2;

    // Layer 5
    wire [7:0] L5_0, L5_1, L5_2, L5_3, L5_4, L5_5, L5_6, L5_7, L5_8;
    compare_swap cs5_0(L4_1, L4_3, L5_1, L5_2);
    compare_swap cs5_1(L4_2, L4_4, L5_3, L5_4);
    compare_swap cs5_2(L4_5, L4_7, L5_5, L5_6);
    assign L5_0 = L4_0;
    assign L5_7 = L4_6;
    assign L5_8 = L4_8;

    // Layer 6
    wire [7:0] L6_0, L6_1, L6_2, L6_3, L6_4, L6_5, L6_6, L6_7, L6_8;
    compare_swap cs6_0(L5_2, L5_3, L6_2, L6_3);
    compare_swap cs6_1(L5_4, L5_5, L6_4, L6_5);
    assign L6_0 = L5_0;
    assign L6_1 = L5_1;
    assign L6_6 = L5_6;
    assign L6_7 = L5_7;
    assign L6_8 = L5_8;

    // Layer 7 - Final layer để lấy median
    wire [7:0] L7_3, L7_4, L7_5, L7_6;
    compare_swap cs7_0(L6_3, L6_4, L7_3, L7_4);
    compare_swap cs7_1(L6_5, L6_6, L7_5, L7_6);

    // Layer 8
    wire [7:0] L8_4, L8_5;
    compare_swap cs8_0(L7_4, L7_5, L8_4, L8_5);

    // Median là phần tử thứ 5 (index 4) sau khi sắp xếp
    assign median = L8_4;

endmodule

// Module chính - Median Filter
module median_filter_opt #(
    parameter MAX_WIDTH = 512,
    parameter MAX_HEIGHT = 512
)(
    input clk,
    input rst,
    input start,
    output reg done
);

    reg [7:0] image_in [0:MAX_HEIGHT*MAX_WIDTH-1];
    reg [7:0] image_out [0:MAX_HEIGHT*MAX_WIDTH-1];
    
    integer height, width;
    integer i;
    integer file_in, file_out;
    
    reg [7:0] win0, win1, win2, win3, win4, win5, win6, win7, win8;
    wire [7:0] median_out;
    
    // Instantiate median module
    median_9 med9(
        .p0(win0), .p1(win1), .p2(win2),
        .p3(win3), .p4(win4), .p5(win5),
        .p6(win6), .p7(win7), .p8(win8),
        .median(median_out)
    );
    
    reg [2:0] state;
    localparam IDLE     = 3'd0;
    localparam LOAD_WIN = 3'd1;
    localparam CALC     = 3'd2;
    localparam WRITE    = 3'd3;
    localparam DONE_ST  = 3'd4;
    
    integer row, col;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            done <= 0;
            row <= 0;
            col <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        file_in = $fopen("C:/Workspace/uit_k18/VHDL/Thuc_Hanh/Lab2/medium_filter/pic_input.txt", "r");
                        if (file_in == 0) begin
                            $display("Error: Cannot open pic_input.txt");
                            $finish;
                        end
                        $fscanf(file_in, "%d %d\n", height, width);
                        $display("Image size: %dx%d", height, width);
                        
                        for (i = 0; i < height * width; i = i + 1) begin
                            $fscanf(file_in, "%d\n", image_in[i]);
                        end
                        $fclose(file_in);
                        
                        row <= 0;
                        col <= 0;
                        state <= LOAD_WIN;
                    end
                end
                
                LOAD_WIN: begin
                    if (row < height) begin
                        if (row == 0 || row == height-1 || col == 0 || col == width-1) begin
                            // Biên: giữ nguyên giá trị
                            image_out[row * width + col] <= image_in[row * width + col];
                            
                            // Chuyển sang pixel tiếp theo
                            if (col >= width - 1) begin
                                col <= 0;
                                row <= row + 1;
                            end else begin
                                col <= col + 1;
                            end
                        end else begin
                            // Load 3x3 window
                            win0 <= image_in[(row-1) * width + (col-1)];
                            win1 <= image_in[(row-1) * width + col];
                            win2 <= image_in[(row-1) * width + (col+1)];
                            win3 <= image_in[row * width + (col-1)];
                            win4 <= image_in[row * width + col];
                            win5 <= image_in[row * width + (col+1)];
                            win6 <= image_in[(row+1) * width + (col-1)];
                            win7 <= image_in[(row+1) * width + col];
                            win8 <= image_in[(row+1) * width + (col+1)];
                            
                            state <= CALC;
                        end
                    end else begin
                        state <= WRITE;
                    end
                end
                
                CALC: begin
                    // Ghi kết quả median
                    image_out[row * width + col] <= median_out;
                    
                    // Chuyển sang pixel tiếp theo
                    if (col >= width - 1) begin
                        col <= 0;
                        row <= row + 1;
                    end else begin
                        col <= col + 1;
                    end
                    
                    state <= LOAD_WIN;
                end
                
                WRITE: begin
                    file_out = $fopen("C:/Workspace/uit_k18/VHDL/Thuc_Hanh/Lab2/medium_filter/pic_output.txt", "w");
                    $fwrite(file_out, "%d %d\n", height, width);
                    
                    for (i = 0; i < height * width; i = i + 1) begin
                        $fwrite(file_out, "%d\n", image_out[i]);
                    end
                    $fclose(file_out);
                    
                    $display("Processing complete!");
                    state <= DONE_ST;
                end
                
                DONE_ST: begin
                    done <= 1;
                end
            endcase
        end
    end

endmodule

