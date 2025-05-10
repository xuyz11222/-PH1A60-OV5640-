`protect begin

-----------------------------------------------------
-- Company: anlgoic
-- Author: 	xg 
-----------------------------------------------------
----equal to clk pattern is 1111100000



library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity Serial_N_1_lvds_dat is
	 Generic ( 	N : NATURAL := 10;
				FAMILY : STRING := "EG4");
    Port ( 	
			DP_I : in  STD_LOGIC_VECTOR (N-1 downto 0);
			PCLK : in  STD_LOGIC; --parallel slow clock
			SCLK : in STD_LOGIC; --serial fast clock (CLK_I = PCLK x N / 2)

			DSP_O : out  STD_LOGIC
		);
end Serial_N_1_lvds_dat;



architecture Behavioral of Serial_N_1_lvds_dat is



component EG_LOGIC_ODDR is 
generic (
    ASYNCRST : string := "ENABLE"
    );
port (
    q : out std_logic ;
    clk : in std_logic ;
    d1 : in std_logic ;
    d0 : in std_logic ;
    rst : in std_logic 
    );
end component;

component PH1_LOGIC_ODDR is 
generic (
    ASYNCRST : string := "ENABLE"
    );
port (
    q : out std_logic ;
    clk : in std_logic ;
    d1 : in std_logic ;
    d0 : in std_logic ;
    rst : in std_logic 
    );
end component;

component AL_LOGIC_ODDR is 
generic (
    ASYNCRST : string := "ENABLE"
    );
port (
    q : out std_logic ;
    clk : in std_logic ;
    d1 : in std_logic ;
    d0 : in std_logic ;
    rst : in std_logic 
    );
end component;

component EF2_LOGIC_ODDR is 
generic (
    ASYNCRST : string := "ENABLE"
    );
port (
    q : out std_logic ;
    clk : in std_logic ;
    d1 : in std_logic ;
    d0 : in std_logic ;
    rst : in std_logic 
    );
end component;

component EF3_LOGIC_ODDR is 
generic (
    ASYNCRST : string := "ENABLE"
    );
port (
    q : out std_logic ;
    clk : in std_logic ;
    d1 : in std_logic ;
    d0 : in std_logic ;
    rst : in std_logic 
    );
end component;

signal  pclk_vld,pclk_vld_q,pclk_vld_qq,sclk_dat_lat,sclk_dat_lat_1d,sclk_dat_lat_2d,sclk_dat_lat_3d: std_logic:='0';
signal  tx_pdat : std_logic_vector(N-1 downto 0) ;
signal  tx_sdat,tx_sdat_1d : std_logic_vector(1 downto 0) ;
signal  tx_out: std_logic:='0';
signal  rx_pdata_h,rx_pdata_l: std_logic_vector(N/2-1 downto 0) ;

begin

	
--------------------------------  lvds  -------------------------------------------

process(PCLK) 
begin
    if rising_edge(PCLK) then  
	      pclk_vld <=  not pclk_vld;
    end if;
end process;    

process(SCLK) 
  begin
    if rising_edge(SCLK) then  
		    pclk_vld_q   <=  pclk_vld;
			pclk_vld_qq  <=  pclk_vld_q;
			sclk_dat_lat <= pclk_vld_q xor pclk_vld_qq; 
			sclk_dat_lat_1d <= sclk_dat_lat;
			sclk_dat_lat_2d <= sclk_dat_lat_1d;
			sclk_dat_lat_3d <= sclk_dat_lat_2d;
    end if;        
end process;



process(SCLK) 
begin
    if rising_edge(SCLK) then 
        if sclk_dat_lat_2d = '1' then
           tx_pdat <= DP_I(0) & DP_I(1) & DP_I(2) & DP_I(3) & DP_I(4) & DP_I(5) & DP_I(6) & DP_I(7) & DP_I(8) & DP_I(9) ; 
        else
           tx_pdat <= tx_pdat(N-3 downto 0) & '0' & '0';  
        end if;        
    end if;
end process; 

process(SCLK) 
begin
    if rising_edge(SCLK) then 
        tx_sdat <=tx_pdat(N-1 downto N-2) ;
        tx_sdat_1d <= tx_sdat;
    end if;
end process;

eg: if FAMILY = "EG4" generate

oddr_snd : EG_LOGIC_ODDR 
port map(
    q => DSP_O,
    clk => SCLK,
    d1 => tx_sdat_1d(0),
    d0 => tx_sdat_1d(1),
    rst => '0'
    );
end generate eg;

ph1: if FAMILY = "PH1" generate	

oddr_snd : PH1_LOGIC_ODDR 
port map(
    q => DSP_O,
    clk => SCLK,
    d1 => tx_sdat_1d(0),
    d0 => tx_sdat_1d(1),
    rst => '0'
    );

end generate ph1;

al: if FAMILY = "AL3" generate	

oddr_snd : AL_LOGIC_ODDR 
port map(
    q => DSP_O,
    clk => SCLK,
    d1 => tx_sdat_1d(0),
    d0 => tx_sdat_1d(1),
    rst => '0'
    );

end generate al;
	
ef2: if FAMILY = "EF2" generate

oddr_snd : EF2_LOGIC_ODDR 
port map(
    q => DSP_O,
    clk => SCLK,
    d1 => tx_sdat_1d(0),
    d0 => tx_sdat_1d(1),
    rst => '0'
    );
end generate ef2;

ef3: if FAMILY = "EF3" generate

oddr_snd : EF3_LOGIC_ODDR 
port map(
    q => DSP_O,
    clk => SCLK,
    d1 => tx_sdat_1d(0),
    d0 => tx_sdat_1d(1),
    rst => '0'
    );
end generate ef3;

end Behavioral;


`protect end
