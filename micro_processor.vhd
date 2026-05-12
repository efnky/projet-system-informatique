-- Company:
-- Engineer:
--
-- Create Date: 05/12/2026 01:14:41 PM
-- Design Name:
-- Module Name: micro_proc - Behavioral
-- Project Name:
-- Target Devices:
-- Tool Versions:
-- Description: Microprocessor Implementation Part 1: instruction AFC
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity micro_proc is
    Port ( CLK : in STD_LOGIC;
           RST : in STD_LOGIC;
           QA : out STD_LOGIC_VECTOR (8 downto 0);
           QB : out STD_LOGIC_VECTOR (8 downto 0));
end micro_proc;

architecture Behavioral of micro_proc is
   
    -- instruction memory
    component instruction_memory
        port(
            addr: in std_logic_vector(7 downto 0);
            CLK: in std_logic;
            out1: out std_logic_vector(31 downto 0)
            );
    end component;
   
    -- register bank
    component bande_registre
        port (
            A : in STD_LOGIC_VECTOR (3 downto 0);
            B : in STD_LOGIC_VECTOR (3 downto 0);
            W_addr : in STD_LOGIC_VECTOR (3 downto 0);
            DATA : in STD_LOGIC_VECTOR (7 downto 0);
            RST : in STD_LOGIC;
            W    : in  STD_LOGIC;
            CLK : in STD_LOGIC;
            QA : out STD_LOGIC_VECTOR (7 downto 0);
            QB : out STD_LOGIC_VECTOR (7 downto 0)
            );
    end component;
   
    -- signals for instruction memory
    signal out_instruction :std_logic_vector(31 downto 0);
    signal ip :std_logic_vector(7 downto 0) :=x"00" ;
   
    --signals for register bank
    signal A_RB : STD_LOGIC_VECTOR (3 downto 0) := x"0";
    signal B_RB : STD_LOGIC_VECTOR (3 downto 0) := x"0";
    signal W_a_RB : STD_LOGIC_VECTOR (3 downto 0) := x"0";
    signal DATA_RB : STD_LOGIC_VECTOR (7 downto 0) := x"00";
    signal RST_RB : STD_LOGIC;
    signal W_RB : STD_LOGIC;
    signal QA_RB : STD_LOGIC_VECTOR (7 downto 0) := x"00";
    signal QB_RB : STD_LOGIC_VECTOR (7 downto 0) := x"00";
   
    -- LI/DI signals
    signal OP_LI : std_logic_vector(7 downto 0):= x"00";
    signal A_LI : std_logic_vector(7 downto 0) := x"00";
    signal B_LI : std_logic_vector(7 downto 0):= x"00";
    signal C_LI : std_logic_vector(7 downto 0):= x"00";
   
    -- DI/EX signals
    signal A_DI, B_DI : std_logic_vector(7 downto 0) := x"00";
    signal OP_DI : std_logic_vector(7 downto 0):= x"00";
   
    -- EX/Mem signals
    signal A_EX, B_EX : std_logic_vector(7 downto 0) := x"00";
    signal OP_EX : std_logic_vector(7 downto 0):= x"00";
   
    -- Mem/RE signals
    signal A_Mem, B_Mem : std_logic_vector(7 downto 0) := x"00";
    signal OP_Mem : std_logic_vector(7 downto 0):= x"00";

begin
   
    inst_mem: instruction_memory
        port map (
            addr => ip,
            CLK => CLK,
            out1 => out_instruction
        );
       
    register_bank: bande_registre
        port map (
                A => A_RB,
                B => B_RB,
                W_addr => W_a_RB,
                DATA => DATA_RB,
                RST => RST_RB,
                W => W_RB,
                CLK => CLK,
                QA => QA_RB,
                QB => QB_RB
                );

    OP_LI <= out_instruction(31 downto 24);
    A_LI <= out_instruction(23 downto 16);
    B_LI <= out_instruction(15 downto 8);
    C_LI <= out_instruction(7 downto 0);

    -- LI/DI
    process(clk)
    begin
        if rising_edge(clk) then
            ip <= std_logic_vector(unsigned(ip)+1);
        end if;
    end process;
   
    -- DI/EX
    process(clk)
    begin
        if rising_edge(clk) then
            OP_DI <= OP_LI;
            A_DI <= A_LI;
            B_DI <= B_LI;
        end if;
    end process;
   
    -- EX/Mem
    process(clk)
    begin
        if rising_edge(clk) then
            OP_EX <= OP_DI;
            A_EX <= A_DI;
            B_EX <= B_DI;
        end if;
    end process;
   
    -- Mem/RE
    process(clk)
    begin
        if rising_edge(clk) then
            OP_Mem <= OP_EX;
            A_Mem <= A_EX;
            B_Mem <= B_EX;
        end if;
    end process;
   
    W_a_RB <= A_Mem(3 downto 0);
    W_RB <= '1' when OP_Mem = x"06" else '0';
    DATA_RB <= B_Mem;
    RST_RB <= RST;
    QA <= '0' & QA_RB;
    QB <= '0' & QB_RB;

end Behavioral;
