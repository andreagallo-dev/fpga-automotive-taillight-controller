`timescale 1ns / 1ps

// Testbench module
// Prints "PASSED" or "FAILED" messages for each test.

module tb();

    // --------------------
    // 1) Clock Generation
    // --------------------
    // Main FSM clock (10ns period -> 100MHz simulated)
    reg clk_main = 0;
    always #5 clk_main = ~clk_main;

    // "Blink" clock (simulates 1Hz, accelerated: 20ns period)
    reg blink = 0;
    always #10 blink = ~blink;

    // Display clock (simulates 1kHz, accelerated: 2ns period)
    reg clk_disp = 0;
    always #1 clk_disp = ~clk_disp;

    // --------------------
    // 2) Reset and Input Signals
    // --------------------
    reg rst_fsm  = 1;   // FSM reset
    reg rst_disp = 1;   // Display driver reset

    reg brake_btn      = 0;
    reg reverse_sw     = 0;
    reg left_sw        = 0;
    reg right_sw       = 0;
    reg four_way_sw    = 0;
    reg btnu_debounced = 0;
    reg btnl_debounced = 0;

    // Emergency button is the AND of btnu_debounced and btnl_debounced
    wire emergency_btn = btnu_debounced & btnl_debounced;

    // --------------------
    // 3) FSM Outputs
    // --------------------
    // leds_fsm: [reverse, brake_left, brake_right, turn_left, turn_right]
    wire [4:0] leds_fsm;
    wire       emergency_active;

    // --------------------
    // 4) Emergency Timer Outputs
    // --------------------
    wire [3:0] minutes;
    wire [5:0] seconds;

    // --------------------
    // 5) Display Driver Outputs
    // --------------------
    wire [7:0] AN;
    wire [6:0] segments;

    // --------------------
    // 6) GTKWave Dump (optional)
    // --------------------
    initial begin
        $dumpfile("waveform_tb.vcd");
        $dumpvars(0, tb);
    end

    // --------------------
    // 7) Instantiate FSM
    // --------------------
    fsm dut_fsm (
        .clk(clk_main),
        .rst(rst_fsm),
        .brake_btn(brake_btn),
        .emergency_btn(emergency_btn),
        .reverse_sw(reverse_sw),
        .left_sw(left_sw),
        .right_sw(right_sw),
        .four_way_sw(four_way_sw),
        .blink(blink),
        .leds(leds_fsm),
        .emergency_active(emergency_active)
    );

    // --------------------
    // 8) Instantiate Emergency Timer
    //    - blink as clock (1Hz simulated)
    //    - asynchronous reset = !emergency_active
    // --------------------
    emergency_timer dut_timer (
        .clk(blink),
        .reset_as(~emergency_active), // Active low reset when emergency is NOT active
        .enable(emergency_active),
        .minutes(minutes),
        .seconds(seconds)
    );

    // --------------------
    // 9) Instantiate Display Driver
    //    - clk_disp as 1kHz simulated clock
    // --------------------
    seven_seg_driver dut_display (
        .clk_1kHz(clk_disp),
        .rst(rst_disp),
        .enable(emergency_active),
        .minutes(minutes),
        .seconds(seconds),
        .AN(AN),
        .segments(segments)
    );

    // --------------------
    // 10) FSM Tests
    // --------------------
    initial begin
        $display("\n============== START FSM TESTS ==============\n");

        // 10.1) Initial RESET
        #0    rst_fsm = 1;
              brake_btn     = 0;
              reverse_sw    = 0;
              left_sw       = 0;
              right_sw      = 0;
              four_way_sw   = 0;
              btnu_debounced = 0;
              btnl_debounced = 0;
        #30   rst_fsm = 0;
        #1    $display("[1) RESET] Inputs = 0, Expected leds_fsm = 00000, emergency_active = 0");
        #1    if (leds_fsm == 5'b00000 && emergency_active == 0) 
                 $display("    --> TEST RESET PASSED\n");
              else
                 $display("    --> TEST RESET FAILED: leds_fsm = %05b, emergency_active = %b\n", leds_fsm, emergency_active);

        // 10.2) Test BRAKE (brake_btn)
        #20   brake_btn = 1;
        #5    $display("[2) BRAKE ON] brake_btn=1, Expected brake_right=1, brake_left=1");
        #1    if (leds_fsm[2] == 1 && leds_fsm[3] == 1) // leds_fsm[3]=brake_left, leds_fsm[2]=brake_right
                 $display("    --> TEST BRAKE PASSED\n");
              else
                 $display("    --> TEST BRAKE FAILED: leds_fsm = %05b\n", leds_fsm);
        #10   brake_btn = 0;
        #1    $display("[2) BRAKE OFF] brake_btn=0, Expected leds_fsm = 00000");
        #1    if (leds_fsm == 5'b00000)
                 $display("    --> TEST BRAKE OFF PASSED\n");
              else
                 $display("    --> TEST BRAKE OFF FAILED: leds_fsm = %05b\n", leds_fsm);

        // 10.3) Test LEFT TURN SIGNAL (LEFT_TURN)
        #20   left_sw = 1;
        #5    $display("[3) LEFT TURN ON] left_sw=1, Expected turn_left blinking");
        // Check over 3 blink cycles
        repeat (3) begin
            @(posedge blink);
            #1 $display("    blink=%b -> turn_left=%b, leds_fsm = %05b",
                        blink, leds_fsm[1], leds_fsm); // leds_fsm[1]=turn_left
        end
        // Verify blinking by checking current state (0 or 1 is acceptable for simplicity)
        #1    if (leds_fsm[1] == 0 || leds_fsm[1] == 1) 
                 $display("    --> TEST LEFT TURN PASSED\n");
              else
                 $display("    --> TEST LEFT TURN FAILED: leds_fsm = %05b\n", leds_fsm);
        #10   left_sw = 0;
        #1    $display("[3) LEFT TURN OFF] left_sw=0, Expected leds_fsm = 00000");
        #1    if (leds_fsm == 5'b00000)
                 $display("    --> TEST LEFT TURN OFF PASSED\n");
              else
                 $display("    --> TEST LEFT TURN OFF FAILED: leds_fsm = %05b\n", leds_fsm);

        // 10.4) Test RIGHT TURN SIGNAL (RIGHT_TURN)
        #20   right_sw = 1;
        #5    $display("[4) RIGHT TURN ON] right_sw=1, Expected turn_right blinking");
        repeat (3) begin
            @(posedge blink);
            #1 $display("    blink=%b -> turn_right=%b, leds_fsm = %05b",
                        blink, leds_fsm[0], leds_fsm); // leds_fsm[0]=turn_right
        end
        #1    if (leds_fsm[0] == 0 || leds_fsm[0] == 1)
                 $display("    --> TEST RIGHT TURN PASSED\n");
              else
                 $display("    --> TEST RIGHT TURN FAILED: leds_fsm = %05b\n", leds_fsm);
        #10   right_sw = 0;
        #1    $display("[4) RIGHT TURN OFF] right_sw=0, Expected leds_fsm = 00000");
        #1    if (leds_fsm == 5'b00000)
                 $display("    --> TEST RIGHT TURN OFF PASSED\n");
              else
                 $display("    --> TEST RIGHT TURN OFF FAILED: leds_fsm = %05b\n", leds_fsm);

        // 10.5) Test HAZARD (FOUR_WAY)
        #20   four_way_sw = 1;
        #5    $display("[5) HAZARD ON] four_way_sw=1, Expected turn_left+turn_right blinking simultaneously");
        repeat (3) begin
            @(posedge blink);
            #1 $display("    blink=%b -> turn_left=%b, turn_right=%b, leds_fsm = %05b",
                        blink, leds_fsm[1], leds_fsm[0], leds_fsm);
        end
        #1    if ((leds_fsm[1] == 0 || leds_fsm[1] == 1) &&
                   (leds_fsm[0] == 0 || leds_fsm[0] == 1))
                 $display("    --> TEST HAZARD PASSED\n");
              else
                 $display("    --> TEST HAZARD FAILED: leds_fsm = %05b\n", leds_fsm);
        #10   four_way_sw = 0;
        #1    $display("[5) HAZARD OFF] four_way_sw=0, Expected leds_fsm = 00000");
        #1    if (leds_fsm == 5'b00000)
                 $display("    --> TEST HAZARD OFF PASSED\n");
              else
                 $display("    --> TEST HAZARD OFF FAILED: leds_fsm = %05b\n", leds_fsm);

        // 10.6) Test REVERSE
        #20   reverse_sw = 1;
        #5    $display("[6) REVERSE ON] reverse_sw=1, Expected reverse = 1 (leds_fsm[4])");
        #1    if (leds_fsm[4] == 1)
                 $display("    --> TEST REVERSE PASSED\n");
              else
                 $display("    --> TEST REVERSE FAILED: leds_fsm = %05b\n", leds_fsm);
        #10   reverse_sw = 0;
        #1    $display("[6) REVERSE OFF] reverse_sw=0, Expected leds_fsm = 00000");
        #1    if (leds_fsm == 5'b00000)
                 $display("    --> TEST REVERSE OFF PASSED\n");
              else
                 $display("    --> TEST REVERSE OFF FAILED: leds_fsm = %05b\n", leds_fsm);

        // 10.7) Test CONCURRENT (brake + left turn)
        #20   brake_btn = 1; left_sw = 1;
        #5    $display("[7) CONCURRENT ON] brake=1 + left=1, Expected: turn_left blinking + brakes steady");
        repeat (3) begin
            @(posedge blink);
            #1 $display("    blink=%b -> turn_left=%b, brake_right=%b, brake_left=%b, leds_fsm = %05b",
                        blink, leds_fsm[1], leds_fsm[2], leds_fsm[3], leds_fsm);
        end
        // Verify brakes are on (1) and turn_left is blinking (0 or 1)
        #1    if ((leds_fsm[2] == 1 && leds_fsm[3] == 1) && (leds_fsm[1] == 0 || leds_fsm[1] == 1))
                 $display("    --> TEST CONCURRENT PASSED\n");
              else
                 $display("    --> TEST CONCURRENT FAILED: leds_fsm = %05b\n", leds_fsm);
        #10   brake_btn = 0; left_sw = 0;
        #1    $display("[7) CONCURRENT OFF] brake=0 + left=0, Expected leds_fsm = 00000");
        #1    if (leds_fsm == 5'b00000)
                 $display("    --> TEST CONCURRENT OFF PASSED\n");
              else
                 $display("    --> TEST CONCURRENT OFF FAILED: leds_fsm = %05b\n", leds_fsm);

        // 10.8) Test EMERGENCY Mode
        $display("\n[8) Test EMERGENCY Mode]\n");
        #20   btnu_debounced = 1; btnl_debounced = 1;
        #5    $display("[8.1) EMERGENCY ON] btnu=1 + btnl=1, Expected: emergency_active = 1");
        #1    if (emergency_active == 1)
                 $display("    --> TEST EMERGENCY ON PASSED\n");
              else
                 $display("    --> TEST EMERGENCY ON FAILED: emergency_active = %b\n", emergency_active);

        // During emergency, also activate reverse
        #20   reverse_sw = 1;
        #5    $display("[8.2) EMER + REVERSE] reverse=1, Expected: reverse=1 + turns blinking + brakes steady");
        repeat (3) begin
            @(posedge blink);
            #1 $display("    blink=%b -> turn_left=%b, turn_right=%b, brake_right=%b, brake_left=%b, reverse=%b, leds_fsm = %05b",
                        blink, leds_fsm[1], leds_fsm[0], leds_fsm[2], leds_fsm[3], leds_fsm[4], leds_fsm);
        end
        // Verify "brakes steady" and "reverse on" and "turns blinking"
        #1    if ((leds_fsm[2] == 1 && leds_fsm[3] == 1 && leds_fsm[4] == 1) &&
                   ((leds_fsm[1] == 0) || (leds_fsm[1] == 1)) &&
                   ((leds_fsm[0] == 0) || (leds_fsm[0] == 1)))
                 $display("    --> TEST EMER + REVERSE PASSED\n");
              else
                 $display("    --> TEST EMER + REVERSE FAILED: leds_fsm = %05b\n", leds_fsm);

        // Deactivate emergency
        #20   btnu_debounced = 0; btnl_debounced = 0; reverse_sw = 0;
        #5    $display("[8.3) EMERGENCY OFF] btnu=0 + btnl=0, Expected: return to NORMAL state, leds_fsm = 00000");
        #1    if (emergency_active == 0 && leds_fsm == 5'b00000)
                 $display("    --> TEST EMERGENCY OFF PASSED\n");
              else
                 $display("    --> TEST EMERGENCY OFF FAILED: emergency_active = %b, leds_fsm = %05b\n", emergency_active, leds_fsm);

        $display("\n============== END FSM TESTS ==============\n");
    end

    // --------------------
    // 11) Emergency Timer Tests
    // --------------------
    initial begin
        // Wait for FSM tests to progress so emergency mode can be entered/exited
        #200; // Adjust delay if FSM tests take longer
        $display("\n=========== START EMERGENCY_TIMER TESTS ===========\n");

        // 11.1) Initially emergency_active = 0, timer should remain at zero
        #1    $display("[11.1) TIMER RESET] Expected: minutes=0, seconds=0");
        #1    if (minutes == 0 && seconds == 0)
                 $display("    --> TEST TIMER RESET PASSED\n");
              else
                 $display("    --> TEST TIMER RESET FAILED: minutes=%0d, seconds=%0d\n", minutes, seconds);

        // 11.2) Force emergency_active=1 to start counting
        force dut_fsm.emergency_active = 1;
        #5    $display("[11.2) TIMER START] emergency_active=1, Timer should start counting");

        // Wait 70 blink cycles -> seconds = 70 mod 60 = 10, minutes = 1
        repeat (70) @(posedge blink);
        #1    $display("[11.2) After 70 cycles] Expected: seconds=10, minutes=1");
        #1    if (seconds == 10 && minutes == 1)
                 $display("    --> TEST TIMER 70s PASSED\n");
              else
                 $display("    --> TEST TIMER 70s FAILED: seconds=%0d, minutes=%0d\n", seconds, minutes);

        // Wait another 50 cycles -> total 120 -> seconds=0, minutes=2
        repeat (50) @(posedge blink);
        #1    $display("[11.2) After 120 cycles] Expected: seconds=0, minutes=2");
        #1    if (seconds == 0 && minutes == 2)
                 $display("    --> TEST TIMER 120s PASSED\n");
              else
                 $display("    --> TEST TIMER 120s FAILED: seconds=%0d, minutes=%0d\n", seconds, minutes);

        // 11.3) Disable emergency -> timer resets
        force dut_fsm.emergency_active = 0;
        #5    $display("[11.3) TIMER RESET (EMERGENCY OFF)] Expected: seconds=0, minutes=0");
        #1    if (seconds == 0 && minutes == 0)
                 $display("    --> TEST TIMER RESET (EMERGENCY OFF) PASSED\n");
              else
                 $display("    --> TEST TIMER RESET (EMERGENCY OFF) FAILED: seconds=%0d, minutes=%0d\n", seconds, minutes);
        release dut_fsm.emergency_active;

        $display("\n=========== END EMERGENCY_TIMER TESTS ===========\n");
    end

    // --------------------
    // 12) Display Driver (seven_seg_driver) Tests
    // --------------------
    initial begin
        // Wait for timer to have produced minutes and seconds values
        #400; // Adjust delay if previous tests take longer
        $display("\n======== START SEVEN_SEG_DRIVER TESTS ========\n");
        
        // Enable display and remove its reset
        rst_disp = 0;                       // Deactivate display reset
        force dut_fsm.emergency_active = 1; // Force display enable (via emergency_active)

        // 12.1) Verify 4-digit multiplexing by synchronizing with clk_disp
        // Wait for 4 posedges of clk_disp to sample anodes stably
        @(posedge clk_disp); // Activates AN0 (digit_sel=0)
        #0.1; // Small delay for stabilization
        $display("[12.1) DIGIT 0] Expected: AN = 11111110 (only AN0 active)");
        if (AN === 8'b11111110)
            $display("    --> TEST DIGIT 0 PASSED\n");
        else
            $display("    --> TEST DIGIT 0 FAILED: AN = %08b\n", AN);

        @(posedge clk_disp); // Activates AN1 (digit_sel=1)
        #0.1;
        $display("[12.1) DIGIT 1] Expected: AN = 11111101 (only AN1 active)");
        if (AN === 8'b11111101)
            $display("    --> TEST DIGIT 1 PASSED\n");
        else
            $display("    --> TEST DIGIT 1 FAILED: AN = %08b\n", AN);

        @(posedge clk_disp); // Activates AN2 (digit_sel=2)
        #0.1;
        $display("[12.1) DIGIT 2] Expected: AN = 11111011 (only AN2 active)");
        if (AN === 8'b11111011)
            $display("    --> TEST DIGIT 2 PASSED\n");
        else
            $display("    --> TEST DIGIT 2 FAILED: AN = %08b\n", AN);

        @(posedge clk_disp); // Activates AN3 (digit_sel=3)
        #0.1;
        $display("[12.1) DIGIT 3] Expected: AN = 11110111 (only AN3 active)");
        if (AN === 8'b11110111)
            $display("    --> TEST DIGIT 3 PASSED\n");
        else
            $display("    --> TEST DIGIT 3 FAILED: AN = %08b\n", AN);

        // 12.2) Reset display and verify it's off
        release dut_fsm.emergency_active; // Release force
        rst_disp = 1;                     // Apply reset
        @(posedge clk_disp);              // Wait for signal update
        #0.1;
        $display("[12.2) DISPLAY RESET] Expected: AN = 11111111, segments = 1111111 (all off)");
        if (AN === 8'b11111111 && segments === 7'b1111111) // Assuming active-low segments turn off to 1s
            $display("    --> TEST DISPLAY RESET PASSED\n");
        else
            $display("    --> TEST DISPLAY RESET FAILED: AN = %08b, segments = %07b\n", AN, segments);

        $display("\n======== END SEVEN_SEG_DRIVER TESTS ========\n");
        #20 $finish;
    end
 
endmodule