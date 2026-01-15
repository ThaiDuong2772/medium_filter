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

// Module line buffer - lưu 2 dòng trước
module line_buffer #(
    parameter MAX_WIDTH = 512
)(
    input clk,
    input rst,
    input write_enable,
    input [7:0] pixel_in,
    input [9:0] write_addr,
    input [9:0] read_addr1,
    input [9:0] read_addr2,
    output reg [7:0] pixel_out1,
    output reg [7:0] pixel_out2
);
    reg [7:0] line1 [0:MAX_WIDTH-1];
    reg [7:0] line2 [0:MAX_WIDTH-1];
    
    always @(posedge clk) begin
        if (write_enable) begin
            line2[write_addr] <= line1[write_addr];
            line1[write_addr] <= pixel_in;
        end
        pixel_out1 <= line1[read_addr1];
        pixel_out2 <= line2[read_addr2];
    end
endmodule

// Module chính - Median Filter tối ưu pipeline
module median_filter_opt #(
    parameter MAX_WIDTH = 512,
    parameter MAX_HEIGHT = 512
)(
    input clk,
    input rst,
    input start,
    output reg done,
    output reg processing
);

    // Memory cho ảnh
    reg [7:0] image_mem [0:MAX_HEIGHT*MAX_WIDTH-1];
    
    // Kích thước ảnh
    reg [15:0] height, width;
    reg [31:0] total_pixels;
    
    // Counter
    reg [31:0] pixel_count;
    reg [15:0] row, col;
    
    // Line buffer signals
    wire [7:0] line1_out, line2_out;
    reg [7:0] current_pixel;
    reg line_buffer_we;
    reg [9:0] lb_write_addr, lb_read_addr;
    
    // Window registers (3x3)
    reg [7:0] w00, w01, w02;
    reg [7:0] w10, w11, w12;
    reg [7:0] w20, w21, w22;
    
    // Median calculation
    wire [7:0] median_result;
    
    // Pipeline stages
    reg [2:0] pipeline_stage;
    reg [15:0] pipeline_row, pipeline_col;
    reg [7:0] pipeline_pixel;
    reg pipeline_valid;
    
    // Line buffer instance
    line_buffer #(.MAX_WIDTH(MAX_WIDTH)) lb (
        .clk(clk),
        .rst(rst),
        .write_enable(line_buffer_we),
        .pixel_in(current_pixel),
        .write_addr(lb_write_addr),
        .read_addr1(lb_read_addr),
        .read_addr2(lb_read_addr),
        .pixel_out1(line1_out),
        .pixel_out2(line2_out)
    );
    
    // Median filter instance
    median_9 median_calc (
        .p0(w00), .p1(w01), .p2(w02),
        .p3(w10), .p4(w11), .p5(w12),
        .p6(w20), .p7(w21), .p8(w22),
        .median(median_result)
    );
    
    // State machine
    reg [3:0] state;
    localparam IDLE         = 4'd0;
    localparam LOAD_IMAGE   = 4'd1;
    localparam INIT_PROCESS = 4'd2;
    localparam PROCESS_ROW0 = 4'd3;
    localparam PROCESS_ROW1 = 4'd4;
    localparam LOAD_WINDOW  = 4'd5;
    localparam CALC_MEDIAN  = 4'd6;
    localparam WRITE_PIXEL  = 4'd7;
    localparam NEXT_PIXEL   = 4'd8;
    localparam SAVE_IMAGE   = 4'd9;
    localparam FINISH       = 4'd10;
    
    // File handles
    integer file_in, file_out, status;
    reg [31:0] addr;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            done <= 0;
            processing <= 0;
            pixel_count <= 0;
            row <= 0;
            col <= 0;
            line_buffer_we <= 0;
            pipeline_valid <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        file_in = $fopen("C:/Workspace/uit_k18/VHDL/Thuc_Hanh/Lab2/medium_filter/pic_input.txt", "r");
                        if (file_in == 0) begin
                            $display("Error: Cannot open pic_input.txt");
                            done <= 1;
                        end else begin
                            status = $fscanf(file_in, "%d %d\n", height, width);
                            total_pixels = height * width;
                            $display("Image size: %dx%d", height, width);
                            pixel_count <= 0;
                            addr <= 0;
                            state <= LOAD_IMAGE;
                            processing <= 1;
                        end
                    end
                end
                
                LOAD_IMAGE: begin
                    if (addr < total_pixels) begin
                        status = $fscanf(file_in, "%d\n", image_mem[addr]);
                        addr <= addr + 1;
                    end else begin
                        $fclose(file_in);
                        row <= 0;
                        col <= 0;
                        state <= INIT_PROCESS;
                    end
                end
                
                INIT_PROCESS: begin
                    // Copy hàng đầu tiên (biên)
                    if (col < width) begin
                        image_mem[col] <= image_mem[col];
                        col <= col + 1;
                    end else begin
                        row <= 1;
                        col <= 0;
                        state <= PROCESS_ROW1;
                    end
                end
                
                PROCESS_ROW1: begin
                    if (row < height - 1) begin
                        if (col == 0) begin
                            // Biên trái
                            image_mem[row * width] <= image_mem[row * width];
                            col <= 1;
                        end else if (col >= width - 1) begin
                            // Biên phải
                            image_mem[row * width + width - 1] <= image_mem[row * width + width - 1];
                            row <= row + 1;
                            col <= 0;
                        end else begin
                            // Load window 3x3
                            addr <= (row - 1) * width + (col - 1);
                            state <= LOAD_WINDOW;
                        end
                    end else begin
                        // Copy hàng cuối (biên)
                        col <= 0;
                        state <= PROCESS_ROW0;
                    end
                end
                
                LOAD_WINDOW: begin
                    // Load 3x3 window từ memory
                    w00 <= image_mem[(row-1) * width + (col-1)];
                    w01 <= image_mem[(row-1) * width + col];
                    w02 <= image_mem[(row-1) * width + (col+1)];
                    w10 <= image_mem[row * width + (col-1)];
                    w11 <= image_mem[row * width + col];
                    w12 <= image_mem[row * width + (col+1)];
                    w20 <= image_mem[(row+1) * width + (col-1)];
                    w21 <= image_mem[(row+1) * width + col];
                    w22 <= image_mem[(row+1) * width + (col+1)];
                    
                    pipeline_row <= row;
                    pipeline_col <= col;
                    state <= CALC_MEDIAN;
                end
                
                CALC_MEDIAN: begin
                    // Median được tính tổ hợp, chờ 1 cycle
                    pipeline_pixel <= median_result;
                    state <= WRITE_PIXEL;
                end
                
                WRITE_PIXEL: begin
                    // Ghi kết quả
                    image_mem[pipeline_row * width + pipeline_col] <= pipeline_pixel;
                    col <= col + 1;
                    state <= PROCESS_ROW1;
                end
                
                PROCESS_ROW0: begin
                    if (col < width) begin
                        image_mem[(height-1) * width + col] <= image_mem[(height-1) * width + col];
                        col <= col + 1;
                    end else begin
                        state <= SAVE_IMAGE;
                        addr <= 0;
                    end
                end
                
                SAVE_IMAGE: begin
                    if (addr == 0) begin
                        file_out = $fopen("pic_output.txt", "w");
                        $fwrite(file_out, "%d %d\n", height, width);
                        addr <= 1;
                    end else if (addr <= total_pixels) begin
                        $fwrite(file_out, "%d\n", image_mem[addr-1]);
                        addr <= addr + 1;
                    end else begin
                        $fclose(file_out);
                        $display("Processing complete!");
                        state <= FINISH;
                    end
                end
                
                FINISH: begin
                    done <= 1;
                    processing <= 0;
                end
            endcase
        end
    end

endmodule