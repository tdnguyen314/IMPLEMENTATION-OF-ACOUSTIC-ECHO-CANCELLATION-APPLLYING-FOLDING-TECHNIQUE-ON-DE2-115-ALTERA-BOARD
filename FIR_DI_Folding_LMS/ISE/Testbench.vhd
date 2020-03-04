LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY Testbench IS
END Testbench;
 
ARCHITECTURE behavior OF Testbench IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT Toplevel
    PORT(
         RESET : IN  std_logic;
         CLOCK_50 : IN  std_logic;
         AUD_XCK : OUT  std_logic;
         AUD_BCK : IN  std_logic;
         AUD_ADCLRCK : IN  std_logic;
         AUD_DACLRCK : IN  std_logic;
         AUD_DACDAT : OUT  std_logic;
         AUD_ADCDAT : IN  std_logic;
         I2C_SCLK : OUT  std_logic;
         I2C_SDAT : OUT  std_logic;
         AIC_XCLK : OUT  std_logic;
         AIC_BCLK : IN  std_logic;
         AIC_LRCOUT : IN  std_logic;
         AIC_LRCIN : IN  std_logic;
         AIC_DOUT : IN  std_logic;
         AIC_DIN : OUT  std_logic;
         AIC_SCLK : OUT  std_logic;
         AIC_SPI_CS : OUT  std_logic;
         AD_SDIO : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal RESET : std_logic := '0';
   signal CLOCK_50 : std_logic := '0';
   signal AUD_BCK : std_logic := '0';
   signal AUD_ADCLRCK : std_logic := '0';
   signal AUD_DACLRCK : std_logic := '0';
   signal AUD_ADCDAT : std_logic := '0';
   signal AIC_BCLK : std_logic := '0';
   signal AIC_LRCOUT : std_logic := '0';
   signal AIC_LRCIN : std_logic := '0';
   signal AIC_DOUT : std_logic := '0';

 	--Outputs
   signal AUD_XCK : std_logic;
   signal AUD_DACDAT : std_logic;
   signal I2C_SCLK : std_logic;
   signal I2C_SDAT : std_logic;
   signal AIC_XCLK : std_logic;
   signal AIC_DIN : std_logic;
   signal AIC_SCLK : std_logic;
   signal AIC_SPI_CS : std_logic;
   signal AD_SDIO : std_logic;

   -- Clock period definitions
   constant CLOCK_50_period   : time := 20 ns;
   constant SA_CLK            : time := 20480 ns;
   constant AIC_BCLK_period   : time := 320 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: Toplevel PORT MAP (
          RESET => RESET,
          CLOCK_50 => CLOCK_50,
          AUD_XCK => AUD_XCK,
          AUD_BCK => AUD_BCK,
          AUD_ADCLRCK => AUD_ADCLRCK,
          AUD_DACLRCK => AUD_DACLRCK,
          AUD_DACDAT => AUD_DACDAT,
          AUD_ADCDAT => AUD_ADCDAT,
          I2C_SCLK => I2C_SCLK,
          I2C_SDAT => I2C_SDAT,
          AIC_XCLK => AIC_XCLK,
          AIC_BCLK => AIC_BCLK,
          AIC_LRCOUT => AIC_LRCOUT,
          AIC_LRCIN => AIC_LRCIN,
          AIC_DOUT => AIC_DOUT,
          AIC_DIN => AIC_DIN,
          AIC_SCLK => AIC_SCLK,
          AIC_SPI_CS => AIC_SPI_CS,
          AD_SDIO => AD_SDIO
        );

 -- Clock process definitions
   CLOCK_50_process :process
   begin
		CLOCK_50 <= '0';
		wait for CLOCK_50_period/2;
		CLOCK_50 <= '1';
		wait for CLOCK_50_period/2;
   end process;
   SA_CLK_process :process
   begin
		AIC_LRCIN <= '0';
      AUD_DACLRCK <= '0';
      AIC_LRCOUT <= '0';
      AUD_ADCLRCK <= '0';
		wait for SA_CLK/2;
		AIC_LRCIN <= '1';
      AUD_DACLRCK <= '1';
      AIC_LRCOUT <= '1';
      AUD_ADCLRCK <= '1';
		wait for SA_CLK/2;
   end process;
   AIC_BCLK_process :process
   begin
		AIC_BCLK <= '0';
      AUD_BCK  <= '0';
		wait for AIC_BCLK_period/2;
		AIC_BCLK <= '1';
      AUD_BCK  <= '1';
		wait for AIC_BCLK_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
		wait for 40 ns;
		RESET <= '1';
		wait for 40 ns;
		RESET <= '0';
      wait;
   end process;

END;
