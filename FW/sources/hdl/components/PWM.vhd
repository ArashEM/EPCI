--********************************************************************************************                                                        
--	  ______                                __                ________  __       __ 
--	 /      \                              |  \              |        \|  \     /  \
--	|  $$$$$$\  ______   ______    _______ | $$____          | $$$$$$$$| $$\   /  $$
--	| $$__| $$ /      \ |      \  /       \| $$    \  ______ | $$__    | $$$\ /  $$$
--	| $$    $$|  $$$$$$\ \$$$$$$\|  $$$$$$$| $$$$$$$\|      \| $$  \   | $$$$\  $$$$
--	| $$$$$$$$| $$   \$$/      $$ \$$    \ | $$  | $$ \$$$$$$| $$$$$   | $$\$$ $$ $$
--	| $$  | $$| $$     |  $$$$$$$ _\$$$$$$\| $$  | $$        | $$_____ | $$ \$$$| $$
--	| $$  | $$| $$      \$$    $$|       $$| $$  | $$        | $$     \| $$  \$ | $$
--	 \$$   \$$ \$$       \$$$$$$$ \$$$$$$$  \$$   \$$         \$$$$$$$$ \$$      \$$
--	                                                                                
--	                                                                                
--	                        
--********************************************************************************************
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

entity PWM is
	generic(
		-- number of bit of PWM counter
		N				: integer 	:= 16;	
		
		-- PWM Freq  = clock freq/ (FREQ_DIV+1); max value = 2^N-1
		FREQ_DIV		: integer 	:= 1000	
	);      
	port (
		i_clk       	: in  std_logic;
		i_rstb      	: in  std_logic; 
		-- PWM width = (others=>0)=> OFF; i_pwm_module => MAX ON 
		i_pwm_width 	: in  std_logic_vector(N-1 downto 0);  
		o_pwm       	: out std_logic);
end PWM;
	
architecture behavior of PWM is
	---------------------------------------------------------------------------
	constant 	r_max_count     	: unsigned(N-1 downto 0)	
									:= to_unsigned(FREQ_DIV, N);
	signal 		r_pwm_counter   	: unsigned(N-1 downto 0);
	signal 		r_pwm_width     	: unsigned(N-1 downto 0);
	signal 		w_tc_pwm_counter	: std_logic;
	---------------------------------------------------------------------------
begin
	
	w_tc_pwm_counter  <= '0' when(r_pwm_counter<r_max_count) else '1';  -- use to strobe new word
	--------------------------------------------------------------------

	p_state_out : process(i_clk,i_rstb)
	begin
	if(i_rstb='0') then
		r_pwm_width     <= (others=>'0');
		r_pwm_counter   <= (others=>'0');
		o_pwm           <= '0';
	elsif(rising_edge(i_clk)) then
		if(r_pwm_counter=0) and (r_pwm_width/=r_max_count) then
			o_pwm           <= '0';
		elsif(r_pwm_counter<=r_pwm_width) then
			o_pwm           <= '1';
		else
			o_pwm           <= '0';
		end if;
      
		if(w_tc_pwm_counter='1') then
			r_pwm_width      <= unsigned(i_pwm_width);
		end if;
      
		if(r_pwm_counter=r_max_count) then
			r_pwm_counter   <= to_unsigned(0,N);
		else
			r_pwm_counter   <= r_pwm_counter + 1;
		end if;
		
	end if;
	
	end process p_state_out;

end behavior;