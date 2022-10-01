`include "define.v"

module psu_cntsrmem(
    rst,
    clk,
    sel_cwdNtime,
    next_id,
    timing,
    cwd,
    cwdsp,
    id_len
);

input rst;
input clk;
input [1:0] sel_cwdNtime;
input next_id;
output reg [`TIME_BW-1:0] timing;
output reg [`CWD_BW-1:0] cwd;
output reg [`CWD_BW-1:0] cwdsp;
output reg [`IDLEN_BW-1:0] id_len;

reg [`CNT_BW-1:0] srmem_init [`CNTLEN_INIT-1:0];
reg [`CNT_BW-1:0] srmem_meas [`CNTLEN_MEAS-1:0];
reg [`CNT_BW-1:0] srmem_resm [`CNTLEN_RESM-1:0];


// combinational transfer
always @(*)
begin
    case (sel_cwdNtime)
        `SELCNT_INIT:
        begin
            {timing, cwd, cwdsp} = srmem_init[0];
            id_len = `CNTLEN_INIT;
        end
        `SELCNT_MEAS:
        begin
            {timing, cwd, cwdsp} = srmem_meas[0];
            id_len = `CNTLEN_MEAS;
        end
        `SELCNT_RESM:
        begin
            {timing, cwd, cwdsp} = srmem_resm[0];
            id_len = `CNTLEN_RESM;
        end
        default:
        begin
            {timing, cwd, cwdsp} = 0;
            id_len = 0;
        end
    endcase
end


// sequential update
integer I;
always @(posedge clk)
begin
    if (rst)
    begin
        // srmem_init
        srmem_init[0] <= {`MEAS_CYCLE, `CWD_MEAS, `CWD_I};
        srmem_init[1] <= {`SQGATE_CYCLE, `CWD_CX, `CWD_I};
        srmem_init[2] <= {`SQGATE_CYCLE, `CWD_H, `CWD_T};
        // srmem_meas
        srmem_meas[0] <= {`SQGATE_CYCLE, `CWD_H, `CWD_SDH};
        srmem_meas[1] <= {`MEAS_CYCLE, `CWD_MEAS, `CWD_I};
        // srmem_resm
        srmem_resm[0] <= {`SQGATE_CYCLE, `CWD_H, `CWD_I};
        srmem_resm[1] <= {`TQGATE_CYCLE, `CWD_CZ0, `CWD_I};
        srmem_resm[2] <= {`TQGATE_CYCLE, `CWD_CZ1, `CWD_I};
        srmem_resm[3] <= {`TQGATE_CYCLE, `CWD_CZ2, `CWD_I};
        srmem_resm[4] <= {`TQGATE_CYCLE, `CWD_CZ3, `CWD_I};
        srmem_resm[5] <= {`SQGATE_CYCLE, `CWD_H, `CWD_I};
        srmem_resm[6] <= {`TQGATE_CYCLE, `CWD_CZ0, `CWD_I};
        srmem_resm[7] <= {`SQGATE_CYCLE, `CWD_H, `CWD_I};
        srmem_resm[8] <= {`TQGATE_CYCLE, `CWD_CZ1, `CWD_I};
        srmem_resm[9] <= {`SQGATE_CYCLE, `CWD_H, `CWD_I};
        srmem_resm[10] <= {`TQGATE_CYCLE, `CWD_CZ2, `CWD_I};
        srmem_resm[11] <= {`SQGATE_CYCLE, `CWD_H, `CWD_SDH};
        srmem_resm[12] <= {`TQGATE_CYCLE, `CWD_CZ3, `CWD_CZ3};
        srmem_resm[13] <= {`SQGATE_CYCLE, `CWD_H, `CWD_HS};
        srmem_resm[14] <= {`TQGATE_CYCLE, `CWD_CZ3, `CWD_I};
        srmem_resm[15] <= {`TQGATE_CYCLE, `CWD_CZ2, `CWD_I};
        srmem_resm[16] <= {`TQGATE_CYCLE, `CWD_CZ1, `CWD_I};
        srmem_resm[17] <= {`TQGATE_CYCLE, `CWD_CZ0, `CWD_I};
        srmem_resm[18] <= {`SQGATE_CYCLE, `CWD_H, `CWD_I};
        srmem_resm[19] <= {`MEAS_CYCLE, `CWD_MEAS, `CWD_I};
    end
    else if (next_id)
    begin
        for (I = 0; I < id_len; I = I+1)
        begin
            case (sel_cwdNtime)
                `SELCNT_INIT:
                begin
                    if (I == id_len-1)
                        srmem_init[id_len-1] <= srmem_init[0];
                    else
                        srmem_init[I] <= srmem_init[I+1];
                end
                `SELCNT_MEAS:
                begin
                    if (I == id_len-1)
                        srmem_meas[id_len-1] <= srmem_meas[0];
                    else
                        srmem_meas[I] <= srmem_meas[I+1];
                end
                `SELCNT_RESM:
                begin
                    if (I == id_len-1)
                        srmem_resm[id_len-1] <= srmem_resm[0];
                    else
                        srmem_resm[I] <= srmem_resm[I+1];
                end
            endcase
        end
    end
end

endmodule
