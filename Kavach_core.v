Kavach_core.v
// kavach_core.v
// RTL Design of Kavach (TCAS) Automatic Train Protection Onboard Core

module kavach_core (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [2:0]  train_type,        
    input  wire [7:0]  current_speed,
    input  wire [15:0] rfid_tag_data,
    input  wire [1:0]  signal_aspect,
    input  wire        opposing_train,
    input  wire        sos_trigger,
    output reg  [1:0]  biu_brake_command,
    output reg  [2:0]  dmi_display_alert,
    output reg         auto_whistle
);

    // Finite State Machine (FSM) States
    parameter NORMAL           = 3'b000;
    parameter OVERSPEED_WARN   = 3'b001;
    parameter NORMAL_BRAKING   = 3'b010;
    parameter EMERGENCY_STOP   = 3'b011;

    reg [2:0] current_state, next_state;

    // Train Profile Constants
    parameter VANDE_BHARAT  = 3'b000;
    parameter GOODS         = 3'b100;

    // Trackside Hardware Marker IDs
    parameter WHISTLE_RFID_TAG = 16'hAFAF; 
    parameter SPAD_RFID_TAG    = 16'hEFEF;

    reg [7:0] max_speed_limit;
    reg [3:0] warn_counter;

    // Dynamic Speed Ceiling Selection Matrix
    always @(*) begin
        case (train_type)
            VANDE_BHARAT: max_speed_limit = 8'd160; 
            GOODS:        max_speed_limit = 8'd75;  
            default:      max_speed_limit = 8'd110; 
        endcase
    end

    // Sequential Process: State Memory Register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= NORMAL;
            warn_counter  <= 4'd0;
        end else begin
            current_state <= next_state;
            if (current_state == OVERSPEED_WARN)
                warn_counter <= warn_counter + 1'b1;
            else
                warn_counter <= 4'd0;
        end
    end

    // Combinational Process: FSM Next-State Logic Routing
    always @(*) begin
        next_state = current_state;
        
        // High-Priority Asynchronous System Safety Overrides
        if (opposing_train || sos_trigger || (signal_aspect == 2'b00 && rfid_tag_data == SPAD_RFID_TAG)) begin
            next_state = EMERGENCY_STOP;
        end else begin
            case (current_state)
                NORMAL: begin
                    if (current_speed > max_speed_limit)
                        next_state = OVERSPEED_WARN;
                end
                OVERSPEED_WARN: begin
                    if (current_speed <= max_speed_limit)
                        next_state = NORMAL;
                    else if (warn_counter >= 4'd10) 
                        next_state = NORMAL_BRAKING;
                end
                NORMAL_BRAKING: begin
                    if (current_speed <= max_speed_limit)
                        next_state = NORMAL;
                end
                EMERGENCY_STOP: begin
                    if (!opposing_train && !sos_trigger && current_speed == 8'd0)
                        next_state = NORMAL; 
                end
                default: next_state = NORMAL;
            endcase
        end
    end

    // Combinational Process: Output Signal Assignment
    always @(*) begin
        biu_brake_command = 2'b00;
        dmi_display_alert = 3'b000;
        auto_whistle      = 1'b0;

        if (rfid_tag_data == WHISTLE_RFID_TAG) begin
            auto_whistle = 1'b1;
        end

        case (current_state)
            NORMAL: begin
                biu_brake_command = 2'b00;
                dmi_display_alert = 3'b000;
            end
            OVERSPEED_WARN: begin
                biu_brake_command = 2'b00;
                dmi_display_alert = 3'b001; 
            end
            NORMAL_BRAKING: begin
                biu_brake_command = 2'b01; 
                dmi_display_alert = 3'b001;
            end
            EMERGENCY_STOP: begin
                biu_brake_command = 2'b10; 
                if (opposing_train)
                    dmi_display_alert = 3'b111; 
                else
                    dmi_display_alert = 3'b010; 
            end
        endcase
    end
endmodule
