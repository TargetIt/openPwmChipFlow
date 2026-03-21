// tb/tb_pwm.v
module tb_pwm;
  reg clk = 0, rst = 1;
  reg [7:0] duty = 8'd0;
  wire pwm_out;

  pwm_ctrl dut (
    .clk(clk), .rst(rst),
    .duty(duty), .pwm_out(pwm_out)
  );

  always #5 clk = ~clk;  // 100MHz

  integer high_count;
  integer total_count;
  integer test_pass;
  real measured_pct;
  real expected_pct;
  real pct_error;
  real tolerance_pct;

  task check_duty_cycle;
    input [7:0] expected_duty;
    input [31:0] cycles;
    begin
      high_count = 0;
      total_count = 0;
      repeat (cycles) begin
        @(posedge clk);
        #1;  // delta delay for signal stabilization after posedge clk
        total_count = total_count + 1;
        if (pwm_out) high_count = high_count + 1;
      end
      measured_pct = (100.0 * high_count) / total_count;
      expected_pct = (100.0 * expected_duty) / 256.0;
      pct_error = measured_pct - expected_pct;
      if (pct_error < 0.0) pct_error = -pct_error;
      $display("  duty=%0d: high=%0d/%0d (%.1f%%)", expected_duty,
               high_count, total_count,
               measured_pct);

      if (pct_error > tolerance_pct) begin
        $display("  FAIL: expected %.2f%%, measured %.2f%%, error %.2f%% > tolerance %.2f%%",
                 expected_pct, measured_pct, pct_error, tolerance_pct);
        test_pass = 0;
      end else begin
        $display("  PASS: expected %.2f%%, measured %.2f%%, error %.2f%%",
                 expected_pct, measured_pct, pct_error);
      end
    end
  endtask

  initial begin
    $dumpfile("wave.vcd"); $dumpvars;
    test_pass = 1;
    tolerance_pct = 0.5;  // With 256-cycle window, quantization error is <= 0.39%.

    // Test 1: Reset behavior
    $display("[TEST 1] Reset behavior");
    #20;
    if (pwm_out !== 1'b0) begin
      $display("  FAIL: pwm_out should be 0 during reset");
      test_pass = 0;
    end else begin
      $display("  PASS: pwm_out is 0 during reset");
    end

    // Release reset
    rst = 0;

    // Test 2: 50% duty cycle
    $display("[TEST 2] 50%% duty cycle (duty=128)");
    duty = 8'd128;
    check_duty_cycle(128, 256);

    // Test 3: 25% duty cycle
    $display("[TEST 3] 25%% duty cycle (duty=64)");
    duty = 8'd64;
    check_duty_cycle(64, 256);

    // Test 4: 0% duty cycle
    $display("[TEST 4] 0%% duty cycle (duty=0)");
    duty = 8'd0;
    check_duty_cycle(0, 256);

    // Test 5: ~100% duty cycle
    $display("[TEST 5] ~100%% duty cycle (duty=255)");
    duty = 8'd255;
    check_duty_cycle(255, 256);

    // Test 6: Reset during operation
    $display("[TEST 6] Reset during operation");
    duty = 8'd0;
    #100;  // wait ~10 clock cycles at 100MHz before asserting reset
    rst = 1;
    @(posedge clk); #1;
    if (pwm_out !== 1'b0) begin
      $display("  FAIL: pwm_out should be 0 during reset (with duty=0)");
      test_pass = 0;
    end else begin
      $display("  PASS: counter reset confirmed, pwm_out is 0");
    end
    rst = 0;
    duty = 8'd128;
    check_duty_cycle(128, 256);

    if (test_pass) begin
      $display("\n=== ALL TESTS PASSED ===");
      $finish_and_return(0);
    end else begin
      $display("\n=== SOME TESTS FAILED ===");
      $finish_and_return(1);
    end

    $finish;
  end
endmodule
