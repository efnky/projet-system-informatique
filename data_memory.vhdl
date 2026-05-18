library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity data_memory is
    port(
        addr: in std_logic_vector(7 downto 0);
        data_in: in std_logic_vector(7 downto 0);
        RW: in std_logic;
        RST: in std_logic;
        CLK: in std_logic;
        data_out: out std_logic_vector(7 downto 0)
    );
end data_memory;

architecture behavioral of data_memory is
    type mem_array is array (0 to 255) of std_logic_vector(7 downto 0);
    signal memory: mem_array := (others => (others => '0'));
begin
    process(CLK)
    begin
        if rising_edge(CLK) then
            if RST = '0' then
                memory <= (others => (others => '0'));
                data_out <= (others => '0');
            elsif RW = '0' then
                memory(to_integer(unsigned(addr))) <= data_in;
            else
                data_out <= memory(to_integer(unsigned(addr)));
            end if;
        end if;
    end process;
end behavioral;