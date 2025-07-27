`timescale 1ns / 1ps

// Module to debounce a button input, ensuring a stable signal
module debouncer (
    input clk,
    input rst,
    input btn_in,
    output reg btn_out
);
    // Counter to measure input stability duration
    reg [20:0] counter;  
    
    always @(posedge clk) begin
        if (rst) begin 
            counter <= 0;             
            btn_out <= 0;
        end
        // If input changes, start/continue counting.
        // Update output only after the input has been stable for a defined period.
        else if (btn_in != btn_out) begin
            counter <= counter + 1;
            if (counter == 21'd2_000_000)  btn_out <= btn_in; // Threshold for stability
        end 
        // If input is stable or returns to previous state, reset counter.
        else counter <= 0;
    end
endmodule

// Generates slower clock signals (1Hz and 1kHz) from a faster input clock
module clock_divider (
    input clk,      // Input clock (100MHz)
    input rst,                      
    output reg clk_1Hz,
    output reg clk_1kHz
);
    // Counters to achieve desired frequencies by toggling output at specific counts
    reg [26:0] counter_1Hz;         // For 50_000_000 counts (100MHz / 2*1Hz)
    reg [16:0] counter_1kHz;        // For 50_000 counts (100MHz / 2*1kHz)

    // 1Hz generator
    always @(posedge clk) begin     
        if (rst) begin 
            counter_1Hz <= 0;
            clk_1Hz <= 0;
        end
        // Toggle clk_1Hz and reset counter when half period is reached
        else if (counter_1Hz == 27'd50_000_000 -1) begin    
            clk_1Hz <= ~clk_1Hz;
            counter_1Hz <= 0;
        end 
        else 
            counter_1Hz <= counter_1Hz + 1;
    end

    // 1kHz generator
    always @(posedge clk) begin     
        if(rst) begin 
            counter_1kHz <= 0;             
            clk_1kHz <= 0;
        end
        // Toggle clk_1kHz and reset counter when half period is reached
        else if (counter_1kHz == 17'd50_000 -1) begin       
            clk_1kHz <= ~clk_1kHz;
            counter_1kHz <= 0;
        end 
        else 
            counter_1kHz <= counter_1kHz + 1;
    end
endmodule

// Finite State Machine to control vehicle light logic
module fsm (
    input clk,
    input rst,
    input brake_btn,
    input emergency_btn,
    input reverse_sw,
    input left_sw,
    input right_sw,
    input four_way_sw,
    input blink,                   // 1Hz clock for blinking
    // LED outputs: [reverse, brake_L, brake_R, turn_L, turn_R]
    output reg [4:0] leds,         
    output reg emergency_active    
);

    // State definitions
    localparam[2:0]
     EMERGENCY  = 3'd0,
     LEFT_TURN  = 3'd1,
     RIGHT_TURN = 3'd2,
     FOUR_WAY   = 3'd3,
     NORMAL     = 3'd4;
    
    reg [2:0] current_state, next_state;

    // Internal signal for turn indicator LEDs {left, right}
    reg [1:0] turn_leds;            

    // Sequential logic for state register
    always @(posedge clk) begin
        if (rst) current_state <= NORMAL;
        else current_state <= next_state;
    end

    // Combinational logic for state transitions
    always @(*) begin
        next_state = current_state; // Default: remain in current state
        
        // Emergency button toggles EMERGENCY state and has highest priority
        if (emergency_btn) begin
            next_state = (current_state == EMERGENCY) ? NORMAL : EMERGENCY;
        end
        // Logic for other states if not in or transitioning to/from EMERGENCY
        else if (current_state != EMERGENCY) begin
            case (current_state)
                NORMAL: begin // From NORMAL, can go to turn signals or four-way
                    if (four_way_sw)       next_state = FOUR_WAY;
                    else if (left_sw)      next_state = LEFT_TURN;
                    else if (right_sw)     next_state = RIGHT_TURN;
                end
                // Return to NORMAL if respective switch is turned off
                LEFT_TURN:  if (!left_sw && !four_way_sw)   next_state = NORMAL;
                RIGHT_TURN: if (!right_sw && !four_way_sw)  next_state = NORMAL;
                FOUR_WAY:   if (!four_way_sw)               next_state = NORMAL;
            endcase
        end
    end

    // Combinational logic for FSM outputs (LEDs and emergency status)
    always @(*) begin
        leds = 5'b00000; // Default all off
        emergency_active = 0;
        turn_leds = 2'b00;

        // Determine turn signal behavior based on state
        case (current_state)
            LEFT_TURN:  turn_leds = {blink, 1'b0}; // Left blinks
            RIGHT_TURN: turn_leds = {1'b0, blink}; // Right blinks
            FOUR_WAY:   turn_leds = {blink, blink}; // Both blink
            EMERGENCY:  turn_leds = {blink, blink}; // Both blink
            default:    turn_leds = 2'b00;
        endcase

        // Output logic for LEDs based on state and inputs
        if (current_state == EMERGENCY) begin
            emergency_active = 1;
            // In EMERGENCY: turn signals blink, brake lights are solid ON
            leds[1] = turn_leds[1]; // turn_L
            leds[0] = turn_leds[0]; // turn_R
            leds[3] = 1'b1;         // brake_L
            leds[2] = 1'b1;         // brake_R
            leds[4] = reverse_sw;   // reverse light
        end else begin // Normal operation
            emergency_active = 0;
            leds[1] = turn_leds[1]; // turn_L
            leds[0] = turn_leds[0]; // turn_R
            if (brake_btn) begin    // Brake lights active if brake_btn pressed
                leds[3] = 1'b1;
                leds[2] = 1'b1;
            end
            leds[4] = reverse_sw;   // reverse light
        end
    end
endmodule

// Timer to count minutes and seconds, active during emergency mode
module emergency_timer (
    input clk,              // Clocked by 1Hz for second counting
    input reset_as,         // Asynchronous reset (active high to reset timer)
    input enable,           // Enables counting when emergency is active
    output reg [3:0] minutes,
    output reg [5:0] seconds
);
    // Synchronize asynchronous reset to the local clock domain
    reg reset_sync;
    always @(posedge clk) reset_sync <= reset_as;
    
    // Counter logic for seconds and minutes (up to 15:59)
    always @(posedge clk) begin
        if (reset_sync || !enable) begin // Reset if reset asserted or not enabled
            minutes <= 0;
            seconds <= 0;
        end
        else if (enable) begin // Count when enabled
            if (seconds == 59) begin
                seconds <= 0;
                minutes <= (minutes == 15) ? 0 : minutes + 1; // Minutes roll over at 15
            end
            else seconds <= seconds + 1;
        end
    end
endmodule

// Drives a 4-digit 7-segment display to show minutes and seconds
module seven_seg_driver (
    input clk_1kHz,         // Clock for display refresh and multiplexing
    input rst,              
    input enable,           // Enables the display output
    input [3:0] minutes,
    input [5:0] seconds,
    output reg [7:0] AN,    // Anode control (active low)
    output reg [6:0] segments // Segment control (active low)
);
    reg [1:0] digit_sel;    // Selects one of the 4 digits to activate
    reg [3:0] digit_value;  // BCD value for the selected digit
    
    // Internal registers for synchronizing time inputs
    reg [3:0] minutes_reg;
    reg [5:0] seconds_reg;
    
    // Convert registered time to BCD for each digit
    wire [3:0] min_tens = minutes_reg / 10;
    wire [3:0] min_units = minutes_reg % 10;
    wire [3:0] sec_tens = seconds_reg / 10;
    wire [3:0] sec_units = seconds_reg % 10;
    
    // Main logic for display multiplexing and BCD-to-7-segment conversion
    always @(posedge clk_1kHz) begin
        if (rst || !enable) begin // If reset or disabled, turn off display
            digit_sel <= 2'd0;
            AN <= 8'b11111111;      // All anodes off
            segments <= 7'b1111111; // All segments off
            minutes_reg <= 0;
            seconds_reg <= 0;
        end
        else begin
            minutes_reg <= minutes; // Latch current time
            seconds_reg <= seconds;
            
            AN <= 8'b11111111; // Briefly turn off anodes to prevent ghosting
            
            // Select active digit and its BCD value based on digit_sel
            case (digit_sel)
                2'd0: begin AN <= 8'b11111110; digit_value = sec_units; end 
                2'd1: begin AN <= 8'b11111101; digit_value = sec_tens;  end 
                2'd2: begin AN <= 8'b11111011; digit_value = min_units; end 
                2'd3: begin AN <= 8'b11110111; digit_value = min_tens;  end 
            endcase
            
            // BCD to 7-segment decoder (common anode, active low segments)
            case (digit_value)
                4'h0: segments <= 7'b1000000; // 0
                4'h1: segments <= 7'b1111001; // 1
                4'h2: segments <= 7'b0100100; // 2
                4'h3: segments <= 7'b0110000; // 3
                4'h4: segments <= 7'b0011001; // 4
                4'h5: segments <= 7'b0010010; // 5
                4'h6: segments <= 7'b0000010; // 6
                4'h7: segments <= 7'b1111000; // 7
                4'h8: segments <= 7'b0000000; // 8
                4'h9: segments <= 7'b0010000; // 9
                default: segments <= 7'b1111111; // Blank
            endcase
            
            digit_sel <= digit_sel + 1; // Cycle to the next digit
        end
    end
endmodule

// Top-level module: integrates debouncers, clock divider, FSM, timer, and display driver
module top (
    input CLK100MHZ,
    input BTNC, BTNU, BTNL, // Buttons: Center (brake), Up, Left
    input [15:0] swt,       
    input rst,                  
    output [15:0] led,      
    output [7:0] AN,        
    output [6:0] segments   
);
    // Internal signals connecting the modules
    wire clk_1Hz, clk_1kHz;
    wire brake_debounced, btnu_debounced, btnl_debounced, reverse_debounced;
    wire [4:0] leds_fsm;    // LED control signals from FSM
    wire [3:0] minutes;
    wire [5:0] seconds;
    wire emergency_active;  

    // Instantiate clock divider for 1Hz (blink) and 1kHz (display refresh)
    clock_divider clk_div(CLK100MHZ, rst, clk_1Hz, clk_1kHz);

    // Instantiate debouncers for critical inputs
    debouncer deb_brake(CLK100MHZ, rst, BTNC, brake_debounced);
    debouncer deb_reverse(CLK100MHZ, rst, swt[8], reverse_debounced); // swt[8] as reverse
    debouncer deb_u(CLK100MHZ, rst, BTNU, btnu_debounced);
    debouncer deb_l(CLK100MHZ, rst, BTNL, btnl_debounced);
    // Emergency is triggered by BTNU AND BTNL
    wire emergency_btn = btnu_debounced & btnl_debounced;

    // Instantiate the main FSM for light control logic
    fsm fsm_inst(
        .clk(CLK100MHZ), // FSM clocked by main system clock
        .rst(rst),                              
        .brake_btn(brake_debounced),
        .emergency_btn(emergency_btn),
        .reverse_sw(reverse_debounced),
        .left_sw(swt[15]),          
        .right_sw(swt[0]),          
        .four_way_sw(swt[7]),      
        .blink(clk_1Hz),           
        .leds(leds_fsm),            // FSM's internal LED representation
        .emergency_active(emergency_active)
    );

    // Instantiate emergency timer: runs on 1Hz, enabled by emergency_active, and reset when emergency is not active.
    emergency_timer timer(clk_1Hz, ~emergency_active, emergency_active, minutes, seconds);
    
    // Instantiate 7-segment display driver: refreshed by 1kHz, displays timer values, enabled by emergency_active.
    seven_seg_driver display(clk_1kHz, rst, emergency_active, minutes, seconds, AN, segments);

    // Map FSM's logical LED outputs to physical board LEDs
    // FSM leds_fsm mapping: [4:reverse, 3:brake_L, 2:brake_R, 1:turn_L, 0:turn_R]
    assign led[0]  = leds_fsm[2];               // Physical led[0] = Right Brake
    assign led[15] = leds_fsm[3];               // Physical led[15] = Left Brake
    assign led[7]  = leds_fsm[2] | leds_fsm[3]; // Physical led[7] = Center Brake 
    assign led[1]  = leds_fsm[0];               // Physical led[1] = Right Turn
    assign led[14] = leds_fsm[1];               // Physical led[14] = Left Turn
    assign led[6]  = leds_fsm[4];               // Physical led[6] = Reverse

endmodule
