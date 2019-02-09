module SDcard(
    input CLK,
    input MISO,
    input RESET,
    input ReadKey,
	 output TX,
	 output CS,
	 output SCLK,
	 output MOSI,
	 output wire [3:0] LED
    );
	 
	 
	 reg RDE=1; 				 // Read  Enable Active-High
	 reg WRE=0; 				 // Write Enable Active-High
	 reg CONTINUE=0; 			 // CONTINUE Enable Active-High
	 reg [31:0] ADDRESS = 0;  // Block address.
	 reg [7:0]  DATA;		 // Data to write to block.
	 reg [7:0]  DATAREC;	 // Data recived from block SD.
	 wire BUSY;				 // controller is busy :performing some operation.
	 reg HSHOST; 			 // Hand Shake Host
	 wire HSSD;   			 // Hand Shake SD Contriller
	 wire [15:0] ERROR;	 // Recive Error!
	 reg [15:0] CounterPulse;
	 reg [3:0] LEDs;
	 reg [7:0] Recive;
	 reg send;

	SdCardCtrl SDC (
	 .clk_i      (CLK),       // Master clock.
    .reset_i    (~RESET),       // active-high, synchronous  reset.
    .rd_i       (RDE),       // active-high read block request.
    .wr_i       (WRE),       // active-high write block request.
    .continue_i (CONTINUE),  // If true, inc address and continue R/W.
    .addr_i     (ADDRESS),   // Block address.
    .data_i     (DATA),      // Data to write to block.
    .data_o     (DATAREC),   // Data read from block.
    .busy_o     (BUSY),      // High when controller is busy performing some operation.
    .hndShk_i   (HSHOST),    // High when host has data to give or has taken data.
    .hndShk_o   (HSSD),      // High when controller has taken data or has data to give.
    .error_o    (ERROR),
	 .LED (LEDs),
    // I/O signals to the external SD card.
    .cs_bo      (CS),      // Active-low chip-select.
    .sclk_o     (SCLK),    // Serial clock to SD card.
    .mosi_o     (MOSI),    // Serial data output to SD card.
    .miso_i     (MISO)    // Serial data input from SD card.
	 );
	 
	UART_TX uart (CLK,send,TX,Recive);
	
	 always @ (posedge CLK)
	  begin
	   CounterPulse = CounterPulse+1;
		 if (CounterPulse [15:0] == 0 ) begin
		   if (HSSD == 1)
			 begin
		     Recive [7:0] = DATAREC [7:0];
			  HSHOST = 1;
			  send = 1;
			 end
			else
			begin
			 HSHOST = 0; 
			 send = 0;
			end
		  end
		end

		assign LED [3:0] = Recive [3:0];
	 
endmodule
