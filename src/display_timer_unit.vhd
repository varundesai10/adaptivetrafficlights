-- The main FSM which controls all of the lights
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

ENTITY display_timer_unit IS
	
    generic(
    	tau : integer  :=  10;
        T_o : integer  :=   5;
        T_ped :integer :=  10
    );
    
    port(
    	clk : IN STD_LOGIC;
        rst : IN STD_LOGIC;
        
    	Tg_N : IN STD_LOGIC_VECTOR (11 downto 0);
        Tg_S : IN STD_LOGIC_VECTOR (11 downto 0);
        Tg_E : IN STD_LOGIC_VECTOR (11 downto 0);
        Tg_W : IN STD_LOGIC_VECTOR (11 downto 0);
        ped_signal : IN STD_LOGIC_VECTOR (3 downto 0);
        em_signal  : IN STD_LOGIC_VECTOR (3 downto 0);
        
        control_N : OUT STD_LOGIC_VECTOR (2 downto 0);
		control_S : OUT STD_LOGIC_VECTOR (2 downto 0);
        control_E : OUT STD_LOGIC_VECTOR (2 downto 0);
        control_W : OUT STD_LOGIC_VECTOR (2 downto 0);
        
        sevenseg_N : OUT STD_LOGIC_VECTOR (20 downto 0);
        sevenseg_S : OUT STD_LOGIC_VECTOR (20 downto 0);
        sevenseg_E : OUT STD_LOGIC_VECTOR (20 downto 0);
        sevenseg_W : OUT STD_LOGIC_VECTOR (20 downto 0)
    );

end display_timer_unit;

ARCHITECTURE bev OF display_timer_unit IS
	
    --signals to keep track of the state of the FSM
	type state_type is (IDLE, N, S, E, W, O, O_ped, R_ped);
	signal state: state_type := N;
    signal next_state: state_type := N;
    signal prev_state: state_type := N;
    signal state_debug: unsigned(5 downto 0);

    --function to view the state in the waveform debugger
    function state_decode(state:state_type) return integer is begin
    	case state is
        	when IDLE => return 0;
            when N => return 1;
            when E => return 2;
            when S => return 3;
            when W => return 4;
            when O => return 5;
            when O_ped => return 6;
            when R_ped => return 7;
            when others => return 8;
        end case;
    end function state_decode;

    --internal signals, which store rounded off values
    signal Tg_N_0 : unsigned (11 downto 0);
    signal Tg_S_0 : unsigned (11 downto 0);
    signal Tg_E_0 : unsigned (11 downto 0);
    signal Tg_W_0 : unsigned (11 downto 0);
    
    signal Tg_N_reg : unsigned (11 downto 0);
    signal Tg_S_reg : unsigned (11 downto 0);
    signal Tg_E_reg : unsigned (11 downto 0);
    signal Tg_W_reg : unsigned (11 downto 0);
    
    --signals to keep count until the next change
    signal counter_N: unsigned(11 downto 0);
    signal counter_S: unsigned(11 downto 0);
    signal counter_E: unsigned(11 downto 0);
    signal counter_W: unsigned(11 downto 0);
    signal counter : unsigned (11 downto 0);
    
    --signals to keep track of pedestrian/emergency request
    signal ped_or : STD_LOGIC;
    signal em_or  : STD_LOGIC;
    
    --module which signals when a second has elapsed.
    component sc
    	generic(
        thresh: integer := 10
        );
        port(
        	clk: IN std_logic;
            rst: IN std_logic;
            counter: OUT std_logic_vector (31 downto 0);
            e: OUT std_logic
            );
    end component;
    FOR ALL: sc use entity work.seconds_clock(bev);
    
    --component for bcd conversion
    component conv 
        port(bin_in:IN STD_LOGIC_VECTOR(11 downto 0); seven_out: OUT STD_LOGIC_VECTOR(20 downto 0));
    end component;
    
    FOR ALL: conv use entity work.bit12_3seven(bev);
    
    -- signals for the seconds clock
    signal sc_e : STD_LOGIC;
    signal sc_counter : STD_LOGIC_VECTOR (31 downto 0);

begin
	
    process(clk) begin
    	--fsm state transition logic
        if(rst = '1') then
            counter <= (others => '0');
            
            state <= IDLE;
            next_state <= N;
        end if;
       	
        if(sc_e = '1' and clk ='1' and clk'event) then
        	--changing values of counters by default
        	counter   <= counter + 1;
            counter_N <= counter_N - 1;
            counter_S <= counter_S - 1;
            counter_W <= counter_W - 1;
            counter_E <= counter_E - 1;
            
        	case state is
            	when IDLE =>
           			if(em_or = '1') then --emergency request 
                    	state <= N;
                        next_state <= N;
                        counter <= (others => '0');
                    else                 --proceed to N state
                        counter_N <= Tg_N_reg;
                        counter_E <= Tg_N_reg + T_o;
                        counter_S <= Tg_N_reg + Tg_E_reg + 2*T_o;
                        counter_W <= Tg_N_reg + Tg_E_reg + Tg_S_reg + 3*T_o;
                    	state <= N;
                        counter <= (others => '0');
                    
                    end if;
                
                when N =>
                	if(counter = 0) then --taking into consideration new adapted values only after one cycle is complete
                        Tg_N_0 <= Tg_N_reg; 
                        Tg_S_0 <= Tg_S_reg; 
                        Tg_E_0 <= Tg_E_reg; 
                        Tg_W_0 <= Tg_W_reg; 
                        
                        counter_N <= Tg_N_reg - 1;
                        counter_E <= Tg_N_reg + T_o - 1;
                        counter_S <= Tg_N_reg + Tg_E_reg + 2*T_o - 1;
                        counter_W <= Tg_N_reg + Tg_E_reg + Tg_S_reg + 3*T_o - 1;
                    end if;
                    
                    if(em_or = '1') then
                    	state <= O_ped;
                        next_state <= E;
                        prev_state <= N;
                        counter <= (others => '0');
                        
                        --updating counters for emergency purpose
                        counter_N <= to_unsigned(T_o, counter_N'length);
                        counter_E <= to_unsigned(T_o + T_ped, counter_E'length);
                        counter_S <= 2*T_o +  T_ped + Tg_E_0;
                        counter_W <= 3*T_o +  T_ped + Tg_E_0 + Tg_S_0;
                        
                    elsif(counter = Tg_N_0 - 1) then
                    	
                        counter   <= (others => '0');
                        counter_N <= to_unsigned(T_o, counter_N'length);
                        next_state <= E;
                        prev_state <= N;
                        
                        if(ped_or = '1') then --pedestrian request is pending
                        	state <= O_ped;
                        	counter_E <= to_unsigned(T_o + T_ped, counter_E'length);
                        	counter_S <= 2*T_o +  T_ped + Tg_E_0; 
                        	counter_W <= 3*T_o +  T_ped + Tg_E_0 + Tg_S_0;
                         else
                         	state <= O; --orange
                         end if;
                     
                     end if;
                 
                 when E =>
                    
                	if(em_or = '1') then
                    	state <= O_ped;
                        next_state <= S;
                        prev_state <= E;
                        counter <= (others => '0');
                        
                        counter_E <= to_unsigned(T_o, counter_E'length);
                        counter_S <= to_unsigned(T_o + T_ped, counter_E'length);
                        counter_W <= 2*T_o +  T_ped + Tg_S_0;
                        counter_N <= 3*T_o +  T_ped + Tg_S_0 + Tg_W_0;
                        
                    
                    elsif(counter = Tg_E_0 - 1) then
                        counter_E <= to_unsigned(T_o, counter_E'length);
                    	counter <= (others => '0');
                        next_state <= S;
                        prev_state <= E;
                        
                        if(ped_or = '1') then
                        	state <= O_ped;
                        	counter_S <= to_unsigned(T_o + T_ped, counter_E'length);
                            counter_W <= 2*T_o +  T_ped + Tg_S_0;
                            counter_N <= 3*T_o +  T_ped + Tg_S_0 + Tg_W_0;
                         else
                         	state <= O;
                         end if;
                     
                     end if;
                 
                 when S =>
           
                	if(em_or = '1') then
                    	state <= O_ped;
                        next_state <= W;
                        prev_state <= S;
                        counter <= (others => '0');
                        
                        counter_S <= to_unsigned(T_o, counter_E'length);
                        counter_W <= to_unsigned(T_o + T_ped, counter_E'length);
                        counter_N <= 2*T_o +  T_ped + Tg_W_0;
                        counter_E <= 3*T_o +  T_ped + Tg_W_0 + Tg_N_0;
                        
                    elsif(counter = Tg_S_0 - 1) then
                    	counter <= (others => '0');
                        next_state <= W;
                        prev_state <= S;
                        counter_S <= to_unsigned(T_o, counter_S'length);
                        
                        if(ped_or = '1') then
                        	state <= O_ped;
                        	counter_W <= to_unsigned(T_o + T_ped, counter_E'length);
                            counter_N <= 2*T_o +  T_ped + Tg_W_0;
                            counter_E <= 3*T_o +  T_ped + Tg_W_0 + Tg_N_0;
                         else
                         	state <= O;
                         end if;
                     end if;
                  
                  when W =>
                	
                    
                    if(em_or = '1') then
                    	state <= O_ped;
                        next_state <= N;
                        prev_state <= W;
                        counter <= (others => '0');
                        
                        counter_W <= to_unsigned(T_o, counter_W'length);
                        counter_N <= to_unsigned(T_o + T_ped, counter_N'length);
                        counter_E <= 2*T_o +  T_ped + Tg_N_0;
                        counter_S <= 3*T_o +  T_ped + Tg_N_0 + Tg_E_0;
                    
                    elsif(counter = Tg_W_0 - 1) then
                    	counter <= (others => '0');
                    	prev_state <= W;
                        next_state <= N;
                        counter_W <= to_unsigned(T_o, counter_W'length);
                        
                        if(ped_or = '1') then
                        	state <= O_ped;
                        	counter_N <= to_unsigned(T_o + T_ped, counter_N'length);
                            counter_E <= 2*T_o +  T_ped + Tg_N_0;
                            counter_S <= 3*T_o +  T_ped + Tg_N_0 + Tg_E_0;
                         else
                         	state <= O;
                         end if;
                     end if;
                   
                   when O =>
                     if(counter = T_o - 1) then
                        if(ped_or='1' or em_or='1') then --if emergency request is pending
                            state <= R_ped;
                            --incrementing all counter values by T_ped...
                            counter_N <= counter_N + T_ped - 1;
                            counter_S <= counter_S + T_ped - 1;
                            counter_E <= counter_E + T_ped - 1;
                            counter_W <= counter_W + T_ped - 1;

                            case prev_state is 
                                when N => counter_N <= T_ped + 3*T_o + Tg_E_0 + Tg_S_0 + Tg_W_0;
                                when S => counter_S <= T_ped + 3*T_o + Tg_E_0 + Tg_N_0 + Tg_W_0;
                                when E => counter_E <= T_ped + 3*T_o + Tg_N_0 + Tg_S_0 + Tg_W_0;
                                when W => counter_W <= T_ped + 3*T_o + Tg_E_0 + Tg_S_0 + Tg_N_0; 
                                when others => state <= IDLE;
                            end case;
                            counter <= (others => '0');
                        else
                            state <= next_state;
                    
                            case next_state is
                            when N => counter_N <= Tg_N_0;
                            when S => counter_S <= Tg_S_0;
                            when E => counter_E <= Tg_E_0;
                            when W => counter_W <= Tg_W_0;
                            when others => state <= IDLE;
                            end case;
                            
                            case prev_state is
                            when N => counter_N <= Tg_E_0 + Tg_S_0 + Tg_W_0 + 3*T_o;
                            when S => counter_S <= Tg_E_0 + Tg_N_0 + Tg_W_0 + 3*T_o;
                            when E => counter_E <= Tg_N_0 + Tg_S_0 + Tg_W_0 + 3*T_o;
                            when W => counter_W <= Tg_E_0 + Tg_S_0 + Tg_N_0 + 3*T_o;
                            when others => state <= IDLE;
                            end case;
                            counter <= (others => '0');
                        end if;
                   	end if;
                   	
                    when O_ped =>
                    	if(counter = T_o - 1) then
                        	state <= R_ped;
                            counter <= (others => '0');
                            
                            case prev_state is 
                                when N => counter_N <= T_ped + 3*T_o + Tg_E_0 + Tg_S_0 + Tg_W_0;
                                when S => counter_S <= T_ped + 3*T_o + Tg_E_0 + Tg_N_0 + Tg_W_0;
                                when E => counter_E <= T_ped + 3*T_o + Tg_N_0 + Tg_S_0 + Tg_W_0;
                                when W => counter_W <= T_ped + 3*T_o + Tg_E_0 + Tg_S_0 + Tg_N_0; 
                                when others => state <= IDLE;
                            end case;
                         end if;
                    
                    when R_ped =>
                    	if(counter = T_ped - 1) then
                        	state <= next_state;
                            counter <= (others => '0');
                            
                            case next_state is
                                when N => counter_N <= Tg_N_0;
                                when E => counter_E <= Tg_E_0;
                                when S => counter_S <= Tg_S_0;
                                when W => counter_W <= Tg_W_0;
                                when others => state <= IDLE;
                            end case;
                         end if;
                     
                
                    when others =>
                    	if(em_or = '1') then 
                          state <= N;
                          next_state <= N;

                          counter <= (others => '0');
                          temp_counter <= (others => '0');
                        else 

                            state <= N;
                            counter <= (others => '0');

                        end if;
             end case;
        end if;
    end process;
    
    SECONDS_CLOCK: sc port map(clk, rst, sc_counter, sc_e); --module to signal when a second has elapsed
    CONV_N: conv port map(bin_in => std_logic_vector(counter_N), seven_out => sevenseg_N);
    CONV_S: conv port map(bin_in => std_logic_vector(counter_S), seven_out => sevenseg_S);
    CONV_E: conv port map(bin_in => std_logic_vector(counter_E), seven_out => sevenseg_E);
    CONV_W: conv port map(bin_in => std_logic_vector(counter_W), seven_out => sevenseg_W);
    
  --rounding off to nearest multiple of tau
    Tg_N_reg <=resize(((unsigned(Tg_N) - tau/2)/tau + 1)*tau, Tg_N_reg'length);
    Tg_S_reg <=resize(((unsigned(Tg_S) - tau/2)/tau + 1)*tau, Tg_S_reg'length); 
    Tg_E_reg <=resize(((unsigned(Tg_E) - tau/2)/tau + 1)*tau, Tg_E_reg'length); 
    Tg_W_reg <=resize(((unsigned(Tg_W) - tau/2)/tau + 1)*tau, Tg_W_reg'length); 
    
    em_or <= em_signal(3) or em_signal(2) or em_signal(1) or em_signal(0);
    ped_or <= ped_signal(3) or ped_signal(2) or ped_signal(1) or ped_signal(0);
    
    --controlling the outputs
    
    control_N <= "100" when state=N else
                 "010" when (state = O and prev_state = N) else
                 "010" when (state = O_ped and prev_state = N) else 
                 "001";
    
    control_S <= "100" when state=S else
                 "010" when (state = O and prev_state = S) else
                 "010" when (state = O_ped and prev_state = S) else 
                 "001";
    
    control_E <= "100" when state=E else
                 "010" when (state = O and prev_state = E) else
                 "010" when (state = O_ped and prev_state = E) else 
                 "001";
    
    control_W <= "100" when state=W else
                 "010" when (state = O and prev_state = W) else
                 "010" when (state = O_ped and prev_state = W) else 
                 "001";
                                                                                                   
    state_debug <= to_unsigned(state_decode(state), state_debug'length);
    
        
end bev;