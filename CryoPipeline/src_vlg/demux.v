`include "define.v"

module demux #(
    parameter NUM_DATA = 2, 
    parameter DATA_BW = 1
)(
    data_in, 
    sel,
    data_out
);

parameter SEL_WIDTH = `log2(NUM_DATA);

input [DATA_BW-1:0] data_in;
input [SEL_WIDTH-1:0] sel;
output reg [DATA_BW*NUM_DATA-1:0] data_out;

integer I;

always @(*)
begin
    for (I=0; I<NUM_DATA; I=I+1)
        if(sel == I)
            data_out[I*DATA_BW +: DATA_BW] = data_in;
        else
            data_out[I*DATA_BW +: DATA_BW] = 0;
end

endmodule
