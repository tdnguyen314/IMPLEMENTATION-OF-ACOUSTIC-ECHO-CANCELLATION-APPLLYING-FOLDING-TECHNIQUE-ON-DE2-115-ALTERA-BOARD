library ieee;
use ieee.std_logic_1164.all;

package my_pack is
-- Testing
--constant fx : natural := 2; -- fixed-point standard
--constant wx : natural := 4; -- data length
--constant fl : natural := 4; -- filter length
-- Implementing
constant fx : natural := 16;  -- fixed-point standard 
constant wx : natural := 16; -- data length 
constant fl : natural := 64;-- filter length

constant ex : natural := 30;   -- extension length 
constant wp : natural := wx*2; -- product length 

constant ex_wx : natural := wx+ex;   -- extension data length 
constant ex_wp : natural := ex_wx*2; -- extension product length

constant scl : natural := 0;  -- scale for overflow problem

subtype byte_data      is std_logic_vector(wx-1 downto 0);
subtype byte_product   is std_logic_vector(wp-1 downto 0);
subtype byte_exdata    is std_logic_vector(ex_wx-1 downto 0);
subtype byte_exproduct is std_logic_vector(ex_wp-1 downto 0);

type array_data      is array (natural range fl-1 downto 0) of byte_data;
type array_product   is array (natural range fl-1 downto 0) of byte_exproduct;
type array_exdata    is array (natural range fl-1 downto 0) of byte_exdata;
type array_exproduct is array (natural range fl-1 downto 0) of byte_exproduct;
type array_SR        is array (natural range fl downto 0) of byte_exproduct;
type array_DR        is array (natural range fl downto 0) of byte_exdata;

-- ============ COMPONENTS ====================================-- 
-- Data simulation----------------------------
component Inputs_Simulation is
   port(
      RESET    : in  std_logic;
      SA_CLK   : in  std_logic;
      datax    : out byte_exdata;
      datad    : out byte_exdata);
end component Inputs_Simulation;
-- Clock divider ----------------------------
component Clock_divider is
   port(
      CLOCK_50 : in  std_logic;
      FCLK     : out std_logic; -- Folding frequency
      XCLK     : out std_logic; -- Main/external clock 12.5MHz
      SA_CLK   : out std_logic; -- 48.828 kHz
      BCLK     : out std_logic; -- XCLK/4 = 3.125 MHz
      SCLK     : out std_logic);-- choose 6.25 MHz
                                -- also for timing requirements
   end component Clock_divider;
-- Audio Interface----------------------------
component Audio_Interface is
   port(
      CLOCK_IN  : in  std_logic;  -- Sampling clock for DAC
      CLOCK_OUT : in  std_logic;  -- Sampling clock for ADC
      BCLK      : in  std_logic;  -- Bit clock
      DIN       : out std_logic;  -- Data bit in to AIC23
      DOUT      : in  std_logic;  -- Data bit out from AIC23
      -- For processing --
      ADC_L     : out byte_data;  -- Data register from AIC23, channel left
      ADC_R     : out byte_data;  -- Data register from AIC23, channel right
      DAC_L     : in  byte_data;  -- Data register to AIC23, channel left
      DAC_R     : in  byte_data); -- Data register to AIC23, channel right
end component Audio_Interface;
-- Audio Controller---------------------------
component Audio_Controller is
   port(
      CLOCK_50   : in  std_logic;
      SCLK       : in  std_logic;  -- SPI clock
      AIC_SPI_CS : out std_logic;  -- SPI CS, ack for new command
      AD_SDIO    : out std_logic;  -- SPI data
      I2C_SCLK   : out std_logic;  -- I2C clock
      I2C_SDAT   : out std_logic); -- I2C data
end component Audio_Controller;
---------------------------------------------
-- FIR filter direct form I -----------------
---------------------------------------------
-- DIRECT FORM I PE -------------------------
component PE_DI is
   port(
      RESET  : in  std_logic;
      SA_CLK : in  std_logic;
      XIN    : in  byte_exdata; -- Input to PE
      HIN    : in  byte_exdata; -- Coefficient to PE
      YIN    : in  byte_exproduct; -- Output to PE
      EIN    : in  byte_exdata;    -- Error to be multiplied to XIN
      
      XOUT   : inout byte_exdata;    -- Input from PE
      YOUT   : out   byte_exproduct; -- Output from PE
      EXOUT  : out   byte_exproduct);-- EIN*XIN
end component PE_DI;
-- NORMAL FIR direct form I -----------------
component FIR_DI is
   port(
      RESET  : in  std_logic;
      SA_CLK : in  std_logic;
      XIN    : in  byte_exdata; -- Filter input
      EIN    : in  byte_exdata; -- Error in
      YOUT   : out byte_exproduct; -- Filter output

      HIN    : in  array_exdata; -- Filter coefficient
      EXOUT  : out array_exproduct);-- e*x
end component FIR_DI;
-- FOLDING FIR direct form I ----------------
component FIR_DI_FOLDING is
   port(
      RESET    : in  std_logic;
      CLOCK_F  : in  std_logic;
      XIN      : in  byte_exdata; -- Filter input
      EIN      : in  byte_exdata; -- Error in
      YOUT     : out byte_exproduct; -- Filter output

      HIN      : in  array_exdata; -- Filter coefficient
      EXOUT    : out array_exproduct);-- e*x
end component FIR_DI_FOLDING;
-- Adaptive filter direct form I ------------
component LMS_ADF_DI is
  port(
      RESET   : in  std_logic;
      SA_CLK  : in  std_logic;
      XIN     : in  byte_exdata; -- Primary signal
      DIN     : in  byte_exdata; -- Desired signal
      EOUT    : out byte_exdata; -- Error out
      YOUT    : out byte_exdata);-- Filter output
end component LMS_ADF_DI;
-- LMS ADF FOLDING DI -----------------------
component FIR_DI_FOLDING_LMS is
   port(
      RESET   : in  std_logic;
      CLOCK_F : in  std_logic;
      SA_CLK  : in  std_logic;
      XIN     : in  byte_exdata; -- Primary signal
      DIN     : in  byte_exdata; -- Desired signal
      EOUT    : out byte_exdata; -- error out
      YOUT    : out byte_exdata);-- filter output
end component FIR_DI_FOLDING_LMS;
---------------------------------------------
-- FIR filter direct form II ----------------
---------------------------------------------
-- DIRECT FORM II PE ------------------------
component PE_DII is
   port(
      RESET  : in  std_logic;
      SA_CLK : in  std_logic;
      XIN    : in  byte_exdata; -- Input to PE
      HIN    : in  byte_exdata; -- Coefficient to PE
      YIN    : in  byte_exproduct; -- Output to PE
      EIN    : in  byte_exdata; -- Error to be multiplied to XIN
      
      XOUT   : inout byte_exdata; -- Input from PE
      YOUT   : out   byte_exproduct; -- Output from PE
      EXOUT  : out   byte_exproduct);-- EIN*XIN
end component PE_DII;
-- NORMAL FIR direct form II -------------
component FIR_DII is
   port(
      RESET  : in  std_logic;
      SA_CLK : in  std_logic;
      XIN    : in  byte_exdata; -- Filter input
      EIN    : in  byte_exdata; -- Error in
      YOUT   : out byte_exproduct; -- Filter output

      HIN    : in  array_exdata; -- Filter coefficient
      EXOUT  : out array_exproduct);-- e*x
end component FIR_DII;
-- FOLDING FIR direct form II ------------
component FIR_DII_FOLDING is
   port(
      RESET    : in  std_logic;
      CLOCK_F  : in  std_logic;
      XIN      : in  byte_exdata; -- Filter input
      EIN      : in  byte_exdata; -- Error in
      YOUT     : out byte_exproduct; -- Filter output

      HIN      : in  array_exdata;   -- Filter coefficient
      EXOUT    : out array_exproduct);-- e*x
end component FIR_DII_FOLDING;
-- Adaptive filter direct form II ------------
component LMS_ADF_DII is
  port(
      RESET   : in  std_logic;      
      SA_CLK  : in  std_logic;
      XIN     : in  byte_exdata; -- Primary signal
      DIN     : in  byte_exdata; -- Desired signal
      EOUT    : out byte_exdata; -- Error out
      YOUT    : out byte_exdata);-- Filter output
end component LMS_ADF_DII;
-- LMS ADF FOLDING DII -----------------------
component FIR_DII_FOLDING_LMS is
   port(
      RESET   : in  std_logic;
      CLOCK_F : in  std_logic;      
      SA_CLK  : in  std_logic;
      XIN     : in  byte_exdata; -- Primary signal
      DIN     : in  byte_exdata; -- Desired signal
      EOUT    : out byte_exdata; -- error out
      YOUT    : out byte_exdata);-- filter output
end component FIR_DII_FOLDING_LMS;
--===========================================================--
--============ FOLDING FIR direct form I 50MHZ ==============--
--===========================================================--
component FIR_DI_FOLDING_50MHz is
   port(
      RESET    : in  std_logic;
      CLOCK_50 : in  std_logic;
      XIN      : in  byte_exdata; -- Filter input
      EIN      : in  byte_exdata; -- Error in
      YOUT     : out byte_exproduct; -- Filter output

      HIN      : in  array_exdata; -- Filter coefficient
      EXOUT    : out array_exproduct);-- e*x
end component FIR_DI_FOLDING_50MHz;
end package;