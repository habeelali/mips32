library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity fetch is port (
	pc_out					: out std_logic_vector(31 downto 0);
	instr						: out std_logic_vector(31 downto 0);
	br_addr, jmp_addr		: in std_logic_vector(31 downto 0);
	br_dec, jmp_dec		: in std_logic;
	rst, clk					: in std_logic
);
end fetch;

architecture behavioral of fetch is
	-- instruction memory 32-bit wide, 16 locations
	type instr_mem_arr is array(0 to 15) of std_logic_vector(31 downto 0);
begin
process
	variable instr_mem: instr_mem_arr := (
				X"00000000",
				X"11111111",
				X"22222222",
				X"33333333",
				X"44444444",
				X"55555555",
				X"66666666",
				X"77777777",
				X"88888888",
				X"99999999",
				X"AAAAAAAA",
				X"BBBBBBBB",
				X"CCCCCCCC",
				X"DDDDDDDD",
				X"EEEEEEEE",
				X"FFFFFFFF"
				);
	variable pc: std_logic_vector(31 downto 0);
	variable idx: integer := 0;
begin
	wait until rising_edge(clk);
		if rst = '1' then
            pc := X"00000000";
        elsif br_dec = '1' then
            pc := br_addr;
        elsif jmp_dec = '1' then
            pc := jmp_addr;
        else
            pc := std_logic_vector(unsigned(pc) + 1);
        end if;
        idx := to_integer(unsigned(pc(3 downto 0)));
        pc_out <= pc;
        instr <= instr_mem(idx);
end process;
end behavioral;