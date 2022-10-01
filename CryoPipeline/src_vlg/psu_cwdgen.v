`include "define.v"

module psu_cwdgen(
    mask,
    cwd,
    final_cwd
);

input mask;
input [`CWD_BW-1:0] cwd;
output [`CWD_BW-1:0] final_cwd;

assign final_cwd = (mask) ? cwd : `CWD_I;

endmodule
