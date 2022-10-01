`include "define.v"

module srmem_single # (
    parameter NUM_RDPORT = 1,
    parameter LEN_SRMEM = 4,
    parameter DATA_BW = 8
)(
    rst, 
    clk,
    valid_din, 
    din, 
    is_lastdin, 
    req_pop,
    req_newdata,
    dout_list,
    wrfull,
    rdvalid,
    wrend,
    rdend,
    rdnext,
    rdlast
);

parameter STATE_FILLING = 2'b00;
parameter STATE_MOVING = 2'b01;
parameter STATE_READING = 2'b10;
parameter MEMLEN_BW = `log2(LEN_SRMEM);
parameter RDPORT_BW = `log2(NUM_RDPORT);

input rst, clk;
input valid_din;
input [DATA_BW-1:0] din;
input is_lastdin;
input req_pop;
input req_newdata;
output [NUM_RDPORT*(DATA_BW+1)-1:0] dout_list;
output wrfull;
output rdvalid;
output wrend;
output rdend;
output rdnext;
output rdlast;

reg [DATA_BW:0] srmem [NUM_RDPORT-1:0][LEN_SRMEM-1:0];

/*** Wires ***/
// from srmem 
reg [NUM_RDPORT*(DATA_BW+1)-1:0] srmem_head; 
//from control
wire [1:0] next_state;
wire [NUM_RDPORT*(DATA_BW+1)-1:0] next_data; 
wire [NUM_RDPORT-1:0] shift_en;
wire rst_hdptr, rst_tlptr, rst_memptr;
wire up_hdptr, up_tlptr, up_memptr;
wire rst_valid;

/*** Registers ***/
reg [1:0] state;
reg [MEMLEN_BW-1:0] hdptr;
reg [MEMLEN_BW-1:0] tlptr;
reg [RDPORT_BW-1:0] memptr;


/*** Combinational transfer ***/
assign dout_list = srmem_head;

integer I;
always @(*)
begin
    for (I = 0; I < NUM_RDPORT; I = I+1)
        srmem_head[I*(DATA_BW+1) +: (DATA_BW+1)] = srmem[I][LEN_SRMEM-1];
end

/*** Sequential update ***/
integer J, K, L, M;
always @(posedge clk)
begin
    if (rst)
    begin
        for (J = 0; J < NUM_RDPORT; J = J+1)
        begin
            for (K = 0; K < LEN_SRMEM; K = K+1)
            begin
                srmem[J][K] <= 0;
            end
        end
        state <= STATE_FILLING;
        hdptr <= 0;
        tlptr <= 0;
        memptr <= 0;
    end
    else
    begin
        // srmem
        for (L = 0; L < NUM_RDPORT; L = L+1)
        begin
            for (M = 0; M < LEN_SRMEM; M = M+1)
            begin
                if (rst_valid)
                begin
                    srmem[L][M][DATA_BW] <= 0;
                end
                else if (shift_en[L])
                begin
                    if (M == 0)
                        srmem[L][M] <= next_data[L*(DATA_BW+1) +: (DATA_BW+1)];
                    else
                        srmem[L][M] <= srmem[L][M-1];
                end
            end
        end
        // state
        state <= next_state;
        // hdptr
        if (up_hdptr)
        begin
            if (hdptr == LEN_SRMEM-1)
                hdptr <= 0;
            else
                hdptr <= hdptr + 1;
        end
        else if (rst_hdptr)
            hdptr <= 0;
        // tlptr
        if (up_tlptr)
        begin
            if (tlptr == LEN_SRMEM-1)
                tlptr <= 0;
            else
                tlptr <= tlptr + 1;
        end
        else if (rst_tlptr)
            tlptr <= 0;
        // memptr
        if (up_memptr)
        begin
            if (memptr == NUM_RDPORT-1)
                memptr <= 0;
            else
                memptr <= memptr + 1;
        end
        else if (rst_memptr)
            memptr <= 0;
    end
end


/*** Control ***/ 
srmem_single_ctrl #(
    .NUM_RDPORT(NUM_RDPORT),
    .LEN_SRMEM(LEN_SRMEM),
    .DATA_BW(DATA_BW)
) UUT0(
    .state(state),
    .hdptr(hdptr),
    .tlptr(tlptr),
    .memptr(memptr),
    .valid_din(valid_din),
    .din(din),
    .is_lastdin(is_lastdin),
    .req_pop(req_pop),
    .req_newdata(req_newdata),
    .srmem_head(srmem_head),
    .next_state(next_state),
    .next_data(next_data),
    .shift_en(shift_en),
    .rst_hdptr(rst_hdptr),
    .rst_tlptr(rst_tlptr),
    .rst_memptr(rst_memptr),
    .up_hdptr(up_hdptr),
    .up_tlptr(up_tlptr),
    .up_memptr(up_memptr),
    .rst_valid(rst_valid),
    .wrfull(wrfull),
    .rdvalid(rdvalid),
    .wrend(wrend),
    .rdend(rdend),
    .rdnext(rdnext),
    .rdlast(rdlast)
);
endmodule
