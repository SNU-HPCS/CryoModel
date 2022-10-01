module fifo # (
    parameter ADDR_BW = 1, 
    parameter DATA_BW = 4
)(
    rst, 
    clk,
    wr_din, 
    rd_dout, 
    din,
    full, 
    empty,
    dout
);

input rst, clk;
input wr_din, rd_dout;
input [DATA_BW-1:0] din;
output full, empty;
output [DATA_BW-1:0] dout;

// Wires
wire [ADDR_BW-1:0] next_wrptr, next_rdptr;
wire [ADDR_BW:0] next_numitem;
wire reg_push; 

// Registers
wire [ADDR_BW-1:0] wr_ptr, rd_ptr;
wire [ADDR_BW:0] num_item;

// FIFO_CTRL
fifo_ctrl #(
    .ADDR_BW(ADDR_BW)
) UUT0(
    .wr_din(wr_din), 
    .rd_dout(rd_dout), 
    .wr_ptr(wr_ptr), 
    .rd_ptr(rd_ptr),
    .num_item(num_item), 
    .next_wrptr(next_wrptr), 
    .next_rdptr(next_rdptr), 
    .next_numitem(next_numitem), 
    .reg_push(reg_push), 
    .full(full), 
    .empty(empty)
);

fifo_reg #(
    .ADDR_BW(ADDR_BW),
    .DATA_BW(DATA_BW)
) UUT1(
    .rst(rst),
    .clk(clk),
    .reg_push(reg_push),
    .next_wrptr(next_wrptr),
    .next_rdptr(next_rdptr),
    .next_numitem(next_numitem),
    .din(din),
    .wr_ptr(wr_ptr),
    .rd_ptr(rd_ptr),
    .num_item(num_item),
    .dout(dout)
);

endmodule
