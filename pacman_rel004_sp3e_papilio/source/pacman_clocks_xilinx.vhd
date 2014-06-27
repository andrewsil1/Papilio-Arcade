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
  clk_dcm_op_0           : out    std_logic;
  clk_dcm_op_dv          : out    std_logic;
  -- Status and control signals
  reset_dcm_h             : in     std_logic;
  dcm_locked            : out    std_logic
 );
end component;

-- The original code for the Papilio series instantiated DCM clock primitives for the Spartan 3/6 which are not usable on the Artix 7.
-- This has been replaced below with an appropriate MMCM tile for the Artix 7, using the input frequency of 100Mhz on the Nexys4 board
-- rather than the 32Mhz discussed in the original, but the end result is still the desired 24.576mhz clock, and the /4 & /2 clock-enables which
-- are derived from it. The reclocked original reference clock output appears to only be used by the DAC audio system.

begin

  reset_dcm_h <= not I_RESET_L;

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

  p_clk_div : process(I_RESET_L, clk) -- Count 24.576Mhz clock ticks from 0b00 to 0b11
  begin
    if (I_RESET_L = '0') then
      div_cnt <= (others => '0');
    elsif rising_edge(clk) then
      div_cnt <= div_cnt + "1";
    end if;
  end process;

  p_assign_ena : process(div_cnt)
  begin
    O_ENA_12 <= div_cnt(0);							-- LSB creates a 12.288Mhz CE signal
    O_ENA_6  <= div_cnt(0) and not div_cnt(1);	-- Once every four clocks, generate a 6.144Mhz CE signal.
  end process;
end RTL;
