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
USE IEEE.NUMERIC_STD.ALL;
--********************************************************
use work.parity.all;
use work.board_config_pkg.ALL;


entity epci_top is
	generic 
	(
		BusWidth	: integer 						:= 32;
		AddrWidth	: integer 						:= 16;
		GPIOWidth	: integer						:= 4;
		LEDWidth	: integer						:= 3;
		FW_VER		: std_logic_vector(31 downto 0)	:=	EPCI_FW_VER
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
		LEDS				: 	out 	std_logic_vector(LEDWidth - 1 downto 0)	
							:=	(others => '0');
		UART_TX				:	out		std_logic	:=	'0';
		UART_RX				:	in		std_logic;
		GPIO				:	inout	std_logic_vector(GPIOWidth - 1 downto 0)
							:=	(others => 'Z');
		I2C_SDA				:	inout	std_logic	:=	'Z';
		I2C_SCL				:	out		std_logic	:=	'0';
		pci_prsnt_o 		:	out		std_logic	:=	'1';
		pci_bus_en_o		:	out		std_logic	:=	'1'
	);
end epci_top;

architecture behavioral of epci_top is
	
	----------------------------------------------------------------
	signal		bus_address	:	std_logic_vector(AddrWidth - 1 downto 0);
	signal		bus_w_data	:	std_logic_vector(BusWidth - 1 downto 0);
	signal		bus_r_data	:	std_logic_vector(BusWidth - 1 downto 0);
	signal		bus_rd_strb	:	std_logic;
	signal		bus_wr_strb	:	std_logic;
	signal		bus_nmask	:	std_logic_vector(BusWidth/8 - 1 downto 0);
	-----------------------------------------------------------------
	signal		U1_mem_CS	:	std_logic;
	-----------------------------------------------------------------
	signal		U2_GPIO_CS	:	std_logic;
	----------------------------------------------------------------
	signal		U3_LEDS_CS	:	std_logic;
	----------------------------------------------------------------
	-- Address Map
	--###########################################################
	--	(0		, 0x8000)	:	BRAM 	(8K x 32 bit)
	--	(0x8000	, 0x8010)	:	GPIO	(4	x 32 bit)
	--	(0x8010	, 0x8020)	:	LEDs	(4	x 32 bit)
	--###########################################################
	
	constant	BRAM_ADDR_W	:	integer		
							:=	13;					-- 8K x 32 bit
							
	-- offset address must be aligned to address width according to AddrWidth
	constant	BRAM_SIZE	:	integer		
							:=	BRAM_ADDR_W + 2;	-- 32 bit bus width
							
	constant	BRAM_BASE	:	std_logic_vector(
									AddrWidth - 1 downto 0)	
							:=	x"0000";
							
	constant	BRAM_MASK	:	std_logic_vector(
									AddrWidth - BRAM_SIZE - 1 downto 0
								)
							:=	BRAM_BASE(AddrWidth - 1 downto BRAM_SIZE);
	-----------------------------------------------------------------------------
	constant	GPIO_ADDR_W	:	integer		
							:=	1;			-- 2 x 32 bit
							
	constant	GPIO_SIZE	:	integer	
							:=	GPIO_ADDR_W + 2;	-- 32 bit bus width
							
	constant	GPIO_BASE	:	std_logic_vector(
									AddrWidth - 1 downto 0)	
							:=	x"8000";			
	constant	GPIO_MASK	:	std_logic_vector(
									AddrWidth - GPIO_SIZE - 1 downto 0
								)
							:=	GPIO_BASE(AddrWidth - 1 downto GPIO_SIZE);
	-----------------------------------------------------------------------------
	constant	LED_ADDR_W	:	integer		
							:=	2;			-- 4 x 32 bit
							
	constant	LED_SIZE	:	integer	
							:=	LED_ADDR_W + 2;	-- 32 bit bus width
							
	constant	LED_BASE	:	std_logic_vector(
									AddrWidth - 1 downto 0)	
							:=	x"8010";			
	constant	LED_MASK	:	std_logic_vector(
									AddrWidth - LED_SIZE - 1 downto 0
								)
							:=	LED_BASE(AddrWidth - 1 downto LED_SIZE);

begin	

	U0_PCI : entity work.pci33_bridge
	generic map (
		BusWidth	=>	BusWidth,
		AddrWidth	=>	AddrWidth,
		FW_VER		=>	FW_VER
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
		NMASK		=>	bus_nmask,
		RD_STRB		=>	bus_rd_strb,
		WR_STRB		=>	bus_wr_strb
	);

	--%<-------------------------------%<---------------------------
	U1_MEM: entity work.BRAM
	generic map (
		BusWidth	=>	BusWidth,
		AddrWidth	=>	BRAM_ADDR_W
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
		ADDR		=>	bus_address(BRAM_SIZE - 1 downto 2),
		OBUS		=>	bus_r_data,
		IBUS		=>	bus_w_data,
		NMASK		=>	bus_nmask,
		RD_STRB		=>	bus_rd_strb,
		WR_STRB		=>	bus_wr_strb
	);
	
	--%<-------------------------------%<---------------------------
	U2_GPIO:	entity	work.GPIO
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
		-- oport		=>	NULL,
		-------------------------------------------------------------
		-- Memory Map interface
		-------------------------------------------------------------
		CS			=>	U2_GPIO_CS,
		ADDR		=>	bus_address(7 downto 0),
		OBUS		=>	bus_r_data,
		IBUS		=>	bus_w_data,
		RD_STRB		=>	bus_rd_strb,
		WR_STRB		=>	bus_wr_strb
	);
	--%<-------------------------------%<---------------------------
	U3_LEDs: entity work.LED 
	generic map (
		BusWidth	=>	BusWidth,
		AddrWidth	=>	LED_ADDR_W,
		NumLEDs		=>	LEDWidth
	)
	port map (
		-------------------------------------------------------------
		-- Clock / Reset
		-------------------------------------------------------------
		CLK			=>	PCLK,
		RST_N		=> 	NRST,
		-------------------------------------------------------------
		-- Input / Output port
		-------------------------------------------------------------
		leds		=>	LEDS,
		-------------------------------------------------------------
		-- Memory Map interface
		-------------------------------------------------------------
		CS			=>	U3_LEDS_CS,
		ADDR		=>	bus_address(LED_SIZE - 1 downto 2),
		OBUS		=>	bus_r_data,
		IBUS		=>	bus_w_data,
		NMASK		=>	bus_nmask,
		RD_STRB		=>	bus_rd_strb,
		WR_STRB		=>	bus_wr_strb
	);
	
	Decode: process(bus_address, bus_rd_strb, bus_wr_strb) 
	begin
		-- BRAM 
		if(bus_address(AddrWidth - 1 downto BRAM_SIZE) = BRAM_MASK) then
			U1_mem_CS	<=	'1';
		else
			U1_mem_CS	<=	'0';
		end if;
		
		-- GPIO
		if(bus_address(AddrWidth - 1 downto GPIO_SIZE ) = GPIO_MASK) then
			U2_GPIO_CS	<=	'1';
		else
			U2_GPIO_CS	<=	'0';
		end if;
		
		-- LED
		if(bus_address(AddrWidth - 1 downto LED_SIZE ) = LED_MASK) then
			U3_LEDS_CS	<=	'1';
		else
			U3_LEDS_CS	<=	'0';
		end if;
		
	end process;

end behavioral;

