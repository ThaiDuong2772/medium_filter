// Testbench
module tb_median_filter_opt;
    reg clk, rst, start;
    wire done;
    
    median_filter_opt uut(
        .clk(clk),
        .rst(rst),
        .start(start),
        .done(done)
    );
    
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    initial begin
        rst = 1;
        start = 0;
        #20 rst = 0;
        #10 start = 1;
        #10 start = 0;
        
        wait(done);
        $display("Simulation completed successfully!");
        #100 $finish;
    end

endmodule