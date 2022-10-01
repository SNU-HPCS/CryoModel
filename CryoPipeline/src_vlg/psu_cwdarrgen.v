`include "define.v"

module psu_cwdarrgen(
    mask_ext_array,
    special_ext_array,
    cwd,
    cwdsp,
    cwdarray
);

input [`NUM_PQ-1:0] mask_ext_array;
input [`NUM_PQ-1:0] special_ext_array;
input [`CWD_BW-1:0] cwd;
input [`CWD_BW-1:0] cwdsp;
output reg [`NUM_PQ*`CWD_BW-1:0] cwdarray;

reg [`CWD_BW-1:0] final_cwd;

integer IDX;
always @(*)
begin
    for (IDX = 0; IDX < `NUM_PQ; IDX = IDX+1)
    begin
        if (special_ext_array[IDX])
            final_cwd = cwdsp;
        else
            final_cwd = cwd;

        if (mask_ext_array[IDX])
            cwdarray[IDX*`CWD_BW +: `CWD_BW] = final_cwd;
        else
            cwdarray[IDX*`CWD_BW +: `CWD_BW] = `CWD_I;
    end
end

endmodule

/*
module psu_cwdarrgen(
    pchinfo_list,
    uc_counter, 
    qb_counter,
    mask_array,
    special_array,
    cwd,
    cwdsp,
    cwdarray
);
input [`NUM_PCU*(`PCHINFO_BW+1)-1:0] pchinfo_list;
input [`NUM_UCC*`UCADDR_BW-1:0] uc_counter;
input [`NUM_QBCTRL*`QBADDR_BW-1:0] qb_counter;
input [`NUM_MASK-1:0] mask_array;
input [`NUM_MASK-1:0] special_array;
input [`CWD_BW-1:0] cwd, cwdsp;
output reg [`NUM_PQ*`CWD_BW-1:0] cwdarray;

// Intermediate wires
reg [`NUM_PQ-1:0] mask_array_ext;
reg [`NUM_PQ-1:0] special_array_ext;
reg [`CWD_BW-1:0] final_cwd;

integer SIDX, I, J, K, TIDX, IDX;
reg pchinfo_valid;
reg [`PCHINFO_BW-1:0] pchinfo;
reg [`PCHADDR_BW-1:0] pchidx;
reg [`UCADDR_BW-1:0] ucidx;
reg [`QBADDR_BW-1:0] qbidx;

always @(*)
begin
    // ext 
    mask_array_ext = 0;
    special_array_ext = 0;
    for (SIDX = 0; SIDX < `NUM_MASK; SIDX = SIDX+1)
    begin
        #1
        I = SIDX / (`NUM_UCC * `NUM_QBCTRL);
        J = (SIDX % (`NUM_UCC*`NUM_QBCTRL)) / `NUM_QBCTRL;
        K = SIDX % `NUM_QBCTRL;
        {pchinfo_valid, pchinfo} = pchinfo_list[I*(`PCHINFO_BW+1) +: (`PCHINFO_BW+1)];
        pchidx = pchinfo[(`PCHINFO_BW-1)-(`PCHSTAT_BW+`PCHDYN_BW) -: `PCHADDR_BW];
        ucidx = uc_counter[J*`UCADDR_BW +: `UCADDR_BW];
        qbidx = qb_counter[K*`QBADDR_BW +: `QBADDR_BW];

        //TIDX = (pchidx * (`NUM_UC * `NUM_QB) + ucidx * (`NUM_QB) + qbidx);

        mask_array_ext[(pchidx * (`NUM_UC * `NUM_QB) + ucidx * (`NUM_QB) + qbidx)] = mask_array[SIDX];
        special_array_ext[(pchidx * (`NUM_UC * `NUM_QB) + ucidx * (`NUM_QB) + qbidx)] = mask_array[SIDX];
    end

    for (IDX = 0; IDX < `NUM_PQ; IDX = IDX+1)
    begin
        if (special_array_ext[IDX])
            final_cwd = cwdsp;
        else
            final_cwd = cwd;

        if (mask_array_ext[IDX])
            cwdarray[IDX*`CWD_BW +: `CWD_BW] = final_cwd;
        else
            cwdarray[IDX*`CWD_BW +: `CWD_BW] = `CWD_I;
    end
end
endmodule
*/
