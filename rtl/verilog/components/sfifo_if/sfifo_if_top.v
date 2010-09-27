//
// Bits of WISHBONE address used for partial decoding of SPI registers.
//
`define SFIFO_OFS_BITS	    4:2

//
// Register offset
//
`define SFIFO_BP_TICK       3'h0
`define SFIFO_CTRL          3'h1
`define SFIFO_DI            3'h2
`define SFIFO_DOUT          3'h3
`define SFIFO_DIN_0         3'b100  // 0x10 ~ 0x13
`define SFIFO_DIN_1         3'b101  // 0x14 ~ 0x17
`define SFIFO_ADC_IN        3'b110  // 0x18 ~ 0x19, ADC value input

module sfifo_if_top
#(
  parameter           WB_AW           = 5,    // lower address bits
  parameter           WB_DW           = 32,
  parameter           SFIFO_DW        = 16,   // data width for SYNC_FIFO
  parameter           ADC_W           = 0     // width for ADC value
)
(
  // WISHBONE Interface
  output  reg [WB_DW-1:0]             wb_dat_o,
  output  reg                         wb_ack_o,
  input                               wb_clk_i,
  input                               wb_rst_i,
  input                               wb_cyc_i,
  input   [3:0]			      wb_sel_i,
  input   [WB_AW-1:2]                 wb_adr_i,   // lower address bits
  input   [WB_DW-1:0]                 wb_dat_i,   // data from wb_master
  input                               wb_we_i,
  input                               wb_stb_i,

  // SFIFO Interface (clk_500)
  output  reg                         sfifo_rd_o,
  input                               sfifo_empty_i,
  input   [SFIFO_DW-1:0]              sfifo_di,

  // SFIFO_CTRL Interface (clk_250)
  input                               sfifo_bp_tick_i,

  // GPIO Interface (clk_250)
  // SYNC_DOUT
  output  reg [7:0]                   dout_set_o,
  output  reg [7:0]                   dout_rst_o,
  // SYNC_DIN
  input       [15:0]                  din_i,

  input       [ADC_W-1:0]             adc_i

);

reg               sfifo_bp_tick_s;
wire              bp_pulser;
reg               bp_tick_n;
reg [WB_DW-1:0]   bp_tick_cnt;
wire              sfifo_di_sel;

// signals for SYNC_DOUT
wire              dout_sel;
reg [7:0]         dout_set;   // to hold non-synchronized signal
reg [7:0]         dout_rst;   // to hold non-synchronized signal
reg [7:0]         next_dout_set;   // to hold non-synchronized signal
reg [7:0]         next_dout_rst;   // to hold non-synchronized signal

// Address decoder
assign sfifo_di_sel = wb_cyc_i & wb_stb_i & (wb_adr_i[`SFIFO_OFS_BITS] == `SFIFO_DI);
                      // wb_sel_i[3]: byte 0
assign dout_sel     = wb_cyc_i & wb_stb_i & wb_we_i & wb_sel_i[3] & (wb_adr_i[WB_AW-1:2] == `SFIFO_DOUT);
   
// Wb acknowledge
always @(posedge wb_clk_i)
begin
  if (wb_rst_i)
    wb_ack_o <= 1'b0;
  else
    wb_ack_o <= wb_cyc_i & wb_stb_i & ~wb_ack_o 
                // block wb_ack_o if (sfifo_di_sel && sfifo_empty) 
                & ~(sfifo_di_sel & sfifo_empty_i);
end
   
// Read from registers
// Wb data out
always @(posedge wb_clk_i)
begin
  if (wb_rst_i)
    wb_dat_o <= 32'b0;
  else
    casez (wb_adr_i[`SFIFO_OFS_BITS])  // synopsys parallel_case
      `SFIFO_BP_TICK:   wb_dat_o  <= {bp_tick_cnt};
      `SFIFO_CTRL:      wb_dat_o  <= {31'd0, sfifo_empty_i};
      `SFIFO_DI:        wb_dat_o  <= {sfifo_di, 16'd0}; 
      `SFIFO_DIN_0:     wb_dat_o  <= {16'd0, din_i};
      `SFIFO_ADC_IN:    wb_dat_o  <= {{(16-ADC_W){1'b0}}, adc_i, 16'd0};
      default:          wb_dat_o  <= 'bx;
    endcase
end

always @(posedge wb_clk_i)
  if (wb_rst_i)
    sfifo_rd_o <= 0;
  else
    sfifo_rd_o <= sfifo_di_sel & (~sfifo_empty_i) & ~wb_ack_o; // (~wb_ack_o): prevent from reading sfifo twice

// sync from clk_250 to clk_500
always @ (posedge wb_clk_i)
  if (wb_rst_i)
    sfifo_bp_tick_s <= 0;
  else 
    sfifo_bp_tick_s <= sfifo_bp_tick_i;

// pulser for bp_tick
assign bp_pulser = sfifo_bp_tick_s & bp_tick_n;
always @ (posedge wb_clk_i)
  if (wb_rst_i)
    bp_tick_n <= 1;
  else
    bp_tick_n <= ~sfifo_bp_tick_s;

always @ (posedge wb_clk_i)
  if (wb_rst_i)
    bp_tick_cnt <= 0;
  else if (bp_pulser)
    bp_tick_cnt <= bp_tick_cnt + 1;

// to synchronize DOUT with Base Period Pulser
always @ (posedge wb_clk_i)
  if (bp_pulser) begin
    dout_set_o <= dout_set;
    dout_rst_o <= dout_rst;
  end
  
always @ (posedge wb_clk_i)
  if (wb_rst_i | bp_pulser) begin
    dout_set  <= 0;
    dout_rst  <= 0;
  end else if (dout_sel) begin
    dout_set  <= dout_set | next_dout_set;
    dout_rst  <= dout_rst | next_dout_rst;
  end

always @ (*) 
begin
    casez (wb_dat_i[31:24]) // synopsys parallel_case
      8'b1?000000: begin next_dout_set <= {7'h0,  wb_dat_i[30]      };  // dout[0]
                         next_dout_rst <= {7'h0, ~wb_dat_i[30]      }; end 
      8'b1?000001: begin next_dout_set <= {6'h0,  wb_dat_i[30], 1'h0}; // dout[1]
                         next_dout_rst <= {6'h0, ~wb_dat_i[30], 1'h0}; end 
      8'b1?000010: begin next_dout_set <= {5'h0,  wb_dat_i[30], 2'h0}; // dout[2]
                         next_dout_rst <= {5'h0, ~wb_dat_i[30], 2'h0}; end      
      8'b1?000011: begin next_dout_set <= {4'h0,  wb_dat_i[30], 3'h0}; // dout[3]
                         next_dout_rst <= {4'h0, ~wb_dat_i[30], 3'h0}; end      
      8'b1?000100: begin next_dout_set <= {3'h0,  wb_dat_i[30], 4'h0}; // dout[4]
                         next_dout_rst <= {3'h0, ~wb_dat_i[30], 4'h0}; end      
      8'b1?000101: begin next_dout_set <= {2'h0,  wb_dat_i[30], 5'h0}; // dout[5]
                         next_dout_rst <= {2'h0, ~wb_dat_i[30], 5'h0}; end      
      8'b1?000110: begin next_dout_set <= {1'h0,  wb_dat_i[30], 6'h0}; // dout[6]
                         next_dout_rst <= {1'h0, ~wb_dat_i[30], 6'h0}; end      
      8'b1?000111: begin next_dout_set <= {       wb_dat_i[30], 7'h0}; // dout[7]
                         next_dout_rst <= {      ~wb_dat_i[30], 7'h0}; end 
      default: begin     next_dout_set <= 8'h00;    dout_rst <= 8'h00; end  // Disable dout
    endcase
end    

endmodule
