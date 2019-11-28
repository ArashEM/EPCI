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
use IEEE.STD_LOGIC_1164.all;

package board_config_pkg is

	constant	EPCI_FW_MAJOR	:	std_logic_vector(7 downto 0)	:= x"01";
	constant	EPCI_FW_MINOR	:	std_logic_vector(7 downto 0)	:= x"04";
	constant	EPCI_BUILD_NUM	:	std_logic_vector(15 downto 0)	:= x"0000";
	constant	EPCI_FW_VER		:	std_logic_vector(31 downto 0)	
								:=	EPCI_FW_MAJOR & 
									EPCI_FW_MINOR & 
									EPCI_BUILD_NUM;

end board_config_pkg;

package body board_config_pkg is
 
end board_config_pkg;
