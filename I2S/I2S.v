/*
    This is an I2S module designed for the upduino HIMAX shield
    to read 16 bits of data from the shield's microphones
    because of the way the microphones are wired on the shield
    it only reads in data when the WS is high and ignores the other channel
    of data that comes when WS is low
    this means that it only reads data from one of the two on board microphones
    and rempves the two least significant bits of the 18-bit output value to 
    get a 16-bit output value that is more easily stored in the on board RAM
    it records 18.75k 16-bit 2's complement samples per second
    
    When new I2S data is brought in the dataflag bit goes high and stays high for
    16 BCLK cycles before going low again for 48 clock cycles or until new data is
    received
*/

module I2S( output reg WS,
            output reg BCLK,
            input clk,  //24MHz input clock
            input SDA,
            output reg [15:0] data,
            output dataflag,
            input rst);

//i2s clock > 1MHz
//WS = BCLK / 64;
//change ws on falling edge of BCLK
//only need to read first 18 bits of data
//2's compliment MSB first
//shift input values right by >>>2 to get 16 bit


//BCLK enable generator
reg BCLK_en;
integer count;

always @(posedge clk or negedge rst) begin
    BCLK_en <= 0;
    count <= count + 1;
    if(!rst) begin
        count <= 0;
    end else if(count == (20-1)) begin //divide clock by 20 for 1.2MHz
        BCLK_en <= 1;
        count <= 0;
    end
end

//BCLK generator uses BCLK enable to create a 1.2MHz clock
always @(posedge clk or negedge rst) begin
    if(!rst) begin
         BCLK <= 0;
    end else if(BCLK_en) begin
        BCLK <= !BCLK;
    end
end


//WS enable generator
reg WS_en;
integer count2;

always @(posedge clk or negedge rst) begin
    WS_en <= 0;
    count2 <= count2 + 1;
    if(!rst) begin
        count2 <= 0;
    end else if(count2 == (1280-1)) begin //divide clock by 1280 for 18.75MHz
        WS_en <= 1;
        count2 <= 0;
    end
end

//WS generator uses WS enable to create clock
always @(posedge clk or negedge rst) begin
    if(!rst) begin
         WS <= 0;
    end else if(WS_en) begin
        WS <= !WS;
    end
end

//dataflag that is high for 16 BCLK cycles while there is valid data on the I2S output
assign dataflag = (i > 15) & rst;


//always block that clocks in new data on falling edges of BCLK
//collects 16 most significant bits of I2S data
integer i;

always @(posedge clk or negedge rst) begin
    if(!rst) begin
        i<=0;
        data <= 0;
    end else if(BCLK_en & BCLK) begin
        if((WS == 0) & (i < 16)) begin
            data <= {data, SDA};
            i <= i + 1;
        end else if (WS == 0 & (i > 15)) begin  
        end else begin
            i <= 0;
            data <= 0;
        end
    end
end
endmodule