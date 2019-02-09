library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use ieee.numeric_std.all;


entity ShowChar is
    Port ( CLK : in  STD_LOGIC;
           x : in  STD_LOGIC_VECTOR (6 downto 0);
           y : in  STD_LOGIC_VECTOR (4 downto 0) ;
			  DATA_OUT : out STD_LOGIC_VECTOR(7 DOWNTO 0);
			  ScanlineX : in std_logic_vector(10 downto 0);
			  ScanlineY : in std_logic_vector(10 downto 0);
           CH : in  STD_LOGIC_VECTOR (6 downto 0)
			  );
end ShowChar;


architecture Behavioral of ShowChar is

signal ADDR_RAM :STD_LOGIC_VECTOR(6 DOWNTO 0);
signal DATA_OUT_ROM: STD_LOGIC_VECTOR(63 DOWNTO 0);

COMPONENT VGACHAR
  PORT (
    clka : IN STD_LOGIC;
    addra : IN STD_LOGIC_VECTOR(6 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(63 DOWNTO 0)
  );
END COMPONENT;


type Characters is Array (15 downto 0) of std_logic_vector (7 downto 0);
signal char :Characters;

begin

VGA_CHAR : VGACHAR
  PORT MAP (
    clka => CLK,
    addra => ADDR_ROM,
    douta => DATA_OUT_ROM
  );
  
  
	ADDR_RAM	<= CH(6 downto 0);
		
	char (0)  <=  DATA_OUT_ROM(07 downto 00);
	char (1)  <=  DATA_OUT_ROM(15 downto 08);
	char (2)  <=  DATA_OUT_ROM(23 downto 16);
	char (3)  <=  DATA_OUT_ROM(31 downto 24);
	char (4)  <=  DATA_OUT_ROM(39 downto 32);
	char (5)  <=  DATA_OUT_ROM(47 downto 40);
	char (6)  <=  DATA_OUT_ROM(55 downto 48);
	char (7)  <=  DATA_OUT_ROM(63 downto 56);

		
		DATA_OUT <= char (to_integer(unsigned(ScanlineY(3 downto 0)))) when std_logic_vector (unsigned(ScanlineX)/8) =  "0000" & x and std_logic_vector (unsigned(ScanlineY)/16) =  "000000" & y else
		"00000000";
		

end Behavioral;

