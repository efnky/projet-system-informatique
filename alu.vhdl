library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity alu is
    port(
        A: in std_logic_vector(7 downto 0);
        B: in std_logic_vector(7 downto 0);
        Ctrl_Alu: in std_logic_vector(2 downto 0);

        S: out std_logic_vector(7 downto 0);
        N: out std_logic;
        O: out std_logic;
        Z: out std_logic;
        C: out std_logic
        );
end alu;

architecture struct of alu is
    signal res: std_logic_vector(7 downto 0);
    signal carry_flag: std_logic := '0';
    signal overflow_flag: std_logic := '0';
    
begin
    process(A, B, Ctrl_Alu)
        variable a_u, b_u: unsigned(7 downto 0);
        variable sum: unsigned(8 downto 0);
        variable dif: unsigned(8 downto 0);
        variable mul: unsigned(15 downto 0);
        variable res_tmp: std_logic_vector(7 downto 0);

    begin
        a_u := unsigned(A);
        b_u := unsigned(B);
        res_tmp := (others => '0');
        carry_flag <= '0';
        overflow_flag <= '0';

        case Ctrl_Alu is
            when "001" => -- Addition
                sum := ('0' & a_u) + ('0' & b_u);
                res_tmp := std_logic_vector(sum(7 downto 0));
                carry_flag <= sum(8);

                overflow_flag <= (A(7) and B(7) and (not res_tmp(7))) or
                         ((not A(7)) and (not B(7)) and res_tmp(7));

            when "011" => -- Soustraction
                dif := ('0' & a_u) - ('0' & b_u);
                res_tmp := std_logic_vector(dif(7 downto 0));
                carry_flag <= dif(8);

                overflow_flag <= (A(7) and (not B(7)) and (not res_tmp(7))) or
                         ((not A(7)) and B(7) and res_tmp(7));

            when "010" => -- Multiplication
                mul := a_u * b_u;
                res_tmp := std_logic_vector(mul(7 downto 0));
                overflow_flag <= '1' when mul(15 downto 8) /= "00000000" else '0';

            when others => 
                res_tmp := (others => '0');
        end case;
        
        res <= res_tmp;
    end process;

    S <= res;
    Z <= '1' when res = "00000000" else '0';
    N <= res(7);
    C <= carry_flag;
    O <= overflow_flag;

end struct;