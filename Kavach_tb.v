
// kavach_tb.v
// Functional Verification Testbench for Kavach ATP Core Engine
`timescale 1ns/1ps

module kavach_tb;
    reg        clk;
    reg        rst_n;
    reg  [2:0] train_type;       
    reg  [7:0] current_speed;
    reg  [15:0] rfid_tag_data;
    reg  [1:0]  signal_aspect;
    reg        opposing_train;
    reg        sos_trigger;
    
    wire [1:0] biu_brake_command;
    wire [2:0] dmi_display_alert;
    wire       auto_whistle;

    // Instantiate Device Under Test (DUT)
    kavach_core dut (
        .clk(clk),
        .rst_n(rst_n),
        .train_type(train_type),
        .current_speed(current_speed),
        .rfid_tag_data(rfid_tag_data),
        .signal_aspect(signal_aspect),
        .opposing_train(opposing_train),
        .sos_trigger(sos_trigger),
        .biu_brake_command(biu_brake_command),
        .dmi_display_alert(dmi_display_alert),
        .auto_whistle(auto_whistle)
    );

    // Clock Generator: Configured to terminate cleanly after 30 cycles
    initial begin
        clk = 0;
        repeat (30) begin
            #20 clk = ~clk;
        end
    end

    // Verification Driver Process
    initial begin
        // Configure VCD Waveform Output Generation
        $dumpfile("dump.vcd");
        $dumpvars(0, kavach_tb);

        // Real-Time Signal Monitoring Console Log
        $monitor("TIME: %0dns | TrainType: %b | Speed: %0d km/h | BrakeCmd: %b | DisplayAlert: %b", 
                 $time, train_type, current_speed, biu_brake_command, dmi_display_alert);

        // System Initialization Reset Sequence
        rst_n = 0;
        train_type = 3'b000;
        current_speed = 0;
        rfid_tag_data = 0;
        signal_aspect = 2'b10; 
        opposing_train = 0;
        sos_trigger = 0;

        #20 rst_n = 1;
        #20;

        // TEST CASE 1: Goods Train Profile Speed Violation Control
        $display("\n--- [LOG] Starting Test: Goods Train Overspeed ---");
        train_type = 3'b100;    // Select Profile: GOODS TRAIN (Ceiling: 75 km/h)
        current_speed = 8'd85;  // Induce Overspeed Condition at 85 km/h
        #100;                   

        // TEST CASE 2: Asynchronous Radio Head-On Collision Prevention Switch
        $display("\n--- [LOG] Starting Test: Collision Sensor Activated ---");
        opposing_train = 1;     // Trip Collision Alarm
        #100;

        $display("\n--- [LOG] Simulation Finished Successfully ---");
        $finish;
    end
endmodule
