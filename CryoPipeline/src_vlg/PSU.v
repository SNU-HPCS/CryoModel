`include "define.v"

module PSU(
    rst,
    clk,
    topsu_valid,
    opcode_in,
    pchinfo,
    last_pchinfo,
    cwdgen_stall,
    pchwr_stall, 
    psu_valid,
    cwdarray_out,
    timing_out,
    opcode_out
);

parameter LEN_SRMEM = ((`NUM_PCH/`NUM_PCU)*`NUM_PCU == `NUM_PCH) ? (`NUM_PCH/`NUM_PCU) : ((`NUM_PCH/`NUM_PCU) +1);

input rst, clk;
input topsu_valid;
input [`OPCODE_BW-1:0] opcode_in;
input [`PCHINFO_BW-1:0] pchinfo;
input last_pchinfo;
input cwdgen_stall, pchwr_stall;
output reg psu_valid;
output reg [`NUM_PQ*`CWD_BW-1:0] cwdarray_out;
output reg [`TIME_BW-1:0] timing_out;
output reg [`OPCODE_BW-1:0] opcode_out;


/*** Wires ***/
// from psu_opbuf (fifo)
wire [`OPCODE_BW-1:0] opcode_running;
// from psu_ctrl
wire [1:0] sel_cwdNtime;
wire flush_output;
wire next_qb;
wire next_uc;
wire next_pch;
wire next_id;
wire next_round;
wire next_opcode;
wire next_state;
// from psu_cntsrmem
wire [`TIME_BW-1:0] timing;
wire [`CWD_BW-1:0] cwd;
wire [`CWD_BW-1:0] cwdsp;
wire [`IDLEN_BW-1:0] id_len;
// from counters
wire [`QBADDR_BW-1:0] qb_counter0;
wire [`UCADDR_BW-1:0] uc_counter0;
// from psu_pisrmem
wire [`NUM_PCU*(`PCHINFO_BW+1)-1:0] pchinfo_list;
reg [`NUM_PCU*(2*`OPCODE_BW)-1:0] pchop_list;
reg [`NUM_PCU*(1)-1:0] pivalid_list;
wire pchinfo_full; 
wire pchinfo_valid; 
wire pchinfo_nextready; 
wire pchinfo_rdlast;
// from psu_opNloc
wire [`NUM_PCU*`OPCODE_BW-1:0] pcu_opcode;
wire [`NUM_UCC*`UCLOC_BW-1:0] ucc_ucloc;
// split for maskgen_array's input 
reg [`NUM_MASK*`OPCODE_BW-1:0] maskgen_opcode; 
reg [`NUM_MASK*`IDLEN_BW-1:0] maskgen_id;
reg [`NUM_MASK*`QBADDR_BW-1:0] maskgen_qbidx;
reg [`NUM_MASK*`UCLOC_BW-1:0] maskgen_ucloc;
reg [`NUM_MASK-1:0] maskgen_pchinfo_valid;
reg [`NUM_MASK*`PCHTYPE_BW-1:0] maskgen_pchtype;
reg [`NUM_MASK*`PCHDYN_BW-1:0] maskgen_pchdyn;
// from psu_maskgen_array
wire [`NUM_MASK-1:0] mask_array;
wire [`NUM_MASK-1:0] special_array;
// from psu_maskext
wire [`NUM_PQ-1:0] mask_ext_array;
wire [`NUM_PQ-1:0] special_ext_array;
// from psu_cwdarrgen
wire [`NUM_PQ*`CWD_BW-1:0] cwdarray;

// intermediate
reg [`NUM_PCU*`PCHADDR_BW-1:0] pchidx_list;


/*** Registers ***/
reg state;
reg [`NUM_QBCTRL*`QBADDR_BW-1:0] qb_counter;
reg [`NUM_UCC*`UCADDR_BW-1:0] uc_counter;
reg [`IDLEN_BW-1:0] id_counter;
reg [`ROUND_BW-1:0] round_counter;


/*** Wire connection ***/
assign qb_counter0 = qb_counter[0 +: `QBADDR_BW];
assign uc_counter0 = uc_counter [0 +: `UCADDR_BW];
assign next_qb = (state == `PSU_RUNNING);
assign flush_output = psu_valid;


integer I1, I2, J, K, T;
reg pivalid;
reg [`PCHINFO_BW-1:0] pidata;
reg [`PCHTYPE_BW-1:0] pchtype;
reg [`PCHDYN_BW-1:0] pchdyn;

always @(*)
begin
    for (I1 = 0; I1 < `NUM_PCU; I1 = I1+1)
    begin
        {pivalid, pidata} = pchinfo_list[I1*(`PCHINFO_BW+1) +: (`PCHINFO_BW+1)];
        pchop_list[I1*(2*`OPCODE_BW) +: (2*`OPCODE_BW)] = pidata[(`PCHINFO_BW-1)-(`PCHSTAT_BW + `PCHDYN_BW + `PCHADDR_BW) -: (2*`OPCODE_BW)];
        pchidx_list[I1*`PCHADDR_BW +: `PCHADDR_BW] = pidata[(`PCHINFO_BW-1)-(`PCHSTAT_BW+`PCHDYN_BW) -: `PCHADDR_BW];
        pivalid_list[I1] = pivalid;
    end

    for (I2 = 0; I2 < `NUM_PCU; I2 = I2+1)
    begin
        for (J = 0; J < `NUM_UCC; J = J+1)
        begin
            for (K = 0; K < `NUM_QBCTRL; K = K+1)
            begin                // output
                {pivalid, pidata} = pchinfo_list[I2*(`PCHINFO_BW+1) +: (`PCHINFO_BW+1)];
                pchtype = pidata[`PCHINFO_BW-1 -: `PCHTYPE_BW];
                pchdyn = pidata[(`PCHINFO_BW-1)-`PCHSTAT_BW -: `PCHDYN_BW];

                T = I2 * (`NUM_UCC * `NUM_QBCTRL) + J * (`NUM_QBCTRL) + K;
                maskgen_opcode[T*`OPCODE_BW +: `OPCODE_BW] = pcu_opcode[I2*`OPCODE_BW +: `OPCODE_BW];
                maskgen_id[T*`IDLEN_BW +: `IDLEN_BW] = id_counter;
                maskgen_qbidx[T*`QBADDR_BW +: `QBADDR_BW] = qb_counter[K*`QBADDR_BW +: `QBADDR_BW];
                maskgen_ucloc[T*`UCLOC_BW +: `UCLOC_BW] = ucc_ucloc[J*`UCLOC_BW +: `UCLOC_BW];
                maskgen_pchinfo_valid[T] = pivalid;
                maskgen_pchtype[T*`PCHTYPE_BW +: `PCHTYPE_BW] = pchtype;
                maskgen_pchdyn[T*`PCHDYN_BW +: `PCHDYN_BW] = pchdyn;
            end
        end
    end
end


/*** Register update ***/
integer IDX, J1, J2, J3, K1, K2, K3;
integer I_TEMP;
always @(posedge clk)
begin
    if (rst)
    begin
        psu_valid <= 0;
        cwdarray_out <= 0;
        timing_out <= 0;
        opcode_out <= `INVALID_OPCODE;
        for (J1 = 0; J1 < `NUM_UCC; J1 = J1+1)
            uc_counter[J1*`UCADDR_BW +: `UCADDR_BW] <= J1;
        for (K1 = 0; K1 < `NUM_QBCTRL; K1 = K1+1)
            qb_counter[K1*`QBADDR_BW +: `QBADDR_BW] <= K1;
        id_counter <= 0;
        round_counter <= 0;
        state <= `PSU_READY;
    end
    else if (~cwdgen_stall)
    begin
        // output regs
        if (next_id)
        begin
            psu_valid <= 1;
            timing_out <= timing;
            opcode_out <= opcode_running;
        end
        else
        begin
            psu_valid <= 0;
        end
        
        for (IDX = 0; IDX < `NUM_PQ; IDX = IDX+1)
        begin
            // if (flush_output | cwdarray[IDX*`CWD_BW +: `CWD_BW] != `CWD_I)
            //     cwdarray_out[IDX*`CWD_BW +:`CWD_BW] <= cwdarray[IDX*`CWD_BW +: `CWD_BW];
            if (flush_output)
                cwdarray_out[IDX*`CWD_BW +:`CWD_BW] <= `CWD_I;
            else if (cwdarray[IDX*`CWD_BW +: `CWD_BW] != `CWD_I)
                cwdarray_out[IDX*`CWD_BW +:`CWD_BW] <= cwdarray[IDX*`CWD_BW +: `CWD_BW];
        end

        // counters
        //// qb_counter
        if (next_uc)
        begin
            for (K2 = 0; K2 < `NUM_QBCTRL; K2 = K2+1)
                qb_counter[K2*`QBADDR_BW +: `QBADDR_BW] <= K2;
        end
        else if (next_qb)
        begin
            for (K3 = 0; K3 < `NUM_QBCTRL; K3 = K3+1)
                qb_counter[K3*`QBADDR_BW +: `QBADDR_BW] <= qb_counter[K3*`QBADDR_BW +: `QBADDR_BW] + `NUM_QBCTRL;
        end
        //// uc_counter
        if (next_pch)
        begin
            for (J2 = 0; J2 < `NUM_UCC; J2 = J2+1)
                uc_counter[J2*`UCADDR_BW +: `UCADDR_BW] <= J2;
        end
        else if (next_uc)
        begin
            for (J3 = 0; J3 < `NUM_UCC; J3 = J3+1)
                uc_counter[J3*`UCADDR_BW +: `UCADDR_BW] <= uc_counter[J3*`UCADDR_BW +: `UCADDR_BW] + `NUM_UCC;
        end
        //// id_counter
        if (next_round)
            id_counter <= 0;
        else if (next_id)
            id_counter <= id_counter + 1;
        //// round_counter
        if (next_opcode)
            round_counter <= 0;
        else if (next_round)
            round_counter <= round_counter + 1;

        // state 
        state <= next_state;

    end
end


/*** Microunit instantiation ***/
// psu_opbuf
fifo #(
    .ADDR_BW(1), 
    .DATA_BW(`OPCODE_BW)
) UUT0(
    .rst(rst), 
    .clk(clk),
    .wr_din((~pchwr_stall) & topsu_valid & last_pchinfo), 
    .rd_dout((~cwdgen_stall) & next_opcode), 
    .din(opcode_in),
    .dout(opcode_running)
);
// psu_ctrl
psu_ctrl UUT1(
    .opcode_running(opcode_running),
    .psu_valid(psu_valid),
    .state(state),
    .qb_counter0(qb_counter0),
    .uc_counter0(uc_counter0),
    .pchinfo_rdlast(pchinfo_rdlast),
    .id_counter(id_counter),
    .id_len(id_len),
    .round_counter(round_counter),
    .pchinfo_valid(pchinfo_valid),
    .pchinfo_nextready(pchinfo_nextready),
    .sel_cwdNtime(sel_cwdNtime),
    .next_uc(next_uc),
    .next_pch(next_pch),
    .next_id(next_id),
    .next_round(next_round),
    .next_opcode(next_opcode),
    .next_state(next_state)
);
// psu_cntsrmem
psu_cntsrmem UUT2(
    .rst(rst),
    .clk(clk),
    .sel_cwdNtime(sel_cwdNtime),
    .next_id((~cwdgen_stall) & next_id),
    .timing(timing),
    .cwd(cwd),
    .cwdsp(cwdsp),
    .id_len(id_len)
);
// psu_pisrmem
srmem_double #(
    .NUM_RDPORT(`NUM_PCU),
    .LEN_SRMEM(LEN_SRMEM),
    .DATA_BW(`PCHINFO_BW)
) UUT3(
    .rst(rst), 
    .clk(clk),
    .valid_din((~pchwr_stall) & topsu_valid),
    .din(pchinfo),
    .is_lastdin(last_pchinfo),
    .req_pop((~cwdgen_stall) & next_pch),
    .req_newdata((~cwdgen_stall) & next_opcode),
    .dout_list(pchinfo_list),
    .wrfull(pchinfo_full),
    .rdvalid(pchinfo_valid),
    .nextready(pchinfo_nextready),
    .rdlastinfo(pchinfo_rdlast)
);

//psu_opNloc
psu_opNloc UUT4(
    .opcode_running(opcode_running),
    .pchop_list(pchop_list),
    .uc_counter(uc_counter),
    .pcu_opcode(pcu_opcode),
    .ucc_ucloc(ucc_ucloc)
);

// array of psu_maskgen
genvar i;
generate
    for (i = 0; i < `NUM_MASK; i = i+1)
    begin: gen_maskgen
        psu_maskgen UUT5_I(
            .opcode(maskgen_opcode[i*`OPCODE_BW +: `OPCODE_BW]), 
            .timeid(maskgen_id[i*`IDLEN_BW +: `IDLEN_BW]), 
            .qbidx(maskgen_qbidx[i*`QBADDR_BW +: `QBADDR_BW]),
            .ucloc(maskgen_ucloc[i*`UCLOC_BW +: `UCLOC_BW]),
            .pchinfo_valid(maskgen_pchinfo_valid[i]),
            .pchtype(maskgen_pchtype[i*`PCHTYPE_BW +: `PCHTYPE_BW]),
            .pchdyn(maskgen_pchdyn[i*`PCHDYN_BW +: `PCHDYN_BW]),
            .mask(mask_array[i]),
            .special(special_array[i])
        );
    end
endgenerate


// psu_maskext
psu_maskext UUT6(
    .pchidx_list(pchidx_list),
    .pivalid_list(pivalid_list),
    .uc_counter(uc_counter), 
    .qb_counter(qb_counter),
    .mask_array(mask_array),
    .special_array(special_array),
    .mask_ext_array(mask_ext_array),
    .special_ext_array(special_ext_array)
);

// psu_cwdarrgen
psu_cwdarrgen UUT7(
    .mask_ext_array(mask_ext_array),
    .special_ext_array(special_ext_array),
    .cwd(cwd),
    .cwdsp(cwdsp),
    .cwdarray(cwdarray)
);


/*
// psu_cwdarrgen
psu_cwdarrgen UUT6(
    .pchinfo_list(pchinfo_list),
    .uc_counter(uc_counter), 
    .qb_counter(qb_counter),
    .mask_array(mask_array),
    .special_array(special_array),
    .cwd(cwd),
    .cwdsp(cwdsp),
    .cwdarray(cwdarray)
);
*/

endmodule
