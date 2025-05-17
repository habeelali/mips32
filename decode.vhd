library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity decode is
    port (
        instruction : in STD_LOGIC_VECTOR (31 downto 0);
        clock       : in STD_LOGIC;
        reset       : in STD_LOGIC;
        RegDst      : in STD_LOGIC;
        RegWrite    : in STD_LOGIC;
        MemToReg    : in STD_LOGIC;
        memory_data : in STD_LOGIC_VECTOR (31 downto 0);
        alu_result  : in STD_LOGIC_VECTOR (31 downto 0);
        register_rs : out STD_LOGIC_VECTOR (31 downto 0);
        register_rt : out STD_LOGIC_VECTOR (31 downto 0);
        immediate   : out STD_LOGIC_VECTOR (31 downto 0);
        jump_addr   : out STD_LOGIC_VECTOR (31 downto 0)
    );
end decode;

architecture Behavioral of decode is
    type reg_array is array(0 to 31) of STD_LOGIC_VECTOR(31 downto 0);
    shared variable RegFile: reg_array := (
        X"00000000", -- Register 0 (ZERO)
        X"11111111", -- Register 1
        X"22222222", -- Register 2
        X"33333333", -- Register 3
        X"44444444", -- Register 4
        others => X"01010101"
    );
begin

    -- Register Write Process (Synchronous)
    reg_writer: process(clock, reset)
        variable write_index : integer;
        variable write_value : STD_LOGIC_VECTOR(31 downto 0);
    begin
        if reset = '1' then
            RegFile := (
                X"00000000", -- Reset Register 0
                X"11111111", -- Register 1
                X"22222222", -- Register 2
                X"33333333", -- Register 3
                X"44444444", -- Register 4
                others => X"01010101"
            );
        elsif rising_edge(clock) then
            if RegWrite = '1' then
                -- Determine destination register index
                if RegDst = '0' then
                    write_index := to_integer(unsigned(instruction(20 downto 16)));
                else
                    write_index := to_integer(unsigned(instruction(15 downto 11)));
                end if;

                -- Prevent write to register 0
                if write_index /= 0 then
                    -- Select write value source
                    if MemToReg = '1' then
                        write_value := memory_data;
                    else
                        write_value := alu_result;
                    end if;
                    RegFile(write_index) := write_value;
                end if;
            end if;
        end if;
    end process;

    -- Register Read Process (Combinational)
    reg_read: process(instruction)
        variable rs_addr, rt_addr : integer;
        variable imm : STD_LOGIC_VECTOR(31 downto 0);
    begin
        -- Read register addresses
        rs_addr := to_integer(unsigned(instruction(25 downto 21)));
        rt_addr := to_integer(unsigned(instruction(20 downto 16)));

        -- Assign register outputs
        register_rs <= RegFile(rs_addr);
        register_rt <= RegFile(rt_addr);

        -- Sign-extend immediate
        imm(15 downto 0) := instruction(15 downto 0);
        if instruction(15) = '1' then
            imm(31 downto 16) := (others => '1');
        else
            imm(31 downto 16) := (others => '0');
        end if;
        immediate <= imm;

        -- Compute jump address
        jump_addr <= "0000" & instruction(25 downto 0) & "00";
    end process;

end Behavioral;