library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

--module which uses three hez2seven units to convert a 12 bit number to seven segment led control signals
entity bit12_3seven is
   port(
        bin_in: IN STD_LOGIC_VECTOR (11 downto 0);
        seven_out: OUT STD_LOGIC_VECTOR (20 downto 0)
   );
end bit12_3seven;

architecture bev of bit12_3seven is
    component conv 
        port(hex_in: IN STD_LOGIC_VECTOR(3 downto 0); led_pins: OUT STD_LOGIC_VECTOR(6 downto 0));
    end component;
    
    FOR ALL: conv use entity work.hex2seven(bev);
begin
    CONV1: conv port map(bin_in(3 downto 0), seven_out(6 downto 0));
    CONV2: conv port map(bin_in(7 downto 4), seven_out(13 downto 7));
    CONV3: conv port map(bin_in(11 downto 8), seven_out(20 downto 14));
end bev;
