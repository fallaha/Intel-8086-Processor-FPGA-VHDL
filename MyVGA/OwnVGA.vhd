library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

--use IEEE.STD_LOGIC_UNSIGNED.ALL;
use ieee.numeric_std.all;

entity MyVGA is
  port ( CLK_50MHz: in std_logic;
         VS: out std_logic;
			HS: out std_logic;
			RED: out std_logic;
			GREEN: out std_logic;
			BLUE: out std_logic
  );
end MyVGA;

architecture Behavioral of MyVGA is
  -- VGA Definitions starts
  constant HDisplayArea: integer:= 640; -- horizontal display area
  constant HLimit: integer:= 800; -- maximum horizontal amount (limit)
  constant HFrontPorch: integer:= 16; -- h. front porch
  constant HBackPorch: integer:= 48;	-- h. back porch
  constant HSyncWidth: integer:= 96;	-- h. pulse width
  
  constant VDisplayArea: integer:= 480; -- vertical display area
  constant VLimit: integer:= 525; -- maximum vertical amount (limit)
  constant VFrontPorch: integer:= 10;	-- v. front porch
  constant VBackPorch: integer:= 33;	-- v. back porch
  constant VSyncWidth: integer:= 2;	-- v. pulse width  
    
  signal Clk_25MHz: std_logic := '0';  
  signal HBlank, VBlank, Blank: std_logic := '0';
    
	 
  signal CurrentHPos: std_logic_vector(10 downto 0) := (others => '0'); -- goes to 1100100000 = 800
  signal CurrentVPos: std_logic_vector(10 downto 0) := (others => '0'); -- goes to 1000001101 = 525
  signal ScanlineX, ScanlineY: std_logic_vector(10 downto 0);
  

  signal ColorOutput: std_logic_vector(2 downto 0);
  -- VGA Definitions end
  
    signal CounterX: std_logic_vector(9 downto 0) := (others => '0'); -- goes to 1100100000 = 680
    signal CounterY: std_logic_vector(8 downto 0) := (others => '0'); -- goes to 1100100000 = 512
	 
	 signal CounterTime : std_logic_vector (19 downto 0):= (others => '0');
	 signal ADDR_ROM :STD_LOGIC_VECTOR(6 DOWNTO 0);
	 signal DATA_OUT_ROM: STD_LOGIC_VECTOR(63 DOWNTO 0);
	
COMPONENT ram
  PORT (
    clka : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(14 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
  );
END COMPONENT;

COMPONENT VGACHAR
  PORT (
    clka : IN STD_LOGIC;
    addra : IN STD_LOGIC_VECTOR(6 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(63 DOWNTO 0)
  );
END COMPONENT;

  
signal WEn : STD_LOGIC_VECTOR(0 DOWNTO 0);
signal VGA_ADDR_RAM :STD_LOGIC_VECTOR(14 DOWNTO 0);
signal VGA_DATA_IN_RAM	:STD_LOGIC_VECTOR(7 DOWNTO 0);
signal VGA_DATA_OUT_RAM: STD_LOGIC_VECTOR(7 DOWNTO 0);

signal Xchar : std_logic_vector(6 downto 0);
signal Ychar : std_logic_vector(4 downto 0);
signal char : std_logic_vector(6 downto 0);
signal Echar : std_logic_vector(6 downto 0) := std_logic_vector(unsigned(char)- x"20");


type Characters is Array (15 downto 0) of std_logic_vector (7 downto 0);
signal ROMchar :Characters;


begin

VGA_RAM : ram
  PORT MAP (
    clka => CLK_50MHz,
    wea => WEn,
    addra => VGA_ADDR_RAM,
    dina => VGA_DATA_IN_RAM,
    douta => VGA_DATA_OUT_RAM
  );
  
  VGA_CHAR : VGACHAR
  PORT MAP (
    clka => CLK_50MHz,
    addra => ADDR_ROM,
    douta => DATA_OUT_ROM
  );
  
  Generate25MHz: process (CLK_50MHz)
  begin
    if rising_edge(CLK_50MHz) then
	   Clk_25MHz <= not Clk_25MHz;	 end if;
  end process Generate25MHz;
    		

  VGAPosition: process (Clk_25MHz)
  begin
    if rising_edge(Clk_25MHz) then
	   if unsigned(CurrentHPos) < HLimit-1 then
		  CurrentHPos <= std_logic_vector (unsigned(CurrentHPos) + 1);
		else
		  if unsigned(CurrentVPos) < VLimit-1 then
		    CurrentVPos <=  std_logic_vector (unsigned(CurrentVPos) + 1);
		  else
		    CurrentVPos <= (others => '0'); -- reset Vertical Position
		  end if;
		  CurrentHPos <= (others => '0'); -- reset Horizontal Position
		end if;
	 end if;
  end process VGAPosition;

  -- Timing definition for HSync, VSync and Blank (http://tinyvga.com/vga-timing/640x480@60Hz)
     HS <= '0' when unsigned(CurrentHPos) < HSyncWidth else
	        '1';
	  
	  VS <= '0' when unsigned(CurrentVPos) < VSyncWidth else
	        '1';
	  
	  HBlank <= '0' when (unsigned(CurrentHPos) >= HSyncWidth + HFrontPorch) and (unsigned(CurrentHPos) < HSyncWidth + HFrontPorch + HDisplayArea) else
	           '1';
				  
	  VBlank <= '0' when (unsigned(CurrentVPos) >= VSyncWidth + VFrontPorch) and (unsigned(CurrentVPos) < VSyncWidth + VFrontPorch + VDisplayArea) else
	           '1';				  
	  
	  Blank <= '1' when HBlank = '1' or VBlank = '1' else
	           '0';
	  
	  ScanlineX <= std_logic_vector(unsigned(CurrentHPos) - HSyncWidth - HFrontPorch) when Blank = '0' else
	               (others => '0');

	  ScanlineY <= std_logic_vector(unsigned(CurrentVPos) - VSyncWidth - VFrontPorch) when Blank = '0' else
	               (others => '0');	

     RED <= ColorOutput(2) when Blank = '0' else
            '0';	  
     GREEN <= ColorOutput(1) when Blank = '0' else
            '0';				
     BLUE <= ColorOutput(0) when Blank = '0' else
            '0';		
	  
	  
	ADDR_ROM	<= std_logic_vector (unsigned(char)-32);	-- begin from 32 to 128 so we decease 32 from ASCII char
	
	VGA_DATA_IN_RAM <= ROMchar (to_integer(unsigned(ScanlineY(3 downto 0)))) when std_logic_vector (unsigned(ScanlineX)/8) =  "0000" & Xchar and std_logic_vector (unsigned(ScanlineY)/16) =  "000000" & Ychar else
	"00000000";
	
	 WEn (0) <= '1' when std_logic_vector (unsigned(ScanlineX)/8) =  "0000" & Xchar and std_logic_vector (unsigned(ScanlineY)/16) =  "000000" & Ychar else
		'0';
	 
 	VGA_ADDR_RAM	<= std_logic_vector((unsigned(ScanlineY (7 downto 0))*80) + (unsigned(ScanlineX)/8));
	
   ColorOutput <= "010" when VGA_DATA_OUT_RAM(to_integer(unsigned(ScanlineX(2 downto 0)))) = '1' else
                 "000";
		 
	 
--	  char	<= "1001101";
	  
	  process (CLK_50MHz)
	  begin
	  if rising_edge (CLK_50MHz) then
	  CounterTime	<= std_logic_vector (unsigned(CounterTime) + 1);
	    if (CounterTime = "00000000000000000000") then
			Xchar	<= std_logic_vector (unsigned(Xchar)+1);
			char	<= std_logic_vector (unsigned(char)+1);
				if (Xchar = "1010000") then
					Xchar	<= (others => '0');
					Ychar	<= std_logic_vector (unsigned(Ychar)+1);
				end if;
	    end if;
	  end if;
	  end process;
  
  
  	ROMchar (7)  <=  DATA_OUT_ROM(07 downto 00);
	ROMchar (6)  <=  DATA_OUT_ROM(15 downto 08);
	ROMchar (5)  <=  DATA_OUT_ROM(23 downto 16);
	ROMchar (4)  <=  DATA_OUT_ROM(31 downto 24);
	ROMchar (3)  <=  DATA_OUT_ROM(39 downto 32);
	ROMchar (2)  <=  DATA_OUT_ROM(47 downto 40);
	ROMchar (1)  <=  DATA_OUT_ROM(55 downto 48);
	ROMchar (0)  <=  DATA_OUT_ROM(63 downto 56);
	
  
end Behavioral;

