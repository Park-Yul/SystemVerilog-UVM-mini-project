`include "uvm_macros.svh"
import uvm_pkg::*;

//---------------------
// 0. interface
interface fifo_if (
    input i_clk
);
    // port
    logic               i_rst_n;
    logic               i_push;
    logic               i_pop;
    logic   [7 : 0]     i_wdata;
    logic   [7 : 0]     o_rdata;
    logic               o_full;
    logic               o_empty;

    // clocking

    // modport

    // property
    property p_rst_fifo;
      @(posedge i_clk) (!i_rst_n) |=> (o_full ==  1'b0) and (o_empty == 1'b1);
    endproperty

    // assertion
    A_RST_FIFO : assert property(p_rst_fifo)
      else `uvm_error("ERROR","\n RESET_ASSERT property p_rst_fifo! \n")
endinterface
//---------------------


//---------------------
// 1. sequence_item
class fifo_seq_item extends uvm_sequence_item;
  // item
  rand  bit               i_rst_n;
  rand  bit               i_push;
  rand  bit               i_pop;
  rand  bit     [7:0]     i_wdata;
        logic   [7:0]     o_rdata;
        logic             o_full;
        logic             o_empty;

  // constraint
  constraint c_rst_n      {i_rst_n    == 1'b1;}
  constraint c_push       {i_push     dist {0:=5, 1:=5};}
  constraint c_pop        {i_pop      dist {0:=5, 1:=5};}

    // counstructor
    function new(string name = "FIFO_SEQUENCE_ITEM");
        super.new(name);
    endfunction

  // uvm factory registry
  `uvm_object_utils_begin(fifo_seq_item)
  `uvm_field_int(i_rst_n,   UVM_DEFAULT)
  `uvm_field_int(i_push,    UVM_DEFAULT)
  `uvm_field_int(i_pop,     UVM_DEFAULT)
  `uvm_field_int(i_wdata,   UVM_DEFAULT)
  `uvm_field_int(o_rdata,   UVM_DEFAULT)
  `uvm_field_int(o_full,    UVM_DEFAULT)
  `uvm_field_int(o_empty,   UVM_DEFAULT)
  `uvm_object_utils_end

    // function 'conver2string'
    virtual function string convert2string();
        return $sformatf("\n i_rst_n = %b, i_push = %b, i_pop = %b, i_wdata =  %h, o_rdata = %h, o_full = %b, o_empty = %b \n", i_rst_n, i_push, i_pop, i_wdata, o_rdata, o_full, o_empty);
    endfunction

endclass
//--------------------


//---------------------
// 2-1. sequence_reset
class fifo_sequence_reset extends uvm_sequence #(fifo_seq_item);
    // uvm factory registry
    `uvm_object_utils(fifo_sequence_reset)

    // handle declaration
    fifo_seq_item u_item;

    // constructor
    function new(string name = "FIFO_SEQUENCE_RESET");
        super.new(name);
    endfunction

    // task 'body'
    virtual task body();
        repeat(3) begin
            u_item =fifo_seq_item::type_id::create("ITEM");
            start_item(u_item);
            u_item.i_rst_n      = 1'b0;
            u_item.i_push       = 1'b0;
            u_item.i_pop        = 1'b0;
            u_item.i_wdata      = 32'd0;
            finish_item(u_item);
            `uvm_info(get_name(), u_item.convert2string(), UVM_HIGH)
        end
    endtask

endclass
//---------------------


//---------------------
// 2-2. sequence_random
class fifo_sequence_random extends uvm_sequence #(fifo_seq_item);
    // uvm factory registry
    `uvm_object_utils(fifo_sequence_random)

    // handle declaration
    fifo_seq_item u_item;

    // constructor
    function new(string name = "FIFO_SEQUENCE_RANDOM");
        super.new(name);
    endfunction

    // task 'body'
    virtual task body();
        repeat(10) begin
            u_item = fifo_seq_item::type_id::create("ITEM");
            start_item(u_item);
             if(!u_item.randomize()) begin
               `uvm_fatal(get_name(), "u_item randomized fail");
             end
            finish_item(u_item);
            `uvm_info(get_name(), u_item.convert2string(), UVM_HIGH)
        end
    endtask

endclass
//---------------------


//---------------------
// 3. driver
class fifo_driver extends uvm_driver #(fifo_seq_item);
    // uvm factory registry
    `uvm_component_utils(fifo_driver)

    // handle declaration
    fifo_seq_item   u_item;

    // virtual interface declaration
    virtual fifo_if u_if;

    // constructor
    function new(string name = "FIFO_DRIVER", uvm_component c = null);
        super.new(name, c);
    endfunction

    // function 'build_phase'
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual fifo_if)::get(this, "", "u_if", u_if)) begin
            `uvm_fatal(get_name(), "\n build phase : can't access virtual interface \n")
        end
    endfunction

    // task 'run_phase'
    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);
        forever begin
            seq_item_port.get_next_item(u_item);
            @(posedge u_if.i_clk) #2;
            u_if.i_rst_n    <= u_item.i_rst_n;
            u_if.i_push     <= u_item.i_push;
            u_if.i_pop      <= u_item.i_pop;
            u_if.i_wdata    <= u_item.i_wdata;
            seq_item_port.item_done();
            `uvm_info(get_name(), u_item.convert2string(), UVM_HIGH)
        end
    endtask

endclass
//---------------------


//---------------------
// 4. monitor
class fifo_monitor extends uvm_monitor;
    // uvm factory registry
    `uvm_component_utils (fifo_monitor)

    // handle declaration
    fifo_seq_item u_item;
    uvm_analysis_port #(fifo_seq_item) send;

    // virtual interface declaration
    virtual fifo_if u_if;

    // constructor
    function new(string name = "FIFO_MONITOR", uvm_component c = null);
        super.new(name, c);
        send = new("WRITE", this);
    endfunction

    // function 'build_phase'
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual fifo_if)::get(this, "", "u_if", u_if)) begin
            `uvm_fatal(get_name(), "\n build phase : can't access virtual interface \n")
        end
    endfunction

    // task 'run_phase'
    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);
        forever begin
            u_item = fifo_seq_item::type_id::create("ITEM");
            @ (posedge u_if.i_clk) #1;
            u_item.i_rst_n      = u_if.i_rst_n;
            u_item.i_push       = u_if.i_push;
            u_item.i_pop        = u_if.i_pop;
            u_item.i_wdata      = u_if.i_wdata;
            u_item.o_rdata      = u_if.o_rdata;
            u_item.o_full       = u_if.o_full;
            u_item.o_empty      = u_if.o_empty;
            `uvm_info(get_name(), u_item.convert2string(), UVM_HIGH)
            send.write(u_item);
        end
    endtask
endclass
//---------------------


//---------------------
// 5. agent
class fifo_agent extends uvm_agent;
    // uvm factory registry
    `uvm_component_utils(fifo_agent)

    // handle declaration
    uvm_sequencer #(fifo_seq_item) u_sqr;
    fifo_driver                    u_drv;
    fifo_monitor                   u_mon;

    // constructor
    function new(string name = "FIFO_AGENT", uvm_component c = null);
        super.new(name, c);
    endfunction

    // function 'build_phase'
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        u_sqr = uvm_sequencer#(fifo_seq_item)::type_id::create("SQR", this);
        u_drv = fifo_driver::type_id::create("DRV", this);
        u_mon = fifo_monitor::type_id::create("MON", this);
    endfunction

    // function 'connect_phase'
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        u_drv.seq_item_port.connect(u_sqr.seq_item_export);   // driver : caller |  sequencer : callee
    endfunction

endclass
//---------------------


//---------------------
// 6. scoreboard
class fifo_scoreboard extends uvm_scoreboard;
    // uvm factory registry
    `uvm_component_utils(fifo_scoreboard)

    // handle declaration
    uvm_analysis_imp #(fifo_seq_item, fifo_scoreboard) recv;

    // value declaration for scoring-
    logic   [7:0]     compare_buffer[0:255];
    bit     [7:0]     expected_rdata    = 8'b0;
    bit               expected_full     = 1'b0;
    bit               expected_empty    = 1'b1;
    bit     [7:0]     push_cnt          = 8'b0;
    bit     [7:0]     pop_cnt           = 8'b0;
    int               pop_total_cnt     = 0;
    int               pop_pass_cnt      = 0;
    int               pop_fail_cnt      = 0;
    int               full_total_cnt    = 0;
    int               full_pass_cnt     = 0;
    int               full_fail_cnt     = 0;
    int               empty_total_cnt   = 0;
    int               empty_pass_cnt    = 0;
    int               empty_fail_cnt    = 0;
    int               skip_cnt          = 0;

    // constructor
    function new(string name = "FIFO_SCOREBOARD", uvm_component c = null);
        super.new(name, c);
        recv = new("READ", this);
    endfunction

    // function 'write'
    virtual function void write(fifo_seq_item u_item);
    `uvm_info(get_name(), u_item.convert2string(), UVM_HIGH)
    if((u_item.o_full === 1'bx) | (u_item.o_empty === 1'bx)) begin
      `uvm_info(get_name(), $sformatf("\n To skip : o_full or o_empty is x \n"), UVM_NONE)
      skip_cnt++;
    end
    else begin
        if (!u_item.i_rst_n)begin
            expected_full       = 0;
            expected_empty      = 1;
            push_cnt            = 0;
            pop_cnt             = 0;
        end
        else begin
            if({u_item.i_push, u_item.i_pop} == 2'b10) begin
                if(!expected_full) begin
                    expected_empty = 0;
                    compare_buffer[push_cnt] = u_item.i_wdata;
                    push_cnt++;
                    if(pop_cnt == push_cnt) expected_full = 1;
                end
             end
             else if({u_item.i_push, u_item.i_pop} == 2'b01) begin
                if(!expected_empty) begin
                    expected_full = 0;
                    pop_cnt++;
                    if(push_cnt == pop_cnt) expected_empty = 1;
                    if(compare_buffer[pop_cnt] === u_item.o_rdata) begin
                        `uvm_info(get_name(), $sformatf("\n PASS POP!! \n expected_rdata = %h | o_rdata = %h", compare_buffer[pop_cnt], u_item.o_rdata), UVM_HIGH);
                        pop_total_cnt++;
                        pop_pass_cnt++;
                    end
                    else begin
                        `uvm_error(get_name(), $sformatf("\n FAIL POP!! \n expected_rdata = %h | o_rdata = %h", compare_buffer[pop_cnt], u_item.o_rdata));
                        pop_total_cnt++;
                        pop_fail_cnt++;
                   end
                end
             end
             else if({u_item.i_push, u_item.i_pop} == 2'b11) begin
                if(expected_empty) begin
                    expected_empty = 0;
                    compare_buffer[push_cnt] = u_item.i_wdata;
                    push_cnt++;
                end
                else if(expected_full) begin
                    expected_full =0 ;
                    pop_cnt++;
                    if(compare_buffer[pop_cnt] === u_item.o_rdata) begin
                        `uvm_info(get_name(), $sformatf("\n PASS POP!! \n expected_rdata = %h | o_rdata = %h", compare_buffer[pop_cnt], u_item.o_rdata), UVM_HIGH);
                        pop_total_cnt++;
                        pop_pass_cnt++;
                    end
                    else begin
                        `uvm_error(get_name(), $sformatf("\n FAIL POP!! \n expected_rdata = %h | o_rdata = %h", compare_buffer[pop_cnt], u_item.o_rdata));
                        pop_total_cnt++;
                        pop_fail_cnt++;
                   end
                end
                else begin
                  compare_buffer[push_cnt] = u_item.i_wdata;
                  push_cnt++;
                  pop_cnt++;
                  if(compare_buffer[pop_cnt] === u_item.o_rdata) begin
                      `uvm_info(get_name(), $sformatf("\n PASS POP!! \n expected_rdata = %h | o_rdata = %h", compare_buffer[pop_cnt], u_item.o_rdata), UVM_HIGH);
                      pop_total_cnt++;
                      pop_pass_cnt++;
                  end
                  else begin
                       `uvm_error(get_name(), $sformatf("\n FAIL POP!! \n expected_rdata = %h | o_rdata = %h", compare_buffer[pop_cnt], u_item.o_rdata));
                       pop_total_cnt++;
                       pop_fail_cnt++;
                  end
                end
              end
            end
            if(expected_full == u_item.o_full) begin
                    `uvm_info(get_name(), $sformatf("\n PASS FULL!! \n expected_full = %b, o_full = %b", expected_full, u_item.o_full), UVM_HIGH)
                    full_total_cnt++;
                    full_pass_cnt++;
            end
            else begin
                    `uvm_error(get_name(), $sformatf("\n FAIL FULL!! \n expected_full = %b, o_full = %b", expected_full, u_item.o_full))
                    full_total_cnt++;
                    full_fail_cnt++;
            end
            if(expected_empty == u_item.o_empty) begin
                    `uvm_info(get_name(), $sformatf("\n PASS EMPTY!! \n expected_empty = %b, o_empty = %b", expected_empty, u_item.o_empty), UVM_HIGH)
                    empty_total_cnt++;
                    empty_pass_cnt++;
            end
            else begin                                              
                    `uvm_error(get_name(), $sformatf("\n FAIL EMPTY!! \n expected_empty = %b, o_empty = %b", expected_empty, u_item.o_empty))
                    empty_total_cnt++;
                    empty_fail_cnt++;
            end
         end
    endfunction

    // function 'report_phase'
    virtual function void report_phase(uvm_phase phase);
        `uvm_info(get_name(), $sformatf("\n ***** Scoreboard Report *****"), UVM_NONE)
        `uvm_info(get_name(), $sformatf("\n === POP TOTAL       : %d === \n === POP PASS       : %d === \n === POP FAIL        : %d === \n === FULL TOTAL       : %d === \n === FULL PASS       : %d === \n === FULL FAIL       : %d ===  \n === EMPTY_TOTAL       : %d === \n === EMPTY_PASS       : %d === \n === EMPTY FAIL       : %d === \n === SKIP      : %d ===", pop_total_cnt, pop_pass_cnt, pop_fail_cnt, full_total_cnt, full_pass_cnt,  full_fail_cnt, empty_total_cnt, empty_pass_cnt,  empty_fail_cnt, skip_cnt), UVM_NONE)
        `uvm_info(get_name(), $sformatf("\n***************************\n"), UVM_NONE)
    endfunction

endclass
//---------------------


//--------------------
// 7. coverage
class fifo_coverage extends uvm_subscriber #(fifo_seq_item);
    // uvm factory registry
    `uvm_component_utils(fifo_coverage)

    // handle declaration
    fifo_seq_item u_item;

    // covergroup
            covergroup fifo_cg;
          option.per_instance = 1;
        
          cp_wdata: coverpoint u_item.i_wdata {
            bins range_0_to_255[] = {[0:255]};
          }
         cp_rdata: coverpoint u_item.o_rdata {
            bins range_0_to_255[] = {[0:255]};
          }
          cp_full: coverpoint u_item.o_full {
            bins full[]   = {[0:1]};
          }
          cp_empty: coverpoint u_item.o_empty {
            bins empty[]   = {[0:1]};
          }
          cx_wdata_empty  : cross cp_wdata, cp_empty;
          cx_wdata_full   : cross cp_wdata, cp_full;
          cx_rdata_empty  : cross cp_rdata, cp_empty;
          cx_rdata_full   : cross cp_rdata, cp_full;
        endgroup

    // constructor
    function new(string name = "FIFO_COVERAGE", uvm_component c = null);
        super.new(name, c);
        fifo_cg = new();
    endfunction

    // function 'write'
    virtual function void write(fifo_seq_item t);
        u_item = t;
        fifo_cg.sample();  // sample, bins one time hit
    endfunction

    // function 'report_phase'
    virtual function void report_phase(uvm_phase phase);
    `uvm_info(get_name(), $sformatf("\n***** Coverage Report *****\n=== i_wdata/o_empty      : %.3f%% ===\n=== i_wdata/o_full      : %.3f%% ===\n=== o_rdata/o_empty      : %.3f%% ===\n=== o_rdata/o_full      : %.3f%% ===",fifo_cg.cx_wdata_empty.get_coverage,fifo_cg.cx_wdata_full.get_coverage, fifo_cg.cx_rdata_empty.get_coverage, fifo_cg.cx_rdata_full.get_coverage), UVM_NONE)
    endfunction
endclass
//---------------------


//---------------------
// 8. environment
class fifo_environment extends uvm_env;
    // uvm factory registry
    `uvm_component_utils(fifo_environment)

    // handle declaration
    fifo_agent      u_agt;
    fifo_scoreboard u_scb;
    fifo_coverage   u_cov;

    // constructor
    function new(string name = "FIFO_ENVIRONMENT", uvm_component c = null);
        super.new(name, c);
    endfunction

    // function 'build_phase'
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        u_agt = fifo_agent::type_id::create("AGT", this);
        u_scb = fifo_scoreboard::type_id::create("SCB", this);
        u_cov = fifo_coverage::type_id::create("COV", this);
    endfunction

    // function 'connect_phase'
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        u_agt.u_mon.send.connect(u_scb.recv);
        u_agt.u_mon.send.connect(u_cov.analysis_export);  // monitor : caller |  scoreboard, coverage : callee
    endfunction

endclass
//---------------------


//---------------------
// 9. test
class fifo_test extends uvm_test;
    // uvm factory registry
    `uvm_component_utils(fifo_test)

    // handle declaration
    fifo_environment        u_env;
    fifo_sequence_reset     u_seq_rst;
    fifo_sequence_random    u_seq_rand;

    // construnctor
    function new(string name = "FIFO_TEST", uvm_component c = null);
        super.new(name, c);
    endfunction

    // function 'build_phase'
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        u_env         = fifo_environment::type_id::create("ENV", this);
        u_seq_rst     = fifo_sequence_reset::type_id::create("SEQ_RST", this);
        u_seq_rand    = fifo_sequence_random::type_id::create("SEQ_RAND", this);
    endfunction

    // task 'run_phase'
    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);
        // u_seq_rst
        phase.raise_objection(this);
        u_seq_rst.start(u_env.u_agt.u_sqr);
        phase.drop_objection(this);
        // u_seq_random
        phase.raise_objection(this);
        u_seq_rand.start(u_env.u_agt.u_sqr);
        repeat(2) @(posedge u_env.u_agt.u_drv.u_if.i_clk);
        phase.drop_objection(this);
    endtask

endclass
//---------------------


//---------------------
// tb
module tb_fifo_uvm;
    // clock generation
    logic i_clk = 0;
    always #5 i_clk = ~i_clk;

    // interface instantiation
    fifo_if u_if (i_clk);

    // DUT instantiation
    fifo_uvm  DUT(
      .i_clk      (i_clk), 
      .i_rst_n    (u_if.i_rst_n),
      .i_push     (u_if.i_push),
      .i_pop      (u_if.i_pop),
      .i_wdata    (u_if.i_wdata),
      .o_rdata    (u_if.o_rdata),
      .o_full     (u_if.o_full),
      .o_empty    (u_if.o_empty)
    );

    // run
    initial begin
        uvm_config_db#(virtual fifo_if)::set(null, "*", "u_if", u_if);
        run_test("fifo_test");
    end

    // fsdb
    initial begin
        $fsdbDumpfile("wave.fsdb");
        $fsdbDumpvars(0, tb_fifo_uvm);
    end

endmodule
//---------------------

