library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity instruction_memory is
    port(
        addr: in std_logic_vector(7 downto 0);
        CLK: in std_logic;
        OUT: out std_logic_vector(31 downto 0)
    );
end instruction_memory;

architecture behavioral of instruction_memory is
    type mem_array is array (0 to 255) of std_logic_vector(31 downto 0);
    signal memory: mem_array := (
        -- AFC R1 5      → OP=06, A=01, B=05, C=00  → R1 = 5
        0 => x"06010500",
        -- AFC R2 3      → OP=06, A=02, B=03, C=00  → R2 = 3
        1 => x"06020300",
        -- ADD R3 R1 R2  → OP=01, A=03, B=01, C=02  → R3 = R1 + R2 = 8
        2 => x"01030102",
        -- MUL R4 R1 R2  → OP=02, A=04, B=01, C=02  → R4 = R1 * R2 = 15
        3 => x"02040102",
        -- SOU R5 R3 R2  → OP=03, A=05, B=03, C=02  → R5 = R3 - R2 = 5
        4 => x"03050302",
        -- DIV R6 R3 R2  → OP=04, A=06, B=03, C=02  → R6 = R3 / R2 = 2
        5 => x"04060302",
        -- COP R7 R1     → OP=05, A=07, B=01, C=00  → R7 = R1 = 5
        6 => x"05070100",
        -- STORE @10 R3  → OP=08, A=0A, B=03, C=00  → mem[10] = R3 = 8
        7 => x"080A0300",
        -- LOAD R8 @10   → OP=07, A=08, B=0A, C=00  → R8 = mem[10] = 8
        8 => x"07080A00",
        -- rest is NOP (all zeros)
        others => (others => '0')
    );
begin
    process(CLK)
    begin
        if rising_edge(CLK) then
            OUT <= memory(to_integer(unsigned(addr)));
        end if;
    end process;
end behavioral;