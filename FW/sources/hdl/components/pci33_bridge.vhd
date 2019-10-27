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


entity pci33_bridge is
	generic 
	(
		BusWidth: integer := 32;
		AddrWidth: integer := 16
	);    
	port 
	( 
		-------------------------------------------------------------
		--	PCI interface
		-------------------------------------------------------------
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
		-------------------------------------------------------------
		-- Memory Map interface
		-------------------------------------------------------------
		ADDR	:	out			std_logic_vector(AddrWidth - 1 downto 0);
		OBUS	:	out			std_logic_vector(BusWidth - 1  downto 0);
		IBUS	:	in			std_logic_vector(BusWidth - 1 downto 0);
		RD_STRB	:	out			std_logic;
		WR_STRB	:	out			std_logic
		
	);
end pci33_bridge;

architecture behavioral of pci33_bridge is
	
-- PCI constants
	constant InterruptAck 		: std_logic_vector(3 downto 0) := x"0";
	constant SpecialCycle 		: std_logic_vector(3 downto 0) := x"1";
	constant IORead 			: std_logic_vector(3 downto 0) := x"2";
	constant IOWrite 			: std_logic_vector(3 downto 0) := x"3";
	constant MemRead 			: std_logic_vector(3 downto 0) := x"6";
	constant MemWrite 			: std_logic_vector(3 downto 0) := x"7";
	constant ConfigRead 		: std_logic_vector(3 downto 0) := x"A";
	constant ConfigWrite 		: std_logic_vector(3 downto 0) := x"B";
	constant MemReadMultiple 	: std_logic_vector(3 downto 0) := x"C";
	constant DualAddressCycle 	: std_logic_vector(3 downto 0) := x"D";
	constant MemReadLine 		: std_logic_vector(3 downto 0) := x"E";
	constant MemWriteandInv 	: std_logic_vector(3 downto 0) := x"F";
	
	
	constant DIDVIDAddr 		: std_logic_vector(7 downto 0) := x"00";	
	constant StatComAddr 		: std_logic_vector(7 downto 0) := x"04";
	constant ClassRevAddr 		: std_logic_vector(7 downto 0) := x"08"; 
	constant ClassRev 			: std_logic_vector(31 downto 0) := x"11000002";  -- data acq & rev 1                                                                                                                                                                                                                                                                                                                                                                                                                                                                            
	--constant ClassRev 		: std_logic_vector(31 downto 0) := x"07010000";    -- parallel port                                                                                                                                                                                                                                                                                                                                                                                                                                                                           
	constant MiscAddr 			: std_logic_vector(7 downto 0) := x"0C";
	constant MiscReg 			: std_logic_vector(31 downto 0) := x"00000000";
	constant SSIDAddr 			: std_logic_vector(7 downto 0) := x"2C";
	constant BAR0Addr 			: std_logic_vector(7 downto 0) := x"10";
	constant IntAddr 			: std_logic_vector(7 downto 0) := x"3C";
	constant DIDVID 			: std_logic_vector(31 downto 0) := x"060010EE";		
	constant SSID 				: std_logic_vector(31 downto 0) := x"060010EE";
	
	-- Misc global signals --
	signal D					: std_logic_vector (BusWidth-1 downto 0);			-- internal data bus
	signal A					: std_logic_vector (BusWidth-1 downto 0);
	
	signal DataStrobe: std_logic;
	signal ReadStb: std_logic;
	signal WriteStb: std_logic;
	signal ConfigReadStb: std_logic;
	signal ConfigWriteStb: std_logic;
	
	-- PCI bus interface signals
	signal NFrame1 : std_logic;
	signal IDevSel : std_logic;
	signal IDevSel1 : std_logic;
	signal IDevSel2 : std_logic;
	signal LIDSel : std_logic;
	signal Lint : std_logic		:=	'1';
	signal PerrStb : std_logic;
	signal PerrStb1 : std_logic;
	signal PerrStb2 : std_logic;
	signal StatPerr : std_logic;
	signal SerrStb : std_logic;
	signal SerrStb1 : std_logic;
	--signal SerrStb2 : std_logic;
	signal StatSerr : std_logic;
	signal PCIFrame : std_logic;
	signal ITRDY : std_logic;
	signal ITRDY1 : std_logic;
	signal IStop : std_logic;    
	signal Selected : std_logic;  
	signal ConfigSelect : std_logic;
	signal NormalSelect : std_logic;  
	signal IPar : std_logic;
	signal CPar : std_logic;
	signal PAR1 : std_logic;
	signal BusCmd : std_logic_vector(3 downto 0);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       
	signal ADDrive : std_logic;  
	signal ParDrive : std_logic; 
	signal BusRead : std_logic; 
	-- signal BusRead1 : std_logic; 
	-- signal BusRead2 : std_logic; 
	signal BusWrite : std_logic; 
	signal BusWrite1 : std_logic; 
	signal BusWrite2 : std_logic; 
	
-- PCI configuration space registers
	signal StatComReg : std_logic_vector(31 downto 0) := x"02000000"; -- medium devsel
	alias MemEna : std_logic is StatComReg(1);
	alias ParEna : std_logic is StatComReg(6);
	alias SerrEna : std_logic is StatComReg(8);
	alias IntDis : std_logic is StatComReg(10);
	signal BAR0Reg : std_logic_vector(31 downto 0) := x"00000000";
	signal IntReg : std_logic_vector(31 downto 0) := x"00000100";

-- BRAM interface
	type ram_type is array (0 to 255) of std_logic_vector(31 downto 0);
	signal RAM : ram_type := 	(others => x"AACCBBDD");
	signal dradd : std_logic_vector(7 downto 0);
	signal readout : std_logic_vector(31 downto 0); 
	
begin

	ADDrivers: process (D,ADDrive)
	begin 
		if  ADDrive	='1' then	
			AD <= D;
		else
			AD <= (others => 'Z');			
		end if;
	end process ADDrivers;

	BusCycleGen: process (PCLK, NIRDY, DataStrobe, ConfigSelect, PCIFrame, A, 
								 IDevSel, IdevSel1, IDevSel2, ITRDY, ITRDY1, ISTOP, ParDrive, IPar, CPar, 
								 LIDSel, Bar0Reg, BusCmd, LInt, IntReg, ConfigSelect, BusRead,Selected,
								 NCBE, NormalSelect, SerrStb1, PerrStb2, StatComReg, BusWrite1,BusWrite2)		-- to do: parity error reporting in status
	begin 
		if rising_edge(PCLK) then
			if  NFRAME = '0' and Nframe1 = '1' then 	-- falling edge of NFRAME = start of frame
				A <= AD;											-- so latch address and PCI command	
				BusCmd <= NCBE;
				PCIFrame <= '1';
				SerrStb <= '1';
				LIDSel <= IDSEL;
			else
				SerrStb <= '0';
			end if;

			if PCIFrame = '1' then							-- if we are in a PCI frame, check if we are selected
				if Selected = '1' then
					IDevSel <= '1';							-- if so assert DEVSEL
				end if;
			end if;

			if IDevSel = '1' then
				if NIRDY = '0' then
					ITRDY <= '1';								-- note one clock delay for one wait state;
				end if;
				if ITRDY = '1' then 							-- only asserted for one clock
					ITRDY <= '0';
				end if;
			end if;

			if	(NFRAME = '1') then		-- any time frame is high end frame
				PCIFrame <= '0';
				if (NIRDY= '0') and (ITRDY = '1') then	-- if frame is de-asserted and we have a data transfer, we're done
					IDevSel <= '0';
				end if;	
			end if;			

			if (NIRDY = '0') and (ITRDY = '1') and (NCBE /= x"F") then 	-- increment address after every transfer
				A <= A + 4;
			end if;	
			
			IDevSel2 <= IDevSel1;
			IDevSel1 <= IDevSel;

--			BusRead2 <= BusRead1;
--			BusRead1 <= BusRead;

			BusWrite2 <= BusWrite1;
			BusWrite1 <= BusWrite;

			PerrStb2 <= PerrStb1;
			PerrStb1 <= PerrStb;

--			SerrStb2 <= SerrStb1;
			SerrStb1 <= SerrStb;
						
					
			NFrame1 <= NFRAME;
			PAR1 <= PAR;
			ITRDY1	<=	ITRDY;

			IStop <= '0';			-- for  now
			
			IPar <= parity(AD&NCBE&'0');		-- Parity generation 1 clock behind data (0 is even reminder)
			CPar <= IPar xor PAR1;			   -- Parity check 2 clocks behind data (high = error)
			ParDrive <= ADDrive;					-- 1 clock behind AD Tristate

			if NRST = '0' then
				PCIFrame <= '0';
				IDevSel <= '0';
				ITRDY <= '0';
			end if;			
		end if; -- clk


		if NIRDY = '0' and ITRDY = '1' and (NCBE /= x"F") then -- data cycle when IRDY AND TRDY and a least one byte enable
			DataStrobe <= '1';
		else
			DataStrobe <= '0';
		end if;	
		
		if (DataStrobe = '1') and ((BusCmd = MemRead) or (BusCmd = MemReadMultiple)) then
			ReadStb<= '1';
		else
			ReadStb <= '0';
		end if;	

		if (DataStrobe = '1') and (BusCmd = MemWrite) then
			WriteStb <= '1';
		else
			WriteStb <= '0';
		end if;	

		if DataStrobe = '1' and (BusCmd = ConfigRead) then
			ConfigReadStb <= '1';
		else
			ConfigReadStb <= '0';
		end if;	

		if DataStrobe = '1' and (BusCmd = ConfigWrite) then
			ConfigWriteStb <= '1';
		else
			ConfigWriteStb <= '0';
		end if;	

		if DataStrobe = '1' and ((BusCmd = MemWrite) or (BusCmd = ConfigWrite)) then
			PErrStb <= '1';
		else
			PErrStb <= '0';
		end if;			
		
		Selected <= (ConfigSelect or (NormalSelect and MemEna));
				
		if ((PCIFrame = '1') and (Selected='1')) or (IDevSel= '1') or (IDevSel1 = '1') then					-- keep driving NDEVSEL/NTRDY/NSTOP one clock after IDevsel de-sasserted	
			NDEVSEL <= not IDevSel;
			NTRDY <= not ITRDY;
			NSTOP <= not IStop;
		else
			NDEVSEL <= 'Z';
			NTRDY <= 'Z';
			NSTOP <= 'Z';
		end if;	
		
		if (IdevSel = '1') and (busread = '1') then
			ADDrive <= '1';
		else
			ADDrive <= '0';
		end if;	

		if ParDrive = '1' then				-- PAR is driven with the AD buffer enable signal but one clock later
			PAR <= IPar;
		else
			PAR <= 'Z';
		end if;	
		
		if ((IDevSel1 = '1') or (IdevSel2 = '1')) and ((BusWrite1 = '1') or (BusWrite2 = '1')) then
			NPERR <= not (CPar and PerrStb2 and ParEna);
			StatPerr <= (CPar and PerrStb2);
		else
			NPERR <= 'Z';
			StatPerr <= '0';
		end if;	

		if ((IDevSel = '1') and (SerrStb1 = '1') and (SerrEna = '1') and (ParEna = '1')) then
			NSERR <= not CPar;
			StatSerr <= CPar;
		else
			NSERR <= 'Z';
			StatSerr <= '0';
			
		end if;	
				
		if (LIDSel = '1') and ((BusCmd = ConfigRead) or (BusCmd = ConfigWrite)) then
			ConfigSelect <= '1';
		else
			ConfigSelect <= '0';
		end if;		
		
		if (Bar0Reg(31 downto 16) = A(31 downto 16)) and (MemEna = '1') and ((BusCmd = MemRead) or (BusCmd = MemReadMultiple) or (BusCmd = MemWrite)) then			-- hard wired for 64 K select
			NormalSelect <= '1';
		else
			NormalSelect <= '0';
		end if;	
	
		if (BusCmd = MemRead) or (BusCmd = MemReadMultiple) or (BusCmd = ConfigRead) then
			BusRead <= '1';
		else
			BusRead <= '0';
		end if;	

		if ((BusCmd = MemWrite) or (BusCmd = ConfigWrite)) then
			BusWrite <= '1';
		else
			BusWrite <= '0';
		end if;	
		
		if (LINT = '0') and IntDis = '0' then
			NINTA <= '0';
		else
			NINTA <= 'Z';
		end if;	
			
	end process BusCycleGen;
	
	PCIConfig : process (PCLK, A, ConfigSelect, BusCmd, LInt, StatComReg, Bar0Reg, IntReg)
	begin

		-- first the config space reads
		D <= (others => 'Z');
		StatComReg(19) <= not LINT;
		if (ConfigSelect = '1') and (BusCmd = ConfigRead) then
			case A(7 downto 0) is
				when DIDVIDAddr  	=> 	D <= DIDVID;
				when StatComAddr  	=> 	D <= StatComReg;
				when ClassRevAddr 	=> 	D <= ClassRev;
				when MiscAddr		=>	D <= MiscReg;
				when BAR0Addr		=>	D <= BAR0Reg;
				when SSIDAddr		=>	D <= SSID;
				when IntAddr		=> 	D <= IntReg;	
				when others			=>	D <= (others => '0'); 	-- all unused config space reads as 0s
			end case;
		end if;		
		
		-- then the config space writes
		if rising_edge(PCLK) then
			if StatPerr = '1' then
				StatComReg(31) <= '1'; -- signal data parity error in status reg
			end if;	
			if StatSerr = '1' then
				StatComReg(30) <= '1'; -- signal address parity error in status reg
			end if;	
			if (ConfigSelect = '1') and (BusCmd = ConfigWrite) and (DataStrobe = '1') then			
				case A(7 downto 0) is
					when StatComAddr  => 
						if NCBE(0) = '0' then 
							StatComReg(1) <= AD(1);	-- MemEna
							StatComReg(6) <= AD(6); -- ParEna
						end if;	
						if NCBE(1) = '0' then	
							StatComReg(8) <= AD(8); -- SerrEna
							StatComReg(10) <= AD(10); -- IntDis
						end if;	
						if NCBE(3) = '0' then
							StatComReg(27) <= StatComReg(27) and not AD(27);  	-- status bits cleared when a 1 is written
							StatComReg(30) <= StatComReg(30) and not AD(30);
							StatComReg(31) <= StatComReg(31) and not AD(31);
						end if;
					when BAR0Addr		=>													-- 64K range so only top 16 bits used
						if NCBE(2) = '0' then 
							BAR0Reg(23 downto 16) <= AD(23 downto 16);
						end if;                                       
						if NCBE(3) = '0' then 
							BAR0Reg(31 downto 24) <= AD(31 downto 24);
						end if;				
					when IntAddr		=> 												-- only R/W byte of int reg supported
						if NCBE(0) = '0' then			
							IntReg(7 downto 0) <= AD(7 downto 0);
						end if;			
					when others			=>	null;
				end case;
			end if;		
			if NRST = '0' then
				BAR0Reg(31 downto 16) <= (others => '0');
				StatComReg <= x"02000000";
				IntReg <= x"00000100";
--				ledff0 <= '0';
--				ledff1 <= '0';
			end if;
		end if; -- clk	
	end process PCIConfig;
	
	PCILooseEnds : process (PCLK)
	begin
		NREQ <= '1';	
	end process PCILooseEnds;
	
	DDrive:	process (ReadStb)
    begin
		D			<=	(others => 'Z');
		if(ReadStb = '1') then
				D <= IBUS;
		end if;
    end process DDrive;

	OBUS	<=	AD;
	WR_STRB	<=	WriteStb;
	RD_STRB	<=	ReadStb;
	ADDR	<=	A(AddrWidth - 1 downto 0);

end behavioral;



