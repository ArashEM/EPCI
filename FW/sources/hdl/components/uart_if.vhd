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

entity UART_IF is
	generic (
		BusWidth	: 	integer 	:= 32;
		AddrWidth	:	integer 	:= 8
	);
	port(
		-------------------------------------------------------------
		-- Clock / Reset
		-------------------------------------------------------------
		CLK		:	in			std_logic;
		RST_N	:	in			std_logic;
		-------------------------------------------------------------
		-- Serial
		-------------------------------------------------------------
		TxD		:	out			std_logic	:=	'1';
		RxD		:	in			std_logic;
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
end UART_IF;
	
architecture behavioral of UART_IF is
	-------------------------------------------------------------
	-- FIFO interface
	-------------------------------------------------------------
	constant c_DEPTH    	: integer := 16;
	constant c_WIDTH    	: integer := 8;
	constant c_AF_LEVEL 	: integer := 14;
	constant c_AE_LEVEL 	: integer := 2;
	signal 	r_WR_EN,r_RD_EN	: std_logic;
	signal	w_RD_DATA		: std_logic_vector(c_WIDTH - 1 downto 0);
	signal 	r_WR_DATA 		: std_logic_vector(c_WIDTH - 1 downto 0);
	-------------------------------------------------------------
	-- status/control registers
	-------------------------------------------------------------
	signal	control,status	: std_logic_vector(7 downto 0)	
							:=	(others => '0');
	alias	tx_full			: std_logic		is	status(0);
	alias	tx_empty		: std_logic		is	status(1);
	alias	rx_full			: std_logic		is	status(2);
	alias	rx_empty		: std_logic		is	status(3);
	
begin
	
	U0_Rx_FIFO: entity work.module_fifo_regs_with_flags
	generic map (
		g_WIDTH    	=> c_WIDTH,
		g_DEPTH    	=> c_DEPTH,
		g_AF_LEVEL 	=> c_AF_LEVEL,
		g_AE_LEVEL 	=> c_AE_LEVEL
	)
	port map (
		i_nrst_sync => RST_N,
		i_clk      	=> CLK,
	------------------------------------------------	
		i_wr_data  	=> r_WR_DATA,
		i_wr_en    	=> r_WR_EN,
		o_af       	=> open,
		o_full     	=> tx_full,
		i_rd_en    	=> r_RD_EN,
		o_rd_data  	=> w_RD_DATA,
		o_ae       	=> open,
		o_empty    	=> tx_empty
	------------------------------------------------	
	);
	
	process (CLK, RD_STRB)
    begin
		-- Write mechanism
		if (rising_edge(CLK)) then
            if (WR_STRB = '1' and CS = '1') then
				if(NMASK(0) = '0' and ADDR = "00") then
					r_WR_EN	<=	'1';
					r_WR_DATA <= IBUS(c_WIDTH - 1 downto 0);
				end if;
			else
				r_WR_EN	<=	'0';
			end if;
		end if;
		
		-- Read mechanism 
		OBUS		<=	(others => 'Z');
		if(RD_STRB = '1' and CS = '1' and ADDR = "01") then
			OBUS(c_WIDTH - 1 downto 0) 	<= w_RD_DATA;
			r_RD_EN	<=	'1';
		else	
			r_RD_EN	<=	'0';
		end if;
		
	end process;

end behavioral;