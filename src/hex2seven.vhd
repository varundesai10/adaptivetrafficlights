----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/29/2021 03:59:45 AM
-- Design Name: 
-- Module Name: hex2seven - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity hex2seven is
    Port ( hex_in : in STD_LOGIC_VECTOR (3 downto 0);
           led_pins : out STD_LOGIC_VECTOR (6 downto 0));
end hex2seven;

architecture bev of hex2seven is
begin
    with hex_in select
        led_pins  <=     "0000001" when "0000", --0
    			         "1001111" when "0001", --1
                         "0010010" when "0010", --2
                         "0000110" when "0011", --3
                         "1001100" when "0100", --4
                         "0100100" when "0101", --5
                         "0100000" when "0110", --6
                         "0001111" when "0111", --7
                         "0000000" when "1000", --8
                         "0000100" when "1001", --9
                         "0001001" when "1010", --a
                         "1100000" when "1011", --b
                         "0110001" when "1100", --c
                         "1000010" when "1101", --d
                         "0110000" when "1110", --e
                         "0111000" when "1111", --f 
                         "1111111" when others;

end bev;
