`include "define.v"

module psu_maskext(
    pchidx_list,
    pivalid_list,
    uc_counter, 
    qb_counter,
    mask_array,
    special_array,
    mask_ext_array,
    special_ext_array
);


input [`NUM_PCU*`PCHADDR_BW-1:0] pchidx_list;
input [`NUM_PCU*(1)-1:0] pivalid_list;
input [`NUM_UCC*`UCADDR_BW-1:0] uc_counter;
input [`NUM_QBCTRL*`QBADDR_BW-1:0] qb_counter;
input [`NUM_MASK-1:0] mask_array;
input [`NUM_MASK-1:0] special_array;
output reg [`NUM_PQ-1:0] mask_ext_array;
output reg [`NUM_PQ-1:0] special_ext_array;

wire [`NUM_PCHDMX_OUT*`NUM_PCUQB-1:0] temp_mask_pchext_array [`NUM_PCU-1:0];
reg [`NUM_PCUQB-1:0] mask_pchext_array [`NUM_PCH-1:0];
wire [`NUM_PCHDMX_OUT*`NUM_PCUQB-1:0] temp_special_pchext_array [`NUM_PCU-1:0];
reg [`NUM_PCUQB-1:0] special_pchext_array [`NUM_PCH-1:0];
//
wire [`NUM_UCDMX_OUT*`NUM_UCCQB-1:0] temp_mask_ucext_array[`NUM_PCH-1:0][`NUM_UCC-1:0];
reg [`NUM_UCCQB-1:0] mask_ucext_array [`NUM_PCH-1:0][`NUM_UC-1:0];
wire [`NUM_UCDMX_OUT*`NUM_UCCQB-1:0] temp_special_ucext_array[`NUM_PCH-1:0][`NUM_UCC-1:0];
reg [`NUM_UCCQB-1:0] special_ucext_array [`NUM_PCH-1:0][`NUM_UC-1:0];
//
wire [`NUM_QBDMX_OUT-1:0] temp_mask_qbext_array[`NUM_PCH-1:0][`NUM_UC-1:0][`NUM_QBCTRL-1:0];
wire [`NUM_QBDMX_OUT-1:0] temp_special_qbext_array[`NUM_PCH-1:0][`NUM_UC-1:0][`NUM_QBCTRL-1:0];
//reg mask_qbext_array [`NUM_PCH-1:0][`NUM_UC-1:0][`NUM_QB-1:0];
//
reg [`log2(`NUM_PCHDMX_OUT)-1:0] pchsel [`NUM_PCU-1:0];
reg [`log2(`NUM_PCU)-1:0] pcusel [`NUM_PCU-1:0];
reg [`log2(`NUM_UCDMX_OUT)-1:0] ucsel [`NUM_UCC-1:0];
reg [`log2(`NUM_QBDMX_OUT)-1:0] qbsel [`NUM_QBCTRL-1:0];

integer I1, I2, J1, J2, J3, K1, K2, K3, K4;
integer PCUID, PCHID, UCCID, UCID, QBCID, QBID;
always @(*)
begin
    for (I1 = 0; I1 < `NUM_PCU; I1 = I1+1) begin
        pchsel[I1] = (pchidx_list[I1*`PCHADDR_BW +: `PCHADDR_BW] / `NUM_PCU);
        pcusel[I1] = (pchidx_list[I1*`PCHADDR_BW +: `PCHADDR_BW] % `NUM_PCU);
    end
    for (J1 = 0; J1 < `NUM_UCC; J1 = J1+1)
        ucsel[J1] = (uc_counter[J1*`UCADDR_BW +: `UCADDR_BW] / `NUM_UCC);
    for (K1 = 0; K1 < `NUM_QBCTRL; K1 = K1+1)
        qbsel[K1] = (qb_counter[K1*`QBADDR_BW +: `QBADDR_BW] / `NUM_QBCTRL);

    for (I2 = 0; I2 < `NUM_PCH; I2 = I2+1)
    begin
        mask_pchext_array[I2] = 0;
        special_pchext_array[I2] = 0;
    end
    for (I2 = 0; I2 < `NUM_PCH; I2 = I2+1)
    begin
        PCUID = I2 % `NUM_PCU;
        PCHID = I2 / `NUM_PCU;
        if (pivalid_list[PCUID]) begin
            mask_pchext_array[pcusel[PCUID] + PCHID*`NUM_PCU] = temp_mask_pchext_array[PCUID][PCHID*`NUM_PCUQB +: `NUM_PCUQB];
            special_pchext_array[pcusel[PCUID] + PCHID*`NUM_PCU] = temp_special_pchext_array[PCUID][PCHID*`NUM_PCUQB +: `NUM_PCUQB];
        end
    end

    for (J2 = 0; J2 < `NUM_PCH; J2 = J2+1)
    begin
        for (J3 = 0; J3 < `NUM_UC; J3 = J3+1)
        begin
            UCCID = J3 % `NUM_UCC;
            UCID = J3 / `NUM_UCC;
            mask_ucext_array[J2][J3] = temp_mask_ucext_array[J2][UCCID][UCID*`NUM_UCCQB +: `NUM_UCCQB];
            special_ucext_array[J2][J3] = temp_special_ucext_array[J2][UCCID][UCID*`NUM_UCCQB +: `NUM_UCCQB];
        end
    end

    for (K2 = 0; K2 < `NUM_PCH; K2 = K2+1)
    begin
        for (K3 = 0; K3 < `NUM_UC; K3 = K3+1)
        begin
            for (K4 = 0; K4 < `NUM_QB; K4 = K4+1)
            begin
                QBCID = K4 % `NUM_QBCTRL;
                QBID = K4 / `NUM_QBCTRL;
                mask_ext_array[K2*(`NUM_UC*`NUM_QB) + K3*(`NUM_QB) + K4] = temp_mask_qbext_array[K2][K3][QBCID][QBID];
                special_ext_array[K2*(`NUM_UC*`NUM_QB) + K3*(`NUM_QB) + K4] = temp_special_qbext_array[K2][K3][QBCID][QBID];
            end
        end
    end
end


genvar ip;
generate
    if (`NUM_PCHDMX_OUT == 1)
    begin
        for (ip = 0; ip < `NUM_PCU; ip = ip+1)
        begin
            assign temp_mask_pchext_array[ip] = mask_array[ip*`NUM_PCUQB +: `NUM_PCUQB];
            assign temp_special_pchext_array[ip] = special_array[ip*`NUM_PCUQB +: `NUM_PCUQB];
        end
    end
    else
    begin
        for (ip = 0; ip < `NUM_PCU; ip = ip+1)
        begin: gen_pchdemux
            demux #(
                .NUM_DATA(`NUM_PCHDMX_OUT),
                .DATA_BW(`NUM_PCUQB)
            ) UUT0_ip(
                .data_in(mask_array[ip*`NUM_PCUQB +: `NUM_PCUQB]),
                .sel(pchsel[ip]),
                .data_out(temp_mask_pchext_array[ip])
            );
            demux #(
                .NUM_DATA(`NUM_PCHDMX_OUT),
                .DATA_BW(`NUM_PCUQB)
            ) UUT1_ip(
                .data_in(special_array[ip*`NUM_PCUQB +: `NUM_PCUQB]),
                .sel(pchsel[ip]),
                .data_out(temp_special_pchext_array[ip])
            );
        end
    end
endgenerate


genvar iu, ju;
generate
    if (`NUM_UCDMX_OUT == 1)
    begin
        for (iu = 0; iu < `NUM_PCH; iu = iu+1)
        begin
            for (ju = 0; ju < `NUM_UCC; ju = ju+1)
            begin
                assign temp_mask_ucext_array[iu][ju] = mask_pchext_array[iu][ju*`NUM_UCCQB +: `NUM_UCCQB];
                assign temp_special_ucext_array[iu][ju] = special_pchext_array[iu][ju*`NUM_UCCQB +: `NUM_UCCQB];
            end
        end
    end
    else
    begin
        for (iu = 0; iu < `NUM_PCH; iu = iu+1)
        begin
            for (ju = 0; ju < `NUM_UCC; ju = ju+1)
            begin
                demux #(
                    .NUM_DATA(`NUM_UCDMX_OUT),
                    .DATA_BW(`NUM_UCCQB)
                ) UUT2_iu_ju(
                    .data_in(mask_pchext_array[iu][ju*`NUM_UCCQB +: `NUM_UCCQB]),
                    .sel(ucsel[ju]),
                    .data_out(temp_mask_ucext_array[iu][ju])
                );
                demux #(
                    .NUM_DATA(`NUM_UCDMX_OUT),
                    .DATA_BW(`NUM_UCCQB)
                ) UUT3_iu_ju(
                    .data_in(special_pchext_array[iu][ju*`NUM_UCCQB +: `NUM_UCCQB]),
                    .sel(ucsel[ju]),
                    .data_out(temp_special_ucext_array[iu][ju])
                );
            end
        end
    end
endgenerate


genvar iq, jq, kq;
generate
    if (`NUM_QBDMX_OUT == 1)
    begin
        for (iq = 0; iq < `NUM_PCH; iq = iq+1)
        begin
            for (jq = 0; jq < `NUM_UC; jq = jq+1)
            begin
                for (kq = 0; kq < `NUM_QBCTRL; kq = kq+1)
                begin
                    assign temp_mask_qbext_array[iq][jq][kq] = mask_ucext_array[iq][jq][kq*`NUM_QBCTRL +: `NUM_QBCTRL]; 
                    assign temp_special_qbext_array[iq][jq][kq] = special_ucext_array[iq][jq][kq*`NUM_QBCTRL +: `NUM_QBCTRL]; 
                end
            end
        end
    end
    else
    begin
        for (iq = 0; iq < `NUM_PCH; iq = iq+1)
        begin
            for (jq = 0; jq < `NUM_UC; jq = jq+1)
            begin
                for (kq = 0; kq < `NUM_QBCTRL; kq = kq+1)
                begin
                    demux #(
                        .NUM_DATA(`NUM_QBDMX_OUT),
                        .DATA_BW(1)
                    ) UUT4_iq_jq_kq(
                        .data_in(mask_ucext_array[iq][jq][kq]),
                        .sel(qbsel[kq]),
                        .data_out(temp_mask_qbext_array[iq][jq][kq])
                    );
                    demux #(
                        .NUM_DATA(`NUM_QBDMX_OUT),
                        .DATA_BW(1)
                    ) UUT5_iq_jq_kq(
                        .data_in(special_ucext_array[iq][jq][kq]),
                        .sel(qbsel[kq]),
                        .data_out(temp_special_qbext_array[iq][jq][kq])
                    );
                end
            end
        end
    end
endgenerate

endmodule
