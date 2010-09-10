`include "subsoc_bench_defines.v"
`include "subsoc_defines.v"
`include "or1200_defines.v"

module subsoc_bench();

reg clock, reset;

//Debug interface
wire dbg_tms_i;
wire dbg_tck_i;
wire dbg_tdi_i;
wire dbg_tdo_o;
wire jtag_vref;
wire jtag_gnd;

//SPI wires
wire spi_mosi;
reg spi_miso;
wire spi_sclk;
wire [1:0] spi_ss;

//UART wires
wire uart_stx;
reg uart_srx;
wire [7:0] uusb_dat_o;
wire [7:0] uusb_dat_i;

// SFIFO_IF wires
wire          sfifo_rd_o;
wire          sfifo_empty_i;
wire [15:0]   sfifo_di;
wire          sfifo_bp_tick_i;

//
// Testbench mechanics
//
reg [7:0] program_mem[(1<<(`MEMORY_ADR_WIDTH+2))-1:0];
integer initialize, final, ptr;
reg [8*64:0] file_name;
reg load_file;

initial begin
    reset = 1'b0;
    clock = 1'b0;

    uart_srx = 1'b1;
    
    //dual and two port rams from FPGA memory instances have to be
    //initialized to 0
    init_fpga_memory;

    load_file = 1'b0;
`ifdef INITIALIZE_MEMORY_MODEL 
    load_file = 1'b1;
`endif
`ifdef START_UP
    load_file = 1'b1;
`endif

    //get firmware hex file from command line input
    if ( load_file ) begin
        if ( ! $value$plusargs("file_name=%s", file_name) || file_name == 0 ) begin
            $display("ERROR: please specify an input file to start.");
            $finish;
        end
        $readmemh(file_name, program_mem);
        // First word comprehends size of program
        final = { program_mem[0] , program_mem[1] , program_mem[2] , program_mem[3] };
    end

`ifdef INITIALIZE_MEMORY_MODEL 
	// Initialize memory with firmware
	initialize = 0;
	while ( initialize < final ) begin
		subsoc_top_0.onchip_ram_top.block_ram_3.mem[initialize/4] = program_mem[initialize];
		subsoc_top_0.onchip_ram_top.block_ram_2.mem[initialize/4] = program_mem[initialize+1];
		subsoc_top_0.onchip_ram_top.block_ram_1.mem[initialize/4] = program_mem[initialize+2];
		subsoc_top_0.onchip_ram_top.block_ram_0.mem[initialize/4] = program_mem[initialize+3];
        initialize = initialize + 4;
	end
	$display("Memory model initialized with firmware:");
	$display("%s", file_name);
	$display("%d Bytes loaded from %d ...", initialize , final);
`endif

    // Reset controller
    repeat (2) @ (negedge clock);
    reset = 1'b1;
    repeat (16) @ (negedge clock);
    reset = 1'b0;

`ifdef START_UP
	// Pass firmware over spi to or1k_startup
	ptr = 0;
	//read dummy
	send_spi(program_mem[ptr]);
	send_spi(program_mem[ptr]);
	send_spi(program_mem[ptr]);
	send_spi(program_mem[ptr]);
	//~read dummy
	while ( ptr < final ) begin
		send_spi(program_mem[ptr]);
		ptr = ptr + 1;
	end
	$display("Memory start-up completed...");
	$display("Loaded firmware:");
	$display("%s", file_name);
`endif


	//
    // Testbench START
	//
    fork
        begin
            #2000000;
`ifdef UART
            uart_send(8'h41);       //Character A
`endif	
        end
    join

end


//
// Modules instantiations
//
subsoc_top subsoc_top_0(
   .clk(clock),
   .reset(reset)

   //SPI ports
`ifdef START_UP
   , 
   .spi_flash_mosi(spi_mosi), 
   .spi_flash_miso(spi_miso), 
   .spi_flash_sclk(spi_sclk), 
   .spi_flash_ss(spi_ss)
`endif

   //UART ports
`ifdef UART
   , 
   // .uart_stx(uart_stx),
   // .uart_srx(uart_srx)
   .uusb_dat_o (uusb_dat_o),
   .uusb_dat_i (uusb_dat_i)
`endif // !UART

//
// SFIFO_IF (sync fofo interface)
//
`ifdef SFIFO_IF
    ,
    .sfifo_rd_o         (sfifo_rd_o),
    .sfifo_empty_i      (sfifo_empty_i),
    .sfifo_di           (sfifo_di),
    .sfifo_bp_tick_i    (sfifo_bp_tick_i)
`endif

);

`ifdef VPI_DEBUG
	dbg_comm_vpi dbg_if(
		.SYS_CLK(clock),
		.P_TMS(dbg_tms_i), 
		.P_TCK(dbg_tck_i), 
		.P_TRST(), 
		.P_TDI(dbg_tdi_i), 
		.P_TDO(dbg_tdo_o)
	);
`else
   assign dbg_tdi_i = 1;
   assign dbg_tck_i = 0;
   assign dbg_tms_i = 1;
`endif


//
//	Regular clocking and output
//
always begin
    #((`CLK_PERIOD)/2) clock <= ~clock;
end

initial begin
        $display("\nStarting RTL simulation of %s test\n", `TEST_NAME_STRING);
`ifdef VCD
	// $dumpfile("../results/subsoc_wave.vcd");
	// $dumpvars();
        // $display("VCD in %s\n", {`TEST_RESULTS_DIR,`TEST_NAME_STRING,".vcd"});
        // $dumpfile({`TEST_RESULTS_DIR,`TEST_NAME_STRING,".vcd"});
        // $dumpvars(0);
        // //TODO: waveform dump based on simulation parameter
        $display("VCD in %s\n", {`TEST_RESULTS_DIR,`TEST_NAME_STRING,".shm"});
        $shm_open ({`TEST_RESULTS_DIR,`TEST_NAME_STRING,".shm"}, , , 0, 100, 20);
        $shm_probe("AMC");  // dump all levels from initial;
`endif
end


//
//	Functionalities tasks: SPI Startup and UART Monitor
//
//SPI START_UP
`ifdef START_UP
task send_spi;
    input [7:0] data_in;
    integer i;
    begin
	i = 7;
	for ( i = 7 ; i >= 0; i = i - 1 ) begin
        	spi_miso = data_in[i];
			@ (posedge spi_sclk);
	    end
    end
endtask
`endif
//~SPI START_UP

//
// SFIFO_IF
//
`ifdef SFIFO_IF
assign  sfifo_empty_i = 1;
assign  sfifo_di = 16'b0;
assign  sfifo_bp_tick_i = 0;
`endif // SFIFO_IF

//UART
`ifdef UART
localparam UART_TX_WAIT = (`FREQ_NUM_FOR_NS / `UART_BAUDRATE);

task uart_send;
    input [7:0] data;
    integer i;
    begin
        uart_srx = 1'b0;
	    #UART_TX_WAIT;
        for ( i = 0; i < 8 ; i = i + 1 ) begin
		    uart_srx = data[i];
		    #UART_TX_WAIT;
	    end        
        uart_srx = 1'b0;
	    #UART_TX_WAIT;
	    uart_srx = 1'b1;	    
    end
endtask

//UART Monitor (prints uart output on the terminal)
// Something to trigger the task
always @(posedge clock)
	uart_decoder;

task uart_decoder;
	integer i;
	reg [7:0] tx_byte;
	begin

	// Wait for start bit
	while (uart_stx == 1'b1)
		@(uart_stx);

	#(UART_TX_WAIT+(UART_TX_WAIT/2));

    for ( i = 0; i < 8 ; i = i + 1 ) begin
		tx_byte[i] = uart_stx;
		#UART_TX_WAIT;
	end

	//Check for stop bit
	if (uart_stx == 1'b0) begin
		  //$display("* WARNING: user stop bit not received when expected at time %d__", $time);
	  // Wait for return to idle
		while (uart_stx == 1'b0)
			@(uart_stx);
	  //$display("* USER UART returned to idle at time %d",$time);
	end
	// display the char
	$write("%c", tx_byte);
	end
endtask
//~UART Monitor
`endif // !UART
//~UART


//
//	TASKS to communicate with interfaces
//
//
// TASK to initialize instantiated FPGA dual and two port memory to 0
//
task init_fpga_memory;
    integer i;
    begin
`ifdef OR1200_RFRAM_TWOPORT
`ifdef OR1200_XILINX_RAMB4
    for ( i = 0; i < (1<<8); i = i + 1 ) begin
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.ramb4_s16_s16_0.mem[i] = 16'h0000;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.ramb4_s16_s16_1.mem[i] = 16'h0000;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.ramb4_s16_s16_0.mem[i] = 16'h0000;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.ramb4_s16_s16_1.mem[i] = 16'h0000;
    end
`elsif OR1200_XILINX_RAMB16
    for ( i = 0; i < (1<<9); i = i + 1 ) begin
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.ramb16_s36_s36.mem[i] = 32'h0000_0000;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.ramb16_s36_s36.mem[i] = 32'h0000_0000;
    end
`elsif OR1200_ALTERA_LPM
`ifndef OR1200_ALTERA_LPM_XXX
    $display("Definition OR1200_ALTERA_LPM in or1200_defines.v does not enable ALTERA memory for neither DUAL nor TWO port RFRAM");
    $display("It uses GENERIC memory instead.");
    $display("Add '`define OR1200_ALTERA_LPM_XXX' under '`define OR1200_ALTERA_LPM' on or1200_defines.v to use ALTERA memory.");
`endif
`ifdef OR1200_ALTERA_LPM_XXX
    $display("...Using ALTERA memory for TWOPORT RFRAM!");
    for ( i = 0; i < (1<<5); i = i + 1 ) begin
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.altqpram_component.mem[i] = 32'h0000_0000;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.altqpram_component.mem[i] = 32'h0000_0000;
    end
`else
    $display("...Using GENERIC memory!");
    for ( i = 0; i < (1<<5); i = i + 1 ) begin
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.mem[i] = 32'h0000_0000;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.mem[i] = 32'h0000_0000;
    end
`endif
`elsif OR1200_XILINX_RAM32X1D
    $display("Definition OR1200_XILINX_RAM32X1D in or1200_defines.v does not enable FPGA memory for TWO port RFRAM");
    $display("It uses GENERIC memory instead.");
    $display("FPGA memory can be used if you choose OR1200_RFRAM_DUALPORT");
    for ( i = 0; i < (1<<5); i = i + 1 ) begin
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.mem[i] = 32'h0000_0000;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.mem[i] = 32'h0000_0000;
    end
`else
    for ( i = 0; i < (1<<5); i = i + 1 ) begin
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.mem[i] = 32'h0000_0000;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.mem[i] = 32'h0000_0000;
    end
`endif
`elsif OR1200_RFRAM_DUALPORT
`ifdef OR1200_XILINX_RAMB4
    for ( i = 0; i < (1<<8); i = i + 1 ) begin
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.ramb4_s16_0.mem[i] = 16'h0000;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.ramb4_s16_1.mem[i] = 16'h0000;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.ramb4_s16_0.mem[i] = 16'h0000;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.ramb4_s16_1.mem[i] = 16'h0000;
    end
`elsif OR1200_XILINX_RAMB16
    for ( i = 0; i < (1<<9); i = i + 1 ) begin
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.ramb16_s36_s36.mem[i] = 32'h0000_0000;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.ramb16_s36_s36.mem[i] = 32'h0000_0000;
    end
`elsif OR1200_ALTERA_LPM
`ifndef OR1200_ALTERA_LPM_XXX
    $display("Definition OR1200_ALTERA_LPM in or1200_defines.v does not enable ALTERA memory for neither DUAL nor TWO port RFRAM");
    $display("It uses GENERIC memory instead.");
    $display("Add '`define OR1200_ALTERA_LPM_XXX' under '`define OR1200_ALTERA_LPM' on or1200_defines.v to use ALTERA memory.");
`endif
`ifdef OR1200_ALTERA_LPM_XXX
    $display("...Using ALTERA memory for DUALPORT RFRAM!");
    for ( i = 0; i < (1<<5); i = i + 1 ) begin
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.altqpram_component.mem[i] = 32'h0000_0000;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.altqpram_component.mem[i] = 32'h0000_0000;
    end
`else
    $display("...Using GENERIC memory!");
    for ( i = 0; i < (1<<5); i = i + 1 ) begin
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.mem[i] = 32'h0000_0000;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.mem[i] = 32'h0000_0000;
    end
`endif
`elsif OR1200_XILINX_RAM32X1D
`ifdef OR1200_USE_RAM16X1D_FOR_RAM32X1D
    for ( i = 0; i < (1<<4); i = i + 1 ) begin
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_0.ram32x1d_0_0.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_0.ram32x1d_0_1.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_0.ram32x1d_0_2.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_0.ram32x1d_0_3.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_0.ram32x1d_0_4.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_0.ram32x1d_0_5.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_0.ram32x1d_0_6.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_0.ram32x1d_0_7.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_0.ram32x1d_1_0.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_0.ram32x1d_1_1.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_0.ram32x1d_1_2.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_0.ram32x1d_1_3.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_0.ram32x1d_1_4.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_0.ram32x1d_1_5.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_0.ram32x1d_1_6.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_0.ram32x1d_1_7.mem[i] = 1'b0;

        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_1.ram32x1d_0_0.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_1.ram32x1d_0_1.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_1.ram32x1d_0_2.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_1.ram32x1d_0_3.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_1.ram32x1d_0_4.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_1.ram32x1d_0_5.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_1.ram32x1d_0_6.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_1.ram32x1d_0_7.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_1.ram32x1d_1_0.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_1.ram32x1d_1_1.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_1.ram32x1d_1_2.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_1.ram32x1d_1_3.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_1.ram32x1d_1_4.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_1.ram32x1d_1_5.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_1.ram32x1d_1_6.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_1.ram32x1d_1_7.mem[i] = 1'b0;

        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_2.ram32x1d_0_0.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_2.ram32x1d_0_1.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_2.ram32x1d_0_2.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_2.ram32x1d_0_3.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_2.ram32x1d_0_4.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_2.ram32x1d_0_5.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_2.ram32x1d_0_6.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_2.ram32x1d_0_7.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_2.ram32x1d_1_0.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_2.ram32x1d_1_1.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_2.ram32x1d_1_2.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_2.ram32x1d_1_3.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_2.ram32x1d_1_4.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_2.ram32x1d_1_5.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_2.ram32x1d_1_6.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_2.ram32x1d_1_7.mem[i] = 1'b0;

        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_3.ram32x1d_0_0.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_3.ram32x1d_0_1.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_3.ram32x1d_0_2.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_3.ram32x1d_0_3.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_3.ram32x1d_0_4.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_3.ram32x1d_0_5.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_3.ram32x1d_0_6.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_3.ram32x1d_0_7.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_3.ram32x1d_1_0.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_3.ram32x1d_1_1.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_3.ram32x1d_1_2.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_3.ram32x1d_1_3.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_3.ram32x1d_1_4.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_3.ram32x1d_1_5.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_3.ram32x1d_1_6.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_3.ram32x1d_1_7.mem[i] = 1'b0;

        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_0.ram32x1d_0_0.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_0.ram32x1d_0_1.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_0.ram32x1d_0_2.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_0.ram32x1d_0_3.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_0.ram32x1d_0_4.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_0.ram32x1d_0_5.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_0.ram32x1d_0_6.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_0.ram32x1d_0_7.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_0.ram32x1d_1_0.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_0.ram32x1d_1_1.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_0.ram32x1d_1_2.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_0.ram32x1d_1_3.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_0.ram32x1d_1_4.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_0.ram32x1d_1_5.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_0.ram32x1d_1_6.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_0.ram32x1d_1_7.mem[i] = 1'b0;

        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_1.ram32x1d_0_0.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_1.ram32x1d_0_1.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_1.ram32x1d_0_2.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_1.ram32x1d_0_3.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_1.ram32x1d_0_4.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_1.ram32x1d_0_5.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_1.ram32x1d_0_6.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_1.ram32x1d_0_7.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_1.ram32x1d_1_0.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_1.ram32x1d_1_1.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_1.ram32x1d_1_2.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_1.ram32x1d_1_3.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_1.ram32x1d_1_4.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_1.ram32x1d_1_5.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_1.ram32x1d_1_6.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_1.ram32x1d_1_7.mem[i] = 1'b0;

        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_2.ram32x1d_0_0.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_2.ram32x1d_0_1.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_2.ram32x1d_0_2.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_2.ram32x1d_0_3.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_2.ram32x1d_0_4.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_2.ram32x1d_0_5.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_2.ram32x1d_0_6.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_2.ram32x1d_0_7.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_2.ram32x1d_1_0.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_2.ram32x1d_1_1.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_2.ram32x1d_1_2.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_2.ram32x1d_1_3.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_2.ram32x1d_1_4.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_2.ram32x1d_1_5.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_2.ram32x1d_1_6.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_2.ram32x1d_1_7.mem[i] = 1'b0;

        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_3.ram32x1d_0_0.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_3.ram32x1d_0_1.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_3.ram32x1d_0_2.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_3.ram32x1d_0_3.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_3.ram32x1d_0_4.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_3.ram32x1d_0_5.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_3.ram32x1d_0_6.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_3.ram32x1d_0_7.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_3.ram32x1d_1_0.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_3.ram32x1d_1_1.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_3.ram32x1d_1_2.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_3.ram32x1d_1_3.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_3.ram32x1d_1_4.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_3.ram32x1d_1_5.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_3.ram32x1d_1_6.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_3.ram32x1d_1_7.mem[i] = 1'b0;
    end
`else
    for ( i = 0; i < (1<<4); i = i + 1 ) begin
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_0.ram32x1d_0.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_0.ram32x1d_1.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_0.ram32x1d_2.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_0.ram32x1d_3.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_0.ram32x1d_4.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_0.ram32x1d_5.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_0.ram32x1d_6.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_0.ram32x1d_7.mem[i] = 1'b0;

        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_1.ram32x1d_0.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_1.ram32x1d_1.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_1.ram32x1d_2.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_1.ram32x1d_3.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_1.ram32x1d_4.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_1.ram32x1d_5.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_1.ram32x1d_6.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_1.ram32x1d_7.mem[i] = 1'b0;

        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_2.ram32x1d_0.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_2.ram32x1d_1.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_2.ram32x1d_2.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_2.ram32x1d_3.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_2.ram32x1d_4.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_2.ram32x1d_5.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_2.ram32x1d_6.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_2.ram32x1d_7.mem[i] = 1'b0;

        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_3.ram32x1d_0.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_3.ram32x1d_1.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_3.ram32x1d_2.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_3.ram32x1d_3.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_3.ram32x1d_4.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_3.ram32x1d_5.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_3.ram32x1d_6.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_3.ram32x1d_7.mem[i] = 1'b0;

        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_0.ram32x1d_0.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_0.ram32x1d_1.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_0.ram32x1d_2.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_0.ram32x1d_3.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_0.ram32x1d_4.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_0.ram32x1d_5.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_0.ram32x1d_6.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_0.ram32x1d_7.mem[i] = 1'b0;

        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_1.ram32x1d_0.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_1.ram32x1d_1.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_1.ram32x1d_2.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_1.ram32x1d_3.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_1.ram32x1d_4.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_1.ram32x1d_5.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_1.ram32x1d_6.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_1.ram32x1d_7.mem[i] = 1'b0;

        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_2.ram32x1d_0.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_2.ram32x1d_1.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_2.ram32x1d_2.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_2.ram32x1d_3.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_2.ram32x1d_4.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_2.ram32x1d_5.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_2.ram32x1d_6.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_2.ram32x1d_7.mem[i] = 1'b0;

        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_3.ram32x1d_0.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_3.ram32x1d_1.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_3.ram32x1d_2.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_3.ram32x1d_3.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_3.ram32x1d_4.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_3.ram32x1d_5.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_3.ram32x1d_6.mem[i] = 1'b0;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_3.ram32x1d_7.mem[i] = 1'b0;
    end
`endif
`else
    for ( i = 0; i < (1<<5); i = i + 1 ) begin
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.mem[i] = 32'h0000_0000;
        subsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.mem[i] = 32'h0000_0000;
    end
`endif
`endif
    end
endtask



endmodule

