-- Code your testbench here
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity tb_display_timer_unit is end tb_display_timer_unit;

architecture tb of tb_display_timer_unit is
	signal clk, rst: STD_LOGIC;
    signal Tg_N, Tg_S, Tg_E, Tg_W: STD_LOGIC_VECTOR (11 downto 0);
    signal ped_signal, em_signal : STD_LOGIC_VECTOR (3 downto 0);
    signal control_N,control_S,control_E,control_W : STD_LOGIC_VECTOR(2 downto 0);
    signal sevenseg_N,sevenseg_S,sevenseg_E,sevenseg_W : STD_LOGIC_VECTOR(20 downto 0); 
	
    constant num_cycles : integer := 1000;
begin

  UUT: entity work.display_timer_unit(bev) port map (
      clk, rst, 
      Tg_N, Tg_S, Tg_E, Tg_W, 
      ped_signal, em_signal,

      control_N, control_S, control_E, control_W,
      sevenseg_N, sevenseg_S, sevenseg_E, sevenseg_W
  );

  process begin
    clk <= '0';
    wait for 5 ns;
    for i in 1 to num_cycles loop
      clk <= not clk;
      wait for 5 ns;
      clk <= not clk;
    wait for 5 ns;
    -- clock period = 10 ns
    end loop;
      wait;  -- simulation stops here
    end process;

  process begin
    rst <= '1';
    wait for 20 ns;
    rst <= '0';
    wait; --simulation stops here.
  end process;
  
  process begin
  	ped_signal <= "0000";
    em_signal  <= "0000";
  	Tg_N <= std_logic_vector(to_unsigned(10, Tg_N'length));
    Tg_S <= std_logic_vector(to_unsigned(10, Tg_S'length));
    Tg_W <= std_logic_vector(to_unsigned(15, Tg_W'length));
    Tg_E <= std_logic_vector(to_unsigned(10, Tg_E'length));
    wait for 1500 ns;
    ped_signal <= "1000";
    wait for 200 ns;
    ped_signal <= "0000";
    wait; --simulation stops here.
  end process;
  
end tb;