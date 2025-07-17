module clock_div(
                 input rst, //active high reset
                 input clk_in, //input clock
                 input [7:0] div, //clock divisor, Fclkout = Fclkin / ((div + 1)*2)
                 output reg clk_out);

    reg [7:0] count;

    always @(posedge clk_in or posedge rst) begin
        if(rst) begin
            clk_out <= 0;
            count <= 0;
        end else begin
            if (count==div) begin
                clk_out <= ~clk_out;
                count <= 0;
            end else
                count <= count + 1;
            end 
    end
endmodule