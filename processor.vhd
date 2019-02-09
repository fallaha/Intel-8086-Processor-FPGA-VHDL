------------------------------< In The Name Of GOD >-------------------------------
-- Company: Dalmif
-- Engineer: Ali Fallah
-- 
-- Create Date:    19:53:17 05/28/2017 
-- Design Name: 		Processor (enshaallah)
-- Module Name:    processor - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
 
entity processor is
    Port ( clk_i   : in  STD_LOGIC;
			  reset_i : in  STD_LOGIC;
			  cs      : out STD_LOGIC;
			  sclk_o  : out STD_LOGIC;
			  mosi_o  : out STD_LOGIC;
			  miso_i  : in  STD_LOGIC;
			  TX 		 : out STD_LOGIC; -- UART
			  LED 	 : out STD_LOGIC_VECTOR (3 downto 0);
  ---------<VGA Signal>--------------------
			  BLUE    : out std_logic;
			  GREEN   : out std_logic;
			  RED     : out std_logic;
			  HS		 : out std_logic;
  			  VS 	    : out std_logic
	 );
end processor;

architecture Behavioral of processor is

COMPONENT MainMemory
  PORT (
    clka : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
  );
END COMPONENT;

component UART_TX port (
    CLK     : in  STD_LOGIC;
	 SendKey   : in  STD_LOGIC;
	 Tx     : out  STD_LOGIC;
	 data : in  STD_LOGIC_VECTOR (7 downto 0));
	end component;

component MYVGA    port ( 
			CLK_50MHz: in std_logic;
			Xchar : std_logic_vector(6 downto 0);
			Ychar : std_logic_vector(4 downto 0);
			char : std_logic_vector(6 downto 0);
         VS: out std_logic;
			HS: out std_logic;
			RED: out std_logic;
			GREEN: out std_logic;
			BLUE: out std_logic
  );
	end component;

	
component SdCardCtrl is
    port (
      clk_i      : in  std_logic;       -- Master clock.
      reset_i    : in  std_logic                     ;  -- active-high, synchronous  reset.
      rd_i       : in  std_logic                     ;  -- active-high read block request.
      wr_i       : in  std_logic                     ;  -- active-high write block request.
      continue_i : in  std_logic                     ;  -- If true, inc address and continue R/W.
      addr_i     : in  std_logic_vector(31 downto 0) ;  -- Block address.
      data_i     : in  std_logic_vector(7 downto 0)  ;  -- Data to write to block.
      data_o     : out std_logic_vector(7 downto 0)  ;  -- Data read from block.
      busy_o     : out std_logic;  -- High when controller is busy performing some operation.
      hndShk_i   : in  std_logic;  -- High when host has data to give or has taken data.
      hndShk_o   : out std_logic;  -- High when controller has taken data or has data to give.
      error_o    : out std_logic_vector(15 downto 0) ;
      -- I/O signals to the external SD card.
      cs_bo      : out std_logic                    ;  -- Active-low chip-select.
      sclk_o     : out std_logic                    ;  -- Serial clock to SD card.
      mosi_o     : out std_logic                     ;  -- Serial data output to SD card.
      miso_i     : in  std_logic                       -- Serial data input from SD card.
      );
  end component;
  
  signal NOTreset_i       : std_logic;	-- Enable read
  signal sd_read_en       : std_logic	:= '1';	-- Enable read
  signal sd_write_en       : std_logic	:= '0';	-- Enable Write
  signal sd_read_continue : std_logic	:= '0';	-- continue read sector
  signal sd_is_busy	  : std_logic;	-- sd card is busy
  signal sd_h_hndShk	  : std_logic; -- host Hande Shake
  signal sd_c_hndShk	  : std_logic;-- clinet Hande Shake
  signal sd_address    : std_logic_vector(31 downto 0):= (others =>'0');	-- address to read / write
  signal sd_data_in    :  std_logic_vector(7 downto 0);-- data to wirte
  signal sd_data_out    :  std_logic_vector(7 downto 0); -- data to read
  signal sd_error    :  std_logic_vector(15 downto 0); -- sd card error message
  signal CounterPulse    :  std_logic_vector(15 downto 0); -- sd card error message
  signal main_mem_wr_en	: std_logic_vector (0 downto 0); -- Enable Write Pin Memory
  signal main_mem_addr	: std_logic_vector (8 downto 0); -- Address of MAin mamory to read / write
  signal main_mem_data_in	: std_logic_vector (7 downto 0); -- data to Write on Main Mamory
  signal main_mem_data_out	: std_logic_vector (7 downto 0); -- data read from Main Mamory
  
  signal tx_char   	: std_logic_vector (7 downto 0); -- char send to tx
  signal uart_tx_b	: std_logic; -- boolean send char
  signal ClockPulse : std_logic_vector (15 downto 0);
  signal CLKPorcessor : std_logic;
	
  signal Xchar : std_logic_vector(6 downto 0);
  signal Ychar : std_logic_vector(4 downto 0);
  signal char  : std_logic_vector(6 downto 0);

	
begin

 mian_mem : MainMemory
  PORT MAP (
    clka => clk_i,
    wea => main_mem_wr_en,
    addra => main_mem_addr,
    dina => main_mem_data_in,
    douta => main_mem_data_out
  );
  
  
 VGA : MYVGA
  PORT MAP (
    CLK_50MHz => clk_i,
	 Xchar => Xchar ,
	 Ychar => Ychar,
	 char  => Char,
    VS => VS,
    HS => HS,
    RED => RED,
    GREEN => GREEN,
    BLUE => BLUE
  );

  
 HDD : SdCardCtrl port map (
		clk_i      => clk_i,
      reset_i    => NOTreset_i,
      rd_i       => sd_read_en,
      wr_i       => sd_write_en,
      continue_i => sd_read_continue,
      addr_i     => sd_address,
      data_i     => sd_data_in,
      data_o     => sd_data_out,
      busy_o     => sd_is_busy,
      hndShk_i   => sd_h_hndShk,
      hndShk_o   => sd_c_hndShk,
      error_o    => sd_error,
      -- I/O signals to the external SD card.
      cs_bo      => cs,
      sclk_o     =>sclk_o,
      mosi_o     =>mosi_o,
      miso_i     =>miso_i
 );
 
UART : UART_TX port map (
    CLK     => clk_i,
	 SendKey   => uart_tx_b,
	 Tx => TX,
    data  => tx_char
);


	instruction : process (CLKPorcessor)
	type State_type is (    -- States of the SD card controller FSM.
      READ_BYTE,  -- Send initialization clock pulses to the deselected SD card.    
		Read_Sector, -- Read first sector
		detect_inst,
		INTRRUPT,
		Next_Byte,
		detect_gpr1,
		detect_addr,
		read_addr_mem,
		const_to_mem,
		detect_operate,
		WRITE_BYTE,
		set_reg_h,
		set_val_reg,
		halt,
		jump,
		detect_gpr4,
		detect_gpr5,
		Cond_Jump,
		Call,
		RET,
		POPF,
		MOVS,
		CMPS,
		COMP,
		REP,
		POP,
		show_char,
		Init			-- redy to start
      );

	variable State     : State_type := Init;  -- Current state of the FSM.
	variable RTNstate  : State_type := Init;  -- Next    state of the FSM.
	variable EXstate   : State_type := Init;  -- Extera  state of the FSM.
			
	type SubState_type is (    -- States of the SD card controller FSM.
			adder,
			adcer,
			suber,
			muler,
			ander,
			xorer,
			orer,
			mover,
			incer,
			decer,
			pusher,
			sbber,
			poper
      );
					
	variable Sub_State     : SubState_type;  -- Current state of the FSM.
	
	type Intrupt_Type is (
	int_LED
	);
	
	subtype NUMBER_MEMORY_BIT is std_logic_vector(8 downto 0);-- 2^9 = 512byte
	 
	variable int : Intrupt_Type;
	variable cnt_bit : natural range 0 to 512;  -- Counter of bits
	variable num_byte : natural range 0 to 4;  -- Number of byte to read
	variable num_byte_v : natural range 0 to 4;  -- Number of byte to read
	variable addr_mem_rw : std_logic_vector (15 downto 0);
	variable ram_rw_en : std_logic ;		-- Enable other address to read write (else IP)
	variable val_const_bit : std_logic ;		-- it show constant value (e.g. mov [bx]+3,'j')

	variable AX  : std_logic_vector (15 downto 0);  -- AX Regester
	variable BX  : std_logic_vector (15 downto 0);  -- BX Regester
	variable CX  : std_logic_vector (15 downto 0);  -- CX Regester
	variable DX  : std_logic_vector (15 downto 0);  -- DX Regester
	
	variable CS  : std_logic_vector (15 downto 0);  -- Code Segment Regester
	variable DS  : std_logic_vector (15 downto 0);  -- Data Segment Regester
	variable ES  : std_logic_vector (15 downto 0);  -- ExtraSegment Regester
	variable SS  : std_logic_vector (15 downto 0);  -- Stack Segment Regester
	variable IP  : std_logic_vector (15 downto 0);  -- Instruction Pointer Regester
	
	variable SP  : std_logic_vector (15 downto 0);  -- Stack Pointer Regester
	variable BP  : std_logic_vector (15 downto 0);  -- Base Pointer Regester
	variable SI  : std_logic_vector (15 downto 0);  -- Source Index Regester
	variable DI  : std_logic_vector (15 downto 0);  -- Destination Index Regester
	
	alias AL: std_logic_vector (7 downto 0) is AX (7 downto 0);
	alias AH: std_logic_vector (7 downto 0) is AX (15 downto 8);
	alias CL: std_logic_vector (7 downto 0) is CX (7 downto 0);
	alias CH: std_logic_vector (7 downto 0) is CX (15 downto 8);
	alias DL: std_logic_vector (7 downto 0) is DX (7 downto 0);
	alias DH: std_logic_vector (7 downto 0) is DX (15 downto 8);	
	alias BL: std_logic_vector (7 downto 0) is BX (7 downto 0);
	alias BH: std_logic_vector (7 downto 0) is BX (15 downto 8);
	
	variable flag	: std_logic_vector (7 downto 0);	-- DF, IF, AF, PF, OF, SF, ZF, CF
	alias carry_flag:    std_logic  is flag(0);	-- carry_flag bit show
	alias zero_flag:     std_logic  is flag(1);	-- zero_flag bit show
	alias sign_flag:     std_logic  is flag(2);	-- sign_flag bit show
	alias overflow_flag: std_logic  is flag(3);	-- overflow_flag bit show
	alias parity_flag:   std_logic  is flag(4);	-- parity_flag bit show
	alias adjust_flag:   std_logic  is flag(5);	-- adjust_flag bit show
	alias intrrupt_flag: std_logic  is flag(6);	-- intrrupt_flag bit show
	alias direction_flag:std_logic  is flag(7);	-- direction_flag bit show


	variable byte0	: std_logic_vector (7 downto 0);	-- Save instruction Code
	variable byte1	: std_logic_vector (7 downto 0);	-- Save instruction Code
	variable byte2	: std_logic_vector (7 downto 0);	-- Save instruction Code
	variable byte3	: std_logic_vector (7 downto 0);	-- Save instruction Code
	
	variable reg_h	: std_logic_vector (16 downto 0);	-- Complementary register - the MSB bit is carry_flag bit
	alias m_reg_0 : std_logic_vector (1 downto 0) is byte0 (7 downto 6);	-- MODE of Addressing (e.g. "11" means reg to reg)
	
	variable m_reg : std_logic_vector (1 downto 0);	-- MODE of Addressing (e.g. "11" means reg to reg)
	
	variable rm_t	: std_logic_vector (2 downto 0);	-- register / memory address
	variable reg_t	: std_logic_vector (2 downto 0);	-- register address
	
	variable repnz_en	: std_logic;	-- repnz enable
	variable repz_en	: std_logic;	-- repz enable
	variable compare	: std_logic;	-- compare : dont operate on byte and reg
	variable S_reg	: std_logic;	-- THE Parameter is Word (16bit)
	variable W_reg	: std_logic;	-- THE Regester is Word (16bit)
	variable D_reg	: std_logic;	-- Direction (1: R/M to reg	0: reg to R/M)
	
	variable bool	: std_logic;	-- boolean 
	variable cheng_reg_h_byte	: std_logic;	-- it Makes it : byte val -> reg_h val (in detect_operate case)
	
   variable LED_v	   : std_logic_vector (3 downto 0);	-- Save Addressing (parametr)
	
	constant iAX,iAL  : std_logic_vector(2 downto 0) := "000";
	constant iCX,iCL  : std_logic_vector(2 downto 0) := "001";
	constant iDX,iDL  : std_logic_vector(2 downto 0) := "010";
	constant iBX,iBL  : std_logic_vector(2 downto 0) := "011";
	constant iSP,iAH  : std_logic_vector(2 downto 0) := "100";
	constant iBP,iCH  : std_logic_vector(2 downto 0) := "101";
	constant iSI,iDH  : std_logic_vector(2 downto 0) := "110";
	constant iDI,iBH  : std_logic_vector(2 downto 0) := "111";
	constant zeros_16 : std_logic_vector(AX'range) 	 := (others => '0');	
	constant zeros_8 	: std_logic_vector(AH'range) 	 := (others => '0');	
	variable reg1_t : std_logic_vector(2 downto 0);
	
	begin
		if rising_edge(CLKPorcessor) then
		 if (NOTreset_i =  '1') then
		  state := Init;
		 else
		  case state is
			when READ_BYTE =>		-- Read One Byte From Main Memory ----------------------<Read Byte>--------------------
			 if (num_byte_v/= num_byte) then
				 case num_byte_v is
				  when 0 =>
					byte0 := main_mem_data_out;
				  when 1 =>
					byte1 := main_mem_data_out;
				  when 2 =>
					byte2 := main_mem_data_out;
				  when 3 =>
					byte3 := main_mem_data_out;
				  when others => null;
				  end case;
				  num_byte_v	:= num_byte_v+1;
				  if (ram_rw_en = '1') then addr_mem_rw	:= std_logic_vector (unsigned(addr_mem_rw) +1); else  
				  IP	:= std_logic_vector (unsigned(IP) +1);
				  end if;
			  else 
			   num_byte_v	:=0;
				state	:= rtnstate;
				ram_rw_en		:= '0';
				tx_char	<= byte0;
				uart_tx_b <= not uart_tx_b;
			end if;
			
			when WRITE_BYTE =>		-- Write One Byte From Main Memory ---------------------<Write Byte>--------------------
				main_mem_wr_en (0) <= '1';
				ram_rw_en	:= '1';
				if (num_byte_v/= num_byte) then
				 case num_byte_v is
				  when 0 =>
					main_mem_data_in <= byte0;
				  when 1 =>
					main_mem_data_in <= byte1;
				  when 2 =>
					main_mem_data_in <= byte2;
				  when 3 =>
					main_mem_data_in <= byte3;
				  when others => null;
				  end case;
				  num_byte_v	:= num_byte_v+1;
				  addr_mem_rw	:= std_logic_vector (unsigned(addr_mem_rw) +1);
			  else 
			   num_byte_v	:=0;
				state	:= rtnstate;
				main_mem_wr_en (0) <= '0';
				ram_rw_en		:= '0';
			end if;

			when detect_inst =>	 -------------------------------<Detection Instruction>-----------------------------
			  case byte0 is
			  ------------------< MOV AL,BL,CL,DL, number>------------------------
				 when "1011----" =>			-- Mov Al,Num
					 w_reg 	 := byte0 (3);
				    if (w_reg = '1') then num_byte := 2; else num_byte := 1; end if; -- parameter is byte or word
					 reg1_t	 := byte0 (2 downto 0);  -- dest reg is AL
					 state 	 := READ_BYTE;
					 d_reg    := '1';
					 sub_state:= mover;
					 rtnstate := set_reg_h;

			-----------------<Intrrupt>---------------------
				 when x"CD" =>		-- intrrupt
					 num_byte := 1;
				    state 	:= READ_BYTE;
				    rtnstate	:= intrrupt;
			-----------------<ADD>---------------------
				 when "0000010-" =>	--0x04 0x05   -- Add Al,AX <- num
					 w_reg 	 := byte0 (0);
				    if (w_reg = '1') then num_byte := 2; else num_byte := 1; end if; -- parameter is byte or word
					 reg1_t	:= iAx;  -- dest reg is AL or AX (depend w_reg)
					 state 	:= READ_BYTE;
					 d_reg := '1';
					 sub_state := adder;
					 rtnstate := set_reg_h;
					 
				 when "000000--"=>	--0x00 0x03   -- Add ABCD L/H/X <- ABCD L/H/X		 
					 W_reg	:= byte0 (0); 
					 D_reg	:= byte0 (1); 
					 num_byte := 1;	-- read Argument Addressing
					 state 	:= READ_BYTE;
					 sub_state := adder;
					 rtnstate := detect_addr; 
					 exstate    := set_reg_h;
			-----------------<ADC>---------------------
				 when "0001010-" =>	--0x14 0x15   -- Adc Al,AX <- num
					 w_reg 	 := byte0 (0);
				    if (w_reg = '1') then num_byte := 2; else num_byte := 1; end if; -- parameter is byte or word
					 reg1_t	:= iAx;  -- dest reg is AL or AX (depend w_reg)
					 state 	:= READ_BYTE;
					 d_reg := '1';
					 sub_state := adcer;
					 rtnstate := set_reg_h;
					 
				 when "000100--"=>	--0x10 0x13   -- Adc ABCD L/H/X <- ABCD L/H/X		 
					 W_reg	:= byte0 (0); 
					 D_reg	:= byte0 (1); 
					 num_byte := 1;	-- read Argument Addressing
					 state 	:= READ_BYTE;
					 sub_state := adcer;
					 rtnstate := detect_addr; 	
					 exstate    := set_reg_h;
					 
			-----------------<SUB>---------------------
				 when "0010110-" =>		 --0x2C 0x2D  -- SUB Al,AX <- num
				 	 w_reg 	 := byte0 (0);
				    if (w_reg = '1') then num_byte := 2; else num_byte := 1; end if; -- parameter is byte or word
					 reg1_t	:= iAx;  -- dest reg is AL or AX (depend w_reg)
					 state 	:= READ_BYTE;
					 d_reg := '1';
					 sub_state := suber;
					 rtnstate := set_reg_h;
								 
				 when "001010--" =>	--0x28 0x2b   -- sub BCD L/H/X <- BCD L/H/X		 
					 W_reg	:= byte0 (0); 
					 D_reg	:= byte0 (1); 
					 num_byte := 1;	-- read Argument Addressing
					 state 	:= READ_BYTE;
					 sub_state := suber;
					 rtnstate := detect_addr; 
					 exstate    := set_reg_h;
					 
			-----------------<SBB>---------------------
				 when "0001110-" =>		 --0x1C 0x1D  -- SUB Al,AX <- num
				 	 w_reg 	 := byte0 (0);
				    if (w_reg = '1') then num_byte := 2; else num_byte := 1; end if; -- parameter is byte or word
					 reg1_t	:= iAx;  -- dest reg is AL or AX (depend w_reg)
					 state 	:= READ_BYTE;
					 d_reg := '1';
					 sub_state := sbber;
					 rtnstate := set_reg_h;
								 
				 when "000110--" =>	--0x18 0x1b   -- sub BCD L/H/X <- BCD L/H/X		 
					 W_reg	:= byte0 (0); 
					 D_reg	:= byte0 (1); 
					 num_byte := 1;	-- read Argument Addressing
					 state 	:= READ_BYTE;
					 sub_state := sbber;
					 rtnstate := detect_addr; 
					 exstate    := set_reg_h;					 
			-----------------<CMP>---------------------
				 when "0011110-" =>		 --0x3C 0x3D  -- CMP Al,AX <- num
				 	 w_reg 	 := byte0 (0);
				    if (w_reg = '1') then num_byte := 2; else num_byte := 1; end if; -- parameter is byte or word
					 reg1_t	:= iAx;  -- dest reg is AL or AX (depend w_reg)
					 state 	:= READ_BYTE;
					 d_reg := '1';
					 sub_state:= suber;
					 rtnstate := set_reg_h;
					 compare  := '1';
								 
				 when "001110--" =>	--0x38 0x3b   -- CMP BCD L/H/X <- BCD L/H/X		 
					 W_reg	:= byte0 (0); 
					 D_reg	:= byte0 (1); 
					 num_byte := 1;	-- read Argument Addressing
					 state 	:= READ_BYTE;
					 sub_state := suber;
					 rtnstate := detect_addr; 
					 exstate    := set_reg_h;	
					 compare  := '1';
			-----------------<AND>---------------------
				when "0010010-" =>	--0x24 0x25   -- And Al,AX <- num
					 w_reg 	 := byte0 (0);
				    if (w_reg = '1') then num_byte := 2; else num_byte := 1; end if; -- parameter is byte or word
					 reg1_t	:= iAx;  -- dest reg is AL or AX (depend w_reg)
					 d_reg := '1';
					 sub_state := ander;
					 rtnstate := set_reg_h;
					 
				 when "001000--" =>	--0x20 0x23   -- And BCD L/H/X <- BCD L/H/X		 
					 W_reg	:= byte0 (0); 
					 D_reg	:= byte0 (1); 
					 num_byte := 1;	-- read Argument Addressing
					 state 	:= READ_BYTE;
					 rtnstate := detect_addr; 
					 exstate    := set_reg_h;
					 sub_state := ander;
					 
			-----------------<Test>---------------------
				when "1010100-" =>	--0xA8 0xA9   -- TEST Al,AX <- num
					 w_reg 	 := byte0 (0);
				    if (w_reg = '1') then num_byte := 2; else num_byte := 1; end if; -- parameter is byte or word
					 reg1_t	:= iAx;  -- dest reg is AL or AX (depend w_reg)
					 d_reg := '1';
					 sub_state := ander;
					 rtnstate := set_reg_h;
					 compare  := '1';
					 
				 when "1000010-" =>	--0x84 0x85   -- Test BCD L/H/X <- BCD L/H/X		 
					 W_reg	:= byte0 (0); 
					 D_reg	:= byte0 (1); 
					 num_byte := 1;	-- read Argument Addressing
					 state 	:= READ_BYTE;
					 rtnstate := detect_addr; 
					 exstate    := set_reg_h;
					 sub_state := ander;			
					 compare  := '1';
					 
			-----------------<XOR>---------------------
				when "0011010-" =>	--0x34 0x35   -- And Al,AX <- num
					 w_reg 	 := byte0 (0);
				    if (w_reg = '1') then num_byte := 2; else num_byte := 1; end if; -- parameter is byte or word
					 reg1_t	:= iAx;  -- dest reg is AL or AX (depend w_reg)
					 d_reg := '1';
					 sub_state := xorer;
					 rtnstate := set_reg_h;
					 
				 when "001100--" =>	--0x30 0x33   -- And BCD L/H/X <- BCD L/H/X		 
					 W_reg	:= byte0 (0); 
					 D_reg	:= byte0 (1); 
					 num_byte := 1;	-- read Argument Addressing
					 state 	:= READ_BYTE;
					 rtnstate := detect_addr; 
					 exstate    := set_reg_h;
					 sub_state := xorer;
					 
			-----------------<CALL>---------------------
				when x"E8" =>	 -- CALL (2byte parameter - show offset of routin from current IP) - should push next IP	 
					 num_byte := 2;	-- read Argument Addressing
					 w_reg := '1';
					 state 	:= READ_BYTE;
					 rtnstate := CALL;
					 
		 -----------------<INC>---------------------
				when "01000---" =>	--0x40 0x47   -- inc AX,BX,CX,DX,SP,BP,SI,DI
					 w_reg 	 := '1'; -- it is for ax,bx,cx,dx,sp,bp,si,di
					 reg1_t	:= byte0(2 downto 0);  -- dest reg is AL or AX (depend w_reg)
					 sub_state := incer;
					 state 	  := set_reg_h;
					 
			-----------------<DEC>---------------------
				when "01001---" =>	--0x48 0x4f   -- dec AX,BX,CX,DX,SP,BP,SI,DI
					 w_reg 	 := '1'; -- it is for ax,bx,cx,dx,sp,bp,si,di
					 reg1_t	:= byte0(2 downto 0);  -- dest reg is AL or AX (depend w_reg)
					 sub_state := decer;
					 state 	  := set_reg_h;				 
					 
		 -----------------<PUSH>---------------------
				when "01010---" =>	--0x50 0x57   -- PUSH AX,BX,CX,DX,SP,BP,SI,DI
					 w_reg 	  := '1'; -- it is for ax,bx,cx,dx,sp,bp,si,di
					 d_reg     := '0';
					 reg1_t	  := byte0(2 downto 0);  -- dest reg
					 sub_state := pusher;
					 state 	  := set_reg_h;
					 				
		-----------------<POP>---------------------
				when "01011---" =>	--058 0x5f   -- POP AX,BX,CX,DX,SP,BP,SI,DI
					 w_reg 	   := '1'; -- it is for ax,bx,cx,dx,sp,bp,si,di
					 d_reg      := '1';
					 num_byte   := 2;
					 reg1_t	   := byte0(2 downto 0);  -- dest reg
 					 sub_state  := poper;
					 ram_rw_en	:= '1';
					 state	   := read_byte;
					 addr_mem_rw:= SP;
					 rtnstate	:= detect_operate;
					 
				when x"8F" => -- POP Ev 
				  d_reg 		:= '0'; 
				  w_reg 		:= '1';
				  num_byte  := 1;
				  ram_rw_en	:= '1';
				  addr_mem_rw:= SP;
				  state	   := read_byte;
				  rtnstate 	:= POP; 
				  
	----------------------<CONDITIONAL JUMP>------------------------
				when "0111----" =>	-- x70 x7f
					w_reg := '0';
					state := cond_jump;

					 
			---------------<GRP1>---------------------
				when "100000--" =>		  -- 0x80 to 0x83 -- ADD,OR,ADC,SBB,AND,SUB,XOR,CMP * BL,CL,DL <- 1B
					 W_reg	:= byte0 (0); 
					 s_reg	:= byte0 (1);
					 num_byte := 1;	-- read Argument Addressing
					 state 	:= READ_BYTE;
					 rtnstate := detect_gpr1;	
					 
			---------------<NOP>---------------------	
				when x"90" => -- NOP
					state := next_byte;
					
			---------------<CBW>---------------------	
				when x"98" => -- CBW
					if (AL(7) = '1') then
						AH := x"ff";
					else
					   AH := x"00";
					end if;
					
			---------------<CWD>---------------------	
				when x"99" => -- CWD
					if (AH(7) = '1') then
						DX := x"ffff";
					else
					   DX := x"0000";
					end if;	
					
					
			---------------<PUSHF>---------------------	
				when x"9C" => -- PUSH Flag reg
					 w_reg 	  := '1'; -- because only word can push
					 d_reg     := '0';
					 byte1	  := x"00";	-- void and no work
					 byte0	  := flag;
					 sub_state := pusher;
					 state 	  := detect_operate;
					 
			---------------<POPF>---------------------	
				when x"9D" => -- POP Flag reg
					 num_byte   := 2;
					 ram_rw_en	:= '1';
					 state	   := read_byte;
					 addr_mem_rw:= SP;
					 rtnstate	:= POPF;
					 
			----------------------<MOV AX>----------------------
				when "1010000-" => -- 0xA0 0xA1 (e.g. MOV al,[41h])
					 w_reg := byte0(0); -- word or byte
					 d_reg := '1'; -- mem to reg
					 num_byte:= 2; -- the paramete is address memory (2byte)
					 state := read_byte;
					 rm_t := "110"; -- immediate (const) address memory --use in read_addr_mem block
					 m_reg := "00";
					 rtnstate := read_addr_mem;
					 sub_state := mover;
					 exstate := detect_operate;
					 
				when "1010001-" => -- 0xA2 0xA3 (e.g. mov [43h],ax)
					 w_reg := byte0(0); -- word or byte
					 d_reg := '0'; -- reg to mem
					 num_byte:= 2; -- the paramete is address memory (2byte)
					 state := read_byte;
					 rm_t := "110"; -- immediate (const) address memory --use in read_addr_mem block
					 m_reg := "00";
					 rtnstate := read_addr_mem;
					 sub_state := mover;
					 reg1_t := iAX;
					 exstate := set_reg_h;
			-----------------------<MOVS>-----------------------
				when "1010010-" =>	--0xA4 0xA5 -- MOVS BW
					if (repz_en = '1') then
						if (cx /= zeros_16) then IP:=std_logic_vector(unsigned(IP) - 2); cx:=std_logic_vector (unsigned (cx) - 1); bool:='1'; else bool:='0'; end if;
						repz_en := '0';
					else bool := '1'; end if;
					if (bool = '1') then
						w_reg := byte0(0);
						if (w_reg = '1') then num_byte := 2; else num_byte := 1; end if;
						ram_rw_en	:= '1';
						addr_mem_rw := std_logic_vector (resize (unsigned (DS&SI),16)); -- source
						if (flag(7) = '0')then SI := std_logic_vector (unsigned (SI) + num_byte); else SI:= std_logic_vector (unsigned (SI) - num_byte);end if;
						state	      := read_byte;
						rtnstate    := MOVS;
					else state:=next_byte;
					end if;

			-----------------------<CMPS>-----------------------
				when "1010011-" =>	--0xA6 0xA7 -- CMPS BW
					if (repz_en = '1') then
						if (cx /= zeros_16) then cx:=std_logic_vector (unsigned (cx) - 1); bool:='1'; else bool:='0'; end if;
					else bool := '1'; end if;
					if (bool = '1') then
						w_reg := byte0(0);
						if (w_reg = '1') then num_byte := 2; else num_byte := 1; end if;
						ram_rw_en	:= '1';
						addr_mem_rw := std_logic_vector (resize (unsigned (DS&SI),16)); -- source
						if (flag(7) = '0')then SI := std_logic_vector (unsigned (SI) + num_byte); else SI:= std_logic_vector (unsigned (SI) - num_byte);end if;
						state	      := read_byte;
						rtnstate    := CMPS;
						exstate		:= REP;
					else state:=next_byte;
					end if;
			-----------------------<STOS>-----------------------
				when "1010101-" =>	--0xAA 0xAB -- STOSB
					if (repz_en = '1') then
						if (cx /= zeros_16) then IP:=std_logic_vector(unsigned(IP) - 2); cx:=std_logic_vector (unsigned (cx) - 1); bool:='1'; else bool:='0'; end if;
						repz_en := '0';
					else bool := '1'; end if;
					if (bool = '1') then
						w_reg := byte0(0);
						byte0 := AL;
						byte1 := AH;
						if (w_reg = '1') then num_byte := 2; else num_byte := 1; end if;
						ram_rw_en	:= '1';
						addr_mem_rw := std_logic_vector (resize (unsigned (ES&DI),16));
						addr_mem_rw	:= std_logic_vector (unsigned (addr_mem_rw) - 1); -- default to Write
						if (flag(7) = '0')then DI := std_logic_vector (unsigned (DI) + num_byte); else DI:= std_logic_vector (unsigned (DI) - num_byte);end if;
						state	      := Write_byte; 
						rtnstate    := next_byte;
					else state:=next_byte;
					end if;
			-----------------------<LODS>-----------------------
				when "1010110-" =>	--0xAC 0xAD-- LODS BW
					if (repz_en = '1') then
						if (cx /= zeros_16) then IP:=std_logic_vector(unsigned(IP) - 2); cx:=std_logic_vector (unsigned (cx) - 1); bool:='1'; else bool:='0'; end if;
						repz_en := '0';
					else bool := '1'; end if;
					if (bool = '1') then
						w_reg 	   := byte0(0); -- byte
						d_reg      := '1'; 
						if (w_reg = '1') then num_byte := 2; else num_byte := 1; end if;
						reg1_t	   := iAL;  -- dest reg AX = AL (depend w_reg)
						sub_state  := mover;
						ram_rw_en	:= '1';
						state	   := read_byte;
						addr_mem_rw:= std_logic_vector (resize (unsigned (DS&SI),16));
						if (flag(7) = '0')then SI := std_logic_vector (unsigned (SI) + num_byte); else SI:= std_logic_vector (unsigned (SI) - num_byte);end if;
						rtnstate	:= detect_operate;
					else state:=next_byte;
					end if;
			-----------------------<SCAN>-----------------------
				when "1010111-" =>	--0xAE 0xAF-- SCAS BW
					if (repz_en = '1') then
						if (cx /= zeros_16) then cx:=std_logic_vector (unsigned (cx) - 1); bool:='1'; else bool:='0'; end if;
					else bool := '1'; end if;
					if (bool = '1') then
						w_reg	:= byte0 (0); 
						if (w_reg = '1') then num_byte := 2; else num_byte := 1; end if;
						reg_h (15 downto 0) := AX;
						ram_rw_en	:= '1';
						 addr_mem_rw := std_logic_vector (resize (unsigned (ES&DI),16));
						if (flag(7) = '0')then DI := std_logic_vector (unsigned (DI) + num_byte); else DI:= std_logic_vector (unsigned (DI) - num_byte);end if;
						state 	:= READ_BYTE;
						rtnstate := COMP;
					else state:=next_byte;
					end if;
			---------------<GRP4  - DEC INC>---------------------
				when x"FE" =>		  -- 0xFE  DEC.INC al,bl,cl,dl
					 W_reg	:= '0'; -- only byte
					 d_reg := '1';
					 num_byte := 1;	-- read Argument Addressing
					 state 	:= READ_BYTE;
					 rtnstate := detect_gpr4;
					 
			-----------------<GRP5 >---------------------
				when x"FF" =>		  -- 0xFF  INC - DEC - CALL -CALL -JMP -JMP(Mp) -PUSH
					 num_byte := 1;	-- read Argument Addressing
					 state 	:= READ_BYTE;
					 rtnstate := detect_gpr5;		
			-------------------<MOV reg to reg>----------------------
				when "100010--" =>		  -- 0x88 to 0x8B  -- MOV reg to reg (e.g. mov bl,cl)
					 W_reg	:= byte0 (0); 
					 D_reg	:= byte0 (1); 
					 num_byte := 1;	-- read Argument Addressing
					 state 	:= READ_BYTE;
					 sub_state := mover;
					 rtnstate  := detect_addr;
					 exstate    := set_reg_h;
					 
			---------------------<RET>----------------------
				when x"C3" =>		 -- RET
					 num_byte 	   := 2;
					 addr_mem_rw:= SP;
					 ram_rw_en	:= '1';
					 state	   := read_byte;
					 rtnstate	:= RET;					 

			-------------------<MOV const to const>----------------------
				when "1100011-" =>		  -- 0xC6 to 0xC7  -- MOV const to const (e.g. mov [21h],67h)
					 W_reg	:= byte0 (0); 
				    num_byte := 1;  -- parameter is byte
					 d_reg := '0';
					 state 	:= READ_BYTE;
					 rtnstate := const_to_mem;	
--					 exstate	 := Assign;

		 -----------------<JMP>---------------------
				when x"EB" =>	 -- jmp	 
					 num_byte := 1;	-- read Argument Addressing
					 w_reg := '0';
					 state 	:= READ_BYTE;
					 rtnstate := jump; 
					 
		 -----------------<LOOP>---------------------
			 when "111000--" =>	 -- E0 E3 -- LOOPNZ - LOOPZ - LOOP
					 cx := std_logic_vector (unsigned (cx)-1);
					 case byte0(1 downto 0) is
						when "00" => if (cx /= zeros_16 and flag(1) = '0') then bool := '1'; else bool := '0'; end if; -- LOOPNZ
						when "01" => if (cx /= zeros_16 and flag(1) = '1') then bool := '1'; else bool := '0'; end if; -- LOOPZ
						when "10" => if (cx /= zeros_16)						   then bool := '1'; else bool := '0'; end if; -- LOOP
						when "11" => if (cx  = zeros_16)					      then bool := '1'; else bool := '0'; end if; -- JCXZ
						when others => null;
					 end case;
					 if (bool = '1') then
						 num_byte := 1;	
						 w_reg := '0';
						 state 	:= READ_BYTE;
						 rtnstate := jump; 
					 else
						 IP	:= std_logic_vector (unsigned (IP)+1); 
						 state:= next_byte;
					 end if;	
					 
				
			-------------------<REP>----------------------
				when x"F2" =>	 -- REP (REPNZ - REPNE)
					 repnz_en := '1';
					 state := next_byte;
				when x"F3" =>	 -- REP (REPZ - REPE)
					 repz_en := '1';
					 state := next_byte;

					 
			-------------------<MOV reg to reg>----------------------
				when x"F4" =>	 -- halted (stop cpu)
					 state := halt;
					 
			-------------------<CLC - Clear Carry>----------------------
				when x"F5" =>	 -- CMC - Clear Carry
					 flag(0) := not flag(0);
					 state := next_byte;
				when x"F8" =>	 -- CLC - Clear Carry
					 flag(0) := '0';
					 state := next_byte;
				when x"F9" =>	-- STC - Set Carry
					 flag(0) := '1';
					 state := next_byte;
				when x"FA" =>	-- CLI - Clear Interrupt
					 flag(6) := '0';
					 state := next_byte;
				when x"FB" =>	-- STI - Set Interrupt
					 flag(6) := '1';
					 state := next_byte;
				when x"FC" =>	-- CLD - Clear Direction
					 flag(7) := '0';
					 state := next_byte;
				when x"FD" =>	-- STD - Set Direction
					 flag(7) := '1';
					 state := next_byte;
					 
				when others =>
					num_byte := 1;
				   state 	:= READ_BYTE;
				   rtnstate := detect_inst;
				end case;
				val_const_bit := '0';

			when INTRRUPT =>     ----------------------------------------<INTRRUPT>-------------------------------
				case byte0 is
					 when x"63" =>		-- int LED
							LED_v := AL(3 downto 0);
							state 	:= Next_Byte;
					  when x"21" => -- int 21h
							case AX(15 downto 8) is
								when x"02" => -- show char
									char <= DX(6 downto 0);
--									LED_v := DX(3 downto 0);
									state := show_char;
									rtnstate:= next_byte;
								when others => state 	:= Next_Byte;
							end case;
							
							
					  when others => state 	:= Next_Byte;
			   end case;
				 				 
			when const_to_mem =>	 ----------------------------------------<const_to_mem>-------------------------------
				m_reg    := m_reg_0;
				rm_t     := byte0 (2 downto 0); 
				reg_t    := byte0 (5 downto 3); 
				reg1_t   := reg_t;
				
			  if (m_reg = "00" and rm_t = "110") then  num_byte := 2; else num_byte := to_integer (unsigned (m_reg));end if; -- direct address memory	
			  if (w_reg = '1') then num_byte := num_byte +2; else num_byte := num_byte +1; end if;
			  state 			 := read_byte;
			  rtnstate 		 := read_addr_mem;  -- calculate new address (adress with offset) and read value
			  exstate 		 := detect_operate;   -- it go to write_byte block finaly 
			  val_const_bit := '1';
				 
			when detect_addr =>	----------------------------------------<detect_addr>-------------------------------
				m_reg := m_reg_0;
				if (m_reg = "11" ) then 
					reg_t := byte0 (2 downto 0); -- in this case reg_t and rm_t is Displaced (in 8086 instruction) = source
					rm_t := byte0 (5 downto 3); -- = destination
					reg1_t := rm_t;				  -- (2 downto 0)  (e.g.: 11 000 001 CL -> AL)
					state    := set_val_reg;	-- read reg_t val 
					rtnstate := set_reg_h;		-- read reg1_t val
				else	
				
				 rm_t     := byte0 (2 downto 0); 
				 reg_t    := byte0 (5 downto 3); 
				 reg1_t   := reg_t;
			    if (m_reg = "00" and rm_t = "110") then  num_byte := 2; else num_byte := to_integer (unsigned (m_reg));end if; -- direct address memory	or no
				 state := read_byte;
				 rtnstate   := read_addr_mem; -- read frome diffrent address (not IP)
--				 exstate    := set_reg_h; -- read frome diffrent address (not IP)
				end if;
				val_const_bit := '0';
				
				
			when read_addr_mem =>	-- read byte from a diffrent address (memory)
				   if (w_reg = '1') then num_byte := 2; else num_byte := 1; end if; -- parameter is byte or word
					case rm_t is	-- (2 downto 0)  (e.g.: 11 000 001 CL -> AL)
						when "000" => addr_mem_rw	 := std_logic_vector (unsigned(BX(8 downto 0))+unsigned(SI(8 downto 0)));
						when "001" => addr_mem_rw	 := std_logic_vector (unsigned(BX(8 downto 0))+unsigned(DI(8 downto 0)));
						when "010" => addr_mem_rw   := std_logic_vector (unsigned(BP(8 downto 0))+unsigned(SI(8 downto 0)));
						when "011" => addr_mem_rw	 := std_logic_vector (unsigned(BP(8 downto 0))+unsigned(DI(8 downto 0)));
						when "100" => addr_mem_rw	 := SI;
						when "101" => addr_mem_rw	 := DI; 
						when "110" => 					if (m_reg = "00") then addr_mem_rw:=(byte1&byte0); else addr_mem_rw := BP;  end if;
						when "111" => addr_mem_rw	 := BX; 
						when others => null;
					end case;
				
					 if (m_reg = "01") then addr_mem_rw := std_logic_vector (unsigned(addr_mem_rw(8 downto 0))+unsigned(byte0));
					 elsif (m_reg = "10") then addr_mem_rw := std_logic_vector (unsigned(addr_mem_rw(8 downto 0))+unsigned(byte1&byte0));
					 end if;
					 
					 ram_rw_en	:= '1';
					 state	:= read_byte;
					 rtnstate:= exstate; 			 

			when set_reg_h =>
				case w_reg&reg1_t (2 downto 0) is	-- (2 downto 0)  (e.g.: 11 000 001 CL -> AL)
					when '1'&iAX => reg_h (7 downto 0)  := AL; reg_h (15 downto 8) := AH;
					when '1'&iBX => reg_h (7 downto 0)  := BL; reg_h (15 downto 8) := BH;
					when '1'&iCX => reg_h (7 downto 0)  := CL; reg_h (15 downto 8) := CH;
					when '1'&iDX => reg_h (7 downto 0)  := DL; reg_h (15 downto 8) := DH;
					when '0'&iAL => reg_h (7 downto 0)  := AL;
					when '0'&iBL => reg_h (7 downto 0)  := BL;
					when '0'&iCL => reg_h (7 downto 0)  := CL;
					when '0'&iDL => reg_h (7 downto 0)  := DL;
					when '0'&iAH => reg_h (7 downto 0)  := AH;
					when '0'&iBH => reg_h (7 downto 0)  := BH;
					when '0'&iCH => reg_h (7 downto 0)  := CH;
					when '0'&iDH => reg_h (7 downto 0)  := DH;
					when others => null;
				end case;	
				   state := detect_operate;
					
					 
			when set_val_reg =>
				case w_reg&reg_t (2 downto 0) is	-- (2 downto 0)  (e.g.: 11 000 001 CL -> AL)
					when '1'&iAX => byte0 := AL; byte1 := AH;
					when '1'&iBX => byte0 := BL; byte1 := BH;
					when '1'&iCX => byte0 := CL; byte1 := CH;
					when '1'&iDX => byte0 := DL; byte1 := DH;
					when '0'&iAL => byte0 := AL;
					when '0'&iBL => byte0 := BL;
					when '0'&iCL => byte0 := CL;
					when '0'&iDL => byte0 := DL;
					when '0'&iAH => byte0 := AH;
					when '0'&iBH => byte0 := BH;
					when '0'&iCH => byte0 := CH;
					when '0'&iDH => byte0 := DH;
					when others => null;
				end case;
				if (m_reg = "11" ) then state := set_reg_h;
				else state := detect_operate;end if;
				
			when Cond_Jump => -- Conditional Jump		
					case byte0 (3 downto 0) is
					 when "0000" => if (flag(3)  = '1') then bool := '1'; else bool := '0'; end if; -- JO  (not appropriate)
					 when "0001" => if (flag(3) /= '1') then bool := '1'; else bool := '0'; end if; -- JNO (not appropriate) 
					 when "0010" => if (flag(0)  = '1' and flag(1) = '0') then bool := '1'; else bool := '0'; end if; -- JB   <  (unsigned)
					 when "0110" => if (flag(0) = '1' or flag(1) = '1') then bool := '1'; else bool := '0'; end if; --LED_V := LED_V or "0010"; -- JBE  <= (unsigned)
					 when "0111" => if (flag(0) = '0'  and flag(1)  = '0') then bool := '1'; else bool := '0'; end if; -- JA  >  (unsigned)
					 when "0011" => if (flag(0)  = '0' or  flag(1) = '1') then bool := '1'; else bool := '0'; end if; -- JAE  >= (unsigned)
					 when "0100" => if (flag(1)  = '1') then bool := '1'; else bool := '0'; end if; -- JZ (not appropriate)
					 when "0101" => if (flag(1)  = '0') then bool := '1'; else bool := '0'; end if; -- JNZ (not appropriate)
					 when "1000" => if (flag(2)  = '1') then bool := '1'; else bool := '0'; end if; -- JS (not appropriate)
					 when "1001" => if (flag(2) = '0')  then bool := '1'; else bool := '0'; end if; -- JNS (not appropriate)
					 when "1010" => if (flag(4) = '1')then bool := '1'; else bool := '0'; end if; -- JPE (not appropriate)
					 when "1011" => if (flag(4) = '0')then bool := '1'; else bool := '0'; end if; -- JPO (JNP) (not appropriate)
					 when "1100" => if ((flag(2) /= flag(3)) and (flag(1)  = '1')) then bool := '1'; else bool := '0'; end if; -- JL  (signed)
					 when "1101" => if ((flag(2)  = flag(3)) or  (flag(1)  = '1')) then bool := '1'; else bool := '0'; end if; -- JGE (signed)
					 when "1110" => if ((flag(2) /= flag(3)) or  (flag(1)  = '1')) then bool := '1'; else bool := '0'; end if; -- JLE (signed)
					 when "1111" => if ((flag(2)  = flag(3)) and (flag(1)  = '0')) then bool := '1'; else bool := '0'; end if; -- JG  (signed)
					 when others => null;
					end case;
				if (bool = '1') then 
				  num_byte := 1;
				  state := read_byte;
				  rtnstate := jump;
				else
					IP	  := std_logic_vector (unsigned (IP)+1);
					state := next_byte;
				end if;		

			
			when Jump => 	-----------------------------------------<Jump>-----------------------------
				if (w_reg = '0') then -- sign
					if (byte0 (7) = '1' ) then byte1 := x"ff"; else byte1 := x"00"; end if;
				end if;
				IP	:= std_logic_vector (unsigned (IP) + unsigned(byte1&byte0));
				state := next_byte;
				
			when Call => 	-------------------------------------<Call>-------------------------------------
				d_reg := '0'; -- write to mem
				addr_mem_rw := IP;
				IP	:= std_logic_vector (unsigned (IP) + unsigned (byte1&byte0));
				byte1 := (others => '0');
				byte0	:= addr_mem_rw(7 downto 0);
				byte1 := std_logic_vector (resize (unsigned (addr_mem_rw(NUMBER_MEMORY_BIT'length-1 downto 8)),8)); -- NOW it is 1 bit because Memory address is 9 bit
				state := detect_operate;
				sub_state := pusher;		
				cheng_reg_h_byte := '1'; -- to write in mem (detect_operare Block)
			
				
			when RET => ----------------------------<RET>--------------------------------
				SP := std_logic_vector (unsigned (SP)+2);
				IP := (byte1&byte0);
				state := next_byte;
				
			when POP  => --------------------<POP Ev>--------------------------
				reg_h (15 downto 0) := byte1&byte0;
				SP := std_logic_vector (unsigned (SP)+2);
				num_byte := 1;
				state 	:= read_byte;
				sub_state:= mover; -- void and it dont work (because d_reg=0)
				rtnstate := detect_addr;
				exstate  := detect_operate;
				
			when POPF => -------------------------<POP Flag>----------------------
				flag := byte0;
				SP := std_logic_vector (unsigned (SP)+2);
				state := next_byte;
				
			when MOVS => ----------------------------------<Mov String>----------------
				   if (w_reg = '1') then num_byte := 2; else num_byte := 1; end if;
					ram_rw_en	:= '1';
					addr_mem_rw := std_logic_vector (resize (unsigned (ES&DI),16)); -- dest
					addr_mem_rw	:= std_logic_vector (unsigned (addr_mem_rw) - 1); -- default to Write
					if (flag(7) = '0')then DI := std_logic_vector (unsigned (DI) + num_byte); else DI:= std_logic_vector (unsigned (DI) - num_byte);end if;
					state	      := Write_byte;
					rtnstate    := next_byte;
					
			when CMPS => ----------------------------------<CMP String>----------------
					reg_h(15 downto 0) := byte1&byte0;
				   if (w_reg = '1') then num_byte := 2; else num_byte := 1; end if;
					ram_rw_en	:= '1';
					addr_mem_rw := std_logic_vector (resize (unsigned (ES&DI),16)); -- dest
					if (flag(7) = '0')then DI := std_logic_vector (unsigned (DI) + num_byte); else DI:= std_logic_vector (unsigned (DI) - num_byte);end if;
					state	      := read_byte;					
					rtnstate 	:= COMP; 
					
			when COMP =>	--------------------------<Compare>------------------
					if (w_reg = '0') then
						flag(0) := reg_h (7) xor byte0 (7);	
						reg_h (8 downto 0) := std_logic_vector (unsigned(reg_h(7 downto 0))-unsigned(byte0));
						flag(0) :=  flag(0) xor reg_h (8);	
						flag(3) := reg_h (8) xor reg_h (7);
						if (reg_h (7) = '1') then flag(2) := '1'; else flag(2) := '0'; end if;
						if (reg_h (7 downto 0) = "00000000") then flag(1) := '1'; else flag(1) := '0'; end if; 
				  else
						flag(0) := reg_h (15) xor byte1 (7);	
						reg_h (16 downto 0) := std_logic_vector (unsigned(reg_h (15 downto 0))-unsigned(byte1&byte0));
						flag(0) := flag(0) xor reg_h (16);	
						flag(3) := reg_h (16) xor reg_h (15);
						if (reg_h (15) = '1') then flag(2) := '1'; else flag(2) := '0'; end if;
						if (reg_h (15 downto 0) = zeros_16) then flag(1) := '1'; else flag(1) := '0'; end if; 
					end if;					
				   state := exstate;
			 		
			when REP =>
				if (repz_en = '1') then
					if (flag(1) = '1') then
					   repz_en := '0';
						IP	:= std_logic_vector (unsigned (IP) -2);
					end if;
				elsif (repnz_en = '1') then
					if (flag(1) = '0') then
						repnz_en:= '0';
						IP	:= std_logic_vector (unsigned (IP) -2);
					end if;
				end if;
				state := next_byte;
				
			when show_char => -------------------<Show char>----------------------
					Xchar	<= std_logic_vector (unsigned(Xchar)+1);
					if (Xchar = "1010000") then
						Xchar	<= (others => '0');
						Ychar	<= std_logic_vector (unsigned(Ychar)+1);
					end if;
					state := rtnstate;
					
		   when detect_gpr1 =>    -----------------------------------<detect_gpr1>-------------------------------
			 byte1 := x"00";
				case byte0 (5 downto 3) is -- show operate
				  when "000" => -- ADD
						sub_state := adder;
				  when "001" => -- OR
						sub_state := orer;
					when "100" => -- AND
						sub_state := ander;
					when "101" => -- SUB
						sub_state := suber;
					when "111" => -- CMP
						sub_state := suber;
						compare := '1';
				  when others => null;
				end case;
					
			  if (m_reg_0 = "00") then -- const to const (e.g. add [60h],2)
				  d_reg := '0';
				  state := const_to_mem;
--				  sub_state:= adder;
			  else -- Certainly it is num to reg (e.g. add bl,2)
			   if ((NOT s_reg and w_reg) = '1') then num_byte := 2; else num_byte := 1; end if;
				d_reg := '1';
				state := Read_Byte;
				rtnstate := set_reg_h;
			  end if;

		   when detect_gpr4 =>    -----------------------------------<detect_gpr4>-------------------------------
				case byte0 (5 downto 3) is -- show operate
				  when "000" => -- INC
						sub_state := incer;
				  when "001" => -- DEC
						sub_state := decer;
				  when others => null;
				end case;
				
				if (m_reg_0 = "11" )then d_reg := '1'; else d_reg := '0'; end if; 
				  w_reg := '0';
				  state 	   := detect_addr; 
				  cheng_reg_h_byte	:= '1';

				  when detect_gpr5 =>    -----------------------------------<detect_gpr5>-------------------------------
				case byte0 (5 downto 3) is -- show operate
				  when "110" => -- PUSH
						sub_state := pusher;
				  when others => null;
				end case;
				
				if (m_reg_0 = "11" )then d_reg := '1'; else d_reg := '0'; end if;
				  w_reg := '1';
				  state 	   := detect_addr; 
				  exstate := detect_operate;
				  cheng_reg_h_byte	:= '1';
			  
			when Next_Byte =>		---------------------------<init read Next Byte>------------------------------
				num_byte := 1;	-- it has 1 parameter so read one byte
				byte0 := x"00"; byte1 := x"00"; byte2 := x"00";byte3 := x"00";
				state 	:= READ_BYTE;
				rtnstate := Detect_Inst;
				
			 when detect_operate =>	-------------------------------<detect_operate>--------------------
			 	if (val_const_bit = '1') then 
					reg_h (15 downto 0) := byte1&byte0; 
				  if (m_reg = "10") then  byte0 := byte2; byte1 := byte3;	elsif (m_reg = "01") then byte0 := byte1; byte1 := byte2; elsif (rm_t = "110")then byte0 := byte2; byte1 := byte3; end if; -- m_reg = "00" -> haven't any offset then byte0 and byte1 are ready now
				end if;
				
				if (cheng_reg_h_byte = '1') then
					reg_h (15 downto 0) := byte1&byte0; 
					cheng_reg_h_byte := '0';
				end if;
				
			 if (w_reg = '0') then
			   flag(0) := reg_h (7) xor byte0 (7);	
			 	case sub_state is
					when adder => reg_h (8 downto 0) := std_logic_vector (resize (unsigned(reg_h(7 downto 0)),9)+resize (unsigned(byte0),9)); -- 1 bit carry_flag
					when incer => reg_h (8 downto 0) := std_logic_vector (resize (unsigned(reg_h(7 downto 0)),9)+1); -- 1 bit carry_flag
					when decer => reg_h (8 downto 0) := std_logic_vector (resize (unsigned(reg_h(7 downto 0)),9)-1); -- 1 bit carry_flag
					when adcer => if (flag(0) = '1') then reg_h (8 downto 0) := std_logic_vector (unsigned(reg_h(7 downto 0))+unsigned(byte0)+1); else reg_h (8 downto 0) := std_logic_vector (unsigned(reg_h(7 downto 0))+unsigned(byte0)); end if;-- 1 bit carry_flag
					when suber => reg_h (8 downto 0) := std_logic_vector (resize (unsigned(reg_h(7 downto 0)),9)-resize (unsigned(byte0),9));
					when sbber => if (flag(0) = '1') then reg_h (8 downto 0) := std_logic_vector (unsigned(reg_h(7 downto 0))-unsigned(byte0)-1); else reg_h (8 downto 0) := std_logic_vector (unsigned(reg_h(7 downto 0))-unsigned(byte0)); end if;-- 1 bit carry_flag
					when muler => reg_h (8 downto 0) := std_logic_vector (unsigned(reg_h(7 downto 0))*unsigned(byte0));
					when ander => reg_h (8 downto 0) := reg_h (7 downto 0) and byte0;
					when xorer => reg_h (8 downto 0) := reg_h (7 downto 0) xor byte0;
					when orer  => reg_h (8 downto 0) := reg_h (7 downto 0) or  byte0;
					when mover => if (d_reg = '1')then reg_h(7 downto 0) := byte0; end if; null;
					when others => null; 
				end case;
				flag(0) :=  flag(0) xor reg_h (8);	
				flag(3) := reg_h (8) xor reg_h (7);
				if (reg_h (7) = '1') then flag(2) := '1'; else flag(2) := '0'; end if;
				if (reg_h (7 downto 0) = "00000000") then flag(1) := '1'; else flag(1) := '0'; end if; 
			else
				flag(0) := reg_h (15) xor byte1 (7);	
			   case sub_state is
			 		when adder  => reg_h (16 downto 0) := std_logic_vector (unsigned(reg_h (15 downto 0))+unsigned(byte1&byte0));
			 		when incer  => reg_h (16 downto 0) := std_logic_vector (unsigned(reg_h (15 downto 0))+1);
			 		when decer  => reg_h (16 downto 0) := std_logic_vector (unsigned(reg_h (15 downto 0))-1);
			 		when adcer  => if (flag(0) = '1' )then reg_h (16 downto 0) := std_logic_vector (unsigned(reg_h (15 downto 0))+unsigned(byte1&byte0)+1); else reg_h (16 downto 0) := std_logic_vector (unsigned(reg_h (15 downto 0))+unsigned(byte1&byte0)); end if;
					when suber  => reg_h (16 downto 0) := std_logic_vector (unsigned(reg_h (15 downto 0))-unsigned(byte1&byte0));
			 		when sbber  => if (flag(0) = '1' )then reg_h (16 downto 0) := std_logic_vector (unsigned(reg_h (15 downto 0))-unsigned(byte1&byte0)-1); else reg_h (16 downto 0) := std_logic_vector (unsigned(reg_h (15 downto 0))-unsigned(byte1&byte0)); end if;
					when muler  => reg_h (16 downto 0) := std_logic_vector (unsigned(reg_h (15 downto 0))*unsigned(byte1&byte0));
					when ander  => reg_h (16 downto 0) := reg_h (15 downto 0) and (byte1&byte0);
					when xorer  => reg_h (16 downto 0) := reg_h (15 downto 0) xor (byte1&byte0);
					when orer   => reg_h (16 downto 0) := reg_h (15 downto 0) or  (byte1&byte0);
					when pusher =>  addr_mem_rw := SP; SP := std_logic_vector (unsigned (SP)-2); -- in belw lines num_byte less addr_mem_rw so 2 less addr_mem_rw so we dont dec 2 from SP  
					when poper  =>  SP := std_logic_vector (unsigned (SP)+2); reg_h (15 downto 0) := byte1&byte0;
					when mover => if (d_reg = '1')then reg_h (15 downto 0) := byte1&byte0; end if; null;
					when others => null;
				end case;	 
				flag(0) := flag(0) xor reg_h (16);	
				flag(3) := reg_h (16) xor reg_h (15);
				if (reg_h (15) = '1') then flag(2) := '1'; else flag(2) := '0'; end if;
				if (reg_h (15 downto 0) = zeros_16) then flag(1) := '1'; else flag(1) := '0'; end if; 
			 end if;
			 
			state 	:= Next_Byte;	

 
			if (compare = '0') then
			byte0 := reg_h(7 downto 0); byte1:= reg_h(15 downto 8); 
			if (d_reg = '0') then
				if (w_reg = '1') then num_byte := 2; else num_byte := 1; end if; -- parameter is byte or word
				ram_rw_en	:= '1';
				addr_mem_rw	:= std_logic_vector (unsigned (addr_mem_rw)-num_byte-1);	-- possetive -1 for : default for writting - num_byte : because addr_mem_rw added when reading byte or word in Previously block (read_addr_mem block)
				state       := write_byte;
				rtnstate	   := next_byte;
					
			 else
				case w_reg&reg1_t is
					when '1'&iAX => AX := reg_h (15 downto 0);
					when '1'&iBX => BX := reg_h (15 downto 0);
					when '1'&iCX => CX := reg_h (15 downto 0);
					when '1'&iDX => DX := reg_h (15 downto 0);
					when '1'&iSP => SP := reg_h (15 downto 0);
					when '1'&iBP => BP := reg_h (15 downto 0);
					when '1'&iSI => SI := reg_h (15 downto 0);
					when '1'&iDI => DI := reg_h (15 downto 0);
					when '0'&iAL => AL := reg_h (7 downto 0);
					when '0'&iBL => BL := reg_h (7 downto 0);
					when '0'&iCL => CL := reg_h (7 downto 0);
					when '0'&iDL => DL := reg_h (7 downto 0);
					when '0'&iAH => AH := reg_h (15 downto 8);
					when '0'&iBH => BH := reg_h (15 downto 8);
					when '0'&iCH => CH := reg_h (15 downto 8);
					when '0'&iDH => DH := reg_h (15 downto 8);
					when others => null;
				end case;	
			end if;
			end if;
		compare := '0';
			
			when halt =>
			  null;
			  
			when Init =>	----------------------------------------------<Init>--------------------------------
			  cnt_bit := 512;	-- Read 512 Byte (1 sector)
			  main_mem_wr_en (0) <= '1';
			  num_byte	:= 1;		-- read 1 byte from sd to ram (main memory)
			  state := Read_Sector;
			  IP := (others => '1'); -- because in "Read_Sector" Block it inc 1 and then become 0000 to write first block ram else it write in secound ram's block
			  num_byte_v	:=0;
			  ram_rw_en := '0';
			  d_reg := '1';
			  flag := "00000000";
			  SP	:= x"FFFE"; -- (0-2)
			  
			when Read_Sector =>	-- read First Sector of SD Card (512 byte)----------------------<Read_Sector>-----------
			  if (sd_c_hndShk = '1') then
					if (cnt_bit /= 0) then
					  main_mem_data_in <= sd_data_out;
					  sd_h_hndShk <= '1';
					  cnt_bit	:= cnt_bit - 1;
				     IP := std_logic_vector (unsigned (IP) + 1);
					 else
					  main_mem_wr_en (0) <= '0';
					  state	:= Read_Byte;
					  rtnstate	:= detect_inst;
					  IP := (others => '0');
					  end if;
		     else
			   sd_h_hndShk <= '0'; 
		    end if;
		  end case;
		  if (ram_rw_en = '0') then 
		  	main_mem_addr	 <= IP(NUMBER_MEMORY_BIT'length-1 downto 0); else main_mem_addr<=addr_mem_rw(NUMBER_MEMORY_BIT'length-1 downto 0); end if;
		  	LED	<= LED_v;
		 end if;
		end if;
	end process;
	
	process (clk_i)
	begin
	if rising_edge (clk_i) then
	
	ClockPulse	<= std_logic_vector (unsigned (ClockPulse)+1);
	 if (ClockPulse = "1111111111111111") then
	   CLKPorcessor	<= not CLKPorcessor;
	 end if;
	end if;
	end process;
	
	NOTreset_i <= not reset_i;
	
	
--		  process (clk_i)
--		  	 variable CounterTime : std_logic_vector (19 downto 0):= (others => '0');
--	  begin
--	  if rising_edge (clk_i) then
--	  CounterTime	:= std_logic_vector (unsigned(CounterTime) + 1);
--	    if (CounterTime = "00000000000000000000") then
--	    end if;
--	  end if;
--	  end process;
	  
end Behavioral;
---------------NEW 