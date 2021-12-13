-- Code your design here
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;

entity adaptation_unit is
	generic(
    	k          : integer :=  50;
        init_value : integer :=  20;
        beta       : integer :=   1;
        tau        : integer :=  10
    );
    
    port(
    	--global signals
        signal clk, rst: IN std_logic;
        
        --traffic lights
    	control_N: IN std_logic_vector(2 downto 0);
        control_S: IN std_logic_vector(2 downto 0);
        control_E: IN std_logic_vector(2 downto 0);
        control_W: IN std_logic_vector(2 downto 0);
        
        --from sensor unit
        N_n: IN std_logic_vector(5 downto 0);
        N_s: IN std_logic_vector(5 downto 0);
        N_e: IN std_logic_vector(5 downto 0);
        N_w: IN std_logic_vector(5 downto 0);
        
        --to display unit
        Tg_N: OUT std_logic_vector(11 downto 0);
        Tg_S: OUT std_logic_vector(11 downto 0);
        Tg_E: OUT std_logic_vector(11 downto 0);
        Tg_W: OUT std_logic_vector(11 downto 0)
    );
end adaptation_unit;

architecture bev of adaptation_unit is
    signal cycle_count: unsigned(7 downto 0);

    --signals/functions to keep track of the state of the FSM
    type au_state is (wait_S, wait_W, buffer_state, calc_average, calc_values, check_values);
    signal state: au_state;
    signal state_debug: unsigned(3 downto 0);

    function state_decode (s:au_state) return integer is begin
        case s is 
            when wait_S => return 1;
            when wait_W => return 2;
            when buffer_state => return 3;
            when calc_average => return 4;
            when calc_values => return 5;
            when check_values => return 6;
            when others => return 7;
        end case;
    end function state_decode;
    
	--signals to calculate the temp values
    signal Tg_N_temp: signed(11 downto 0);
    signal Tg_S_temp: signed(11 downto 0);
    signal Tg_E_temp: signed(11 downto 0);
    signal Tg_W_temp: signed(11 downto 0);
    signal N_avg    : signed(8  downto 0);
    
    begin
    process(clk) 
    	variable N_n_signed, N_s_signed, N_e_signed, N_w_signed : signed(8 downto 0);
    	begin
        

        if(rising_edge(clk)) then
            if(rst = '1') then
                Tg_N <= std_logic_vector(to_unsigned(init_value, Tg_N'length));
                Tg_E <= std_logic_vector(to_unsigned(init_value, Tg_N'length));
                Tg_S <= std_logic_vector(to_unsigned(init_value, Tg_N'length));
                Tg_W <= std_logic_vector(to_unsigned(init_value, Tg_N'length));
                
                Tg_N_temp <= to_signed(init_value, Tg_N_temp'length);
                Tg_E_temp <= to_signed(init_value, Tg_N_temp'length);
                Tg_S_temp <= to_signed(init_value, Tg_N_temp'length);
                Tg_W_temp <= to_signed(init_value, Tg_N_temp'length);
                
                cycle_count <= to_unsigned(0, cycle_count'length);
                
            else
                
                N_n_signed := signed(resize(unsigned(N_n), N_n_signed'length));
                N_s_signed := signed(resize(unsigned(N_s), N_s_signed'length));
                N_e_signed := signed(resize(unsigned(N_e), N_e_signed'length));
                N_w_signed := signed(resize(unsigned(N_w), N_w_signed'length));
                
                case state is
                	when wait_S =>
                    	if (control_S(2) = '1') then 
                        	state <= wait_W;
                        end if;
                        
                    when wait_W => 
                        if (control_W(2) = '1') then
                            if(cycle_count = k - 1) then
                                state       <= buffer_state;
                                cycle_count <= to_unsigned(0, cycle_count'length);
                            else
                                cycle_count <= cycle_count + 1;
                                state <= wait_S;
                            end if;
                        end if;

                    when buffer_state =>
                        state <= calc_average;
                    
                    when calc_average =>
                        N_avg  <= (N_n_signed + N_s_signed + N_e_signed + N_w_signed)/4;
                        state  <= calc_values;
                    
                    when calc_values =>
                        case(beta) is
                            when 0 => -- represents 0.5
                                Tg_N_temp <= signed(Tg_N) + (N_n_signed - N_avg)/2;
                                Tg_E_temp <= signed(Tg_E) + (N_e_signed - N_avg)/2;
                                Tg_S_temp <= signed(Tg_S) + (N_s_signed - N_avg)/2;
                                Tg_W_temp <= signed(Tg_W) + (N_w_signed - N_avg)/2;
                            when others =>
                                Tg_N_temp <= signed(Tg_N) + resize((N_n_signed - N_avg)*beta, Tg_N'length);
                                Tg_E_temp <= signed(Tg_E) + resize((N_e_signed - N_avg)*beta, Tg_S'length);
                                Tg_S_temp <= signed(Tg_S) + resize((N_s_signed - N_avg)*beta, Tg_E'length);
                                Tg_W_temp <= signed(Tg_W) + resize((N_w_signed - N_avg)*beta, Tg_W'length);
                         end case;
                        state <= check_values;
                    when check_values =>
                        if((Tg_N_temp < tau) or (Tg_E_temp < tau) or (Tg_S_temp < tau) or (Tg_W_temp < tau)) then
                            state <= wait_S;
                        else 
                            Tg_N <= std_logic_vector(Tg_N_temp(11 downto 0));
                            Tg_E <= std_logic_vector(Tg_E_temp(11 downto 0));
                            Tg_S <= std_logic_vector(Tg_S_temp(11 downto 0));
                            Tg_W <= std_logic_vector(Tg_W_temp(11 downto 0));
                            state <= wait_S;
                        end if;
                    when others =>
                            state <= wait_S;
                end case;
            end if;
        end if;
    end process;

    state_debug <= to_unsigned(state_decode(state), state_debug'length);
end bev;