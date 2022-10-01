`include "define.v"

module psu_ctrl(
    opcode_running,
    psu_valid,
    state,
    qb_counter0,
    uc_counter0,
    pchinfo_rdlast,
    id_counter,
    id_len,
    round_counter,
    pchinfo_valid,
    pchinfo_nextready,
    sel_cwdNtime,
    next_uc,
    next_pch,
    next_id,
    next_round,
    next_opcode,
    next_state
);

input [`OPCODE_BW-1:0] opcode_running;
input psu_valid;
input state;
input [`QBADDR_BW-1:0] qb_counter0;
input [`UCADDR_BW-1:0] uc_counter0;
input pchinfo_rdlast;
input [`IDLEN_BW-1:0] id_counter;
input [`IDLEN_BW-1:0] id_len;
input [`ROUND_BW-1:0] round_counter;
input pchinfo_valid;
input pchinfo_nextready;
output reg [1:0] sel_cwdNtime;
output reg next_uc;
output reg next_pch;
output reg next_id;
output reg next_round;
output reg next_opcode;
output reg next_state;


always @(*)
begin
    // sel_cwdNtime
    if (opcode_running == `LQI_OPCODE | opcode_running == `INIT_INTMD_OPCODE)
        sel_cwdNtime = `SELCNT_INIT;
    else if (opcode_running == `LQM_X_OPCODE | opcode_running == `LQM_Y_OPCODE | opcode_running == `LQM_Z_OPCODE | opcode_running == `MEAS_INTMD_OPCODE)
        sel_cwdNtime = `SELCNT_MEAS;
    else if (opcode_running == `RUN_ESM_OPCODE)
        sel_cwdNtime = `SELCNT_RESM;
    else
        sel_cwdNtime = `SELCNT_INVALID;
    // next_counters
    if (state == `PSU_RUNNING)
    begin
        // next_uc
        if ((qb_counter0 + `NUM_QBCTRL) >= `NUM_QB)
            next_uc = 1;
        else
            next_uc = 0;
        // next_pch
        if ((next_uc) & ((uc_counter0 + `NUM_UCC) >= `NUM_UC))
            next_pch = 1;
        else
            next_pch = 0;
        // next_id
        if (next_pch & pchinfo_rdlast)
            next_id = 1;
        else
            next_id = 0;
        // next_round
        if (next_id & id_counter == (id_len-1))
            next_round = 1;
        else
            next_round = 0;
        // next_opcode 
        if (next_round)
        begin
            if (opcode_running == `RUN_ESM_OPCODE)
            begin
                if (round_counter == `CODE_DIST-1)
                    next_opcode = 1;
                else
                    next_opcode = 0;
            end
            else
                next_opcode = 1;
        end
        else
            next_opcode = 0;
    end
    else
    begin
        next_uc = 0;
        next_pch = 0;
        next_id = 0;
        next_round = 0;
        next_opcode = 0;
    end

    // next_state 
    if (state == `PSU_READY)
    begin
        if (pchinfo_valid)
            next_state = `PSU_RUNNING;
        else
            next_state = `PSU_READY;
    end
    else // state == `PSU_RUNNING
    begin
        if (next_id)
        begin
            if (pchinfo_nextready)
                next_state = `PSU_RUNNING;
            else
                next_state = `PSU_READY;
        end
        else
            next_state = `PSU_RUNNING;
    end
end

endmodule
