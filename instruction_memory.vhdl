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
        -- needs to be changed with the real addresses for each instruction
        0 => x"E0000000",
        1 => x"E0010001",
        2 => x"E0020002",
        3 => x"E0030003",
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