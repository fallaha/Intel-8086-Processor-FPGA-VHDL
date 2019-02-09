module UART_TX  (CLK,SendKey,Tx,data);
	input CLK;
	input SendKey;
	input [7:0] data;
	output Tx;
	wire [15:0] Buffer;
								// -Idle- S- -Data- -S-   
//	[Idle = NoWork   - Data = (in this code) ASCCI 'B' - Right S means Start - Left S means Stop]
	reg [3:0] Number=0; // Counter of Buffer
	reg [12:0] CounterPluse=0;	// Counter Pulse for Creat 1/9600 time
	reg StartSend;			// bit Control Sending on Tx
	reg EndSend=1;			// bit Control Sending on Tx
	reg SendKeyPrev=0; 	// bit Control Sending on Tx
	
	always @ (posedge CLK)
	  begin
	    if (StartSend == 1 || EndSend == 0 ) begin
		 EndSend = 0;	// Sending not Finish
	    CounterPluse = CounterPluse +1;
			if (CounterPluse == 5000) // 50000000MHz(Clock)/9600)Baudrate
			 begin
			     Number = Number + 1;	// Counter Buffer to Send Next Bit to TX
			     CounterPluse = 0;
				   if (Number == 15)	// Finished Send
						EndSend = 1;	// Sending Finished	 		  
			end
		 end
	  end
		
	always @ (posedge CLK)
	  begin
		if (EndSend == 1) begin
		  if (SendKey != SendKeyPrev)begin
		     StartSend = 1;
			  SendKeyPrev = ~ SendKeyPrev;
		  end
		 end
		 else
			 StartSend = 0;
	  end
	  
	assign Tx = Buffer [Number];
	assign Buffer = {7'b1111111,data[7:0],1'b0};
endmodule
