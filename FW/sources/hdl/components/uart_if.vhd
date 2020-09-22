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
	constant c_DEPTH    		: integer := 16;
	constant c_WIDTH    		: integer := 8;
	constant c_AF_LEVEL 		: integer := 14;
	constant c_AE_LEVEL 		: integer := 2;
	
	signal 	tx_fifo_wr_en,
			tx_fifo_rd_en,
			rx_fifo_wr_en,
			rx_fifo_rd_en 		: std_logic;
	signal 	tx_fifo_wr_data,
			tx_fifo_rd_data,
			rx_fifo_wr_data,
			rx_fifo_rd_data 	: std_logic_vector(c_WIDTH - 1 downto 0);
	signal	tx_en, tx_ready		: std_logic;
	signal	rx_valid,
			rx_frame_error		: std_logic;
	-------------------------------------------------------------
	-- status/control registers
	-------------------------------------------------------------
	signal	control,status	: std_logic_vector(7 downto 0)	
							:=	(others => '0');
	alias	tx_fifo_full	: std_logic		is	status(0);
	alias	tx_fifo_empty	: std_logic		is	status(1);
	alias	rx_full			: std_logic		is	status(2);
	alias	rx_empty		: std_logic		is	status(3);
	-------------------------------------------------------------
	-- uart
	-------------------------------------------------------------
	signal	RST				: std_logic	:=	'0';
	type state is (idle, wait_tx);
    signal tx_pstate : state;
    signal tx_nstate : state;
	
begin
	-------------------------------------------------------------
	-- Archtecture 
	--
	--	PCI	-> Tx_FIFO	->	UART-tx
	--	PCI <- Rx_FIFO	<-	UART-Rx
	-------------------------------------------------------------
	U0_Tx_FIFO: entity work.module_fifo_regs_with_flags
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
	-- From PCI interface 
		i_wr_data  	=> tx_fifo_wr_data,
		i_wr_en    	=> tx_fifo_wr_en,
		o_af       	=> open,
		o_full     	=> tx_fifo_full,
	-- To UART module 
		i_rd_en    	=> tx_fifo_rd_en,
		o_rd_data  	=> tx_fifo_rd_data,
		o_ae       	=> open,
		o_empty    	=> tx_fifo_empty
	------------------------------------------------	
	);
	
	U1_Rx_FIFO: entity work.module_fifo_regs_with_flags
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
	-- From UART module
		i_wr_data  	=> rx_fifo_wr_data,
		i_wr_en    	=> rx_fifo_wr_en,
		o_af       	=> open,
		o_full     	=> rx_full,
	-- To PCI interface
		i_rd_en    	=> rx_fifo_rd_en,
		o_rd_data  	=> rx_fifo_rd_data,
		o_ae       	=> open,
		o_empty    	=> rx_empty
	------------------------------------------------	
	);
	
	U3_uart: entity work.uart
	generic map (
		CLK_FREQ      	=> 33e6,   				-- system clock frequency in Hz
        BAUD_RATE     	=> 115200, 				-- baud rate value
        PARITY_BIT    	=> "none", 				-- type of parity: "none", "even", "odd", "mark", "space"
        USE_DEBOUNCER 	=> True    				-- enable/disable debouncer
	)
	port map (
		-- CLOCK AND RESET
        CLK           	=> 	CLK,				-- system clock
        RST           	=> 	RST, 				-- high active synchronous reset
        -- UART INTERFACE
        UART_TXD    	=> 	TxD,				-- serial transmit data
        UART_RXD    	=>	RxD,				-- serial receive data
        -- USER DATA INPUT INTERFACE
        DIN         	=>	tx_fifo_rd_data,	-- input data to be transmitted over UART
        DIN_VLD      	=>	tx_en,				-- when DIN_VLD = 1, input data (DIN) are valid
        DIN_RDY      	=>	tx_ready,			-- when DIN_RDY = 1, transmitter is ready and valid input data will be accepted for transmiting
        -- USER DATA OUTPUT INTERFACE
        DOUT         	=>	rx_fifo_wr_data,	-- output data received via UART
        DOUT_VLD     	=>	rx_valid,			-- when DOUT_VLD = 1, output data (DOUT) are valid (is assert only for one clock cycle)
        FRAME_ERROR  	=>	rx_frame_error		-- when FRAME_ERROR = 1
	);
	
	-------------------------------------------------------------
	-- Assignments
	-------------------------------------------------------------
	RST 	<=	not(RST_N);
	
	-------------------------------------------------------------
	-- PCI Read/Write 
	-------------------------------------------------------------
	process (CLK, RD_STRB)
    begin
		-- Write mechanism
		if (rising_edge(CLK)) then
            if (WR_STRB = '1' and CS = '1') then
				if(NMASK(0) = '0' and ADDR = "00") then
					tx_fifo_wr_en	<=	'1';
					tx_fifo_wr_data <= IBUS(c_WIDTH - 1 downto 0);
				end if;
			else
				tx_fifo_wr_en	<=	'0';
			end if;
		end if;
		
		-- Read mechanism 
		OBUS		<=	(others => 'Z');
		if(RD_STRB = '1' and CS = '1' and ADDR = "01") then
			OBUS(c_WIDTH - 1 downto 0) 	<= rx_fifo_rd_data;
			rx_fifo_rd_en	<=	'1';
		else	
			rx_fifo_rd_en	<=	'0';
		end if;
	end process;
	-------------------------------------------------------------
	-- FIFO Read/Write 
	-- 	tx_fifo_empty (in)
	-- 	tx_ready (in)
	-- 	tx_fifo_rd_en (out)
	-- 	tx_en (out)
	-------------------------------------------------------------
	fifo_to_uart_tx: process(CLK)
	begin
		if(rising_edge(CLK)) then
			if(RST_N = '0') then
				tx_pstate <= idle;
            else
                tx_pstate <= tx_nstate;
            end if;
		end if;
	end process;
	
	process(tx_pstate, tx_fifo_empty, tx_ready) 
	begin
		tx_en			<=	'0';
		tx_fifo_rd_en	<=	'0';
		case tx_pstate is
			when idle =>
				if(tx_fifo_empty = '0') then
					tx_nstate		<=	wait_tx;
					tx_en			<=	'1';
					tx_fifo_rd_en	<=	'1';
				else
					tx_nstate	<=	idle;
				end if;
			when wait_tx =>
				if(tx_ready = '1') then
					tx_nstate		<=	idle;
				else
					tx_nstate		<=	wait_tx;
				end if;
		end case;
	end process;

end behavioral;