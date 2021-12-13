-- Code your design here
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity sensor_unit is

	generic(
    	k : integer := 50;
        init_value : integer := 32
    );
    
	port(
      --global signals
      clk, rst: IN std_logic;
      --readings coming from the sensors
      sensor_N: IN std_logic_vector(5 downto 0);
      sensor_S: IN std_logic_vector(5 downto 0);
      sensor_E: IN std_logic_vector(5 downto 0);
      sensor_W: IN std_logic_vector(5 downto 0);
      
      --signals to reset the sensor counts
      reset_sens: OUT std_logic_vector(3 downto 0); --N, E, S, W
      
      --the traffic light signals
      control_N:IN std_logic_vector(2 downto 0);
      control_S:IN std_logic_vector(2 downto 0);
      control_E:IN std_logic_vector(2 downto 0);
      control_W:IN std_logic_vector(2 downto 0);
      
      --output signals
      N_n: OUT std_logic_vector(5 downto 0);
      N_s: OUT std_logic_vector(5 downto 0);
      N_e: OUT std_logic_vector(5 downto 0);
      N_w: OUT std_logic_vector(5 downto 0)
      );
end sensor_unit;

architecture bev of sensor_unit is
	--signals to keep track of the number of vehicles passed
    signal count_N: unsigned(13 downto 0);
	signal count_S: unsigned(13 downto 0);
	signal count_E: unsigned(13 downto 0);
	signal count_W: unsigned(13 downto 0);
    
    --state for the fsm
    type su_state is (wait_N, wait_S, wait_E, wait_W, calc_counts);
    signal state : su_state;
    
    --signal to keep track of the number of cycles elapsed
    signal cycle_count: unsigned(7 downto 0);
	
    signal state_debug: unsigned(4 downto 0);
    --function to keep track of the state of the FSM
    function state_decode(s : su_state) return integer is
	begin
      case s is
          when wait_N => return 1;
          when wait_E => return 2;
          when wait_S => return 3;
          when wait_W => return 4;
          when calc_counts => return 5;
          when others => return 6;
      end case;
	end function state_decode;

begin
	process(clk) begin
    	if(rising_edge(clk)) then 
    	if(rst = '1') then
        	reset_sens <= "0000"; 
            N_n <= std_logic_vector(to_unsigned(init_value, N_n'length));
            N_s <= std_logic_vector(to_unsigned(init_value, N_s'length));
            N_e <= std_logic_vector(to_unsigned(init_value, N_e'length));
            N_w <= std_logic_vector(to_unsigned(init_value, N_w'length));
            
            count_N <= (to_unsigned(0, count_N'length));
            count_S <= (to_unsigned(0, count_S'length));
            count_E <= (to_unsigned(0, count_E'length));
            count_W <= (to_unsigned(0, count_W'length));
            
            state <= wait_N;
            
            cycle_count <= to_unsigned(0, cycle_count'length);
        else 
        	reset_sens <= "0000";
        	case state is
            	when wait_N =>
                	if control_N(2) = '1' then
                    	state   <= wait_E;
                        count_N <= count_N + unsigned(sensor_N);
                        reset_sens <= "1000";
                    end if;
                
                when wait_E =>
                	if control_E(2) = '1' then
                    	state   <= wait_S;
                        count_E <= count_E + unsigned(sensor_E);
                        reset_sens <= "0100";
                     end if;
                when wait_S =>
                	if control_S(2) = '1' then 
                    	state <= wait_W;
                        count_S <= count_S + unsigned(sensor_S);
                        reset_sens <= "0010";
                    end if;
                when wait_W =>
                	if control_W(2) = '1' then 
                         state <= calc_counts;
                         count_W <= count_W + unsigned(sensor_W);
                         reset_sens <= "0001";
                   end if;
               when calc_counts =>
               		if cycle_count = k - 1 then
                    	--bringing values to output
                    	N_n <= std_logic_vector(resize(count_N/to_unsigned(k, count_N'length), N_n'length));
                        N_e <= std_logic_vector(resize(count_E/to_unsigned(k, count_E'length), N_e'length));
                        N_s <= std_logic_vector(resize(count_S/to_unsigned(k, count_S'length), N_s'length));
                        N_w <= std_logic_vector(resize(count_W/to_unsigned(k, count_W'length), N_w'length));
                        cycle_count <= to_unsigned(0, cycle_count'length);
                        
                        --resetting the counters
                        count_N <= to_unsigned(0, count_N'length);
                        count_E <= to_unsigned(0, count_E'length);
                        count_S <= to_unsigned(0, count_S'length);
                        count_W <= to_unsigned(0, count_W'length);
                    else
                        cycle_count <= cycle_count + 1;
                    end if;
                    state <= wait_N;
             when others =>
             	state <= wait_N;
            end case;
        end if; 
        end if;
    end process;
	state_debug <= to_unsigned(state_decode(state), state_debug'length);
end bev;

