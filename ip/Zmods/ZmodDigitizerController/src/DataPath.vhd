
-------------------------------------------------------------------------------
--
-- File: DataPath.vhd
-- Author: Tudor Gherman, Robert Bocos
-- Date: 2021
--
-------------------------------------------------------------------------------
-- (c) 2020 Copyright Digilent Incorporated
-- All Rights Reserved
-- 
-- This program is free software; distributed under the terms of BSD 3-clause 
-- license ("Revised BSD License", "New BSD License", or "Modified BSD License")
--
-- Redistribution and use in source and binary forms, with or without modification,
-- are permitted provided that the following conditions are met:
--
-- 1. Redistributions of source code must retain the above copyright notice, this
--    list of conditions and the following disclaimer.
-- 2. Redistributions in binary form must reproduce the above copyright notice,
--    this list of conditions and the following disclaimer in the documentation
--    and/or other materials provided with the distribution.
-- 3. Neither the name(s) of the above-listed copyright holder(s) nor the names
--    of its contributors may be used to endorse or promote products derived
--    from this software without specific prior written permission.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
-- IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
-- ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE 
-- FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL 
-- DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR 
-- SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
-- CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, 
-- OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE 
-- OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--
-------------------------------------------------------------------------------
--
--This module synchronizes the data output by the ADC on the DCO input clock (DcoClkIn) 
--to the sampling clock generated by an MMCM in the DcoClkOut domain.
--
--  
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VComponents.all;
use work.PkgZmodDigitizer.all;

entity DataPath is
    Generic (
        -- Sampling clock frequency (in ns).
        kSamplingPeriod : real range 2.5 to 100.0:= 10.0;
        -- ADC number of bits.
        kADC_Width : integer range 10 to 16 := 14
    );
    Port (
        -- Reference clock. 
        RefClk  : in STD_LOGIC;
        -- Reset signal asynchronously asserted and synchronously 
        -- de-asserted (in the RefClk domain).
        arRst           : in std_logic;
        -- Reset signal asynchronously asserted and synchronously 
        -- de-asserted (in the DcoClkOut domain).
        adoRst          : in std_logic;
        -- AD96xx DCO output clock.
        DcoClkIn         : in std_logic;
        -- AD96xx DCO output clock forwarded to the IP's upper levels.
        DcoClkOut        : out std_logic;
        -- MMCM Locked output signal synchronized on RefClk
        rDcoMMCM_LockState : out std_logic;
        -- When logic '1', this signal enables data acquisition from the ADC. This signal
	    -- should be kept in logic '0' until the downstream IP (e.g. DMA controller) is
	    -- ready to receive the ADC data.
	    doEnableAcquisition : in std_logic;
        -- ADC parallel interleaved output data signals.
        diADC_Data        : in std_logic_vector(kADC_Width-1 downto 0);
        -- AD96xx demutiplexed Channel A data output (synchronized in
        -- the DcoClkOut domain).
        doChannelA        : out STD_LOGIC_VECTOR (kADC_Width-1 downto 0);
        -- AD96xx demutiplexed Channel B data output (synchronized in
        -- the DcoClkOut domain).
        doChannelB        : out STD_LOGIC_VECTOR (kADC_Width-1 downto 0);
        -- Channel A & B data valid indicator.
        doDataOutValid    : out STD_LOGIC
    );
end DataPath;

architecture Behavioral of DataPath is

    -- Function used to compute the CLKOUT1_DIVIDE and CLKFBOUT_MULT_F parameters
    -- of the MMCM so that the VCO frequency is in the specified range.
    -- The MMCM is used for de-skew purposes, so the MMCM's input and output
    -- clock frequency should be the same. The CLKOUT1_DIVIDE and CLKFBOUT_MULT_F
    -- need to be adjusted to cover input clock frequencies between 10MHz and
    -- 400MHz.
    function MMCM_M_Coef(SamplingPeriod:real)
    return real is
    begin
        --400MHz to 200MHz -> VCO frequency = [1200;600]
        if ((SamplingPeriod > 2.5) and (SamplingPeriod <= 5.0)) then
            return 3.0;
        --200MHz to 100MHz 
        elsif ((SamplingPeriod > 5.0) and (SamplingPeriod <= 10.0)) then
            return 6.0;
        --100MHz to 50MHz    
        elsif ((SamplingPeriod > 10.0) and (SamplingPeriod <= 20.0)) then
            return 12.0;
        --50MHz to 25MHz 
        elsif ((SamplingPeriod > 20.0) and (SamplingPeriod <= 40.0)) then
            return 24.0;
        --25MHz to 12.5MHz 
        elsif ((SamplingPeriod > 40.0) and (SamplingPeriod <= 80.0)) then
            return 48.0;
        --12.5MHz to 10MHz 
        elsif (SamplingPeriod > 80.0) then
            return 64.0;
        --Out of specifications;               
        else
            return 1.0;
        end if;
    end function;
    
    signal DcoBufgClk, FboutDcoClk, FbinDcoClk, DcoBUFR_Clk, DcoBufioClk, DcoMMCM_Clk1, DcoMMCM_Clk2 : std_logic;
    signal dbChannelA_IDDR, dbChannelB_IDDR : std_logic_vector(kADC_Width-1 downto 0);
    signal aMMCM_Locked: std_logic;
    signal rMMCM_LockedLoc: std_logic;
    signal rMMCM_LckdFallingFlag: std_logic;
    signal rMMCM_Locked_q: std_logic_vector(3 downto 0);
    signal rMMCM_Reset_q: std_logic_vector(3 downto 0);
    signal aMMCM_ClkStop, cMMCM_ClkStop: std_logic;
    signal rMMCM_ClkStop_q: std_logic_vector(3 downto 0);
    signal rMMCM_ClkStopFallingFlag: std_logic;
    signal doMMCM_LockedLoc : std_logic;
    signal doMMCM_Locked_q : std_logic_vector(3 downto 0);
    signal doHandShakeDataOutValid : std_logic;
    signal doDataOutValidLoc : std_logic;
    signal rHandShakeRdy : std_logic;

    constant kClkfboutMultF : real := MMCM_M_Coef(kSamplingPeriod);
    constant kClk1Divide : integer := integer(MMCM_M_Coef(kSamplingPeriod));
    constant kDummy : std_logic_vector (15 downto 0) := x"0000";

begin

    DcoClkOut <= DcoBufgClk;

    BUFIO_inst : BUFIO
        port map (
            O => DcoBufioClk, -- 1-bit output: Clock output (connect to I/O clock loads).
            I => DcoMMCM_Clk2  -- 1-bit input: Clock input (connect to an IBUF or BUFMR).
        );

    ------------------------------------------------------------------------------------------
    -- Input data interface decode
    ------------------------------------------------------------------------------------------ 
    --Clock domain crossing between DcoClkIn and DcoBufioClk should be safe,
    --the latter clock is generated from the former using an MMCM, and we rely on proper timing analysis
    --to ensure timing conditions are met

    -- Demultiplex the input data bus   
    GenerateIDDR : for i in 0 to (kADC_Width-1) generate
        InstIDDR : IDDR
            generic map (
                DDR_CLK_EDGE => "SAME_EDGE", -- "OPPOSITE_EDGE", "SAME_EDGE" 
                -- or "SAME_EDGE_PIPELINED" 
                INIT_Q1 => '0', -- Initial value of Q1: '0' or '1'
                INIT_Q2 => '0', -- Initial value of Q2: '0' or '1'
                SRTYPE => "SYNC") -- Set/Reset type: "SYNC" or "ASYNC" 
            port map (
                Q1 => dbChannelA_IDDR(i), -- 1-bit output for positive edge of clock  
                Q2 => dbChannelB_IDDR(i), -- 1-bit output for negative edge of clock
                C => DcoBufioClk,        -- 1-bit clock input
                CE => '1', -- 1-bit clock enable input
                D => diADC_Data(i),   -- 1-bit DDR data input
                R => '0',   -- 1-bit reset
                S => '0'    -- 1-bit set
            );

    end generate GenerateIDDR;

    ------------------------------------------------------------------------------------------
    -- Input data interface de-skew
    ------------------------------------------------------------------------------------------ 

    --Clock buffer for write FIFO clock.
    InstDcoBufg : BUFG
        port map (
            O => DcoBufgClk, -- 1-bit output: Clock output (connect to I/O clock loads).
            I => DcoMMCM_Clk1  -- 1-bit input: Clock input (connect to an IBUF or BUFMR).
        );

    --FIFO write clock de-skew.

    InstBufrFeedbackPLL : BUFR
        generic map (
            BUFR_DIVIDE => "1",   -- Values: "BYPASS, 1, 2, 3, 4, 5, 6, 7, 8" 
            SIM_DEVICE => "7SERIES"  -- Must be set to "7SERIES" 
        )
        port map (
            O => FbinDcoClk, -- 1-bit output: Clock output (connect to I/O clock loads).
            CE => '1',   -- 1-bit input: Active high, clock enable (Divided modes only)
            CLR => '0', -- 1-bit input: Active high, asynchronous clear (Divided modes only)
            I => FboutDcoClk --CLK_DCO_Delay  -- 1-bit input: Clock input (connect to an IBUF or BUFMR).
        );

    Digitizer_MMCM : MMCME2_ADV
        generic map (
            BANDWIDTH => "OPTIMIZED",  -- Jitter programming (OPTIMIZED, HIGH, LOW)
            CLKFBOUT_MULT_F => kClkfboutMultF,    -- Multiply value for all CLKOUT (2.000-64.000).
            CLKFBOUT_PHASE => 0.0,     -- Phase offset in degrees of CLKFB (-360.000-360.000).
            CLKIN1_PERIOD => kSamplingPeriod,      -- Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).

            CLKIN2_PERIOD => 0.0,
            -- CLKOUT0_DIVIDE - CLKOUT6_DIVIDE: Divide amount for each CLKOUT (1-128)
            CLKOUT1_DIVIDE => kClk1Divide,
            CLKOUT2_DIVIDE => kClk1Divide,
            CLKOUT3_DIVIDE => 1,
            CLKOUT4_DIVIDE => 1,
            CLKOUT5_DIVIDE => 1,
            CLKOUT6_DIVIDE => 1,
            CLKOUT0_DIVIDE_F => kClkfboutMultF,   -- Divide amount for CLKOUT0 (1.000-128.000).
            -- CLKOUT0_DUTY_CYCLE - CLKOUT6_DUTY_CYCLE: Duty cycle for each CLKOUT (0.01-0.99).
            CLKOUT0_DUTY_CYCLE => 0.5,
            CLKOUT1_DUTY_CYCLE => 0.5,
            CLKOUT2_DUTY_CYCLE => 0.5,
            CLKOUT3_DUTY_CYCLE => 0.5,
            CLKOUT4_DUTY_CYCLE => 0.5,
            CLKOUT5_DUTY_CYCLE => 0.5,
            CLKOUT6_DUTY_CYCLE => 0.5,
            -- CLKOUT0_PHASE - CLKOUT6_PHASE: Phase offset for each CLKOUT (-360.000-360.000).
            CLKOUT0_PHASE => 0.0,
            CLKOUT1_PHASE => 0.0,
            CLKOUT2_PHASE => IDDR_ClockPhase(kSamplingPeriod),
            CLKOUT3_PHASE => 0.0,
            CLKOUT4_PHASE => 0.0,
            CLKOUT5_PHASE => 0.0,
            CLKOUT6_PHASE => 0.0,
            CLKOUT4_CASCADE => FALSE,  -- Cascade CLKOUT4 counter with CLKOUT6 (FALSE, TRUE)

            COMPENSATION => "ZHOLD",       -- ZHOLD, BUF_IN, EXTERNAL, INTERNAL
            DIVCLK_DIVIDE => 1,            -- Master division value (1-106)
            -- REF_JITTER: Reference input jitter in UI (0.000-0.999).
            REF_JITTER1 => 0.0,
            REF_JITTER2 => 0.0,
            STARTUP_WAIT => FALSE,         -- Delays DONE until MMCM is locked (FALSE, TRUE)
            -- Spread Spectrum: Spread Spectrum Attributes
            SS_EN => "FALSE",              -- Enables spread spectrum (FALSE, TRUE)
            SS_MODE => "CENTER_HIGH",      -- CENTER_HIGH, CENTER_LOW, DOWN_HIGH, DOWN_LOW
            SS_MOD_PERIOD => 10000,        -- Spread spectrum modulation period (ns) (VALUES)
            -- USE_FINE_PS: Fine phase shift enable (TRUE/FALSE)
            CLKFBOUT_USE_FINE_PS => FALSE,
            CLKOUT0_USE_FINE_PS => FALSE,
            CLKOUT1_USE_FINE_PS => FALSE,
            CLKOUT2_USE_FINE_PS => FALSE,
            CLKOUT3_USE_FINE_PS => FALSE,
            CLKOUT4_USE_FINE_PS => FALSE,
            CLKOUT5_USE_FINE_PS => FALSE,
            CLKOUT6_USE_FINE_PS => FALSE
        )
        port map (
            -- Clock Outputs: 1-bit (each) output: User configurable clock outputs
            CLKOUT0 => open,     -- 1-bit output: CLKOUT0
            CLKOUT0B => open,   -- 1-bit output: Inverted CLKOUT0
            CLKOUT1 => DcoMMCM_Clk1,     -- 1-bit output: CLKOUT1
            CLKOUT1B => open,   -- 1-bit output: Inverted CLKOUT1
            CLKOUT2 => DcoMMCM_Clk2,     -- 1-bit output: CLKOUT2
            CLKOUT2B => open,   -- 1-bit output: Inverted CLKOUT2
            CLKOUT3 => open,     -- 1-bit output: CLKOUT3
            CLKOUT3B => open,   -- 1-bit output: Inverted CLKOUT3
            CLKOUT4 => open,     -- 1-bit output: CLKOUT4
            CLKOUT5 => open,     -- 1-bit output: CLKOUT5
            CLKOUT6 => open,     -- 1-bit output: CLKOUT6

            -- DRP Ports: 16-bit (each) output: Dynamic reconfiguration ports
            DO => open,                     -- 16-bit output: DRP data
            DRDY => open,                 -- 1-bit output: DRP ready
            -- Dynamic Phase Shift Ports: 1-bit (each) output: Ports used for dynamic phase shifting of the outputs
            PSDONE => open,             -- 1-bit output: Phase shift done
            -- Feedback Clocks: 1-bit (each) output: Clock feedback ports
            CLKFBOUT => FboutDcoClk,         -- 1-bit output: Feedback clock
            CLKFBOUTB => open,       -- 1-bit output: Inverted CLKFBOUT
            -- Status Ports: 1-bit (each) output: MMCM status ports
            CLKFBSTOPPED => open, -- 1-bit output: Feedback clock stopped
            CLKINSTOPPED => aMMCM_ClkStop, -- 1-bit output: Input clock stopped
            LOCKED => aMMCM_Locked,             -- 1-bit output: LOCK
            -- Clock Inputs: 1-bit (each) input: Clock inputs
            CLKIN1 => DcoClkIn,             -- 1-bit input: Primary clock
            CLKIN2 => '0',             -- 1-bit input: Secondary clock
            -- Control Ports: 1-bit (each) input: MMCM control ports
            CLKINSEL => '1',         -- 1-bit input: Clock select, High=CLKIN1 Low=CLKIN2
            PWRDWN => '0',             -- 1-bit input: Power-down
            RST => rMMCM_Reset_q(0),                   -- 1-bit input: Reset
            -- DRP Ports: 7-bit (each) input: Dynamic reconfiguration ports
            DADDR => (others => '0'),               -- 7-bit input: DRP address
            DCLK => '0',                 -- 1-bit input: DRP clock
            DEN => '0',                   -- 1-bit input: DRP enable
            DI => (others => '0'),                     -- 16-bit input: DRP data
            DWE => '0',                   -- 1-bit input: DRP write enable
            -- Dynamic Phase Shift Ports: 1-bit (each) input: Ports used for dynamic phase shifting of the outputs
            PSCLK => '0',               -- 1-bit input: Phase shift clock
            PSEN => '0',                 -- 1-bit input: Phase shift enable
            PSINCDEC => '0',         -- 1-bit input: Phase shift increment/decrement
            -- Feedback Clocks: 1-bit (each) input: Clock feedback ports
            CLKFBIN => FbinDcoClk            -- 1-bit input: Feedback clock
        );

    ------------------------------------------------------------------------------------------
    --DcoClock presence detection
    ------------------------------------------------------------------------------------------ 
    -- Not sure if LOCKED or CLKINSTOPPED should be used to reset the MMCM. For now,
    -- logic relying on CLKINSTOPPED is commented out

    InstMMCM_LockRefClkSync: entity work.SyncAsync
        port map (
            aoReset => '0',
            aIn => aMMCM_Locked,
            OutClk => RefClk,
            oOut => rMMCM_LockedLoc);
            
    --the process has no reset signal, however the synchronous logic input
    --has no reset either. I don't think this is an issue      
    ProcMMCM_LockedDetect: process(RefClk)
    begin
        if Rising_Edge(RefClk) then
            rMMCM_Locked_q <= rMMCM_LockedLoc & rMMCM_Locked_q(3 downto 1);
            rMMCM_LckdFallingFlag <= rMMCM_Locked_q(3) and not rMMCM_LockedLoc;
        end if;
    end process;

        rDcoMMCM_LockState <= rMMCM_LockedLoc;

    ------------------------------------------------------------------------------------------
    --MMCM Reset
    ------------------------------------------------------------------------------------------ 
    -- This process will keep the generated reset (rMMCM_Reset_q(0)) asserted for
    -- 4 RefClk cycles. The MMCM_RSTMINPULSE Minimum Reset Pulse Width is 5.00ns
    -- This condition is guaranteed for Sampling frequencies up to 800MHz.

    ProcMMCM_Reset: process(arRst, RefClk)
    begin
        if (arRst = '1') then
            rMMCM_Reset_q <= (others => '1');
        elsif Rising_Edge(RefClk) then
            --if (cMMCM_ClkStopFallingFlag = '1') then -- Not clear which condition should be used from Xilinx documentation
            if (rMMCM_LckdFallingFlag = '1') then
                rMMCM_Reset_q <= (others => '1');
            else
                rMMCM_Reset_q <= '0' & rMMCM_Reset_q(rMMCM_Reset_q'high downto 1);
            end if;
        end if;
    end process;

    ------------------------------------------------------------------------------------------
    -- Data Output Valid Logic
    ------------------------------------------------------------------------------------------
    -- The output valid flag is forced to '0' when the DCO strobe is lost and is 
    -- only allowed to be reasserted on the rising edge of doMMCM_Locked.
    -- A disadvantage of adding this process is that it adds an extra clock latency
    
    InstMMCM_LockDcoBufgClkSync: entity work.SyncBase
    generic map (
        kResetTo => '0',
        kStages => 2)
    port map (
        aiReset => arRst,
        InClk => RefClk,
        iIn => rMMCM_LockedLoc,
        aoReset => adoRst,
        OutClk => DcoBufgClk,
        oOut => doMMCM_LockedLoc);
        
    InstDigitizerHandshake: entity work.HandshakeData
    Generic Map (
       kDataWidth => 4)
    Port Map (
       InClk    => RefClk,
       OutClk   => DcoBufgClk,
       iData    => rMMCM_Locked_q,
       oData    => doMMCM_Locked_q,
       iPush    => rHandShakeRdy,
       iRdy     => rHandShakeRdy,
       oAck     => '1',
       oValid   => doHandShakeDataOutValid,
       aiReset  => arRst,
       aoReset  => adoRst    
       );

    --DcoBufgClk and DcoBufioClk are related, since they are generated by the same MMCM, 
    --and we rely on timing analysis to ensure timing is correctly analized and respected.
    ProcOutDataValid: process(DcoBufgClk, adoRst, doEnableAcquisition)
    begin
        if (adoRst = '1') then
            doDataOutValidLoc <= '0';
            doChannelA <= (others => '0');
            doChannelB <= (others => '0');  
        elsif Rising_Edge(DcoBufgClk) then
            if (doEnableAcquisition = '1') then    
                if ((doMMCM_LockedLoc = '0') or (doMMCM_Locked_q /= "1111" and doHandShakeDataOutValid = '1')) then
                    doDataOutValidLoc <= '0';
                else
                    doDataOutValidLoc <= '1';
                end if;
                if (doDataOutValidLoc = '1') then
                    doChannelA <= dbChannelA_IDDR;
                    doChannelB <= dbChannelB_IDDR;
                end if;
            end if;
        end if;
    end process;

doDataOutValid <= doDataOutValidLoc;


end Behavioral;
