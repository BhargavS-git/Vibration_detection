`timescale 1ns / 1ns

module vibration_anomaly_detector (
    input wire clk,
    input wire rst_n,
    input wire [7:0] accel_data, // 8-bit streaming accelerometer data
    output reg anomaly_flag,
    output reg [3:0] confidence_counter
);

    // Internal Registers
    reg [7:0] prev_accel_data;
    reg delta_spike;
    reg [7:0] neuron_membrane_potential;
    reg neuron_spike;
    reg [7:0] normal_activity_window;

    // Parameters for Neuromorphic Layer
    parameter DELTA_THRESHOLD = 8'd15;
    parameter LIF_THRESHOLD   = 8'd50;
    parameter LIF_DECAY       = 8'd5;

    // 1. Delta-Modulation Spike Encoder
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev_accel_data <= 8'b0;
            delta_spike     <= 1'b0;
        end else begin
            prev_accel_data <= accel_data;
            if ((accel_data > prev_accel_data && (accel_data - prev_accel_data) > DELTA_THRESHOLD) ||
                (prev_accel_data > accel_data && (prev_accel_data - accel_data) > DELTA_THRESHOLD)) begin
                delta_spike <= 1'b1; // Generate spike on high-frequency delta deviation
            end else begin
                delta_spike <= 1'b0;
            end
        end
    end

    // 2. Leaky Integrate-and-Fire (LIF) Neuron Processing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            neuron_membrane_potential <= 8'b0;
            neuron_spike              <= 1'b0;
        end else begin
            if (neuron_spike) begin
                neuron_membrane_potential <= 8'b0; // Reset after spike
                neuron_spike              <= 1'b0;
            end else begin
                // Integrate spike energy and apply passive leakage
                if (delta_spike) begin
                    if (neuron_membrane_potential + 8'd20 >= LIF_THRESHOLD) begin
                        neuron_spike <= 1'b1;
                    end else begin
                        neuron_membrane_potential <= neuron_membrane_potential + 8'd20 - LIF_DECAY;
                    end
                end else if (neuron_membrane_potential > LIF_DECAY) begin
                    neuron_membrane_potential <= neuron_membrane_potential - LIF_DECAY;
                end else begin
                    neuron_membrane_potential <= 8'b0;
                end
            end
        end
    end

    // 3. Spike Pattern Correlator & Confidence Scoring
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            normal_activity_window <= 8'b0;
            confidence_counter     <= 4'b0;
            anomaly_flag           <= 1'b0;
        end else begin
            // Shift register tracking temporal firing patterns
            normal_activity_window <= {normal_activity_window[6:0], neuron_spike};
            
            // If spike density becomes too high (indicating bearing wear or excessive vibrations)
            if (normal_activity_window > 8'b0000_1111) begin
                if (confidence_counter < 4'd15)
                    confidence_counter <= confidence_counter + 1;
            end else if (confidence_counter > 0) begin
                confidence_counter <= confidence_counter - 1;
            end

            // Assert anomaly flag when confidence crosses evaluation threshold
            if (confidence_counter >= 4'd10) begin
                anomaly_flag <= 1'b1;
            end else begin
                anomaly_flag <= 1'b0;
            end
        end
    end

endmodule
