-----------------------------------------------------
-- Company: anlgoic
-- Author: 	xg 
-----------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;



entity DVITransmitter is
	 Generic (FAMILY : STRING := "EG4");
	 
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
end DVITransmitter;

`protect begin

architecture Behavioral of DVITransmitter is
signal intTmdsRed, intTmdsGreen, intTmdsBlue : std_logic_vector(9 downto 0);
signal tmds_p, tmds_n : std_logic_vector(3 downto 0);
signal int_rst, SerClk : std_logic;

constant CLKIN_PERIOD : REAL := 13.468; --ns = 74.25MHz (maximum supported pixel clock)
constant N : NATURAL := 10; --serialization factor
constant PLLO0 : NATURAL := 1;	-- SERCLK = PCLK * N
constant PLLO2 : NATURAL := PLLO0 * N; -- PCLK = PCLK * N / N
constant PLLO3 : NATURAL := PLLO0 * N / 2;	-- PCLK_X2 = PLCK * N / (N/2)
signal intfb, intfb_buf, intpllout_x2, pllout_xs, pllout_x1, pllout_x2: std_logic;
signal PClk, PClk_x2, PllLckd, intRst, BufPllLckd, SerStb : std_logic;





component Serial_N_1_lvds is
	 Generic ( 	N : NATURAL := 10;
					FAMILY : STRING := "EG4");
    Port ( 	DP_I : in  STD_LOGIC_VECTOR (N-1 downto 0);
			PCLK : in  STD_LOGIC; 
			SCLK : in STD_LOGIC; 
			DSP_O : out  STD_LOGIC
			);
end component;

component Serial_N_1_lvds_dat is
	 Generic ( 	N : NATURAL := 10;
					FAMILY : STRING := "EG4");
    Port ( 	DP_I : in  STD_LOGIC_VECTOR (N-1 downto 0);
			PCLK : in  STD_LOGIC; 
			SCLK : in STD_LOGIC; 
			DSP_O : out  STD_LOGIC
			);
end component;



component TMDSEncoder is
    Port ( 	D_I : in  STD_LOGIC_VECTOR (7 downto 0);
			C0_I : in  STD_LOGIC;
			C1_I : in  STD_LOGIC;
			DE_I : in  STD_LOGIC;
			CLK_I: in STD_LOGIC;
			RST_I: in STD_LOGIC;
			D_O : out  STD_LOGIC_VECTOR (9 downto 0));
end component;

signal  test_p,test_n : std_logic;

begin



PClk <= PCLK_I;
SerClk <= PCLK_X5_I;
intRst <= RST_I;

----------------------------------------------------------------------------------
-- DVI Encoder; DVI 1.0 Specifications
-- This component encodes 24-bit RGB video frames with sync signals into 10-bit
-- TMDS characters.
----------------------------------------------------------------------------------
	Inst_TMDSEncoder_red: TMDSEncoder PORT MAP(
		D_I => RED_I,
		C0_I => '0',
		C1_I => '0',
		DE_I => VDE_I,
		CLK_I => PClk,
		RST_I => intRst,
		D_O => intTmdsRed
	);
	Inst_TMDSEncoder_green: TMDSEncoder PORT MAP(
		D_I => GREEN_I,
		C0_I => '0',
		C1_I => '0',
		DE_I => VDE_I,
		CLK_I => PClk,
		RST_I => intRst,
		D_O => intTmdsGreen
	);
	Inst_TMDSEncoder_blue: TMDSEncoder PORT MAP(
		D_I => BLUE_I,
		C0_I => HS_I,
		C1_I => VS_I,
		DE_I => VDE_I,
		CLK_I => PClk,
		RST_I => intRst,
		D_O => intTmdsBlue
	);
	
----------------------------------------------------------------------------------
-- TMDS serializer; ratio of 10:1; 3 data & 1 clock channel
-- Since the TMDS clock's period is character-long (10-bit periods), the
-- serialization of "1111100000" will result in a 10-bit long clock period.
----------------------------------------------------------------------------------

	Inst_clk_serializer_10_1: Serial_N_1_lvds GENERIC MAP (10, FAMILY)  ----normal is 1111100000
	PORT MAP(
		DP_I => "0000011111",
		PCLK => PClk,
		SCLK => SerClk,
		DSP_O => TMDS_TX_CLK_P
	);
	Inst_red_serializer_10_1: Serial_N_1_lvds_dat GENERIC MAP (10, FAMILY)  ----normal is 1111100000
	PORT MAP(
		DP_I => intTmdsRed,  --conv_std_logic_vector(852,10), --"1100100001", --"1100100001", --
		PCLK => PClk,
		SCLK => SerClk,
		DSP_O => TMDS_TX_2_P
	);  
	Inst_green_serializer_10_1: Serial_N_1_lvds_dat GENERIC MAP (10, FAMILY)  ----normal is 1111100000
	PORT MAP(
		DP_I => intTmdsGreen,  --conv_std_logic_vector(852,10), --
		PCLK => PClk,
		SCLK => SerClk,
		DSP_O => TMDS_TX_1_P
	);
	Inst_blue_serializer_10_1: Serial_N_1_lvds_dat GENERIC MAP (10, FAMILY)  ----normal is 1111100000
	PORT MAP(
		DP_I => intTmdsBlue,  --conv_std_logic_vector(171,10), --"1100100001", --
		PCLK => PClk,
		SCLK => SerClk,
		DSP_O => TMDS_TX_0_P
	);




--	 lvds_clk: SerializerN_1_lvds GENERIC MAP (10, FAMILY)  ----normal is 1111100000
--	 PORT MAP(
--		 DP_I => "1111100000",
--		 CLKDIV_I => PClk,
--		 SERCLK_I => SerClk,
--		 DSP_O => ODDR_CLK_TEST
--	 );



--	 lvds_0: SerializerN_1_lvds_dat GENERIC MAP (10, FAMILY)  ----normal is 1111100000
--	 PORT MAP(
--		 DP_I => "1100100001",
--		 CLKDIV_I => PClk,
--		 SERCLK_I => SerClk,
--		 DSP_O => ODDR_DATA1_TEST
--	 );

`protect end

end Behavioral;

