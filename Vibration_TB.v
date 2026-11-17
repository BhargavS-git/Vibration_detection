`timescale 1ns / 1ns

module vibration_detector_tb;
    reg clk;
    reg rst_n;
    reg [7:0] accel_data;
    wire anomaly_flag;
    wire [3:0] confidence_counter;

    // Unit Under Test (UUT)
    vibration_anomaly_detector uut (
        .clk(clk),
        .rst_n(rst_n),
        .accel_data(accel_data),
        .anomaly_flag(anomaly_flag),
        .confidence_counter(confidence_counter)
    );

    // Clock Generation: 1 MHz Frequency (Period = 1000ns)
    always #500 clk = ~clk;

    initial begin
        clk = 0;
        rst_n = 0;
        accel_data = 8'd100;
        
        // Release Active-Low Reset
        #2000 rst_n = 1;

        // Scenario A: Normal Operating Vibration (Low delta variation)
        repeat(10) begin
            #1000 accel_data = 8'd102;
            #1000 accel_data = 8'd100;
        end

        // Scenario B: Structural Fault Injection (Rapid Bearing Wear / High Vibration)
        repeat(30) begin
            #1000 accel_data = 8'd145; // Induces heavy delta-spikes
            #1000 accel_data = 8'd85;
        end

        // Return to Normal to test tracking recovery
        repeat(10) begin
            #1000 accel_data = 8'd101;
            #1000 accel_data = 8'd100;
        end

        #5000 $finish;
    end

    // Monitor Performance Signoff
    initial begin
        $monitor("Time=%0t ns | Accel Data=%d | Confidence=%d | Anomaly Flag=%b", 
                 $time, accel_data, confidence_counter, anomaly_flag);
    end

endmodule
