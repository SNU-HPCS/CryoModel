`include "define.v"

module psu_opNloc(
    opcode_running,
    pchop_list,
    uc_counter,
    pcu_opcode,
    ucc_ucloc
);

input [`OPCODE_BW-1:0] opcode_running;
input [`NUM_PCU*(2*`OPCODE_BW)-1:0] pchop_list;
input [`NUM_UCC*`UCADDR_BW-1:0] uc_counter;
output reg [`NUM_UCC*`UCLOC_BW-1:0] ucc_ucloc;
output reg [`NUM_PCU*`OPCODE_BW-1:0] pcu_opcode;


integer I, J;
reg [`OPCODE_BW-1:0] opcode, pchop0, pchop1;
reg [`UCADDR_BW-1:0] ucidx, ucrow, uccol;
reg uc_west, uc_north, uc_east, uc_south, uc_lowtri, uc_uppertri, uc_leftdiag, uc_rightdiag;

always @(*)
begin
    // pcu_opcode
    for (I = 0; I < `NUM_PCU; I = I+1)
    begin
        if (opcode_running == `LQM_X_OPCODE | opcode_running == `LQM_Y_OPCODE | opcode_running == `LQM_Z_OPCODE)
        begin
            {pchop0, pchop1} = pchop_list[I*(2*`OPCODE_BW) +: (2*`OPCODE_BW)];
            opcode = (pchop0 & pchop1);
        end
        else
            opcode = opcode_running;
        pcu_opcode[I*`OPCODE_BW +: `OPCODE_BW] = opcode;
    end
    // ucc_ucloc
    for (J = 0; J < `NUM_UCC; J = J+1)
    begin
            // ucloc
            ucidx = uc_counter[J*`UCADDR_BW +: `UCADDR_BW];
            ucrow = (ucidx) / (`NUM_UCCOL);
            uccol = (ucidx) % (`NUM_UCCOL);
            /*
            uc_west = (uccol == 0);
            uc_north = (ucrow == 0);
            uc_east = (uccol == `NUM_UCCOL-1);
            uc_south = (ucrow == `NUM_UCROW-1);
            uc_lowtri = ((ucrow+uccol) > `NUM_UCROW);
            uc_uppertri = ((ucrow+uccol) < `NUM_UCROW-1);
            uc_leftdiag = ((ucrow+uccol) == `NUM_UCROW-1);
            uc_rightdiag = ((ucrow+uccol) == `NUM_UCROW);
            */
            ucc_ucloc[J*`UCLOC_BW +: `UCLOC_BW] = {(uccol==0), (ucrow==0), (uccol==`NUM_UCCOL-1), (ucrow==`NUM_UCROW-1), ((ucrow+uccol) > `NUM_UCROW), ((ucrow+uccol) < `NUM_UCROW-1), ((ucrow+uccol) == `NUM_UCROW-1), ((ucrow+uccol) == `NUM_UCROW)};
    end

end


endmodule
