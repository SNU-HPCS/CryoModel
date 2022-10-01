`include "define.v"

module srmem_single_ctrl #(
    parameter NUM_RDPORT = `NUM_PCU,
    parameter LEN_SRMEM = (`NUM_PCH/`NUM_PCU),
    parameter DATA_BW = `PCHINFO_BW
)(
    state,
    hdptr,
    tlptr,
    memptr,
    valid_din,
    din,
    is_lastdin,
    req_pop,
    req_newdata,
    srmem_head,
    next_state,
    next_data,
    shift_en,
    rst_hdptr,
    rst_tlptr,
    rst_memptr,
    up_hdptr,
    up_tlptr,
    up_memptr,
    rst_valid,
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

input [1:0] state;
input [MEMLEN_BW-1:0] hdptr;
input [MEMLEN_BW-1:0] tlptr;
input [RDPORT_BW-1:0] memptr;
input valid_din;
input [DATA_BW-1:0] din;
input is_lastdin;
input req_pop;
input req_newdata;
input [NUM_RDPORT*(DATA_BW+1)-1:0] srmem_head; 
output reg [1:0] next_state;
output reg [NUM_RDPORT*(DATA_BW+1)-1:0] next_data; 
output reg [NUM_RDPORT-1:0] shift_en;
output reg rst_hdptr, rst_tlptr, rst_memptr;
output reg up_hdptr, up_tlptr, up_memptr;
output reg rst_valid;
output reg wrfull;
output reg rdvalid;
output reg wrend;
output reg rdend;
output reg rdnext;
output reg rdlast;


integer I, J, K;
always @(*)
begin
    case (state)
        STATE_FILLING:
        begin
            // next_state
            if (valid_din & is_lastdin)
            begin
                if ((hdptr == LEN_SRMEM-1 & memptr == 0) | hdptr == 0)
                    next_state = STATE_READING;
                else
                    next_state = STATE_MOVING;
            end
            else
                next_state = STATE_FILLING;
            // next_data, shift_en
            for (I = 0; I < NUM_RDPORT; I = I+1)
            begin
                next_data[I*(DATA_BW+1) +: (DATA_BW+1)] = {valid_din, din};
                
                if (I == memptr)
                    shift_en[I] = valid_din;
                else
                    shift_en[I] = 0;
            end
            // rst/up_hdptr
            if (valid_din & memptr == 0)
                up_hdptr = 1;
            else
                up_hdptr = 0;
            rst_hdptr = 0;
            // rst/up_tlptr
            up_tlptr = 0;
            rst_tlptr = 1;
            // rst/up_memptr
            if (valid_din)
                up_memptr = 1;
            else
                up_memptr = 0;
            rst_memptr = 0;
            // rst_valid
            rst_valid = 0;
        end
        STATE_MOVING:
        begin
            // next_state
            if (hdptr == LEN_SRMEM-1)
                next_state = STATE_READING;
            else
                next_state = STATE_MOVING;
            // next_data, shift_en
            next_data = 0;
            for (J = 0; J < NUM_RDPORT; J = J+1)
            begin
                shift_en[J] = 1;
            end
            // rst/up_hdptr
            up_hdptr = 1;
            rst_hdptr = 0;
            // rst/up_tlptr
            up_tlptr = 1;
            rst_tlptr = 0;
            // rst/up_memptr
            up_memptr = 0;
            rst_memptr = 0;
            // rst_valid
            rst_valid = 0;
        end
        STATE_READING:
        begin
            // next_state
            if (tlptr == LEN_SRMEM-1 & req_pop)
            begin
                if (req_newdata)
                    next_state = STATE_FILLING;
                else
                begin
                    if (hdptr == tlptr)
                        next_state = STATE_READING;
                    else
                        next_state = STATE_MOVING;
                end
            end
            else
                next_state = STATE_READING;
            // next_data, shift_en
            for (K = 0; K < NUM_RDPORT; K = K+1)
            begin
                next_data[K*(DATA_BW+1) +: (DATA_BW+1)] = srmem_head[K*(DATA_BW+1) +: (DATA_BW+1)];
                shift_en[K] = req_pop;
            end
            // rst/up_hdptr
            if (next_state == STATE_FILLING)
            begin
                up_hdptr = 0;
                rst_hdptr = 1;
            end
            else
            begin
                up_hdptr = req_pop;
                rst_hdptr = 0;
            end
            // rst/up_tlptr
            up_tlptr = req_pop;
            rst_tlptr = 0;
            // rst/up_memptr
            up_memptr = 0;
            rst_memptr = 1;
            // rst_valid
            rst_valid = (next_state == STATE_FILLING);
        end
        default:
        begin
            // next_state
            next_state = state;
            // next_data
            next_data = 0;
            // shift_en
            shift_en = 0;
            // rst/up_hdptr
            rst_hdptr = 0;
            up_hdptr = 0;
            // rst/up_tlptr
            rst_tlptr = 0;
            up_tlptr = 0;
            // rst/up_memptr
            rst_memptr = 0;
            up_memptr = 0;
            // rst_valid
            rst_valid = 0;
        end
    endcase
    // wrfull
    wrfull = (state != STATE_FILLING);
    // rdvalid
    rdvalid = (state == STATE_READING);
    // wrend
    if (state == STATE_FILLING & next_state != STATE_FILLING)
        wrend = 1;
    else
        wrend = 0;
    // rdend
    if (state == STATE_READING & next_state == STATE_FILLING)
        rdend = 1;
    else
        rdend = 0;
    // rdnext
    if (next_state == STATE_READING)
        rdnext = 1;
    else
        rdnext = 0;
    // rdlast
    if (state == STATE_READING & tlptr == LEN_SRMEM-1 & req_pop)
        rdlast = 1;
    else
        rdlast = 0;
end


endmodule
