library IEEE;
use IEEE.std_logic.all;

entity tb_lab1 is end entity tb_lab1;

architecture tb of tb_lab1 is 
signal clk, rst: std_logic;
signal control_N: std_logic_vector(2 downto 0);
signal control_S: std_logic_vector(2 downto 0);
signal control_E: std_logic_vector(2 downto 0);
signal control_W: std_logic_vector(2 downto 0);
signal reset_sens: std_logic_vector(3 downto 0);

signal sensor_N: std_logic_vector(5 downto 0);
signal sensor_S: std_logic_vector(5 downto 0);
signal sensor_E: std_logic_vector(5 downto 0);
signal sensor_W: std_logic_vector(5 downto 0);

signal N_n: std_logic_Vector(5 downto 0);
signal N_s: std_logic_Vector(5 downto 0);
signal N_e: std_logic_Vector(5 downto 0);
signal N_w: std_logic_Vector(5 downto 0);

signal Tg_N: std_logic_Vector(11 downto 0);
signal Tg_S: std_logic_Vector(11 downto 0);
signal Tg_E: std_logic_Vector(11 downto 0);
signal Tg_W: std_logic_Vector(11 downto 0);

signal ped_signal, em_signal : STD_LOGIC_VECTOR (3 downto 0);
signal sevenseg_N,sevenseg_S,sevenseg_E,sevenseg_W : STD_LOGIC_VECTOR(20 downto 0); 

constant num_cycles : integer := 900;

begin

    UUT_sensor: entity work.sensor_unit(bev)
    generic map(4, 32)
    port map(
    clk, rst, 
    sensor_N, sensor_S, sensor_E, sensor_W, 
    reset_sens, 
    control_N, control_S, control_E, control_W, 
    N_n, N_s, N_e, N_w
    );
    
    UUT_adapt: entity work.adaptation_unit(bev)
    generic map(4, 20, 1, 5)
    port map(
    clk, rst, 
    control_N, control_S, control_E, control_W, 
    N_n, N_s, N_e, N_w, 
    Tg_N, Tg_S, Tg_E, Tg_W
    );

    UUT_display: entity work.display_timer_unit(bev)
    generic map(10, 5, 10)
    port map(
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

    --process to control the pedestrian/emergency signals
    process begin
      ped_signal <= "0000";
      em_signal  <= "0000";
      wait for 1500 ns;
      --ped_signal <= "1000";
      wait for 200 ns;
      ped_signal <= "0000";
      wait; --simulation stops here.
    end process;

    --process to contorl the sensor inputs
    process begin
        sensor_N <= std_logic_vector(to_unsigned(10, sensor_N'length));
        sensor_E <= std_logic_vector(to_unsigned(15, sensor_E'length));
        sensor_S <= std_logic_vector(to_unsigned(20, sensor_S'length));
        sensor_W <= std_logic_vector(to_unsigned(25, sensor_W'length));
        wait; --simulation stops here.
     end process;

end tb;
