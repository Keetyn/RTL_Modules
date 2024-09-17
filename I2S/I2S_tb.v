`timescale 100 ps / 10 ps
module I2S_tb;

  // Parameters

  //Ports
  wire  WS;
  wire  BCLK;
  reg  SDA;
  reg  clk;
  wire [15:0] data;
  wire  dataflag;
  reg  rst;
 integer i;

  I2S  I2S_inst (
    .clk(clk),
    .WS(WS),
    .BCLK(BCLK),
    .SDA(SDA),
    .data(data),
    .dataflag(dataflag),
    .rst(rst)
  );


initial begin 
    clk = 0;
    forever begin
    #1 clk = ~clk;
 end end

 /*
initial begin 
    BCLK = 0;
    forever begin
    #1 BCLK = ~BCLK;
 end end

 initial begin
        WS = 0;
    forever begin
    #64   WS = ~WS;
end end
*/

 initial begin
    rst = 1;
    SDA <= 0;
    #3;
    rst = 0;
    #3;
    rst=1;
    #3;
    for (i=0;i<1000;i=i+1) begin
        #22;
        SDA <= $random;
    end
    $finish;
 end

 initial begin
    $dumpfile("I2S_tb.vcd");
    $dumpvars(0, I2S_tb);
end

endmodule