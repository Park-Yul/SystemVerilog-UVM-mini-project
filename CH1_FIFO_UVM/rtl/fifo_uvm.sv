`timescale 1ns / 1ps
module fifo_uvm #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8,
    parameter ADDR_DEPTH = 2 ** ADDR_WIDTH
) (
    input                         i_clk,
    input                         i_rst_n,
    input                         i_push,
    input                         i_pop,
    input   [DATA_WIDTH - 1 : 0]  i_wdata,
    output  [DATA_WIDTH - 1 : 0]  o_rdata,
    output                        o_full,
    output                        o_empty
);

    // logic declaration
    wire                      w_full, w_we;
    wire [ADDR_WIDTH - 1 : 0] w_wptr, w_rptr;

    // assignment
    assign w_we = (~w_full) & i_push;
    assign o_full = w_full;

    // register_file instantiation
    register_file #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) U_REGISTER_FILE (
        .i_clk  (i_clk),
        .i_wdata(i_wdata),
        .i_waddr(w_wptr),
        .i_raddr(w_rptr),
        .i_we   (w_we),
        .o_rdata(o_rdata)
    );

    // control_unit instantiation
    control_unit #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) U_CONTROL_UNIT (
        .i_clk  (i_clk),
        .i_rst_n(i_rst_n),
        .i_push (i_push),
        .i_pop  (i_pop),
        .o_wptr (w_wptr),
        .o_rptr (w_rptr),
        .o_empty(o_empty),
        .o_full (w_full)
    );

endmodule

module register_file #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8,
    parameter ADDR_DEPTH = 2 ** ADDR_WIDTH
) (
    input  logic                        i_clk,
    input  logic   [DATA_WIDTH - 1 : 0] i_wdata,
    input  logic   [ADDR_WIDTH - 1 : 0] i_waddr,
    input  logic   [ADDR_WIDTH - 1 : 0] i_raddr,
    input  logic                        i_we,
    output logic   [DATA_WIDTH - 1 : 0] o_rdata
);

    // ram declaration
    logic  [DATA_WIDTH - 1:0] register_file[0:ADDR_DEPTH - 1]; // 256B

    // SL
    always @(posedge i_clk) begin
        if (i_we) begin
            register_file[i_waddr] <= i_wdata;
        end
    end

    // CL
    assign o_rdata = register_file[i_raddr];
endmodule

//////////

module control_unit #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8,
    parameter ADDR_DEPTH = 2 ** ADDR_WIDTH
) (
    input  logic                   i_clk,
    input  logic                   i_rst_n,
    input  logic                   i_push,
    input  logic                   i_pop,
    output logic [ADDR_WIDTH -1:0] o_wptr,
    output logic [ADDR_WIDTH -1:0] o_rptr,
    output logic                   o_empty,
    output logic                   o_full
);
    // logic declaration
    logic [ADDR_WIDTH-1 : 0]  wptr_next, wptr_reg;
    logic [ADDR_WIDTH-1 : 0]  rptr_next, rptr_reg;
    logic                     empty_next, empty_reg;
    logic                     full_next, full_reg;

    // CL
    assign o_wptr   = wptr_reg;
    assign o_rptr   = rptr_reg;
    assign o_empty  = empty_reg;
    assign o_full   = full_reg;

    // CL
    always @(*) begin
        wptr_next  = wptr_reg;
        rptr_next  = rptr_reg;
        empty_next = empty_reg;
        full_next  = full_reg;
        case ({
            i_push, i_pop
        })
            2'b00: ;  // init ;
            2'b10: begin  // push only
                if (!full_reg) begin
                    empty_next = 0;
                    wptr_next  = wptr_reg + 1;
                    if (rptr_reg == wptr_next) full_next = 1;
                end
            end
            2'b01: begin  // pop only
                if (!empty_reg) begin
                    full_next = 0;
                    rptr_next = rptr_reg + 1;
                    if (wptr_reg == rptr_next) empty_next = 1;
                end
            end
            2'b11: begin  // push & pop
                if (empty_reg) begin
                    empty_next = 0;
                    wptr_next  = wptr_reg + 1;
                end else if (full_reg) begin
                    full_next = 0;
                    rptr_next = rptr_reg + 1;
                end else begin
                    wptr_next = wptr_reg + 1;
                    rptr_next = rptr_reg + 1;
                end
            end
        endcase
    end

    // SL
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            wptr_reg  <= 0;
            rptr_reg  <= 0;
            empty_reg <= 1;
            full_reg  <= 0;
        end else begin
            wptr_reg  <= wptr_next;
            rptr_reg  <= rptr_next;
            empty_reg <= empty_next;
            full_reg  <= full_next;
        end
    end


endmodule

