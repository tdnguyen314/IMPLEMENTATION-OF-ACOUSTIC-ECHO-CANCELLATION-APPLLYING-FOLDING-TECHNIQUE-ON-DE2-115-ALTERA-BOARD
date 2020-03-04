library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_signed.all;

library work;
use work.my_pack.all;
library lpm; --Using predefined packages
use lpm.lpm_components.all;

entity Toplevel is
  port (
      RESET      : in  std_logic;
      CLOCK_50   : in  std_logic;
      --Audio WM8731--
      AUD_XCK    : out std_logic; -- Main clock to WM8731
      AUD_BCK    : in  std_logic; -- Bit clock from WM8731
      AUD_ADCLRCK: in  std_logic; -- Clock for data out
      AUD_DACLRCK: in  std_logic; -- Clock for data in
      
      AUD_DACDAT : out std_logic; -- Data in to WM8731
      AUD_ADCDAT : in  std_logic; -- Data out from WM8731
      
      I2C_SCLK   : out std_logic; -- I2C clock
      I2C_SDAT   : out std_logic; -- I2C data
      --Audio AIC23--
      AIC_XCLK   : out std_logic; -- Main clock to AIC23
      AIC_BCLK   : in  std_logic; -- Bit clock from AIC23
      AIC_LRCOUT : in  std_logic; -- Clock for data out
      AIC_LRCIN  : in  std_logic; -- Clock for data in
      
      AIC_DOUT   : in  std_logic; -- Data in to AIC23
      AIC_DIN    : out std_logic; -- Data out from AIC23
      
      AIC_SCLK   : out std_logic; -- SPI clock
      AIC_SPI_CS : out std_logic; -- SPI CS
      AD_SDIO    : out std_logic);-- SPI data
end Toplevel;

architecture Behavioural of Toplevel is
   signal ADC_WM8731_L : byte_data:= (others => '0');
   signal ADC_WM8731_R : byte_data:= (others => '0');
   signal DAC_WM8731_L : byte_data:= (others => '0');
   signal DAC_WM8731_R : byte_data:= (others => '0');
   
   signal ADC_AIC23_L  : byte_data:= (others => '0');
   signal ADC_AIC23_R  : byte_data:= (others => '0');
   signal DAC_AIC23_L  : byte_data:= (others => '0');
   signal DAC_AIC23_R  : byte_data:= (others => '0');
 --Data simulation
   signal xin        : byte_exdata:= (others => '0');
   signal din        : byte_exdata:= (others => '0');
   signal eout       : byte_exdata:= (others => '0');
   signal yout       : byte_exdata:= (others => '0');
   
--temporary registers
   --data interface
   signal sXCLK     : std_logic;

   signal sSCLK     : std_logic; --SPI clock
   signal sSA_CLK   : std_logic; --sampling rate
   signal sBCLK     : std_logic; --serial bit clock
   signal sFCLK     : std_logic; --folding clock

begin
--Interface-------------------------------------------------
   AUD_XCK  <= sXCLK;
   AIC_SCLK <= sSCLK;     --Send serial clock to AIC23
   AIC_XCLK <= sXCLK;     --Send main clock to AIC23
   sSA_CLK  <= AIC_LRCIN; --Obtain sampling rate
--Initialization --
   --Extract the data from product to send to the output----      
   xin(ex_wx-1 downto ex_wx-1-scl) <= (others => ADC_AIC23_L(wx-1));
	xin(ex_wx-scl-2 downto 0) <= ADC_AIC23_L(wx-2 downto 0) & (ex-scl-1 downto 0 => '0');
	
	din(ex_wx-1 downto ex_wx-1-scl) <= (others => ADC_WM8731_L(wx-1));
	din(ex_wx-scl-2 downto 0) <= ADC_WM8731_L(wx-2 downto 0) & (ex-scl-1 downto 0 => '0');

	--Audio out clock skew problem
	Audio_out_AIC23:process(AIC_LRCIN)
	begin
		if rising_edge(AIC_LRCIN) then
			DAC_AIC23_L(wx-1 downto wx-1-scl) <= (others => eout(wx-1));
			DAC_AIC23_L(wx-scl-2 downto 0) <= eout(wx-2 downto scl);

			DAC_AIC23_R(wx-1 downto wx-1-scl) <= (others => eout(wx-1));
			DAC_AIC23_R(wx-scl-2 downto 0) <= eout(wx-2 downto scl);
		end if;
	end process;

	Audio_out_WM8731:process(AUD_DACLRCK)
	begin
		if rising_edge(AUD_DACLRCK) then
			DAC_WM8731_L(wx-1 downto wx-1-scl) <= (others => ADC_AIC23_L(wx-1));
			DAC_WM8731_L(wx-scl-2 downto 0) <= ADC_AIC23_L(wx-2 downto scl);

			DAC_WM8731_R(wx-1 downto wx-1-scl) <= (others => ADC_AIC23_R(wx-1));
			DAC_WM8731_R(wx-scl-2 downto 0) <= ADC_AIC23_R(wx-2 downto scl);
		end if;
	end process;
--FIR filter for channel left ---------------
FIR_DI_FOLDING_LMS_block: FIR_DI_FOLDING_LMS
   port map(
      RESET    => RESET,
      CLOCK_F  => sFCLK,
      SA_CLK   => sSA_CLK,
      XIN      => xin,
      DIN      => din,
      EOUT     => eout,
      YOUT     => yout);
--Audio interface----------------------------
Aduio_controller_block: Audio_controller
   port map(
      CLOCK_50   => CLOCK_50,
      SCLK       => sSCLK,
      AIC_SPI_CS => AIC_SPI_CS,
      AD_SDIO    => AD_SDIO,
      I2C_SCLK   => I2C_SCLK,
      I2C_SDAT   => I2C_SDAT);
Audio_Interface_WM8731: Audio_Interface
   port map(
      CLOCK_IN  => AUD_DACLRCK,
      CLOCK_OUT => AUD_ADCLRCK,
      BCLK      => AUD_BCK,
      DIN       => AUD_DACDAT,
      DOUT      => AUD_ADCDAT,
      ADC_L     => ADC_WM8731_L,
      ADC_R     => ADC_WM8731_R,
      DAC_L     => DAC_WM8731_L,
      DAC_R     => DAC_WM8731_R);
Audio_Interface_AIC23: Audio_Interface
   port map(
      CLOCK_IN   => AIC_LRCIN,
      CLOCK_OUT  => AIC_LRCOUT,
      BCLK       => AIC_BCLK,
      DIN        => AIC_DIN,
      DOUT       => AIC_DOUT,
      ADC_L      => ADC_AIC23_L,
      ADC_R      => ADC_AIC23_R,
      DAC_L      => DAC_AIC23_L,
      DAC_R      => DAC_AIC23_R);
Clock_divider_block: Clock_divider
   port map(
      CLOCK_50 => CLOCK_50,
      FCLK     => sFCLK,
      XCLK     => sXCLK,
      SCLK     => sSCLK);
end Behavioural;