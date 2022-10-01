module fifo_reg #(
    parameter ADDR_BW = 1, 
    parameter DATA_BW = 4
)(
    rst,
    clk,
    reg_push,
    next_wrptr,
    next_rdptr,
    next_numitem,
    din,
    wr_ptr,
    rd_ptr,
    num_item,
    dout
);

input rst, clk;
input reg_push;
input [ADDR_BW-1:0] next_wrptr;
input [ADDR_BW-1:0] next_rdptr;
input [ADDR_BW:0] next_numitem;
input [DATA_BW-1:0] din;
output [ADDR_BW-1:0] wr_ptr;
output [ADDR_BW-1:0] rd_ptr;
output [ADDR_BW:0] num_item;
output [DATA_BW-1:0] dout;


reg [DATA_BW-1:0] regarray [2**ADDR_BW-1:0];
reg [ADDR_BW-1:0] wrptr_reg, rdptr_reg;
reg [ADDR_BW:0] numitem_reg;

assign dout = regarray[rd_ptr];
assign wr_ptr = wrptr_reg;
assign rd_ptr = rdptr_reg;
assign num_item = numitem_reg;


integer i;
// Register update
always @(posedge clk)
begin
    if (rst)
    begin
        for (i=0; i < 2**ADDR_BW-1; i=i+1)
            regarray[i] <= {DATA_BW{1'b1}};
        wrptr_reg <= 0;
        rdptr_reg <= 0;
        numitem_reg <= 0;
    end
    else
    begin
        if (reg_push)
            regarray[wrptr_reg] <= din;
        wrptr_reg <= next_wrptr;
        rdptr_reg <= next_rdptr;
        numitem_reg <= next_numitem;
    end
end



endmodule
