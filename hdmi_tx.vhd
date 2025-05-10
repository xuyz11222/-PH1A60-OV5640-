-----------------------------------------------------
-- Company: anlgoic
-- Author: 	xg 
-----------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_arith.all;


entity uihdmitx is
	 Generic (FAMILY : STRING := "EG4");
	Port (
		PCLKX1_i : in STD_LOGIC;
        --PCLKX2_5_i : in STD_LOGIC;,
		PCLKX5_i : in STD_LOGIC;
		RSTn_i : in STD_LOGIC;

		--VGA
		HS_i : in std_logic;
		VS_i : in std_logic;
		DE_i : in std_logic;
		RGB_i : in std_logic_vector(23 downto 0);

		--HDMI
		HDMI_CLK_P : out  STD_LOGIC;
		HDMI_TX_P : out std_logic_vector(2 downto 0)	
	);
			  
end uihdmitx;

architecture Behavioral of uihdmitx is

component DVITransmitter is
	 Generic (FAMILY : STRING := "PH1");
    Port ( RED_I : in  STD_LOGIC_VECTOR (7 downto 0);
           GREEN_I : in  STD_LOGIC_VECTOR (7 downto 0);
           BLUE_I : in  STD_LOGIC_VECTOR (7 downto 0);
           HS_I : in  STD_LOGIC;
           VS_I : in  STD_LOGIC;
           VDE_I : in  STD_LOGIC;
		   RST_I : in STD_LOGIC;
           PCLK_I : in  STD_LOGIC;
           PCLK_X5_I : in  STD_LOGIC;
           TMDS_TX_CLK_P : out  STD_LOGIC;
           TMDS_TX_2_P : out  STD_LOGIC;
           TMDS_TX_1_P : out  STD_LOGIC;
           TMDS_TX_0_P : out  STD_LOGIC
		   );
end component;

signal SysRst : std_logic;

begin

		
	Inst_DVITransmitter: DVITransmitter 
	GENERIC MAP (FAMILY => FAMILY)
	PORT MAP(
		RED_I   => RGB_i(23 downto 16),
		GREEN_I => RGB_i(15 downto 8),
		BLUE_I  => RGB_i(7 downto 0),
		HS_I    => HS_i,
		VS_I    => VS_i,
		VDE_I   => DE_i,
		RST_I   => RSTn_i,
		PCLK_I  => PCLKX1_i,
		PCLK_X5_I     => PCLKX5_i,
		TMDS_TX_CLK_P => HDMI_CLK_P,
		TMDS_TX_2_P   => HDMI_TX_P(2),
		TMDS_TX_1_P   => HDMI_TX_P(1),
		TMDS_TX_0_P   => HDMI_TX_P(0)
		
	);
	
end Behavioral;

