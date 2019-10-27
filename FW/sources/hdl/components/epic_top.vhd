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
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.parity.all;


entity epic_top is
	generic 
	(
		BusWidth	: integer 	:= 32;
		AddrWidth	: integer 	:= 16;
		IOWidth		: integer	:= 3
	);    
	port 
	( 
		---------------------------------------------------------------
		-- PCI interface
		---------------------------------------------------------------
		AD 		: 	inout  		std_logic_vector (31 downto 0);
		NCBE 	: 	in  		std_logic_vector (3 downto 0);
		PAR 	: 	inout  		std_logic;
		NFRAME 	: 	in  		std_logic;
		NIRDY 	: 	in  		std_logic;
		NTRDY 	: 	out  		std_logic;
		NSTOP 	: 	out  		std_logic;
		NLOCK 	: 	in  		std_logic		:=		'1';
		IDSEL 	: 	in  		std_logic;
		NDEVSEL : 	inout  		std_logic; 		-- inout is kludge
		NPERR 	: 	out  		std_logic;
		NSERR 	: 	out  		std_logic;
		NINTA 	: 	out  		std_logic;
		NRST 	: 	in  		std_logic;
		NREQ 	: 	out 		std_logic;
		PCLK  	: 	in	 		std_logic; 		-- PCI clock	
		XCLK	: 	in 			std_logic;		-- Xtal clock
		NINIT	: 	out 		std_logic			:=	'0';
		---------------------------------------------------------------
		-- General signals
		---------------------------------------------------------------
		LEDS				: 	out 	std_logic_vector(2 downto 0)	:=	"000";
		pci_prsnt_o 		:	out		std_logic	:=	'1';
		pci_bus_en_o		:	out		std_logic	:=	'1'
	);
end epic_top;

architecture behavioral of epic_top is
	
	----------------------------------------------------------------
	signal		bus_address	:	std_logic_vector(AddrWidth - 1 downto 0);
	signal		bus_w_data	:	std_logic_vector(BusWidth - 1 downto 0);
	signal		bus_r_data	:	std_logic_vector(BusWidth - 1 downto 0);
	signal		bus_rd_strb	:	std_logic;
	signal		bus_wr_strb	:	std_logic;
	-----------------------------------------------------------------
	signal		U1_mem_CS	:	std_logic;
	-----------------------------------------------------------------
	signal		U2_LED_CS	:	std_logic;

begin	

	U0_PCI : entity work.pci33_bridge
	generic map (
		BusWidth	=>	BusWidth,
		AddrWidth	=>	AddrWidth
	)
	port map(
		-------------------------------------------------------------
		--	PCI interface
		-------------------------------------------------------------
		AD 			=>	AD, 			
		NCBE 		=>  NCBE, 		
		PAR 		=>  PAR, 		
		NFRAME 		=>  NFRAME, 		
		NIRDY 		=>  NIRDY, 		
		NTRDY 		=>  NTRDY, 		
		NSTOP 		=>  NSTOP, 		
		NLOCK 		=>  NLOCK, 		
		IDSEL 		=>  IDSEL, 		
		NDEVSEL 	=>  NDEVSEL, 	
		NPERR 		=>  NPERR, 		
		NSERR 		=>  NSERR, 		
		NINTA 		=>  NINTA, 		
		NRST 		=>  NRST, 		
		NREQ 		=>  NREQ, 		
		PCLK  		=>  PCLK,  		
		XCLK		=>  XCLK,		
		NINIT		=>  NINIT,		
		-------------------------------------------------------------
		-- Memory Map interface
		-------------------------------------------------------------
		ADDR		=>	bus_address,
		OBUS		=>	bus_w_data,
		IBUS		=>	bus_r_data,
		RD_STRB		=>	bus_rd_strb,
		WR_STRB		=>	bus_wr_strb
	);

	U1_MEM: entity work.BRAM
	generic map (
		BusWidth	=>	BusWidth,
		AddrWidth	=>	8
	)
	port map(
		-------------------------------------------------------------
		-- Clock / Reset
		-------------------------------------------------------------
		CLK			=>	PCLK,
		-------------------------------------------------------------
		-- Memory Map interface
		-------------------------------------------------------------
		CS			=>	U1_mem_CS,
		ADDR		=>	bus_address(7 downto 0),
		OBUS		=>	bus_r_data,
		IBUS		=>	bus_w_data,
		RD_STRB		=>	bus_rd_strb,
		WR_STRB		=>	bus_wr_strb
	);
	
	U2_LED:	entity	work.GPIO
	generic map
		(
			BusWidth	=>	BusWidth,
			AddrWidth	=>	8,
			PortWidth	=> 	3
		)
	port map(
		-------------------------------------------------------------
		-- Clock / Reset
		-------------------------------------------------------------
		CLK			=>	PCLK,
		RST_N		=> 	NRST,
		-------------------------------------------------------------
		-- Input / Output port
		-------------------------------------------------------------
		oport		=>	LEDS,
		-------------------------------------------------------------
		-- Memory Map interface
		-------------------------------------------------------------
		CS			=>	U2_LED_CS,
		ADDR		=>	bus_address(7 downto 0),
		OBUS		=>	bus_r_data,
		IBUS		=>	bus_w_data,
		RD_STRB		=>	bus_rd_strb,
		WR_STRB		=>	bus_wr_strb
	);
	
	
	Decode: process(bus_address, bus_rd_strb, bus_wr_strb) 
	begin
		
		-- BRAM on address (0x0000 to 0x00FF)
		if(bus_address(15 downto 8) = x"00") then
			U1_mem_CS	<=	'1';
		else
			U1_mem_CS	<=	'0';
		end if;
		
		if(bus_address(15 downto 8) = x"01") then
			U2_LED_CS	<=	'1';
		else
			U2_LED_CS	<=	'0';
		end if;
		
	end process;

end behavioral;

