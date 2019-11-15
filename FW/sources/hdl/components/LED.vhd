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
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity LED is
	generic (
		BusWidth	: 	integer 	:= 32;
		AddrWidth	:	integer 	:= 8;
		NumLEDs		:	integer 	:= 3
	);
	port(
		-------------------------------------------------------------
		-- Clock / Reset
		-------------------------------------------------------------
		CLK		:	in			std_logic;
		RST_N	:	in			std_logic;
		-------------------------------------------------------------
		-- Input / Output port
		-------------------------------------------------------------
		leds	:	out			std_logic_vector(NumLEDs - 1 downto 0)
				:=				(others => '0');
		-------------------------------------------------------------
		-- Memory Map interface
		-------------------------------------------------------------
		CS		:	in			std_logic;
		ADDR	:	in			std_logic_vector(AddrWidth - 1 downto 0);
		OBUS	:	out			std_logic_vector(BusWidth - 1  downto 0);
		IBUS	:	in			std_logic_vector(BusWidth - 1 downto 0);
		NMASK	:	in			std_logic_vector(BusWidth/8 - 1 downto 0);
		RD_STRB	:	in			std_logic;
		WR_STRB	:	in			std_logic
	);
end LED;
	
architecture behavior of LED is
	---------------------------------------------------------------------------
	-- Each LED has 4x8bit register
	type	led_regfile_t	is 	array(0 to NumLEDs - 1) of 
							std_logic_vector(31 downto 0);
	signal	led_regfile		:	led_regfile_t	:= (others =>x"00000000");
	signal 	dradd	 		: 	std_logic_vector(AddrWidth - 1 downto 0);
    signal 	readout 	: 	std_logic_vector(BusWidth - 1 downto 0); 
	---------------------------------------------------------------------------
begin
	
	regfile_proc:	process (CLK, RD_STRB)
    begin
		-- Write mechanism
        if (rising_edge(CLK)) then
            if (WR_STRB = '1' and CS = '1') then
				if(NMASK(0) = '0') then
					led_regfile(to_integer(unsigned(ADDR)))(7 downto 0) <=
						IBUS(7 downto 0);
				end if;
				if(NMASK(1) = '0') then
					led_regfile(to_integer(unsigned(ADDR)))(15 downto 8) <=
						IBUS(15 downto 8);
				end if;
				if(NMASK(2) = '0') then
					led_regfile(to_integer(unsigned(ADDR)))(23 downto 16) <=
						IBUS(23 downto 16);
				end if;
				if(NMASK(3) = '0') then
					led_regfile(to_integer(unsigned(ADDR)))(31 downto 24) <=
						IBUS(31 downto 24);
				end if;
				
            end if;
			dradd	<=	ADDR;
        end if;
		
		-- Read mechanism 
		readout		<=	led_regfile(to_integer(unsigned(dradd)));
		OBUS		<=	(others => 'Z');
		if(RD_STRB = '1' and CS = '1') then
				OBUS <= readout;
		end if;
		
    end process regfile_proc; 

end behavior;