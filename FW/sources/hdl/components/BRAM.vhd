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
		NMASK	:	in			std_logic_vector(BusWidth/8 - 1 downto 0);
		RD_STRB	:	in			std_logic;
		WR_STRB	:	in			std_logic
		
	);
end BRAM;

architecture behavioral of BRAM is

	----------------------------------------------------------------
	-- BRAM interface
    type 		ram_type is array (0 to 2**AddrWidth - 1) of 
								std_logic_vector(7 downto 0);
    signal 		RAM0 		: 	ram_type :=     (others => x"00");
    signal 		RAM1 		: 	ram_type :=     (others => x"00");
    signal 		RAM2 		: 	ram_type :=     (others => x"00");
    signal 		RAM3 		: 	ram_type :=     (others => x"00");
    signal 		dradd 		: 	std_logic_vector(AddrWidth - 1 downto 0);
    signal 		readout 	: 	std_logic_vector(BusWidth - 1 downto 0); 
	----------------------------------------------------------------
begin

	bram:	process (CLK, RD_STRB, dradd, readout)
    begin
		-- Write mechanism
        if (rising_edge(CLK)) then
            if (WR_STRB = '1' and CS = '1') then
				if(NMASK(0) = '0') then
					RAM0(to_integer(unsigned(ADDR))) <=
						IBUS(7 downto 0);
				end if;
				if(NMASK(1) = '0') then
					RAM1(to_integer(unsigned(ADDR))) <=
						IBUS(15 downto 8);
				end if;
				if(NMASK(2) = '0') then
					RAM2(to_integer(unsigned(ADDR))) <=
						IBUS(23 downto 16);
				end if;
				if(NMASK(3) = '0') then
					RAM3(to_integer(unsigned(ADDR))) <=
						IBUS(31 downto 24);
				end if;
				
            end if;
			dradd	<=	ADDR;
        end if;
		
		-- Read mechanism 
		readout		<=	RAM3(to_integer(unsigned(dradd))) &
						RAM2(to_integer(unsigned(dradd))) &
						RAM1(to_integer(unsigned(dradd))) &
						RAM0(to_integer(unsigned(dradd)));
		OBUS		<=	(others => 'Z');
		if(RD_STRB = '1' and CS = '1') then
				OBUS <= readout;
		end if;
		
    end process bram; 

end behavioral;

