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


entity GPIO is
	generic
	(
		BusWidth	: 	integer 	:= 32;
		AddrWidth	:	integer 	:= 8;
		PortWidth	:	integer 	:= 8
	);
	port 
	( 
		-------------------------------------------------------------
		-- Clock / Reset
		-------------------------------------------------------------
		CLK		:	in			std_logic;
		RST_N	:	in			std_logic;
		-------------------------------------------------------------
		-- Input / Output port
		-------------------------------------------------------------
		oport	:	out			std_logic_vector(PortWidth - 1 downto 0);
		-------------------------------------------------------------
		-- Memory Map interface
		-------------------------------------------------------------
		CS		:	in			std_logic;
		ADDR	:	in			std_logic_vector(AddrWidth - 1 downto 0);
		OBUS	:	out			std_logic_vector(BusWidth - 1  downto 0);
		IBUS	:	in			std_logic_vector(BusWidth - 1 downto 0);
		RD_STRB	:	in			std_logic;
		WR_STRB	:	in			std_logic
		
	);
end GPIO;

architecture behavioral of GPIO is

	signal	port_value	:	std_logic_vector(PortWidth - 1 downto 0);
	
begin

	IO:	process (CLK, RD_STRB)
    begin
		-- Write mechanism
        if (rising_edge(CLK)) then
			if (RST_N = '0') then
				port_value	<=	(others => '0');
            elsif (WR_STRB = '1' and CS = '1') then
                port_value <= IBUS(PortWidth - 1 downto 0);
            end if;
        end if;
		
		-- Read mechanism 
		OBUS		<=	(others => 'Z');
		if(RD_STRB = '1' and CS = '1') then
				OBUS(PortWidth -1 downto 0) <= port_value;
				OBUS(BusWidth - 1 downto PortWidth)	<=	(others => '0');
		end if;
    end process IO; 

	oport	<=	port_value;

end behavioral;

