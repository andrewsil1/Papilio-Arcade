--
-- A simulation model of Pacman hardware
-- Copyright (c) MikeJ - January 2006
--
-- All rights reserved
--
-- Redistribution and use in source and synthezised forms, with or without
-- modification, are permitted provided that the following conditions are met:
--
-- Redistributions of source code must retain the above copyright notice,
-- this list of conditions and the following disclaimer.
--
-- Redistributions in synthesized form must reproduce the above copyright
-- notice, this list of conditions and the following disclaimer in the
-- documentation and/or other materials provided with the distribution.
--
-- Neither the name of the author nor the names of other contributors may
-- be used to endorse or promote products derived from this software without
-- specific prior written permission.
--
-- THIS CODE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
-- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
-- PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
-- LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
-- CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
-- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
-- CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
-- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
-- POSSIBILITY OF SUCH DAMAGE.
--
-- You are responsible for any legal issues arising from your use of this code.
--
-- The latest version of this file can be found at: www.fpgaarcade.com
--
-- Email pacman@fpgaarcade.com
--
-- Revision list
--
-- version 005 Artix 7 release
-- version 004 spartan3e release
-- version 001 Jan 2006 release - initial release of this module

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_unsigned.all;
  use ieee.numeric_std.all;

library UNISIM;
use UNISIM.Vcomponents.all;

entity PACMAN_CLOCKS is
  port (
    I_CLK_REF         : in    std_logic;
    I_RESET_L         : in    std_logic;
    --
    O_CLK_REF         : out   std_logic;
    --
    O_ENA_12          : out   std_logic;
    O_ENA_6           : out   std_logic;
    O_CLK             : out   std_logic;
    O_RESET           : out   std_logic
    );
end;

architecture RTL of PACMAN_CLOCKS is

  signal reset_dcm_h            : std_logic;
  signal clk_ref_ibuf           : std_logic;
  signal clk_dcm_op_0           : std_logic;
  signal clk_dcm_op_dv          : std_logic;
  signal clk_dcm_0_bufg         : std_logic;
  signal clk                    : std_logic;
  signal dcm_locked             : std_logic;
  signal delay_count            : std_logic_vector(7 downto 0) := (others => '0');
  signal div_cnt                : std_logic_vector(1 downto 0);
--  signal clkfbout,clkfbin		  : std_logic;
  
  component NexysClockGenerator
port
 (-- Clock in ports
  clk_ref_ibuf           : in     std_logic;
  -- Clock out ports
  clk_dcm_op_0          : out    std_logic;
  clk_dcm_op_dv          : out    std_logic;
  -- Status and control signals
  reset_dcm_h             : in     std_logic;
  dcm_locked            : out    std_logic
 );
end component;

-- All the commented code below is from the Papilio Pro (Spartan 6?) which further modified the original Spartan3 code.
-- This has been replaced below with an appropriate MMCM tile for the Artix 7, using the input frequency of 100Mhz on the Nexys4 board
-- rather than the 32Mhz discussed in the original, still resulting in the desired 24.576mhz and 12.288mhz output clocks needed.  The 24Mhz
-- is divided by 4 and 2 to create 12 and 6Mhz clock enables, and the 12Mhz secondary clock output appears to only be used by the DAC audio output.

--  attribute DLL_FREQUENCY_MODE    : string;
--  attribute DUTY_CYCLE_CORRECTION : string;
--  attribute CLKOUT_PHASE_SHIFT    : string;
--  attribute PHASE_SHIFT           : integer;
--  attribute CLKFX_MULTIPLY        : integer;
--  attribute CLKFX_DIVIDE          : integer;
--  attribute CLKDV_DIVIDE          : real;
--  attribute STARTUP_WAIT          : string;
--  attribute CLKIN_PERIOD          : real;

  -- The original uses a 6.144 MHz clock
  --
  -- Here we are taking in 32MHz clock, and using the CLKFX 32*(10/13) to get 24.615MHz
  -- We are then clock enabling the whole design at /4 and /2
  --
  -- This runs the game at 6.15 MHz which is 0.16% fast.
  --
  -- (The scan doubler requires a x2 freq clock)
--  function str2bool (str : string) return boolean is
--  begin
--    if (str = "TRUE") or (str = "true") then
--      return TRUE;
--    else
--      return FALSE;
--    end if;
--  end str2bool;

begin

  reset_dcm_h <= not I_RESET_L;
  --IBUFG0 : IBUFG port map (I=> I_CLK_REF, O => clk_ref_ibuf);

--  dcma   : if true generate
--    attribute DLL_FREQUENCY_MODE    of dcm_inst : label is "LOW";
--    attribute DUTY_CYCLE_CORRECTION of dcm_inst : label is "TRUE";
--    attribute CLKOUT_PHASE_SHIFT    of dcm_inst : label is "NONE";
--    attribute PHASE_SHIFT           of dcm_inst : label is 0;
--    attribute CLKFX_MULTIPLY        of dcm_inst : label is 10;
--    attribute CLKFX_DIVIDE          of dcm_inst : label is 13;
--    attribute CLKDV_DIVIDE          of dcm_inst : label is 2.0;
--    attribute STARTUP_WAIT          of dcm_inst : label is "FALSE";
--    attribute CLKIN_PERIOD          of dcm_inst : label is 31.25;
--    --
--    begin
--    dcm_inst : DCM_SP
--      generic map (
--        DLL_FREQUENCY_MODE    => "LOW",
--        DUTY_CYCLE_CORRECTION => TRUE,
--        CLKOUT_PHASE_SHIFT    => "NONE",
--        PHASE_SHIFT           => 0,
--        CLKFX_MULTIPLY        => 10,
--        CLKFX_DIVIDE          => 13,
--        CLKDV_DIVIDE          => 2.0,
--        STARTUP_WAIT          => FALSE,
--        CLKIN_PERIOD          => 31.25
--       )
--      port map (
--        CLKIN    => clk_ref_ibuf,
--        CLKFB    => clk_dcm_0_bufg,
--        DSSEN    => '0',
--        PSINCDEC => '0',
--        PSEN     => '0',
--        PSCLK    => '0',
--        RST      => reset_dcm_h,
--        CLK0     => clk_dcm_op_0,
--        CLK90    => open,
--        CLK180   => open,
--        CLK270   => open,
--        CLK2X    => open,
--        CLK2X180 => open,
--        CLKDV    => open,
--        CLKFX    => clk_dcm_op_dv,
--        CLKFX180 => open,
--        LOCKED   => dcm_locked,
--        PSDONE   => open
--       );

--------	   MMCME2_ADV_inst : MMCME2_ADV
--------   generic map (
--------      BANDWIDTH => "OPTIMIZED",      -- Jitter programming (OPTIMIZED, HIGH, LOW)
--------      CLKFBOUT_MULT_F => 7.25,        -- Multiply value for all CLKOUT (2.000-64.000).
--------      CLKFBOUT_PHASE => 0.0,         -- Phase offset in degrees of CLKFB (-360.000-360.000).
--------      -- CLKIN_PERIOD: Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).
--------      CLKIN1_PERIOD => 10.0,
--------      CLKIN2_PERIOD => 10.0,
--------      -- CLKOUT0_DIVIDE - CLKOUT6_DIVIDE: Divide amount for CLKOUT (1-128)
--------      CLKOUT1_DIVIDE => 59,
--------      CLKOUT2_DIVIDE => 1,
--------      CLKOUT3_DIVIDE => 1,
--------      CLKOUT4_DIVIDE => 1,
--------      CLKOUT5_DIVIDE => 1,
--------      CLKOUT6_DIVIDE => 1,
--------      CLKOUT0_DIVIDE_F => 118.0,       -- Divide amount for CLKOUT0 (1.000-128.000).
--------      -- CLKOUT0_DUTY_CYCLE - CLKOUT6_DUTY_CYCLE: Duty cycle for CLKOUT outputs (0.01-0.99).
--------      CLKOUT0_DUTY_CYCLE => 0.5,
--------      CLKOUT1_DUTY_CYCLE => 0.5,
--------      CLKOUT2_DUTY_CYCLE => 0.5,
--------      CLKOUT3_DUTY_CYCLE => 0.5,
--------      CLKOUT4_DUTY_CYCLE => 0.5,
--------      CLKOUT5_DUTY_CYCLE => 0.5,
--------      CLKOUT6_DUTY_CYCLE => 0.5,
--------      -- CLKOUT0_PHASE - CLKOUT6_PHASE: Phase offset for CLKOUT outputs (-360.000-360.000).
--------      CLKOUT0_PHASE => 0.0,
--------      CLKOUT1_PHASE => 0.0,
--------      CLKOUT2_PHASE => 0.0,
--------      CLKOUT3_PHASE => 0.0,
--------      CLKOUT4_PHASE => 0.0,
--------      CLKOUT5_PHASE => 0.0,
--------      CLKOUT6_PHASE => 0.0,
--------      CLKOUT4_CASCADE => FALSE,      -- Cascade CLKOUT4 counter with CLKOUT6 (FALSE, TRUE)
--------      COMPENSATION => "ZHOLD",       -- ZHOLD, BUF_IN, EXTERNAL, INTERNAL
--------      DIVCLK_DIVIDE => 1,            -- Master division value (1-106)
--------      -- REF_JITTER: Reference input jitter in UI (0.000-0.999).
--------      REF_JITTER1 => 0.010,
--------      REF_JITTER2 => 0.010,
--------      STARTUP_WAIT => FALSE,         -- Delays DONE until MMCM is locked (FALSE, TRUE)
--------      -- Spread Spectrum: Spread Spectrum Attributes
--------      SS_EN => "FALSE",              -- Enables spread spectrum (FALSE, TRUE)
--------      SS_MODE => "CENTER_HIGH",      -- CENTER_HIGH, CENTER_LOW, DOWN_HIGH, DOWN_LOW
--------      SS_MOD_PERIOD => 10000,        -- Spread spectrum modulation period (ns) (VALUES)
--------      -- USE_FINE_PS: Fine phase shift enable (TRUE/FALSE)
--------      CLKFBOUT_USE_FINE_PS => FALSE,
--------      CLKOUT0_USE_FINE_PS => FALSE,
--------      CLKOUT1_USE_FINE_PS => FALSE,
--------      CLKOUT2_USE_FINE_PS => FALSE,
--------      CLKOUT3_USE_FINE_PS => FALSE,
--------      CLKOUT4_USE_FINE_PS => FALSE,
--------      CLKOUT5_USE_FINE_PS => FALSE,
--------      CLKOUT6_USE_FINE_PS => FALSE 
--------   )
--------   port map (
--------      -- Clock Outputs: 1-bit (each) output: User configurable clock outputs
--------      CLKOUT0 => clk_dcm_op_0,           -- 1-bit output: CLKOUT0
--------      CLKOUT0B => open,         -- 1-bit output: Inverted CLKOUT0
--------      CLKOUT1 => clk_dcm_op_dv,           -- 1-bit output: CLKOUT1
--------      CLKOUT1B => open,         -- 1-bit output: Inverted CLKOUT1
--------      CLKOUT2 => open,           -- 1-bit output: CLKOUT2
--------      CLKOUT2B => open,         -- 1-bit output: Inverted CLKOUT2
--------      CLKOUT3 => open,           -- 1-bit output: CLKOUT3
--------      CLKOUT3B => open,         -- 1-bit output: Inverted CLKOUT3
--------      CLKOUT4 => open,           -- 1-bit output: CLKOUT4
--------      CLKOUT5 => open,           -- 1-bit output: CLKOUT5
--------      CLKOUT6 => open,           -- 1-bit output: CLKOUT6
--------      -- DRP Ports: 16-bit (each) output: Dynamic reconfiguration ports
--------      DO => open,                     -- 16-bit output: DRP data
--------      DRDY => open,                 -- 1-bit output: DRP ready
--------      -- Dynamic Phase Shift Ports: 1-bit (each) output: Ports used for dynamic phase shifting of the outputs
--------      PSDONE => open,             -- 1-bit output: Phase shift done
--------      -- Feedback Clocks: 1-bit (each) output: Clock feedback ports
--------      CLKFBOUT => clkfbout,         -- 1-bit output: Feedback clock
--------      CLKFBOUTB => open,       -- 1-bit output: Inverted CLKFBOUT
--------      -- Status Ports: 1-bit (each) output: MMCM status ports
--------      CLKFBSTOPPED => open, -- 1-bit output: Feedback clock stopped
--------      CLKINSTOPPED => open, -- 1-bit output: Input clock stopped
--------      LOCKED => dcm_locked,             -- 1-bit output: LOCK
--------      -- Clock Inputs: 1-bit (each) input: Clock inputs
--------      CLKIN1 => clk_ref_ibuf,             -- 1-bit input: Primary clock
--------      CLKIN2 => '0',             -- 1-bit input: Secondary clock
--------      -- Control Ports: 1-bit (each) input: MMCM control ports
--------      CLKINSEL => '1',         -- 1-bit input: Clock select, High=CLKIN1 Low=CLKIN2
--------      PWRDWN => '0',             -- 1-bit input: Power-down
--------      RST => reset_dcm_h,                   -- 1-bit input: Reset
--------      -- DRP Ports: 7-bit (each) input: Dynamic reconfiguration ports
--------      DADDR => "0000000",               -- 7-bit input: DRP address
--------      DCLK => '0',                 -- 1-bit input: DRP clock
--------      DEN => '0',                   -- 1-bit input: DRP enable
--------      DI => "0000000000000000",     -- 16-bit input: DRP data
--------      DWE => '0',                   -- 1-bit input: DRP write enable
--------      -- Dynamic Phase Shift Ports: 1-bit (each) input: Ports used for dynamic phase shifting of the outputs
--------      PSCLK => '0',               -- 1-bit input: Phase shift clock
--------      PSEN => '0',                 -- 1-bit input: Phase shift enable
--------      PSINCDEC => '0',         -- 1-bit input: Phase shift increment/decrement
--------      -- Feedback Clocks: 1-bit (each) input: Clock feedback ports
--------      CLKFBIN => clkfbin  -- 1-bit input: Feedback clock
--------   );

NexysClock : NexysClockGenerator
  port map
   (-- Clock in ports
    clk_ref_ibuf => I_CLK_REF,
    -- Clock out ports
    clk_dcm_op_0 => clk_dcm_op_0,
    clk_dcm_op_dv => clk_dcm_op_dv,
    -- Status and control signals
    reset_dcm_h  => reset_dcm_h,
    dcm_locked => dcm_locked);

  BUFG0 : BUFG port map (I=> clk_dcm_op_0,  O => clk_dcm_0_bufg);
  O_CLK_REF <= clk_dcm_0_bufg;
  BUFG1 : BUFG port map (I=> clk_dcm_op_dv, O => clk);
  O_CLK <= clk;
  --BUFG2 : BUFG port map (I=> clkfbout, O => clkfbin);

  p_delay : process(I_RESET_L, clk) -- hold reset pulse for 256 clocks before releasing CPU.
  begin
    if (I_RESET_L = '0') then
      delay_count <= x"00"; -- longer delay for cpu
      O_RESET <= '1';
    elsif rising_edge(clk) then
      if (delay_count(7 downto 0) = (x"FF")) then
        delay_count <= (x"FF");
        O_RESET <= '0';
      else
        delay_count <= delay_count + "1";
        O_RESET <= '1';
      end if;
    end if;
  end process;

  p_clk_div : process(I_RESET_L, clk)
  begin
    if (I_RESET_L = '0') then
      div_cnt <= (others => '0');
    elsif rising_edge(clk) then
      div_cnt <= div_cnt + "1";
    end if;
  end process;

  p_assign_ena : process(div_cnt)
  begin
    O_ENA_12 <= div_cnt(0);
    O_ENA_6  <= div_cnt(0) and not div_cnt(1);
  end process;
end RTL;
