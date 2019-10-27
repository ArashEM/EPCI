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


entity BRAM is
	generic 
	(
		BusWidth: integer := 32;
		AddrWidth: integer := 8
	);    
	port 
	( 
		-------------------------------------------------------------
		-- Clock / Reset
		-------------------------------------------------------------
		CLK		:	in			std_logic;
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
end BRAM;

architecture behavioral of BRAM is

	----------------------------------------------------------------
	-- BRAM interface
    type 		ram_type is array (0 to 255) of std_logic_vector(BusWidth - 1 downto 0);
    signal 		RAM 		: 	ram_type :=     (others => x"55AA55AA");
    signal 		dradd 		: 	std_logic_vector(AddrWidth - 1 downto 0);
    signal 		readout 	: 	std_logic_vector(BusWidth - 1 downto 0); 
	----------------------------------------------------------------
begin

	bram:	process (CLK, RD_STRB, dradd, readout)
    begin
		-- Write mechanism
        if (rising_edge(CLK)) then
            if (WR_STRB = '1' and CS = '1') then
                RAM(to_integer(unsigned(ADDR))) <= IBUS;
            end if;
			dradd	<=	ADDR(7 downto 0);
        end if;
		
		-- Read mechanism 
		readout		<=	RAM(to_integer(unsigned(dradd)));
		OBUS		<=	(others => 'Z');
		if(RD_STRB = '1' and CS = '1') then
				OBUS <= readout;
		end if;
		
    end process bram; 

end behavioral;

