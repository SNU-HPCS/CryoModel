module fifo_ctrl # (
    parameter ADDR_BW = 1 
)(
    wr_din, 
    rd_dout, 
    wr_ptr, 
    rd_ptr,
    num_item, 
    next_wrptr, 
    next_rdptr, 
    next_numitem, 
    reg_push, 
    full, 
    empty
);

input wr_din, rd_dout;
input [ADDR_BW-1:0] wr_ptr, rd_ptr;
input [ADDR_BW:0] num_item;
output reg [ADDR_BW-1:0] next_wrptr, next_rdptr;
output reg [ADDR_BW:0] next_numitem;
output reg_push, full, empty;
wire reg_pop;


// full, empty
assign full = (num_item == 2**ADDR_BW) ? 1 : 0;
assign empty = (num_item == 0) ? 1 : 0;
// reg_push, reg_pop
assign reg_push = (wr_din & ~full);
assign reg_pop = (rd_dout & ~empty);
// next_wrptr, next_rdptr, next_numitem
always @(*)
begin
    case({reg_push, reg_pop})
        2'b00:
        begin
            next_wrptr = wr_ptr;
            next_rdptr = rd_ptr;
            next_numitem = num_item;
        end
        2'b01: // pop
        begin
            next_wrptr = wr_ptr;
            next_rdptr = rd_ptr + 1;
            next_numitem = num_item - 1;
        end
        2'b10: // push
        begin
            next_wrptr = wr_ptr + 1;
            next_rdptr = rd_ptr;
            next_numitem = num_item + 1;
        end
        2'b11:
        begin
            next_wrptr = wr_ptr + 1;
            next_rdptr = rd_ptr + 1;
            next_numitem = num_item;
        end
    endcase
end

endmodule
