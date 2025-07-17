module SPI_controller(
                      input             clk, //main clock input
                      input             reset, // active high reset
                      input       [7:0] divisor,
                      input      [15:0] command,
                      input             cmdregwrt,
                      input      [31:0] wtdata1,
                      input      [31:0] wtdata2,
                      output     [31:0] rddata1,
                      output     [31:0] rddata2,
                      output reg [15:0] status,
                      output reg        irq,
                      output            sclk_out,
                      output reg        cs,
                      output reg        dout,
                      input             din);


localparam idle=0, start=1,send_data=2,read_data=3,stop=4, turnaround=5;
genvar i;

wire sclk_falling;
wire sclk_rising;

reg sclk_en;
reg din_delay;
reg sclk_delay;
reg cmdregwrt_delay;
reg [71:0] data_out_reg;
reg [63:0] data_read_reg;
reg [3:0] send_bytes;
reg [3:0] read_bytes;
reg [6:0] bit_count;
reg [3:0] state;

clock_div clock_div(
    .clk_in(clk),
    .rst(reset),
    .div(divisor),
    .clk_out(sclk));

assign sclk_out = sclk_en ? sclk : 0;
assign sclk_falling = sclk_delay & !sclk;
assign sclk_rising = !sclk_delay & sclk;


generate for (i=0;i<32;i=i+1) begin: rddata1_gen
            assign rddata1[i] = data_read_reg[i]; 
         end
endgenerate
generate for (i=0;i<32;i=i+1) begin: rddata2_gen
            assign rddata2[i] = data_read_reg[32+i]; 
         end
endgenerate


always @(posedge clk or posedge reset) begin
    if(reset) begin
        status <= 0;
        irq <= 0;
        sclk_en <= 0;
        cs <=  1;
        dout <= 0;
        din_delay <= 0;
        cmdregwrt_delay <= 0;
        data_read_reg <= 0;
        data_out_reg <= 0;
        state <= idle;
    end else begin
        cmdregwrt_delay <= cmdregwrt;
        sclk_delay <= sclk;
        din_delay <= din;

        case (state)
            idle : begin
                if(cmdregwrt_delay)begin
                    data_out_reg <= {command[7:0], wtdata1, wtdata2};
                    send_bytes <= command[15:12];
                    read_bytes <= command[11:8];
                    state <= start;
                    status <= 16'h8000;
                end else begin
                    state <= idle;
                    bit_count <= 0;
                    status <= 0;
                    dout <= 0;
                    cs <= 1;
                    sclk_en <= 0;
                    irq <= 0;
                end
            end
            start : begin
                if(sclk_falling) begin
                    state <= send_data;
                    sclk_en <= 1;
                    cs <= 0;
                end else begin
                    state <= start;
                end
            end
            send_data : begin
                if(sclk_rising) begin
                    bit_count <= bit_count + 1;
                    data_out_reg <= {data_out_reg[70:0], 1'b0};
                    dout <= data_out_reg[71];
                end
                if(bit_count[6:3] == send_bytes) begin
                    state <= turnaround;
                    bit_count <= 0;
                end else begin
                    state <= send_data;
                end
            end
            turnaround : begin
                if(sclk_rising) begin
                    state <= read_data;
                    dout <= 0;
                end else begin
                    state <= turnaround;
                    dout <= 0;
                end
            end
            read_data : begin
                if(sclk_falling) begin
                    bit_count <= bit_count + 1;
                    data_read_reg <= {data_read_reg[62:0], din_delay};
                end
                if(bit_count[6:3] == read_bytes) begin
                    state <= stop;
                    sclk_en <= 0;
                    bit_count <= 0;
                end else begin
                    state <= read_data;
                end
            end
            stop : begin
                    state <= idle;
                    irq <= 1;
            end
        endcase

    end
end
endmodule