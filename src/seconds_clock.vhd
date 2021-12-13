--module to signal when a second has elapsed.
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity seconds_clock is
	generic(thresh: integer:= 1000);
	port(
    	clk: IN std_logic;
        rst: IN std_logic;
        counter: OUT std_logic_vector (31 downto 0);
        e: OUT std_logic
        );
end seconds_clock;

architecture bev of seconds_clock is
	signal internal_counter: std_logic_vector (31 downto 0);
    signal int_e: std_logic;
begin
	process(clk) begin
   		if(clk = '1' and clk'event) then
        	if(rst = '1') then
            	internal_counter <= (others => '0');
                int_e <= '0';
            else
                internal_counter <= internal_counter + 1;
                if(internal_counter = thresh - 1) then
                	int_e <= '1';
                 	internal_counter <= (others => '0');
                end if;
             end if;
            if (int_e = '1') then
            	int_e <= '0';
            end if;
          end if;
    end process;
    
    e <= int_e;
    counter <= internal_counter;
    
end bev;
