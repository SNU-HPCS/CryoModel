`include "define.v"

module srmem_double #(
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
    nextready,
    rdlastinfo
);

input rst, clk;
input valid_din;
input [DATA_BW-1:0] din;
input is_lastdin;
input req_pop;
input req_newdata;
output reg [NUM_RDPORT*(DATA_BW+1)-1:0] dout_list;
output reg wrfull;
output reg rdvalid;
output reg nextready;
output reg rdlastinfo;

/*** Wires ***/
reg flip_pchwr, flip_pchrd;

reg valid_din_double [1:0];
reg [DATA_BW-1:0] din_double [1:0];
reg is_lastdin_double [1:0];
reg req_pop_double [1:0];
reg req_newdata_double [1:0];
wire [NUM_RDPORT*(DATA_BW+1)-1:0] dout_list_double [1:0];
wire wrfull_double [1:0];
wire rdvalid_double [1:0];
wire wrend_double [1:0];
wire rdend_double [1:0];
wire rdnext_double [1:0];
wire rdlast_double [1:0];

/*** Registers ***/
reg sel_pchwr, sel_pchrd;


/*** Wire connection ***/
always @(*)
begin
    // flip_pchwr
    flip_pchwr = wrend_double[sel_pchwr];
    // flip_pchrd
    flip_pchrd = rdend_double[sel_pchrd];

    // input for write
    valid_din_double[sel_pchwr] = valid_din;
    din_double[sel_pchwr] = din;
    is_lastdin_double[sel_pchwr] = is_lastdin;
    valid_din_double[sel_pchwr^1] = 0;
    din_double[sel_pchwr^1] = 0;
    is_lastdin_double[sel_pchwr^1] = 0;
    // input for read
    req_pop_double[sel_pchrd] = req_pop;
    req_newdata_double[sel_pchrd] = req_newdata;
    req_pop_double[sel_pchrd^1] = 0;
    req_newdata_double[sel_pchrd^1] = 0;
    // dout_list
    dout_list = dout_list_double[sel_pchrd];
    // wrfull
    wrfull = wrfull_double[sel_pchwr];
    // rdvalid
    rdvalid = rdvalid_double[sel_pchrd];
    // nextready
    if (flip_pchrd)
        nextready = rdvalid_double[sel_pchrd^1];
    else
        nextready = rdnext_double[sel_pchrd];
    // rdlastinfo
    rdlastinfo = rdlast_double[sel_pchrd];
end


/*** Register update ***/
always @(posedge clk)
begin
    if (rst)
    begin
        sel_pchwr <= 0;
        sel_pchrd <= 0;
    end
    else
    begin
        if (flip_pchwr)
            sel_pchwr <= sel_pchwr ^ 1;
        if (flip_pchrd)
            sel_pchrd <= sel_pchrd ^ 1;
    end
end


/*** Double-buffered srmems ***/
srmem_single #(
    .NUM_RDPORT(NUM_RDPORT),
    .LEN_SRMEM(LEN_SRMEM),
    .DATA_BW(DATA_BW)
) UUT0(
    .rst(rst), 
    .clk(clk),
    .valid_din(valid_din_double[0]), 
    .din(din_double[0]), 
    .is_lastdin(is_lastdin_double[0]), 
    .req_pop(req_pop_double[0]),
    .req_newdata(req_newdata_double[0]),
    .dout_list(dout_list_double[0]),
    .wrfull(wrfull_double[0]),
    .rdvalid(rdvalid_double[0]),
    .wrend(wrend_double[0]),
    .rdend(rdend_double[0]),
    .rdnext(rdnext_double[0]),
    .rdlast(rdlast_double[0])
);

srmem_single #(
    .NUM_RDPORT(NUM_RDPORT),
    .LEN_SRMEM(LEN_SRMEM),
    .DATA_BW(DATA_BW)
) UUT1(
    .rst(rst), 
    .clk(clk),
    .valid_din(valid_din_double[1]), 
    .din(din_double[1]), 
    .is_lastdin(is_lastdin_double[1]), 
    .req_pop(req_pop_double[1]),
    .req_newdata(req_newdata_double[1]),
    .dout_list(dout_list_double[1]),
    .wrfull(wrfull_double[1]),
    .rdvalid(rdvalid_double[1]),
    .wrend(wrend_double[1]),
    .rdend(rdend_double[1]),
    .rdnext(rdnext_double[1]),
    .rdlast(rdlast_double[1])
);

endmodule
