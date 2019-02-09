--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   22:46:27 05/14/2017
-- Design Name:   
-- Module Name:   D:/FPGA Example/MyVGA/VGA_tb1.vhd
-- Project Name:  MyVGA
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: MyVGA
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY VGA_tb1 IS
END VGA_tb1;
 
ARCHITECTURE behavior OF VGA_tb1 IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT MyVGA
    PORT(
         CLK_50MHz : IN  std_logic;
         VS : OUT  std_logic;
         HS : OUT  std_logic;
         RED : OUT  std_logic_vector(2 downto 0);
         GREEN : OUT  std_logic_vector(2 downto 0);
         BLUE : OUT  std_logic_vector(2 downto 1)
        );
    END COMPONENT;
    

   --Inputs
   signal CLK_50MHz : std_logic := '0';

 	--Outputs
   signal VS : std_logic;
   signal HS : std_logic;
   signal RED : std_logic_vector(2 downto 0);
   signal GREEN : std_logic_vector(2 downto 0);
   signal BLUE : std_logic_vector(2 downto 1);

   -- Clock period definitions
   constant CLK_50MHz_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: MyVGA PORT MAP (
          CLK_50MHz => CLK_50MHz,
          VS => VS,
          HS => HS,
          RED => RED,
          GREEN => GREEN,
          BLUE => BLUE
        );

   -- Clock process definitions
   CLK_50MHz_process :process
   begin
		CLK_50MHz <= '0';
		wait for CLK_50MHz_period/2;
		CLK_50MHz <= '1';
		wait for CLK_50MHz_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	

      wait for CLK_50MHz_period*10;

      -- insert stimulus here 

      wait;
   end process;

END;
