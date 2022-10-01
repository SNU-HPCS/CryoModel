`include "define.v"

module psu_maskgen (
    opcode,
    timeid, 
    qbidx, 
    ucloc, 
    pchinfo_valid,
    pchtype, 
    pchdyn,
    mask,
    special
);

input [`OPCODE_BW-1:0] opcode;
input [`IDLEN_BW-1:0] timeid;
input [`QBADDR_BW-1:0] qbidx; // 0~3: dq, 4~7: aq
input [`UCLOC_BW-1:0] ucloc; // west, north, east, south, lowtri, uppertri, leftdiag, rightdiag
input pchinfo_valid;
input [`PCHTYPE_BW-1:0] pchtype;
input [`PCHDYN_BW-1:0] pchdyn;
output reg [0:0] mask, special;

// decode opcode
wire is_init, is_measx, is_measy, is_measz, is_resm, is_meassplit, is_initmerge;
assign is_init = (opcode == `LQI_OPCODE);
assign is_measx = (opcode == `LQM_X_OPCODE);
assign is_measy = (opcode == `LQM_Y_OPCODE);
assign is_measz = (opcode == `LQM_Z_OPCODE);
assign is_resm = (opcode == `RUN_ESM_OPCODE);
assign is_meassplit = (opcode == `MEAS_INTMD_OPCODE);
assign is_initmerge = (opcode == `INIT_INTMD_OPCODE);

// reverse: for distillation, MT is only reversed pchtype
wire reverse;
assign reverse = (pchtype == `PCHTYPE_MT);

// patch_dyninfo
wire [`FACEBD_BW-1:0] facebd_w, facebd_n, facebd_e, facebd_s; 
wire [`CORNERBD_BW-1:0] cornerbd_nw, cornerbd_ne, cornerbd_sw, cornerbd_se; 
assign {facebd_w, facebd_n, facebd_e, facebd_s, cornerbd_nw, cornerbd_ne, cornerbd_sw, cornerbd_se} = pchdyn;

// ucloc info
// REVISED: IK - differentiate uc_leftdiag and uc_rightdiag
// REVISED: IK - add uc_valid for considering ucidx higher than the number of unit cells
wire uc_west, uc_north, uc_east, uc_south, uc_lowtri, uc_uppertri, uc_leftdiag, uc_rightdiag, uc_valid;
assign {uc_west, uc_north, uc_east, uc_south, uc_lowtri, uc_uppertri, uc_leftdiag, uc_rightdiag} = ucloc;
assign uc_valid = (uc_west | uc_north | uc_east | uc_south | uc_lowtri | uc_uppertri | uc_leftdiag | uc_rightdiag);

// definition for various timeid groups
// REVISED: IK - timeid groups are adjusted to 20-codeword sequence for RESM
wire is_entq4id;
wire is_entq5id;
wire is_entq6id;
wire is_entq7id;
wire is_normaqid;
wire is_entdqid;
wire is_q0q4id;
wire is_q0q5id;
wire is_q0q6id;
wire is_q0q7id;
wire is_q1q4id;
wire is_q1q5id;
wire is_q1q6id;
wire is_q1q7id;
wire is_q2q4id;
wire is_q2q5id;
wire is_q2q6id;
wire is_q2q7id;
wire is_q3q4id;
wire is_q3q5id;
wire is_q3q6id;
wire is_q3q7id;
wire is_q0q45id;
wire is_q0q46id;
wire is_q0q47id;
wire is_q0q56id;
wire is_q0q57id;
wire is_q0q67id;
wire is_q1q45id;
wire is_q1q46id;
wire is_q1q47id;
wire is_q1q56id;
wire is_q1q57id;
wire is_q1q67id;
wire is_q2q45id;
wire is_q2q46id;
wire is_q2q47id;
wire is_q2q56id;
wire is_q2q57id;
wire is_q2q67id;
wire is_q3q45id;
wire is_q3q46id;
wire is_q3q47id;
wire is_q3q56id;
wire is_q3q57id;
wire is_q3q67id;
wire is_q0q456id;
wire is_q0q457id;
wire is_q0q467id;
wire is_q0q567id;
wire is_q1q456id;
wire is_q1q457id;
wire is_q1q467id;
wire is_q1q567id;
wire is_q2q456id;
wire is_q2q457id;
wire is_q2q467id;
wire is_q2q567id;
wire is_q3q456id;
wire is_q3q457id;
wire is_q3q467id;
wire is_q3q567id;
wire is_q0allid;
wire is_q1allid;
wire is_q2allid;
wire is_q3allid;

assign is_entq4id = (timeid == 0 | timeid == 2 | timeid == 16 | timeid == 18);
assign is_entq5id = (timeid == 0 | timeid == 1 | timeid == 17 | timeid == 18);
assign is_entq6id = is_entq4id;
assign is_entq7id = is_entq5id;
assign is_normaqid = (timeid == 5 | timeid == 6 | timeid == 8 | timeid == 10 | timeid == 12 | timeid == 13 | timeid == 19);
assign is_entdqid = (timeid == 0 | timeid == 1 | timeid == 2 | timeid == 16 | timeid == 17 | timeid == 18 | timeid == 19);

assign is_q0q4id = (reverse) ? (timeid == 8) : (timeid == 7 | timeid == 8 | timeid == 9); 
assign is_q0q5id = (reverse) ? (timeid == 10) : (timeid == 9 | timeid == 10 | timeid == 11); 
assign is_q0q6id = (reverse) ? (timeid == 5 | timeid == 6 | timeid == 7) : (timeid == 6); 
assign is_q0q7id = (reverse) ? (timeid == 11 | timeid == 12 | timeid == 13) : (timeid == 12); 
assign is_q1q4id = (reverse) ? (timeid == 6) : (timeid == 5 | timeid == 6 | timeid == 7); 
assign is_q1q5id = (reverse) ? (timeid == 12) : (timeid == 11 | timeid == 12 | timeid == 13); 
assign is_q1q6id = (reverse) ? (timeid == 9 | timeid == 10 | timeid == 11) : (timeid == 10); 
assign is_q1q7id = (reverse) ? (timeid == 7 | timeid == 8 | timeid == 9) : (timeid == 8); 
assign is_q2q4id = (reverse) ? (timeid == 12) : (timeid == 11 | timeid == 12 | timeid == 13); 
assign is_q2q5id = (reverse) ? (timeid == 6) : (timeid == 5 | timeid == 6 | timeid == 7); 
assign is_q2q6id = (reverse) ? (timeid == 7 | timeid == 8 | timeid == 9) : (timeid == 8); 
assign is_q2q7id = (reverse) ? (timeid == 9 | timeid == 10 | timeid == 11) : (timeid == 10); 
assign is_q3q4id = (reverse) ? (timeid == 10) : (timeid == 9 | timeid == 10 | timeid == 11); 
assign is_q3q5id = (reverse) ? (timeid == 8) : (timeid == 7 | timeid == 8 | timeid == 9); 
assign is_q3q6id = (reverse) ? (timeid == 11 | timeid == 12 | timeid == 13) : (timeid == 12); 
assign is_q3q7id = (reverse) ? (timeid == 5 | timeid == 6 | timeid == 7) : (timeid == 6); 

assign is_q0q45id = (is_q0q4id ^ is_q0q5id);
assign is_q0q46id = (is_q0q4id ^ is_q0q6id);
assign is_q0q47id = (is_q0q4id ^ is_q0q7id);
assign is_q0q56id = (is_q0q5id ^ is_q0q6id);
assign is_q0q57id = (is_q0q5id ^ is_q0q7id);
assign is_q0q67id = (is_q0q6id ^ is_q0q7id);
assign is_q1q45id = (is_q1q4id ^ is_q1q5id);
assign is_q1q46id = (is_q1q4id ^ is_q1q6id);
assign is_q1q47id = (is_q1q4id ^ is_q1q7id);
assign is_q1q56id = (is_q1q5id ^ is_q1q6id);
assign is_q1q57id = (is_q1q5id ^ is_q1q7id);
assign is_q1q67id = (is_q1q6id ^ is_q1q7id);
assign is_q2q45id = (is_q2q4id ^ is_q2q5id);
assign is_q2q46id = (is_q2q4id ^ is_q2q6id);
assign is_q2q47id = (is_q2q4id ^ is_q2q7id);
assign is_q2q56id = (is_q2q5id ^ is_q2q6id);
assign is_q2q57id = (is_q2q5id ^ is_q2q7id);
assign is_q2q67id = (is_q2q6id ^ is_q2q7id);
assign is_q3q45id = (is_q3q4id ^ is_q3q5id);
assign is_q3q46id = (is_q3q4id ^ is_q3q6id);
assign is_q3q47id = (is_q3q4id ^ is_q3q7id);
assign is_q3q56id = (is_q3q5id ^ is_q3q6id);
assign is_q3q57id = (is_q3q5id ^ is_q3q7id);
assign is_q3q67id = (is_q3q6id ^ is_q3q7id);

assign is_q0q456id = (is_q0q4id ^ is_q0q5id ^ is_q0q6id);
assign is_q0q457id = (is_q0q4id ^ is_q0q5id ^ is_q0q7id);
assign is_q0q467id = (is_q0q4id ^ is_q0q6id ^ is_q0q7id);
assign is_q0q567id = (is_q0q5id ^ is_q0q6id ^ is_q0q7id);
assign is_q1q456id = (is_q1q4id ^ is_q1q5id ^ is_q1q6id);
assign is_q1q457id = (is_q1q4id ^ is_q1q5id ^ is_q1q7id);
assign is_q1q467id = (is_q1q4id ^ is_q1q6id ^ is_q1q7id);
assign is_q1q567id = (is_q1q5id ^ is_q1q6id ^ is_q1q7id);
assign is_q2q456id = (is_q2q4id ^ is_q2q5id ^ is_q2q6id);
assign is_q2q457id = (is_q2q4id ^ is_q2q5id ^ is_q2q7id);
assign is_q2q467id = (is_q2q4id ^ is_q2q6id ^ is_q2q7id);
assign is_q2q567id = (is_q2q5id ^ is_q2q6id ^ is_q2q7id);
assign is_q3q456id = (is_q3q4id ^ is_q3q5id ^ is_q3q6id);
assign is_q3q457id = (is_q3q4id ^ is_q3q5id ^ is_q3q7id);
assign is_q3q467id = (is_q3q4id ^ is_q3q6id ^ is_q3q7id);
assign is_q3q567id = (is_q3q5id ^ is_q3q6id ^ is_q3q7id);

assign is_q0allid = (is_q0q4id ^ is_q0q5id ^ is_q0q6id ^ is_q0q7id);
assign is_q1allid = (is_q1q4id ^ is_q1q5id ^ is_q1q6id ^ is_q1q7id);
assign is_q2allid = (is_q2q4id ^ is_q2q5id ^ is_q2q6id ^ is_q2q7id);
assign is_q3allid = (is_q3q4id ^ is_q3q5id ^ is_q3q6id ^ is_q3q7id);

// REVISED: IK - add several intermediate wires for convenience
wire meas_mask;
wire anc_pchtype;
assign meas_mask = (is_measz) ? (timeid == 1) : 1;
assign anc_pchtype = (pchtype == `PCHTYPE_AW | pchtype == `PCHTYPE_AC | pchtype == `PCHTYPE_AE | pchtype == `PCHTYPE_AWE);

always @(*)
begin
    if (~pchinfo_valid)
    begin
        mask = 0;
    end
    else
    begin
        /*** INIT ***/
        if (is_init)
        begin
            /*** INIT-mask ***/
            if (qbidx >= 4)
            begin
                mask = 0;
            end
            else // for dq
            begin
                case(pchtype)
                    `PCHTYPE_ZT: // INIT: PCHTYPE-ZT
                    begin
                        if (timeid == 2) 
                        begin
                            mask = 0;
                        end
                        else // timeid == 0, 1
                        begin
                            if (uc_west & uc_north) // NW
                                mask = 0;
                            else if (uc_north)      // N, NE
                            begin
                                if (qbidx == 2 | qbidx == 3)
                                    mask = 1;
                                else
                                    mask = 0;
                            end
                            else if (uc_west) // W, SW
                            begin
                                if (qbidx == 1 | qbidx == 3)
                                    mask = 1;
                                else
                                    mask = 0;
                            end
                            else if (uc_valid) // C, E, S, SE
                                mask = 1;
                            else // INVALID UC
                                mask = 0;
                        end
                    end
                    `PCHTYPE_ZB: // INIT: PCHTYPE-ZB
                    begin
                        if (timeid == 2)
                        begin
                            mask = 0;
                        end
                        else // timeid == 0, 1
                        begin
                            if (uc_west & ~uc_south) // NW, W
                            begin
                                if (qbidx == 1 | qbidx == 3)
                                    mask = 1;
                                else
                                    mask = 0;
                            end
                            else if (uc_west) // SW
                            begin
                                if (qbidx == 1)
                                    mask = 1;
                                else
                                    mask = 0;
                            end
                            else if (uc_valid) // N, NE, C, E, S, SE
                                mask = 1;
                            else // INVALID UC
                                mask = 0;
                        end
                    end
                    `PCHTYPE_MB: // INIT: PCHTYPE-MB
                    begin
                        if (timeid == 2)
                        begin
                            if (uc_rightdiag | uc_lowtri)
                                mask = 1;
                            else if (uc_leftdiag)
                            begin
                                if (qbidx == 3)
                                    mask = 1;
                                else
                                    mask = 0;
                            end
                            else
                                mask = 0;
                        end
                        else // timeid == 0, 1
                        begin
                            if (uc_north & uc_west) // NW
                            begin
                                if (qbidx == 3)
                                    mask = 1;
                                else
                                    mask = 0;
                            end
                            else if (uc_north) // N, NE
                            begin
                                if (qbidx == 2 | qbidx == 3)
                                    mask = 1;
                                else
                                    mask = 0;
                            end
                            else if (uc_west) // W, SW
                            begin
                                if (qbidx == 1 | qbidx == 3)
                                    mask = 1;
                                else
                                    mask = 0;
                            end
                            else if (uc_valid) // C, E, S, SE
                                mask = 1;
                            else // INVALID UC
                                mask = 0;
                        end
                    end
                    `PCHTYPE_M: // INIT: PCHTYPE-M
                    begin
                        if (uc_uppertri | uc_leftdiag)
                        begin // for timeid == 0, 1, 2
                            if (uc_north & uc_west) // NW
                            begin
                                if (qbidx == 3)
                                    mask = 1;
                                else
                                    mask = 0;
                            end
                            else if (uc_north) // N, NE
                            begin
                                if (qbidx == 2 | qbidx == 3)
                                    mask = 1;
                                else
                                    mask = 0;
                            end
                            else if (uc_west) // W, SW
                            begin
                                if (qbidx == 1 | qbidx == 3)
                                    mask = 1;
                                else
                                    mask = 0;
                            end
                            else // OTHER UCs in left-top
                            begin
                                mask = 1;
                            end
                        end
                        else if (uc_rightdiag)
                        begin
                            if (timeid == 2)
                            begin
                                if (qbidx == 0)
                                    mask = 1;
                                else
                                    mask = 0;
                            end
                            else // timeid == 0, 1
                            begin
                                mask = 1;
                            end
                        end
                        else if (uc_valid) // uc_lowtri
                        begin
                            if (timeid == 2)
                                mask = 0;
                            else // timeid == 0, 1
                            begin
                                mask = 1;
                            end
                        end
                        else // INVALID UC
                            mask = 0;
                    end
                    `PCHTYPE_X:
                    begin
                        //timeid == 0, 1, 2
                        if (uc_west & uc_north) // NW
                        begin
                            if (qbidx == 3)
                                mask = 1;
                            else
                                mask = 0;
                        end
                        else if (uc_north) // N, NE
                        begin
                            if (qbidx == 2 | qbidx == 3)
                                mask = 1;
                            else
                                mask = 0;
                        end
                        else if (uc_west) // W, SW
                        begin
                            if (qbidx == 1 | qbidx == 3)
                                mask = 1;
                            else
                                mask = 0;
                        end
                        else if (uc_valid) // C, E, S, SE
                            mask = 1;
                        else // INVALID UC
                            mask = 0;
                    end
                    default: // INIT: PCHTYPE-OTHERS
                    begin
                        mask = 0;
                    end
                endcase
            end
            /*** INIT-special ***/
            if (pchtype == `PCHTYPE_M | pchtype == `PCHTYPE_MB)
            begin // for 'm' gate for left-bottom dq at id == 2
                if (timeid == 2)
                begin
                    if (uc_west & uc_south)
                    begin
                        if (qbidx == 3)
                            special = 1;
                        else
                            special = 0;
                    end
                    else
                        special = 0;
                end
                else // timeid == 0, 1
                    special = 0;
            end
            else // INIT-special: PCHTYPE-OTHERS
                special = 0;
         end // INIT-END

        /*** MEAS ***/
        else if (is_measx | is_measy | is_measz)
        begin
            /*** MEAS-mask ***/
            if (qbidx >= 4)
                mask = 0;
            else // for dq
            begin
                if (uc_west & uc_north) // NW
                begin
                    if (facebd_n == `FACEBD_PP) // only for ZB
                    begin
                        if (qbidx == 1 | qbidx == 3)
                            mask = meas_mask;
                        else
                            mask = 0;
                    end
                    else // other patches
                    begin
                        if (cornerbd_nw != `CORNERBD_C) // except for ZT
                        begin
                            if (qbidx == 3)
                                mask = meas_mask;
                            else
                                mask = 0;
                        end
                        else // only for ZT
                            mask = 0;
                    end
                end
                else if (uc_north) // N, NE
                begin
                    if (facebd_n == `FACEBD_PP) // only for ZB
                    begin
                        mask = meas_mask;
                    end
                    else // other patches
                    begin
                        if (qbidx == 2 | qbidx == 3)
                            mask = meas_mask;
                        else
                            mask = 0;
                    end
                end
                else if (uc_west) // W, SW
                begin
                    if (uc_south & cornerbd_sw == `CORNERBD_C) // only for ZB's SW
                    begin
                        if (qbidx == 1)
                            mask = meas_mask;
                        else
                            mask = 0;
                    end
                    else // others
                    begin
                        if (qbidx == 1 | qbidx == 3)
                            mask = meas_mask;
                        else
                            mask = 0;
                    end
                end
                else if (uc_valid) // C, E, S, SE
                    mask = meas_mask;
                else // INVALID UC
                    mask = 0;
            end // MEAS-mask END

            /*** MEAS-special ***/
            if (is_measy & timeid == 0)
                special = 1;
            else
                special = 0;
        end
        
        /*** INIT_MERGE ***/
        else if (is_initmerge)
        begin
            /*** INIT_MERGE-mask ***/
            if (qbidx >= 4)
                mask = 0;
            else
            begin
                if (uc_west & uc_north) // NW
                begin
                    if (qbidx == 0) // for entdq
                    begin
                        mask = 0;
                    end
                    else if (qbidx == 1)
                    begin
                        if (facebd_n == `FACEBD_PP & pchtype != `PCHTYPE_ZB)
                            mask = 1;
                        else
                            mask = 0;
                    end
                    else if (qbidx == 2) 
                    begin
                        mask = (facebd_w == `FACEBD_MP | facebd_w == `FACEBD_PP);
                    end
                    else // qbidx == 3
                    begin
                        if (pchtype == `PCHTYPE_MT)
                            mask = (timeid <= 1);
                        else if (anc_pchtype)
                            mask = 1;
                        else
                            mask = 0;
                    end
                end
                else if (uc_north) // N, NE
                begin
                    if (qbidx == 0 | qbidx == 1)
                    begin
                        if (facebd_n == `FACEBD_PP & pchtype != `PCHTYPE_ZB)
                            mask = 1;
                        else
                            mask = 0;
                    end
                    else // qbidx == 2, 3
                    begin
                        if (pchtype == `PCHTYPE_MT)
                            mask = (timeid <= 1);
                        else if (anc_pchtype)
                            mask = 1;
                        else
                            mask = 0;
                    end
                end
                else if (uc_west) // W, SW
                begin
                    if (qbidx == 1 | qbidx == 3)
                    begin
                        if (pchtype == `PCHTYPE_MT)
                            mask = (timeid <= 1);
                        else if (anc_pchtype)
                            mask = 1;
                        else
                            mask = 0;
                    end
                    else // qbidx == 0, 2
                    begin
                        mask = (facebd_w == `FACEBD_MP | facebd_w == `FACEBD_PP);
                    end
                end
                else if (uc_valid)// C, E, S, SE
                begin
                    if (pchtype == `PCHTYPE_MT)
                        mask = (timeid <= 1);
                    else if (anc_pchtype)
                        mask = 1;
                    else
                        mask = 0;
                end
                else // INVALID UC
                    mask = 0;
            end
            /*** INIT_MERGE-special ***/
            special = 0;
        end
        
        /*** MEAS_SPLIT ***/
        else if (is_meassplit)
        begin
            /*** MEAS_SPLIT-mask ***/
            if (qbidx >= 4)
                mask = 0;
            else
            begin
                if (uc_west & uc_north) // NW
                begin
                    if (qbidx == 1)
                        mask = (facebd_n == `FACEBD_PP & pchtype != `PCHTYPE_ZB);
                    else if (qbidx == 2) 
                        mask = (facebd_w == `FACEBD_MP | facebd_w == `FACEBD_PP);
                    else if (qbidx == 3)
                        mask = (anc_pchtype);
                    else
                        mask = 0;
                end
                else if (uc_north) // N, NE
                begin
                    if (qbidx == 0 | qbidx == 1)
                        mask = (facebd_n == `FACEBD_PP & pchtype != `PCHTYPE_ZB);
                    else // qbidx == 2, 3
                        mask = (anc_pchtype);
                end
                else if (uc_west) // W, SW
                begin
                    if (qbidx == 1 | qbidx == 3)
                        mask = (anc_pchtype);
                    else // qbidx == 0, 2
                        mask = (facebd_w == `FACEBD_MP | facebd_w == `FACEBD_PP);
                end
                else if (uc_valid)// C, E, S, SE
                    mask = (anc_pchtype);
                else // INVALID UC
                    mask = 0;
            end
            /*** MEAS_SPLIT-special ***/
            special = 0;
        end

        /*** RESM ***/
        else if (is_resm)
        begin
            /*** RESM-mask ***/
            if (uc_west & uc_north) // RESM-NW
            begin
                case (qbidx)
                    0: begin
                        // PCHTYPE-MB, MERGED
                        if (cornerbd_nw == `CORNERBD_YE)
                            mask = is_entdqid;
                        // PCHTYPE-AW, MERGED
                        else if (cornerbd_nw == `CORNERBD_IE | cornerbd_nw == `CORNERBD_ZE)
                            mask = is_entdqid;
                        else
                            mask = 0;
                    end
                    1: begin
                        if (facebd_n == `FACEBD_PP)
                        begin
                            // PCHTYPE-M, BOTTOM, MERGED
                            // PCHTYPE-A, MERGED with above M
                            if (cornerbd_nw == `CORNERBD_Z | cornerbd_nw == `CORNERBD_ZE)
                                mask = is_q1q567id;
                            // PCHTYPE-ZB
                            else 
                                mask = is_q1q56id;
                        end
                        // PCHTYPE-MB, SPLIT, MERGED
                        else if (facebd_n == `FACEBD_LP)
                            mask = is_entdqid;
                        // 
                        else
                            mask = 0;
                    end
                    2: begin
                        if (facebd_w == `FACEBD_PP)
                        begin
                            // PCHTYPE-MB, MERGED
                            if (cornerbd_nw == `CORNERBD_YE)
                                mask = is_q2allid;
                            // PCHTYPE-A, ALWAYS
                            // PCHTYPE-X, MERGED
                            else
                                mask = is_q2q567id;
                        end
                        else if (facebd_w == `FACEBD_MP)
                        begin
                            // PCHTYPE-MT, MERGED
                            mask = is_q2q457id;
                        end
                        else
                            mask = 0;
                    end
                    3: begin
                        if (facebd_w == `FACEBD_PP)
                        begin
                            // PCHTYPE-MB, MERGED
                            if (cornerbd_nw == `CORNERBD_YE)
                                mask = is_q3allid;
                            // PCHTYPE-A, ALWAYS
                            // PCHTYPE-X, MERGED
                            else
                                mask = is_q3q567id;
                        end
                        // PCHTYPE-MT, MERGED
                        else if (facebd_w == `FACEBD_MP)
                        begin
                            mask = is_q3q457id;
                        end
                        // PCHTYPE-M, MERGED (with top)
                        // PCHTYPE-ZB, ALWAYS
                        else if (facebd_n == `FACEBD_PP)
                        begin
                            mask = is_q3q567id;
                        end
                        // PCHTYPE-MB, SPLIT
                        else if (facebd_n == `FACEBD_LP)
                        begin
                            mask = is_q3q456id;
                        end
                        else if (facebd_n == `FACEBD_X)
                        begin
                            // PCHTYPE-M, not MERGED with top
                            if (cornerbd_nw != `CORNERBD_C)
                                mask = is_q3q57id;
                            // PCHTYPE-ZT
                            else
                                mask = 0;
                        end
                        else if (facebd_n == `FACEBD_Z)
                        begin
                            // PCHTYPE-MT, SPLIT
                            if (reverse)
                                mask = is_q3q57id;
                            // PCHTYPE-X, PS
                            // PCHTYPE-MP, P
                            else
                                mask = is_q3q56id;
                        end
                        else 
                            mask = 0;
                    end
                    4: begin
                        if (is_normaqid)
                            mask = 1;
                        else if (is_entq4id)
                        begin
                            // PCHTYPE-MB, SM
                            mask = (facebd_n == `FACEBD_LP);
                        end
                        else 
                            mask = 0;
                    end
                    5: begin
                        mask = is_normaqid;
                    end
                    6: begin
                        if (is_normaqid)
                            mask = 1;
                        else if (is_entq6id)
                        begin
                            // PCHTYPE-MB, SM
                            mask = (facebd_n == `FACEBD_LP);
                        end
                        else
                            mask = 0;
                    end
                    7: begin
                        mask = is_normaqid;
                    end
                    default: begin
                        mask = 0;
                    end
                endcase
            end
            else if (uc_north & ~uc_east) // RESM-N
            begin
                case (qbidx)
                    0: begin
                        if (facebd_n == `FACEBD_PP)
                            mask = is_q0allid;
                        else if (facebd_n == `FACEBD_LP)
                            mask = is_entdqid;
                        else
                            mask = 0;
                    end
                    1: begin
                        if (facebd_n == `FACEBD_PP)
                            mask = is_q1allid;
                        else if (facebd_n == `FACEBD_LP)
                            mask = is_entdqid;
                        else
                            mask = 0;
                    end
                    2: begin
                        if (facebd_n == `FACEBD_PP | facebd_n == `FACEBD_LP)
                            mask = is_q2allid;
                        else if (facebd_n == `FACEBD_X)
                            mask = is_q2q457id;
                        else if (facebd_n == `FACEBD_Z)
                        begin
                            if (reverse)
                                mask = is_q2q457id;
                            else
                                mask = is_q2q567id;
                        end
                        else
                            mask = 0;
                    end
                    3: begin
                        if (facebd_n == `FACEBD_PP)
                            mask = is_q3allid;
                        else if (facebd_n == `FACEBD_X)
                            mask = is_q3q457id;
                        else if (facebd_n == `FACEBD_Z)
                        begin
                            if (reverse)
                                mask = is_q3q457id;
                            else
                                mask = is_q3q567id;
                        end
                        else
                            mask = 0;
                    end
                    4: begin
                        if (is_normaqid)
                            mask = 1;
                        else if (is_entq4id)
                            mask = (facebd_n == `FACEBD_LP);
                        else 
                            mask = 0;
                    end
                    5: begin
                        mask = is_normaqid;
                    end
                    6: begin
                        if (is_normaqid)
                            mask = 1;
                        else if (is_entq6id)
                            mask = (facebd_n == `FACEBD_LP);
                        else 
                            mask = 0;
                    end
                    7: begin
                        mask = is_normaqid;
                    end
                    default: begin
                        mask = 0;
                    end
                endcase
            end
            else if (uc_north) // RESM-NE
            begin
                case (qbidx)
                    0: begin
                        if (facebd_n == `FACEBD_LP)
                            mask = is_entdqid;
                        else if (facebd_n == `FACEBD_PP)
                            mask = is_q0allid;
                        else
                            mask = 0;
                    end
                    1: begin
                        if (facebd_n == `FACEBD_LP)
                            mask = is_entdqid;
                        else if (facebd_n == `FACEBD_PP)
                        begin
                            if (facebd_w == `FACEBD_PP | (facebd_w == `FACEBD_Z & facebd_e == `FACEBD_Z))
                                mask = is_q1q467id;
                            else if (facebd_w == `FACEBD_Z & facebd_e == `FACEBD_X)
                                mask = is_q1q47id;
                            else if (facebd_w == `FACEBD_Z & facebd_e == `FACEBD_PP)
                                mask = is_q1q457id;
                            else
                                mask = 0;
                        end
                        else
                            mask = 0;
                    end
                    2: begin
                        if (facebd_n == `FACEBD_PP | facebd_n == `FACEBD_LP)
                            mask = is_q2allid;
                        else if (facebd_n == `FACEBD_X)
                            mask = is_q2q457id;
                        else if (facebd_n == `FACEBD_Z)
                        begin
                            if (reverse)
                                mask = is_q2q457id;
                            else
                                mask = is_q2q567id;
                        end
                        else
                            mask = 0;
                    end
                    3: begin
                        if (facebd_n == `FACEBD_Z & facebd_e == `FACEBD_Z)
                        begin
                            if (reverse)
                                mask = is_q3q457id;
                            else
                                mask = 0;
                        end
                        else if (facebd_n == `FACEBD_Z & facebd_e == `FACEBD_X)
                            mask = is_q3q57id;
                        else if (facebd_n == `FACEBD_X & facebd_e == `FACEBD_Z)
                            mask = is_q3q47id;
                        else if (facebd_n == `FACEBD_PP | facebd_n == `FACEBD_LP)
                        begin
                            if (facebd_e == `FACEBD_PP)
                                mask = is_q3allid;
                            else if (facebd_e == `FACEBD_Z)
                                mask = is_q3q467id;
                            else if (facebd_e == `FACEBD_X)
                                mask = is_q3q457id;
                            else
                                mask = 0;
                        end
                        else if (facebd_e == `FACEBD_MP)
                            mask = is_q3q457id;
                        else
                            mask = 0;
                    end
                    4: begin
                        if (is_normaqid)
                            mask = 1;
                        else if (is_entq4id)
                            mask = (facebd_n == `FACEBD_LP);
                        else
                            mask = 0;
                    end
                    5: begin
                        mask = is_normaqid;
                    end
                    6: begin
                         if (is_normaqid)
                            mask = 1;
                        else if (is_entq6id)
                            mask = (cornerbd_ne == `CORNERBD_Y | cornerbd_nw == `CORNERBD_YE);
                        else
                            mask = 0;                       
                    end
                    7: begin
                        mask = is_normaqid;
                    end
                    default: begin
                        mask = 0;
                    end
                endcase
            end
            else if (uc_west & ~uc_south) // RESM-W
            begin
                case (qbidx)
                    0: begin
                        if (facebd_w == `FACEBD_MP | facebd_w == `FACEBD_PP)
                            mask = is_q0allid;
                        else
                            mask = 0;
                    end
                    1: begin
                        if (facebd_w == `FACEBD_MP | facebd_w == `FACEBD_PP)
                            mask = is_q1allid;
                        else if (facebd_w == `FACEBD_X)
                        begin
                            if (reverse)
                                mask = is_q1q567id;
                            else
                                mask = is_q1q456id;
                        end
                        else if (facebd_w == `FACEBD_Z)
                            mask = is_q1q567id;
                        else
                            mask = 0;
                    end
                    2: begin
                        if (facebd_w == `FACEBD_MP | facebd_w == `FACEBD_PP)
                            mask = is_q2allid;
                        else
                            mask = 0;
                    end
                    3: begin
                        if (facebd_w == `FACEBD_MP | facebd_w == `FACEBD_PP)
                            mask = is_q3allid;
                        else if (facebd_w == `FACEBD_X)
                        begin
                            if (reverse)
                                mask = is_q3q567id;
                            else
                                mask = is_q3q456id;
                        end
                        else if (facebd_w == `FACEBD_Z)
                            mask = is_q3q567id;
                        else
                            mask = 0;
                    end
                    4: begin
                        mask = is_normaqid;
                    end
                    5: begin
                        mask = is_normaqid;
                    end
                    6: begin
                        mask = is_normaqid;
                    end
                    7: begin
                        mask = is_normaqid;
                    end
                    default: begin
                        mask = 0;
                    end
                endcase
            end
            else if (uc_east & ~uc_south) // RESM-E
            begin
                case (qbidx)
                    0: begin
                        mask = is_q0allid;
                    end
                    1: begin
                        if (facebd_e == `FACEBD_PP | facebd_e == `FACEBD_MP)
                            mask = is_q1allid;
                        else if (facebd_e == `FACEBD_Z)
                        begin
                            if (reverse)
                                mask = is_q1q457id;
                            else
                                mask = is_q1q467id;
                        end
                        else if (facebd_e == `FACEBD_X)
                            mask = is_q1q457id;
                        else
                            mask = 0;
                    end
                    2: begin
                        mask = is_q2allid;
                    end
                    3: begin
                        if (facebd_e == `FACEBD_PP | facebd_e == `FACEBD_MP)
                            mask = is_q3allid;
                        else if (facebd_e == `FACEBD_Z)
                        begin
                            if (reverse)
                                mask = is_q3q457id;
                            else
                                mask = is_q3q467id;
                        end
                        else if (facebd_e == `FACEBD_X)
                            mask = is_q3q457id;
                        else
                            mask = 0;
                    end
                    4: begin
                        mask = is_normaqid;
                    end
                    5: begin
                        mask = is_normaqid;
                    end
                    6: begin
                        mask = is_normaqid;
                    end
                    7: begin
                        mask = is_normaqid;
                    end
                    default: begin
                        mask = 0;
                    end
                endcase
            end
            else if (uc_south & uc_west) // RESM-SW
            begin
                case (qbidx)
                    0: begin
                        if (facebd_w == `FACEBD_PP | facebd_w == `FACEBD_MP)
                            mask = is_q0allid;
                        else
                            mask = 0;
                    end
                    1: begin
                        if (facebd_w == `FACEBD_PP | facebd_w == `FACEBD_MP)
                            mask = is_q1allid;
                        else if (facebd_w == `FACEBD_X)
                        begin
                            if (reverse)
                                mask = is_q1q567id;
                            else
                                mask = is_q1q456id;
                        end
                        else if (facebd_w == `FACEBD_Z)
                            mask = is_q1q567id;
                        else
                            mask = 0;
                    end
                    2: begin
                        if (facebd_w == `FACEBD_PP)
                            mask = is_q2q467id;
                        else if (facebd_w == `FACEBD_MP)
                            mask = is_q2allid;
                        else
                            mask = 0;
                    end
                    3: begin
                        if (facebd_s == `FACEBD_PP | facebd_s == `FACEBD_LP)
                        begin
                            if (facebd_w == `FACEBD_PP | facebd_w == `FACEBD_MP)
                                mask = is_q3allid;
                            else if (facebd_w == `FACEBD_X)
                            begin
                                if (reverse)
                                    mask = is_q3q567id;
                                else
                                    mask = is_q3q456id;
                            end
                            else if (facebd_w == `FACEBD_Z)
                                mask = is_q3q567id;
                            else
                                mask = 0;
                        end
                        else if (facebd_s == `FACEBD_Z)
                        begin
                            if (facebd_w == `FACEBD_PP)
                                mask = is_q3q467id;
                            else if (facebd_w == `FACEBD_X)
                                mask = is_q3q46id;
                            else
                                mask = 0;
                        end
                        else if (facebd_s == `FACEBD_X)
                            mask = is_q3q56id;
                        else
                            mask = 0;
                    end
                    4: begin
                        mask = is_normaqid;
                    end
                    5: begin
                        if (is_normaqid)
                            mask = 1;
                        else if (is_entq5id)
                            mask = (facebd_s == `FACEBD_LP);
                        else
                            mask = 0;
                    end
                    6: begin
                        mask = is_normaqid;
                    end
                    7: begin
                        if (is_normaqid)
                            mask = 1;
                        else if (is_entq7id)
                            mask = (facebd_s == `FACEBD_LP);
                        else
                            mask = 0;
                    end
                    default: begin
                        mask = 0;
                    end
                endcase
            end
            else if (uc_south & ~uc_east) // RESM-S
            begin
                case (qbidx)
                    0: begin
                        mask = is_q0allid;
                    end
                    1: begin
                        mask = is_q1allid;
                    end
                    2: begin
                        if (facebd_s == `FACEBD_PP | facebd_s == `FACEBD_LP)
                            mask = is_q2allid;
                        else if (facebd_s == `FACEBD_Z)
                            mask = is_q2q467id;
                        else if (facebd_s == `FACEBD_X)
                            mask = is_q2q456id;
                        else
                            mask = 0;
                    end
                    3: begin
                        if (facebd_s == `FACEBD_PP | facebd_s == `FACEBD_LP)
                            mask = is_q3allid;
                        else if (facebd_s == `FACEBD_Z)
                            mask = is_q3q467id;
                        else if (facebd_s == `FACEBD_X)
                            mask = is_q3q456id;
                        else
                            mask = 0;
                    end
                    4: begin
                        mask = is_normaqid;
                    end
                    5: begin
                        if (is_normaqid)
                            mask = 1;
                        else if (is_entq5id)
                            mask = (facebd_s == `FACEBD_LP);
                        else
                            mask = 0;
                    end
                    6: begin
                        mask = is_normaqid;
                    end
                    7: begin
                        if (is_normaqid)
                            mask = 1;
                        else if (is_entq7id)
                            mask = (facebd_s == `FACEBD_LP);
                        else
                            mask = 0;
                    end
                    default: begin
                        mask = 0;
                    end
                endcase
            end
            else if (uc_south) // RESM-SE
            begin
                case (qbidx)
                    0: begin
                        mask = is_q0allid;
                    end
                    1: begin
                        if (facebd_e == `FACEBD_PP | facebd_e == `FACEBD_MP)
                            mask = is_q1allid;
                        else if (facebd_e == `FACEBD_Z)
                        begin
                            if (reverse)
                                mask = is_q1q457id;
                            else
                                mask = is_q1q467id;
                        end
                        else if (facebd_e == `FACEBD_X)
                            mask = is_q1q457id;
                        else
                            mask = 0;
                    end
                    2: begin
                        if (facebd_s == `FACEBD_PP | facebd_s == `FACEBD_LP)
                            mask = is_q2allid;
                        else if(facebd_s == `FACEBD_Z)
                            mask = is_q2q467id;
                        else if (facebd_s == `FACEBD_X)
                            mask = is_q2q456id;
                        else
                            mask = 0;
                    end
                    3: begin
                        if (facebd_e == `FACEBD_MP)
                            mask = is_q3allid;
                        else if (facebd_e == `FACEBD_PP | facebd_s == `FACEBD_PP)
                            mask = is_q3q467id;
                        else if (facebd_e == `FACEBD_Z & facebd_s == `FACEBD_Z)
                            mask = is_q3q467id;
                        else if (facebd_s == `FACEBD_LP)
                        begin
                            if (cornerbd_se == `CORNERBD_Z)
                                mask = is_q3q457id;
                            else
                                mask = is_q3q47id;
                        end
                        else if (facebd_e == `FACEBD_X & facebd_s == `FACEBD_Z)
                            mask = is_q3q47id;
                        else if (facebd_e == `FACEBD_Z & facebd_s == `FACEBD_X)
                            mask = is_q3q46id;
                        else
                            mask = 0;
                    end
                    4: begin
                        mask = is_normaqid;
                    end
                    5: begin
                        if (is_normaqid)
                            mask = 1;
                        else if (is_entq5id)
                        begin
                            if (facebd_e == `FACEBD_MP)
                                mask = 1;
                            else if (facebd_s == `FACEBD_LP & cornerbd_se == `CORNERBD_Z)
                                mask = 1;
                            else
                                mask = 0;
                        end
                        else 
                            mask = 0;
                    end
                    6: begin
                        mask = is_normaqid;
                    end
                    7: begin
                        if (is_normaqid)
                            mask = 1;
                        else if (is_entq7id)
                            mask = (facebd_s == `FACEBD_LP);
                        else
                            mask = 0;
                    end
                    default: begin
                        mask = 0;
                    end
                endcase
            end
            else if (uc_valid) // RESM-C
            begin
                case (qbidx)
                    0: begin
                        mask = is_q0allid;
                    end
                    1: begin
                        mask = is_q1allid;
                    end
                    2: begin
                        mask = is_q2allid;
                    end
                    3: begin
                        mask = is_q3allid;
                    end
                    4: begin
                        mask = is_normaqid;
                    end
                    5: begin
                        mask = is_normaqid;
                    end
                    6: begin
                        mask = is_normaqid;
                    end
                    7: begin
                        mask = is_normaqid;
                    end
                    default: begin
                        mask = 0;
                    end
                endcase
            end
            else // RESM-INVALID UC
            begin
                mask = 0;
            end

            /*** RESM-special ***/
            if (pchtype == `PCHTYPE_ZB)
            begin
                if (is_q1q5id & (uc_north & uc_east) & (qbidx == 1))
                    special = (facebd_e == `FACEBD_PP);
                else
                    special = 0;
            end
            else
                special = 0;
        end

        /*** INVALID_OPCODE ***/
        else
        begin
            mask = 0;
            special = 0;
        end
    end
end


endmodule
