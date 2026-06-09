`timescale 1ns / 1ps

module viterbi_k7 #

(
    parameter SEQ_LEN  = 256,
    parameter TB_LEN   = 40,
    parameter METRIC_W = 8
)
(
    //////////////////////////////////////////////////
    // CHIP IO PADS
    //////////////////////////////////////////////////

    input  clk_pad,
    input  rst_n_pad,
    input  start_pad,

    input  rx_valid_pad,
    input  rx_bit0_pad,
    input  rx_bit1_pad,

    output ready_pad,
    output out_valid_pad,
    output out_bit_pad
);

////////////////////////////////////////////////////
// INTERNAL SIGNALS
////////////////////////////////////////////////////

wire clk;
wire rst_n;
wire start;

wire rx_valid;
wire rx_bit0;
wire rx_bit1;

reg ready;
reg out_valid;
reg out_bit;

////////////////////////////////////////////////////
// INPUT PAD INSTANTIATION
////////////////////////////////////////////////////

pc3i05 u_pad_clk
(
    .PAD(clk_pad),
    .Y(clk)
);

pc3i05 u_pad_rst
(
    .PAD(rst_n_pad),
    .Y(rst_n)
);

pc3i05 u_pad_start
(
    .PAD(start_pad),
    .Y(start)
);

pc3i05 u_pad_rxvalid
(
    .PAD(rx_valid_pad),
    .Y(rx_valid)
);

pc3i05 u_pad_rx0
(
    .PAD(rx_bit0_pad),
    .Y(rx_bit0)
);

pc3i05 u_pad_rx1
(
    .PAD(rx_bit1_pad),
    .Y(rx_bit1)
);

////////////////////////////////////////////////////
// VITERBI DECODER CORE
////////////////////////////////////////////////////

localparam N_STATES = 64;

////////////////////////////////////////////////////
// PATH METRICS
////////////////////////////////////////////////////

reg [METRIC_W-1:0] path_metric [0:N_STATES-1];
reg [METRIC_W-1:0] path_metric_nxt [0:N_STATES-1];

////////////////////////////////////////////////////
// BACKPOINTER MEMORY
////////////////////////////////////////////////////

reg [5:0] backptr [0:SEQ_LEN-1][0:N_STATES-1];

////////////////////////////////////////////////////
// CONTROL
////////////////////////////////////////////////////

reg [15:0] symbol_cnt;
reg [15:0] tb_index;

reg decoding;
reg traceback;

reg [5:0] current_state;

integer i;

////////////////////////////////////////////////////
// ENCODER MODEL (171,133)
////////////////////////////////////////////////////

function [1:0] enc;

    input bit_in;
    input [5:0] state;

    reg [6:0] shift;

    begin

        shift = {bit_in, state};

        // G1 = 171(octal)
        enc[1] =
            shift[6] ^
            shift[5] ^
            shift[4] ^
            shift[3] ^
            shift[0];

        // G2 = 133(octal)
        enc[0] =
            shift[6] ^
            shift[4] ^
            shift[3] ^
            shift[1] ^
            shift[0];

    end

endfunction

////////////////////////////////////////////////////
// TEMP VARIABLES
////////////////////////////////////////////////////

reg [1:0] exp;
reg [METRIC_W-1:0] br_metric;
reg [5:0] next_state;

////////////////////////////////////////////////////
// MAIN LOGIC
////////////////////////////////////////////////////

always @(posedge clk or negedge rst_n)
begin

    if (!rst_n)
    begin

        ready         <= 1'b1;
        decoding      <= 1'b0;
        traceback     <= 1'b0;

        out_valid     <= 1'b0;
        out_bit       <= 1'b0;

        symbol_cnt    <= 0;
        tb_index      <= 0;

        current_state <= 0;

        for (i=0; i<N_STATES; i=i+1)
            path_metric[i] <= 8'h7F;

        path_metric[0] <= 0;

    end

    else
    begin

        out_valid <= 1'b0;

        ////////////////////////////////////////////////
        // START
        ////////////////////////////////////////////////

        if (start && ready)
        begin

            ready        <= 1'b0;
            decoding     <= 1'b1;
            traceback    <= 1'b0;

            symbol_cnt   <= 0;

            for (i=0; i<N_STATES; i=i+1)
                path_metric[i] <= 8'h7F;

            path_metric[0] <= 0;

        end

        ////////////////////////////////////////////////
        // ACS OPERATION
        ////////////////////////////////////////////////

        else if (decoding && rx_valid)
        begin

            for (i=0; i<N_STATES; i=i+1)
                path_metric_nxt[i] = 8'h7F;

            for (i=0; i<N_STATES; i=i+1)
            begin

                ////////////////////////////////////////
                // INPUT = 0
                ////////////////////////////////////////

                exp = enc(0, i);

                br_metric =
                    (exp[1] ^ rx_bit1) +
                    (exp[0] ^ rx_bit0);

                next_state = {1'b0, i[5:1]};

                if ((path_metric[i] + br_metric)
                    < path_metric_nxt[next_state])
                begin

                    path_metric_nxt[next_state]
                        = path_metric[i] + br_metric;

                    backptr[symbol_cnt][next_state]
                        <= i;

                end

                ////////////////////////////////////////
                // INPUT = 1
                ////////////////////////////////////////

                exp = enc(1, i);

                br_metric =
                    (exp[1] ^ rx_bit1) +
                    (exp[0] ^ rx_bit0);

                next_state = {1'b1, i[5:1]};

                if ((path_metric[i] + br_metric)
                    < path_metric_nxt[next_state])
                begin

                    path_metric_nxt[next_state]
                        = path_metric[i] + br_metric;

                    backptr[symbol_cnt][next_state]
                        <= i;

                end

            end

            ////////////////////////////////////////////
            // UPDATE METRICS
            ////////////////////////////////////////////

            for (i=0; i<N_STATES; i=i+1)
                path_metric[i] <= path_metric_nxt[i];

            symbol_cnt <= symbol_cnt + 1;

            ////////////////////////////////////////////
            // START TRACEBACK
            ////////////////////////////////////////////

            if (symbol_cnt == SEQ_LEN-1)
            begin

                decoding  <= 1'b0;
                traceback <= 1'b1;

                tb_index <= SEQ_LEN-1;

                current_state <= 0;

                for (i=1; i<N_STATES; i=i+1)
                begin
                    if (path_metric[i]
                        < path_metric[current_state])
                    begin
                        current_state <= i;
                    end
                end

                $display("TRACEBACK STARTED");

            end

        end

        ////////////////////////////////////////////////
        // TRACEBACK
        ////////////////////////////////////////////////

        else if (traceback)
        begin

            out_bit   <= current_state[5];
            out_valid <= 1'b1;

            current_state
                <= backptr[tb_index][current_state];

            if (tb_index == 0)
            begin

                traceback <= 1'b0;
                ready     <= 1'b1;

            end

            else
            begin

                tb_index <= tb_index - 1;

            end

        end

    end

end

////////////////////////////////////////////////////
// OUTPUT PAD INSTANTIATION
////////////////////////////////////////////////////

pc3o05 u_pad_ready
(
    .I(ready),
    .PAD(ready_pad)
);

pc3o05 u_pad_outvalid
(
    .I(out_valid),
    .PAD(out_valid_pad)
);

pc3o05 u_pad_outbit
(
    .I(out_bit),
    .PAD(out_bit_pad)
);

endmodule
