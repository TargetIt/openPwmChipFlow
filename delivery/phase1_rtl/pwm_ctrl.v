module pwm_ctrl (
  input        clk,
  input        rst,
  input  [7:0] duty,
  output       pwm_out
);
  reg [7:0] counter;

  always @(posedge clk) begin
    if (rst)
      counter <= 8'd0;
    else
      counter <= counter + 8'd1;  // 自动溢出回绕
  end

  assign pwm_out = (counter < duty);

endmodule
